import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/order_model.dart';
import '../models/vendor_request_model.dart';

class OrdersRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // --- CUSTOMER ORDERS ---
  Stream<List<OrderModel>> getOrdersByStatus(List<String> statuses) {
    print("🔍 OrdersRepository: Fetching orders with statuses: $statuses");

    return _db
        .collection('orders')
        .where('status', whereIn: statuses)
        .snapshots()
        .map((snapshot) {
          print(
            "📦 OrdersRepository: Received ${snapshot.docs.length} orders from Firebase",
          );

          if (snapshot.docs.isEmpty) {
            print("⚠️ No orders found. Check:");
            print("   - Firebase collection name is 'orders'");
            print("   - status field exists in documents");
            print("   - status values match: $statuses");
          }

          return snapshot.docs.map((doc) {
            try {
              print("   Processing order: ${doc.id} with data: ${doc.data()}");
              return OrderModel.fromMap(doc.data(), doc.id);
            } catch (e, stack) {
              print("❌ Error parsing order ${doc.id}: $e");
              print("Stack: $stack");
              rethrow;
            }
          }).toList();
        })
        .handleError((error) {
          print("❌ Stream error in getOrdersByStatus: $error");
          return <OrderModel>[];
        });
  }

  Future<void> updateOrderStatus(String orderId, String newStatus) async {
    print("📝 Updating order $orderId to status: $newStatus");
    try {
      await _db.collection('orders').doc(orderId).update({'status': newStatus});
      print("✅ Order status updated successfully");
    } catch (e) {
      print("❌ Error updating order status: $e");
      rethrow;
    }
  }

  // --- FEE REQUESTS ---
  Stream<List<Map<String, dynamic>>> getFeeRequests() {
    print("🔍 OrdersRepository: Fetching fee requests");

    return _db
        .collection('fee_requests')
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .map((snap) {
          print(
            "💰 OrdersRepository: Received ${snap.docs.length} fee requests from Firebase",
          );

          if (snap.docs.isEmpty) {
            print("⚠️ No fee requests found. Check:");
            print("   - Collection name is 'fee_requests'");
            print("   - Documents have 'status' field");
            print("   - Some documents have status = 'pending'");
          }

          return snap.docs.map((doc) {
            var data = doc.data();
            data['id'] = doc.id;
            print(
              "   Fee request: ${doc.id} - ${data['userEmail'] ?? 'no email'}",
            );
            return data;
          }).toList();
        })
        .handleError((error) {
          print("❌ Stream error in getFeeRequests: $error");
          return <Map<String, dynamic>>[];
        });
  }

  Future<void> handleFeeRequest(
    String reqId,
    String userId,
    String status, {
    String reason = "",
  }) async {
    print(
      "📝 Handling fee request: $reqId for user: $userId with status: $status",
    );

    try {
      WriteBatch batch = _db.batch();

      batch.update(_db.collection('fee_requests').doc(reqId), {
        'status': status,
        'rejectionReason': reason,
        'processedAt': FieldValue.serverTimestamp(),
      });

      DocumentReference userRef = _db.collection('users').doc(userId);
      if (status == 'approved') {
        batch.update(userRef, {
          'membershipStatus': 'approved',
          'isMLMActive': true,
          'approvedAt': FieldValue.serverTimestamp(),
        });
      } else {
        batch.update(userRef, {
          'membershipStatus': 'rejected',
          'rejectionReason': reason,
          'rejectedAt': FieldValue.serverTimestamp(),
        });
      }

      await batch.commit();
      print("✅ Fee request handled successfully");
    } catch (e) {
      print("❌ Error handling fee request: $e");
      rethrow;
    }
  }

  // --- VENDOR REQUESTS ---
  Stream<List<VendorRequestModel>> getPendingRequests() {
    print("🔍 OrdersRepository: Fetching pending vendor requests");

    return _db
        .collection('vendor_requests')
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .map((snapshot) {
          print(
            "🏪 OrdersRepository: Received ${snapshot.docs.length} vendor requests from Firebase",
          );

          if (snapshot.docs.isEmpty) {
            print("⚠️ No vendor requests found. Check:");
            print("   - Collection name is 'vendor_requests'");
            print("   - Documents have 'status' field = 'pending'");
          }

          return snapshot.docs.map((doc) {
            try {
              print("   Processing vendor request: ${doc.id}");
              return VendorRequestModel.fromMap(doc.data(), doc.id);
            } catch (e) {
              print("❌ Error parsing vendor request ${doc.id}: $e");
              rethrow;
            }
          }).toList();
        })
        .handleError((error) {
          print("❌ Stream error in getPendingRequests: $error");
          return <VendorRequestModel>[];
        });
  }

  Stream<List<VendorRequestModel>> getRequestHistory() {
    print("🔍 OrdersRepository: Fetching vendor request history");

    return _db
        .collection('vendor_requests')
        .where('status', whereIn: ['approved', 'rejected'])
        .snapshots()
        .map((snapshot) {
          print(
            "📜 OrdersRepository: Received ${snapshot.docs.length} history items",
          );

          return snapshot.docs.map((doc) {
            try {
              return VendorRequestModel.fromMap(doc.data(), doc.id);
            } catch (e) {
              print("❌ Error parsing history request ${doc.id}: $e");
              rethrow;
            }
          }).toList();
        })
        .handleError((error) {
          print("❌ Stream error in getRequestHistory: $error");
          return <VendorRequestModel>[];
        });
  }

  Future<void> updateRequestStatus(String reqId, String newStatus) async {
    print("📝 Updating vendor request $reqId to status: $newStatus");

    try {
      await _db.collection('vendor_requests').doc(reqId).update({
        'status': newStatus,
        'processedAt': FieldValue.serverTimestamp(),
      });

      if (newStatus == 'approved') {
        print("✅ Vendor request approved, adding to products...");
        var doc = await _db.collection('vendor_requests').doc(reqId).get();

        if (doc.exists) {
          var data = doc.data()!;
          await _db.collection('products').add({
            'vendorId': data['vendorId'],
            'name': data['productName'],
            'description': data['description'] ?? '',
            'price': data['productPrice'] ?? data['price'] ?? 0,
            'image': data['productImage'] ?? data['image'] ?? '',
            'category': data['category'] ?? 'General',
            'createdAt': FieldValue.serverTimestamp(),
            'fromRequest': reqId,
          });
          print("✅ Product added successfully");
        }
      }

      print("✅ Vendor request status updated successfully");
    } catch (e) {
      print("❌ Error updating vendor request: $e");
      rethrow;
    }
  }

  // --- DEBUG HELPER ---
  Future<void> debugCollections() async {
    print("\n🔍 === FIREBASE DEBUG INFO ===");

    try {
      var ordersSnapshot = await _db.collection('orders').limit(5).get();
      print("\n📦 ORDERS Collection:");
      print("   Total documents found: ${ordersSnapshot.docs.length}");
      for (var doc in ordersSnapshot.docs) {
        print("   - ${doc.id}: status=${doc.data()['status']}");
      }
    } catch (e) {
      print("❌ Error reading orders: $e");
    }

    try {
      var feeSnapshot = await _db.collection('fee_requests').limit(5).get();
      print("\n💰 FEE_REQUESTS Collection:");
      print("   Total documents found: ${feeSnapshot.docs.length}");
      for (var doc in feeSnapshot.docs) {
        print("   - ${doc.id}: status=${doc.data()['status']}");
      }
    } catch (e) {
      print("❌ Error reading fee_requests: $e");
    }

    try {
      var vendorSnapshot = await _db
          .collection('vendor_requests')
          .limit(5)
          .get();
      print("\n🏪 VENDOR_REQUESTS Collection:");
      print("   Total documents found: ${vendorSnapshot.docs.length}");
      for (var doc in vendorSnapshot.docs) {
        print("   - ${doc.id}: status=${doc.data()['status']}");
      }
    } catch (e) {
      print("❌ Error reading vendor_requests: $e");
    }

    print("\n=== END DEBUG INFO ===\n");
  }
}
