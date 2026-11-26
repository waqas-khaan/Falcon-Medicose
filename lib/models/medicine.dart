import 'unit_type.dart';

class Medicine {
  final int? id;
  final String name;
  final String? companyName;
  final String? category;
  final UnitType unitType;
  final double buyingPrice;      // Cost / Purchase price from supplier
  final double retailPrice;      // Retail / MRP (Printed price on medicine box)
  final double sellingPrice;     // Counter / POS Selling price to customers
  final double discountPercent;  // Default Wholesale discount %
  final double extraDiscountPercent; // Extra / Special discount %
  final double currentStock;
  final double minStockLevel;
  final String? nearestExpiryDate; // YYYY-MM-DD
  final bool active;

  Medicine({
    this.id,
    required this.name,
    this.companyName,
    this.category,
    this.unitType = UnitType.strip,
    this.buyingPrice = 0.0,
    this.retailPrice = 0.0,
    required this.sellingPrice,
    this.discountPercent = 0.0,
    this.extraDiscountPercent = 0.0,
    this.currentStock = 0.0,
    this.minStockLevel = 5.0,
    this.nearestExpiryDate,
    this.active = true,
  });

  bool get isLowStock => currentStock <= minStockLevel && currentStock > 0;
  bool get isOutOfStock => currentStock <= 0;

  /// Effective retail price (falls back to sellingPrice if retailPrice not set)
  double get effectiveRetailPrice => retailPrice > 0 ? retailPrice : sellingPrice;

  /// Total combined discount percentage (Wholesale % + Extra %)
  double get totalDiscountPercent => discountPercent + extraDiscountPercent;

  /// Effective wholesale price after applying total discount
  double get effectiveWholesalePrice {
    final base = effectiveRetailPrice;
    if (totalDiscountPercent > 0) {
      return base - (base * (totalDiscountPercent / 100));
    }
    return base;
  }

  /// Profit margin in Rs (Selling Price - Buying/Cost Price)
  double get profitMargin => sellingPrice - buyingPrice;

  /// Profit margin percentage based on cost
  double get profitMarginPercent => buyingPrice > 0 ? ((sellingPrice - buyingPrice) / buyingPrice) * 100 : 0.0;

  /// Discount percentage from Retail (MRP) to Selling Price
  double get retailDiscountPercent {
    final effective = effectiveRetailPrice;
    if (effective > sellingPrice && effective > 0) {
      return ((effective - sellingPrice) / effective) * 100;
    }
    return 0.0;
  }

  bool isExpiringSoon([int days = 30]) {
    if (nearestExpiryDate == null || nearestExpiryDate!.isEmpty) return false;
    try {
      final expiry = DateTime.parse(nearestExpiryDate!);
      final now = DateTime.now();
      final difference = expiry.difference(now).inDays;
      return difference >= 0 && difference <= days;
    } catch (_) {
      return false;
    }
  }

  bool isExpired() {
    if (nearestExpiryDate == null || nearestExpiryDate!.isEmpty) return false;
    try {
      final expiry = DateTime.parse(nearestExpiryDate!);
      final today = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
      return expiry.isBefore(today);
    } catch (_) {
      return false;
    }
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'companyName': companyName,
      'category': category,
      'unitType': unitType.toDbString(),
      'buyingPrice': buyingPrice,
      'retailPrice': retailPrice > 0 ? retailPrice : sellingPrice,
      'discountPercent': discountPercent,
      'extraDiscountPercent': extraDiscountPercent,
      'sellingPrice': sellingPrice,
      'currentStock': currentStock,
      'minStockLevel': minStockLevel,
      'nearestExpiryDate': nearestExpiryDate,
      'active': active ? 1 : 0,
    };
  }

  factory Medicine.fromMap(Map<String, dynamic> map) {
    final selling = (map['sellingPrice'] as num?)?.toDouble() ?? 0.0;
    final retail = (map['retailPrice'] as num?)?.toDouble() ?? selling;
    return Medicine(
      id: map['id'] as int?,
      name: map['name'] as String? ?? '',
      companyName: map['companyName'] as String?,
      category: map['category'] as String?,
      unitType: UnitType.fromString(map['unitType'] as String?),
      buyingPrice: (map['buyingPrice'] as num?)?.toDouble() ?? 0.0,
      retailPrice: retail > 0 ? retail : selling,
      discountPercent: (map['discountPercent'] as num?)?.toDouble() ?? 0.0,
      extraDiscountPercent: (map['extraDiscountPercent'] as num?)?.toDouble() ?? 0.0,
      sellingPrice: selling,
      currentStock: (map['currentStock'] as num?)?.toDouble() ?? 0.0,
      minStockLevel: (map['minStockLevel'] as num?)?.toDouble() ?? 5.0,
      nearestExpiryDate: map['nearestExpiryDate'] as String?,
      active: (map['active'] as int?) != 0,
    );
  }

  Medicine copyWith({
    int? id,
    String? name,
    String? companyName,
    String? category,
    UnitType? unitType,
    double? buyingPrice,
    double? retailPrice,
    double? discountPercent,
    double? extraDiscountPercent,
    double? sellingPrice,
    double? currentStock,
    double? minStockLevel,
    String? nearestExpiryDate,
    bool? active,
  }) {
    return Medicine(
      id: id ?? this.id,
      name: name ?? this.name,
      companyName: companyName ?? this.companyName,
      category: category ?? this.category,
      unitType: unitType ?? this.unitType,
      buyingPrice: buyingPrice ?? this.buyingPrice,
      retailPrice: retailPrice ?? this.retailPrice,
      discountPercent: discountPercent ?? this.discountPercent,
      extraDiscountPercent: extraDiscountPercent ?? this.extraDiscountPercent,
      sellingPrice: sellingPrice ?? this.sellingPrice,
      currentStock: currentStock ?? this.currentStock,
      minStockLevel: minStockLevel ?? this.minStockLevel,
      nearestExpiryDate: nearestExpiryDate ?? this.nearestExpiryDate,
      active: active ?? this.active,
    );
  }
}

