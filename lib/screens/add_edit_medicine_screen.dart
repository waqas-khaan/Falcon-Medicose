import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../models/medicine.dart';
import '../models/unit_type.dart';
import '../utils/app_theme.dart';
import '../utils/constants.dart';
import '../utils/formatters.dart';
import '../widgets/glass_widgets.dart';

class AddEditMedicineScreen extends StatefulWidget {
  final Medicine? medicine;

  const AddEditMedicineScreen({super.key, this.medicine});

  @override
  State<AddEditMedicineScreen> createState() => _AddEditMedicineScreenState();
}

class _AddEditMedicineScreenState extends State<AddEditMedicineScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameCtrl;
  late TextEditingController _companyCtrl;
  late TextEditingController _buyingPriceCtrl;
  late TextEditingController _retailPriceCtrl;
  late TextEditingController _sellingPriceCtrl;
  late TextEditingController _discountCtrl;
  late TextEditingController _stockCtrl;
  late TextEditingController _minStockCtrl;
  late TextEditingController _expiryDateCtrl;

  bool _sellingPriceManuallyEdited = false;
  String _selectedCategory = 'Tablets';
  UnitType _selectedUnit = UnitType.strip;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final m = widget.medicine;
    _nameCtrl = TextEditingController(text: m?.name ?? '');
    _companyCtrl = TextEditingController(text: m?.companyName ?? '');
    _buyingPriceCtrl = TextEditingController(
        text: m != null && m.buyingPrice > 0
            ? m.buyingPrice.toStringAsFixed(1)
            : '');

    final initialRetail = m != null && m.retailPrice > 0
        ? m.retailPrice.toStringAsFixed(1)
        : (m != null && m.sellingPrice > 0
            ? m.sellingPrice.toStringAsFixed(1)
            : '');
    final initialSelling =
        m != null && m.sellingPrice > 0 ? m.sellingPrice.toStringAsFixed(1) : '';

    _retailPriceCtrl = TextEditingController(text: initialRetail);
    _sellingPriceCtrl = TextEditingController(text: initialSelling);

    if (m != null &&
        m.retailPrice > 0 &&
        m.sellingPrice > 0 &&
        m.retailPrice != m.sellingPrice) {
      _sellingPriceManuallyEdited = true;
    }

    _discountCtrl = TextEditingController(
        text: m != null && m.discountPercent > 0
            ? m.discountPercent.toStringAsFixed(0)
            : '0');
    _stockCtrl = TextEditingController(
        text: m != null ? m.currentStock.toStringAsFixed(0) : '0');
    _minStockCtrl = TextEditingController(
        text: m != null ? m.minStockLevel.toStringAsFixed(0) : '5');
    _expiryDateCtrl = TextEditingController(text: m?.nearestExpiryDate ?? '');

    if (m?.category != null &&
        AppConstants.medicineCategories.contains(m!.category)) {
      _selectedCategory = m.category!;
    }
    if (m != null) {
      _selectedUnit = m.unitType;
    }

    _buyingPriceCtrl.addListener(() => setState(() {}));
    _retailPriceCtrl.addListener(() {
      if (!_sellingPriceManuallyEdited) {
        _sellingPriceCtrl.text = _retailPriceCtrl.text;
      }
      setState(() {});
    });
    _sellingPriceCtrl.addListener(() => setState(() {}));
    _discountCtrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _companyCtrl.dispose();
    _buyingPriceCtrl.dispose();
    _retailPriceCtrl.dispose();
    _sellingPriceCtrl.dispose();
    _discountCtrl.dispose();
    _stockCtrl.dispose();
    _minStockCtrl.dispose();
    _expiryDateCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickExpiryDate() async {
    final now = DateTime.now();
    DateTime initial = now.add(const Duration(days: 365));
    if (_expiryDateCtrl.text.isNotEmpty) {
      try {
        initial = DateTime.parse(_expiryDateCtrl.text);
      } catch (_) {}
    }

    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime(2040),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primaryLight,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _expiryDateCtrl.text = Formatters.toDbDate(picked);
      });
    }
  }

  Future<void> _saveMedicine() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final name = _nameCtrl.text.trim();
      final company = _companyCtrl.text.trim();
      final buyingPrice = double.tryParse(_buyingPriceCtrl.text.trim()) ?? 0.0;
      final retailPrice = double.tryParse(_retailPriceCtrl.text.trim()) ?? 0.0;
      final sellingPrice = double.tryParse(_sellingPriceCtrl.text.trim()) ??
          (retailPrice > 0 ? retailPrice : 0.0);
      final discount = double.tryParse(_discountCtrl.text.trim()) ?? 0.0;
      final stock = double.tryParse(_stockCtrl.text.trim()) ?? 0.0;
      final minStock = double.tryParse(_minStockCtrl.text.trim()) ?? 5.0;
      final expiry = _expiryDateCtrl.text.trim().isNotEmpty
          ? _expiryDateCtrl.text.trim()
          : null;

      final medicine = Medicine(
        id: widget.medicine?.id,
        name: name,
        companyName: company.isNotEmpty ? company : null,
        category: _selectedCategory,
        unitType: _selectedUnit,
        buyingPrice: buyingPrice,
        retailPrice: retailPrice > 0 ? retailPrice : sellingPrice,
        sellingPrice: sellingPrice,
        discountPercent: discount,
        currentStock: stock,
        minStockLevel: minStock,
        nearestExpiryDate: expiry,
        active: true,
      );

      if (widget.medicine == null) {
        await DatabaseHelper.insertMedicine(medicine);
      } else {
        await DatabaseHelper.updateMedicine(medicine);
      }

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${medicine.name} saved successfully!'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving medicine: $e'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.medicine != null;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Medicine' : 'Add New Medicine'),
        actions: [
          IconButton(
            icon: _isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2))
                : const Icon(Icons.check_rounded),
            onPressed: _isSaving ? null : _saveMedicine,
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(18),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Basic Information Card
                  _buildSectionCard(
                    title: 'Basic Information',
                    icon: Icons.medication_rounded,
                    children: [
                      TextFormField(
                        controller: _nameCtrl,
                        decoration: _inputDecor(
                          'Medicine Name *',
                          Icons.title_rounded,
                          hint: 'e.g. Panadol 500mg',
                        ),
                        validator: (val) => val == null || val.trim().isEmpty
                            ? 'Please enter medicine name'
                            : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _companyCtrl,
                        decoration: _inputDecor(
                          'Manufacturer / Company',
                          Icons.business_rounded,
                          hint: 'e.g. GSK, Abbott, Getz',
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: _selectedCategory,
                              decoration: _inputDecor(
                                'Category',
                                Icons.category_rounded,
                              ),
                              items: AppConstants.medicineCategories.map((c) {
                                return DropdownMenuItem(
                                  value: c,
                                  child: Text(c,
                                      style: const TextStyle(fontSize: 13)),
                                );
                              }).toList(),
                              onChanged: (val) {
                                if (val != null) {
                                  setState(() => _selectedCategory = val);
                                }
                              },
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: DropdownButtonFormField<UnitType>(
                              value: _selectedUnit,
                              decoration: _inputDecor(
                                'Unit Type',
                                Icons.straighten_rounded,
                              ),
                              items: UnitType.values.map((u) {
                                return DropdownMenuItem(
                                  value: u,
                                  child: Text(u.displayName,
                                      style: const TextStyle(fontSize: 13)),
                                );
                              }).toList(),
                              onChanged: (val) {
                                if (val != null) {
                                  setState(() => _selectedUnit = val);
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Pricing & Margins Card
                  _buildSectionCard(
                    title: 'Pricing & Discounts',
                    icon: Icons.attach_money_rounded,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _buyingPriceCtrl,
                              keyboardType: const TextInputType.numberWithOptions(
                                  decimal: true),
                              decoration: _inputDecor(
                                'Cost Price',
                                Icons.shopping_bag_outlined,
                                hint: '0.0',
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextFormField(
                              controller: _retailPriceCtrl,
                              keyboardType: const TextInputType.numberWithOptions(
                                  decimal: true),
                              decoration: _inputDecor(
                                'Retail (MRP) *',
                                Icons.sell_outlined,
                                hint: '0.0',
                              ),
                              validator: (val) {
                                if (val == null || val.trim().isEmpty) {
                                  return 'Enter retail price';
                                }
                                final parsed = double.tryParse(val.trim());
                                if (parsed == null || parsed <= 0) {
                                  return 'Must be > 0';
                                }
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _sellingPriceCtrl,
                              keyboardType: const TextInputType.numberWithOptions(
                                  decimal: true),
                              decoration: _inputDecor(
                                'Selling Price *',
                                Icons.point_of_sale_rounded,
                                hint: '0.0',
                              ),
                              onChanged: (_) =>
                                  _sellingPriceManuallyEdited = true,
                              validator: (val) {
                                if (val == null || val.trim().isEmpty) {
                                  return 'Enter selling price';
                                }
                                final parsed = double.tryParse(val.trim());
                                if (parsed == null || parsed <= 0) {
                                  return 'Must be > 0';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextFormField(
                              controller: _discountCtrl,
                              keyboardType: const TextInputType.numberWithOptions(
                                  decimal: true),
                              decoration: _inputDecor(
                                'Wholesale Disc %',
                                Icons.discount_outlined,
                                hint: '0%',
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _buildLivePriceSummary(),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Inventory & Expiry Card
                  _buildSectionCard(
                    title: 'Stock & Expiry Alert',
                    icon: Icons.inventory_2_outlined,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _stockCtrl,
                              keyboardType: const TextInputType.numberWithOptions(
                                  decimal: true),
                              decoration: _inputDecor(
                                'Current Stock',
                                Icons.layers_outlined,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextFormField(
                              controller: _minStockCtrl,
                              keyboardType: const TextInputType.numberWithOptions(
                                  decimal: true),
                              decoration: _inputDecor(
                                'Min Stock Alert',
                                Icons.warning_amber_outlined,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _expiryDateCtrl,
                        readOnly: true,
                        onTap: _pickExpiryDate,
                        decoration: InputDecoration(
                          labelText: 'Nearest Expiry Date (YYYY-MM-DD)',
                          prefixIcon: const Icon(Icons.calendar_today_outlined,
                              color: AppColors.primaryLight, size: 18),
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.date_range_rounded,
                                color: AppColors.primaryLight),
                            onPressed: _pickExpiryDate,
                          ),
                          filled: true,
                          fillColor: Colors.white.withValues(alpha: 0.8),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 12),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide:
                                const BorderSide(color: AppColors.border),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide:
                                const BorderSide(color: AppColors.border),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Save Button
                  ModernButton(
                    label: isEditing
                        ? 'Update Medicine'
                        : 'Save Medicine to Catalog',
                    icon: Icons.save_rounded,
                    isLoading: _isSaving,
                    onPressed: _isSaving ? null : _saveMedicine,
                    width: double.infinity,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecor(String label, IconData icon, {String? hint}) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: Icon(icon, color: AppColors.primaryLight, size: 18),
      filled: true,
      fillColor: Colors.white.withValues(alpha: 0.8),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 16, color: AppColors.primaryLight),
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...children,
        ],
      ),
    );
  }

  Widget _buildLivePriceSummary() {
    final cost = double.tryParse(_buyingPriceCtrl.text.trim()) ?? 0.0;
    final retail = double.tryParse(_retailPriceCtrl.text.trim()) ?? 0.0;
    final sell = double.tryParse(_sellingPriceCtrl.text.trim()) ?? 0.0;

    if (sell <= 0 && retail <= 0 && cost <= 0) return const SizedBox.shrink();

    final activeSell = sell > 0 ? sell : retail;
    final margin = activeSell - cost;
    final marginPct = cost > 0 ? (margin / cost) * 100 : 0.0;
    final customerSavings =
        (retail > sell && retail > 0 && sell > 0) ? (retail - sell) : 0.0;
    final savingsPct = (retail > sell && retail > 0 && sell > 0)
        ? ((retail - sell) / retail) * 100
        : 0.0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
              Row(
                children: [
                  Icon(
                    margin >= 0
                        ? Icons.trending_up_rounded
                        : Icons.trending_down_rounded,
                    size: 16,
                    color: margin >= 0 ? AppColors.success : AppColors.danger,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Profit Margin: Rs. ${margin.toStringAsFixed(1)}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: margin >= 0 ? AppColors.success : AppColors.danger,
                    ),
                  ),
                ],
              ),
              if (cost > 0)
                Text(
                  '${marginPct.toStringAsFixed(1)}% on cost',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: margin >= 0 ? AppColors.success : AppColors.danger,
                  ),
                ),
            ],
          ),
          if (customerSavings > 0) ...[
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.discount_outlined,
                        size: 14, color: AppColors.primaryLight),
                    SizedBox(width: 6),
                    Text(
                      'Customer Savings:',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                Text(
                  'Rs. ${customerSavings.toStringAsFixed(1)} (${savingsPct.toStringAsFixed(1)}% off MRP)',
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.primaryLight,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
