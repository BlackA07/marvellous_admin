import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../data/models/order_model.dart';
import '../../data/models/vendor_request_model.dart';

class OrdersController extends GetxController {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  var isLoading = true.obs;

  // Orders
  var pendingOrders = <OrderModel>[].obs;
  var historyOrders = <OrderModel>[].obs;

  // Vendor Requests
  var pendingRequests = <VendorRequestModel>[].obs;
  var historyRequests = <VendorRequestModel>[].obs;

  // Finance Requests (NEW)
  var withdrawalRequests = <Map<String, dynamic>>[].obs;
  var depositRequests = <Map<String, dynamic>>[].obs;

  // Old Fee Requests (for backward compatibility)
  var feeRequests = <Map<String, dynamic>>[].obs;

  @override
  void onInit() {
    super.onInit();
    _checkAdminAndListen();
  }

  void _checkAdminAndListen() async {
    User? user = _auth.currentUser;
    if (user == null) return;

    var doc = await _db.collection('users').doc(user.uid).get();
    if (doc.exists && doc.data()?['role'] == 'admin') {
      _listenToOrders();
      _listenToVendorRequests();
      _listenToFinanceRequests(); // ✅ NEW
      _listenToOldFeeRequests(); // ✅ OLD SYSTEM
    }
  }

  void _listenToOrders() {
    _db
        .collection('orders')
        .where('status', whereIn: ['pending', 'confirmed', 'shipped'])
        .snapshots()
        .listen((snap) {
          pendingOrders.assignAll(
            snap.docs.map((doc) => OrderModel.fromFirestore(doc)).toList(),
          );
          isLoading(false);
        });
  }

  void _listenToVendorRequests() {
    _db
        .collection('vendor_requests')
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .listen((snap) {
          pendingRequests.assignAll(
            snap.docs
                .map((doc) => VendorRequestModel.fromFirestore(doc))
                .toList(),
          );
        });
  }

  /// ✅ NEW: Listen to withdrawal and deposit requests
  void _listenToFinanceRequests() {
    // Withdrawal Requests
    _db
        .collection('finances')
        .where('type', isEqualTo: 'withdrawal')
        .where('status', isEqualTo: 'pending')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .listen((snap) {
          withdrawalRequests.assignAll(
            snap.docs.map((doc) {
              var data = doc.data();
              data['id'] = doc.id;
              return data;
            }).toList(),
          );
        });

    // Deposit Requests
    _db
        .collection('finances')
        .where('type', isEqualTo: 'deposit')
        .where('status', isEqualTo: 'pending')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .listen((snap) {
          depositRequests.assignAll(
            snap.docs.map((doc) {
              var data = doc.data();
              data['id'] = doc.id;
              return data;
            }).toList(),
          );
        });
  }

  /// ✅ OLD: Listen to old fee_requests collection (for backward compatibility)
  void _listenToOldFeeRequests() {
    _db
        .collection('fee_requests')
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .listen((snap) {
          feeRequests.assignAll(
            snap.docs.map((doc) {
              var data = doc.data();
              data['id'] = doc.id;
              return data;
            }).toList(),
          );
        });
  }

  // ==========================================
  // ORDER METHODS
  // ==========================================

  Future<void> acceptOrder(String orderId) async {
    await updateOrderStage(orderId, 'confirmed');
  }

  Future<void> rejectOrder(String orderId) async {
    await updateOrderStage(orderId, 'rejected');
  }

