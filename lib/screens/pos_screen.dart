import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../models/customer.dart';
import '../models/invoice.dart';
import '../models/invoice_item.dart';
import '../models/medicine.dart';
import '../models/store_settings.dart';
import '../utils/app_theme.dart';
import '../utils/constants.dart';
import '../utils/formatters.dart';
import '../widgets/empty_state.dart';
import '../widgets/glass_widgets.dart';
import '../widgets/thermal_receipt_dialog.dart';

class PosItem {
  final Medicine medicine;
  double quantity;
  double unitPrice;
  double discountPercent;

  PosItem({
    required this.medicine,
    this.quantity = 1,
    double? unitPrice,
    double? discountPercent,
  })  : unitPrice = unitPrice ?? medicine.sellingPrice,
        discountPercent = discountPercent ?? 0.0;

  double get lineTotal {
    final base = quantity * unitPrice;
    if (discountPercent > 0) {
      return base - (base * (discountPercent / 100));
    }
    return base;
  }
}

class PosScreen extends StatefulWidget {
  const PosScreen({super.key});

  @override
  State<PosScreen> createState() => _PosScreenState();
}

class _PosScreenState extends State<PosScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  List<Medicine> _medicines = [];
  List<Customer> _customers = [];
  StoreSettings _settings = StoreSettings();
  String _selectedCategory = 'All';

  final Map<int, PosItem> _cart = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final settings = await DatabaseHelper.getSettings();
    final meds = await DatabaseHelper.getMedicines();
    final customers = await DatabaseHelper.getCustomers();

    if (mounted) {
      setState(() {
        _settings = settings;
        _medicines = meds;
        _customers = customers;
        _isLoading = false;
      });
    }
  }

  List<Medicine> get _filteredMedicines {
    final q = _searchCtrl.text.trim().toLowerCase();
    return _medicines.where((m) {
      final matchesCat =
          _selectedCategory == 'All' || m.category == _selectedCategory;
      final matchesQuery = q.isEmpty ||
          m.name.toLowerCase().contains(q) ||
          (m.companyName?.toLowerCase().contains(q) ?? false);
      return matchesCat && matchesQuery;
    }).toList();
  }

  void _addToCart(Medicine med) {
    if (med.isOutOfStock) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${med.name} is Out of Stock!'),
          backgroundColor: AppColors.danger,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() {
      if (_cart.containsKey(med.id)) {
        if (_cart[med.id]!.quantity < med.currentStock) {
          _cart[med.id]!.quantity += 1;
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  'Cannot exceed available stock of ${med.currentStock.toInt()}'),
              backgroundColor: AppColors.warning,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } else {
        _cart[med.id!] = PosItem(
          medicine: med,
          quantity: 1,
          unitPrice: med.sellingPrice,
          discountPercent: 0,
        );
      }
    });
  }

  void _removeFromCart(int medId) {
    setState(() {
      _cart.remove(medId);
    });
  }

  void _clearCart() {
    setState(() {
      _cart.clear();
    });
  }

  double get _cartTotal {
    return _cart.values.fold(0, (sum, i) => sum + i.lineTotal);
  }

  void _openCheckoutSheet() {
    if (_cart.isEmpty) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _CheckoutModal(
        cart: _cart,
        customers: _customers,
        settings: _settings,
        onCartUpdated: () => setState(() {}),
        onSaleCompleted: (createdInvoice) {
          _clearCart();
          _loadData();
          ThermalReceiptDialog.show(context, createdInvoice, _settings);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredMedicines;
    final isDesktop = ResponsiveBreakpoints.isDesktop(context);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('Falcon POS Terminal'),
        actions: [
          if (_cart.isNotEmpty) ...[
            Center(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  gradient: AppColors.primaryActionGradient,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primaryLight.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(
                  '${_cart.length} in cart',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.delete_sweep_rounded),
              tooltip: 'Clear Cart',
              onPressed: _clearCart,
            ),
          ],
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primaryLight))
          : isDesktop
              ? _buildDesktopLayout(filtered)
              : _buildMobileLayout(filtered),
    );
  }

  Widget _buildDesktopLayout(List<Medicine> filtered) {
    return Padding(
      padding: const EdgeInsets.all(18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left: Catalog and Filters
          Expanded(
            flex: 3,
            child: Column(
              children: [
                _buildSearchAndFilterBar(),
                const SizedBox(height: 14),
                Expanded(
                  child: filtered.isEmpty
                      ? const EmptyState(
                          icon: Icons.medication_outlined,
                          title: 'No medicines matched',
                          subtitle:
                              'Try searching by brand name or adjust filters',
                        )
                      : GridView.builder(
                          padding: const EdgeInsets.only(bottom: 20),
                          gridDelegate:
                              const SliverGridDelegateWithMaxCrossAxisExtent(
                            maxCrossAxisExtent: 380,
                            mainAxisExtent: 140,
                            crossAxisSpacing: 14,
                            mainAxisSpacing: 14,
                          ),
                          itemCount: filtered.length,
                          itemBuilder: (context, i) =>
                              _buildMedicineCard(filtered[i]),
                        ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 18),

          // Right: Real-time Cart & Checkout Panel
          SizedBox(
            width: 400,
            child: _cart.isEmpty
                ? GlassCard(
                    padding: const EdgeInsets.all(24),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(18),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color:
                                  AppColors.primaryLight.withValues(alpha: 0.1),
                            ),
                            child: const Icon(
                              Icons.shopping_cart_outlined,
                              size: 40,
                              color: AppColors.primaryLight,
                            ),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Cart is Empty',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Click on any medicine from the catalog to add it to this invoice.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 12.5,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : GlassCard(
                    padding: const EdgeInsets.all(18),
                    child: _CheckoutModal(
                      cart: _cart,
                      customers: _customers,
                      settings: _settings,
                      isEmbedded: true,
                      onCartUpdated: () => setState(() {}),
                      onSaleCompleted: (createdInvoice) {
                        _clearCart();
                        _loadData();
                        ThermalReceiptDialog.show(
                            context, createdInvoice, _settings);
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileLayout(List<Medicine> filtered) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
          child: _buildSearchAndFilterBar(),
        ),
        const SizedBox(height: 6),
        Expanded(
          child: filtered.isEmpty
              ? const EmptyState(
                  icon: Icons.medication_outlined,
                  title: 'No medicines matched',
                  subtitle: 'Try searching by brand name or adjust filters',
                )
              : ListView.separated(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, i) => _buildMedicineCard(filtered[i]),
                ),
        ),
        if (_cart.isNotEmpty) _buildMobileFloatingCartBar(),
      ],
    );
  }

  Widget _buildSearchAndFilterBar() {
    return GlassCard(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          ModernSearchField(
            controller: _searchCtrl,
            hintText: 'Search medicine name, formula, company...',
            onChanged: (_) => setState(() {}),
            onClear: () => setState(() {}),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 36,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _buildCategoryChip('All'),
                ...AppConstants.medicineCategories
                    .map((c) => _buildCategoryChip(c)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMedicineCard(Medicine med) {
    final inCart = _cart[med.id];

    return GlassCard(
      padding: const EdgeInsets.all(12),
      border: inCart != null
          ? Border.all(color: AppColors.primaryLight, width: 1.8)
          : null,
      child: Row(
        children: [
          // Category/Medicine Icon Avatar
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              gradient: inCart != null
                  ? AppColors.primaryActionGradient
                  : null,
              color: inCart != null
                  ? null
                  : AppColors.primaryLight.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              Icons.medication_rounded,
              color: inCart != null ? Colors.white : AppColors.primaryLight,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),

          // Medicine Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  med.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${med.companyName ?? "Unknown"} • ${med.unitType.displayName}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11.5,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      Formatters.formatCurrency(
                          med.sellingPrice, _settings.currency),
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 14.5,
                        color: AppColors.primaryLight,
                      ),
                    ),
                    if (med.retailPrice > med.sellingPrice) ...[
                      const SizedBox(width: 6),
                      Text(
                        Formatters.formatCurrency(
                            med.retailPrice, _settings.currency),
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textMuted,
                          decoration: TextDecoration.lineThrough,
                        ),
                      ),
                    ],
                    if (med.discountPercent > 0 ||
                        med.extraDiscountPercent > 0) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 5, vertical: 1.5),
                        decoration: BoxDecoration(
                          color: AppColors.success.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          med.extraDiscountPercent > 0
                              ? '${med.totalDiscountPercent.toInt()}% Off (${med.discountPercent.toInt()}%+${med.extraDiscountPercent.toInt()}%)'
                              : '${med.discountPercent.toInt()}% Off',
                          style: const TextStyle(
                            fontSize: 9.5,
                            fontWeight: FontWeight.bold,
                            color: AppColors.success,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),

          // Stock and Add / Stepper
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (med.isOutOfStock)
                const StatusBadge(
                  label: 'Out of Stock',
                  color: AppColors.danger,
                )
              else if (med.isLowStock)
                StatusBadge(
                  label: 'Only ${med.currentStock.toInt()} left',
                  color: AppColors.warning,
                )
              else
                Text(
                  'Stock: ${med.currentStock.toInt()}',
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              const SizedBox(height: 8),

              if (inCart != null)
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: AppColors.primaryLight.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.remove,
                            size: 15, color: AppColors.primaryLight),
                        padding: const EdgeInsets.all(4),
                        constraints: const BoxConstraints(),
                        onPressed: () {
                          setState(() {
                            if (inCart.quantity > 1) {
                              inCart.quantity -= 1;
                            } else {
                              _removeFromCart(med.id!);
                            }
                          });
                        },
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        child: Text(
                          '${inCart.quantity.toInt()}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryLight,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add,
                            size: 15, color: AppColors.primaryLight),
                        padding: const EdgeInsets.all(4),
                        constraints: const BoxConstraints(),
                        onPressed: () => _addToCart(med),
                      ),
                    ],
                  ),
                )
              else
                ModernButton(
                  label: 'Add +',
                  onPressed: med.isOutOfStock ? null : () => _addToCart(med),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMobileFloatingCartBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
        boxShadow: [
          BoxShadow(
            color: Color(0x1F0F243A),
            blurRadius: 18,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${_cart.length} item${_cart.length > 1 ? "s" : ""} selected',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  Formatters.formatCurrency(_cartTotal, _settings.currency),
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 18,
                    color: AppColors.textPrimary,
                    letterSpacing: -0.3,
                  ),
                ),
              ],
            ),
            const Spacer(),
            ModernButton(
              label: 'Checkout →',
              icon: Icons.shopping_cart_checkout_rounded,
              onPressed: _openCheckoutSheet,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryChip(String title) {
    final isSelected = _selectedCategory == title;
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: ChoiceChip(
        label: Text(title),
        selected: isSelected,
        selectedColor: AppColors.primaryLight,
        backgroundColor: Colors.white.withValues(alpha: 0.7),
        labelStyle: TextStyle(
          fontSize: 11.5,
          fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
          color: isSelected ? Colors.white : AppColors.textPrimary,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(
            color: isSelected
                ? AppColors.primaryLight
                : AppColors.border.withValues(alpha: 0.8),
          ),
        ),
        onSelected: (_) => setState(() => _selectedCategory = title),
      ),
    );
  }
}

class _CheckoutModal extends StatefulWidget {
  final Map<int, PosItem> cart;
  final List<Customer> customers;
  final StoreSettings settings;
  final bool isEmbedded;
  final VoidCallback onCartUpdated;
  final ValueChanged<Invoice> onSaleCompleted;

  const _CheckoutModal({
    required this.cart,
    required this.customers,
    required this.settings,
    this.isEmbedded = false,
    required this.onCartUpdated,
    required this.onSaleCompleted,
  });

  @override
  State<_CheckoutModal> createState() => _CheckoutModalState();
}

class _CheckoutModalState extends State<_CheckoutModal> {
  String _saleType = InvoiceType.retail;
  Customer? _selectedCustomer;
  String _customerFilter = 'ALL'; // 'ALL', 'RETAIL', 'WHOLESALE'

  final TextEditingController _customerNameCtrl = TextEditingController();
  final TextEditingController _customerPhoneCtrl = TextEditingController();
  final TextEditingController _doctorNameCtrl = TextEditingController();
  final TextEditingController _roomNumberCtrl = TextEditingController();
  final TextEditingController _discountCtrl = TextEditingController(text: '0');
  late TextEditingController _paidCtrl;

  bool _isWalkIn = true;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    if (_saleType == InvoiceType.wholesale) {
      for (final item in widget.cart.values) {
        item.discountPercent = item.medicine.totalDiscountPercent;
      }
    }
    _paidCtrl = TextEditingController(
        text: _calculateGrandTotal().toStringAsFixed(0));
  }

  @override
  void dispose() {
    _customerNameCtrl.dispose();
    _customerPhoneCtrl.dispose();
    _doctorNameCtrl.dispose();
    _roomNumberCtrl.dispose();
    _discountCtrl.dispose();
    _paidCtrl.dispose();
    super.dispose();
  }

  double get _subtotal =>
      widget.cart.values.fold(0, (sum, i) => sum + i.lineTotal);

  double _calculateGrandTotal() {
    final discount = double.tryParse(_discountCtrl.text.trim()) ?? 0.0;
    final total = _subtotal - discount;
    return total > 0 ? total : 0.0;
  }

  Future<void> _submitSale() async {
    if (widget.cart.isEmpty) return;

    setState(() => _isSubmitting = true);

    try {
      final grandTotal = _calculateGrandTotal();
      final paid = double.tryParse(_paidCtrl.text.trim()) ?? grandTotal;
      final discount = double.tryParse(_discountCtrl.text.trim()) ?? 0.0;
      final remaining = (grandTotal - paid) > 0 ? (grandTotal - paid) : 0.0;

      final items = widget.cart.values.map((item) {
        return InvoiceItem(
          medicineId: item.medicine.id,
          medicineName: item.medicine.name,
          companyName: item.medicine.companyName,
          quantity: item.quantity,
          unitPrice: item.unitPrice,
          discountPercent: item.discountPercent,
          buyingPrice: item.medicine.buyingPrice,
          totalPrice: item.lineTotal,
        );
      }).toList();

      final invoice = Invoice(
        customerId: _selectedCustomer?.id,
        customerName: _selectedCustomer != null
            ? (_selectedCustomer!.isWholesale &&
                    _selectedCustomer!.companyName != null
                ? '${_selectedCustomer!.name} (${_selectedCustomer!.companyName})'
                : _selectedCustomer!.name)
            : (_customerNameCtrl.text.trim().isNotEmpty
                ? _customerNameCtrl.text.trim()
                : (_saleType == InvoiceType.wholesale
                    ? 'Wholesale Walk-in'
                    : 'Walk-in Customer')),
        customerPhone: _selectedCustomer != null
            ? _selectedCustomer!.phone
            : _customerPhoneCtrl.text.trim(),
        invoiceType: _saleType,
        roomNumber: _roomNumberCtrl.text.trim().isNotEmpty
            ? _roomNumberCtrl.text.trim()
            : null,
        doctorName: _doctorNameCtrl.text.trim().isNotEmpty
            ? _doctorNameCtrl.text.trim()
            : null,
        totalAmount: grandTotal,
        discount: discount,
        paidAmount: paid,
        remainingAmount: remaining,
        invoiceDate: DateTime.now().toIso8601String(),
        items: items,
      );

      final created = await DatabaseHelper.createSaleInvoice(invoice);

      if (mounted) {
        if (!widget.isEmbedded) {
          Navigator.pop(context);
        }
        widget.onSaleCompleted(created);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to process sale: $e'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final grandTotal = _calculateGrandTotal();
    final paid = double.tryParse(_paidCtrl.text.trim()) ?? grandTotal;
    final remaining = grandTotal - paid;

    final availableCustomers = _saleType == InvoiceType.wholesale
        ? widget.customers.where((c) => c.isWholesale).toList()
        : widget.customers.where((c) {
            if (_customerFilter == 'RETAIL') return c.isRetail;
            if (_customerFilter == 'WHOLESALE') return c.isWholesale;
            return true;
          }).toList();

    Widget body = SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!widget.isEmbedded) ...[
            Center(
              child: Container(
                width: 44,
                height: 4.5,
                margin: const EdgeInsets.only(bottom: 14),
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.shopping_cart_checkout_rounded,
                        color: AppColors.primaryLight, size: 22),
                    SizedBox(width: 8),
                    Text(
                      'Cart & Checkout',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, size: 20),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const Divider(color: AppColors.borderLight),
          ] else ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.receipt_long_rounded,
                        color: AppColors.primaryLight, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Current Order',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${widget.cart.length} items',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryLight,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
          ],

          // Items List Summary
          Container(
            constraints: const BoxConstraints(maxHeight: 180),
            child: ListView(
              shrinkWrap: true,
              children: widget.cart.values.map((item) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.medicine.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            Text(
                              '${item.quantity.toInt()} x ${item.unitPrice.toStringAsFixed(1)}${item.discountPercent > 0 ? " (-${item.discountPercent.toInt()}%)" : ""}',
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        Formatters.formatCurrency(
                            item.lineTotal, widget.settings.currency),
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                          color: AppColors.primaryLight,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
          const Divider(color: AppColors.borderLight),

          // Sale Type (Retail vs Wholesale)
          Row(
            children: [
              Expanded(
                child: SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(
                      value: InvoiceType.retail,
                      icon: Icon(Icons.shopping_bag_outlined, size: 15),
                      label: Text('Retail Sale', style: TextStyle(fontSize: 12)),
                    ),
                    ButtonSegment(
                      value: InvoiceType.wholesale,
                      icon: Icon(Icons.business_outlined, size: 15),
                      label: Text('Wholesale B2B',
                          style: TextStyle(fontSize: 12)),
                    ),
                  ],
                  selected: {_saleType},
                  onSelectionChanged: (set) {
                    setState(() {
                      _saleType = set.first;
                      _selectedCustomer = null;
                      for (final item in widget.cart.values) {
                        if (_saleType == InvoiceType.wholesale) {
                          item.discountPercent =
                              item.medicine.totalDiscountPercent;
                        } else {
                          item.discountPercent = 0.0;
                        }
                      }
                      widget.onCartUpdated();
                      _paidCtrl.text =
                          _calculateGrandTotal().toStringAsFixed(0);
                    });
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Customer Selector (Walk-in vs Registered)
          Row(
            children: [
              Expanded(
                child: SegmentedButton<bool>(
                  segments: [
                    ButtonSegment(
                      value: true,
                      label: Text(
                        _saleType == InvoiceType.wholesale
                            ? 'Walk-in Bulk'
                            : 'Walk-in Consumer',
                        style: const TextStyle(fontSize: 11.5),
                      ),
                    ),
                    ButtonSegment(
                      value: false,
                      label: Text(
                        _saleType == InvoiceType.wholesale
                            ? 'Wholesale Client'
                            : 'Registered Customer',
                        style: const TextStyle(fontSize: 11.5),
                      ),
                    ),
                  ],
                  selected: {_isWalkIn},
                  onSelectionChanged: (set) {
                    setState(() {
                      _isWalkIn = set.first;
                      if (_isWalkIn) _selectedCustomer = null;
                    });
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          if (!_isWalkIn) ...[
            if (_saleType == InvoiceType.retail) ...[
              Wrap(
                spacing: 6,
                runSpacing: 6,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  const Text('Filter:',
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textSecondary)),
                  _buildFilterPill('ALL', 'All (${widget.customers.length})'),
                  _buildFilterPill('RETAIL',
                      'Retail (${widget.customers.where((c) => c.isRetail).length})'),
                  _buildFilterPill('WHOLESALE',
                      'Wholesale (${widget.customers.where((c) => c.isWholesale).length})'),
                ],
              ),
              const SizedBox(height: 8),
            ],

            DropdownButtonFormField<Customer>(
              value: availableCustomers.contains(_selectedCustomer)
                  ? _selectedCustomer
                  : null,
              isExpanded: true,
              decoration: InputDecoration(
                labelText: _saleType == InvoiceType.wholesale
                    ? 'Select Wholesale Client *'
                    : (_customerFilter == 'WHOLESALE'
                        ? 'Select Wholesale Client (for Retail Sale)'
                        : (_customerFilter == 'RETAIL'
                            ? 'Select Retail Customer'
                            : 'Select Customer (Retail or Wholesale)')),
                prefixIcon: Icon(
                  _saleType == InvoiceType.wholesale ||
                          _customerFilter == 'WHOLESALE'
                      ? Icons.business
                      : Icons.person,
                  color: AppColors.primaryLight,
                  size: 18,
                ),
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.8),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.border)),
                enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.border)),
              ),
              items: availableCustomers.map((c) {
                return DropdownMenuItem(
                  value: c,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Text(
                          c.companyName != null && c.companyName!.isNotEmpty
                              ? '${c.name} (${c.companyName})'
                              : '${c.name} (${c.phone ?? "No phone"})',
                          style: const TextStyle(fontSize: 12.5),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 5, vertical: 1.5),
                        decoration: BoxDecoration(
                          color: (c.isWholesale
                                  ? const Color(0xFF6366F1)
                                  : AppColors.primaryLight)
                              .withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          c.isWholesale ? 'Wholesale' : 'Retail',
                          style: TextStyle(
                            fontSize: 9.5,
                            fontWeight: FontWeight.bold,
                            color: c.isWholesale
                                ? const Color(0xFF6366F1)
                                : AppColors.primaryLight,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (c) => setState(() => _selectedCustomer = c),
            ),
            const SizedBox(height: 10),
          ] else ...[
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _customerNameCtrl,
                    decoration: InputDecoration(
                      labelText: 'Customer Name',
                      prefixIcon: const Icon(Icons.person_outline,
                          color: AppColors.primaryLight, size: 18),
                      filled: true,
                      fillColor: Colors.white.withValues(alpha: 0.8),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide:
                              const BorderSide(color: AppColors.border)),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _customerPhoneCtrl,
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(
                      labelText: 'Phone',
                      prefixIcon: const Icon(Icons.phone_outlined,
                          color: AppColors.primaryLight, size: 18),
                      filled: true,
                      fillColor: Colors.white.withValues(alpha: 0.8),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide:
                              const BorderSide(color: AppColors.border)),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
          ],

          // Doctor and Ward/Room
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _doctorNameCtrl,
                  decoration: InputDecoration(
                    labelText: 'Doctor (Optional)',
                    prefixIcon: const Icon(Icons.medical_services_outlined,
                        color: AppColors.primaryLight, size: 18),
                    filled: true,
                    fillColor: Colors.white.withValues(alpha: 0.8),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.border)),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _roomNumberCtrl,
                  decoration: InputDecoration(
                    labelText: 'Ward/Room (Opt)',
                    prefixIcon: const Icon(Icons.meeting_room_outlined,
                        color: AppColors.primaryLight, size: 18),
                    filled: true,
                    fillColor: Colors.white.withValues(alpha: 0.8),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.border)),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Discount & Paid Inputs
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _discountCtrl,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: 'Discount (${widget.settings.currency})',
                    prefixIcon: const Icon(Icons.discount_outlined,
                        color: AppColors.primaryLight, size: 18),
                    filled: true,
                    fillColor: Colors.white.withValues(alpha: 0.8),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.border)),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _paidCtrl,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: 'Cash Paid',
                    prefixIcon: const Icon(Icons.payments_outlined,
                        color: AppColors.primaryLight, size: 18),
                    filled: true,
                    fillColor: Colors.white.withValues(alpha: 0.8),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.border)),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Summary Card
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Total Amount:',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 13.5)),
                    Text(
                      Formatters.formatCurrency(
                          grandTotal, widget.settings.currency),
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                        color: AppColors.primaryLight,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Paid Amount:',
                        style: TextStyle(
                            fontSize: 11.5, color: AppColors.textSecondary)),
                    Text(
                      Formatters.formatCurrency(paid, widget.settings.currency),
                      style: const TextStyle(
                          fontSize: 11.5, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      remaining > 0 ? 'Remaining / Due:' : 'Change / Return:',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.bold,
                        color: remaining > 0
                            ? AppColors.danger
                            : AppColors.success,
                      ),
                    ),
                    Text(
                      Formatters.formatCurrency(
                          remaining.abs(), widget.settings.currency),
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: remaining > 0
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

          // Complete Button
          ModernButton(
            label: _isSubmitting ? 'Processing...' : 'Complete & Print Receipt',
            icon: Icons.print_rounded,
            isLoading: _isSubmitting,
            onPressed: _isSubmitting ? null : _submitSale,
            width: double.infinity,
          ),
        ],
      ),
    );

    if (widget.isEmbedded) {
      return body;
    }

    final bottomPadding = MediaQuery.of(context).viewInsets.bottom +
        MediaQuery.of(context).padding.bottom +
        24;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Color(0x33000000),
            blurRadius: 24,
            offset: Offset(0, -6),
          ),
        ],
      ),
      padding: EdgeInsets.only(
        top: 14,
        left: 20,
        right: 20,
        bottom: bottomPadding,
      ),
      constraints:
          BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.9),
      child: SafeArea(
        top: false,
        bottom: true,
        child: body,
      ),
    );
  }

  Widget _buildFilterPill(String filterKey, String label) {
    final isSelected = _customerFilter == filterKey;
    final color = filterKey == 'WHOLESALE'
        ? const Color(0xFF6366F1)
        : (filterKey == 'RETAIL'
            ? AppColors.primaryLight
            : AppColors.secondary);

    return InkWell(
      onTap: () {
        setState(() {
          _customerFilter = filterKey;
          if (_selectedCustomer != null) {
            if (filterKey == 'RETAIL' && !_selectedCustomer!.isRetail) {
              _selectedCustomer = null;
            } else if (filterKey == 'WHOLESALE' &&
                !_selectedCustomer!.isWholesale) {
              _selectedCustomer = null;
            }
          }
        });
      },
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: isSelected ? color : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? color : AppColors.border,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 10.5,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected ? Colors.white : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}
