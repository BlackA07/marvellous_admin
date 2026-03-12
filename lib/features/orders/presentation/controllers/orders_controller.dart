import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../data/models/order_model.dart';
import '../../data/models/vendor_request_model.dart';

// ══════════════════════════════════════════════════════════════════════════════
//  ORDERS CONTROLLER — ADMIN APP
//
//  CHANGES:
//  1. updateOrderStage() — All notifications now include full extraData
//     (orderId, grandTotal, subTotal, shippingFee, codCharges,
//      paymentMethod, customerAddress, items) so customer app can
//     show order details in the notification detail sheet.
//
//  2. approveOrderPayment() — Order is now created with status 'pending'
//     (not 'confirmed'). A separate "Payment Confirmed" notification is
//     sent. Admin still needs to manually move order through
//     pending → confirmed → shipped → delivered.
// ══════════════════════════════════════════════════════════════════════════════

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

  // ════════════════════════════════════════════════════════════════════════════
  //  ORDER STATUS UPDATE
  //
  //  ALL notifications now include extraData with full order details so
  //  the customer app notification sheet can display them properly.
  //
  //  When newStatus == 'delivered':
  //    Atomic transaction sets status='delivered' + rewardPending=true.
  //    Customer app listener picks up rewardPending=true and processes rewards.
  //
  //  For confirmed / shipped / rejected:
  //    Simple update + notification with full order details.
  // ════════════════════════════════════════════════════════════════════════════
  Future<void> updateOrderStage(String orderId, String newStatus) async {
    try {
      final orderRef = _db.collection('orders').doc(orderId);

      if (newStatus == 'delivered') {
        // ── Atomic delivery + reward trigger ──────────────────────────────
        bool success = false;
        String? userId;
        Map<String, dynamic>? orderData;

        await _db.runTransaction((transaction) async {
          final snap = await transaction.get(orderRef);
          if (!snap.exists) throw Exception('Order not found');

          final data = snap.data() as Map<String, dynamic>;
          final currentStatus = data['status']?.toString().toLowerCase() ?? '';

          if (currentStatus == 'delivered')
            throw Exception('ALREADY_DELIVERED');
          if (data['rewarded'] == true) throw Exception('ALREADY_REWARDED');

          transaction.update(orderRef, {
            'status': 'delivered',
            'rewardPending': true,
            'rewardProcessing': false,
            'updatedAt': FieldValue.serverTimestamp(),
          });

          success = true;
          userId = data['userId'] as String?;
          orderData = data;
        });

        if (!success) return;

        print("✅ ADMIN: Order #$orderId marked DELIVERED | rewardPending=true");

        if (userId != null && userId!.isNotEmpty) {
          // ── Delivered notification with full order details ──────────────
          await _sendNotification(
            userId: userId!,
            title: "Order Delivered! 🎉",
            body:
                "Great news! Your order #$orderId has been delivered successfully. We hope you love it!",
            type: 'order',
            extraData: _buildOrderExtraData(orderId, orderData!),
          );

          // Review notification after 3 seconds
          final bool isReviewed = orderData?['isReviewed'] ?? false;
          if (!isReviewed) {
            Future.delayed(const Duration(seconds: 3), () async {
              await _sendNotification(
                userId: userId!,
                title: "How was your order? 🌟",
                body:
                    "Please take a moment to review your order #$orderId. Your feedback helps us improve!",
                type: 'review',
                extraData: {
                  'orderId': orderId,
                  'showReviewButton': true,
                  'items': orderData?['items'] ?? [],
                },
              );
            });
          }
        }
      } else {
        // ── Non-delivery status update ────────────────────────────────────
        DocumentSnapshot orderDoc = await orderRef.get();
        if (!orderDoc.exists) return;
        var data = orderDoc.data() as Map<String, dynamic>;
        String userId = data['userId'] ?? '';

        await orderRef.update({
          'status': newStatus,
          'updatedAt': FieldValue.serverTimestamp(),
        });

        print("✅ ADMIN: Order #$orderId → $newStatus");

        if (userId.isNotEmpty) {
          String title = '';
          String body = '';

          switch (newStatus) {
            case 'confirmed':
              title = "Order Confirmed! ✅";
              body =
                  "Your order #$orderId has been confirmed and is being prepared for shipment.";
              break;
            case 'shipped':
              title = "Order Shipped! 📦";
              body =
                  "Your order #$orderId is on its way! Our delivery team will reach you soon.";
              break;
            case 'rejected':
              title = "Order Rejected ❌";
              body =
                  "Unfortunately, your order #$orderId has been rejected. Please contact support for assistance.";
              break;
          }

          if (title.isNotEmpty) {
            await _sendNotification(
              userId: userId,
              title: title,
              body: body,
              type: 'order',
              // ✅ Full order details in every status notification
              extraData: _buildOrderExtraData(orderId, data),
            );
          }
        }
      }

      Get.snackbar(
        "Success",
        "Order status updated to $newStatus",
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } on FirebaseException catch (e) {
      final msg = e.message ?? e.code;
      if (msg.contains('ALREADY_DELIVERED') ||
          msg.contains('ALREADY_REWARDED')) {
        Get.snackbar(
          "Already Processed",
          "This order was already marked as delivered.",
          backgroundColor: Colors.orange,
          colorText: Colors.white,
        );
      } else {
        Get.snackbar(
          "Error",
          "Failed to update order: $msg",
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      final msg = e.toString();
      if (msg.contains('ALREADY_DELIVERED') ||
          msg.contains('ALREADY_REWARDED')) {
        Get.snackbar(
          "Already Processed",
          "This order was already marked as delivered.",
          backgroundColor: Colors.orange,
          colorText: Colors.white,
        );
      } else {
        Get.snackbar(
          "Error",
          "Failed to update order: $msg",
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    }
  }

  // ════════════════════════════════════════════════════════════════════════════
  //  HELPER: Build extraData map from order document
  //  Used in all order status notifications so customer sheet shows details
  // ════════════════════════════════════════════════════════════════════════════
  Map<String, dynamic> _buildOrderExtraData(
    String orderId,
    Map<String, dynamic> orderData,
  ) {
    return {
      'orderId': orderId,
      'grandTotal': orderData['grandTotal'] ?? orderData['totalAmount'] ?? 0,
      'subTotal': orderData['subTotal'] ?? 0,
      'shippingFee': orderData['shippingFee'] ?? 0,
      'codCharges': orderData['codCharges'] ?? 0,
      'paymentMethod': orderData['paymentMethod'] ?? 'N/A',
      'customerAddress': orderData['customerAddress'] ?? '',
      'items': orderData['items'] ?? [],
    };
  }

  Future<void> acceptOrder(String orderId) async {
    await updateOrderStage(orderId, 'confirmed');
  }

  Future<void> rejectOrder(String orderId) async {
    await updateOrderStage(orderId, 'rejected');
  }

  // ════════════════════════════════════════════════════════════════════════════
  //  VENDOR REQUESTS
  // ════════════════════════════════════════════════════════════════════════════
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

  // ════════════════════════════════════════════════════════════════════════════
  //  WITHDRAWAL — APPROVE (screenshot compulsory)
  // ════════════════════════════════════════════════════════════════════════════
  Future<void> approveWithdrawal({
    required String requestId,
    required String userId,
    required double amount,
    required String base64Image,
    required String imageExtension,
  }) async {
    try {
      Get.dialog(
        const Center(child: CircularProgressIndicator(color: Colors.green)),
        barrierDismissible: false,
      );

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
      String paymentMethod = data['method'] ?? 'N/A';

      await _db.collection('finances').doc(requestId).update({
        'status': 'approved',
        'adminScreenshotBase64': base64Image,
        'adminImageExtension': imageExtension,
        'feeDeducted': feeDeducted,
        'amountToReceive': amountToReceive,
        'method': paymentMethod,
        'processedAt': FieldValue.serverTimestamp(),
      });

      if (isUnpaidMember && feeDeducted > 0) {
        var userDoc = await _db.collection('users').doc(userId).get();
        var userData = userDoc.data() as Map<String, dynamic>? ?? {};
        double currentPaid = (userData['paidFees'] ?? 0.0).toDouble();

        final settingsDoc = await _db
            .collection('admin_settings')
            .doc('mlm_variables')
            .get();
        double totalFee = (settingsDoc.data()?['membershipFee'] ?? 0.0)
            .toDouble();

        double newPaid = double.parse(
          (currentPaid + feeDeducted).toStringAsFixed(2),
        );
        bool isFullyPaid = totalFee > 0 && newPaid >= totalFee;

        Map<String, dynamic> userUpdate = {'paidFees': newPaid};
        if (isFullyPaid) {
          userUpdate['membershipStatus'] = 'approved';
          userUpdate['isMLMActive'] = true;
          userUpdate['rejectionReason'] = '';
        }

        await _db.collection('users').doc(userId).update(userUpdate);

        await _db.collection('users').doc(userId).collection('wallet_history').add({
          'amount': feeDeducted,
          'type': isFullyPaid ? 'fee_payment_approved' : 'fee_partial_approved',
          'description': isFullyPaid
              ? 'Withdrawal fee completed membership! Rs.${feeDeducted.toStringAsFixed(0)}'
              : 'Withdrawal fee credited: Rs.${feeDeducted.toStringAsFixed(0)} — Paid: Rs.${newPaid.toStringAsFixed(0)} / Rs.${totalFee.toStringAsFixed(0)}',
          'timestamp': FieldValue.serverTimestamp(),
        });
      }

      await _db.collection('users').doc(userId).collection('wallet_history').add({
        'amount': amountToReceive,
        'type': 'withdrawal_approved',
        'description': isUnpaidMember
            ? 'Withdrawal approved — Rs.${amountToReceive.toStringAsFixed(0)} sent to you (Rs.${feeDeducted.toStringAsFixed(0)} fee applied to membership)'
            : 'Withdrawal approved — Rs.${amountToReceive.toStringAsFixed(0)} sent to you',
        'requestedAmount': requestedAmount,
        'feeDeducted': feeDeducted,
        'amountToReceive': amountToReceive,
        'method': paymentMethod,
        'hasAdminScreenshot': true,
        'timestamp': FieldValue.serverTimestamp(),
      });

      await _sendNotification(
        userId: userId,
        title: "Withdrawal Approved ✅",
        body: isUnpaidMember
            ? "Rs.${amountToReceive.toStringAsFixed(0)} has been sent to your $paymentMethod account. Rs.${feeDeducted.toStringAsFixed(0)} was applied to your membership fee. Check payment proof in notification details."
            : "Rs.${amountToReceive.toStringAsFixed(0)} has been sent to your $paymentMethod account. Check payment proof in notification details.",
        type: 'finance',
        extraData: {
          'hasScreenshot': true,
          'withdrawalId': requestId,
          'method': paymentMethod,
        },
      );

      Get.back();
      Get.snackbar(
        "Success ✅",
        "Withdrawal approved with screenshot",
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

  // ════════════════════════════════════════════════════════════════════════════
  //  WITHDRAWAL — REJECT (full refund)
  // ════════════════════════════════════════════════════════════════════════════
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

      var financeDoc = await _db.collection('finances').doc(requestId).get();
      if (!financeDoc.exists) {
        Get.back();
        Get.snackbar(
          "Error",
          "Request not found",
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        return;
      }

      var financeData = financeDoc.data() as Map<String, dynamic>;
      double refundAmount =
          (financeData['requestedAmount'] ?? financeData['amount'] ?? 0.0)
              .toDouble();

      await _db.collection('finances').doc(requestId).update({
        'status': 'rejected',
        'rejectionReason': reason,
        'processedAt': FieldValue.serverTimestamp(),
      });

      if (refundAmount > 0) {
        await _db.collection('users').doc(userId).update({
          'walletBalance': FieldValue.increment(refundAmount),
        });
      }

      await _db.collection('users').doc(userId).collection('wallet_history').add({
        'amount': refundAmount,
        'type': 'withdrawal_rejected',
        'description':
            'Withdrawal rejected — Rs.${refundAmount.toStringAsFixed(0)} refunded to your wallet. Reason: $reason',
        'refundedAmount': refundAmount,
        'rejectionReason': reason,
        'timestamp': FieldValue.serverTimestamp(),
      });

      await _sendNotification(
        userId: userId,
        title: "Withdrawal Rejected ❌",
        body:
            "Your withdrawal request has been rejected. Rs.${refundAmount.toStringAsFixed(0)} has been refunded to your wallet. Reason: $reason",
        type: 'finance',
      );

      Get.back();
      Get.snackbar(
        "Rejected",
        "Withdrawal rejected and Rs.${refundAmount.toStringAsFixed(0)} refunded",
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

  // ════════════════════════════════════════════════════════════════════════════
  //  DEPOSIT — APPROVE
  // ════════════════════════════════════════════════════════════════════════════
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
        var userDoc = await _db.collection('users').doc(userId).get();
        var userData = userDoc.data() as Map<String, dynamic>? ?? {};
        double currentPaid = (userData['paidFees'] ?? 0.0).toDouble();

        final settingsDoc = await _db
            .collection('admin_settings')
            .doc('mlm_variables')
            .get();
        double totalFee = (settingsDoc.data()?['membershipFee'] ?? 0.0)
            .toDouble();

        double newPaid = double.parse(
          (currentPaid + amount).toStringAsFixed(2),
        );
        bool isFullyPaid = totalFee > 0 && newPaid >= totalFee;

        await _db.collection('users').doc(userId).update({
          'paidFees': newPaid,
          'membershipStatus': isFullyPaid ? 'approved' : 'unpaid',
          if (isFullyPaid) 'isMLMActive': true,
          if (isFullyPaid) 'rejectionReason': '',
        });

        await _db.collection('users').doc(userId).collection('wallet_history').add({
          'amount': amount,
          'type': isFullyPaid ? 'fee_payment_approved' : 'fee_partial_approved',
          'description': isFullyPaid
              ? 'Membership fee fully paid! Rs.${amount.toStringAsFixed(0)} — Membership Active!'
              : 'Partial fee approved Rs.${amount.toStringAsFixed(0)} — Paid: Rs.${newPaid.toStringAsFixed(0)} / Rs.${totalFee.toStringAsFixed(0)}',
          'timestamp': FieldValue.serverTimestamp(),
        });

        await _sendNotification(
          userId: userId,
          title: isFullyPaid
              ? "Membership Activated! 🎉"
              : "Fee Payment Approved ✅",
          body: isFullyPaid
              ? "Congratulations! Your membership is now active. You can now earn rewards and commissions!"
              : "Rs.${amount.toStringAsFixed(0)} fee payment approved. Total paid: Rs.${newPaid.toStringAsFixed(0)} / Rs.${totalFee.toStringAsFixed(0)}",
          type: 'finance',
        );
      } else {
        await _db.collection('users').doc(userId).update({
          'walletBalance': FieldValue.increment(amount),
        });

        await _db.collection('users').doc(userId).collection('wallet_history').add({
          'amount': amount,
          'type': 'deposit_approved',
          'description':
              'Deposit Approved — Rs.${amount.toStringAsFixed(0)} added to your wallet',
          'timestamp': FieldValue.serverTimestamp(),
        });

        await _sendNotification(
          userId: userId,
          title: "Deposit Approved ✅",
          body:
              "Rs.${amount.toStringAsFixed(0)} has been added to your wallet successfully!",
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

  // ════════════════════════════════════════════════════════════════════════════
  //  DEPOSIT — REJECT
  // ════════════════════════════════════════════════════════════════════════════
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
        body:
            "Your payment request has been rejected. Reason: $reason. Please contact support if you have questions.",
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

  // ════════════════════════════════════════════════════════════════════════════
  //  ORDER PAYMENT — APPROVE
  //
  //  ✅ CHANGE: Order status is now 'pending' (not 'confirmed').
  //  Admin verified payment — order enters the queue as pending.
  //  Admin must then manually move: pending → confirmed → shipped → delivered.
  //
  //  Notification sent: "Payment Confirmed" — tells user payment was received
  //  and their order is now in the system, pending processing.
  // ════════════════════════════════════════════════════════════════════════════
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

      List orderItems = data['items'] ?? [];
      double subTotal = (data['subTotal'] ?? 0.0).toDouble();
      double shippingFee = (data['shippingFee'] ?? 0.0).toDouble();
      double grandTotal = (data['totalAmount'] ?? 0.0).toDouble();
      String paymentMethod = data['method'] ?? 'Online Payment';
      String customerAddress = data['customerAddress'] ?? '';

      // ✅ Order created with 'pending' status — not 'confirmed'
      await _db.collection('orders').doc(orderId).set({
        'orderId': orderId,
        'userId': userId,
        'userEmail': data['userEmail'],
        'customerName': data['customerName'],
        'customerPhone': data['customerPhone'],
        'customerAddress': customerAddress,
        'items': orderItems,
        'subTotal': subTotal,
        'shippingFee': shippingFee,
        'grossProfit': data['grossProfit'] ?? 0,
        'codCharges': 0,
        'grandTotal': grandTotal,
        'paymentMethod': paymentMethod,
        'trxId': data['trxId'],
        'status': 'pending', // ✅ pending, not confirmed
        'rewarded': false,
        'rewardPending': false,
        'rewardProcessing': false,
        'isReviewed': false,
        'createdAt': FieldValue.serverTimestamp(),
      });

      await _db.collection('finances').doc(financeId).update({
        'status': 'approved',
        'orderId': orderId,
        'processedAt': FieldValue.serverTimestamp(),
      });

      // ✅ "Payment Confirmed" notification — full order details included
      await _sendNotification(
        userId: userId,
        title: "Payment Confirmed! ✅",
        body:
            "Your payment of Rs.${grandTotal.toStringAsFixed(0)} has been verified. Your order #$orderId is now pending processing. We'll update you once it's confirmed.",
        type: 'order',
        extraData: {
          'orderId': orderId,
          'grandTotal': grandTotal,
          'subTotal': subTotal,
          'shippingFee': shippingFee,
          'codCharges': 0,
          'paymentMethod': paymentMethod,
          'customerAddress': customerAddress,
          'items': orderItems,
        },
      );

      Get.back();
      Get.snackbar(
        "Success ✅",
        "Payment approved — Order #$orderId created (pending)",
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

  // ════════════════════════════════════════════════════════════════════════════
  //  ORDER PAYMENT — REJECT
  // ════════════════════════════════════════════════════════════════════════════
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
            "Your order payment has been rejected. Reason: $reason. Please contact support or resubmit with correct payment details.",
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

  // ════════════════════════════════════════════════════════════════════════════
  //  OLD FEE REQUESTS
  // ════════════════════════════════════════════════════════════════════════════
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

  // ════════════════════════════════════════════════════════════════════════════
  //  HISTORY
  // ════════════════════════════════════════════════════════════════════════════
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

  // ════════════════════════════════════════════════════════════════════════════
  //  HELPER: Send notification to customer
  // ════════════════════════════════════════════════════════════════════════════
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
      print("⚠️ [OrdersController] _sendNotification error: $e");
    }
  }
}
