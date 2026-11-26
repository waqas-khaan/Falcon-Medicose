import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../models/report_models.dart';
import '../models/store_settings.dart';
import '../utils/app_theme.dart';
import '../utils/formatters.dart';
import '../widgets/glass_widgets.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  String _selectedPeriod = 'today'; // today, month, all
  StoreSettings _settings = StoreSettings();
  ProfitSummary _profit =
      ProfitSummary(revenue: 0, cost: 0, gross: 0, expenses: 0, net: 0);
  Map<String, double> _inventoryValuation = {
    'cost': 0,
    'retail': 0,
    'potentialProfit': 0
  };
  List<TopSeller> _topSellers = [];
  List<CategoryCount> _categoryCounts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadReportData();
  }

  Future<void> _loadReportData() async {
    setState(() => _isLoading = true);
    final settings = await DatabaseHelper.getSettings();
    final profit = await DatabaseHelper.getProfitSummary(_selectedPeriod);
    final valuation = await DatabaseHelper.getFullInventoryValuation();
    final topSellers = await DatabaseHelper.getTopSellers(10);
    final catCounts = await DatabaseHelper.getStockByCategory();

    if (mounted) {
      setState(() {
        _settings = settings;
        _profit = profit;
        _inventoryValuation = valuation;
        _topSellers = topSellers;
        _categoryCounts = catCounts;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = ResponsiveBreakpoints.isDesktop(context);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('Reports & Analytics'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh Reports',
            onPressed: _loadReportData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primaryLight))
          : RefreshIndicator(
              onRefresh: _loadReportData,
              color: AppColors.primaryLight,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1200),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Period Selector
                        Center(
                          child: SegmentedButton<String>(
                            segments: const [
                              ButtonSegment(
                                  value: 'today',
                                  label: Text('Today',
                                      style: TextStyle(
                                          fontWeight: FontWeight.w600))),
                              ButtonSegment(
                                  value: 'month',
                                  label: Text('This Month',
                                      style: TextStyle(
                                          fontWeight: FontWeight.w600))),
                              ButtonSegment(
                                  value: 'all',
                                  label: Text('All Time',
                                      style: TextStyle(
                                          fontWeight: FontWeight.w600))),
                            ],
                            selected: {_selectedPeriod},
                            onSelectionChanged: (set) {
                              setState(() {
                                _selectedPeriod = set.first;
                              });
                              _loadReportData();
                            },
                          ),
                        ),
                        const SizedBox(height: 16),

                        if (isDesktop) ...[
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                flex: 6,
                                child: _buildProfitLossCard(),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                flex: 5,
                                child: Column(
                                  children: [
                                    _buildValuationCard(),
                                    const SizedBox(height: 16),
                                    _buildCategoryBreakdownCard(),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          _buildTopSellersCard(),
                        ] else ...[
                          _buildProfitLossCard(),
                          const SizedBox(height: 16),
                          _buildValuationCard(),
                          const SizedBox(height: 16),
                          _buildTopSellersCard(),
                          const SizedBox(height: 16),
                          _buildCategoryBreakdownCard(),
                        ],
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildProfitLossCard() {
    final isProfitable = _profit.net >= 0;

    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.query_stats_rounded,
                      color: AppColors.primaryLight, size: 22),
                  SizedBox(width: 8),
                  Text(
                    'Profit & Loss (Accrual)',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary),
                  ),
                ],
              ),
              StatusBadge(
                label:
                    '${_profit.netMarginPercent.toStringAsFixed(1)}% Margin',
                color: isProfitable ? AppColors.success : AppColors.danger,
                icon: isProfitable
                    ? Icons.trending_up_rounded
                    : Icons.trending_down_rounded,
              ),
            ],
          ),
          const SizedBox(height: 16),

          _buildReportRow(
              'Revenue (Sales - Returns)',
              Formatters.formatCurrency(_profit.revenue, _settings.currency),
              isBold: true),
          const SizedBox(height: 8),

          // Retail vs Wholesale Breakdown
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Column(
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.shopping_bag_outlined,
                            size: 13, color: AppColors.primaryLight),
                        SizedBox(width: 4),
                        Text('Retail Sales',
                            style: TextStyle(
                                fontSize: 11,
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.w600)),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      Formatters.formatCurrency(
                          _profit.retailRevenue, _settings.currency),
                      style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: AppColors.primaryLight),
                    ),
                  ],
                ),
                Container(width: 1, height: 26, color: AppColors.border),
                Column(
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.business_outlined,
                            size: 13, color: Color(0xFF6366F1)),
                        SizedBox(width: 4),
                        Text('Wholesale B2B',
                            style: TextStyle(
                                fontSize: 11,
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.w600)),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      Formatters.formatCurrency(
                          _profit.wholesaleRevenue, _settings.currency),
                      style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: Color(0xFF6366F1)),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          _buildReportRow(
              'Cost of Goods Sold (COGS)',
              '- ${Formatters.formatCurrency(_profit.cost, _settings.currency)}',
              color: AppColors.textSecondary),
          const Divider(height: 18, color: AppColors.borderLight),
          _buildReportRow(
            'Gross Profit',
            Formatters.formatCurrency(_profit.gross, _settings.currency),
            isBold: true,
            color: _profit.gross >= 0 ? AppColors.primaryLight : AppColors.danger,
          ),
          const SizedBox(height: 6),
          _buildReportRow(
              'Operating Expenses',
              '- ${Formatters.formatCurrency(_profit.expenses, _settings.currency)}',
              color: const Color(0xFFEA580C)),
          const Divider(height: 18, color: AppColors.borderLight),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              gradient: isProfitable
                  ? AppColors.emeraldGradient.scale(0.15)
                  : null,
              color: isProfitable
                  ? null
                  : AppColors.danger.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: _buildReportRow(
              'NET PROFIT',
              Formatters.formatCurrency(_profit.net, _settings.currency),
              isBold: true,
              fontSize: 16,
              color: isProfitable ? AppColors.success : AppColors.danger,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildValuationCard() {
    return GlassCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.inventory_2_outlined,
                  color: AppColors.primaryLight, size: 20),
              SizedBox(width: 8),
              Text(
                'Inventory Stock Valuation',
                style: TextStyle(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Total Cost Value',
                        style: TextStyle(
                            fontSize: 11, color: AppColors.textMuted)),
                    const SizedBox(height: 2),
                    Text(
                      Formatters.formatCurrency(
                          _inventoryValuation['cost'] ?? 0,
                          _settings.currency),
                      style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                          color: AppColors.secondary),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Retail / Selling Value',
                        style: TextStyle(
                            fontSize: 11, color: AppColors.textMuted)),
                    const SizedBox(height: 2),
                    Text(
                      Formatters.formatCurrency(
                          _inventoryValuation['retail'] ?? 0,
                          _settings.currency),
                      style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                          color: AppColors.primaryLight),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Potential Stock Profit:',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppColors.success)),
                Text(
                  Formatters.formatCurrency(
                      _inventoryValuation['potentialProfit'] ?? 0,
                      _settings.currency),
                  style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                      color: AppColors.success),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopSellersCard() {
    return GlassCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.leaderboard_rounded,
                  color: AppColors.primaryLight, size: 20),
              SizedBox(width: 8),
              Text(
                'Top 10 Best Sellers',
                style: TextStyle(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_topSellers.isEmpty)
            const Text('No sales records available yet',
                style: TextStyle(color: AppColors.textMuted, fontSize: 13))
          else
            ..._topSellers.map((ts) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        gradient: _topSellers.indexOf(ts) < 3
                            ? AppColors.primaryActionGradient
                            : null,
                        color: _topSellers.indexOf(ts) >= 3
                            ? AppColors.primaryLight.withValues(alpha: 0.12)
                            : null,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '${_topSellers.indexOf(ts) + 1}',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            color: _topSellers.indexOf(ts) < 3
                                ? Colors.white
                                : AppColors.primaryLight),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(ts.medicineName,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600, fontSize: 13)),
                          Text('${ts.unitsSold.toInt()} units',
                              style: const TextStyle(
                                  fontSize: 11, color: AppColors.textMuted)),
                        ],
                      ),
                    ),
                    Text(
                      Formatters.formatCurrency(ts.revenue, _settings.currency),
                      style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                          color: AppColors.primaryLight),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildCategoryBreakdownCard() {
    return GlassCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.pie_chart_outline_rounded,
                  color: AppColors.primaryLight, size: 20),
              SizedBox(width: 8),
              Text(
                'Stock by Category',
                style: TextStyle(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ..._categoryCounts.map((cc) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 5),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(cc.category,
                      style: const TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w500)),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Text('${cc.count} medicines',
                        style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textSecondary)),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildReportRow(String label, String value,
      {bool isBold = false, Color? color, double fontSize = 13}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            color: AppColors.textPrimary,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: isBold ? FontWeight.w800 : FontWeight.w600,
            color: color ?? AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}
