class SupplierPayment {
  final int? id;
  final int? supplierId;
  final int? purchaseInvoiceId;
  final double amount;
  final String paymentDate;
  // Snapshot/display
  final String? supplierName;

  SupplierPayment({
    this.id,
    this.supplierId,
    this.purchaseInvoiceId,
    required this.amount,
    required this.paymentDate,
    this.supplierName,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'supplierId': supplierId,
      'purchaseInvoiceId': purchaseInvoiceId,
      'amount': amount,
      'paymentDate': paymentDate,
    };
  }

  factory SupplierPayment.fromMap(Map<String, dynamic> map, [String? supplierName]) {
    return SupplierPayment(
      id: map['id'] as int?,
      supplierId: map['supplierId'] as int?,
      purchaseInvoiceId: map['purchaseInvoiceId'] as int?,
      amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
      paymentDate: map['paymentDate'] as String? ?? DateTime.now().toIso8601String(),
      supplierName: supplierName ?? map['supplierName'] as String?,
    );
  }
}

