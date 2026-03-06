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
  var orderPaymentRequests = <Map<String, dynamic>>[].obs;

  // Old Fee Requests
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

  void _listenToFinanceRequests() {
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
      // ✅ Pehle order data fetch karo — userId chahiye notification ke liye
      DocumentSnapshot orderDoc = await _db
          .collection('orders')
          .doc(orderId)
          .get();
      if (!orderDoc.exists) return;
      var orderData = orderDoc.data() as Map<String, dynamic>;
      String userId = orderData['userId'] ?? '';

      // ✅ Firestore update
      await _db.collection('orders').doc(orderId).update({
        'status': newStatus,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // ✅ Turant notification — user ko real-time milegi
      if (userId.isNotEmpty) {
        String title = '';
        String body = '';

        switch (newStatus) {
          case 'confirmed':
            title = "Order Confirmed! 🎉";
            body =
                "Your order #$orderId has been confirmed and is being prepared.";
            break;
          case 'shipped':
            title = "Order Shipped! 📦";
            body = "Your order #$orderId is on its way to you!";
            break;
          case 'delivered':
            title = "Order Delivered! ✅";
            body = "Your order #$orderId has been delivered successfully!";
            break;
          case 'rejected':
            title = "Order Rejected ❌";
            body =
                "Your order #$orderId has been rejected. Please contact support.";
            break;
        }

        if (title.isNotEmpty) {
          await _sendNotification(
            userId: userId,
            title: title,
            body: body,
            type: 'order',
          );
        }

        // ✅ Delivered hote hi review notification bhi bhejo (3 sec baad)
        if (newStatus == 'delivered') {
          bool isReviewed = orderData['isReviewed'] ?? false;
          if (!isReviewed) {
            Future.delayed(const Duration(seconds: 3), () async {
              await _sendNotification(
                userId: userId,
                title: "Review Your Order 🌟",
                body: "How was your experience? Share your review!",
                type: 'review',
                extraData: {
                  'orderId': orderId,
                  'showReviewButton': true,
                  'items': orderData['items'] ?? [],
                },
              );
            });
          }
        }
      }

      print("\n========================================");
      print("✅ ADMIN ACTION: Order #$orderId updated to -> $newStatus");
      print("========================================\n");

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

      print("✅ ADMIN ACTION: Vendor Request $requestId Approved.");

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

      print("❌ ADMIN ACTION: Vendor Request $requestId Rejected.");

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
  // ==========================================
  // WITHDRAWAL METHODS (FIXED VERSION)
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

      // 🔍 Pehle finance document fetch karo - isUnpaidMember check karne ke liye
      var financeDoc = await _db.collection('finances').doc(requestId).get();
      if (!financeDoc.exists) {
        Get.back();
        Get.snackbar(
          "Error",
          "Withdrawal request not found",
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        return;
      }

      var data = financeDoc.data()!;
      double requestedAmount = (data['requestedAmount'] ?? amount).toDouble();
      bool isUnpaidMember = data['isUnpaidMember'] ?? false;
      double feeDeducted = isUnpaidMember ? requestedAmount * 0.50 : 0.0;
      double amountToReceive = requestedAmount - feeDeducted;

      print("📝 Processing withdrawal approval:");
      print("   - Request ID: $requestId");
      print("   - User ID: $userId");
      print("   - Requested Amount: Rs. $requestedAmount");
      print("   - Is Unpaid: $isUnpaidMember");
      print("   - Fee Deducted: Rs. $feeDeducted");
      print("   - User Receives: Rs. $amountToReceive");
      print(
        "   ⚠️ NOTE: Amount already deducted at request time, no further deduction",
      );

      // ✅ 1. Update finances doc status
      await _db.collection('finances').doc(requestId).update({
        'status': 'approved',
        'feeDeducted': feeDeducted,
        'amountToReceive': amountToReceive,
        'processedAt': FieldValue.serverTimestamp(),
      });

      // ✅ 2. Apply fee to paidFees if unpaid member
      if (isUnpaidMember && feeDeducted > 0) {
        // Get current paidFees
        var userDoc = await _db.collection('users').doc(userId).get();
        var userData = userDoc.data() as Map<String, dynamic>? ?? {};
        double currentPaid = (userData['paidFees'] ?? 0.0).toDouble();
        double totalFee =
            (await _db.collection('admin_settings').doc('mlm_variables').get())
                .data()?['membershipFee'] ??
            0.0;

        double newPaid = currentPaid + feeDeducted;
        bool isFullyPaid = newPaid >= totalFee;

        Map<String, dynamic> userUpdate = {'paidFees': newPaid};

        if (isFullyPaid) {
          userUpdate['membershipStatus'] = 'approved';
          userUpdate['isMLMActive'] = true;
        }

        await _db.collection('users').doc(userId).update(userUpdate);

        // Add fee credit history
        await _db.collection('users').doc(userId).collection('wallet_history').add({
          'amount': feeDeducted,
          'type': isFullyPaid ? 'fee_payment_approved' : 'fee_partial_approved',
          'description': isFullyPaid
              ? 'Withdrawal fee completed membership!'
              : 'Withdrawal fee credited: Rs. ${feeDeducted.toStringAsFixed(0)}',
          'timestamp': FieldValue.serverTimestamp(),
        });
      }

      // ✅ 3. Add withdrawal approved history (positive entry - informational only)
      await _db.collection('users').doc(userId).collection('wallet_history').add({
        'amount': amountToReceive,
        'type': 'withdrawal_approved',
        'description': isUnpaidMember
            ? 'Withdrawal approved - Rs.${amountToReceive.toStringAsFixed(0)} sent (Rs.${feeDeducted.toStringAsFixed(0)} fee applied)'
            : 'Withdrawal approved - Rs.${amountToReceive.toStringAsFixed(0)} sent',
        'requestedAmount': requestedAmount,
        'feeDeducted': feeDeducted,
        'amountToReceive': amountToReceive,
        'timestamp': FieldValue.serverTimestamp(),
      });

      // ✅ 4. Send notification
      await _sendNotification(
        userId: userId,
        title: "Withdrawal Approved ✅",
        body: isUnpaidMember
            ? "Your withdrawal of Rs. ${amountToReceive.toStringAsFixed(0)} has been approved. Fee Rs. ${feeDeducted.toStringAsFixed(0)} applied to membership."
            : "Your withdrawal of Rs. ${amount.toStringAsFixed(0)} has been approved!",
        type: 'finance',
      );

      Get.back(); // Close progress dialog

      print("✅ WITHDRAWAL APPROVED SUCCESSFULLY - NO DOUBLE DEDUCTION");

      Get.snackbar(
        "Success ✅",
        "Withdrawal approved successfully",
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e) {
      Get.back(); // Close progress dialog
      print("❌ Withdrawal approval error: $e");
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
      print("❌ ADMIN ACTION: Withdrawal $requestId Rejected.");

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
      print("✅ ADMIN ACTION: Deposit $requestId Approved.");

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
      print("❌ ADMIN ACTION: Deposit $requestId Rejected.");

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
  // ORDER PAYMENT METHODS
  // ==========================================

  Future<void> approveOrderPayment(String financeId) async {
    try {
      Get.dialog(
        const Center(child: CircularProgressIndicator(color: Colors.green)),
        barrierDismissible: false,
      );

      var financeDoc = await _db.collection('finances').doc(financeId).get();
      if (!financeDoc.exists) {
        Get.back();
        Get.snackbar("Error", "Payment not found", backgroundColor: Colors.red);
        return;
      }

      var data = financeDoc.data()!;
      String userId = data['userId'];
      String orderId = DateTime.now().millisecondsSinceEpoch.toString();

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
        'status': 'confirmed',
        'rewarded': false,
        'isReviewed': false,
        'createdAt': FieldValue.serverTimestamp(),
      });

      await _db.collection('finances').doc(financeId).update({
        'status': 'approved',
        'orderId': orderId,
        'processedAt': FieldValue.serverTimestamp(),
      });

      await _db.collection('users').doc(userId).update({'isMLMActive': true});

      await _sendNotification(
        userId: userId,
        title: "Payment Approved ✅",
        body:
            "Your payment has been approved! Order #$orderId is now confirmed and will be shipped soon.",
        type: 'order',
      );

      Get.back();
      print(
        "✅ ADMIN ACTION: Order Payment $financeId Approved. Order #$orderId created.",
      );

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

      await _sendNotification(
        userId: userId,
        title: "Payment Rejected ❌",
        body:
            "Your order payment has been rejected.\nReason: $reason\n\nPlease contact support if you have questions.",
        type: 'order',
      );

      Get.back();
      print("❌ ADMIN ACTION: Order Payment $financeId Rejected.");

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
    } catch (e) {
      // ignore
    }
  }

  // ==========================================
  // OLD FEE REQUEST METHODS
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

      print("✅ ADMIN ACTION: Old Fee $requestId Approved.");

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

      print("❌ ADMIN ACTION: Old Fee $requestId Rejected.");

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
      // ignore
    }
  }
}
