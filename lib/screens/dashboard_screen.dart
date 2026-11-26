import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../models/invoice.dart';
import '../models/report_models.dart';
import '../models/store_settings.dart';
import '../utils/app_theme.dart';
import '../utils/formatters.dart';
import '../widgets/badge_pill.dart';
import '../widgets/glass_widgets.dart';
import '../widgets/simple_bar_chart.dart';
import '../widgets/stat_card.dart';
import '../widgets/thermal_receipt_dialog.dart';
import 'inventory_alerts_screen.dart';
import 'invoices_screen.dart';
import 'medicines_screen.dart';
import 'pos_screen.dart';
import 'purchases_screen.dart';
import 'expenses_screen.dart';
import 'customers_screen.dart';
import 'suppliers_screen.dart';
import 'returns_screen.dart';
import 'reports_screen.dart';
import 'settings_screen.dart';
import 'backup_screen.dart';

class DashboardScreen extends StatefulWidget {
  final VoidCallback? onNavigateToPos;
  final Function(int)? onNavigateToTab;
  final bool isDesktop;

  const DashboardScreen({
    super.key,
    this.onNavigateToPos,
    this.onNavigateToTab,
    this.isDesktop = false,
  });

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  void _goTo(int tabIndex, Widget fallbackScreen) {
    if (widget.onNavigateToTab != null) {
      widget.onNavigateToTab!(tabIndex);
    } else {
      Navigator.push(context, MaterialPageRoute(builder: (_) => fallbackScreen));
    }
  }
  bool _isLoading = true;
  StoreSettings _settings = StoreSettings();
  ProfitSummary _todayProfit =
      ProfitSummary(revenue: 0, cost: 0, gross: 0, expenses: 0, net: 0);
  double _todayCash = 0.0;
  double _inventoryVal = 0.0;
  int _totalMedicinesCount = 0;
  NeedsAttention _alerts =
      NeedsAttention(lowStock: 0, outOfStock: 0, expired: 0, expiringSoon: 0);
  List<DayRevenue> _revenueTrend = [];
  List<TopSeller> _topSellers = [];
  List<Invoice> _recentInvoices = [];

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    setState(() => _isLoading = true);
    try {
      final settings = await DatabaseHelper.getSettings();
      final todayProfit = await DatabaseHelper.getProfitSummary('today');
      final todayCash = await DatabaseHelper.getTodayCashCollected();
      final inventoryVal = await DatabaseHelper.getInventoryValuation();
      final medicines = await DatabaseHelper.getMedicines();
      final alerts = await DatabaseHelper.getNeedsAttention();
      final revenueTrend = await DatabaseHelper.getRevenueLastNDays(7);
      final topSellers = await DatabaseHelper.getTopSellers(5);
      final recentInvoices = await DatabaseHelper.getInvoices(limit: 5);

      if (mounted) {
        setState(() {
          _settings = settings;
          _todayProfit = todayProfit;
          _todayCash = todayCash;
          _inventoryVal = inventoryVal;
          _totalMedicinesCount = medicines.length;
          _alerts = alerts;
          _revenueTrend = revenueTrend;
          _topSellers = topSellers;
          _recentInvoices = recentInvoices;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primaryLight),
        ),
      );
    }

