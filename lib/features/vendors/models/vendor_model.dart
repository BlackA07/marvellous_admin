class VendorModel {
  String? id;
  String name;
  String storeName;
  String phone;
  String cnic;
  String address;
  String speciality; // Example: Electronics, Fashion

  VendorModel({
    this.id,
    required this.name,
    required this.storeName,
    required this.phone,
    required this.cnic,
    required this.address,
    required this.speciality,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'storeName': storeName,
      'phone': phone,
      'cnic': cnic,
      'address': address,
      'speciality': speciality,
    };
  }

  factory VendorModel.fromMap(Map<String, dynamic> map, String docId) {
    return VendorModel(
      id: docId,
      name: map['name'] ?? '',
      storeName: map['storeName'] ?? '',
      phone: map['phone'] ?? '',
      cnic: map['cnic'] ?? '',
      address: map['address'] ?? '',
      speciality: map['speciality'] ?? '',
    );
  }
}
