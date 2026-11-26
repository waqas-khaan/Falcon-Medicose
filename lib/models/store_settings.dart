class StoreSettings {
  final int id;
  final String storeName;
  final String phone;
  final String address;
  final String currency;
  final double lowStockThreshold;
  final String receiptFooter;

  StoreSettings({
    this.id = 1,
    this.storeName = 'Falcon Medicose',
    this.phone = '0300-1234567',
    this.address = 'Main Bazar, Healthcare Plaza',
    this.currency = 'Rs.',
    this.lowStockThreshold = 5.0,
    this.receiptFooter = 'Thank you for your visit! Wishing you good health.',
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'storeName': storeName,
      'phone': phone,
      'address': address,
      'currency': currency,
      'lowStockThreshold': lowStockThreshold,
      'receiptFooter': receiptFooter,
    };
  }

  factory StoreSettings.fromMap(Map<String, dynamic> map) {
    return StoreSettings(
      id: map['id'] as int? ?? 1,
      storeName: map['storeName'] as String? ?? 'Falcon Medicose',
      phone: map['phone'] as String? ?? '',
      address: map['address'] as String? ?? '',
      currency: map['currency'] as String? ?? 'Rs.',
      lowStockThreshold: (map['lowStockThreshold'] as num?)?.toDouble() ?? 5.0,
      receiptFooter: map['receiptFooter'] as String? ?? 'Thank you for your visit! Wishing you good health.',
    );
  }

  StoreSettings copyWith({
    int? id,
    String? storeName,
    String? phone,
    String? address,
    String? currency,
    double? lowStockThreshold,
    String? receiptFooter,
  }) {
    return StoreSettings(
      id: id ?? this.id,
      storeName: storeName ?? this.storeName,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      currency: currency ?? this.currency,
      lowStockThreshold: lowStockThreshold ?? this.lowStockThreshold,
      receiptFooter: receiptFooter ?? this.receiptFooter,
    );
  }
}

