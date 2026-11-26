class SupplierReturn {
  final int? id;
  final int medicineId;
  final int? supplierId;
  final String? supplierNameSnapshot;
  final double quantity;
  final double creditAmount;
  final String? reason;
  final String returnDate; // ISO-8601
  // Display helper
  final String? medicineName;

  SupplierReturn({
    this.id,
    required this.medicineId,
    this.supplierId,
    this.supplierNameSnapshot,
    required this.quantity,
    this.creditAmount = 0.0,
    this.reason,
    required this.returnDate,
    this.medicineName,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'medicineId': medicineId,
      'supplierId': supplierId,
      'supplierNameSnapshot': supplierNameSnapshot,
      'quantity': quantity,
      'creditAmount': creditAmount,
      'reason': reason,
      'returnDate': returnDate,
    };
  }

  factory SupplierReturn.fromMap(Map<String, dynamic> map, [String? medicineName]) {
    return SupplierReturn(
      id: map['id'] as int?,
      medicineId: map['medicineId'] as int,
      supplierId: map['supplierId'] as int?,
      supplierNameSnapshot: map['supplierNameSnapshot'] as String?,
      quantity: (map['quantity'] as num?)?.toDouble() ?? 0.0,
      creditAmount: (map['creditAmount'] as num?)?.toDouble() ?? 0.0,
      reason: map['reason'] as String?,
      returnDate: map['returnDate'] as String? ?? DateTime.now().toIso8601String(),
      medicineName: medicineName ?? map['medicineName'] as String?,
    );
  }
}