    final bool isWide = widget.isDesktop || MediaQuery.of(context).size.width >= 900;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: isWide
          ? null
          : AppBar(
              title: Column(
                children: [
                  Text(
                    _settings.storeName,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 17,
                      letterSpacing: 0.3,
                    ),
                  ),
                  const Text(
                    'Pharmacy & POS Command Center',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.white70,
                      fontWeight: FontWeight.normal,
                    ),
                  ),
                ],
              ),
              actions: [
                IconButton(
                  tooltip: 'Inventory Alerts',
                  icon: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      const Icon(Icons.notifications_outlined, size: 22),
                      if (_alerts.hasIssues)
                        Positioned(
                          right: -2,
                          top: -2,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: AppColors.danger,
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              '${_alerts.totalIssues}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  onPressed: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const InventoryAlertsScreen()),
                    );
                    _loadDashboardData();
                  },
                ),
                IconButton(
                  tooltip: 'Backup Database',
                  icon: const Icon(Icons.backup_outlined, size: 21),
                  onPressed: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const BackupScreen()),
                    );
                    _loadDashboardData();
                  },
                ),
                IconButton(
                  tooltip: 'Store Settings',
                  icon: const Icon(Icons.settings_outlined, size: 21),
                  onPressed: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const SettingsScreen()),
                    );
                    _loadDashboardData();
                  },
                ),
              ],
            ),
      body: RefreshIndicator(
        onRefresh: _loadDashboardData,
        color: AppColors.primaryLight,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.symmetric(
            horizontal: isWide ? 24 : 16,
            vertical: isWide ? 20 : 14,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Hero Welcome Card (adaptive desktop/mobile)
              _buildHeroHeader(isWide),
              const SizedBox(height: 18),

              // 📊 Top 4 KPI Metrics Grid (1 row of 4 on desktop, 2x2 on mobile)
              _buildKpiGrid(isWide),
              const SizedBox(height: 20),

              if (isWide) ...[
                // Desktop Two-Column Executive Layout
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Left Column (flex: 6): Charts & Recent Activity
                    Expanded(
                      flex: 6,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildRevenueChart(),
                          const SizedBox(height: 20),
                          _buildRecentInvoices(),
                        ],
                      ),
                    ),
                    const SizedBox(width: 20),
                    // Right Column (flex: 4): Alerts, Quick Actions, Top Sellers
                    Expanded(
                      flex: 4,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (_alerts.hasIssues) ...[
                            _buildAlertsBanner(),
                            const SizedBox(height: 20),
                          ],
                          _buildDesktopQuickActions(),
                          if (_topSellers.isNotEmpty) ...[
                            const SizedBox(height: 20),
                            _buildTopSellers(),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ] else ...[
                // Mobile Single-Column Layout
                if (_alerts.hasIssues) ...[
                  _buildAlertsBanner(),
                  const SizedBox(height: 16),
                ],
                _buildQuickActions(),
                const SizedBox(height: 20),
                _buildRevenueChart(),
                const SizedBox(height: 20),
                if (_topSellers.isNotEmpty) ...[
                  _buildTopSellers(),
                  const SizedBox(height: 20),
                ],
                _buildRecentInvoices(),
              ],
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeroHeader(bool isWide) {
    if (isWide) {
      return GlassCard(
        borderRadius: 22,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 22),
        gradient: AppColors.headerGradient,
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.2),
          width: 1.2,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.verified_user_rounded,
                          color: AppColors.secondary, size: 16),
                      const SizedBox(width: 6),
                      const Text(
                        'STORE OVERVIEW',
                        style: TextStyle(
                          color: AppColors.secondary,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.0,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                              color: Colors.white.withValues(alpha: 0.2)),
                        ),
                        child: Text(
                          Formatters.formatDate(DateTime.now().toIso8601String()),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Welcome to ${_settings.storeName}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.3,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Real-time pharmacy point of sale, wholesale inventory, and financial ledger.',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 20),
            Row(
              children: [
                ModernButton(
                  label: 'Open POS Counter',
                  icon: Icons.add_shopping_cart,
                  variant: ModernButtonVariant.primary,
                  onPressed: () => _goTo(1, const PosScreen()),
                ),
                const SizedBox(width: 12),
                ModernButton(
                  label: 'New Purchase',
                  icon: Icons.add_business_rounded,
                  variant: ModernButtonVariant.secondary,
                  onPressed: () => _goTo(6, const PurchasesScreen()),
                ),
              ],
            ),
          ],
        ),
      );
    }

    return GlassCard(
      borderRadius: 20,
      padding: const EdgeInsets.all(18),
      gradient: AppColors.headerGradient,
      border: Border.all(
        color: Colors.white.withValues(alpha: 0.2),
        width: 1.2,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.verified_user_rounded,
                      color: AppColors.secondary, size: 16),
                  SizedBox(width: 6),
                  Text(
                    'STORE OVERVIEW',
                    style: TextStyle(
                      color: AppColors.secondary,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.0,
                    ),
                  ),
                ],
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  Formatters.formatDate(DateTime.now().toIso8601String()),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Text(
            'Ready to serve customers',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.2,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Tap New Sale to initiate counter POS billing or wholesale consignment.',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 12,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 14),
          ModernButton(
            label: 'Open POS Counter',
            icon: Icons.add_shopping_cart,
            variant: ModernButtonVariant.primary,
            onPressed: () => _goTo(1, const PosScreen()),
          ),
        ],
      ),
    );
  }

  Widget _buildAlertsBanner() {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      borderRadius: 18,
      color: const Color(0xFFFFFBEB).withValues(alpha: 0.88),
      border: Border.all(color: AppColors.warning.withValues(alpha: 0.4), width: 1.2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.warning_amber_rounded,
                    color: AppColors.warning, size: 20),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Inventory Needs Attention',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              TextButton(
                onPressed: () => _goTo(8, const InventoryAlertsScreen()),
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  visualDensity: VisualDensity.compact,
                ),
                child: const Text(
                  'Resolve →',
                  style: TextStyle(
                    color: AppColors.warning,
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              if (_alerts.lowStock > 0)
                BadgePill(
                  text: '${_alerts.lowStock} Low Stock',
                  type: BadgeType.warning,
                  icon: Icons.trending_down,
                ),
              if (_alerts.outOfStock > 0)
                BadgePill(
                  text: '${_alerts.outOfStock} Out of Stock',
                  type: BadgeType.danger,
                  icon: Icons.remove_shopping_cart,
                ),
              if (_alerts.expiringSoon > 0)
                BadgePill(
                  text: '${_alerts.expiringSoon} Expiring Soon (<30d)',
                  type: BadgeType.info,
                  icon: Icons.access_time,
                ),
              if (_alerts.expired > 0)
                BadgePill(
                  text: '${_alerts.expired} Expired',
                  type: BadgeType.danger,
                  icon: Icons.event_busy,
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildKpiGrid(bool isWide) {
    return GridView.count(
      crossAxisCount: isWide ? 4 : 2,
      crossAxisSpacing: 14,
      mainAxisSpacing: 14,
      childAspectRatio: isWide ? 2.3 : 1.35,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        StatCard(
          title: "Today's Sales",
          value: Formatters.formatCurrency(
              _todayProfit.revenue, _settings.currency),
          subtitle:
              "Cash: ${Formatters.formatCurrency(_todayCash, _settings.currency)}",
          icon: Icons.point_of_sale_rounded,
          color: AppColors.primaryLight,
          onTap: () => _goTo(2, const InvoicesScreen()),
        ),
        StatCard(
          title: "Today's Net Profit",
          value: Formatters.formatCurrency(_todayProfit.net, _settings.currency),
          subtitle:
              "Margin: ${_todayProfit.netMarginPercent.toStringAsFixed(1)}%",
          icon: Icons.trending_up_rounded,
          color: _todayProfit.net >= 0 ? AppColors.success : AppColors.danger,
          onTap: () => _goTo(11, const ReportsScreen()),
        ),
        StatCard(
          title: "Catalog Medicines",
          value: "$_totalMedicinesCount Items",
          subtitle: "Active stock items",
          icon: Icons.medication_rounded,
          color: AppColors.secondary,
          onTap: () => _goTo(5, const MedicinesScreen()),
        ),
        StatCard(
          title: "Stock Valuation",
          value: Formatters.formatCurrency(_inventoryVal, _settings.currency),
          subtitle: "Total cost value",
          icon: Icons.inventory_2_rounded,
          color: AppColors.accent,
          onTap: () => _goTo(11, const ReportsScreen()),
        ),
      ],
    );
  }

  Widget _buildDesktopQuickActions() {
    final quickItems = [
      {
        'title': 'New POS Sale',
        'icon': Icons.point_of_sale_rounded,
        'color': AppColors.primaryLight,
        'action': () => _goTo(1, const PosScreen()),
      },
      {
        'title': 'Medicines',
        'icon': Icons.medication_rounded,
        'color': const Color(0xFF14B8A6),
        'action': () => _goTo(5, const MedicinesScreen()),
      },
      {
        'title': 'Purchases',
        'icon': Icons.add_business_rounded,
        'color': const Color(0xFF0284C7),
        'action': () => _goTo(6, const PurchasesScreen()),
      },
      {
        'title': 'Retail Cust.',
        'icon': Icons.people_rounded,
        'color': const Color(0xFF0D9488),
        'action': () => _goTo(3, const CustomersScreen(initialTabIndex: 0)),
      },
      {
        'title': 'Wholesale B2B',
        'icon': Icons.business_rounded,
        'color': const Color(0xFF6366F1),
        'action': () => _goTo(4, const CustomersScreen(initialTabIndex: 1)),
      },
      {
        'title': 'Expenses',
        'icon': Icons.account_balance_wallet_rounded,
        'color': const Color(0xFFEA580C),
        'action': () => _goTo(10, const ExpensesScreen()),
      },
      {
        'title': 'Sales Invoices',
        'icon': Icons.receipt_long_rounded,
        'color': AppColors.textSecondary,
        'action': () => _goTo(2, const InvoicesScreen()),
      },
      {
        'title': 'Reports & P&L',
        'icon': Icons.analytics_rounded,
        'color': const Color(0xFF059669),
        'action': () => _goTo(11, const ReportsScreen()),
      },
    ];

    return GlassCard(
      padding: const EdgeInsets.all(18),
      borderRadius: 20,
      color: Colors.white.withValues(alpha: 0.88),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Quick Operations',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
              letterSpacing: 0.1,
            ),
          ),
          const SizedBox(height: 14),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 2.8,
            ),
            itemCount: quickItems.length,
            itemBuilder: (context, i) {
              final item = quickItems[i];
              final color = item['color'] as Color;
              return Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: item['action'] as VoidCallback,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.9)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(item['icon'] as IconData,
                              color: color, size: 16),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            item['title'] as String,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    final actions = [
      {
        'label': 'New Sale',
        'icon': Icons.point_of_sale_rounded,
        'color': AppColors.primaryLight,
        'onTap': () {
          if (widget.onNavigateToPos != null) {
            widget.onNavigateToPos!();
          } else {
            Navigator.push(context,
                MaterialPageRoute(builder: (_) => const PosScreen()));
          }
        },
      },
      {
        'label': 'Medicines',
        'icon': Icons.medication_liquid_rounded,
        'color': const Color(0xFF14B8A6),
        'onTap': () => Navigator.push(
            context, MaterialPageRoute(builder: (_) => const MedicinesScreen()))
      },
      {
        'label': 'Purchases',
        'icon': Icons.add_business_rounded,
        'color': const Color(0xFF0284C7),
        'onTap': () => Navigator.push(
            context, MaterialPageRoute(builder: (_) => const PurchasesScreen()))
      },
      {
        'label': 'Retail Cust.',
        'icon': Icons.people_alt_rounded,
        'color': const Color(0xFF0D9488),
        'onTap': () => Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => const CustomersScreen(initialTabIndex: 0)))
      },
      {
        'label': 'Wholesale B2B',
        'icon': Icons.business_rounded,
        'color': const Color(0xFF6366F1),
        'onTap': () => Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => const CustomersScreen(initialTabIndex: 1)))
      },
      {
        'label': 'Suppliers',
        'icon': Icons.local_shipping_rounded,
        'color': const Color(0xFF8B5CF6),
        'onTap': () => Navigator.push(
            context, MaterialPageRoute(builder: (_) => const SuppliersScreen()))
      },
      {
        'label': 'Alerts',
        'icon': Icons.warning_amber_rounded,
        'color': AppColors.warning,
        'onTap': () => Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => const InventoryAlertsScreen()))
      },
      {
        'label': 'Returns',
        'icon': Icons.assignment_return_rounded,
        'color': const Color(0xFFE11D48),
        'onTap': () => Navigator.push(
            context, MaterialPageRoute(builder: (_) => const ReturnsScreen()))
      },
      {
        'label': 'Expenses',
        'icon': Icons.account_balance_wallet_rounded,
        'color': const Color(0xFFEA580C),
        'onTap': () => Navigator.push(
            context, MaterialPageRoute(builder: (_) => const ExpensesScreen()))
      },
      {
        'label': 'Reports',
        'icon': Icons.analytics_rounded,
        'color': const Color(0xFF059669),
        'onTap': () => Navigator.push(
            context, MaterialPageRoute(builder: (_) => const ReportsScreen()))
      },
      {
        'label': 'Invoices',
        'icon': Icons.receipt_long_rounded,
        'color': AppColors.textSecondary,
        'onTap': () => Navigator.push(
            context, MaterialPageRoute(builder: (_) => const InvoicesScreen()))
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Quick Operations',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
                letterSpacing: 0.1,
              ),
            ),
            Text(
              'Scroll for more',
              style: TextStyle(fontSize: 11, color: AppColors.textMuted),
            ),
          ],
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 92,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: actions.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (context, i) {
              final a = actions[i];
              final color = a['color'] as Color;
              return Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: a['onTap'] as VoidCallback,
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    width: 82,
                    padding: const EdgeInsets.symmetric(
                        vertical: 10, horizontal: 6),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.border),
                      boxShadow: [
                        BoxShadow(
                          color: color.withAlpha(12),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: color.withAlpha(22),
                            shape: BoxShape.circle,
                          ),
                          child:
                              Icon(a['icon'] as IconData, color: color, size: 20),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          a['label'] as String,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildRevenueChart() {
    return GlassCard(
      borderRadius: 20,
      padding: const EdgeInsets.all(18),
      color: Colors.white.withValues(alpha: 0.88),
      border: Border.all(color: Colors.white.withValues(alpha: 0.8), width: 1.2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.bar_chart_rounded,
                      size: 20, color: AppColors.primaryLight),
                  SizedBox(width: 8),
                  Text(
                    '7-Day Sales Performance',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                      letterSpacing: 0.1,
                    ),
                  ),
                ],
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.surfaceSubtle,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.borderLight),
                ),
                child: const Text(
                  'Daily Trend',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SimpleBarChart(data: _revenueTrend, currency: _settings.currency),
        ],
      ),
    );
  }

  Widget _buildTopSellers() {
    return GlassCard(
      borderRadius: 20,
      padding: const EdgeInsets.all(18),
      color: Colors.white.withValues(alpha: 0.88),
      border: Border.all(color: Colors.white.withValues(alpha: 0.8), width: 1.2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.local_fire_department_rounded,
                  color: AppColors.accent, size: 20),
              SizedBox(width: 8),
              Text(
                'Top Fast-Moving Medicines',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ..._topSellers.map((ts) {
            final index = _topSellers.indexOf(ts);
            final rankColors = [
              const Color(0xFFF59E0B), // 1st - Gold
              const Color(0xFF64748B), // 2nd - Silver
              const Color(0xFFB45309), // 3rd - Bronze
            ];
            final rankColor = index < 3 ? rankColors[index] : AppColors.primaryLight;

            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: rankColor.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '#${index + 1}',
                      style: TextStyle(
                        color: rankColor,
                        fontWeight: FontWeight.w900,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          ts.medicineName,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          '${ts.unitsSold.toInt()} units dispensed',
                          style: const TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    Formatters.formatCurrency(ts.revenue, _settings.currency),
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                      color: AppColors.primaryLight,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildRecentInvoices() {
    return GlassCard(
      borderRadius: 20,
      padding: const EdgeInsets.all(18),
      color: Colors.white.withValues(alpha: 0.88),
      border: Border.all(color: Colors.white.withValues(alpha: 0.8), width: 1.2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.history_rounded,
                      size: 20, color: AppColors.primaryLight),
                  SizedBox(width: 8),
                  Text(
                    'Recent Sales & Receipts',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              TextButton(
                onPressed: () => _goTo(2, const InvoicesScreen()),
                child: const Text(
                  'View All →',
                  style: TextStyle(
                    fontSize: 12.5,
                    color: AppColors.primaryLight,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (_recentInvoices.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: Text(
                  'No sales transactions logged today',
                  style: TextStyle(color: AppColors.textMuted, fontSize: 13),
                ),
              ),
            )
          else
            ..._recentInvoices.map((inv) {
              return Container(
                margin: const EdgeInsets.symmetric(vertical: 4),
                padding: const EdgeInsets.all(11),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.9)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(9),
                      decoration: BoxDecoration(
                        color: (inv.isWholesale
                                ? const Color(0xFF6366F1)
                                : AppColors.primaryLight)
                            .withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        inv.isWholesale
                            ? Icons.business_rounded
                            : Icons.receipt_rounded,
                        color: inv.isWholesale
                            ? const Color(0xFF6366F1)
                            : AppColors.primaryLight,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                'Invoice #${inv.id ?? ""}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 13,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 5, vertical: 1.5),
                                decoration: BoxDecoration(
                                  color: (inv.isWholesale
                                          ? const Color(0xFF6366F1)
                                          : AppColors.primaryLight)
                                      .withAlpha(20),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  inv.isWholesale ? 'Wholesale' : 'Retail',
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                    color: inv.isWholesale
                                        ? const Color(0xFF6366F1)
                                        : AppColors.primaryLight,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            inv.customerName ?? "Walk-in Customer",
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 11.5,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            Formatters.formatDateTime(inv.invoiceDate),
                            style: const TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          Formatters.formatCurrency(
                              inv.totalAmount, _settings.currency),
                          style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 13,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        if (inv.remainingAmount > 0.01)
                          Text(
                            'Due: ${Formatters.formatCurrency(inv.remainingAmount, _settings.currency)}',
                            style: const TextStyle(
                              color: AppColors.danger,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                          )
                        else
                          const Text(
                            'Paid in Full',
                            style: TextStyle(
                              color: AppColors.success,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(width: 6),
                    IconButton(
                      icon: const Icon(Icons.print_rounded,
                          size: 19, color: AppColors.textSecondary),
                      onPressed: () =>
                          ThermalReceiptDialog.show(context, inv, _settings),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }
}
