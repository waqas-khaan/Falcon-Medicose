import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../models/medicine.dart';
import '../models/store_settings.dart';
import '../utils/app_theme.dart';
import '../utils/formatters.dart';
import '../widgets/empty_state.dart';
import '../widgets/glass_widgets.dart';
import 'purchases_screen.dart';
import 'returns_screen.dart';

class InventoryAlertsScreen extends StatefulWidget {
  const InventoryAlertsScreen({super.key});

  @override
  State<InventoryAlertsScreen> createState() => _InventoryAlertsScreenState();
}

class _InventoryAlertsScreenState extends State<InventoryAlertsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  StoreSettings _settings = StoreSettings();
  bool _isLoading = true;

  List<Medicine> _lowStock = [];
  List<Medicine> _outOfStock = [];
  List<Medicine> _expiringSoon = [];
  List<Medicine> _expired = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadAlerts();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAlerts() async {
    setState(() => _isLoading = true);
    final settings = await DatabaseHelper.getSettings();
    final low = await DatabaseHelper.getLowStockMedicines();
    final out = await DatabaseHelper.getOutOfStockMedicines();
    final expiring = await DatabaseHelper.getExpiringSoonMedicines(30);
    final expired = await DatabaseHelper.getExpiredMedicines();

    if (mounted) {
      setState(() {
        _settings = settings;
        _lowStock = low;
        _outOfStock = out;
        _expiringSoon = expiring;
        _expired = expired;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('Inventory Alerts'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          labelStyle:
              const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
          isScrollable: true,
          tabs: [
            Tab(text: 'Low Stock (${_lowStock.length})'),
            Tab(text: 'Out of Stock (${_outOfStock.length})'),
            Tab(text: 'Expiring Soon (${_expiringSoon.length})'),
            Tab(text: 'Expired (${_expired.length})'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primaryLight))
          : TabBarView(
              controller: _tabController,
              children: [
                _buildMedicineList(
                  _lowStock,
                  'No low stock medicines',
                  'All medicines have sufficient stock',
                  AppColors.warning,
                ),
                _buildMedicineList(
                  _outOfStock,
                  'No out of stock medicines',
                  'Everything is currently in stock',
                  AppColors.danger,
                ),
                _buildMedicineList(
                  _expiringSoon,
                  'No medicines expiring soon',
                  'No items expiring within the next 30 days',
                  AppColors.secondary,
                ),
                _buildMedicineList(
                  _expired,
                  'No expired medicines',
                  'Great! No expired medicines found in inventory',
                  AppColors.danger,
                ),
              ],
            ),
    );
  }

  Widget _buildMedicineList(
      List<Medicine> list, String emptyTitle, String emptySubtitle, Color accent) {
    if (list.isEmpty) {
      return EmptyState(
        icon: Icons.check_circle_outline_rounded,
        title: emptyTitle,
        subtitle: emptySubtitle,
      );
    }

    final isDesktop = ResponsiveBreakpoints.isDesktop(context);

    if (isDesktop) {
      return GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 460,
          mainAxisExtent: 145,
          crossAxisSpacing: 14,
          mainAxisSpacing: 14,
        ),
        itemCount: list.length,
        itemBuilder: (context, i) => _buildAlertCard(list[i]),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: list.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, i) => _buildAlertCard(list[i]),
    );
  }

  Widget _buildAlertCard(Medicine m) {
    return GlassCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      m.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 14.5),
                    ),
                    Text(
                      '${m.companyName ?? "Unknown"} • ${m.category ?? "General"}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 11.5, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              if (m.isOutOfStock)
                const StatusBadge(
                  label: '0 Stock',
                  color: AppColors.danger,
                  icon: Icons.error_outline_rounded,
                )
              else if (m.isLowStock)
                StatusBadge(
                  label:
                      '${m.currentStock.toInt()} Left (Min: ${m.minStockLevel.toInt()})',
                  color: AppColors.warning,
                  icon: Icons.warning_amber_rounded,
                )
              else if (m.isExpired())
                const StatusBadge(
                  label: 'EXPIRED',
                  color: AppColors.danger,
                  icon: Icons.cancel_outlined,
                )
              else if (m.isExpiringSoon(30))
                StatusBadge(
                  label: 'Exp: ${m.nearestExpiryDate}',
                  color: AppColors.secondary,
                  icon: Icons.event_busy_rounded,
                ),
            ],
          ),
          const Divider(height: 8, color: AppColors.borderLight),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Sell: ${Formatters.formatCurrency(m.sellingPrice, _settings.currency)}' +
                    (m.buyingPrice > 0
                        ? ' • Cost: ${Formatters.formatCurrency(m.buyingPrice, _settings.currency)}'
                        : ''),
                style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 12.5,
                    color: AppColors.primaryLight),
              ),
              Row(
                children: [
                  OutlinedButton.icon(
                    onPressed: () async {
                      await Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const PurchasesScreen()));
                      _loadAlerts();
                    },
                    icon: const Icon(Icons.add_rounded, size: 14),
                    label: const Text('Stock In',
                        style: TextStyle(fontSize: 11)),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    onPressed: () async {
                      await Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const ReturnsScreen()));
                      _loadAlerts();
                    },
                    icon: const Icon(Icons.keyboard_return_rounded, size: 14),
                    label: const Text('Return',
                        style: TextStyle(fontSize: 11)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.danger,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                      visualDensity: VisualDensity.compact,
                    ),
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
