class VendorRequestModel {
  final String id;
  final String vendorId;
  final String vendorName;
  final String vendorImage;
  final String requestType; // 'add_product', 'edit_product'
  final String productName;
  final String productDescription;
  final double productPrice;
  final String productImage;
  final String status; // 'pending', 'approved', 'rejected'
  final DateTime date;

  VendorRequestModel({
    required this.id,
    required this.vendorId,
    required this.vendorName,
    required this.vendorImage,
    required this.requestType,
    required this.productName,
    required this.productDescription,
    required this.productPrice,
    required this.productImage,
    required this.status,
    required this.date,
  });

  factory VendorRequestModel.fromMap(Map<String, dynamic> data, String docId) {
    return VendorRequestModel(
      id: docId,
      vendorId: data['vendorId'] ?? '',
      vendorName: data['vendorName'] ?? 'Unknown Vendor',
      vendorImage: data['vendorImage'] ?? '',
      requestType: data['requestType'] ?? 'add_product',
      productName: data['productName'] ?? '',
      productDescription: data['description'] ?? '',
      productPrice: (data['price'] ?? 0).toDouble(),
      productImage: data['image'] ?? '',
      status: data['status'] ?? 'pending',
      date: (data['createdAt'] as dynamic)?.toDate() ?? DateTime.now(),
    );
  }
}
