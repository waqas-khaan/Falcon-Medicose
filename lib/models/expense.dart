class Expense {
  final int? id;
  final String title;
  final String category;
  final double amount;
  final String? notes;
  final String expenseDate; // YYYY-MM-DD or ISO

  Expense({
    this.id,
    required this.title,
    required this.category,
    required this.amount,
    this.notes,
    required this.expenseDate,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'title': title,
      'category': category,
      'amount': amount,
      'notes': notes,
      'expenseDate': expenseDate,
    };
  }

  factory Expense.fromMap(Map<String, dynamic> map) {
    return Expense(
      id: map['id'] as int?,
      title: map['title'] as String? ?? '',
      category: map['category'] as String? ?? 'General',
      amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
      notes: map['notes'] as String?,
      expenseDate: map['expenseDate'] as String? ?? DateTime.now().toIso8601String(),
    );
  }
}

