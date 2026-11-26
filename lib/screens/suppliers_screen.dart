import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../models/store_settings.dart';
import '../models/supplier.dart';
import '../utils/app_theme.dart';
import '../utils/formatters.dart';
import '../widgets/empty_state.dart';
import '../widgets/glass_widgets.dart';
import 'supplier_detail_screen.dart';

class SuppliersScreen extends StatefulWidget {
  const SuppliersScreen({super.key});

  @override
  State<SuppliersScreen> createState() => _SuppliersScreenState();
}

class _SuppliersScreenState extends State<SuppliersScreen> {
  List<Supplier> _suppliers = [];
  List<Supplier> _filtered = [];
  StoreSettings _settings = StoreSettings();
  bool _isLoading = true;
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadSuppliers();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadSuppliers() async {
    setState(() => _isLoading = true);
    final settings = await DatabaseHelper.getSettings();
    final list = await DatabaseHelper.getSuppliers();

    if (mounted) {
      setState(() {
        _settings = settings;
        _suppliers = list;
        _filterSuppliers();
        _isLoading = false;
      });
    }
  }

  void _filterSuppliers() {
    final q = _searchCtrl.text.trim().toLowerCase();
    setState(() {
      _filtered = _suppliers.where((s) {
        return q.isEmpty ||
            s.name.toLowerCase().contains(q) ||
            (s.phone?.toLowerCase().contains(q) ?? false);
      }).toList();
    });
  }

  double get _totalPayables =>
      _suppliers.fold(0, (sum, s) => sum + s.remainingAmount);

