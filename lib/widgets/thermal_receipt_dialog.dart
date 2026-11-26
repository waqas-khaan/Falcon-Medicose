import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/invoice.dart';
import '../models/store_settings.dart';
import '../utils/app_theme.dart';
import '../utils/receipt_formatter.dart';

class ThermalReceiptDialog extends StatefulWidget {
  final Invoice invoice;
  final StoreSettings settings;

  const ThermalReceiptDialog({
    super.key,
    required this.invoice,
    required this.settings,
  });

  static Future<void> show(BuildContext context, Invoice invoice, StoreSettings settings) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => ThermalReceiptDialog(invoice: invoice, settings: settings),
    );
  }

  @override
  State<ThermalReceiptDialog> createState() => _ThermalReceiptDialogState();
}

class _ThermalReceiptDialogState extends State<ThermalReceiptDialog> {
  final GlobalKey _receiptKey = GlobalKey();
  bool _isSharingImage = false;

  void _copyToClipboard(BuildContext context, String receiptText) {
    Clipboard.setData(ClipboardData(text: receiptText));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Receipt text copied to clipboard!'),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _shareReceiptImage(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _isSharingImage = true);
    try {
      final boundary = _receiptKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) {
        throw Exception('Could not render receipt graphic');
      }
      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) throw Exception('Failed to generate PNG');

      final pngBytes = byteData.buffer.asUint8List();
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/receipt_${widget.invoice.id ?? "new"}.png');
      await file.writeAsBytes(pngBytes);

