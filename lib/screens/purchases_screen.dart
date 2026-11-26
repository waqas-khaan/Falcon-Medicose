import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../models/medicine.dart';
import '../models/purchase_invoice.dart';
import '../models/stock_in.dart';
import '../models/store_settings.dart';
import '../models/supplier.dart';
import '../utils/app_theme.dart';
import '../utils/formatters.dart';
import '../widgets/empty_state.dart';
import '../widgets/glass_widgets.dart';

class PurchasesScreen extends StatefulWidget {
  const PurchasesScreen({super.key});

  @override
  State<PurchasesScreen> createState() => _PurchasesScreenState();
}

class _PurchasesScreenState extends State<PurchasesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<PurchaseInvoice> _purchases = [];
  List<StockIn> _stockInHistory = [];
  List<Medicine> _medicines = [];
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
    final purchases = await DatabaseHelper.getPurchaseInvoices();
    final history = await DatabaseHelper.getStockInHistory();
    final medicines = await DatabaseHelper.getMedicines();
    final suppliers = await DatabaseHelper.getSuppliers();

    if (mounted) {
      setState(() {
        _settings = settings;
        _purchases = purchases;
        _stockInHistory = history;
        _medicines = medicines;
        _suppliers = suppliers;
        _isLoading = false;
      });
    }
  }

  void _openQuickStockInDialog() {
    if (_medicines.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one medicine first!')),
      );
      return;
    }

    Medicine selectedMed = _medicines.first;
    Supplier? selectedSupplier =
        _suppliers.isNotEmpty ? _suppliers.first : null;
    final qtyCtrl = TextEditingController(text: '10');
    final priceCtrl = TextEditingController(
        text: selectedMed.buyingPrice > 0
            ? selectedMed.buyingPrice.toStringAsFixed(1)
            : '');
    final batchCtrl = TextEditingController();
    final expiryCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          return AlertDialog(
            backgroundColor: Colors.white,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Row(
              children: [
                Icon(Icons.inventory_rounded,
                    color: AppColors.primaryLight, size: 22),
                SizedBox(width: 8),
                Text('Quick Stock-In',
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<Medicine>(
                    value: selectedMed,
                    decoration: _dialogInputDecor(
                        'Select Medicine', Icons.medication_rounded),
                    items: _medicines.map((m) {
                      return DropdownMenuItem(
                          value: m,
                          child: Text(m.name,
                              style: const TextStyle(fontSize: 13)));
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setDialogState(() {
                          selectedMed = val;
                          if (val.buyingPrice > 0) {
                            priceCtrl.text = val.buyingPrice.toStringAsFixed(1);
                          }
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<Supplier>(
                    value: selectedSupplier,
                    decoration: _dialogInputDecor(
                        'Supplier (Optional)', Icons.local_shipping_rounded),
                    items: [
                      const DropdownMenuItem<Supplier>(
                          value: null, child: Text('None / Walk-in Purchase')),
                      ..._suppliers.map((s) => DropdownMenuItem(
                          value: s,
                          child: Text(s.name,
                              style: const TextStyle(fontSize: 13)))),
                    ],
                    onChanged: (val) =>
                        setDialogState(() => selectedSupplier = val),
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
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: priceCtrl,
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                          decoration: _dialogInputDecor('Cost Price',
                              Icons.payments_outlined),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: batchCtrl,
                          decoration: _dialogInputDecor(
                              'Batch #', Icons.qr_code_rounded),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: expiryCtrl,
                          readOnly: true,
                          decoration: _dialogInputDecor(
                              'Expiry Date', Icons.event_rounded),
                          onTap: () async {
                            final now = DateTime.now();
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: now.add(const Duration(days: 365)),
                              firstDate: now,
                              lastDate: DateTime(2040),
                            );
                            if (picked != null) {
                              setDialogState(() {
                                expiryCtrl.text = Formatters.toDbDate(picked);
                              });
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancel')),
              ModernButton(
                label: 'Add Stock',
                icon: Icons.add_rounded,
                onPressed: () async {
                  final qty = double.tryParse(qtyCtrl.text.trim()) ?? 0.0;
                  final price = double.tryParse(priceCtrl.text.trim()) ??
                      selectedMed.buyingPrice;
                  if (qty <= 0) {
                    ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Quantity must be > 0')));
                    return;
                  }

                  final stockIn = StockIn(
                    medicineId: selectedMed.id!,
                    supplierId: selectedSupplier?.id,
                    quantity: qty,
                    buyingPrice: price,
                    batchNumber: batchCtrl.text.trim().isNotEmpty
                        ? batchCtrl.text.trim()
                        : null,
                    expiryDate: expiryCtrl.text.trim().isNotEmpty
                        ? expiryCtrl.text.trim()
                        : null,
                    purchaseDate:
                        DateTime.now().toIso8601String().substring(0, 10),
                  );

                  await DatabaseHelper.quickStockIn(stockIn);
                  Navigator.pop(ctx);
                  _loadData();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Added $qty ${selectedMed.name} to stock!'),
                      backgroundColor: AppColors.success,
                      behavior: SnackBarBehavior.floating,
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

  void _openMultiItemPurchaseSheet() {
    if (_medicines.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add medicines first!')),
      );
      return;
    }

    Supplier? selectedSupplier =
        _suppliers.isNotEmpty ? _suppliers.first : null;
    final List<Map<String, dynamic>> items = [];
    final paidCtrl = TextEditingController(text: '0');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) {
          double totalAmount = items.fold(
              0,
              (sum, i) =>
                  sum +
                  ((i['quantity'] as double) * (i['buyingPrice'] as double)));
          double paid = double.tryParse(paidCtrl.text.trim()) ?? 0.0;
          double remaining = totalAmount - paid;

          final bottomPadding = MediaQuery.of(context).viewInsets.bottom +
              MediaQuery.of(context).padding.bottom +
              24;

          return Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius:
                  BorderRadius.vertical(top: Radius.circular(24)),
              boxShadow: [
                BoxShadow(
                  color: Color(0x33000000),
                  blurRadius: 24,
                  offset: Offset(0, -6),
                ),
              ],
            ),
            padding: EdgeInsets.only(
              top: 20,
              left: 20,
              right: 20,
              bottom: bottomPadding,
            ),
            constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.9),
            child: SafeArea(
              top: false,
              bottom: true,
              child: SingleChildScrollView(
                padding: const EdgeInsets.only(bottom: 12),
                child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.receipt_long_rounded,
                              color: AppColors.primaryLight, size: 22),
                          SizedBox(width: 8),
                          Text('New Purchase Invoice',
                              style: TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.w800)),
                        ],
                      ),
                      IconButton(
                          icon: const Icon(Icons.close_rounded),
                          onPressed: () => Navigator.pop(ctx)),
                    ],
                  ),
                  const Divider(color: AppColors.borderLight),

                  // Supplier
                  DropdownButtonFormField<Supplier>(
                    value: selectedSupplier,
                    decoration: _dialogInputDecor(
                        'Supplier', Icons.local_shipping_rounded),
                    items: [
                      const DropdownMenuItem<Supplier>(
                          value: null,
                          child: Text('No Supplier / Cash Purchase')),
                      ..._suppliers.map((s) => DropdownMenuItem(
                          value: s, child: Text(s.name))),
                    ],
                    onChanged: (val) =>
                        setSheetState(() => selectedSupplier = val),
                  ),
                  const SizedBox(height: 14),

                  // Add Item Button
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Purchase Items',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 14)),
                      ModernButton(
                        label: 'Add Medicine',
                        icon: Icons.add_rounded,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        onPressed: () {
                          Medicine curMed = _medicines.first;
                          double qty = 10;
                          double price = curMed.buyingPrice > 0
                              ? curMed.buyingPrice
                              : 10;
                          String? batch;
                          String? expiry;

                          showDialog(
                            context: context,
                            builder: (dCtx) => StatefulBuilder(
                              builder: (dCtx, setItemState) {
                                return AlertDialog(
                                  backgroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(18)),
                                  title: const Text('Add Purchase Item'),
                                  content: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      DropdownButtonFormField<Medicine>(
                                        value: curMed,
                                        decoration: _dialogInputDecor(
                                            'Medicine',
                                            Icons.medication_rounded),
                                        items: _medicines
                                            .map((m) => DropdownMenuItem(
                                                value: m,
                                                child: Text(m.name,
                                                    style: const TextStyle(
                                                        fontSize: 13))))
                                            .toList(),
                                        onChanged: (val) {
                                          if (val != null) {
                                            setItemState(() {
                                              curMed = val;
                                              if (val.buyingPrice > 0) {
                                                price = val.buyingPrice;
                                              }
                                            });
                                          }
                                        },
                                      ),
                                      const SizedBox(height: 10),
                                      TextFormField(
                                        initialValue: '$qty',
                                        keyboardType: const TextInputType
                                            .numberWithOptions(decimal: true),
                                        decoration: _dialogInputDecor(
                                            'Quantity', Icons.numbers_rounded),
                                        onChanged: (v) =>
                                            qty = double.tryParse(v) ?? 1,
                                      ),
                                      const SizedBox(height: 10),
                                      TextFormField(
                                        initialValue: '$price',
                                        keyboardType: const TextInputType
                                            .numberWithOptions(decimal: true),
                                        decoration: _dialogInputDecor(
                                            'Buying / Cost Price',
                                            Icons.payments_outlined),
                                        onChanged: (v) =>
                                            price = double.tryParse(v) ?? 0,
                                      ),
                                      const SizedBox(height: 10),
                                      TextFormField(
                                        decoration: _dialogInputDecor(
                                            'Batch Number (Optional)',
                                            Icons.qr_code_rounded),
                                        onChanged: (v) => batch =
                                            v.trim().isNotEmpty
                                                ? v.trim()
                                                : null,
                                      ),
                                    ],
                                  ),
                                  actions: [
                                    TextButton(
                                        onPressed: () => Navigator.pop(dCtx),
                                        child: const Text('Cancel')),
                                    ModernButton(
                                      label: 'Add to Invoice',
                                      onPressed: () {
                                        setSheetState(() {
                                          items.add({
                                            'medicine': curMed,
                                            'quantity': qty,
                                            'buyingPrice': price,
                                            'batch': batch,
                                            'expiry': expiry,
                                          });
                                          paidCtrl.text = items
                                              .fold<double>(
                                                  0,
                                                  (sum, i) =>
                                                      sum +
                                                      ((i['quantity']
                                                              as double) *
                                                          (i['buyingPrice']
                                                              as double)))
                                              .toStringAsFixed(0);
                                        });
                                        Navigator.pop(dCtx);
                                      },
                                    ),
                                  ],
                                );
                              },
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  if (items.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(24),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: const Text(
                          'No items added yet. Tap "Add Medicine"',
                          style: TextStyle(color: AppColors.textMuted)),
                    )
                  else
                    ...items.map((it) {
                      final m = it['medicine'] as Medicine;
                      final q = it['quantity'] as double;
                      final p = it['buyingPrice'] as double;
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(m.name,
                            style:
                                const TextStyle(fontWeight: FontWeight.w600)),
                        subtitle: Text(
                            '${q.toInt()} units @ ${Formatters.formatCurrency(p, _settings.currency)}'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                                Formatters.formatCurrency(
                                    q * p, _settings.currency),
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold)),
                            IconButton(
                              icon: const Icon(Icons.close_rounded,
                                  size: 16, color: AppColors.danger),
                              onPressed: () {
                                setSheetState(() {
                                  items.remove(it);
                                  paidCtrl.text = items
                                      .fold<double>(
                                          0,
                                          (sum, i) =>
                                              sum +
                                              ((i['quantity'] as double) *
                                                  (i['buyingPrice'] as double)))
                                      .toStringAsFixed(0);
                                });
                              },
                            ),
                          ],
                        ),
                      );
                    }),

                  const SizedBox(height: 14),
                  const Divider(color: AppColors.borderLight),

                  // Financials
                  TextField(
                    controller: paidCtrl,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: _dialogInputDecor(
                        'Amount Paid to Supplier', Icons.payments_outlined),
                    onChanged: (_) => setSheetState(() {}),
                  ),
                  const SizedBox(height: 12),

                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Total Invoice Amount:',
                                style: TextStyle(fontWeight: FontWeight.bold)),
                            Text(
                              Formatters.formatCurrency(
                                  totalAmount, _settings.currency),
                              style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.primaryLight),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              remaining > 0
                                  ? 'Payable (You Owe):'
                                  : 'Status:',
                              style: TextStyle(
                                color: remaining > 0
                                    ? AppColors.danger
                                    : AppColors.success,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              remaining > 0
                                  ? Formatters.formatCurrency(
                                      remaining, _settings.currency)
                                  : 'Paid in Full',
                              style: TextStyle(
                                color: remaining > 0
                                    ? AppColors.danger
                                    : AppColors.success,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  ModernButton(
                    label: 'Save Purchase Invoice',
                    icon: Icons.check_circle_outline_rounded,
                    onPressed: items.isEmpty
                        ? null
                        : () async {
                            final stockInItems = items.map((it) {
                              final m = it['medicine'] as Medicine;
                              return StockIn(
                                medicineId: m.id!,
                                supplierId: selectedSupplier?.id,
                                quantity: it['quantity'] as double,
                                buyingPrice: it['buyingPrice'] as double,
                                batchNumber: it['batch'] as String?,
                                expiryDate: it['expiry'] as String?,
                                purchaseDate: DateTime.now()
                                    .toIso8601String()
                                    .substring(0, 10),
                              );
                            }).toList();

                            final invoice = PurchaseInvoice(
                              supplierId: selectedSupplier?.id,
                              supplierNameSnapshot: selectedSupplier?.name,
                              totalAmount: totalAmount,
                              paidAmount: paid,
                              remainingAmount: remaining > 0 ? remaining : 0.0,
                              purchaseDate: DateTime.now().toIso8601String(),
                              items: stockInItems,
                            );

                            await DatabaseHelper.createPurchaseInvoice(invoice);
                            Navigator.pop(ctx);
                            _loadData();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                    'Purchase invoice recorded successfully!'),
                                backgroundColor: AppColors.success,
                              ),
                            );
                          },
                    width: double.infinity,
                  ),
                ],
              ),
            ),
          ),
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
        title: const Text('Purchases & Stock In'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold),
          tabs: const [
            Tab(text: 'Purchase Invoices'),
            Tab(text: 'Stock-In History'),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openQuickStockInDialog,
        backgroundColor: AppColors.primaryLight,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Quick Stock-In'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primaryLight))
          : TabBarView(
              controller: _tabController,
              children: [
                // Invoices tab
                Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                      child: GlassCard(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${_purchases.length} Purchase Invoices',
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 13.5),
                            ),
                            ModernButton(
                              label: 'New Purchase Cart',
                              icon: Icons.receipt_long_rounded,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 8),
                              onPressed: _openMultiItemPurchaseSheet,
                            ),
                          ],
                        ),
                      ),
                    ),
                    Expanded(
                      child: _purchases.isEmpty
                          ? EmptyState(
                              icon: Icons.add_business_outlined,
                              title: 'No purchase invoices yet',
                              subtitle:
                                  'Create a new purchase invoice or add a quick stock-in',
                              actionLabel: 'New Purchase',
                              onAction: _openMultiItemPurchaseSheet,
                            )
                          : isDesktop
                              ? GridView.builder(
                                  padding: const EdgeInsets.all(16),
                                  gridDelegate:
                                      const SliverGridDelegateWithMaxCrossAxisExtent(
                                    maxCrossAxisExtent: 460,
                                    mainAxisExtent: 155,
                                    crossAxisSpacing: 14,
                                    mainAxisSpacing: 14,
                                  ),
                                  itemCount: _purchases.length,
                                  itemBuilder: (context, i) =>
                                      _buildPurchaseCard(_purchases[i]),
                                )
                              : ListView.separated(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 8),
                                  itemCount: _purchases.length,
                                  separatorBuilder: (_, __) =>
                                      const SizedBox(height: 10),
                                  itemBuilder: (context, i) =>
                                      _buildPurchaseCard(_purchases[i]),
                                ),
                    ),
                  ],
                ),

                // History tab
                _stockInHistory.isEmpty
                    ? const EmptyState(
                        icon: Icons.history_rounded,
                        title: 'No stock-in history yet',
                        subtitle: 'Added stock entries will appear here',
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: _stockInHistory.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (context, i) {
                          final s = _stockInHistory[i];
                          return GlassCard(
                            padding: const EdgeInsets.all(12),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: AppColors.primaryLight
                                        .withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(
                                      Icons.arrow_downward_rounded,
                                      color: AppColors.primaryLight,
                                      size: 20),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        s.medicineName ??
                                            'Medicine #${s.medicineId}',
                                        style: const TextStyle(
                                            fontWeight: FontWeight.w700,
                                            fontSize: 13),
                                      ),
                                      Text(
                                        '${s.supplierName ?? "No Supplier"} • ${Formatters.formatShortDate(s.purchaseDate)}',
                                        style: const TextStyle(
                                            color: AppColors.textSecondary,
                                            fontSize: 11),
                                      ),
                                    ],
                                  ),
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      '+${s.quantity.toInt()} units',
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.success,
                                          fontSize: 13),
                                    ),
                                    Text(
                                      'Cost: ${Formatters.formatCurrency(s.buyingPrice, _settings.currency)}',
                                      style: const TextStyle(
                                          fontSize: 11,
                                          color: AppColors.textMuted),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ],
            ),
    );
  }

  Widget _buildPurchaseCard(PurchaseInvoice p) {
    return GlassCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Purchase #${p.id} • ${p.supplierNameSnapshot ?? "Cash Purchase"}',
                style:
                    const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
              ),
              Text(
                Formatters.formatShortDate(p.purchaseDate),
                style:
                    const TextStyle(color: AppColors.textMuted, fontSize: 11),
              ),
            ],
          ),
          Text(
            '${p.items.length} items purchased',
            style:
                const TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
          const Divider(height: 8, color: AppColors.borderLight),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total: ${Formatters.formatCurrency(p.totalAmount, _settings.currency)}',
                style: const TextStyle(
                    fontWeight: FontWeight.w800, color: AppColors.primaryLight),
              ),
              if (p.hasRemainingPayable)
                StatusBadge(
                  label:
                      'Due: ${Formatters.formatCurrency(p.remainingAmount, _settings.currency)}',
                  color: AppColors.danger,
                )
              else
                const StatusBadge(
                  label: 'Paid in Full',
                  color: AppColors.success,
                ),
            ],
          ),
        ],
      ),
    );
  }
}
