class CustomerReturn {
  final int? id;
  final int medicineId;
  final int? customerId;
  final String? customerNameSnapshot;
  final double quantity;
  final double refundAmount;
  final double buyingPriceSnapshot;
  final String? reason;
  final String returnDate; // ISO-8601
  // Display helper
  final String? medicineName;

  CustomerReturn({
    this.id,
    required this.medicineId,
    this.customerId,
    this.customerNameSnapshot,
    required this.quantity,
    this.refundAmount = 0.0,
    this.buyingPriceSnapshot = 0.0,
    this.reason,
    required this.returnDate,
    this.medicineName,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'medicineId': medicineId,
      'customerId': customerId,
      'customerNameSnapshot': customerNameSnapshot,
      'quantity': quantity,
      'refundAmount': refundAmount,
      'buyingPriceSnapshot': buyingPriceSnapshot,
      'reason': reason,
      'returnDate': returnDate,
    };
  }

  factory CustomerReturn.fromMap(Map<String, dynamic> map, [String? medicineName]) {
    return CustomerReturn(
      id: map['id'] as int?,
      medicineId: map['medicineId'] as int,
      customerId: map['customerId'] as int?,
      customerNameSnapshot: map['customerNameSnapshot'] as String?,
      quantity: (map['quantity'] as num?)?.toDouble() ?? 0.0,
      refundAmount: (map['refundAmount'] as num?)?.toDouble() ?? 0.0,
      buyingPriceSnapshot: (map['buyingPriceSnapshot'] as num?)?.toDouble() ?? 0.0,
      reason: map['reason'] as String?,
      returnDate: map['returnDate'] as String? ?? DateTime.now().toIso8601String(),
      medicineName: medicineName ?? map['medicineName'] as String?,
    );
  }
}

