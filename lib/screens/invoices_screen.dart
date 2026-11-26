import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../models/invoice.dart';
import '../models/store_settings.dart';
import '../utils/app_theme.dart';
import '../utils/formatters.dart';
import '../widgets/empty_state.dart';
import '../widgets/glass_widgets.dart';
import '../widgets/thermal_receipt_dialog.dart';

class InvoicesScreen extends StatefulWidget {
  const InvoicesScreen({super.key});

  @override
  State<InvoicesScreen> createState() => _InvoicesScreenState();
}

class _InvoicesScreenState extends State<InvoicesScreen> {
  List<Invoice> _invoices = [];
  List<Invoice> _filtered = [];
  StoreSettings _settings = StoreSettings();
  bool _isLoading = true;
  String _selectedFilter = 'ALL'; // ALL, PAID, DUE, WHOLESALE, RETAIL
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadInvoices();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadInvoices() async {
    setState(() => _isLoading = true);
    final settings = await DatabaseHelper.getSettings();
    final list = await DatabaseHelper.getInvoices(limit: 150);

    if (mounted) {
      setState(() {
        _settings = settings;
        _invoices = list;
        _filterInvoices();
        _isLoading = false;
      });
    }
  }

  void _filterInvoices() {
    final q = _searchCtrl.text.trim().toLowerCase();
    setState(() {
      _filtered = _invoices.where((inv) {
        final matchesQuery = q.isEmpty ||
            (inv.customerName?.toLowerCase().contains(q) ?? false) ||
            (inv.id?.toString().contains(q) ?? false) ||
            (inv.doctorName?.toLowerCase().contains(q) ?? false);

        bool matchesFilter = true;
        if (_selectedFilter == 'PAID') {
          matchesFilter = !inv.hasRemainingBalance;
        } else if (_selectedFilter == 'DUE') {
          matchesFilter = inv.hasRemainingBalance;
        } else if (_selectedFilter == 'WHOLESALE') {
          matchesFilter = inv.isWholesale;
        } else if (_selectedFilter == 'RETAIL') {
          matchesFilter = !inv.isWholesale;
        }

        return matchesQuery && matchesFilter;
      }).toList();
    });
  }

  double get _totalBilled =>
      _invoices.fold(0, (sum, i) => sum + i.totalAmount);
  double get _totalDue =>
      _invoices.fold(0, (sum, i) => sum + i.remainingAmount);

