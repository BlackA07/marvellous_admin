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

  // Finance Requests
  var withdrawalRequests = <Map<String, dynamic>>[].obs;
  var depositRequests = <Map<String, dynamic>>[].obs;
  var orderPaymentRequests = <Map<String, dynamic>>[].obs; // ✅ NEW

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
      _listenToFinanceRequests();
      _listenToOldFeeRequests();
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

  /// ✅ UPDATED: Listen to all finance request types
  void _listenToFinanceRequests() {
    // 1. Withdrawal Requests
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

    // 2. Deposit Requests (Fee Payments)
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

    // ✅ 3. Order Payment Requests (NEW)
    _db
        .collection('finances')
        .where('type', isEqualTo: 'order_payment')
        .where('status', isEqualTo: 'pending')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .listen((snap) {
          orderPaymentRequests.assignAll(
            snap.docs.map((doc) {
              var data = doc.data();
              data['id'] = doc.id;
              return data;
            }).toList(),
          );
        });
  }

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
  // WITHDRAWAL METHODS
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

      await _db.collection('finances').doc(requestId).update({
        'status': 'approved',
        'processedAt': FieldValue.serverTimestamp(),
      });

      await _db.collection('users').doc(userId).update({
        'walletBalance': FieldValue.increment(-amount),
      });

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

      await _sendNotification(
        userId: userId,
        title: "Withdrawal Approved ✅",
        body:
            "Your withdrawal of Rs. ${amount.toStringAsFixed(0)} has been processed successfully!",
        type: 'finance',
      );

      Get.back();

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

      await _sendNotification(
        userId: userId,
        title: "Withdrawal Rejected ❌",
        body: "Your withdrawal request has been rejected.\nReason: $reason",
        type: 'finance',
      );

      Get.back();

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
  // DEPOSIT (FEE PAYMENT) METHODS
  // ==========================================

  Future<void> approveDeposit(String requestId, String userId) async {
    try {
      Get.dialog(
        const Center(child: CircularProgressIndicator(color: Colors.green)),
        barrierDismissible: false,
      );

      var depositDoc = await _db.collection('finances').doc(requestId).get();
      if (!depositDoc.exists) {
        Get.back();
        Get.snackbar("Error", "Deposit not found", backgroundColor: Colors.red);
        return;
      }

      var data = depositDoc.data()!;
      double amount = (data['amount'] ?? 0.0).toDouble();
      String purpose = data['purpose'] ?? '';

      await _db.collection('finances').doc(requestId).update({
        'status': 'approved',
        'processedAt': FieldValue.serverTimestamp(),
      });

      if (purpose == 'membership_fee') {
        await _db.collection('users').doc(userId).update({
          'membershipStatus': 'approved',
          'isMLMActive': true,
        });

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

        await _sendNotification(
          userId: userId,
          title: "Membership Approved ✅",
          body:
              "Congratulations! Your membership has been activated. Start earning rewards now!",
          type: 'finance',
        );
      } else {
        await _db.collection('users').doc(userId).update({
          'walletBalance': FieldValue.increment(amount),
        });

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

        await _sendNotification(
          userId: userId,
          title: "Deposit Approved ✅",
          body:
              "Rs. ${amount.toStringAsFixed(0)} has been added to your wallet successfully!",
          type: 'finance',
        );
      }

      Get.back();

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

      await _sendNotification(
        userId: userId,
        title: "Payment Rejected ❌",
        body: "Your payment request has been rejected.\nReason: $reason",
        type: 'finance',
      );

      Get.back();

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

  // ==========================================
  // ✅ NEW: ORDER PAYMENT METHODS
  // ==========================================

  Future<void> approveOrderPayment(String financeId) async {
    try {
      Get.dialog(
        const Center(child: CircularProgressIndicator(color: Colors.green)),
        barrierDismissible: false,
      );

      // Get payment data
      var financeDoc = await _db.collection('finances').doc(financeId).get();
      if (!financeDoc.exists) {
        Get.back();
        Get.snackbar("Error", "Payment not found", backgroundColor: Colors.red);
        return;
      }

      var data = financeDoc.data()!;
      String userId = data['userId'];
      String orderId = DateTime.now().millisecondsSinceEpoch.toString();

      // ✅ Create order in orders collection
      await _db.collection('orders').doc(orderId).set({
        'orderId': orderId,
        'userId': userId,
        'userEmail': data['userEmail'],
        'customerName': data['customerName'],
        'customerPhone': data['customerPhone'],
        'customerAddress': data['customerAddress'],
        'items': data['items'],
        'subTotal': data['subTotal'],
        'shippingFee': data['shippingFee'],
        'grossProfit': data['grossProfit'],
        'grandTotal': data['totalAmount'],
        'paymentMethod': data['method'],
        'trxId': data['trxId'],
        'status': 'confirmed', // Start at confirmed (payment already verified)
        'rewarded': false,
        'isReviewed': false,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // ✅ Update finance request status
      await _db.collection('finances').doc(financeId).update({
        'status': 'approved',
        'orderId': orderId, // Link to created order
        'processedAt': FieldValue.serverTimestamp(),
      });

      // ✅ Activate MLM
      await _db.collection('users').doc(userId).update({'isMLMActive': true});

      // ✅ Send notification
      await _sendNotification(
        userId: userId,
        title: "Payment Approved ✅",
        body:
            "Your payment has been approved! Order #$orderId is now confirmed and will be shipped soon.",
        type: 'order',
      );

      Get.back();

      Get.snackbar(
        "Success ✅",
        "Payment approved and order #$orderId created",
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

  Future<void> rejectOrderPayment(
    String financeId,
    String userId,
    String reason,
  ) async {
    try {
      Get.dialog(
        const Center(child: CircularProgressIndicator(color: Colors.red)),
        barrierDismissible: false,
      );

      await _db.collection('finances').doc(financeId).update({
        'status': 'rejected',
        'rejectionReason': reason,
        'processedAt': FieldValue.serverTimestamp(),
      });

      // Send notification
      await _sendNotification(
        userId: userId,
        title: "Payment Rejected ❌",
        body:
            "Your order payment has been rejected.\nReason: $reason\n\nPlease contact support if you have questions.",
        type: 'order',
      );

      Get.back();

      Get.snackbar(
        "Rejected",
        "Payment rejected",
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
  // HELPER METHOD: Send Notification
  // ==========================================

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
      var orderSnap = await _db
          .collection('orders')
          .where('status', whereIn: ['delivered', 'rejected', 'cancelled'])
          .get();

      historyOrders.assignAll(
        orderSnap.docs.map((doc) => OrderModel.fromFirestore(doc)).toList(),
      );

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
