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

  /// ✅ NEW: Factory method for Firestore DocumentSnapshot
  factory VendorRequestModel.fromFirestore(DocumentSnapshot doc) {
    try {
      var data = doc.data() as Map<String, dynamic>;
      return VendorRequestModel.fromMap(data, doc.id);
    } catch (e) {
      print("❌ Error parsing VendorRequestModel from Firestore: $e");
      print("Document ID: ${doc.id}");
      print("Document Data: ${doc.data()}");
      rethrow;
    }
  }

  /// ✅ UPDATED: Factory method for Map with better error handling
  factory VendorRequestModel.fromMap(Map<String, dynamic> data, String docId) {
    try {
      // Extract vendor info
      String vendorId = data['vendorId']?.toString() ?? '';
      String vendorName = data['vendorName']?.toString() ?? 'Unknown Vendor';
      String vendorImage = data['vendorImage']?.toString() ?? '';

      // Extract request type
      String requestType = data['requestType']?.toString() ?? 'add_product';

      // Extract product name (multiple possible fields)
      String productName =
          data['productName']?.toString() ??
          data['name']?.toString() ??
          'No Name';

      // Extract product description
      String productDescription =
          data['description']?.toString() ??
          data['productDescription']?.toString() ??
          '';

      // Extract product price (handle multiple possible fields and types)
      double productPrice = _parsePrice(data);

      // Extract product image (multiple possible fields)
      String productImage =
          data['image']?.toString() ?? data['productImage']?.toString() ?? '';

      // Extract status
      String status = data['status']?.toString() ?? 'pending';

      // Extract date
      DateTime date = _parseDate(data);

      return VendorRequestModel(
        id: docId,
        vendorId: vendorId,
        vendorName: vendorName,
        vendorImage: vendorImage,
        requestType: requestType,
        productName: productName,
        productDescription: productDescription,
        productPrice: productPrice,
        productImage: productImage,
        status: status,
        date: date,
      );
    } catch (e, stack) {
      print("❌ Error parsing VendorRequestModel from Map: $e");
      print("Document ID: $docId");
      print("Data: $data");
      print("Stack: $stack");
      rethrow;
    }
  }

  /// ✅ Helper method to safely parse price from multiple fields
  static double _parsePrice(Map<String, dynamic> data) {
    // Try different field names
    var priceFields = ['productPrice', 'salePrice', 'price', 'amount'];

    for (var field in priceFields) {
      if (data[field] != null) {
        try {
          // Handle different types
          if (data[field] is double) {
            return data[field];
          } else if (data[field] is int) {
            return data[field].toDouble();
          } else if (data[field] is String) {
            var parsed = double.tryParse(data[field]);
            if (parsed != null) return parsed;
          }
        } catch (e) {
          print("⚠️ Failed to parse price from field '$field': ${data[field]}");
        }
      }
    }

    print("⚠️ No valid price found, defaulting to 0.0");
    return 0.0;
  }

  /// ✅ Helper method to safely parse date
  static DateTime _parseDate(Map<String, dynamic> data) {
    try {
      // Try createdAt field
      if (data['createdAt'] != null) {
        if (data['createdAt'] is Timestamp) {
          return (data['createdAt'] as Timestamp).toDate();
        } else if (data['createdAt'] is String) {
          var parsed = DateTime.tryParse(data['createdAt']);
          if (parsed != null) return parsed;
        }
      }

      // Try timestamp field
      if (data['timestamp'] != null) {
        if (data['timestamp'] is Timestamp) {
          return (data['timestamp'] as Timestamp).toDate();
        } else if (data['timestamp'] is String) {
          var parsed = DateTime.tryParse(data['timestamp']);
          if (parsed != null) return parsed;
        }
      }

      // Try date field
      if (data['date'] != null) {
        if (data['date'] is Timestamp) {
          return (data['date'] as Timestamp).toDate();
        } else if (data['date'] is String) {
          var parsed = DateTime.tryParse(data['date']);
          if (parsed != null) return parsed;
        }
      }
    } catch (e) {
      print("⚠️ Failed to parse date: $e");
    }

    print("⚠️ No valid date found, using current time");
    return DateTime.now();
  }

  /// Convert to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'vendorId': vendorId,
      'vendorName': vendorName,
      'vendorImage': vendorImage,
      'requestType': requestType,
      'productName': productName,
      'description': productDescription,
      'productPrice': productPrice,
      'productImage': productImage,
      'status': status,
      'createdAt': Timestamp.fromDate(date),
    };
  }

  /// Copy with method for updates
  VendorRequestModel copyWith({
    String? id,
    String? vendorId,
    String? vendorName,
    String? vendorImage,
    String? requestType,
    String? productName,
    String? productDescription,
    double? productPrice,
    String? productImage,
    String? status,
    DateTime? date,
  }) {
    return VendorRequestModel(
      id: id ?? this.id,
      vendorId: vendorId ?? this.vendorId,
      vendorName: vendorName ?? this.vendorName,
      vendorImage: vendorImage ?? this.vendorImage,
      requestType: requestType ?? this.requestType,
      productName: productName ?? this.productName,
      productDescription: productDescription ?? this.productDescription,
      productPrice: productPrice ?? this.productPrice,
      productImage: productImage ?? this.productImage,
      status: status ?? this.status,
      date: date ?? this.date,
    );
  }

  @override
  String toString() {
    return 'VendorRequestModel(id: $id, vendorName: $vendorName, productName: $productName, price: $productPrice, status: $status)';
  }
}
