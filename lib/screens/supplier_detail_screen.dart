import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../models/store_settings.dart';
import '../models/supplier.dart';
import '../models/supplier_payment.dart';
import '../utils/app_theme.dart';
import '../utils/formatters.dart';
import '../widgets/empty_state.dart';
import '../widgets/glass_widgets.dart';

class SupplierDetailScreen extends StatefulWidget {
  final int supplierId;

  const SupplierDetailScreen({super.key, required this.supplierId});

  @override
  State<SupplierDetailScreen> createState() => _SupplierDetailScreenState();
}

class _SupplierDetailScreenState extends State<SupplierDetailScreen> {
  Supplier? _supplier;
  StoreSettings _settings = StoreSettings();
  List<SupplierPayment> _payments = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSupplierData();
  }

  Future<void> _loadSupplierData() async {
    setState(() => _isLoading = true);
    final settings = await DatabaseHelper.getSettings();
    final supplier = await DatabaseHelper.getSupplierById(widget.supplierId);
    final payments =
        await DatabaseHelper.getSupplierPayments(widget.supplierId);

    if (mounted) {
      setState(() {
        _settings = settings;
        _supplier = supplier;
        _payments = payments;
        _isLoading = false;
      });
    }
  }

  void _openPaySupplierDialog() {
    if (_supplier == null) return;
    final amountCtrl = TextEditingController(
      text: _supplier!.remainingAmount > 0
          ? _supplier!.remainingAmount.toStringAsFixed(0)
          : '',
    );

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Pay ${_supplier!.name}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Current Amount You Owe: ${Formatters.formatCurrency(_supplier!.remainingAmount, _settings.currency)}',
              style: const TextStyle(
                  color: AppColors.danger, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: amountCtrl,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: 'Amount to Pay',
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
            label: 'Record Payment',
            icon: Icons.check_rounded,
            onPressed: () async {
              final amt = double.tryParse(amountCtrl.text.trim()) ?? 0.0;
              if (amt <= 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please enter valid amount')));
                return;
              }

              await DatabaseHelper.paySupplier(_supplier!.id!, amt);
              Navigator.pop(ctx);
              _loadSupplierData();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                      'Recorded payment of ${Formatters.formatCurrency(amt, _settings.currency)} to ${_supplier!.name}'),
                  backgroundColor: AppColors.success,
                ),
              );
            },
          ),
        ],
      ),
    );
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

    if (_supplier == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Supplier Not Found')),
        body: const Center(child: Text('Supplier does not exist')),
      );
    }

    final s = _supplier!;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text(s.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadSupplierData,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Supplier Summary Card
            GlassCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF6366F1).withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.local_shipping_rounded,
                            color: Color(0xFF6366F1), size: 28),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(s.name,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w800, fontSize: 16)),
                            if (s.phone != null && s.phone!.isNotEmpty)
                              Text('Phone: ${s.phone}',
                                  style: const TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: 13)),
                            if (s.address != null && s.address!.isNotEmpty)
                              Text('Address: ${s.address}',
                                  style: const TextStyle(
                                      color: AppColors.textMuted,
                                      fontSize: 12)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Balances
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
                            const Text('Total Bought',
                                style: TextStyle(
                                    fontSize: 11, color: AppColors.textMuted)),
                            const SizedBox(height: 2),
                            Text(
                                Formatters.formatCurrency(
                                    s.totalAmount, _settings.currency),
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
                                    s.paidAmount, _settings.currency),
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                    color: AppColors.success)),
                          ],
                        ),
                        Container(width: 1, height: 28, color: AppColors.border),
                        Column(
                          children: [
                            const Text('You Owe',
                                style: TextStyle(
                                    fontSize: 11, color: AppColors.textMuted)),
                            const SizedBox(height: 2),
                            Text(
                              Formatters.formatCurrency(
                                  s.remainingAmount, _settings.currency),
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 13,
                                color: s.hasOutstandingPayable
                                    ? AppColors.danger
                                    : AppColors.success,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  ModernButton(
                    label: 'Pay Supplier',
                    icon: Icons.payments_rounded,
                    onPressed: _openPaySupplierDialog,
                    width: double.infinity,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Payments List
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Payment History to Supplier',
                    style:
                        TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                const SizedBox(height: 10),
                if (_payments.isEmpty)
                  const EmptyState(
                    icon: Icons.payments_outlined,
                    title: 'No payments recorded',
                    subtitle: 'Payments made to this supplier will appear here',
                  )
                else
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _payments.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, i) {
                      final p = _payments[i];
                      return GlassCard(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                                      Icons.arrow_upward_rounded,
                                      color: AppColors.success,
                                      size: 18),
                                ),
                                const SizedBox(width: 12),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Payment Sent',
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
                              '-${Formatters.formatCurrency(p.amount, _settings.currency)}',
                              style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.primaryLight,
                                  fontSize: 14),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
