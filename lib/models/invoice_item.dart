class InvoiceItem {
  final int? id;
  final int? invoiceId;
  final int? medicineId;
  final String medicineName;
  final String? companyName;
  final double quantity;
  final double unitPrice;
  final double discountPercent;
  final double buyingPrice;
  final double totalPrice;

  InvoiceItem({
    this.id,
    this.invoiceId,
    this.medicineId,
    required this.medicineName,
    this.companyName,
    required this.quantity,
    required this.unitPrice,
    this.discountPercent = 0.0,
    this.buyingPrice = 0.0,
    required this.totalPrice,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'invoiceId': invoiceId,
      'medicineId': medicineId,
      'medicineName': medicineName,
      'companyName': companyName,
      'quantity': quantity,
      'unitPrice': unitPrice,
      'discountPercent': discountPercent,
      'buyingPrice': buyingPrice,
      'totalPrice': totalPrice,
    };
  }

  factory InvoiceItem.fromMap(Map<String, dynamic> map) {
    return InvoiceItem(
      id: map['id'] as int?,
      invoiceId: map['invoiceId'] as int?,
      medicineId: map['medicineId'] as int?,
      medicineName: map['medicineName'] as String? ?? '',
      companyName: map['companyName'] as String?,
      quantity: (map['quantity'] as num?)?.toDouble() ?? 0.0,
      unitPrice: (map['unitPrice'] as num?)?.toDouble() ?? 0.0,
      discountPercent: (map['discountPercent'] as num?)?.toDouble() ?? 0.0,
      buyingPrice: (map['buyingPrice'] as num?)?.toDouble() ?? 0.0,
      totalPrice: (map['totalPrice'] as num?)?.toDouble() ?? 0.0,
    );
  }

  InvoiceItem copyWith({
    int? id,
    int? invoiceId,
    int? medicineId,
    String? medicineName,
    String? companyName,
    double? quantity,
    double? unitPrice,
    double? discountPercent,
    double? buyingPrice,
    double? totalPrice,
  }) {
    return InvoiceItem(
      id: id ?? this.id,
      invoiceId: invoiceId ?? this.invoiceId,
      medicineId: medicineId ?? this.medicineId,
      medicineName: medicineName ?? this.medicineName,
      companyName: companyName ?? this.companyName,
      quantity: quantity ?? this.quantity,
      unitPrice: unitPrice ?? this.unitPrice,
      discountPercent: discountPercent ?? this.discountPercent,
      buyingPrice: buyingPrice ?? this.buyingPrice,
      totalPrice: totalPrice ?? this.totalPrice,
    );
  }
}

