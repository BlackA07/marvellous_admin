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
        .where('status', whereIn: ['accepted', 'rejected'])
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
    // Assuming requests are stored in 'products' with status 'pending_approval'
    // Or a separate 'vendor_requests' collection.
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

  Future<void> updateRequestStatus(String reqId, String newStatus) async {
    // Agar approve hua to product ko 'published' bhi karna parega logic men
    await _db.collection('vendor_requests').doc(reqId).update({
      'status': newStatus,
    });
  }
}
