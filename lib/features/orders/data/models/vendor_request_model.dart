import 'package:cloud_firestore/cloud_firestore.dart';

class VendorRequestModel {
  final String id;
  final String vendorId;
  final String vendorName;
  final String vendorImage;
  final String requestType;
  final String productName;
  final String productDescription;
  final double productPrice;
  final String productImage;
  final String status;
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
      productName: data['productName'] ?? data['name'] ?? 'No Name',
      productDescription: data['description'] ?? '',

      // FIX: Price ko 'salePrice' ya 'price' dono se dhoond raha hai
      // toString() use kiya taake agar Int ho to crash na kare
      productPrice:
          double.tryParse(data['salePrice'].toString()) ??
          double.tryParse(data['price'].toString()) ??
          0.0,

      // FIX: Image field check
      productImage: data['image'] ?? data['productImage'] ?? '',

      status: data['status'] ?? 'pending',
      date: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}