  Future<void> updateOrderStage(String orderId, String newStatus) async {
    try {
      await _db.collection('orders').doc(orderId).update({
        'status': newStatus,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      Get.snackbar(
        "Success",
        "Order status updated to $newStatus",
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar(
        "Error",
        "Failed to update order: ${e.toString()}",
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  // ==========================================
  // VENDOR REQUEST METHODS
  // ==========================================

  Future<void> acceptRequest(String requestId) async {
    try {
      var reqDoc = await _db.collection('vendor_requests').doc(requestId).get();
      if (!reqDoc.exists) return;

      var data = reqDoc.data()!;

      // Add product to products collection
      await _db.collection('products').add({
        'name': data['productName'],
        'price': data['productPrice'],
        'description': data['productDescription'],
        'category': data['productCategory'],
        'image': data['productImage'],
        'vendorId': data['vendorId'],
        'vendorName': data['vendorName'],
        'isActive': true,
        'stock': data['stock'] ?? 100,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Update request status
      await _db.collection('vendor_requests').doc(requestId).update({
        'status': 'approved',
        'processedAt': FieldValue.serverTimestamp(),
      });

      Get.snackbar(
        "Success",
        "Vendor request approved",
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar(
        "Error",
        "Failed to approve: ${e.toString()}",
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  Future<void> rejectRequest(String requestId) async {
    try {
      await _db.collection('vendor_requests').doc(requestId).update({
        'status': 'rejected',
        'processedAt': FieldValue.serverTimestamp(),
      });

      Get.snackbar(
        "Success",
        "Vendor request rejected",
        backgroundColor: Colors.orange,
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar(
        "Error",
        "Failed to reject: ${e.toString()}",
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  // ==========================================
  // NEW: WITHDRAWAL METHODS
  // ==========================================

  Future<void> approveWithdrawal(
    String requestId,
    String userId,
    double amount,
  ) async {
    try {
      Get.dialog(
        const Center(child: CircularProgressIndicator(color: Colors.green)),
        barrierDismissible: false,
      );

      // Update finance request
      await _db.collection('finances').doc(requestId).update({
        'status': 'approved',
        'processedAt': FieldValue.serverTimestamp(),
      });

      // Deduct from user's wallet
      await _db.collection('users').doc(userId).update({
        'walletBalance': FieldValue.increment(-amount),
      });

      // Add to wallet history
      await _db
          .collection('users')
          .doc(userId)
          .collection('wallet_history')
          .add({
            'amount': -amount,
            'type': 'withdrawal_approved',
            'description': 'Withdrawal Approved',
            'timestamp': FieldValue.serverTimestamp(),
          });

      // ✅ SEND NOTIFICATION - Withdrawal Approved
      await _sendNotification(
        userId: userId,
        title: "Withdrawal Approved ✅",
        body:
            "Your withdrawal of Rs. ${amount.toStringAsFixed(0)} has been processed successfully!",
        type: 'finance',
      );

      Get.back(); // Close loading

      Get.snackbar(
        "Success ✅",
        "Withdrawal approved and processed",
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e) {
      Get.back();
      Get.snackbar(
        "Error",
        "Failed to approve: ${e.toString()}",
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  Future<void> rejectWithdrawal(
    String requestId,
    String userId,
    String reason,
  ) async {
    try {
      Get.dialog(
        const Center(child: CircularProgressIndicator(color: Colors.red)),
        barrierDismissible: false,
      );

      await _db.collection('finances').doc(requestId).update({
        'status': 'rejected',
        'rejectionReason': reason,
        'processedAt': FieldValue.serverTimestamp(),
      });

      // Add to wallet history
      await _db
          .collection('users')
          .doc(userId)
          .collection('wallet_history')
          .add({
            'amount': 0,
            'type': 'withdrawal_rejected',
            'description': 'Withdrawal Rejected: $reason',
            'timestamp': FieldValue.serverTimestamp(),
          });

      // ✅ SEND NOTIFICATION - Withdrawal Rejected
      await _sendNotification(
        userId: userId,
        title: "Withdrawal Rejected ❌",
        body: "Your withdrawal request has been rejected.\nReason: $reason",
        type: 'finance',
      );

      Get.back(); // Close loading

      Get.snackbar(
        "Rejected",
        "Withdrawal request rejected",
        backgroundColor: Colors.orange,
        colorText: Colors.white,
      );
    } catch (e) {
      Get.back();
      Get.snackbar(
        "Error",
        "Failed to reject: ${e.toString()}",
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  // ==========================================
  // NEW: DEPOSIT METHODS (WITH BASE64 IMAGE SUPPORT)
  // ==========================================

  Future<void> approveDeposit(String requestId, String userId) async {
    try {
      Get.dialog(
        const Center(child: CircularProgressIndicator(color: Colors.green)),
        barrierDismissible: false,
      );

      // Get deposit data
      var depositDoc = await _db.collection('finances').doc(requestId).get();
      if (!depositDoc.exists) {
        Get.back();
        Get.snackbar("Error", "Deposit not found", backgroundColor: Colors.red);
        return;
      }

      var data = depositDoc.data()!;
      double amount = (data['amount'] ?? 0.0).toDouble();
      String purpose = data['purpose'] ?? '';

      // Update finance request
      await _db.collection('finances').doc(requestId).update({
        'status': 'approved',
        'processedAt': FieldValue.serverTimestamp(),
      });

      // If it's a membership fee, activate membership
      if (purpose == 'membership_fee') {
        await _db.collection('users').doc(userId).update({
          'membershipStatus': 'approved',
          'isMLMActive': true,
        });

        // Add to wallet history
        await _db
            .collection('users')
            .doc(userId)
            .collection('wallet_history')
            .add({
              'amount': 0,
              'type': 'membership_approved',
              'description': 'Membership Fee Approved',
              'timestamp': FieldValue.serverTimestamp(),
            });

        // ✅ SEND NOTIFICATION - Membership Approved
        await _sendNotification(
          userId: userId,
          title: "Membership Approved ✅",
          body:
              "Congratulations! Your membership has been activated. Start earning rewards now!",
          type: 'finance',
        );
      } else {
        // Regular deposit - add to wallet
        await _db.collection('users').doc(userId).update({
          'walletBalance': FieldValue.increment(amount),
        });

        // Add to wallet history
        await _db
            .collection('users')
            .doc(userId)
            .collection('wallet_history')
            .add({
              'amount': amount,
              'type': 'deposit_approved',
              'description': 'Deposit Approved',
              'timestamp': FieldValue.serverTimestamp(),
            });

        // ✅ SEND NOTIFICATION - Deposit Approved
        await _sendNotification(
          userId: userId,
          title: "Deposit Approved ✅",
          body:
              "Rs. ${amount.toStringAsFixed(0)} has been added to your wallet successfully!",
          type: 'finance',
        );
      }

      Get.back(); // Close loading

      Get.snackbar(
        "Success ✅",
        "Deposit approved successfully",
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e) {
      Get.back();
      Get.snackbar(
        "Error",
        "Failed to approve: ${e.toString()}",
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  Future<void> rejectDeposit(
    String requestId,
    String userId,
    String reason,
  ) async {
    try {
      Get.dialog(
        const Center(child: CircularProgressIndicator(color: Colors.red)),
        barrierDismissible: false,
      );

      await _db.collection('finances').doc(requestId).update({
        'status': 'rejected',
        'rejectionReason': reason,
        'processedAt': FieldValue.serverTimestamp(),
      });

      // Update user's membership status if it was a fee payment
      var depositDoc = await _db.collection('finances').doc(requestId).get();
      if (depositDoc.exists) {
        var data = depositDoc.data()!;
        if (data['purpose'] == 'membership_fee') {
          await _db.collection('users').doc(userId).update({
            'membershipStatus': 'rejected',
            'rejectionReason': reason,
          });
        }
      }

      // Add to wallet history
      await _db
          .collection('users')
          .doc(userId)
          .collection('wallet_history')
          .add({
            'amount': 0,
            'type': 'deposit_rejected',
            'description': 'Deposit Rejected: $reason',
            'timestamp': FieldValue.serverTimestamp(),
          });

      // ✅ SEND NOTIFICATION - Deposit Rejected
      await _sendNotification(
        userId: userId,
        title: "Payment Rejected ❌",
        body: "Your payment request has been rejected.\nReason: $reason",
        type: 'finance',
      );

      Get.back(); // Close loading

      Get.snackbar(
        "Rejected",
        "Deposit request rejected",
        backgroundColor: Colors.orange,
        colorText: Colors.white,
      );
    } catch (e) {
      Get.back();
      Get.snackbar(
        "Error",
        "Failed to reject: ${e.toString()}",
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  // ✅ HELPER METHOD: Send Notification
  Future<void> _sendNotification({
    required String userId,
    required String title,
    required String body,
    required String type,
    Map<String, dynamic>? extraData,
  }) async {
    try {
      await _db
          .collection('users')
          .doc(userId)
          .collection('notifications')
          .add({
            'title': title,
            'body': body,
            'type': type,
            'isRead': false,
            'timestamp': FieldValue.serverTimestamp(),
            if (extraData != null) 'data': extraData,
          });
      print("✅ Notification sent to user: $userId");
    } catch (e) {
      print("❌ Failed to send notification: $e");
    }
  }

  // ==========================================
  // OLD FEE REQUEST METHODS (Backward Compatibility)
  // ==========================================

  Future<void> approveFee(String requestId, String userId) async {
    try {
      await _db.collection('fee_requests').doc(requestId).update({
        'status': 'approved',
        'processedAt': FieldValue.serverTimestamp(),
      });

      await _db.collection('users').doc(userId).update({
        'membershipStatus': 'approved',
        'isMLMActive': true,
      });

      Get.snackbar(
        "Success",
        "Fee approved",
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar(
        "Error",
        "Failed: ${e.toString()}",
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  Future<void> rejectFee(String requestId, String userId) async {
    try {
      await _db.collection('fee_requests').doc(requestId).update({
        'status': 'rejected',
        'processedAt': FieldValue.serverTimestamp(),
      });

      await _db.collection('users').doc(userId).update({
        'membershipStatus': 'rejected',
      });

      Get.snackbar(
        "Rejected",
        "Fee rejected",
        backgroundColor: Colors.orange,
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar(
        "Error",
        "Failed: ${e.toString()}",
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  // ==========================================
  // HISTORY METHODS
  // ==========================================

  Future<void> fetchHistory() async {
    try {
      // Fetch order history
      var orderSnap = await _db
          .collection('orders')
          .where('status', whereIn: ['delivered', 'rejected', 'cancelled'])
          .get();

      historyOrders.assignAll(
        orderSnap.docs.map((doc) => OrderModel.fromFirestore(doc)).toList(),
      );

      // Fetch vendor request history
      var vendorSnap = await _db
          .collection('vendor_requests')
          .where('status', whereIn: ['approved', 'rejected'])
          .get();

      historyRequests.assignAll(
        vendorSnap.docs
            .map((doc) => VendorRequestModel.fromFirestore(doc))
            .toList(),
      );
    } catch (e) {
      print("Error fetching history: $e");
    }
  }
}
