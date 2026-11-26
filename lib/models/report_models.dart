class ProfitSummary {
  final double revenue;
  final double cost;
  final double gross;
  final double expenses;
  final double net;
  final double retailRevenue;
  final double wholesaleRevenue;

  ProfitSummary({
    required this.revenue,
    required this.cost,
    required this.gross,
    required this.expenses,
    required this.net,
    this.retailRevenue = 0.0,
    this.wholesaleRevenue = 0.0,
  });

  double get grossMarginPercent => revenue > 0 ? (gross / revenue) * 100 : 0.0;
  double get netMarginPercent => revenue > 0 ? (net / revenue) * 100 : 0.0;
}

class DayRevenue {
  final String dateLabel;
  final double revenue;

  DayRevenue(this.dateLabel, this.revenue);
}

class TopSeller {
  final String medicineName;
  final double unitsSold;
  final double revenue;

  TopSeller({
    required this.medicineName,
    required this.unitsSold,
    required this.revenue,
  });
}

class CategoryCount {
  final String category;
  final int count;

  CategoryCount(this.category, this.count);
}

class NeedsAttention {
  final int lowStock;
  final int outOfStock;
  final int expired;
  final int expiringSoon;

  NeedsAttention({
    required this.lowStock,
    required this.outOfStock,
    required this.expired,
    required this.expiringSoon,
  });

  int get totalIssues => lowStock + outOfStock + expired + expiringSoon;
  bool get hasIssues => totalIssues > 0;
}
