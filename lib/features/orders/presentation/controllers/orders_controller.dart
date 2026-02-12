import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../data/models/order_model.dart';
import '../../data/models/vendor_request_model.dart';
import '../../data/repositories/orders_repository.dart';

class OrdersController extends GetxController {
  final OrdersRepository _repo = OrdersRepository();
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  var pendingOrders = <OrderModel>[].obs;
  var pendingRequests = <VendorRequestModel>[].obs;
  var feeRequests = <Map<String, dynamic>>[].obs;
  var historyOrders = <OrderModel>[].obs;
  var historyRequests = <VendorRequestModel>[].obs;

  var isLoading = false.obs;

  int get pendingOrdersCount =>
      pendingOrders.where((o) => o.status == 'pending').length;
  int get pendingRequestsCount => pendingRequests.length;
  int get feeRequestsCount => feeRequests.length;

  @override
  void onInit() {
    super.onInit();
    bindStreams();
  }

  void bindStreams() {
    pendingOrders.bindStream(
      _repo.getOrdersByStatus(['pending', 'confirmed', 'shipped']),
    );
    pendingRequests.bindStream(_repo.getPendingRequests());
    feeRequests.bindStream(_repo.getFeeRequests());
  }

  void fetchHistory() {
    historyOrders.bindStream(
      _repo.getOrdersByStatus(['accepted', 'rejected', 'delivered']),
    );
    historyRequests.bindStream(_repo.getRequestHistory());
  }

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
      print("❌ Notification Error: $e");
    }
  }

  // --- PREVENT DOUBLE NOTIFICATIONS & SYNC STOCK ---
  Future<void> updateOrderStage(String id, String nextStage) async {
    try {
      isLoading.value = true;
      var orderDoc = await _db.collection('orders').doc(id).get();
      if (!orderDoc.exists) throw "Order not found";

      // FIXED: Case-insensitive comparison
      String currentStatus = (orderDoc.data()?['status'] ?? '')
          .toString()
          .toLowerCase()
          .trim();
      String targetStatus = nextStage.toLowerCase().trim();

      if (currentStatus == targetStatus) {
        Get.snackbar(
          "Already Updated",
          "Order is already in $nextStage status",
          backgroundColor: Colors.orange,
          colorText: Colors.white,
        );
        return;
      }

      String userId = orderDoc.data()?['userId'] ?? '';
      double grossProfit = (orderDoc.data()?['grossProfit'] ?? 0.0).toDouble();
      var items = orderDoc.data()?['items'] as List? ?? [];
      bool isReviewed = orderDoc.data()?['isReviewed'] ?? false;

      // Update status
      await _repo.updateOrderStatus(id, nextStage);

      if (userId.isNotEmpty) {
        Map<String, dynamic>? extraData;

        if (targetStatus == 'delivered') {
          // Process Rewards (only once)
          bool alreadyRewarded = orderDoc.data()?['rewarded'] ?? false;
          if (!alreadyRewarded) {
            await _internalProcessReward(userId, grossProfit, id);
            await _db.collection('orders').doc(id).update({'rewarded': true});
          }

          // --- SYNC STOCK OUT (SOLD COUNT) AUTOMATICALLY ---
          for (var item in items) {
            String pId = item['productId'] ?? '';
            bool isPkg = item['isPackage'] ?? false;
            String coll = isPkg ? 'packages' : 'products';

            if (pId.isNotEmpty) {
              await _db.collection(coll).doc(pId).update({
                'stockOut': FieldValue.increment(item['quantity'] ?? 1),
              });
            }
          }

          // Only show review button if not already reviewed
          if (!isReviewed) {
            extraData = {
              'orderId': id,
              'items': items,
              'showReviewButton': true,
            };
          }
        }

        // Send notification
        await _sendNotification(
          userId: userId,
          title: "Order ${nextStage.capitalizeFirst}",
          body: "Your order #$id has been ${nextStage.toLowerCase()}.",
          type: 'order',
          extraData: extraData,
        );
      }

      Get.snackbar(
        "Success",
        "Status Updated to $nextStage",
        backgroundColor: Colors.blue,
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar(
        "Error",
        e.toString(),
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _internalProcessReward(String uid, double gp, String oid) async {
    var varsDoc = await _db
        .collection('admin_settings')
        .doc('mlm_variables')
        .get();
    var v = varsDoc.data()!;
    var uDoc = await _db.collection('users').doc(uid).get();
    var u = uDoc.data()!;

    double pts = gp / (v['profitPerPoint'] ?? 1.0);
    double mDistP = (v['mlmDistributionPercent'] ?? 0.0).toDouble();
    double cBackP = (v['cashbackPercent'] ?? 0.0).toDouble();

    double mlmPool = gp * (mDistP / 100);
    double userBasePool = mlmPool * (cBackP / 100);

    double mult = 25.0;
    double curPts = (u['totalPoints'] ?? 0.0).toDouble();
    if (curPts > (v['goldLimit'] ?? 2000))
      mult = 100;
    else if (curPts > (v['silverLimit'] ?? 500))
      mult = 75;
    else if (curPts > (v['bronzeLimit'] ?? 100))
      mult = 50;

    if (u['membershipStatus'] == "approved" && mult < 100) mult += 25;

    double finalCash = userBasePool * (mult / 100);
    double compRem = userBasePool - finalCash;

    await _db.collection('users').doc(uid).update({
      'totalPoints': FieldValue.increment(pts),
      'walletBalance': FieldValue.increment(finalCash),
    });

    if (compRem > 0) {
      await _db.collection('company_finances').doc('balance').set({
        'totalCompanyBalance': FieldValue.increment(compRem),
      }, SetOptions(merge: true));
      await _db
          .collection('company_finances')
          .doc('balance')
          .collection('history')
          .add({
            'orderId': oid,
            'amount': compRem,
            'source': 'Rank Gap',
            'timestamp': FieldValue.serverTimestamp(),
          });
    }

    await _db.collection('users').doc(uid).collection('wallet_history').add({
      'amount': finalCash,
      'points': pts,
      'type': 'commission',
      'description': 'Reward for Order #$oid',
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  Future<void> acceptRequest(String id) async {
    try {
      isLoading.value = true;
      await _repo.updateRequestStatus(id, 'approved');
      Get.snackbar(
        "Success",
        "Vendor request approved!",
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar("Error", e.toString(), backgroundColor: Colors.red);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> rejectRequest(String id) async {
    try {
      isLoading.value = true;
      await _repo.updateRequestStatus(id, 'rejected');
      Get.snackbar(
        "Rejected",
        "Vendor request rejected.",
        backgroundColor: Colors.orange,
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar("Error", e.toString(), backgroundColor: Colors.red);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> acceptOrder(String id) async =>
      updateOrderStage(id, 'confirmed');
  Future<void> rejectOrder(String id) async => updateOrderStage(id, 'rejected');

  Future<void> approveFee(String reqId, String userId) async {
    await _repo.handleFeeRequest(reqId, userId, 'approved');
    _sendNotification(
      userId: userId,
      title: "Membership Approved",
      body: "Welcome!",
      type: 'info',
    );
  }

  Future<void> rejectFee(String reqId, String userId) async {
    await _repo.handleFeeRequest(reqId, userId, 'rejected');
  }

  @override
  void onClose() => super.onClose();
}