      await Share.shareXFiles(
        [XFile(file.path)],
        text: '${widget.settings.storeName} - Invoice #${widget.invoice.id ?? ""}',
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(
          content: Text('Sharing text instead: $e'),
          backgroundColor: AppColors.warning,
        ),
      );
      final text = ReceiptFormatter.generate58mmReceipt(
        invoice: widget.invoice,
        settings: widget.settings,
      );
      Share.share(text);
    } finally {
      if (mounted) setState(() => _isSharingImage = false);
    }
  }

  void _sendViaWhatsApp(BuildContext context) async {
    final phone = widget.invoice.customerPhone?.replaceAll(RegExp(r'[^0-9]'), '');
    final receiptText = ReceiptFormatter.generateWhatsAppText(
      invoice: widget.invoice,
      settings: widget.settings,
    );
    final encodedText = Uri.encodeComponent(receiptText);

    Uri uri;
    if (phone != null && phone.isNotEmpty) {
      final formattedPhone = phone.startsWith('0') ? '92${phone.substring(1)}' : phone;
      uri = Uri.parse('https://wa.me/$formattedPhone?text=$encodedText');
    } else {
      uri = Uri.parse('https://wa.me/?text=$encodedText');
    }

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      Share.share(receiptText);
    }
  }

  @override
  Widget build(BuildContext context) {
    final invoice = widget.invoice;
    final settings = widget.settings;
    final storeName = settings.storeName.contains('🦅') ? settings.storeName : '🦅 ${settings.storeName}';
    final whatsapp = settings.phone.isNotEmpty ? settings.phone : '03345008354';
    final customer = (invoice.customerName != null && invoice.customerName!.isNotEmpty)
        ? invoice.customerName!.toUpperCase()
        : 'WALK-IN CUSTOMER';

    final subtotal = invoice.items.fold<double>(0, (sum, i) => sum + i.totalPrice);
    final discount = invoice.discount > 0
        ? invoice.discount
        : (subtotal - invoice.totalAmount > 0 ? subtotal - invoice.totalAmount : 0.0);

    final rawReceiptText = ReceiptFormatter.generate58mmReceipt(
      invoice: invoice,
      settings: settings,
    );

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 380),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(50),
              blurRadius: 18,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Top App Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: const BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.print, color: Colors.white, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Print Receipt (58mm)',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, color: Colors.white, size: 20),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),

            // Scrollable Receipt Body (Target for Image Generation)
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: RepaintBoundary(
                  key: _receiptKey,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: Colors.black26, width: 0.8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Store Header
                        Center(
                          child: Text(
                            storeName,
                            style: const TextStyle(
                              fontFamily: 'Courier',
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              color: Colors.black,
                              letterSpacing: 0.5,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Center(
                          child: Text(
                            'WhatsApp: $whatsapp',
                            style: const TextStyle(
                              fontFamily: 'Courier',
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.black,
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        _buildDashedLine(),
                        const SizedBox(height: 6),

                        // Metadata
                        Text(
                          'Invoice #: ${invoice.id ?? "N/A"}',
                          style: const TextStyle(
                            fontFamily: 'Courier',
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Date: ${ReceiptFormatter.formatReceiptDate(invoice.invoiceDate)}',
                          style: const TextStyle(
                            fontFamily: 'Courier',
                            fontSize: 12,
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Customer: $customer',
                          style: const TextStyle(
                            fontFamily: 'Courier',
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                        if (invoice.doctorName != null && invoice.doctorName!.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            'Doctor: ${invoice.doctorName!.toUpperCase()}',
                            style: const TextStyle(
                              fontFamily: 'Courier',
                              fontSize: 11,
                              color: Colors.black,
                            ),
                          ),
                        ],
                        if (invoice.roomNumber != null && invoice.roomNumber!.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            'Ward/Room: ${invoice.roomNumber}',
                            style: const TextStyle(
                              fontFamily: 'Courier',
                              fontSize: 11,
                              color: Colors.black,
                            ),
                          ),
                        ],

                        const SizedBox(height: 6),
                        _buildDashedLine(),
                        const SizedBox(height: 6),

                        // EXACT TABLE GRID FROM IMAGE
                        Table(
                          border: TableBorder.all(color: Colors.black, width: 1.0),
                          defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                          columnWidths: const {
                            0: FixedColumnWidth(22), // #
                            1: FlexColumnWidth(3.4), // ITEM
                            2: FlexColumnWidth(1.6), // RATE
                            3: FixedColumnWidth(28), // QTY
                            4: FixedColumnWidth(32), // DISC
                            5: FlexColumnWidth(1.8), // NET
                          },
                          children: [
                            // Table Header Row
                            TableRow(
                              decoration: const BoxDecoration(color: Color(0xFFEBEBEB)),
                              children: [
                                _tableCell('#', align: TextAlign.center, isHeader: true),
                                _tableCell('ITEM', align: TextAlign.left, isHeader: true),
                                _tableCell('RATE', align: TextAlign.right, isHeader: true),
                                _tableCell('QTY', align: TextAlign.center, isHeader: true),
                                _tableCell('DISC', align: TextAlign.center, isHeader: true),
                                _tableCell('NET', align: TextAlign.right, isHeader: true),
                              ],
                            ),

                            // Table Data Rows
                            ...invoice.items.asMap().entries.map((entry) {
                              final idx = entry.key + 1;
                              final item = entry.value;
                              final qtyStr = item.quantity % 1 == 0
                                  ? '${item.quantity.toInt()}'
                                  : item.quantity.toStringAsFixed(1);
                              final discStr = item.discountPercent > 0
                                  ? '${item.discountPercent.toInt()}%'
                                  : '0';

                              return TableRow(
                                children: [
                                  _tableCell('$idx', align: TextAlign.center),
                                  _tableCell(item.medicineName.toUpperCase(), align: TextAlign.left),
                                  _tableCell(item.unitPrice.toStringAsFixed(2), align: TextAlign.right),
                                  _tableCell(qtyStr, align: TextAlign.center),
                                  _tableCell(discStr, align: TextAlign.center),
                                  _tableCell(item.totalPrice.toStringAsFixed(2), align: TextAlign.right),
                                ],
                              );
                            }),
                          ],
                        ),

                        const SizedBox(height: 8),
                        _buildDashedLine(),
                        const SizedBox(height: 6),

                        // Totals Summary
                        _buildTotalsRow('Subtotal', 'Rs ${subtotal.toStringAsFixed(0)}'),
                        const SizedBox(height: 2),
                        _buildTotalsRow('Discount', 'Rs ${discount.toStringAsFixed(0)}'),
                        const SizedBox(height: 4),
                        _buildTotalsRow(
                          'Total',
                          'Rs ${invoice.totalAmount.toStringAsFixed(0)}',
                          isBold: true,
                          fontSize: 15,
                        ),
                        const SizedBox(height: 4),
                        _buildTotalsRow('Paid', 'Rs ${invoice.paidAmount.toStringAsFixed(0)}'),
                        const SizedBox(height: 2),
                        _buildTotalsRow('Balance', 'Rs ${invoice.remainingAmount.toStringAsFixed(0)}'),

                        const SizedBox(height: 6),
                        _buildDashedLine(),
                        const SizedBox(height: 8),

                        // Footer
                        Center(
                          child: Text(
                            settings.receiptFooter.isNotEmpty
                                ? settings.receiptFooter
                                : 'Thank you! Get well soon.',
                            style: const TextStyle(
                              fontFamily: 'Courier',
                              fontSize: 12,
                              color: Colors.black,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // Action Buttons Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: const BoxDecoration(
                color: Color(0xFFF9FAFB),
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
                border: Border(top: BorderSide(color: AppColors.border)),
              ),
              child: Row(
                children: [
                  // Share Receipt Image (PNG)
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _isSharingImage ? null : () => _shareReceiptImage(context),
                      icon: _isSharingImage
                          ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                            )
                          : const Icon(Icons.share, size: 16, color: Colors.white),
                      label: Text(
                        _isSharingImage ? 'Saving...' : 'Share Receipt',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // WhatsApp Button
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _sendViaWhatsApp(context),
                      icon: const Icon(Icons.chat, size: 16, color: Colors.white),
                      label: const Text(
                        'WhatsApp',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF25D366),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),

                  // Copy Text Button
                  IconButton(
                    onPressed: () => _copyToClipboard(context, rawReceiptText),
                    icon: const Icon(Icons.copy, size: 18, color: AppColors.textPrimary),
                    tooltip: 'Copy Text',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tableCell(String text, {required TextAlign align, bool isHeader = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2.5, vertical: 3.5),
      child: Text(
        text,
        textAlign: align,
        style: TextStyle(
          fontFamily: 'Courier',
          fontSize: 9.5,
          fontWeight: isHeader ? FontWeight.w900 : FontWeight.w600,
          color: Colors.black,
        ),
      ),
    );
  }

  Widget _buildTotalsRow(
    String label,
    String value, {
    bool isBold = false,
    double fontSize = 12,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontFamily: 'Courier',
            fontSize: fontSize,
            fontWeight: isBold ? FontWeight.w900 : FontWeight.normal,
            color: Colors.black,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontFamily: 'Courier',
            fontSize: fontSize,
            fontWeight: isBold ? FontWeight.w900 : FontWeight.normal,
            color: Colors.black,
          ),
        ),
      ],
    );
  }

  Widget _buildDashedLine() {
    return const Text(
      '----------------------------------------',
      maxLines: 1,
      overflow: TextOverflow.clip,
      style: TextStyle(
        fontFamily: 'Courier',
        fontSize: 11,
        color: Colors.black,
        letterSpacing: 1.0,
      ),
    );
  }
}
