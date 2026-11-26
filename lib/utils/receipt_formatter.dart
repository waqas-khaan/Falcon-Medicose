import 'package:intl/intl.dart';
import '../models/invoice.dart';
import '../models/store_settings.dart';

class ReceiptFormatter {
  static const int paperWidth = 38; // standard 58mm thermal receipt characters width

  static String center(String text, [int width = paperWidth]) {
    if (text.length >= width) return text;
    final pad = (width - text.length) ~/ 2;
    return ' ' * pad + text;
  }

  static String line([String char = '-', int width = paperWidth]) {
    return char * width;
  }

  static String row2(String left, String right, [int width = paperWidth]) {
    final available = width - left.length - right.length;
    if (available <= 0) return '$left $right';
    return left + (' ' * available) + right;
  }

  static String formatReceiptDate(String? raw) {
    if (raw == null || raw.isEmpty) {
      return DateFormat('M/d/yyyy, h:mm:ss a').format(DateTime.now());
    }
    try {
      final dt = DateTime.parse(raw);
      return DateFormat('M/d/yyyy, h:mm:ss a').format(dt);
    } catch (_) {
      return raw;
    }
  }

  static String generate58mmReceipt({
    required Invoice invoice,
    required StoreSettings settings,
  }) {
    final buffer = StringBuffer();
    final storeName = settings.storeName.contains('🦅') ? settings.storeName : '🦅 ${settings.storeName}';
    final whatsapp = settings.phone.isNotEmpty ? settings.phone : '03345008354';

    // Header
    buffer.writeln(center(storeName));
    buffer.writeln(center('WhatsApp: $whatsapp'));
    buffer.writeln(line('-'));

    // Metadata
    buffer.writeln('Invoice #: ${invoice.id ?? "N/A"}');
    buffer.writeln('Date: ${formatReceiptDate(invoice.invoiceDate)}');
    final customer = (invoice.customerName != null && invoice.customerName!.isNotEmpty)
        ? invoice.customerName!.toUpperCase()
        : 'WALK-IN';
    buffer.writeln('Customer: $customer');
    if (invoice.doctorName != null && invoice.doctorName!.isNotEmpty) {
      buffer.writeln('Doctor: ${invoice.doctorName!.toUpperCase()}');
    }
    if (invoice.roomNumber != null && invoice.roomNumber!.isNotEmpty) {
      buffer.writeln('Ward/Room: ${invoice.roomNumber}');
    }
    buffer.writeln(line('-'));

    // Table Header
    // Column layout: # (2) | ITEM (12) | RATE (6) | QTY (3) | DISC (4) | NET (7)
    buffer.writeln(
      '#  ${'ITEM'.padRight(12)}${'RATE'.padLeft(6)} ${'QTY'.padLeft(3)} ${'DISC'.padLeft(4)} ${'NET'.padLeft(7)}',
    );
    buffer.writeln(line('-'));

    // Items
    for (int i = 0; i < invoice.items.length; i++) {
      final item = invoice.items[i];
      final idx = '${i + 1}'.padRight(2);
      final rawName = item.medicineName.toUpperCase();
      final name = rawName.length > 12 ? '${rawName.substring(0, 11)}.' : rawName.padRight(12);
      final rate = item.unitPrice.toStringAsFixed(2).padLeft(6);
      final qty = (item.quantity % 1 == 0 ? '${item.quantity.toInt()}' : item.quantity.toStringAsFixed(1)).padLeft(3);
      final disc = (item.discountPercent > 0 ? '${item.discountPercent.toInt()}%' : '0').padLeft(4);
      final net = item.totalPrice.toStringAsFixed(2).padLeft(7);

      buffer.writeln('$idx $name $rate $qty $disc $net');
    }

    buffer.writeln(line('-'));

    // Totals
    final subtotal = invoice.items.fold<double>(0, (sum, i) => sum + i.totalPrice);
    final discount = invoice.discount > 0 ? invoice.discount : (subtotal - invoice.totalAmount > 0 ? subtotal - invoice.totalAmount : 0.0);

    buffer.writeln(row2('Subtotal', 'Rs ${subtotal.toStringAsFixed(0)}'));
    buffer.writeln(row2('Discount', 'Rs ${discount.toStringAsFixed(0)}'));
    buffer.writeln(row2('Total', 'Rs ${invoice.totalAmount.toStringAsFixed(0)}'));
    buffer.writeln(row2('Paid', 'Rs ${invoice.paidAmount.toStringAsFixed(0)}'));
    buffer.writeln(row2('Balance', 'Rs ${invoice.remainingAmount.toStringAsFixed(0)}'));

    buffer.writeln(line('-'));

    // Footer
    final footer = settings.receiptFooter.isNotEmpty ? settings.receiptFooter : 'Thank you! Get well soon.';
    buffer.writeln(center(footer));
    buffer.writeln('');

    return buffer.toString();
  }

  static String generateWhatsAppText({
    required Invoice invoice,
    required StoreSettings settings,
  }) {
    final buffer = StringBuffer();
    final storeName = settings.storeName.contains('🦅') ? settings.storeName : '🦅 *${settings.storeName}*';
    final whatsapp = settings.phone.isNotEmpty ? settings.phone : '03345008354';

    buffer.writeln(storeName);
    buffer.writeln('WhatsApp: $whatsapp');
    buffer.writeln('--------------------------------');
    buffer.writeln('*Invoice #:* ${invoice.id ?? "N/A"}');
    buffer.writeln('*Date:* ${formatReceiptDate(invoice.invoiceDate)}');
    final customer = (invoice.customerName != null && invoice.customerName!.isNotEmpty)
        ? invoice.customerName!.toUpperCase()
        : 'WALK-IN';
    buffer.writeln('*Customer:* $customer');
    buffer.writeln('--------------------------------');

    for (int i = 0; i < invoice.items.length; i++) {
      final item = invoice.items[i];
      final disc = item.discountPercent > 0 ? ' (${item.discountPercent.toInt()}% off)' : '';
      final qty = item.quantity % 1 == 0 ? item.quantity.toInt() : item.quantity;
      buffer.writeln('${i + 1}. *${item.medicineName.toUpperCase()}*');
      buffer.writeln('   $qty x Rs ${item.unitPrice.toStringAsFixed(2)}$disc = *Rs ${item.totalPrice.toStringAsFixed(2)}*');
    }

    buffer.writeln('--------------------------------');
    final subtotal = invoice.items.fold<double>(0, (sum, i) => sum + i.totalPrice);
    final discount = invoice.discount > 0 ? invoice.discount : (subtotal - invoice.totalAmount > 0 ? subtotal - invoice.totalAmount : 0.0);

    buffer.writeln('Subtotal: Rs ${subtotal.toStringAsFixed(0)}');
    buffer.writeln('Discount: Rs ${discount.toStringAsFixed(0)}');
    buffer.writeln('*Total: Rs ${invoice.totalAmount.toStringAsFixed(0)}*');
    buffer.writeln('Paid: Rs ${invoice.paidAmount.toStringAsFixed(0)}');
    buffer.writeln('Balance: Rs ${invoice.remainingAmount.toStringAsFixed(0)}');
    buffer.writeln('--------------------------------');
    final footer = settings.receiptFooter.isNotEmpty ? settings.receiptFooter : 'Thank you! Get well soon.';
    buffer.writeln(footer);

    return buffer.toString();
  }
}
