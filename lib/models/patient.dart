class Patient {
  int? id;
  String name;
  String fatherName;
  String phone;
  String address;
  String email;
  String? photoPath;

  Patient({
    this.id,
    required this.name,
    required this.fatherName,
    required this.phone,
    required this.address,
    required this.email,
    this.photoPath,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'fatherName': fatherName,
      'phone': phone,
      'address': address,
      'email': email,
      'photoPath': photoPath,
    };
  }

  factory Patient.fromMap(Map<String, dynamic> map) {
    return Patient(
      id: map['id'],
      name: map['name'],
      fatherName: map['fatherName'],
      phone: map['phone'],
      address: map['address'],
      email: map['email'],
      photoPath: map['photoPath'],
    );
  }
}
