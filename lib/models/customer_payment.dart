class CustomerPayment {
  final int? id;
  final int? customerId;
  final int? invoiceId;
  final double amount;
  final String paymentDate;
  // Snapshot/display
  final String? customerName;

  CustomerPayment({
    this.id,
    this.customerId,
    this.invoiceId,
    required this.amount,
    required this.paymentDate,
    this.customerName,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'customerId': customerId,
      'invoiceId': invoiceId,
      'amount': amount,
      'paymentDate': paymentDate,
    };
  }

  factory CustomerPayment.fromMap(Map<String, dynamic> map, [String? customerName]) {
    return CustomerPayment(
      id: map['id'] as int?,
      customerId: map['customerId'] as int?,
      invoiceId: map['invoiceId'] as int?,
      amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
      paymentDate: map['paymentDate'] as String? ?? DateTime.now().toIso8601String(),
      customerName: customerName ?? map['customerName'] as String?,
    );
  }
}

