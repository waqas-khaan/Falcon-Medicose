import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../models/customer.dart';
import '../models/store_settings.dart';
import '../utils/app_theme.dart';
import '../utils/formatters.dart';
import '../widgets/empty_state.dart';
import '../widgets/glass_widgets.dart';
import 'customer_detail_screen.dart';

class CustomersScreen extends StatefulWidget {
  final int initialTabIndex;

  const CustomersScreen({super.key, this.initialTabIndex = 0});

  @override
  State<CustomersScreen> createState() => _CustomersScreenState();
}

class _CustomersScreenState extends State<CustomersScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Customer> _allCustomers = [];
  StoreSettings _settings = StoreSettings();
  bool _isLoading = true;
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
        length: 2, vsync: this, initialIndex: widget.initialTabIndex);
    _tabController.addListener(() {
      if (mounted) setState(() {});
    });
    _loadCustomers();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadCustomers() async {
    setState(() => _isLoading = true);
    final settings = await DatabaseHelper.getSettings();
    final list = await DatabaseHelper.getCustomers();

    if (mounted) {
      setState(() {
        _settings = settings;
        _allCustomers = list;
        _isLoading = false;
      });
    }
  }

  List<Customer> _getFilteredList(String type) {
    final q = _searchCtrl.text.trim().toLowerCase();
    return _allCustomers.where((c) {
      final matchesType = c.customerType == type;
      final matchesQuery = q.isEmpty ||
          c.name.toLowerCase().contains(q) ||
          (c.phone?.toLowerCase().contains(q) ?? false) ||
          (c.companyName?.toLowerCase().contains(q) ?? false);
      return matchesType && matchesQuery;
    }).toList();
  }

  double _calculateOutstanding(String type) {
    return _allCustomers
        .where((c) => c.customerType == type)
        .fold(0.0, (sum, c) => sum + c.remainingAmount);
  }

  void _openAddEditDialog(
      {Customer? customer, String defaultType = CustomerType.retail}) {
    final nameCtrl = TextEditingController(text: customer?.name ?? '');
    final phoneCtrl = TextEditingController(text: customer?.phone ?? '');
    final addrCtrl = TextEditingController(text: customer?.address ?? '');
    final companyCtrl =
        TextEditingController(text: customer?.companyName ?? '');
    String selectedType = customer?.customerType ?? defaultType;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          final isWholesale = selectedType == CustomerType.wholesale;

          return AlertDialog(
            backgroundColor: Colors.white,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Row(
              children: [
                Icon(
                  isWholesale
                      ? Icons.business_rounded
                      : Icons.person_rounded,
                  color: isWholesale
                      ? const Color(0xFF6366F1)
                      : AppColors.primaryLight,
                  size: 22,
                ),
                const SizedBox(width: 8),
                Text(
                  customer == null
                      ? 'New $selectedType Customer'
                      : 'Edit Customer',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Type Switcher
                  SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(
                        value: CustomerType.retail,
                        icon: Icon(Icons.person_outline_rounded, size: 16),
                        label: Text('Retail'),
                      ),
                      ButtonSegment(
                        value: CustomerType.wholesale,
                        icon: Icon(Icons.business_outlined, size: 16),
                        label: Text('Wholesale'),
                      ),
                    ],
                    selected: {selectedType},
                    onSelectionChanged: (set) {
                      setDialogState(() => selectedType = set.first);
                    },
                  ),
                  const SizedBox(height: 14),

                  TextField(
                    controller: nameCtrl,
                    decoration: _dialogInput(
                      isWholesale
                          ? 'Contact Person / Proprietor *'
                          : 'Customer Name *',
                      Icons.badge_outlined,
                    ),
                  ),
                  const SizedBox(height: 10),

                  if (isWholesale) ...[
                    TextField(
                      controller: companyCtrl,
                      decoration: _dialogInput(
                        'Pharmacy / Clinic / Business Name',
                        Icons.store_outlined,
                        hint: 'e.g. Al-Madina Medical Store',
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],

                  TextField(
                    controller: phoneCtrl,
                    keyboardType: TextInputType.phone,
                    decoration: _dialogInput('Phone Number', Icons.phone_outlined),
                  ),
                  const SizedBox(height: 10),

                  TextField(
                    controller: addrCtrl,
                    decoration: _dialogInput(
                      isWholesale
                          ? 'Shop / Clinic Address'
                          : 'Address',
                      Icons.home_outlined,
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancel')),
              ModernButton(
                label: 'Save Customer',
                icon: Icons.check_rounded,
                onPressed: () async {
                  final name = nameCtrl.text.trim();
                  if (name.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Please enter name')));
                    return;
                  }

                  if (customer == null) {
                    final newC = Customer(
                      name: name,
                      phone: phoneCtrl.text.trim().isNotEmpty
                          ? phoneCtrl.text.trim()
                          : null,
                      address: addrCtrl.text.trim().isNotEmpty
                          ? addrCtrl.text.trim()
                          : null,
                      customerType: selectedType,
                      companyName: companyCtrl.text.trim().isNotEmpty
                          ? companyCtrl.text.trim()
                          : null,
                    );
                    await DatabaseHelper.insertCustomer(newC);
                  } else {
                    final updatedC = customer.copyWith(
                      name: name,
                      phone: phoneCtrl.text.trim().isNotEmpty
                          ? phoneCtrl.text.trim()
                          : null,
                      address: addrCtrl.text.trim().isNotEmpty
                          ? addrCtrl.text.trim()
                          : null,
                      customerType: selectedType,
                      companyName: companyCtrl.text.trim().isNotEmpty
                          ? companyCtrl.text.trim()
                          : null,
                    );
                    await DatabaseHelper.updateCustomer(updatedC);
                  }

                  Navigator.pop(ctx);
                  _loadCustomers();
                },
              ),
            ],
          );
        },
      ),
    );
  }

  static InputDecoration _dialogInput(String label, IconData icon,
      {String? hint}) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
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
    final retailOutstanding = _calculateOutstanding(CustomerType.retail);
    final wholesaleOutstanding =
        _calculateOutstanding(CustomerType.wholesale);

    final retailList = _getFilteredList(CustomerType.retail);
    final wholesaleList = _getFilteredList(CustomerType.wholesale);
    final isDesktop = ResponsiveBreakpoints.isDesktop(context);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('Customers & Udhaar Ledger'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh Customers',
            onPressed: _loadCustomers,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          labelStyle:
              const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          tabs: [
            Tab(
              icon: const Icon(Icons.shopping_bag_outlined, size: 17),
              text:
                  'Retail Customers (${_allCustomers.where((c) => c.isRetail).length})',
            ),
            Tab(
              icon: const Icon(Icons.business_outlined, size: 17),
              text:
                  'Wholesale B2B (${_allCustomers.where((c) => c.isWholesale).length})',
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          final isWholesaleTab = _tabController.index == 1;
          _openAddEditDialog(
            defaultType: isWholesaleTab
                ? CustomerType.wholesale
                : CustomerType.retail,
          );
        },
        backgroundColor: AppColors.primaryLight,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.person_add_rounded, size: 21),
        label: Text(
          _tabController.index == 1
              ? 'Add Wholesale Client'
              : 'Add Retail Customer',
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      body: Column(
        children: [
          // Udhaar Overview Cards (Retail vs Wholesale)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                // Retail Udhaar Card
                Expanded(
                  child: GlassCard(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.shopping_bag_outlined,
                                size: 14, color: AppColors.primaryLight),
                            SizedBox(width: 5),
                            Text('Retail Udhaar',
                                style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primaryLight)),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          Formatters.formatCurrency(
                              retailOutstanding, _settings.currency),
                          style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              color: AppColors.primaryLight),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 10),

                // Wholesale Udhaar Card
                Expanded(
                  child: GlassCard(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.business_outlined,
                                size: 14, color: Color(0xFF6366F1)),
                            SizedBox(width: 5),
                            Text('Wholesale Udhaar',
                                style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF6366F1))),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          Formatters.formatCurrency(
                              wholesaleOutstanding, _settings.currency),
                          style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF6366F1)),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Search Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ModernSearchField(
              controller: _searchCtrl,
              hintText: 'Search customer name, phone, or company...',
              onChanged: (_) => setState(() {}),
              onClear: () => setState(() {}),
            ),
          ),
          const SizedBox(height: 10),

          // Tab Views
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                        color: AppColors.primaryLight))
                : TabBarView(
                    controller: _tabController,
                    children: [
                      // Retail Tab
                      _buildCustomerListView(
                        customers: retailList,
                        emptyTitle: 'No retail customers found',
                        emptySubtitle:
                            'Retail customers and walk-in accounts will appear here',
                        isWholesale: false,
                        isDesktop: isDesktop,
                      ),

                      // Wholesale Tab
                      _buildCustomerListView(
                        customers: wholesaleList,
                        emptyTitle: 'No wholesale clients found',
                        emptySubtitle:
                            'Add bulk pharmacies, clinics, and wholesale clients',
                        isWholesale: true,
                        isDesktop: isDesktop,
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomerListView({
    required List<Customer> customers,
    required String emptyTitle,
    required String emptySubtitle,
    required bool isWholesale,
    required bool isDesktop,
  }) {
    if (customers.isEmpty) {
      return EmptyState(
        icon: isWholesale
            ? Icons.business_outlined
            : Icons.people_outline_rounded,
        title: emptyTitle,
        subtitle: emptySubtitle,
        actionLabel:
            isWholesale ? 'Add Wholesale Client' : 'Add Retail Customer',
        onAction: () => _openAddEditDialog(
          defaultType: isWholesale
              ? CustomerType.wholesale
              : CustomerType.retail,
        ),
      );
    }

    if (isDesktop) {
      return GridView.builder(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 88),
        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 460,
          mainAxisExtent: 110,
          crossAxisSpacing: 14,
          mainAxisSpacing: 14,
        ),
        itemCount: customers.length,
        itemBuilder: (context, i) =>
            _buildCustomerCard(customers[i], isWholesale),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 88),
      itemCount: customers.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, i) =>
          _buildCustomerCard(customers[i], isWholesale),
    );
  }

  Widget _buildCustomerCard(Customer c, bool isWholesale) {
    final accentColor =
        isWholesale ? const Color(0xFF6366F1) : AppColors.primaryLight;

    return GlassCard(
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => CustomerDetailScreen(customerId: c.id!)),
        );
        _loadCustomers();
      },
      padding: const EdgeInsets.all(14),
      border: c.hasOutstandingLoan
          ? Border.all(
              color: AppColors.danger.withValues(alpha: 0.6), width: 1.4)
          : null,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: (c.hasOutstandingLoan ? AppColors.danger : accentColor)
                  .withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              isWholesale ? Icons.business_rounded : Icons.person_rounded,
              color: c.hasOutstandingLoan ? AppColors.danger : accentColor,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        c.name,
                        style: const TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 14),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 6),
                    StatusBadge(
                      label: isWholesale ? 'Wholesale' : 'Retail',
                      color: isWholesale
                          ? const Color(0xFF6366F1)
                          : AppColors.primaryLight,
                    ),
                  ],
                ),
                if (c.companyName != null && c.companyName!.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    c.companyName!,
                    style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF4F46E5)),
                  ),
                ],
                if (c.phone != null && c.phone!.isNotEmpty)
                  Text(c.phone!,
                      style: const TextStyle(
                          fontSize: 11.5, color: AppColors.textSecondary)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (c.hasOutstandingLoan) ...[
                Text(
                  Formatters.formatCurrency(
                      c.remainingAmount, _settings.currency),
                  style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      color: AppColors.danger,
                      fontSize: 14),
                ),
                const Text(
                  'Udhaar Due',
                  style: TextStyle(
                      color: AppColors.danger,
                      fontSize: 10,
                      fontWeight: FontWeight.bold),
                ),
              ] else ...[
                const StatusBadge(
                  label: 'No Dues',
                  color: AppColors.success,
                ),
                const SizedBox(height: 2),
                Text(
                  'Paid: ${Formatters.formatCurrency(c.paidAmount, _settings.currency)}',
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
