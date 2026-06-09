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

  var pendingOrders = <OrderModel>[].obs;
  var historyOrders = <OrderModel>[].obs;

  var pendingRequests = <VendorRequestModel>[].obs;
  var historyRequests = <VendorRequestModel>[].obs;
  var pendingVendorAccounts = <Map<String, dynamic>>[].obs;

  var withdrawalRequests = <Map<String, dynamic>>[].obs;
  var depositRequests = <Map<String, dynamic>>[].obs;
  var orderPaymentRequests = <Map<String, dynamic>>[].obs;

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

  Future<void> approveVendorAccount(String vendorUid) async {
    try {
      Get.dialog(
        const Center(child: CircularProgressIndicator(color: Colors.green)),
        barrierDismissible: false,
      );

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

      await _db.collection('vendors').doc(vendorUid).update({
        'status': 'approved',
        'approvedAt': FieldValue.serverTimestamp(),
      });

      List<Map<String, dynamic>> pendingNewCats =
          List<Map<String, dynamic>>.from(
            vendorData['pendingNewCategories'] ?? [],
          );

      List<Map<String, dynamic>> pendingNewSubs =
          List<Map<String, dynamic>>.from(
            vendorData['pendingNewSubCategories'] ?? [],
          );

      for (var cat in pendingNewCats) {
        String catName = (cat['name'] ?? '').toString().trim();
        if (catName.isEmpty) continue;

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
        }
      }

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

  // ✅ FIX: OrdersParsing Fix for LegacyJavaScriptObject
  void _listenToOrders() {
    _db
        .collection('orders')
        .where('status', whereIn: ['pending', 'confirmed', 'shipped'])
        .snapshots()
        .listen((snap) {
          final List<OrderModel> orders = [];
          for (var doc in snap.docs) {
            try {
              // Convert explicitly to Map<String, dynamic> before passing to fromFirestore
              final data = Map<String, dynamic>.from(doc.data());
              // Creating a temporary map and simulating a DocumentSnapshot is not ideal,
              // but we need to ensure the raw map is clean.
              // Assuming your OrderModel.fromFirestore takes a DocumentSnapshot
              // Alternatively, if you have OrderModel.fromMap, use that.
              // We will pass the doc directly but ensure it doesn't crash on internal lists.
              orders.add(OrderModel.fromFirestore(doc));
            } catch (e) {
              debugPrint(
                "❌ Error parsing OrderModel from Firestore: $e\nDocument ID: ${doc.id}",
              );
              // Skipping bad order, you can handle it differently if you want.
            }
          }
          pendingOrders.assignAll(orders);
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

  Future<void> updateOrderStage(
    String orderId,
    String newStatus, {
    String reason = '',
  }) async {
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
        }
        Get.back();
      } else {
        DocumentSnapshot orderDoc = await orderRef.get();
        if (!orderDoc.exists) return;
        var data = orderDoc.data() as Map<String, dynamic>;
        String userId = data['userId'] ?? '';

        await orderRef.update({
          'status': newStatus,
          if (reason.isNotEmpty) 'rejectionReason': reason,
          'updatedAt': FieldValue.serverTimestamp(),
        });

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
                  "Your order #$orderId has been rejected.\nReason: ${reason.isNotEmpty ? reason : 'Not specified'}\n\nNeed help? Tap the WhatsApp icon on the Home Screen and quote your Order ID.";

              // Refund logic
              String src = data['paymentSource'] ?? '';
              double deduction = (data['actualDeduction'] ?? 0.0).toDouble();

              if (deduction > 0) {
                if (src == 'main_wallet') {
                  await _db.collection('users').doc(userId).update({
                    'walletBalance': FieldValue.increment(deduction),
                  });
                  await _db
                      .collection('users')
                      .doc(userId)
                      .collection('wallet_history')
                      .add({
                        'amount': deduction,
                        'type': 'order_refund_wallet',
                        'description':
                            'Order #$orderId rejected — Rs.${deduction.toStringAsFixed(0)} refunded to wallet',
                        'orderId': orderId,
                        'timestamp': FieldValue.serverTimestamp(),
                      });
                } else if (src == 'shopping_wallet') {
                  await _db.collection('users').doc(userId).update({
                    'shoppingWalletBalance': FieldValue.increment(deduction),
                  });
                  await _db
                      .collection('users')
                      .doc(userId)
                      .collection('wallet_history')
                      .add({
                        'amount': deduction,
                        'type': 'order_refund_shopping_wallet',
                        'description':
                            'Order #$orderId rejected — Rs.${deduction.toStringAsFixed(0)} refunded to shopping wallet',
                        'orderId': orderId,
                        'timestamp': FieldValue.serverTimestamp(),
                      });
                }
              }
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
      if (Get.isDialogOpen == true) Get.back();
      _handleOrderUpdateError(e.message ?? e.code);
    } catch (e) {
      if (Get.isDialogOpen == true) Get.back();
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

  Future<String?> _findFirstAvailableSpotBFS(String startUid) async {
    List<String> queue = [startUid];
    Set<String> visited = {};
    while (queue.isNotEmpty) {
      String currentUid = queue.removeAt(0);
      if (visited.contains(currentUid)) continue;
      visited.add(currentUid);
      QuerySnapshot childrenSnap = await _db
          .collection('users')
          .doc(currentUid)
          .collection('mlm_downline')
          .orderBy('joinedAt', descending: false)
          .get();
      if (childrenSnap.docs.length < 7) return currentUid;
      for (var doc in childrenSnap.docs) {
        if (!visited.contains(doc.id)) queue.add(doc.id);
      }
    }
    return null;
  }

  Future<Map<String, dynamic>> _ensureUserInTree(
    String buyerUid,
    Map<String, dynamic> buyerData,
  ) async {
    String parentUid = buyerData['mlmParentUid'] ?? '';
    if (parentUid.isNotEmpty && (buyerData['mlmLevel'] ?? -1) != -1) {
      return buyerData;
    }

    String referralCode = buyerData['referralCode'] ?? '';
    if (referralCode.isEmpty) return buyerData;

    QuerySnapshot referrerQuery = await _db
        .collection('users')
        .where('myReferralCode', isEqualTo: referralCode)
        .limit(1)
        .get();

    if (referrerQuery.docs.isEmpty) return buyerData;

    String referrerUid = referrerQuery.docs.first.id;
    String? newParentUid = await _findFirstAvailableSpotBFS(referrerUid);
    if (newParentUid == null) return buyerData;

    DocumentSnapshot parentDoc = await _db
        .collection('users')
        .doc(newParentUid)
        .get();
    int parentLevel =
        (parentDoc.data() as Map<String, dynamic>)['mlmLevel'] ?? 0;
    int newUserLevel = parentLevel + 1;

    await _db
        .collection('users')
        .doc(newParentUid)
        .collection('mlm_downline')
        .doc(buyerUid)
        .set({
          'uid': buyerUid,
          'name': buyerData['name'] ?? buyerData['username'] ?? 'User',
          'level': newUserLevel,
          'joinedAt': FieldValue.serverTimestamp(),
          'isActive': true,
        });

    Map<String, dynamic> updates = {
      'isMLMActive': true,
      'mlmLevel': newUserLevel,
      'mlmParentUid': newParentUid,
      'mlmReferrerUid': referrerUid,
      'firstSaleDone': true,
    };

    await _db.collection('users').doc(buyerUid).update(updates);

    Map<String, dynamic> updatedData = Map.from(buyerData);
    updatedData.addAll(updates);
    return updatedData;
  }

  // ✅ FULL AUTOMATED PROCESS WITH SKIP LOGIC FOR DOUBLE COMMISSIONS
  Future<bool> _processInstantRewardsAtomically(
    String orderId,
    Map<String, dynamic> orderData,
  ) async {
    String buyerUid = (orderData['userId'] ?? '').toString().trim();
    if (buyerUid.isEmpty) return false;

    WriteBatch batch = _db.batch();
    double totalCompanyShare = 0.0;

    try {
      String paymentMethod = orderData['paymentMethod'] ?? '';
      double grandTotal =
          (orderData['grandTotal'] ?? orderData['totalAmount'] ?? 0.0)
              .toDouble();

      if (paymentMethod == 'Cash on Delivery' && grandTotal > 0) {
        var banksRef = _db
            .collection('company_finances')
            .doc('main_finances')
            .collection('banks');

        DocumentSnapshot? codBank;

        try {
          var cashSnap = await banksRef
              .where('name', isEqualTo: 'Cash')
              .limit(1)
              .get();
          if (cashSnap.docs.isNotEmpty) {
            codBank = cashSnap.docs.first;
          }
        } catch (_) {}

        if (codBank == null) {
          try {
            var sysSnap = await banksRef
                .where('isSystem', isEqualTo: true)
                .limit(1)
                .get();
            if (sysSnap.docs.isNotEmpty) {
              codBank = sysSnap.docs.first;
            }
          } catch (_) {}
        }

        if (codBank != null) {
          batch.update(codBank.reference, {
            'balance': FieldValue.increment(grandTotal),
          });

          DocumentReference txRef = _db
              .collection('company_finances')
              .doc('main_finances')
              .collection('transactions')
              .doc();
          batch.set(txRef, {
            'bankId': codBank.id,
            'type': 'in',
            'amount': grandTotal,
            'date': FieldValue.serverTimestamp(),
            'description': 'COD Payment added for Order #$orderId',
          });
          // --- NEW LEDGER HOOK: COD PAYMENT ---
          DocumentReference ledgerRef = _db
              .collection('admin_ledger_transactions')
              .doc();
          batch.set(ledgerRef, {
            'type': 'in',
            'category': 'product_purchase_cod',
            'amount': grandTotal,
            'paymentMethod': 'cash',
            'bankId': codBank.id,
            'bankName': 'Cash',
            'description': 'COD Payment for Order #$orderId',
            'linkedUserId': buyerUid,
            'linkedOrderId': orderId,
            'createdBy': 'system',
            'date': FieldValue.serverTimestamp(),
            'createdAt': FieldValue.serverTimestamp(),
            // Naye fields for breakdown
            'subTotal': orderData['subTotal'] ?? 0,
            'shippingFee': orderData['shippingFee'] ?? 0,
            'codCharges': orderData['codCharges'] ?? 0,
            'grossProfit': orderData['grossProfit'] ?? 0,
          });
        }
      }

      double grossProfit = (orderData['grossProfit'] ?? 0.0).toDouble();

      if (grossProfit <= 0) {
        await batch.commit();
        return true;
      }

      DocumentSnapshot buyerDoc = await _db
          .collection('users')
          .doc(buyerUid)
          .get();
      if (!buyerDoc.exists) return false;
      Map<String, dynamic> buyerData = buyerDoc.data() as Map<String, dynamic>;

      buyerData = await _ensureUserInTree(buyerUid, buyerData);

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

      double buyerPoints = (buyerData['totalPoints'] ?? 0.0).toDouble();
      String buyerMemStatus = buyerData['membershipStatus'] ?? 'unpaid';
      String buyerName =
          buyerData['name'] ?? buyerData['username'] ?? 'Customer';
      String buyerParentUid = (buyerData['mlmParentUid'] ?? '')
          .toString()
          .trim();
      String referrerUid = (buyerData['mlmReferrerUid'] ?? '')
          .toString()
          .trim();

      double buyerRankMultiplier = _getRankMultiplier(buyerPoints, settings);
      if (buyerMemStatus == 'approved' && buyerRankMultiplier < 100.0) {
        buyerRankMultiplier += 25.0;
      }

      double maxCashback = mlmPool * (cashbackPercent / 100);
      double finalCashback = double.parse(
        (maxCashback * (buyerRankMultiplier / 100)).toStringAsFixed(2),
      );
      totalCompanyShare += (maxCashback - finalCashback);

      await _addWalletTransactionToBatch(
        batch: batch,
        uid: buyerUid,
        memStatus: buyerMemStatus,
        amount: finalCashback,
        type: 'cashback',
        isCashback: true,
        description: 'Order cashback\nOrder No: $orderId',
        extraData: {
          'orderId': orderId,
          'points': pointsEarned,
          'grossProfit': grossProfit,
          'rankMultiplier': buyerRankMultiplier,
          'items': orderData['items'] ?? [],
        },
      );

      batch.update(_db.collection('users').doc(buyerUid), {
        'totalPoints': FieldValue.increment(pointsEarned.toDouble()),
      });

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

      // ✅ FIX 1: Admin app will now send SEPARATE Review notifications for each item
      final List items = orderData['items'] ?? [];
      for (var rawItem in items) {
        final itemMap = Map<String, dynamic>.from(rawItem as Map);
        final pid = itemMap['productId']?.toString() ?? '';
        final pName = itemMap['name']?.toString() ?? 'Product';

        if (pid.isNotEmpty) {
          _addNotificationToBatch(
            batch,
            buyerUid,
            'How was your $pName? 🌟',
            'Please take a moment to review $pName. Your feedback helps us improve!',
            'review',
            {
              'orderId': orderId,
              'showReviewButton': true,
              'items': [itemMap], // Individual item for review
            },
          );
        }
      }

      double poolForUplines = mlmPool - maxCashback;
      double totalBaseUsed = 0.0;

      if (referrerUid.isNotEmpty) {
        double level1Percent = commPercentages['level_1'] ?? 0.0;
        double refBaseComm = mlmPool * (level1Percent / 100);

        DocumentSnapshot refDoc = await _db
            .collection('users')
            .doc(referrerUid)
            .get();
        if (refDoc.exists) {
          var refData = refDoc.data() as Map<String, dynamic>;
          bool isRefActive = refData['isMLMActive'] ?? false;
          String refMemStatus = refData['membershipStatus'] ?? 'unpaid';
          double refPoints = (refData['totalPoints'] ?? 0.0).toDouble();

          if (isRefActive && level1Percent > 0) {
            double rankMulti = _getRankMultiplier(refPoints, settings);
            if (refMemStatus == 'approved' && rankMulti < 100.0)
              rankMulti += 25.0;

            double finalComm = double.parse(
              (refBaseComm * (rankMulti / 100)).toStringAsFixed(2),
            );
            double companyShare = refBaseComm - finalComm;

            if (finalComm > 0) {
              await _addWalletTransactionToBatch(
                batch: batch,
                uid: referrerUid,
                memStatus: refMemStatus,
                amount: finalComm,
                type: 'commission',
                isCashback: false,
                description:
                    'Direct Sale Bonus (Level 1)\nFrom: $buyerName\nOrder No: $orderId',
                extraData: {
                  'orderId': orderId,
                  'level': 1,
                  'fromUser': buyerName,
                  'fromUid': buyerUid,
                  'rankMultiplier': rankMulti,
                  'grossProfit': grossProfit,
                },
              );

              final String refRankLabel = _rankLabelFromMultiplier(rankMulti);
              _addNotificationToBatch(
                batch,
                referrerUid,
                "Direct Sale Bonus! 🚀",
                'Rs.${finalComm.toStringAsFixed(0)} Direct Sale Bonus credited! 💰\nFrom: $buyerName\nOrder No: $orderId\nRank: $refRankLabel',
                'finance',
                {
                  'orderId': orderId,
                  'level': 1,
                  'fromUser': buyerName,
                  'fromUid': buyerUid,
                  'amount': finalComm,
                  'rankMultiplier': rankMulti,
                },
              );

              DocumentReference commHistRef = _db
                  .collection('users')
                  .doc(referrerUid)
                  .collection('commission_history')
                  .doc();
              batch.set(commHistRef, {
                'amount': finalComm,
                'baseAmount': refBaseComm,
                'rankMultiplier': rankMulti,
                'level': 1,
                'depth': 1, // Physical depth added
                'fromUser': buyerName,
                'fromUid': buyerUid,
                'orderId': orderId,
                'type': 'direct_sale_bonus',
                'timestamp': FieldValue.serverTimestamp(),
              });
            }
            totalCompanyShare += companyShare;
            totalBaseUsed += refBaseComm;
          }
        }
      }

      String currentUplineUid = buyerParentUid.trim();
      int physicalDepth = 1;
      int level =
          2; // ✅ FIX: Use while loop to properly control skipped referrer

      while (currentUplineUid.isNotEmpty && level <= maxLevels) {
        DocumentSnapshot uDoc = await _db
            .collection('users')
            .doc(currentUplineUid)
            .get();
        if (!uDoc.exists) break;

        Map<String, dynamic> uData = uDoc.data() as Map<String, dynamic>;
        String nextParent = (uData['mlmParentUid'] ?? '').toString().trim();

        // ✅ FIX: Referrer skip without incrementing the level
        if (currentUplineUid == referrerUid) {
          double levelPercent = commPercentages['level_$level'] ?? 0.0;
          if (levelPercent > 0) {
            double baseComm = mlmPool * (levelPercent / 100);
            if (baseComm > 0) {
              totalCompanyShare += baseComm;
              totalBaseUsed += baseComm;
            }
          }
          currentUplineUid = nextParent;
          physicalDepth++;
          continue;
        }

        bool isMLMActive = uData['isMLMActive'] ?? false;
        if (!isMLMActive) {
          currentUplineUid = nextParent;
          physicalDepth++;
          level++;
          continue;
        }

        double levelPercent = commPercentages['level_$level'] ?? 0.0;
        if (levelPercent > 0) {
          double baseComm = mlmPool * (levelPercent / 100);
          double uPoints = (uData['totalPoints'] ?? 0.0).toDouble();
          String uMemStatus = uData['membershipStatus'] ?? 'unpaid';

          double rankMulti = _getRankMultiplier(uPoints, settings);
          if (uMemStatus == 'approved' && rankMulti < 100.0) rankMulti += 25.0;

          double finalComm = double.parse(
            (baseComm * (rankMulti / 100)).toStringAsFixed(2),
          );
          totalCompanyShare += (baseComm - finalComm);
          totalBaseUsed += baseComm;

          if (finalComm > 0) {
            await _addWalletTransactionToBatch(
              batch: batch,
              uid: currentUplineUid,
              memStatus: uMemStatus,
              amount: finalComm,
              type: 'commission',
              isCashback: false,
              description:
                  'Level $level Commission\nFrom: $buyerName\nOrder No: $orderId',
              extraData: {
                'orderId': orderId,
                'level': level,
                'fromUser': buyerName,
                'fromUid': buyerUid,
                'rankMultiplier': rankMulti,
                'grossProfit': grossProfit,
              },
            );

            final String uRankLabel = _rankLabelFromMultiplier(rankMulti);
            _addNotificationToBatch(
              batch,
              currentUplineUid,
              "Commission Earned! 💰",
              'Rs.${finalComm.toStringAsFixed(0)} commission credited! 💰\nLevel $level\nFrom: $buyerName\nOrder No: $orderId\nRank: $uRankLabel',
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

            DocumentReference commHistRef = _db
                .collection('users')
                .doc(currentUplineUid)
                .collection('commission_history')
                .doc();
            batch.set(commHistRef, {
              'amount': finalComm,
              'baseAmount': baseComm,
              'rankMultiplier': rankMulti,
              'level': level, // Matrix table level mapped exactly
              'depth': physicalDepth, // Physical UI box depth
              'fromUser': buyerName,
              'fromUid': buyerUid,
              'orderId': orderId,
              'type': 'downline_purchase',
              'timestamp': FieldValue.serverTimestamp(),
            });
          }
        }
        currentUplineUid = nextParent;
        physicalDepth++;
        level++;
      }

      double unallocated = poolForUplines - totalBaseUsed;
      if (unallocated > 0) totalCompanyShare += unallocated;

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

      await batch.commit();

      for (final item in items) {
        final pid = (item['productId'] ?? '').toString().trim();
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

  Future<void> _addWalletTransactionToBatch({
    required WriteBatch batch,
    required String uid,
    required String memStatus,
    required double amount,
    required String type,
    required bool isCashback,
    required String description,
    required Map<String, dynamic> extraData,
  }) async {
    if (amount <= 0) return;

    double actualDeduction = 0.0;
    double newGiven = 0.0;
    double newRemaining = 0.0;
    bool isDone = false;

    try {
      var lockSnap = await _db
          .collection('sponsor_locks')
          .where('userUid', isEqualTo: uid)
          .where('active', isEqualTo: true)
          .limit(1)
          .get();

      if (lockSnap.docs.isNotEmpty) {
        var lockDoc = lockSnap.docs.first;
        var lockData = lockDoc.data();
        double remaining = (lockData['remaining'] ?? 0.0).toDouble();

        if (remaining > 0) {
          double percent = (lockData['percent'] ?? 0.0).toDouble();
          String sponsorUidVal = lockData['sponsorUid'] ?? '';
          String sponsorNameVal = lockData['sponsorName'] ?? 'Sponsor';
          double totalAmount = (lockData['totalAmount'] ?? 0.0).toDouble();
          double given = (lockData['given'] ?? 0.0).toDouble();

          if (sponsorUidVal.isNotEmpty && percent > 0) {
            double rawDeduction = amount * (percent / 100);
            actualDeduction = rawDeduction > remaining
                ? remaining
                : rawDeduction;
            actualDeduction = double.parse(actualDeduction.toStringAsFixed(2));

            if (actualDeduction > 0) {
              newGiven = double.parse(
                (given + actualDeduction).toStringAsFixed(2),
              );
              newRemaining = double.parse(
                (totalAmount - newGiven).toStringAsFixed(2),
              );
              if (newRemaining < 0) newRemaining = 0.0;
              isDone = newRemaining <= 0;
              String userName = lockData['userName'] ?? 'User';

              batch.update(lockDoc.reference, {
                'given': newGiven,
                'remaining': newRemaining,
                'active': !isDone,
                if (isDone) 'completedAt': FieldValue.serverTimestamp(),
              });

              batch.update(_db.collection('users').doc(sponsorUidVal), {
                'walletBalance': FieldValue.increment(actualDeduction),
                'totalCommissionEarned': FieldValue.increment(actualDeduction),
              });

              DocumentReference spUserHist = _db
                  .collection('users')
                  .doc(uid)
                  .collection('wallet_history')
                  .doc();
              batch.set(spUserHist, {
                'amount': -actualDeduction,
                'type': 'sponsor_deduction',
                'description':
                    'Sponsor deduction (${percent.toStringAsFixed(0)}%) → $sponsorNameVal — Rs.${actualDeduction.toStringAsFixed(0)}${isDone ? " [Lock Complete ✅]" : ""}',
                'sponsorUid': sponsorUidVal,
                'sponsorName': sponsorNameVal,
                'percent': percent,
                'givenSoFar': newGiven,
                'remaining': newRemaining,
                'totalAmount': totalAmount,
                'timestamp': FieldValue.serverTimestamp(),
              });

              DocumentReference spHist = _db
                  .collection('users')
                  .doc(sponsorUidVal)
                  .collection('wallet_history')
                  .doc();
              batch.set(spHist, {
                'amount': actualDeduction,
                'type': 'sponsor_income',
                'description':
                    'Sponsor income from $userName (${percent.toStringAsFixed(0)}%) — Rs.${actualDeduction.toStringAsFixed(0)}${isDone ? " [Lock Complete ✅]" : ""}',
                'fromUid': uid,
                'fromName': userName,
                'percent': percent,
                'givenSoFar': newGiven,
                'remaining': newRemaining,
                'totalAmount': totalAmount,
                'timestamp': FieldValue.serverTimestamp(),
              });

              DocumentReference sponsoredSubRef = _db
                  .collection('users')
                  .doc(sponsorUidVal)
                  .collection('sponsored_users')
                  .doc(uid);
              batch.set(sponsoredSubRef, {
                'given': newGiven,
                'remaining': newRemaining,
                'active': !isDone,
                if (isDone) 'completedAt': FieldValue.serverTimestamp(),
              }, SetOptions(merge: true));

              _addNotificationToBatch(
                batch,
                sponsorUidVal,
                'Sponsor Income 💰',
                'Rs.${actualDeduction.toStringAsFixed(0)} added to your wallet from $userName (${percent.toStringAsFixed(0)}%)',
                'sponsor_income',
                {},
              );

              _addNotificationToBatch(
                batch,
                uid,
                'Sponsor Deduction 💸',
                'Rs.${actualDeduction.toStringAsFixed(0)} sent to sponsor ($sponsorNameVal). Remaining: Rs.${newRemaining.toStringAsFixed(0)}',
                'sponsor_deduction',
                {},
              );
            }
          }
        } else {
          batch.update(lockDoc.reference, {'active': false});
        }
      }
    } catch (e) {
      debugPrint("❌ Admin Sponsor Deduction Error: $e");
    }

    double afterSponsor = amount - actualDeduction;
    if (afterSponsor < 0) afterSponsor = 0;

    double heDeductedAmount = 0.0;
    Map<String, dynamic> heLock = {};

    if (afterSponsor > 0) {
      DocumentSnapshot vars = await _db
          .collection('admin_settings')
          .doc('mlm_variables')
          .get();
      double hThreshold = 25000.0;
      double hDeduction = 2500.0;
      if (vars.exists && vars.data() != null) {
        var vData = vars.data() as Map<String, dynamic>;
        hThreshold = (vData['highEarnerThreshold'] ?? 25000.0).toDouble();
        hDeduction = (vData['highEarnerDeduction'] ?? 2500.0).toDouble();
      }

      DocumentSnapshot userDoc = await _db.collection('users').doc(uid).get();
      var userData = userDoc.data() as Map<String, dynamic>? ?? {};

      if (userData['highEarnerLock'] != null) {
        try {
          heLock = Map<String, dynamic>.from(userData['highEarnerLock']);
        } catch (_) {
          heLock = {
            'active': false,
            'given': 0.0,
            'target': hDeduction,
            'earningsSinceLastLock': 0.0,
          };
        }
      } else {
        heLock = {
          'active': false,
          'given': 0.0,
          'target': hDeduction,
          'earningsSinceLastLock': 0.0,
        };
      }

      bool isHeActive = heLock['active'] ?? false;
      double heGiven = (heLock['given'] ?? 0.0).toDouble();
      double heTarget = (heLock['target'] ?? hDeduction).toDouble();
      double heEarningsSince = (heLock['earningsSinceLastLock'] ?? 0.0)
          .toDouble();

      if (!isHeActive) {
        heEarningsSince +=
            amount; // ✅ FIX: Use 'amount' (Gross) instead of 'afterSponsor' for total earnings metric calculations
        if (heEarningsSince >= hThreshold) {
          isHeActive = true;
          heTarget = hDeduction;
          heGiven = 0.0;
          heEarningsSince = heEarningsSince - hThreshold;
        }
      }

      if (isHeActive) {
        double remainingLock = heTarget - heGiven;
        if (afterSponsor > remainingLock) {
          heDeductedAmount = remainingLock;
        } else {
          heDeductedAmount = afterSponsor;
        }

        heGiven += heDeductedAmount;
        if (heGiven >= heTarget) {
          isHeActive = false;
        }
      }

      heLock['active'] = isHeActive;
      heLock['given'] = heGiven;
      heLock['target'] = heTarget;
      heLock['earningsSinceLastLock'] = heEarningsSince;
    }

    double netAmount = afterSponsor - heDeductedAmount;
    if (netAmount < 0) netAmount = 0;

    double toShopping = 0.0;
    double toMain = netAmount;

    if (memStatus == 'approved' && netAmount > 0) {
      toShopping = double.parse((netAmount * 0.25).toStringAsFixed(2));
      toMain = double.parse((netAmount - toShopping).toStringAsFixed(2));
    }

    Map<String, dynamic> userUpdates = {
      'totalCommissionEarned': FieldValue.increment(amount),
    };

    if (isCashback) {
      userUpdates['totalCashbackEarned'] = FieldValue.increment(amount);
    }

    if (heLock.isNotEmpty) {
      userUpdates['highEarnerLock'] = heLock;
    }
    if (toMain > 0) userUpdates['walletBalance'] = FieldValue.increment(toMain);
    if (toShopping > 0)
      userUpdates['shoppingWalletBalance'] = FieldValue.increment(toShopping);

    if (actualDeduction > 0) {
      userUpdates['sponsorLock.given'] = newGiven;
      userUpdates['sponsorLock.remaining'] = newRemaining;
      userUpdates['sponsorLock.active'] = !isDone;
    }

    if (userUpdates.isNotEmpty) {
      batch.update(_db.collection('users').doc(uid), userUpdates);
    }

    if (heDeductedAmount > 0) {
      batch.set(_db.collection('company_finances').doc('balance'), {
        'totalCompanyBalance': FieldValue.increment(heDeductedAmount),
      }, SetOptions(merge: true));

      DocumentReference histRef = _db
          .collection('company_finances')
          .doc('balance')
          .collection('history')
          .doc();
      batch.set(histRef, {
        'orderId': extraData['orderId'] ?? 'N/A',
        'amount': heDeductedAmount,
        'source': 'Milestone Fee Deduction',
        'timestamp': FieldValue.serverTimestamp(),
      });

      DocumentReference mileHist = _db
          .collection('users')
          .doc(uid)
          .collection('wallet_history')
          .doc();
      batch.set(mileHist, {
        'amount': -heDeductedAmount,
        'type': 'milestone_deduction',
        'description':
            'Milestone Fee Deduction (Rs.${heLock['target']?.toStringAsFixed(0) ?? 2500}) — Target reached.',
        'timestamp': FieldValue.serverTimestamp(),
      });
    }

    String finalDescription = description;
    if (actualDeduction > 0) {
      finalDescription +=
          '\n(Sponsor Rs.${actualDeduction.toStringAsFixed(0)} deducted)';
    }

    if (toMain > 0) {
      DocumentReference mainHist = _db
          .collection('users')
          .doc(uid)
          .collection('wallet_history')
          .doc();
      batch.set(mainHist, {
        'type': type,
        'amount': toMain,
        'description': finalDescription,
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

  Future<void> rejectOrder(String orderId, {String reason = ''}) async {
    await updateOrderStage(orderId, 'rejected', reason: reason);
  }

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
      // --- NEW LEDGER HOOK: CUSTOMER WITHDRAWAL ---
      await _db.collection('admin_ledger_transactions').add({
        'type': 'out',
        'category': 'customer_withdrawal',
        'amount': amountToReceive,
        'paymentMethod': paymentMethod.toLowerCase().contains('cash')
            ? 'cash'
            : 'online',
        'description': 'Withdrawal approved for User',
        'linkedUserId': userId,
        'screenshotBase64': base64Image,
        'createdBy': 'system',
        'date': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
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
      String paymentMethod = data['method'] ?? '';
      String bankId = data['bankId'] ?? '';

      await _db.collection('finances').doc(requestId).update({
        'status': 'approved',
        'processedAt': FieldValue.serverTimestamp(),
      });

      if (bankId.isNotEmpty || paymentMethod.isNotEmpty) {
        try {
          var banksRef = _db
              .collection('company_finances')
              .doc('main_finances')
              .collection('banks');
          DocumentSnapshot? targetBank;

          if (bankId.isNotEmpty) {
            var b = await banksRef.doc(bankId).get();
            if (b.exists) targetBank = b;
          }

          if (targetBank == null && paymentMethod.isNotEmpty) {
            var bankSnap = await banksRef
                .where('name', isEqualTo: paymentMethod)
                .limit(1)
                .get();
            if (bankSnap.docs.isNotEmpty) {
              targetBank = bankSnap.docs.first;
            } else {
              var allBanks = await banksRef.get();
              for (var b in allBanks.docs) {
                if (b.data()['name'].toString().trim().toLowerCase() ==
                    paymentMethod.trim().toLowerCase()) {
                  targetBank = b;
                  break;
                }
              }
            }
          }

          if (targetBank != null) {
            await _db.runTransaction((transaction) async {
              DocumentSnapshot freshSnap = await transaction.get(
                targetBank!.reference,
              );
              if (freshSnap.exists) {
                double currentBal =
                    (freshSnap.data() as Map<String, dynamic>)['balance']
                        ?.toDouble() ??
                    0.0;
                transaction.update(targetBank.reference, {
                  'balance': currentBal + amount,
                });
              }
            });

            await _db
                .collection('company_finances')
                .doc('main_finances')
                .collection('transactions')
                .add({
                  'bankId': targetBank.id,
                  'type': 'in',
                  'amount': amount,
                  'date': FieldValue.serverTimestamp(),
                  'description': purpose == 'membership_fee'
                      ? 'Fee Deposit Approved'
                      : 'Wallet Deposit Approved',
                });
            // --- NEW LEDGER HOOK: ONLINE DEPOSIT ---
            await _db.collection('admin_ledger_transactions').add({
              'type': 'in',
              'category': purpose == 'membership_fee'
                  ? 'registration_fee'
                  : 'bank_transfer',
              'amount': amount,
              'paymentMethod': 'online',
              'bankId': targetBank.id,
              'description': purpose == 'membership_fee'
                  ? 'Membership Fee Deposit Approved'
                  : 'Wallet Deposit Approved',
              'linkedUserId': userId,
              'createdBy': 'system',
              'date': FieldValue.serverTimestamp(),
              'createdAt': FieldValue.serverTimestamp(),
            });
          }
        } catch (e) {
          debugPrint("Error updating bank balance for deposit: $e");
        }
      }

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
      String bankId = data['bankId'] ?? '';

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

      if (bankId.isNotEmpty || paymentMethod.isNotEmpty) {
        try {
          var banksRef = _db
              .collection('company_finances')
              .doc('main_finances')
              .collection('banks');
          DocumentSnapshot? targetBank;

          if (bankId.isNotEmpty) {
            var b = await banksRef.doc(bankId).get();
            if (b.exists) targetBank = b;
          }

          if (targetBank == null && paymentMethod.isNotEmpty) {
            var bankSnap = await banksRef
                .where('name', isEqualTo: paymentMethod)
                .limit(1)
                .get();
            if (bankSnap.docs.isNotEmpty) {
              targetBank = bankSnap.docs.first;
            } else {
              var allBanks = await banksRef.get();
              for (var b in allBanks.docs) {
                if (b.data()['name'].toString().trim().toLowerCase() ==
                    paymentMethod.trim().toLowerCase()) {
                  targetBank = b;
                  break;
                }
              }
            }
          }

          if (targetBank != null) {
            await _db.runTransaction((transaction) async {
              DocumentSnapshot freshSnap = await transaction.get(
                targetBank!.reference,
              );
              if (freshSnap.exists) {
                double currentBal =
                    (freshSnap.data() as Map<String, dynamic>)['balance']
                        ?.toDouble() ??
                    0.0;
                transaction.update(targetBank.reference, {
                  'balance': currentBal + grandTotal,
                });
              }
            });

            await _db
                .collection('company_finances')
                .doc('main_finances')
                .collection('transactions')
                .add({
                  'bankId': targetBank.id,
                  'type': 'in',
                  'amount': grandTotal,
                  'date': FieldValue.serverTimestamp(),
                  'description': 'Order Payment received for Order #$orderId',
                });
            // --- NEW LEDGER HOOK: ONLINE ORDER PAYMENT ---
            await _db.collection('admin_ledger_transactions').add({
              'type': 'in',
              'category': 'product_purchase_online',
              'amount': grandTotal,
              'paymentMethod': 'online',
              'bankId': targetBank.id,
              'description': 'Online Payment for Order #$orderId',
              'linkedUserId': userId,
              'linkedOrderId': orderId,
              'createdBy': 'system',
              'date': FieldValue.serverTimestamp(),
              'createdAt': FieldValue.serverTimestamp(),
            });
          }
        } catch (e) {
          debugPrint("Error updating bank balance: $e");
        }
      }

      await _sendNotification(
        userId: userId,
        title: "Payment Confirmed! ✅",
        body:
            "Your payment of Rs.${grandTotal.toStringAsFixed(0)} has been verified. Your order #$orderId is now pending processing.",
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
        "Payment approved — Order #$orderId created",
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
            "Your order payment (Ref ID: $financeId) has been rejected.\nReason: $reason\n\nNeed help? Tap the WhatsApp icon on the Home Screen and quote your Ref ID.",
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
