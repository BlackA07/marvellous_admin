// Path: lib/data/models/order_model.dart
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
  final String status;
  final DateTime date;
  final String paymentMethod;
  final String trxId;
  final List<Map<String, dynamic>> items; // ✅ NAYI CHEEZ: Order ke saare items

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
    this.items = const [], // ✅ Initialize
  });

  factory OrderModel.fromFirestore(DocumentSnapshot doc) {
    try {
      var data = doc.data() as Map<String, dynamic>;
      return OrderModel.fromMap(data, doc.id);
    } catch (e) {
      print("❌ Error parsing OrderModel from Firestore: $e");
      print("Document ID: ${doc.id}");
      print("Document Data: ${doc.data()}");
      rethrow;
    }
  }

  factory OrderModel.fromMap(Map<String, dynamic> data, String docId) {
    print("🔍 Parsing order: $docId");

    try {
      String extractedName = 'Unknown Product';
      String extractedImage = '';
      List<Map<String, dynamic>> parsedItems = [];

      // ✅ FIX: Extracting ALL items
      if (data['items'] != null && data['items'] is List) {
        for (var i in data['items']) {
          if (i is Map) {
            final item = Map<String, dynamic>.from(i as Map);
            // productId ko string force karo
            if (item['productId'] != null) {
              item['productId'] = item['productId'].toString();
            }
            parsedItems.add(item);
          }
        }
      }

      if (parsedItems.isNotEmpty) {
        var firstItem = parsedItems[0];
        extractedName =
            firstItem['name'] ?? firstItem['productName'] ?? 'Unknown Product';
        extractedImage = firstItem['image'] ?? firstItem['productImage'] ?? '';

        // ✅ FIX: Dashboard pe "Bubble Gun + 1 more item" show hoga
        if (parsedItems.length > 1) {
          extractedName =
              "$extractedName + ${parsedItems.length - 1} more items";
        }
      } else if (data['productName'] != null) {
        extractedName = data['productName'];
        extractedImage = data['productImage'] ?? '';
      } else if (data['name'] != null) {
        extractedName = data['name'];
        extractedImage = data['image'] ?? '';
      }

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

      String status = data['status']?.toString().toLowerCase() ?? 'pending';
      String paymentMethod = data['paymentMethod'] ?? 'Cash on Delivery';
      String trxId = data['trxId'] ?? data['transactionId'] ?? '';

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
        items: parsedItems, // ✅ Saved in model
      );
    } catch (e, stack) {
      print("❌ Error parsing order $docId: $e");
      print("Data: $data");
      print("Stack: $stack");
      rethrow;
    }
  }

  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      return double.tryParse(value.replaceAll(',', '')) ?? 0.0;
    }
    return 0.0;
  }

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
      'items': items,
    };
  }
}