  @override
  Widget build(BuildContext context) {
    final isDesktop = ResponsiveBreakpoints.isDesktop(context);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('Sales Invoices & Receipts'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh Invoices',
            onPressed: _loadInvoices,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primaryLight))
          : Column(
              children: [
                // Top Metric & Filter Bar
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Column(
                    children: [
                      // KPI Summary strip
                      Row(
                        children: [
                          Expanded(
                            child: _buildMetricPill(
                              'Total Invoices',
                              '${_invoices.length}',
                              Icons.receipt_long_rounded,
                              AppColors.primaryLight,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _buildMetricPill(
                              'Billed Volume',
                              Formatters.formatCurrency(
                                  _totalBilled, _settings.currency),
                              Icons.payments_rounded,
                              AppColors.secondary,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _buildMetricPill(
                              'Unpaid Due',
                              Formatters.formatCurrency(
                                  _totalDue, _settings.currency),
                              Icons.pending_actions_rounded,
                              AppColors.danger,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),

                      // Search & Quick Filter Pills
                      GlassCard(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          children: [
                            ModernSearchField(
                              controller: _searchCtrl,
                              hintText:
                                  'Search invoice #, customer name, doctor...',
                              onChanged: (_) => _filterInvoices(),
                              onClear: () => _filterInvoices(),
                            ),
                            const SizedBox(height: 8),
                            SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: [
                                  _buildFilterChip('ALL', 'All Invoices'),
                                  _buildFilterChip('PAID', 'Fully Paid'),
                                  _buildFilterChip('DUE', 'With Due Balance'),
                                  _buildFilterChip('RETAIL', 'Retail Sales'),
                                  _buildFilterChip(
                                      'WHOLESALE', 'Wholesale Consignments'),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Invoices List / Grid
                Expanded(
                  child: _filtered.isEmpty
                      ? const EmptyState(
                          icon: Icons.receipt_long_outlined,
                          title: 'No invoices found',
                          subtitle:
                              'Completed sales from POS will show up here',
                        )
                      : isDesktop
                          ? GridView.builder(
                              padding: const EdgeInsets.all(16),
                              gridDelegate:
                                  const SliverGridDelegateWithMaxCrossAxisExtent(
                                maxCrossAxisExtent: 480,
                                mainAxisExtent: 175,
                                crossAxisSpacing: 14,
                                mainAxisSpacing: 14,
                              ),
                              itemCount: _filtered.length,
                              itemBuilder: (context, i) =>
                                  _buildInvoiceCard(_filtered[i]),
                            )
                          : ListView.separated(
                              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                              itemCount: _filtered.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(height: 10),
                              itemBuilder: (context, i) =>
                                  _buildInvoiceCard(_filtered[i]),
                            ),
                ),
              ],
            ),
    );
  }

  Widget _buildMetricPill(
      String label, String value, IconData icon, Color color) {
    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 10.5,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String key, String label) {
    final isSelected = _selectedFilter == key;
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: ChoiceChip(
        label: Text(label),
        selected: isSelected,
        selectedColor: AppColors.primaryLight,
        backgroundColor: Colors.white.withValues(alpha: 0.7),
        labelStyle: TextStyle(
          fontSize: 11.5,
          fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
          color: isSelected ? Colors.white : AppColors.textPrimary,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: isSelected
                ? AppColors.primaryLight
                : AppColors.border.withValues(alpha: 0.8),
          ),
        ),
        onSelected: (_) {
          setState(() {
            _selectedFilter = key;
            _filterInvoices();
          });
        },
      ),
    );
  }

  Widget _buildInvoiceCard(Invoice inv) {
    return GlassCard(
      onTap: () => ThermalReceiptDialog.show(context, inv, _settings),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Top Row: Invoice # and Date
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(
                    'Invoice #${inv.id ?? "N/A"}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 14.5,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  StatusBadge(
                    label: inv.isWholesale ? 'Wholesale' : 'Retail',
                    color: inv.isWholesale
                        ? const Color(0xFF6366F1)
                        : AppColors.primaryLight,
                  ),
                ],
              ),
              Text(
                Formatters.formatDateTime(inv.invoiceDate),
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textMuted,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),

          // Middle Row: Customer and Doctor
          Row(
            children: [
              const Icon(Icons.person_outline_rounded,
                  size: 15, color: AppColors.textSecondary),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  inv.customerName ?? 'Walk-in Customer',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (inv.doctorName != null && inv.doctorName!.isNotEmpty) ...[
                const SizedBox(width: 6),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceSubtle,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'Dr. ${inv.doctorName}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ],
          ),

          // Items summary snippet
          Text(
            '${inv.items.length} item${inv.items.length > 1 ? "s" : ""} • ${inv.items.map((e) => e.medicineName).take(2).join(", ")}${inv.items.length > 2 ? "..." : ""}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 11.5,
              color: AppColors.textSecondary,
            ),
          ),

          const Divider(height: 8, color: AppColors.borderLight),

          // Bottom Row: Total, Due Badge, and Print Action
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(
                    'Total: ${Formatters.formatCurrency(inv.totalAmount, _settings.currency)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      color: AppColors.primaryLight,
                      fontSize: 14,
                    ),
                  ),
                  if (inv.discount > 0) ...[
                    const SizedBox(width: 6),
                    Text(
                      '(-${inv.discount.toInt()})',
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ],
              ),
              Row(
                children: [
                  if (inv.hasRemainingBalance)
                    StatusBadge(
                      label:
                          'Due: ${Formatters.formatCurrency(inv.remainingAmount, _settings.currency)}',
                      color: AppColors.danger,
                      icon: Icons.error_outline_rounded,
                    )
                  else
                    const StatusBadge(
                      label: 'Paid',
                      color: AppColors.success,
                      icon: Icons.check_circle_outline_rounded,
                    ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.print_rounded,
                        size: 20, color: AppColors.primaryLight),
                    tooltip: 'Print Thermal Receipt',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () =>
                        ThermalReceiptDialog.show(context, inv, _settings),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
