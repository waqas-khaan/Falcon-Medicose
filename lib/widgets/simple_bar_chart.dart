import 'package:flutter/material.dart';
import '../models/report_models.dart';
import '../utils/app_theme.dart';

class SimpleBarChart extends StatelessWidget {
  final List<DayRevenue> data;
  final String currency;

  const SimpleBarChart({
    super.key,
    required this.data,
    this.currency = 'Rs.',
  });

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return const SizedBox(
        height: 140,
        child: Center(
          child: Text(
            'No sales data available yet',
            style: TextStyle(color: AppColors.textMuted, fontSize: 13),
          ),
        ),
      );
    }

    final maxRevenue = data.fold<double>(0, (prev, e) => e.revenue > prev ? e.revenue : prev);
    final effectiveMax = maxRevenue > 0 ? maxRevenue : 1.0;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      height: 170,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: data.map((item) {
          final heightPercent = (item.revenue / effectiveMax).clamp(0.05, 1.0);

          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (item.revenue > 0)
                    Text(
                      item.revenue >= 1000 ? '${(item.revenue / 1000).toStringAsFixed(1)}k' : item.revenue.toStringAsFixed(0),
                      style: const TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                      maxLines: 1,
                    ),
                  const SizedBox(height: 4),
                  Container(
                    height: 100 * heightPercent,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          item.revenue > 0 ? AppColors.primaryLight : AppColors.border,
                          item.revenue > 0 ? AppColors.primary : AppColors.border,
                        ],
                      ),
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    item.dateLabel,
                    style: const TextStyle(
                      fontSize: 10,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
