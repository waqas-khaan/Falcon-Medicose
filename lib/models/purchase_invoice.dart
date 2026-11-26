import 'stock_in.dart';

class PurchaseInvoice {
  final int? id;
  final int? supplierId;
  final String? supplierNameSnapshot;
  final double totalAmount;
  final double paidAmount;
  final double remainingAmount;
  final String purchaseDate;
  final List<StockIn> items;

  PurchaseInvoice({
    this.id,
    this.supplierId,
    this.supplierNameSnapshot,
    required this.totalAmount,
    required this.paidAmount,
    this.remainingAmount = 0.0,
    required this.purchaseDate,
    this.items = const [],
  });

  bool get hasRemainingPayable => remainingAmount > 0.01;

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'supplierId': supplierId,
      'supplierNameSnapshot': supplierNameSnapshot,
      'totalAmount': totalAmount,
      'paidAmount': paidAmount,
      'remainingAmount': remainingAmount,
      'purchaseDate': purchaseDate,
    };
  }

  factory PurchaseInvoice.fromMap(Map<String, dynamic> map, [List<StockIn> items = const []]) {
    return PurchaseInvoice(
      id: map['id'] as int?,
      supplierId: map['supplierId'] as int?,
      supplierNameSnapshot: map['supplierNameSnapshot'] as String?,
      totalAmount: (map['totalAmount'] as num?)?.toDouble() ?? 0.0,
      paidAmount: (map['paidAmount'] as num?)?.toDouble() ?? 0.0,
      remainingAmount: (map['remainingAmount'] as num?)?.toDouble() ?? 0.0,
      purchaseDate: map['purchaseDate'] as String? ?? DateTime.now().toIso8601String(),
      items: items,
    );
  }
}

