class CustomerType {
  static const String retail = 'RETAIL';
  static const String wholesale = 'WHOLESALE';
}

class Customer {
  final int? id;
  final String name;
  final String? phone;
  final String? address;
  final String customerType; // 'RETAIL' or 'WHOLESALE'
  final String? companyName; // for Wholesale (e.g. Pharmacy / Clinic name)
  final double totalAmount;
  final double paidAmount;
  final double remainingAmount;
  final bool active;

  Customer({
    this.id,
    required this.name,
    this.phone,
    this.address,
    this.customerType = CustomerType.retail,
    this.companyName,
    this.totalAmount = 0.0,
    this.paidAmount = 0.0,
    this.remainingAmount = 0.0,
    this.active = true,
  });

  bool get hasOutstandingLoan => remainingAmount > 0.01;
  bool get isWholesale => customerType == CustomerType.wholesale;
  bool get isRetail => customerType == CustomerType.retail;

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'phone': phone,
      'address': address,
      'customerType': customerType,
      'companyName': companyName,
      'totalAmount': totalAmount,
      'paidAmount': paidAmount,
      'remainingAmount': remainingAmount,
      'active': active ? 1 : 0,
    };
  }

  factory Customer.fromMap(Map<String, dynamic> map) {
    return Customer(
      id: map['id'] as int?,
      name: map['name'] as String? ?? '',
      phone: map['phone'] as String?,
      address: map['address'] as String?,
      customerType: map['customerType'] as String? ?? CustomerType.retail,
      companyName: map['companyName'] as String?,
      totalAmount: (map['totalAmount'] as num?)?.toDouble() ?? 0.0,
      paidAmount: (map['paidAmount'] as num?)?.toDouble() ?? 0.0,
      remainingAmount: (map['remainingAmount'] as num?)?.toDouble() ?? 0.0,
      active: (map['active'] as int?) != 0,
    );
  }

  Customer copyWith({
    int? id,
    String? name,
    String? phone,
    String? address,
    String? customerType,
    String? companyName,
    double? totalAmount,
    double? paidAmount,
    double? remainingAmount,
    bool? active,
  }) {
    return Customer(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      customerType: customerType ?? this.customerType,
      companyName: companyName ?? this.companyName,
      totalAmount: totalAmount ?? this.totalAmount,
      paidAmount: paidAmount ?? this.paidAmount,
      remainingAmount: remainingAmount ?? this.remainingAmount,
      active: active ?? this.active,
    );
  }
}
