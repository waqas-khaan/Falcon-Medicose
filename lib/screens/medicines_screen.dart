import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../models/medicine.dart';
import '../models/store_settings.dart';
import '../utils/app_theme.dart';
import '../utils/constants.dart';
import '../utils/formatters.dart';
import '../widgets/empty_state.dart';
import '../widgets/glass_widgets.dart';
import 'add_edit_medicine_screen.dart';

class MedicinesScreen extends StatefulWidget {
  const MedicinesScreen({super.key});

  @override
  State<MedicinesScreen> createState() => _MedicinesScreenState();
}

class _MedicinesScreenState extends State<MedicinesScreen> {
  List<Medicine> _medicines = [];
  List<Medicine> _filtered = [];
  StoreSettings _settings = StoreSettings();
  bool _isLoading = true;

  String _selectedCategory = 'All';
  String _selectedStockFilter =
      'All'; // All, Low Stock, Out of Stock, Expiring, Expired
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadMedicines();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadMedicines() async {
    setState(() => _isLoading = true);
    final settings = await DatabaseHelper.getSettings();
    final list = await DatabaseHelper.getMedicines();

    if (mounted) {
      setState(() {
        _settings = settings;
        _medicines = list;
        _applyFilters();
        _isLoading = false;
      });
    }
  }

  void _applyFilters() {
    final query = _searchCtrl.text.trim().toLowerCase();

    setState(() {
      _filtered = _medicines.where((m) {
        final matchesCat =
            _selectedCategory == 'All' || m.category == _selectedCategory;
        final matchesQuery = query.isEmpty ||
            m.name.toLowerCase().contains(query) ||
            (m.companyName?.toLowerCase().contains(query) ?? false);

        bool matchesStock = true;
        if (_selectedStockFilter == 'Low Stock') {
          matchesStock = m.isLowStock;
        } else if (_selectedStockFilter == 'Out of Stock') {
          matchesStock = m.isOutOfStock;
        } else if (_selectedStockFilter == 'Expiring') {
          matchesStock = m.isExpiringSoon(30);
        } else if (_selectedStockFilter == 'Expired') {
          matchesStock = m.isExpired();
        }

        return matchesCat && matchesQuery && matchesStock;
      }).toList();
    });
  }

