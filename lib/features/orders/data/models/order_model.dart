import 'package:cloud_firestore/cloud_firestore.dart';

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
    // --- 1. SMART DATA EXTRACTION ---
    String extractedName = 'Unknown Product';
    String extractedImage = '';

    // Check agar 'items' list exist karti hai (New Structure)
    if (data['items'] != null && (data['items'] as List).isNotEmpty) {
      var firstItem = data['items'][0];
      extractedName =
          firstItem['name'] ?? firstItem['productName'] ?? 'Unknown Product';
      extractedImage = firstItem['image'] ?? firstItem['productImage'] ?? '';
    } else {
      // Fallback for Old Structure
      extractedName = data['productName'] ?? 'Unknown Product';
      extractedImage = data['productImage'] ?? '';
    }

    // Check Price fields (priority: grandTotal -> totalAmount -> price)
    double extractedPrice =
        double.tryParse(data['grandTotal'].toString()) ??
        double.tryParse(data['totalAmount'].toString()) ??
        double.tryParse(data['price'].toString()) ??
        0.0;

    return OrderModel(
      id: docId,
      customerId: data['userId'] ?? data['customerId'] ?? '',
      customerName: data['customerName'] ?? 'Unknown',
      customerImage: data['customerImage'] ?? '',
      customerPhone: data['customerPhone'] ?? '',
      customerAddress: data['customerAddress'] ?? '',

      productName: extractedName,
      productImage: extractedImage,
      price: extractedPrice,

      status: data['status'] ?? 'pending',
      date: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}
