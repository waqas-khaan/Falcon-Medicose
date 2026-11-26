import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../models/customer.dart';
import '../models/customer_return.dart';
import '../models/medicine.dart';
import '../models/store_settings.dart';
import '../models/supplier.dart';
import '../models/supplier_return.dart';
import '../utils/app_theme.dart';
import '../utils/formatters.dart';
import '../widgets/empty_state.dart';
import '../widgets/glass_widgets.dart';

class ReturnsScreen extends StatefulWidget {
  const ReturnsScreen({super.key});

  @override
  State<ReturnsScreen> createState() => _ReturnsScreenState();
}

class _ReturnsScreenState extends State<ReturnsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<CustomerReturn> _customerReturns = [];
  List<SupplierReturn> _supplierReturns = [];
  List<Medicine> _medicines = [];
  List<Customer> _customers = [];
  List<Supplier> _suppliers = [];
  StoreSettings _settings = StoreSettings();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final settings = await DatabaseHelper.getSettings();
    final cRet = await DatabaseHelper.getCustomerReturns();
    final sRet = await DatabaseHelper.getSupplierReturns();
    final meds = await DatabaseHelper.getMedicines();
    final custs = await DatabaseHelper.getCustomers();
    final sups = await DatabaseHelper.getSuppliers();

    if (mounted) {
      setState(() {
        _settings = settings;
        _customerReturns = cRet;
        _supplierReturns = sRet;
        _medicines = meds;
        _customers = custs;
        _suppliers = sups;
        _isLoading = false;
      });
    }
  }

  void _openNewCustomerReturnDialog() {
    if (_medicines.isEmpty) return;
    Medicine selectedMed = _medicines.first;
    Customer? selectedCust =
        _customers.isNotEmpty ? _customers.first : null;
    final qtyCtrl = TextEditingController(text: '1');
    final refundCtrl = TextEditingController(
        text: selectedMed.sellingPrice.toStringAsFixed(0));
    final reasonCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          return AlertDialog(
            backgroundColor: Colors.white,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Text('Customer Return (Sales Return)',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<Medicine>(
                    value: selectedMed,
                    decoration: _dialogInputDecor(
                        'Medicine *', Icons.medication_rounded),
                    items: _medicines
                        .map((m) => DropdownMenuItem(
                            value: m,
                            child: Text(m.name,
                                style: const TextStyle(fontSize: 13))))
                        .toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setDialogState(() {
                          selectedMed = val;
                          final q = double.tryParse(qtyCtrl.text) ?? 1;
                          refundCtrl.text =
                              (q * val.sellingPrice).toStringAsFixed(0);
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<Customer>(
                    value: selectedCust,
                    decoration: _dialogInputDecor(
                        'Customer (Optional)', Icons.person_outline_rounded),
                    items: [
                      const DropdownMenuItem<Customer>(
                          value: null, child: Text('Walk-in Customer')),
                      ..._customers.map((c) => DropdownMenuItem(
                          value: c,
                          child: Text(c.name,
                              style: const TextStyle(fontSize: 13)))),
                    ],
                    onChanged: (val) =>
                        setDialogState(() => selectedCust = val),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: qtyCtrl,
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                          decoration: _dialogInputDecor(
                              'Quantity *', Icons.numbers_rounded),
                          onChanged: (v) {
                            final q = double.tryParse(v) ?? 0;
                            refundCtrl.text =
                                (q * selectedMed.sellingPrice).toStringAsFixed(0);
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: refundCtrl,
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                          decoration: _dialogInputDecor(
                              'Refund Amount', Icons.payments_outlined),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: reasonCtrl,
                    decoration: _dialogInputDecor(
                        'Reason (e.g. Expired, Not Needed, Wrong item)',
                        Icons.comment_outlined),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancel')),
              ModernButton(
                label: 'Process Return',
                onPressed: () async {
                  final qty = double.tryParse(qtyCtrl.text.trim()) ?? 0;
                  final refund = double.tryParse(refundCtrl.text.trim()) ?? 0;
                  if (qty <= 0) {
                    ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Quantity must be > 0')));
                    return;
                  }

                  final cr = CustomerReturn(
                    medicineId: selectedMed.id!,
                    customerId: selectedCust?.id,
                    customerNameSnapshot:
                        selectedCust?.name ?? 'Walk-in Customer',
                    quantity: qty,
                    refundAmount: refund,
                    buyingPriceSnapshot: selectedMed.buyingPrice,
                    reason: reasonCtrl.text.trim().isNotEmpty
                        ? reasonCtrl.text.trim()
                        : null,
                    returnDate: DateTime.now().toIso8601String(),
                  );

                  await DatabaseHelper.createCustomerReturn(cr);
                  Navigator.pop(ctx);
                  _loadData();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content:
                          Text('Returned $qty ${selectedMed.name} to stock!'),
                      backgroundColor: AppColors.success,
                    ),
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }

  void _openNewSupplierReturnDialog() {
    if (_medicines.isEmpty) return;
    Medicine selectedMed = _medicines.first;
    Supplier? selectedSup =
        _suppliers.isNotEmpty ? _suppliers.first : null;
    final qtyCtrl = TextEditingController(text: '1');
    final creditCtrl = TextEditingController(
        text: selectedMed.buyingPrice.toStringAsFixed(0));
    final reasonCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          return AlertDialog(
            backgroundColor: Colors.white,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Text('Supplier Return (Purchase Return)',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<Medicine>(
                    value: selectedMed,
                    decoration: _dialogInputDecor(
                        'Medicine *', Icons.medication_rounded),
                    items: _medicines.map((m) {
                      return DropdownMenuItem(
                        value: m,
                        child: Text(
                            '${m.name} (Stock: ${m.currentStock.toInt()})',
                            style: const TextStyle(fontSize: 13)),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setDialogState(() {
                          selectedMed = val;
                          final q = double.tryParse(qtyCtrl.text) ?? 1;
                          creditCtrl.text =
                              (q * val.buyingPrice).toStringAsFixed(0);
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<Supplier>(
                    value: selectedSup,
                    decoration: _dialogInputDecor(
                        'Supplier (Optional)', Icons.local_shipping_rounded),
                    items: [
                      const DropdownMenuItem<Supplier>(
                          value: null, child: Text('No Supplier')),
                      ..._suppliers.map((s) => DropdownMenuItem(
                          value: s,
                          child: Text(s.name,
                              style: const TextStyle(fontSize: 13)))),
                    ],
                    onChanged: (val) =>
                        setDialogState(() => selectedSup = val),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: qtyCtrl,
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                          decoration: _dialogInputDecor(
                              'Quantity *', Icons.numbers_rounded),
                          onChanged: (v) {
                            final q = double.tryParse(v) ?? 0;
                            creditCtrl.text =
                                (q * selectedMed.buyingPrice).toStringAsFixed(0);
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: creditCtrl,
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                          decoration: _dialogInputDecor(
                              'Credit Amount', Icons.payments_outlined),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: reasonCtrl,
                    decoration: _dialogInputDecor(
                        'Reason (e.g. Expired, Damaged packaging)',
                        Icons.comment_outlined),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancel')),
              ModernButton(
                label: 'Return to Supplier',
                onPressed: () async {
                  final qty = double.tryParse(qtyCtrl.text.trim()) ?? 0;
                  final credit = double.tryParse(creditCtrl.text.trim()) ?? 0;
                  if (qty <= 0) {
                    ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Quantity must be > 0')));
                    return;
                  }
                  if (selectedMed.currentStock < qty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                          content: Text(
                              'Insufficient stock: only ${selectedMed.currentStock.toInt()} available')),
                    );
                    return;
                  }

                  final sr = SupplierReturn(
                    medicineId: selectedMed.id!,
                    supplierId: selectedSup?.id,
                    supplierNameSnapshot: selectedSup?.name,
                    quantity: qty,
                    creditAmount: credit,
                    reason: reasonCtrl.text.trim().isNotEmpty
                        ? reasonCtrl.text.trim()
                        : null,
                    returnDate: DateTime.now().toIso8601String(),
                  );

                  await DatabaseHelper.createSupplierReturn(sr);
                  Navigator.pop(ctx);
                  _loadData();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content:
                          Text('Returned $qty ${selectedMed.name} to supplier!'),
                      backgroundColor: AppColors.success,
                    ),
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }

  static InputDecoration _dialogInputDecor(String label, IconData icon) {
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
        title: const Text('Returns & Adjustments'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold),
          tabs: [
            Tab(text: 'Customer Returns (${_customerReturns.length})'),
            Tab(text: 'Supplier Returns (${_supplierReturns.length})'),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          if (_tabController.index == 0) {
            _openNewCustomerReturnDialog();
          } else {
            _openNewSupplierReturnDialog();
          }
        },
        backgroundColor: AppColors.primaryLight,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: Text(_tabController.index == 0
            ? 'Customer Return'
            : 'Supplier Return'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primaryLight))
          : TabBarView(
              controller: _tabController,
              children: [
                // Customer Returns List
                _customerReturns.isEmpty
                    ? EmptyState(
                        icon: Icons.assignment_return_outlined,
                        title: 'No customer returns yet',
                        subtitle:
                            'Tap the button below to process a customer return',
                        actionLabel: 'New Customer Return',
                        onAction: _openNewCustomerReturnDialog,
                      )
                    : isDesktop
                        ? GridView.builder(
                            padding: const EdgeInsets.all(16),
                            gridDelegate:
                                const SliverGridDelegateWithMaxCrossAxisExtent(
                              maxCrossAxisExtent: 460,
                              mainAxisExtent: 115,
                              crossAxisSpacing: 14,
                              mainAxisSpacing: 14,
                            ),
                            itemCount: _customerReturns.length,
                            itemBuilder: (context, i) =>
                                _buildCustomerReturnCard(_customerReturns[i]),
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 10),
                            itemCount: _customerReturns.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 10),
                            itemBuilder: (context, i) =>
                                _buildCustomerReturnCard(_customerReturns[i]),
                          ),

                // Supplier Returns List
                _supplierReturns.isEmpty
                    ? EmptyState(
                        icon: Icons.assignment_return_outlined,
                        title: 'No supplier returns yet',
                        subtitle:
                            'Tap the button below to return defective or expired items to supplier',
                        actionLabel: 'New Supplier Return',
                        onAction: _openNewSupplierReturnDialog,
                      )
                    : isDesktop
                        ? GridView.builder(
                            padding: const EdgeInsets.all(16),
                            gridDelegate:
                                const SliverGridDelegateWithMaxCrossAxisExtent(
                              maxCrossAxisExtent: 460,
                              mainAxisExtent: 115,
                              crossAxisSpacing: 14,
                              mainAxisSpacing: 14,
                            ),
                            itemCount: _supplierReturns.length,
                            itemBuilder: (context, i) =>
                                _buildSupplierReturnCard(_supplierReturns[i]),
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 10),
                            itemCount: _supplierReturns.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 10),
                            itemBuilder: (context, i) =>
                                _buildSupplierReturnCard(_supplierReturns[i]),
                          ),
              ],
            ),
    );
  }

  Widget _buildCustomerReturnCard(CustomerReturn cr) {
    return GlassCard(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.primaryLight.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.keyboard_return_rounded,
                color: AppColors.primaryLight, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  cr.medicineName ?? 'Medicine #${cr.medicineId}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontWeight: FontWeight.w700, fontSize: 13.5),
                ),
                Text(
                  'From: ${cr.customerNameSnapshot ?? "Walk-in"} • ${Formatters.formatShortDate(cr.returnDate)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: 11.5, color: AppColors.textSecondary),
                ),
                if (cr.reason != null && cr.reason!.isNotEmpty)
                  Text(
                    'Reason: ${cr.reason}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 10.5,
                        color: AppColors.textMuted,
                        fontStyle: FontStyle.italic),
                  ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '+${cr.quantity.toInt()} to Stock',
                style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.success,
                    fontSize: 12.5),
              ),
              const SizedBox(height: 2),
              Text(
                'Refund: ${Formatters.formatCurrency(cr.refundAmount, _settings.currency)}',
                style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.bold,
                    color: AppColors.danger),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSupplierReturnCard(SupplierReturn sr) {
    return GlassCard(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.danger.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.arrow_upward_rounded,
                color: AppColors.danger, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  sr.medicineName ?? 'Medicine #${sr.medicineId}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontWeight: FontWeight.w700, fontSize: 13.5),
                ),
                Text(
                  'To: ${sr.supplierNameSnapshot ?? "Supplier"} • ${Formatters.formatShortDate(sr.returnDate)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: 11.5, color: AppColors.textSecondary),
                ),
                if (sr.reason != null && sr.reason!.isNotEmpty)
                  Text(
                    'Reason: ${sr.reason}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 10.5,
                        color: AppColors.textMuted,
                        fontStyle: FontStyle.italic),
                  ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '-${sr.quantity.toInt()} from Stock',
                style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.danger,
                    fontSize: 12.5),
              ),
              const SizedBox(height: 2),
              Text(
                'Credit: ${Formatters.formatCurrency(sr.creditAmount, _settings.currency)}',
                style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryLight),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
