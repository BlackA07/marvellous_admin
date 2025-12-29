class OrderModel {
  final String id;
  final String customerId;
  final String customerName;
  final String customerImage; // URL
  final String customerPhone;
  final String customerAddress;
  final String productName;
  final String productImage;
  final double price;
  final String status; // 'pending', 'accepted', 'rejected'
  final DateTime date;

  OrderModel({
    required this.id,
    required this.customerId,
    required this.customerName,
    required this.customerImage,
    required this.customerPhone,
    required this.customerAddress,
    required this.productName,
    required this.productImage,
    required this.price,
    required this.status,
    required this.date,
  });

  factory OrderModel.fromMap(Map<String, dynamic> data, String docId) {
    return OrderModel(
      id: docId,
      customerId: data['customerId'] ?? '',
      customerName: data['customerName'] ?? 'Unknown',
      customerImage: data['customerImage'] ?? '',
      customerPhone: data['customerPhone'] ?? '',
      customerAddress: data['customerAddress'] ?? '',
      productName: data['productName'] ?? '',
      productImage: data['productImage'] ?? '',
      price: (data['price'] ?? 0).toDouble(),
      status: data['status'] ?? 'pending',
      date: (data['createdAt'] as dynamic)?.toDate() ?? DateTime.now(),
    );
  }
}
