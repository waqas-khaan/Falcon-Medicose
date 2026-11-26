import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../database/database_helper.dart';
import '../models/customer.dart';
import '../models/customer_payment.dart';
import '../models/invoice.dart';
import '../models/store_settings.dart';
import '../utils/app_theme.dart';
import '../utils/formatters.dart';
import '../widgets/empty_state.dart';
import '../widgets/glass_widgets.dart';
import '../widgets/thermal_receipt_dialog.dart';

class CustomerDetailScreen extends StatefulWidget {
  final int customerId;

  const CustomerDetailScreen({super.key, required this.customerId});

  @override
  State<CustomerDetailScreen> createState() => _CustomerDetailScreenState();
}

class _CustomerDetailScreenState extends State<CustomerDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Customer? _customer;
  StoreSettings _settings = StoreSettings();
  List<Invoice> _invoices = [];
  List<CustomerPayment> _payments = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadCustomerData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadCustomerData() async {
    setState(() => _isLoading = true);
    final settings = await DatabaseHelper.getSettings();
    final customer = await DatabaseHelper.getCustomerById(widget.customerId);
    final invoices =
        await DatabaseHelper.getInvoices(customerId: widget.customerId);
    final payments =
        await DatabaseHelper.getCustomerPayments(widget.customerId);

    if (mounted) {
      setState(() {
        _settings = settings;
        _customer = customer;
        _invoices = invoices;
        _payments = payments;
        _isLoading = false;
      });
    }
  }

  void _openReceivePaymentDialog() {
    if (_customer == null) return;
    final amountCtrl = TextEditingController(
        text: _customer!.remainingAmount > 0
            ? _customer!.remainingAmount.toStringAsFixed(0)
            : '');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Receive Payment from ${_customer!.name}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Current Outstanding Debt: ${Formatters.formatCurrency(_customer!.remainingAmount, _settings.currency)}',
              style: const TextStyle(
                  color: AppColors.danger, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: amountCtrl,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: 'Amount Received',
                prefixIcon: const Icon(Icons.payments_outlined,
                    color: AppColors.primaryLight, size: 18),
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.8),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ModernButton(
            label: 'Save Payment',
            icon: Icons.check_rounded,
            onPressed: () async {
              final amt = double.tryParse(amountCtrl.text.trim()) ?? 0.0;
              if (amt <= 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please enter valid amount')));
                return;
              }

              await DatabaseHelper.receiveCustomerPayment(
                  _customer!.id!, amt);
              Navigator.pop(ctx);
              _loadCustomerData();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                      'Recorded payment of ${Formatters.formatCurrency(amt, _settings.currency)}'),
                  backgroundColor: AppColors.success,
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  void _sendReminder(bool viaWhatsApp) async {
    if (_customer == null) return;
    final phone =
        _customer!.phone?.replaceAll(RegExp(r'[^0-9]'), '') ?? '';
    final msg = 'Dear ${_customer!.name},\n'
        'This is a friendly reminder from ${_settings.storeName}.\n\n'
        'Total Payment: ${Formatters.formatCurrency(_customer!.totalAmount, _settings.currency)}\n'
        'Received: ${Formatters.formatCurrency(_customer!.paidAmount, _settings.currency)}\n'
        'Remaining Balance: ${Formatters.formatCurrency(_customer!.remainingAmount, _settings.currency)}\n\n'
        'Please clear your remaining balance at your earliest convenience. Thank you!\n'
        'Contact: ${_settings.phone}';

    if (viaWhatsApp) {
      final formattedPhone =
          phone.startsWith('0') ? '92${phone.substring(1)}' : phone;
      final uri = Uri.parse(
          'https://wa.me/$formattedPhone?text=${Uri.encodeComponent(msg)}');
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } else {
      final uri = Uri.parse('sms:$phone?body=${Uri.encodeComponent(msg)}');
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(
            child: CircularProgressIndicator(color: AppColors.primaryLight)),
      );
    }

    if (_customer == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Customer Not Found')),
        body: const Center(child: Text('Customer does not exist')),
      );
    }

    final c = _customer!;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text(c.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadCustomerData,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold),
          tabs: [
            Tab(text: 'Invoices (${_invoices.length})'),
            Tab(text: 'Payments (${_payments.length})'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Customer Summary Card
          Padding(
            padding: const EdgeInsets.all(16),
            child: GlassCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          gradient: AppColors.primaryActionGradient,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.person_rounded,
                            color: Colors.white, size: 28),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(c.name,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w800, fontSize: 16)),
                            if (c.phone != null && c.phone!.isNotEmpty)
                              Text('Phone: ${c.phone}',
                                  style: const TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: 13)),
                            if (c.address != null && c.address!.isNotEmpty)
                              Text('Address: ${c.address}',
                                  style: const TextStyle(
                                      color: AppColors.textMuted,
                                      fontSize: 12)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Balances Row
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Column(
                          children: [
                            const Text('Total Billed',
                                style: TextStyle(
                                    fontSize: 11, color: AppColors.textMuted)),
                            const SizedBox(height: 2),
                            Text(
                                Formatters.formatCurrency(
                                    c.totalAmount, _settings.currency),
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 13)),
                          ],
                        ),
                        Container(width: 1, height: 28, color: AppColors.border),
                        Column(
                          children: [
                            const Text('Total Paid',
                                style: TextStyle(
                                    fontSize: 11, color: AppColors.textMuted)),
                            const SizedBox(height: 2),
                            Text(
                                Formatters.formatCurrency(
                                    c.paidAmount, _settings.currency),
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                    color: AppColors.success)),
                          ],
                        ),
                        Container(width: 1, height: 28, color: AppColors.border),
                        Column(
                          children: [
                            const Text('Balance Due',
                                style: TextStyle(
                                    fontSize: 11, color: AppColors.textMuted)),
                            const SizedBox(height: 2),
                            Text(
                              Formatters.formatCurrency(
                                  c.remainingAmount, _settings.currency),
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 13,
                                color: c.hasOutstandingLoan
                                    ? AppColors.danger
                                    : AppColors.success,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Actions: Receive Payment & WhatsApp Reminder
                  Row(
                    children: [
                      Expanded(
                        child: ModernButton(
                          label: 'Receive Payment',
                          icon: Icons.add_rounded,
                          onPressed: _openReceivePaymentDialog,
                          isFullWidth: true,
                        ),
                      ),
                      if (c.hasOutstandingLoan &&
                          c.phone != null &&
                          c.phone!.isNotEmpty) ...[
                        const SizedBox(width: 8),
                        OutlinedButton.icon(
                          onPressed: () => _sendReminder(true),
                          icon: const Icon(Icons.chat_rounded,
                              size: 17, color: Color(0xFF25D366)),
                          label: const Text('WhatsApp Statement'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF1E8E3E),
                            side: const BorderSide(
                                color: Color(0xFF25D366), width: 1.2),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 12),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Invoices & Payments Lists
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // Invoices tab
                _invoices.isEmpty
                    ? const EmptyState(
                        icon: Icons.receipt_outlined,
                        title: 'No invoices yet',
                        subtitle: 'Invoices for this customer will show up here',
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: _invoices.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (context, i) {
                          final inv = _invoices[i];
                          return GlassCard(
                            padding: const EdgeInsets.all(12),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Text('Invoice #${inv.id}',
                                              style: const TextStyle(
                                                  fontWeight: FontWeight.w700)),
                                          const SizedBox(width: 6),
                                          StatusBadge(
                                            label: inv.isWholesale
                                                ? 'Wholesale'
                                                : 'Retail',
                                            color: inv.isWholesale
                                                ? const Color(0xFF6366F1)
                                                : AppColors.primaryLight,
                                          ),
                                        ],
                                      ),
                                      Text(
                                          Formatters.formatDateTime(
                                              inv.invoiceDate),
                                          style: const TextStyle(
                                              fontSize: 11,
                                              color: AppColors.textMuted)),
                                      Text('${inv.items.length} items',
                                          style: const TextStyle(
                                              fontSize: 11,
                                              color: AppColors.textSecondary)),
                                    ],
                                  ),
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                        Formatters.formatCurrency(
                                            inv.totalAmount,
                                            _settings.currency),
                                        style: const TextStyle(
                                            fontWeight: FontWeight.w800,
                                            color: AppColors.primaryLight)),
                                    if (inv.remainingAmount > 0.01)
                                      Text(
                                        'Due: ${Formatters.formatCurrency(inv.remainingAmount, _settings.currency)}',
                                        style: const TextStyle(
                                            color: AppColors.danger,
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold),
                                      ),
                                  ],
                                ),
                                const SizedBox(width: 6),
                                IconButton(
                                  icon: const Icon(Icons.print_rounded,
                                      size: 18, color: AppColors.primaryLight),
                                  onPressed: () => ThermalReceiptDialog.show(
                                      context, inv, _settings),
                                ),
                              ],
                            ),
                          );
                        },
                      ),

                // Payments tab
                _payments.isEmpty
                    ? const EmptyState(
                        icon: Icons.payments_outlined,
                        title: 'No payments recorded',
                        subtitle:
                            'Payments recorded from this customer will appear here',
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: _payments.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (context, i) {
                          final p = _payments[i];
                          return GlassCard(
                            padding: const EdgeInsets.all(12),
                            child: Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: AppColors.success
                                            .withValues(alpha: 0.15),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                          Icons.arrow_downward_rounded,
                                          color: AppColors.success,
                                          size: 18),
                                    ),
                                    const SizedBox(width: 12),
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text('Payment Received',
                                            style: TextStyle(
                                                fontWeight: FontWeight.w600)),
                                        Text(
                                            Formatters.formatDateTime(
                                                p.paymentDate),
                                            style: const TextStyle(
                                                fontSize: 11,
                                                color: AppColors.textMuted)),
                                      ],
                                    ),
                                  ],
                                ),
                                Text(
                                  '+${Formatters.formatCurrency(p.amount, _settings.currency)}',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.success,
                                      fontSize: 14),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