  void _openAddEditDialog([Supplier? supplier]) {
    final nameCtrl = TextEditingController(text: supplier?.name ?? '');
    final phoneCtrl = TextEditingController(text: supplier?.phone ?? '');
    final addrCtrl = TextEditingController(text: supplier?.address ?? '');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.local_shipping_rounded,
                color: Color(0xFF6366F1), size: 22),
            const SizedBox(width: 8),
            Text(supplier == null ? 'Add Supplier' : 'Edit Supplier',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: _dialogInput(
                  'Supplier / Company Name *', Icons.business_rounded),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: phoneCtrl,
              keyboardType: TextInputType.phone,
              decoration:
                  _dialogInput('Phone Number', Icons.phone_outlined),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: addrCtrl,
              decoration: _dialogInput(
                  'Address / Wholesale Market', Icons.location_on_outlined),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
          ModernButton(
            label: 'Save Supplier',
            icon: Icons.check_rounded,
            onPressed: () async {
              final name = nameCtrl.text.trim();
              if (name.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please enter name')));
                return;
              }

              if (supplier == null) {
                final newS = Supplier(
                  name: name,
                  phone: phoneCtrl.text.trim().isNotEmpty
                      ? phoneCtrl.text.trim()
                      : null,
                  address: addrCtrl.text.trim().isNotEmpty
                      ? addrCtrl.text.trim()
                      : null,
                );
                await DatabaseHelper.insertSupplier(newS);
              } else {
                final updatedS = supplier.copyWith(
                  name: name,
                  phone: phoneCtrl.text.trim().isNotEmpty
                      ? phoneCtrl.text.trim()
                      : null,
                  address: addrCtrl.text.trim().isNotEmpty
                      ? addrCtrl.text.trim()
                      : null,
                );
                await DatabaseHelper.updateSupplier(updatedS);
              }

              Navigator.pop(ctx);
              _loadSuppliers();
            },
          ),
        ],
      ),
    );
  }

  static InputDecoration _dialogInput(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: AppColors.primaryLight, size: 18),
      filled: true,
      fillColor: Colors.white.withValues(alpha: 0.8),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.border),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = ResponsiveBreakpoints.isDesktop(context);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('Suppliers & Payables'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh Suppliers',
            onPressed: _loadSuppliers,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openAddEditDialog(),
        backgroundColor: AppColors.primaryLight,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_business_rounded),
        label: const Text('Add Supplier'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      body: Column(
        children: [
          // Total Payables Banner
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: GlassCard(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF6366F1).withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.account_balance_wallet_rounded,
                        color: Color(0xFF6366F1)),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Total Supplier Payables (You Owe)',
                          style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textSecondary),
                        ),
                        Text(
                          Formatters.formatCurrency(
                              _totalPayables, _settings.currency),
                          style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF6366F1)),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFF6366F1).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${_suppliers.where((s) => s.hasOutstandingPayable).length} pending',
                      style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF6366F1),
                          fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Search
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ModernSearchField(
              controller: _searchCtrl,
              hintText: 'Search supplier name or phone...',
              onChanged: (_) => _filterSuppliers(),
              onClear: () => _filterSuppliers(),
            ),
          ),
          const SizedBox(height: 10),

          // List
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                        color: AppColors.primaryLight))
                : _filtered.isEmpty
                    ? EmptyState(
                        icon: Icons.local_shipping_outlined,
                        title: 'No suppliers found',
                        subtitle:
                            'Tap the button below to add a wholesale supplier',
                        actionLabel: 'Add Supplier',
                        onAction: () => _openAddEditDialog(),
                      )
                    : isDesktop
                        ? GridView.builder(
                            padding: const EdgeInsets.all(16),
                            gridDelegate:
                                const SliverGridDelegateWithMaxCrossAxisExtent(
                              maxCrossAxisExtent: 460,
                              mainAxisExtent: 110,
                              crossAxisSpacing: 14,
                              mainAxisSpacing: 14,
                            ),
                            itemCount: _filtered.length,
                            itemBuilder: (context, i) =>
                                _buildSupplierCard(_filtered[i]),
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            itemCount: _filtered.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 10),
                            itemBuilder: (context, i) =>
                                _buildSupplierCard(_filtered[i]),
                          ),
          ),
        ],
      ),
    );
  }

  Widget _buildSupplierCard(Supplier s) {
    return GlassCard(
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => SupplierDetailScreen(supplierId: s.id!)),
        );
        _loadSuppliers();
      },
      padding: const EdgeInsets.all(14),
      border: s.hasOutstandingPayable
          ? Border.all(
              color: AppColors.danger.withValues(alpha: 0.6), width: 1.4)
          : null,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: (s.hasOutstandingPayable
                      ? AppColors.danger
                      : const Color(0xFF6366F1))
                  .withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.local_shipping_rounded,
              color: s.hasOutstandingPayable
                  ? AppColors.danger
                  : const Color(0xFF6366F1),
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  s.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontWeight: FontWeight.w700, fontSize: 14),
                ),
                if (s.phone != null && s.phone!.isNotEmpty)
                  Text(s.phone!,
                      style: const TextStyle(
                          fontSize: 11.5, color: AppColors.textSecondary)),
                if (s.address != null && s.address!.isNotEmpty)
                  Text(s.address!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 11, color: AppColors.textMuted)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (s.hasOutstandingPayable) ...[
                Text(
                  Formatters.formatCurrency(
                      s.remainingAmount, _settings.currency),
                  style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      color: AppColors.danger,
                      fontSize: 14),
                ),
                const Text(
                  'Payable Due',
                  style: TextStyle(
                      color: AppColors.danger,
                      fontSize: 10,
                      fontWeight: FontWeight.bold),
                ),
              ] else ...[
                const StatusBadge(
                  label: 'Settled',
                  color: AppColors.success,
                ),
                const SizedBox(height: 2),
                Text(
                  'Paid: ${Formatters.formatCurrency(s.paidAmount, _settings.currency)}',
                  style: const TextStyle(
                      color: AppColors.textMuted, fontSize: 10),
                ),
              ],
            ],
          ),
          const SizedBox(width: 6),
          const Icon(Icons.chevron_right_rounded,
              color: AppColors.textMuted, size: 20),
        ],
      ),
    );
  }
}
