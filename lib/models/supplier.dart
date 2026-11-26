class Supplier {
  final int? id;
  final String name;
  final String? phone;
  final String? address;
  final double totalAmount;
  final double paidAmount;
  final double remainingAmount;
  final bool active;

  Supplier({
    this.id,
    required this.name,
    this.phone,
    this.address,
    this.totalAmount = 0.0,
    this.paidAmount = 0.0,
    this.remainingAmount = 0.0,
    this.active = true,
  });

  bool get hasOutstandingPayable => remainingAmount > 0.01;

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'phone': phone,
      'address': address,
      'totalAmount': totalAmount,
      'paidAmount': paidAmount,
      'remainingAmount': remainingAmount,
      'active': active ? 1 : 0,
    };
  }

  factory Supplier.fromMap(Map<String, dynamic> map) {
    return Supplier(
      id: map['id'] as int?,
      name: map['name'] as String? ?? '',
      phone: map['phone'] as String?,
      address: map['address'] as String?,
      totalAmount: (map['totalAmount'] as num?)?.toDouble() ?? 0.0,
      paidAmount: (map['paidAmount'] as num?)?.toDouble() ?? 0.0,
      remainingAmount: (map['remainingAmount'] as num?)?.toDouble() ?? 0.0,
      active: (map['active'] as int?) != 0,
    );
  }

  Supplier copyWith({
    int? id,
    String? name,
    String? phone,
    String? address,
    double? totalAmount,
    double? paidAmount,
    double? remainingAmount,
    bool? active,
  }) {
    return Supplier(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      totalAmount: totalAmount ?? this.totalAmount,
      paidAmount: paidAmount ?? this.paidAmount,
      remainingAmount: remainingAmount ?? this.remainingAmount,
      active: active ?? this.active,
    );
  }
}