  Future<void> _deleteMedicine(Medicine m) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Medicine?'),
        content:
            Text('Are you sure you want to remove ${m.name} from the catalog?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true && m.id != null) {
      await DatabaseHelper.deleteMedicine(m.id!);
      _loadMedicines();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${m.name} deleted'),
            backgroundColor: AppColors.danger,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final categories = ['All', ...AppConstants.medicineCategories];
    final stockFilters = [
      'All',
      'Low Stock',
      'Out of Stock',
      'Expiring',
      'Expired'
    ];
    final isDesktop = ResponsiveBreakpoints.isDesktop(context);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Medicine Catalog'),
            const SizedBox(width: 8),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${_filtered.length}',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh Catalog',
            onPressed: _loadMedicines,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final res = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddEditMedicineScreen()),
          );
          if (res == true) _loadMedicines();
        },
        backgroundColor: AppColors.primaryLight,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded, size: 21),
        label: const Text(
          'Add Medicine',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      body: Column(
        children: [
          // Search & Filter Header Strip
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: GlassCard(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  ModernSearchField(
                    controller: _searchCtrl,
                    hintText: 'Search medicine name, formula, company...',
                    onChanged: (_) => _applyFilters(),
                    onClear: () => _applyFilters(),
                  ),
                  const SizedBox(height: 10),
                  // Categories strip
                  SizedBox(
                    height: 36,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: categories.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 6),
                      itemBuilder: (context, i) {
                        final cat = categories[i];
                        final isSelected = _selectedCategory == cat;
                        return ChoiceChip(
                          label: Text(cat),
                          selected: isSelected,
                          onSelected: (val) {
                            if (val) {
                              setState(() {
                                _selectedCategory = cat;
                                _applyFilters();
                              });
                            }
                          },
                          selectedColor: AppColors.primaryLight,
                          labelStyle: TextStyle(
                            color:
                                isSelected ? Colors.white : AppColors.textPrimary,
                            fontWeight: isSelected
                                ? FontWeight.w800
                                : FontWeight.w500,
                            fontSize: 11,
                          ),
                          backgroundColor: Colors.white.withValues(alpha: 0.7),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(
                              color: isSelected
                                  ? AppColors.primaryLight
                                  : AppColors.border.withValues(alpha: 0.8),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 6),
                  // Stock filter chips
                  SizedBox(
                    height: 34,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: stockFilters.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 6),
                      itemBuilder: (context, i) {
                        final sf = stockFilters[i];
                        final isSelected = _selectedStockFilter == sf;
                        return FilterChip(
                          label: Text(sf),
                          selected: isSelected,
                          onSelected: (val) {
                            setState(() {
                              _selectedStockFilter = sf;
                              _applyFilters();
                            });
                          },
                          selectedColor:
                              AppColors.primaryLight.withValues(alpha: 0.18),
                          labelStyle: TextStyle(
                            color: isSelected
                                ? AppColors.primaryLight
                                : AppColors.textSecondary,
                            fontWeight: isSelected
                                ? FontWeight.w800
                                : FontWeight.w500,
                            fontSize: 11,
                          ),
                          backgroundColor: Colors.white.withValues(alpha: 0.6),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                            side: BorderSide(
                              color: isSelected
                                  ? AppColors.primaryLight
                                  : AppColors.border.withValues(alpha: 0.8),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Medicine Grid / List
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                        color: AppColors.primaryLight))
                : _filtered.isEmpty
                    ? EmptyState(
                        icon: Icons.medication_outlined,
                        title: 'No medicines found',
                        subtitle:
                            'Tap the button below to add your first medicine',
                        actionLabel: 'Add Medicine',
                        onAction: () async {
                          final res = await Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) =>
                                    const AddEditMedicineScreen()),
                          );
                          if (res == true) _loadMedicines();
                        },
                      )
                    : isDesktop
                        ? GridView.builder(
                            padding: const EdgeInsets.fromLTRB(16, 8, 16, 88),
                            gridDelegate:
                                const SliverGridDelegateWithMaxCrossAxisExtent(
                              maxCrossAxisExtent: 460,
                              mainAxisExtent: 185,
                              crossAxisSpacing: 14,
                              mainAxisSpacing: 14,
                            ),
                            itemCount: _filtered.length,
                            itemBuilder: (context, index) =>
                                _buildMedicineCard(_filtered[index]),
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.fromLTRB(16, 8, 16, 88),
                            itemCount: _filtered.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 10),
                            itemBuilder: (context, index) =>
                                _buildMedicineCard(_filtered[index]),
                          ),
          ),
        ],
      ),
    );
  }

  Widget _buildMedicineCard(Medicine m) {
    return GlassCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: AppColors.primaryActionGradient,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primaryLight.withValues(alpha: 0.25),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: const Icon(Icons.medication_rounded,
                    color: Colors.white, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      m.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 14.5,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${m.companyName ?? "Unknown"} • ${m.category ?? "General"} • ${m.unitType.displayName}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 11.5,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert_rounded,
                    color: AppColors.textSecondary, size: 20),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                onSelected: (val) async {
                  if (val == 'edit') {
                    final res = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AddEditMedicineScreen(medicine: m),
                      ),
                    );
                    if (res == true) _loadMedicines();
                  } else if (val == 'delete') {
                    _deleteMedicine(m);
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit_outlined, size: 18),
                        SizedBox(width: 8),
                        Text('Edit Medicine'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete_outline,
                            color: AppColors.danger, size: 18),
                        SizedBox(width: 8),
                        Text('Delete',
                            style: TextStyle(color: AppColors.danger)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          const Divider(height: 10, color: AppColors.borderLight),

          // Price, Stock and Expiry details row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        Formatters.formatCurrency(
                            m.sellingPrice, _settings.currency),
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 15,
                          color: AppColors.primaryLight,
                        ),
                      ),
                      if (m.retailPrice > m.sellingPrice) ...[
                        const SizedBox(width: 6),
                        Text(
                          Formatters.formatCurrency(
                              m.retailPrice, _settings.currency),
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.textMuted,
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Wrap(
                    spacing: 6,
                    children: [
                      if (m.buyingPrice > 0)
                        Text(
                          'Cost: ${Formatters.formatCurrency(m.buyingPrice, _settings.currency)}',
                          style: const TextStyle(
                            fontSize: 10.5,
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      if (m.retailPrice > 0 && m.retailPrice != m.sellingPrice)
                        Text(
                          'MRP: ${Formatters.formatCurrency(m.retailPrice, _settings.currency)}',
                          style: const TextStyle(
                            fontSize: 10.5,
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      if (m.discountPercent > 0 || m.extraDiscountPercent > 0)
                        Text(
                          m.extraDiscountPercent > 0
                              ? 'Wholesale: ${m.totalDiscountPercent.toInt()}% (${m.discountPercent.toInt()}%+${m.extraDiscountPercent.toInt()}%)'
                              : 'Wholesale: ${m.discountPercent.toInt()}%',
                          style: const TextStyle(
                            fontSize: 10.5,
                            color: Color(0xFF6366F1),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (m.isOutOfStock)
                    const StatusBadge(
                      label: 'Out of Stock (0)',
                      color: AppColors.danger,
                      icon: Icons.error_outline,
                    )
                  else if (m.isLowStock)
                    StatusBadge(
                      label: 'Low Stock (${m.currentStock.toInt()})',
                      color: AppColors.warning,
                      icon: Icons.warning_amber_rounded,
                    )
                  else
                    StatusBadge(
                      label: 'In Stock (${m.currentStock.toInt()})',
                      color: AppColors.success,
                      icon: Icons.check_circle_outline,
                    ),
                  const SizedBox(height: 4),
                  if (m.nearestExpiryDate != null &&
                      m.nearestExpiryDate!.isNotEmpty) ...[
                    if (m.isExpired())
                      const Text(
                        'EXPIRED',
                        style: TextStyle(
                          color: AppColors.danger,
                          fontWeight: FontWeight.bold,
                          fontSize: 10,
                        ),
                      )
                    else if (m.isExpiringSoon(30))
                      Text(
                        'Exp: ${m.nearestExpiryDate} (Soon)',
                        style: const TextStyle(
                          color: AppColors.warning,
                          fontWeight: FontWeight.bold,
                          fontSize: 10,
                        ),
                      )
                    else
                      Text(
                        'Exp: ${m.nearestExpiryDate}',
                        style: const TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 10,
                        ),
                      ),
                  ],
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
