import 'package:cloud_firestore/cloud_firestore.dart';

class OrderModel {
  final String id;
  final String customerId;
  final String customerName;
  final String customerImage;
  final String customerPhone;
  final String customerAddress;
  final String productName;
  final String productImage;
  final double price;
  final String
  status; // 'pending', 'confirmed', 'shipped', 'delivered', 'rejected'
  final DateTime date;
  final String paymentMethod;
  final String trxId;

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
    this.paymentMethod = 'N/A',
    this.trxId = '',
  });

  factory OrderModel.fromMap(Map<String, dynamic> data, String docId) {
    print("🔍 Parsing order: $docId");

    try {
      // Extract product name and image
      String extractedName = 'Unknown Product';
      String extractedImage = '';

      // Try multiple possible field structures
      if (data['items'] != null && (data['items'] as List).isNotEmpty) {
        var firstItem = data['items'][0];
        extractedName =
            firstItem['name'] ?? firstItem['productName'] ?? 'Unknown Product';
        extractedImage = firstItem['image'] ?? firstItem['productImage'] ?? '';
      } else if (data['productName'] != null) {
        extractedName = data['productName'];
        extractedImage = data['productImage'] ?? '';
      } else if (data['name'] != null) {
        extractedName = data['name'];
        extractedImage = data['image'] ?? '';
      }

      // Extract price - try multiple fields
      double extractedPrice = 0.0;

      if (data['grandTotal'] != null) {
        extractedPrice = _parseDouble(data['grandTotal']);
      } else if (data['totalAmount'] != null) {
        extractedPrice = _parseDouble(data['totalAmount']);
      } else if (data['subTotal'] != null) {
        extractedPrice = _parseDouble(data['subTotal']);
      } else if (data['price'] != null) {
        extractedPrice = _parseDouble(data['price']);
      } else if (data['salePrice'] != null) {
        extractedPrice = _parseDouble(data['salePrice']);
      }

      // Extract customer info with fallbacks
      String customerId =
          data['userId'] ??
          data['customerId'] ??
          data['userEmail'] ??
          'unknown';

      String customerName =
          data['customerName'] ??
          data['userName'] ??
          data['userEmail']?.split('@').first ??
          'Unknown Customer';

      String customerImage = data['customerImage'] ?? data['userImage'] ?? '';

      String customerPhone =
          data['customerPhone'] ?? data['userPhone'] ?? data['phone'] ?? 'N/A';

      String customerAddress =
          data['customerAddress'] ??
          data['address'] ??
          data['shippingAddress'] ??
          'N/A';

      // Extract status
      String status = data['status']?.toString().toLowerCase() ?? 'pending';

      // Extract payment info
      String paymentMethod = data['paymentMethod'] ?? 'Cash on Delivery';
      String trxId = data['trxId'] ?? data['transactionId'] ?? '';

      // Extract date
      DateTime date;
      if (data['createdAt'] != null) {
        if (data['createdAt'] is Timestamp) {
          date = (data['createdAt'] as Timestamp).toDate();
        } else if (data['createdAt'] is String) {
          date = DateTime.tryParse(data['createdAt']) ?? DateTime.now();
        } else {
          date = DateTime.now();
        }
      } else if (data['orderDate'] != null) {
        if (data['orderDate'] is Timestamp) {
          date = (data['orderDate'] as Timestamp).toDate();
        } else {
          date =
              DateTime.tryParse(data['orderDate'].toString()) ?? DateTime.now();
        }
      } else {
        date = DateTime.now();
      }

      print("✅ Order parsed successfully:");
      print("   Name: $extractedName");
      print("   Price: $extractedPrice");
      print("   Status: $status");
      print("   Customer: $customerName");

      return OrderModel(
        id: docId,
        customerId: customerId,
        customerName: customerName,
        customerImage: customerImage,
        customerPhone: customerPhone,
        customerAddress: customerAddress,
        productName: extractedName,
        productImage: extractedImage,
        price: extractedPrice,
        status: status,
        paymentMethod: paymentMethod,
        trxId: trxId,
        date: date,
      );
    } catch (e, stack) {
      print("❌ Error parsing order $docId: $e");
      print("Data: $data");
      print("Stack: $stack");
      rethrow;
    }
  }

  // Helper method to safely parse double values
  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;

    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      return double.tryParse(value.replaceAll(',', '')) ?? 0.0;
    }

    return 0.0;
  }

  // Convert to map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'userId': customerId,
      'customerName': customerName,
      'customerImage': customerImage,
      'customerPhone': customerPhone,
      'customerAddress': customerAddress,
      'productName': productName,
      'productImage': productImage,
      'price': price,
      'status': status,
      'paymentMethod': paymentMethod,
      'trxId': trxId,
      'createdAt': Timestamp.fromDate(date),
    };
  }

  // Copy with method for updates
  OrderModel copyWith({
    String? id,
    String? customerId,
    String? customerName,
    String? customerImage,
    String? customerPhone,
    String? customerAddress,
    String? productName,
    String? productImage,
    double? price,
    String? status,
    DateTime? date,
    String? paymentMethod,
    String? trxId,
  }) {
    return OrderModel(
      id: id ?? this.id,
      customerId: customerId ?? this.customerId,
      customerName: customerName ?? this.customerName,
      customerImage: customerImage ?? this.customerImage,
      customerPhone: customerPhone ?? this.customerPhone,
      customerAddress: customerAddress ?? this.customerAddress,
      productName: productName ?? this.productName,
      productImage: productImage ?? this.productImage,
      price: price ?? this.price,
      status: status ?? this.status,
      date: date ?? this.date,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      trxId: trxId ?? this.trxId,
    );
  }
}
