import 'invoice_item.dart';

class InvoiceType {
  static const String retail = 'RETAIL';
  static const String wholesale = 'WHOLESALE';
}

class Invoice {
  final int? id;
  final int? customerId;
  final String? customerName;
  final String? customerPhone;
  final String invoiceType; // 'RETAIL' or 'WHOLESALE'
  final String? roomNumber;
  final String? doctorName;
  final double totalAmount;
  final double discount;
  final double paidAmount;
  final double remainingAmount;
  final String invoiceDate; // ISO-8601 string
  final List<InvoiceItem> items;

  Invoice({
    this.id,
    this.customerId,
    this.customerName,
    this.customerPhone,
    this.invoiceType = InvoiceType.retail,
    this.roomNumber,
    this.doctorName,
    required this.totalAmount,
    this.discount = 0.0,
    required this.paidAmount,
    this.remainingAmount = 0.0,
    required this.invoiceDate,
    this.items = const [],
  });

  bool get hasRemainingBalance => remainingAmount > 0.01;
  bool get isWholesale => invoiceType == InvoiceType.wholesale;

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'customerId': customerId,
      'customerName': customerName,
      'customerPhone': customerPhone,
      'invoiceType': invoiceType,
      'roomNumber': roomNumber,
      'doctorName': doctorName,
      'totalAmount': totalAmount,
      'discount': discount,
      'paidAmount': paidAmount,
      'remainingAmount': remainingAmount,
      'invoiceDate': invoiceDate,
    };
  }

  factory Invoice.fromMap(Map<String, dynamic> map, [List<InvoiceItem> items = const []]) {
    return Invoice(
      id: map['id'] as int?,
      customerId: map['customerId'] as int?,
      customerName: map['customerName'] as String?,
      customerPhone: map['customerPhone'] as String?,
      invoiceType: map['invoiceType'] as String? ?? InvoiceType.retail,
      roomNumber: map['roomNumber'] as String?,
      doctorName: map['doctorName'] as String?,
      totalAmount: (map['totalAmount'] as num?)?.toDouble() ?? 0.0,
      discount: (map['discount'] as num?)?.toDouble() ?? 0.0,
      paidAmount: (map['paidAmount'] as num?)?.toDouble() ?? 0.0,
      remainingAmount: (map['remainingAmount'] as num?)?.toDouble() ?? 0.0,
      invoiceDate: map['invoiceDate'] as String? ?? DateTime.now().toIso8601String(),
      items: items,
    );
  }

  Invoice copyWith({
    int? id,
    int? customerId,
    String? customerName,
    String? customerPhone,
    String? invoiceType,
    String? roomNumber,
    String? doctorName,
    double? totalAmount,
    double? discount,
    double? paidAmount,
    double? remainingAmount,
    String? invoiceDate,
    List<InvoiceItem>? items,
  }) {
    return Invoice(
      id: id ?? this.id,
      customerId: customerId ?? this.customerId,
      customerName: customerName ?? this.customerName,
      customerPhone: customerPhone ?? this.customerPhone,
      invoiceType: invoiceType ?? this.invoiceType,
      roomNumber: roomNumber ?? this.roomNumber,
      doctorName: doctorName ?? this.doctorName,
      totalAmount: totalAmount ?? this.totalAmount,
      discount: discount ?? this.discount,
      paidAmount: paidAmount ?? this.paidAmount,
      remainingAmount: remainingAmount ?? this.remainingAmount,
      invoiceDate: invoiceDate ?? this.invoiceDate,
      items: items ?? this.items,
    );
  }
}
