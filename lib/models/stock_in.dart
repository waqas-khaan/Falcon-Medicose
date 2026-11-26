class StockIn {
  final int? id;
  final int medicineId;
  final int? supplierId;
  final int? purchaseInvoiceId;
  final double quantity;
  final double buyingPrice;
  final String? batchNumber;
  final String? expiryDate; // YYYY-MM-DD
  final String purchaseDate; // YYYY-MM-DD or ISO
  // Denormalized/snapshot display fields
  final String? medicineName;
  final String? supplierName;

  StockIn({
    this.id,
    required this.medicineId,
    this.supplierId,
    this.purchaseInvoiceId,
    required this.quantity,
    required this.buyingPrice,
    this.batchNumber,
    this.expiryDate,
    required this.purchaseDate,
    this.medicineName,
    this.supplierName,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'medicineId': medicineId,
      'supplierId': supplierId,
      'purchaseInvoiceId': purchaseInvoiceId,
      'quantity': quantity,
      'buyingPrice': buyingPrice,
      'batchNumber': batchNumber,
      'expiryDate': expiryDate,
      'purchaseDate': purchaseDate,
    };
  }

  factory StockIn.fromMap(Map<String, dynamic> map, [String? medicineName, String? supplierName]) {
    return StockIn(
      id: map['id'] as int?,
      medicineId: map['medicineId'] as int,
      supplierId: map['supplierId'] as int?,
      purchaseInvoiceId: map['purchaseInvoiceId'] as int?,
      quantity: (map['quantity'] as num?)?.toDouble() ?? 0.0,
      buyingPrice: (map['buyingPrice'] as num?)?.toDouble() ?? 0.0,
      batchNumber: map['batchNumber'] as String?,
      expiryDate: map['expiryDate'] as String?,
      purchaseDate: map['purchaseDate'] as String? ?? DateTime.now().toIso8601String(),
      medicineName: medicineName ?? map['medicineName'] as String?,
      supplierName: supplierName ?? map['supplierName'] as String?,
    );
  }
}

