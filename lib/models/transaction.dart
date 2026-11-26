class TransactionModel {
  int? id;
  int patientId;
  double amount;
  String type;
  String date;
  String createdAt;
  String remarks;

  TransactionModel({
    this.id,
    required this.patientId,
    required this.amount,
    required this.type,
    required this.date,
    required this.createdAt,
    required this.remarks,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'patientId': patientId,
      'amount': amount,
      'type': type,
      'date': date,
      'createdAt': createdAt,
      'remarks': remarks,
    };
  }

  factory TransactionModel.fromMap(Map<String, dynamic> map) {
    return TransactionModel(
      id: map['id'],
      patientId: map['patientId'],
      amount: (map['amount'] as num).toDouble(),
      type: map['type'],
      date: map['date'],
      createdAt: map['createdAt'],
      remarks: map['remarks'] ?? "",
    );
  }
}
