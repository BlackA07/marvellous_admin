// Path: lib/features/orders/controllers/orders_controller.dart
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
  // --- NEW: Vendor Account Signups ---
  var pendingVendorAccounts = <Map<String, dynamic>>[].obs;

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
      _listenToVendorAccounts();
      _listenToOldFeeRequests();
    }
  }
  // ════════════════════════════════════════════════════════════════════════════
  //  NEW: VENDOR ACCOUNT APPROVAL LOGIC
  // ════════════════════════════════════════════════════════════════════════════

  void _listenToVendorAccounts() {
    _db
        .collection('vendors')
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .listen((snap) {
          pendingVendorAccounts.assignAll(
            snap.docs.map((doc) {
              var data = doc.data();
              data['id'] = doc.id;
              return data;
            }).toList(),
          );
        });
  }

  // orders_controller.dart mein SIRF approveVendorAccount function replace karo
  // Koi extra import nahi chahiye - cloud_firestore already imported hai

  Future<void> approveVendorAccount(String vendorUid) async {
    try {
      Get.dialog(
        const Center(child: CircularProgressIndicator(color: Colors.green)),
        barrierDismissible: false,
      );

      // 1. Vendor doc fetch karo
      DocumentSnapshot vendorDoc = await _db
          .collection('vendors')
          .doc(vendorUid)
          .get();

      if (!vendorDoc.exists) {
        Get.back();
        Get.snackbar(
          "Error",
          "Vendor not found",
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        return;
      }

      Map<String, dynamic> vendorData =
          vendorDoc.data() as Map<String, dynamic>;

      // 2. Vendor status approve karo
      await _db.collection('vendors').doc(vendorUid).update({
        'status': 'approved',
        'approvedAt': FieldValue.serverTimestamp(),
      });

      // 3. ✅ Pending new categories Firestore mein sync karo
      // (Vendor ne signup ke waqt jo naye categories type kiye the)
      List<Map<String, dynamic>> pendingNewCats =
          List<Map<String, dynamic>>.from(
            vendorData['pendingNewCategories'] ?? [],
          );

      List<Map<String, dynamic>> pendingNewSubs =
          List<Map<String, dynamic>>.from(
            vendorData['pendingNewSubCategories'] ?? [],
          );

      // Naye categories Firestore mein add karo
      for (var cat in pendingNewCats) {
        String catName = (cat['name'] ?? '').toString().trim();
        if (catName.isEmpty) continue;

        // Pehle check karo ke exist toh nahi karta
        var existing = await _db
            .collection('categories')
            .where('name', isEqualTo: catName)
            .limit(1)
            .get();

        if (existing.docs.isEmpty) {
          await _db.collection('categories').add({
            'name': catName,
            'subCategories': [],
            'createdAt': FieldValue.serverTimestamp(),
          });
          debugPrint('✅ New category added: $catName');
        }
      }

      // Naye sub-categories existing category docs mein add karo
      for (var sub in pendingNewSubs) {
        String catName = (sub['categoryName'] ?? '').toString().trim();
        String subName = (sub['subName'] ?? '').toString().trim();
        if (catName.isEmpty || subName.isEmpty) continue;

        var catQuery = await _db
            .collection('categories')
            .where('name', isEqualTo: catName)
            .limit(1)
            .get();

        if (catQuery.docs.isNotEmpty) {
          await _db.collection('categories').doc(catQuery.docs.first.id).update(
            {
              'subCategories': FieldValue.arrayUnion([subName]),
            },
          );
          debugPrint('✅ Sub-category added: $subName under $catName');
        }
      }

      Get.back();
      Get.snackbar(
        "Success ✅",
        "Vendor Account Approved!",
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e) {
      Get.back();
      Get.snackbar(
        "Error",
        "Failed: $e",
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  Future<void> rejectVendorAccount(String vendorUid, String reason) async {
    try {
      Get.dialog(
        const Center(child: CircularProgressIndicator(color: Colors.red)),
        barrierDismissible: false,
      );
      await _db.collection('vendors').doc(vendorUid).update({
        'status': 'rejected',
        'rejectionReason': reason,
        'rejectedAt': FieldValue.serverTimestamp(),
      });
      Get.back();
      Get.snackbar(
        "Rejected",
        "Vendor Account Rejected!",
        backgroundColor: Colors.orange,
        colorText: Colors.white,
      );
    } catch (e) {
      Get.back();
      Get.snackbar(
        "Error",
        "Failed: $e",
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
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
  //  ORDER STATUS UPDATE (WITH INSTANT ATOMIC REWARDS)
  // ════════════════════════════════════════════════════════════════════════════
  Future<void> updateOrderStage(String orderId, String newStatus) async {
    try {
      final orderRef = _db.collection('orders').doc(orderId);

      if (newStatus == 'delivered') {
        Get.dialog(
          const Center(child: CircularProgressIndicator(color: Colors.green)),
          barrierDismissible: false,
        );

        DocumentSnapshot snap = await orderRef.get();
        if (!snap.exists) throw Exception('Order not found');
        var data = snap.data() as Map<String, dynamic>;

        if (data['rewarded'] == true) {
          Get.back();
          throw Exception('ALREADY_REWARDED');
        }

        bool success = await _processInstantRewardsAtomically(orderId, data);

        if (success) {
          await orderRef.update({
            'status': 'delivered',
            'rewarded': true,
            'rewardPending': false,
            'rewardProcessing': false,
            'rewardedAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          });

          debugPrint(
            "✅ ADMIN: Order #$orderId DELIVERED and REWARDS DISTRIBUTED instantly!",
          );
        }

        Get.back();
      } else {
        DocumentSnapshot orderDoc = await orderRef.get();
        if (!orderDoc.exists) return;
        var data = orderDoc.data() as Map<String, dynamic>;
        String userId = data['userId'] ?? '';

        await orderRef.update({
          'status': newStatus,
          'updatedAt': FieldValue.serverTimestamp(),
        });

        debugPrint("✅ ADMIN: Order #$orderId → $newStatus");

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
      if (Get.isDialogOpen ?? false) Get.back();
      _handleOrderUpdateError(e.message ?? e.code);
    } catch (e) {
      if (Get.isDialogOpen ?? false) Get.back();
      _handleOrderUpdateError(e.toString());
    }
  }

  void _handleOrderUpdateError(String msg) {
    if (msg.contains('ALREADY_DELIVERED') || msg.contains('ALREADY_REWARDED')) {
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

  // ════════════════════════════════════════════════════════════════════════════
  //  INSTANT ATOMIC REWARDS & MLM DISTRIBUTION
  // ════════════════════════════════════════════════════════════════════════════
  Future<bool> _processInstantRewardsAtomically(
    String orderId,
    Map<String, dynamic> orderData,
  ) async {
    String buyerUid = orderData['userId'] ?? '';
    if (buyerUid.isEmpty) return false;

    double grossProfit = (orderData['grossProfit'] ?? 0.0).toDouble();

    if (grossProfit <= 0) {
      debugPrint("⚠️ Order $orderId has 0 gross profit. Skipping rewards.");
      return true;
    }

    WriteBatch batch = _db.batch();
    double totalCompanyShare = 0.0;

    try {
      // 1. Fetch MLM Settings
      DocumentSnapshot settingsDoc = await _db
          .collection('admin_settings')
          .doc('mlm_variables')
          .get();
      Map<String, dynamic> settings =
          settingsDoc.data() as Map<String, dynamic>? ?? {};

      double mlmDistPercent = (settings['mlmDistributionPercent'] ?? 56.95)
          .toDouble();
      double cashbackPercent =
          (settings['cashbackPercent'] ?? 14.705882352941178).toDouble();
      int maxLevels = (settings['totalLevels'] ?? 13).toInt();

      double mlmPool = grossProfit * (mlmDistPercent / 100);

      // ── Points formula from Firebase global_config ──────────────────────
      double profitPerPoint = 199.0;
      bool showDecimals = false;
      try {
        final globalConfigDoc = await _db
            .collection('admin_settings')
            .doc('global_config')
            .get();
        if (globalConfigDoc.exists) {
          final gData = globalConfigDoc.data()!;
          profitPerPoint = (gData['profitPerPoint'] ?? 199.0).toDouble();
          showDecimals = gData['showDecimals'] ?? false;
          if (profitPerPoint <= 0) profitPerPoint = 199.0;
        }
      } catch (_) {}

      final double rawPoints = grossProfit / profitPerPoint;
      num pointsEarned = showDecimals
          ? double.parse(rawPoints.toStringAsFixed(2))
          : rawPoints.floor();

      // Fetch Commission Levels
      QuerySnapshot commSnap = await _db
          .collection('admin_settings')
          .doc('mlm_variables')
          .collection('commission_levels')
          .get();
      Map<String, double> commPercentages = {};
      for (var doc in commSnap.docs) {
        var d = doc.data() as Map<String, dynamic>;
        commPercentages[doc.id] = (d['percentage'] ?? 0.0).toDouble();
      }

      // 2. Fetch Buyer Data
      DocumentSnapshot buyerDoc = await _db
          .collection('users')
          .doc(buyerUid)
          .get();
      if (!buyerDoc.exists) return false;
      Map<String, dynamic> buyerData = buyerDoc.data() as Map<String, dynamic>;

      double buyerPoints = (buyerData['totalPoints'] ?? 0.0).toDouble();
      String buyerMemStatus = buyerData['membershipStatus'] ?? 'unpaid';
      String buyerName =
          buyerData['name'] ?? buyerData['username'] ?? 'Customer';

      // 3. Calculate Buyer Cashback
      double buyerRankMultiplier = _getRankMultiplier(buyerPoints, settings);
      if (buyerMemStatus == 'approved' && buyerRankMultiplier < 100.0) {
        buyerRankMultiplier += 25.0;
      }

      double maxCashback = mlmPool * (cashbackPercent / 100);
      double finalCashback = double.parse(
        (maxCashback * (buyerRankMultiplier / 100)).toStringAsFixed(2),
      );
      totalCompanyShare += (maxCashback - finalCashback);

      // Add cashback to Buyer Wallet
      _addWalletTransactionToBatch(
        batch: batch,
        uid: buyerUid,
        memStatus: buyerMemStatus,
        amount: finalCashback,
        type: 'cashback',
        description: 'Order cashback #$orderId',
        extraData: {
          'orderId': orderId,
          'points': pointsEarned,
          'grossProfit': grossProfit,
          'rankMultiplier': buyerRankMultiplier,
          'items': orderData['items'] ?? [],
        },
      );

      // Update Buyer Points
      batch.update(_db.collection('users').doc(buyerUid), {
        'totalPoints': FieldValue.increment(pointsEarned.toDouble()),
        'totalCashbackEarned': FieldValue.increment(finalCashback),
      });

      // ── REWARD NOTIFICATION — detailed with cashback + points ───────────
      final String rankLabel = _rankLabelFromMultiplier(buyerRankMultiplier);
      final String rewardBody =
          'Order #$orderId delivered! 🎉\n'
          'Rs.${finalCashback.toStringAsFixed(0)} cashback credited to your wallet.\n'
          '$pointsEarned points earned. (Rank: $rankLabel)';

      _addNotificationToBatch(
        batch,
        buyerUid,
        "Order Delivered & Rewards Credited! 🎉",
        rewardBody,
        'reward',
        {
          ..._buildOrderExtraData(orderId, orderData),
          'grossProfit': grossProfit,
          'pointsEarned': pointsEarned,
          'cashbackCredited': finalCashback,
          'rankMultiplier': buyerRankMultiplier,
          'status': 'delivered',
        },
      );

      // ── REVIEW NOTIFICATION — 3 sec delay outside batch ─────────────────
      // Sent after batch commit so orderId exists in Firestore
      Future.delayed(const Duration(seconds: 3), () async {
        try {
          await _db
              .collection('users')
              .doc(buyerUid)
              .collection('notifications')
              .add({
                'title': 'How was your order? 🌟',
                'body':
                    'Please take a moment to review your order #$orderId. Your feedback helps us improve!',
                'type': 'review',
                'isRead': false,
                'timestamp': FieldValue.serverTimestamp(),
                'data': {
                  'orderId': orderId,
                  'showReviewButton': true,
                  'items': orderData['items'] ?? [],
                },
              });
        } catch (e) {
          debugPrint('⚠️ Review notification error: $e');
        }
      });

      // 4. MLM Upline Distribution
      double poolForUplines = mlmPool - maxCashback;
      double totalBaseUsed = 0.0;
      String currentParentUid = buyerData['mlmParentUid'] ?? '';

      for (int level = 1; level <= maxLevels; level++) {
        if (currentParentUid.isEmpty) break;

        DocumentSnapshot uplineDoc = await _db
            .collection('users')
            .doc(currentParentUid)
            .get();
        if (!uplineDoc.exists) break;

        Map<String, dynamic> uplineData =
            uplineDoc.data() as Map<String, dynamic>;
        bool isMLMActive = uplineData['isMLMActive'] ?? false;

        if (!isMLMActive) {
          currentParentUid = uplineData['mlmParentUid'] ?? '';
          continue;
        }

        double levelPercent = commPercentages['level_$level'] ?? 0.0;
        if (levelPercent > 0) {
          double baseComm = mlmPool * (levelPercent / 100);
          double uplinePoints = (uplineData['totalPoints'] ?? 0.0).toDouble();
          String uplineMemStatus = uplineData['membershipStatus'] ?? 'unpaid';
          String uplineName =
              uplineData['name'] ?? uplineData['username'] ?? 'User';

          double rankMulti = _getRankMultiplier(uplinePoints, settings);
          if (uplineMemStatus == 'approved' && rankMulti < 100.0) {
            rankMulti += 25.0;
          }

          double finalComm = double.parse(
            (baseComm * (rankMulti / 100)).toStringAsFixed(2),
          );
          totalCompanyShare += (baseComm - finalComm);
          totalBaseUsed += baseComm;

          if (finalComm > 0) {
            _addWalletTransactionToBatch(
              batch: batch,
              uid: currentParentUid,
              memStatus: uplineMemStatus,
              amount: finalComm,
              type: 'commission',
              description:
                  'Level $level Commission from $buyerName\'s order #$orderId',
              extraData: {
                'orderId': orderId,
                'level': level,
                'fromUser': buyerName,
                'fromUid': buyerUid,
                'rankMultiplier': rankMulti,
                'grossProfit': grossProfit,
              },
            );

            // ── MLM Commission Notification — detailed ───────────────────
            final String uplineRankLabel = _rankLabelFromMultiplier(rankMulti);
            final String commBody =
                'Rs.${finalComm.toStringAsFixed(0)} commission credited! 💰\n'
                'Level $level • From: $buyerName\'s order\n'
                'Order #$orderId • Rank: $uplineRankLabel';

            _addNotificationToBatch(
              batch,
              currentParentUid,
              "Commission Earned! 💰",
              commBody,
              'finance',
              {
                'orderId': orderId,
                'level': level,
                'fromUser': buyerName,
                'fromUid': buyerUid,
                'amount': finalComm,
                'rankMultiplier': rankMulti,
              },
            );
          }
        }
        currentParentUid = uplineData['mlmParentUid'] ?? '';
      }

      double unallocated = poolForUplines - totalBaseUsed;
      if (unallocated > 0) totalCompanyShare += unallocated;

      // 5. Update Company Finances
      if (totalCompanyShare > 0) {
        batch.set(
          _db.collection('company_finances').doc('balance'),
          {'totalCompanyBalance': FieldValue.increment(totalCompanyShare)},
          SetOptions(merge: true),
        );

        DocumentReference histRef = _db
            .collection('company_finances')
            .doc('balance')
            .collection('history')
            .doc();
        batch.set(histRef, {
          'orderId': orderId,
          'amount': totalCompanyShare,
          'source': 'MLM System (Gaps & Unallocated)',
          'timestamp': FieldValue.serverTimestamp(),
        });
      }

      // 6. Commit batch atomically
      await batch.commit();

      // Stock updates (non-critical, outside batch)
      final List items = orderData['items'] ?? [];
      for (final item in items) {
        final pid = item['productId']?.toString() ?? '';
        if (pid.isNotEmpty) {
          int qty = int.tryParse(item['quantity']?.toString() ?? '1') ?? 1;
          _db
              .collection('products')
              .doc(pid)
              .update({'stockOut': FieldValue.increment(qty)})
              .catchError((e) {});
        }
      }

      return true;
    } catch (e) {
      debugPrint("❌ ATOMIC REWARD BATCH ERROR: $e");
      return false;
    }
  }

  // ── Helper: rank label from multiplier ────────────────────────────────────
  String _rankLabelFromMultiplier(double m) {
    if (m <= 25) return 'Bronze';
    if (m <= 50) return 'Silver';
    if (m <= 75) return 'Gold';
    return 'Diamond';
  }

  double _getRankMultiplier(double points, Map<String, dynamic> settings) {
    double bronze = (settings['bronzeLimit'] ?? 100.0).toDouble();
    double silver = (settings['silverLimit'] ?? 200.0).toDouble();
    double gold = (settings['goldLimit'] ?? 300.0).toDouble();
    if (points <= bronze) return 25.0;
    if (points <= silver) return 50.0;
    if (points <= gold) return 75.0;
    return 100.0;
  }

  void _addWalletTransactionToBatch({
    required WriteBatch batch,
    required String uid,
    required String memStatus,
    required double amount,
    required String type,
    required String description,
    required Map<String, dynamic> extraData,
  }) {
    if (amount <= 0) return;

    double toShopping = 0.0;
    double toMain = amount;

    if (memStatus == 'approved') {
      toShopping = double.parse((amount * 0.25).toStringAsFixed(2));
      toMain = double.parse((amount - toShopping).toStringAsFixed(2));
    }

    Map<String, dynamic> updates = {
      'totalCommissionEarned': FieldValue.increment(amount),
    };
    if (toMain > 0) updates['walletBalance'] = FieldValue.increment(toMain);
    if (toShopping > 0)
      updates['shoppingWalletBalance'] = FieldValue.increment(toShopping);

    batch.update(_db.collection('users').doc(uid), updates);

    if (toMain > 0) {
      DocumentReference mainHist = _db
          .collection('users')
          .doc(uid)
          .collection('wallet_history')
          .doc();
      batch.set(mainHist, {
        'type': type,
        'amount': toMain,
        'description': description,
        'timestamp': FieldValue.serverTimestamp(),
        ...extraData,
      });
    }

    if (toShopping > 0) {
      DocumentReference shopHist = _db
          .collection('users')
          .doc(uid)
          .collection('wallet_history')
          .doc();
      batch.set(shopHist, {
        'type': 'shopping_wallet_credit',
        'amount': toShopping,
        'description': 'Shopping Wallet (25%) — $description',
        'timestamp': FieldValue.serverTimestamp(),
        ...extraData,
      });
    }
  }

  void _addNotificationToBatch(
    WriteBatch batch,
    String uid,
    String title,
    String body,
    String type,
    Map<String, dynamic> extra,
  ) {
    DocumentReference notifRef = _db
        .collection('users')
        .doc(uid)
        .collection('notifications')
        .doc();
    batch.set(notifRef, {
      'title': title,
      'body': body,
      'type': type,
      'isRead': false,
      'timestamp': FieldValue.serverTimestamp(),
      'data': extra,
    });
  }

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
  //  WITHDRAWAL — APPROVE
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
            ? "Rs.${amountToReceive.toStringAsFixed(0)} sent to your $paymentMethod account. Rs.${feeDeducted.toStringAsFixed(0)} was applied to your membership fee. Check payment proof in notification details."
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
  //  WITHDRAWAL — REJECT
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
        'status': 'pending',
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
      debugPrint("⚠️ [OrdersController] _sendNotification error: $e");
    }
  }
}
