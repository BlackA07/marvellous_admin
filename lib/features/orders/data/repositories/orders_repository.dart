import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/order_model.dart';
import '../models/vendor_request_model.dart';

class OrdersRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // --- CUSTOMER ORDERS ---

  // Get Top 10 Pending Orders
  Stream<List<OrderModel>> getPendingOrders({int limit = 10}) {
    return _db
        .collection('orders')
        .where('status', isEqualTo: 'pending')
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => OrderModel.fromMap(doc.data(), doc.id))
              .toList(),
        );
  }

  // Get History (All Non-Pending)
  Stream<List<OrderModel>> getOrderHistory() {
    return _db
        .collection('orders')
        .where('status', whereIn: ['accepted', 'rejected', 'delivered'])
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => OrderModel.fromMap(doc.data(), doc.id))
              .toList(),
        );
  }

  Future<void> updateOrderStatus(String orderId, String newStatus) async {
    await _db.collection('orders').doc(orderId).update({'status': newStatus});
  }

  // --- VENDOR REQUESTS ---

  // Get Top 10 Pending Requests
  Stream<List<VendorRequestModel>> getPendingRequests({int limit = 10}) {
    return _db
        .collection('vendor_requests')
        .where('status', isEqualTo: 'pending')
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => VendorRequestModel.fromMap(doc.data(), doc.id))
              .toList(),
        );
  }

  // Get Vendor Request History
  Stream<List<VendorRequestModel>> getRequestHistory() {
    return _db
        .collection('vendor_requests')
        .where('status', whereIn: ['approved', 'rejected'])
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => VendorRequestModel.fromMap(doc.data(), doc.id))
              .toList(),
        );
  }

  // UPDATED LOGIC: Agar Approve ho to Product Create bhi karo
  Future<void> updateRequestStatus(String reqId, String newStatus) async {
    // 1. Status Update karo Request table men
    await _db.collection('vendor_requests').doc(reqId).update({
      'status': newStatus,
    });

    // 2. Agar Approved hai, to is request ka data utha kar 'products' men dalo
    if (newStatus == 'approved') {
      var docSnapshot = await _db
          .collection('vendor_requests')
          .doc(reqId)
          .get();
      if (docSnapshot.exists) {
        var data = docSnapshot.data()!;

        // Add to Products Collection (Customer App men show hone k liye)
        await _db.collection('products').add({
          'vendorId': data['vendorId'],
          'name': data['productName'],
          'description':
              data['description'], // Field names model se match kar lena
          'price': data['price'],
          'image': data['image'],
          'category': 'General', // Default category ya request se uthao
          'rating': 0.0,
          'reviews': 0,
          'isPopular': false,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
    }
  }
}
