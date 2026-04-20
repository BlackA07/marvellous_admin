import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../mlm/data/models/mlm_models.dart';
import '../models/customer_model.dart';

class CustomerDetailController extends GetxController {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final String uid;

  var isLoading = true.obs;
  var customer = Rxn<CustomerModel>();
  var mlmTree = Rxn<MLMNode>();

  // Dates
  var startDate = DateTime.now().subtract(const Duration(days: 30)).obs;
  var endDate = DateTime.now().obs;

  // Stats
  var ownSaleAmount = 0.0.obs;
  var receiptCount = 0.obs;
  var referralSaleTotal = 0.0.obs;
  var allLevelEarnings = 0.0.obs;
  var cashbackEarned = 0.0.obs;
  var totalWithdrawn = 0.0.obs;

  // Profile extras
  var downlineCount = 0.obs; // total active downline
  var directActiveCount = 0.obs; // direct active members
  var totalActiveCount = 0.obs; // all active members in tree
  var paidStatus = "".obs;
  var remainingFee = 0.0.obs;
  var membershipStatus = "".obs;
  var uplineCode = "".obs;

  // Level-wise earnings
  var levelEarnings = <Map<String, dynamic>>[].obs;
  var directReferralCount = 0.obs;

  // Orders
  var ordersList = <Map<String, dynamic>>[].obs;

  CustomerDetailController({required this.uid});

  @override
  void onInit() {
    super.onInit();
    loadAllData();
  }

  Future<void> loadAllData() async {
    isLoading(true);
    await _fetchCustomerData();
    await fetchStatsForDateRange();
    await _loadMLMTree();
    await _fetchProfileExtras();
    await fetchLevelEarnings();
    isLoading(false);
  }

  Future<void> _fetchCustomerData() async {
    try {
      var doc = await _db.collection('users').doc(uid).get();
      if (doc.exists) {
        customer.value = CustomerModel.fromMap(
          doc.data() as Map<String, dynamic>,
          doc.id,
        );
      }
    } catch (e) {
      Get.snackbar("Error", "Failed to load user info");
    }
  }

  Future<void> _fetchProfileExtras() async {
    if (customer.value == null) return;
    try {
      // Upline code
      uplineCode.value =
          customer.value!.referralCode == "null" ||
              customer.value!.referralCode.isEmpty
          ? "Top / Direct"
          : customer.value!.referralCode;

      // Membership status
      membershipStatus.value = customer.value!.membershipStatus ?? "pending";

      double requiredFee = 15000;
      double paidFee = 0.0;

      if (membershipStatus.value.toLowerCase() == "approved") {
        paidFee = requiredFee;
      } else {
        paidFee = 0.0;
      }

      paidStatus.value = paidFee >= requiredFee ? "Paid" : "Unpaid";
      remainingFee.value = (requiredFee - paidFee).clamp(0, double.infinity);

      // Direct active members (mlm_downline of this user, isMLMActive = true)
      final directSnap = await _db
          .collection('users')
          .doc(uid)
          .collection('mlm_downline')
          .get();

      int directActive = 0;
      for (var doc in directSnap.docs) {
        final userDoc = await _db.collection('users').doc(doc.id).get();
        if (userDoc.exists) {
          final data = userDoc.data() as Map<String, dynamic>;
          if (data['isMLMActive'] == true) directActive++;
        }
      }
      directActiveCount.value = directActive;
      directReferralCount.value = directActive;

      // Total active in full tree (counted during tree build)
      // Will be set after _loadMLMTree completes
    } catch (e) {
      debugPrint("Profile extras error: $e");
    }
  }

  // ── MLM TREE (mlm_downline subcollection, unlimited levels, active only) ──
  Future<void> _loadMLMTree() async {
    if (customer.value == null) return;
    try {
      int activeMembersTotal = 0;

      final root = await _buildAdminTree(
        nodeUid: uid,
        name: customer.value!.name,
        image: customer.value!.faceImage,
        myReferralCode: customer.value!.myReferralCode,
        level: 0,
        totalPoints: customer.value!.totalPoints,
        totalCommission: customer.value!.totalCashbackEarned,
        rank: _calcRank(customer.value!.totalPoints),
        isMLMActive: customer.value!.isMLMActive,
        parentUid: '', // root has no parent
        referrerUid: '', // root has no referrer
        rootUid: uid,
        activeMembersRef: (count) => activeMembersTotal += count,
      );

      mlmTree.value = root;
      totalActiveCount.value = activeMembersTotal;
      downlineCount.value = activeMembersTotal;
    } catch (e) {
      debugPrint("Tree error: $e");
    }
  }

  /// Builds tree from mlm_downline subcollection recursively.
  /// - Only includes nodes where isMLMActive == true
  /// - Detects isDirectReferral (joined via rootUser's referral code)
  /// - Detects isOverflow (placed under a different parent than referrer)
  Future<MLMNode> _buildAdminTree({
    required String nodeUid,
    required String name,
    required String image,
    required String myReferralCode,
    required int level,
    required double totalPoints,
    required double totalCommission,
    required String rank,
    required bool isMLMActive,
    required String parentUid,
    required String referrerUid,
    required String rootUid,
    required Function(int) activeMembersRef,
  }) async {
    List<MLMNode> children = [];
    int activeCount = 0;

    try {
      final downlineSnap = await _db
          .collection('users')
          .doc(nodeUid)
          .collection('mlm_downline')
          .get();

      // Sort by joinedAt ascending (earliest first)
      final sortedDocs = downlineSnap.docs.toList()
        ..sort((a, b) {
          final aData = a.data() as Map<String, dynamic>;
          final bData = b.data() as Map<String, dynamic>;
          final aTime = aData['joinedAt'] as Timestamp?;
          final bTime = bData['joinedAt'] as Timestamp?;
          if (aTime == null && bTime == null) return 0;
          if (aTime == null) return 1;
          if (bTime == null) return -1;
          return aTime.compareTo(bTime);
        });

      for (var doc in sortedDocs) {
        final childUid = doc.id;
        try {
          final childDoc = await _db.collection('users').doc(childUid).get();
          if (!childDoc.exists) continue;

          final childData = childDoc.data() as Map<String, dynamic>;

          // ✅ Skip inactive users — they don't appear in tree or count
          if (childData['isMLMActive'] != true) continue;

          final childPoints = (childData['totalPoints'] ?? 0.0).toDouble();
          final childComm = (childData['totalCashbackEarned'] ?? 0.0)
              .toDouble();
          final childRank = _calcRank(childPoints);
          final childReferralCode = childData['referralCode'] ?? '';
          final childParentUid = childData['mlmParentUid'] ?? '';
          final childReferrerUid = childData['mlmReferrerUid'] ?? '';
          final childMyCode = childData['myReferralCode'] ?? '';

          // D badge: direct referral of root user
          final bool isDirectReferral =
              childReferralCode == customer.value!.myReferralCode;

          // OF badge: placed under a different parent than who referred them
          final bool isOverflow =
              childReferrerUid.isNotEmpty &&
              childParentUid.isNotEmpty &&
              childReferrerUid != childParentUid;

          int childActiveCount = 0;

          final childNode = await _buildAdminTree(
            nodeUid: childUid,
            name: childData['name'] ?? childData['username'] ?? 'User',
            image: childData['faceImage'] ?? '',
            myReferralCode: childMyCode,
            level: level + 1,
            totalPoints: childPoints,
            totalCommission: childComm,
            rank: childRank,
            isMLMActive: true,
            parentUid: childParentUid,
            referrerUid: childReferrerUid,
            rootUid: rootUid,
            activeMembersRef: (count) => childActiveCount += count,
          );

          activeCount++;
          activeCount += childActiveCount;
          activeMembersRef(1 + childActiveCount);

          children.add(
            childNode.copyWith(
              isDirectReferral: isDirectReferral,
              isOverflow: isOverflow,
            ),
          );
        } catch (e) {
          debugPrint("Error loading child $childUid: $e");
        }
      }
    } catch (e) {
      debugPrint("Error loading downline for $nodeUid: $e");
    }

    return MLMNode(
      uid: nodeUid,
      name: name,
      image: image,
      myReferralCode: myReferralCode,
      level: level,
      isMLMActive: isMLMActive,
      hasPaidFee: false,
      rank: rank,
      totalCommissionEarned: totalCommission,
      children: children,
      totalMembers: activeCount,
      paidMembers: 0,
      remainingSlots: 7 - children.length,
      isOverflow: false,
      isDirectReferral: false,
    );
  }

  String _calcRank(double points) {
    if (points <= 100) return 'Bronze';
    if (points <= 200) return 'Silver';
    if (points <= 300) return 'Gold';
    return 'Diamond';
  }

  // ── PUBLIC: fetch level earnings ────────────────────────────────────────
  Future<void> fetchLevelEarnings() async {
    try {
      final start = Timestamp.fromDate(startDate.value);
      final end = Timestamp.fromDate(
        endDate.value.add(const Duration(hours: 23, minutes: 59)),
      );

      final commSnap = await _db
          .collection('users')
          .doc(uid)
          .collection('commission_history')
          .where('timestamp', isGreaterThanOrEqualTo: start)
          .where('timestamp', isLessThanOrEqualTo: end)
          .get();

      Map<int, double> levelTotal = {};
      Map<int, int> levelCount = {};

      for (var doc in commSnap.docs) {
        final data = doc.data();
        int level = data['level'] ?? 0;
        double amount = (data['amount'] ?? 0.0).toDouble();
        levelTotal[level] = (levelTotal[level] ?? 0) + amount;
        levelCount[level] = (levelCount[level] ?? 0) + 1;
      }

      List<Map<String, dynamic>> breakdown = [];
      for (int lvl in levelTotal.keys.toList()..sort()) {
        breakdown.add({
          'level': lvl,
          'peopleCount': levelCount[lvl] ?? 0,
          'totalCommission': levelTotal[lvl] ?? 0.0,
        });
      }
      levelEarnings.value = breakdown;
    } catch (e) {
      debugPrint("Level earnings error: $e");
    }
  }

  Future<void> fetchStatsForDateRange() async {
    try {
      final Timestamp start = Timestamp.fromDate(startDate.value);
      final Timestamp end = Timestamp.fromDate(
        endDate.value.add(const Duration(hours: 23, minutes: 59)),
      );

      final ordersSnap = await _db
          .collection('orders')
          .where('userId', isEqualTo: uid)
          .where('createdAt', isGreaterThanOrEqualTo: start)
          .where('createdAt', isLessThanOrEqualTo: end)
          .get();

      double sale = 0.0;
      final List<Map<String, dynamic>> fetchedOrders = [];

      for (var doc in ordersSnap.docs) {
        final d = doc.data();
        final status = d['status'] ?? '';
        if (status != 'rejected' && status != 'cancelled') {
          sale += (d['grandTotal'] ?? d['totalAmount'] ?? 0.0).toDouble();
        }

        final raw = Map<String, dynamic>.from(d);
        raw['id'] = doc.id;
        if (raw['createdAt'] is Timestamp) {
          raw['createdAt'] = (raw['createdAt'] as Timestamp).toDate();
        }

        double totalCashback = 0.0;
        final cashbackSnap = await _db
            .collection('users')
            .doc(uid)
            .collection('wallet_history')
            .where('orderId', isEqualTo: doc.id)
            .where('type', isEqualTo: 'cashback')
            .get();
        for (var cbDoc in cashbackSnap.docs) {
          totalCashback += (cbDoc.data()['amount'] ?? 0.0).toDouble();
        }
        raw['cashbackEarned'] = totalCashback;
        raw['paymentMethod'] =
            d['paymentMethod'] ?? d['paymentType'] ?? 'Unknown';

        final items = raw['items'] as List? ?? [];
        for (var item in items) {
          String? productId = item['productId'];
          if (productId != null) {
            final productDoc = await _db
                .collection('products')
                .doc(productId)
                .get();
            if (productDoc.exists) {
              String? img = productDoc.data()?['image'];
              if (img != null && img.isNotEmpty) item['image'] = img;
              if ((item['price'] ?? 0) == 0) {
                item['price'] = productDoc.data()?['price'] ?? 0;
              }
            }
          }
          if ((item['price'] ?? 0) == 0) {
            item['price'] = item['unitPrice'] ?? item['salePrice'] ?? 0;
          }
        }
        fetchedOrders.add(raw);
      }

      fetchedOrders.sort((a, b) {
        final da = a['createdAt'];
        final db = b['createdAt'];
        if (da is DateTime && db is DateTime) return db.compareTo(da);
        return 0;
      });

      ownSaleAmount.value = sale;
      receiptCount.value = ordersSnap.docs.length;
      ordersList.assignAll(fetchedOrders);

      final commSnap = await _db
          .collection('users')
          .doc(uid)
          .collection('commission_history')
          .where('timestamp', isGreaterThanOrEqualTo: start)
          .where('timestamp', isLessThanOrEqualTo: end)
          .get();

      double allEarnings = 0.0;
      double refSalesEst = 0.0;
      for (var doc in commSnap.docs) {
        final d = doc.data();
        final double amt = (d['amount'] ?? 0.0).toDouble();
        allEarnings += amt;
        refSalesEst += (d['baseAmount'] ?? amt) * 10;
      }
      allLevelEarnings.value = allEarnings;
      referralSaleTotal.value = refSalesEst;

      final walletHistSnap = await _db
          .collection('users')
          .doc(uid)
          .collection('wallet_history')
          .where('timestamp', isGreaterThanOrEqualTo: start)
          .where('timestamp', isLessThanOrEqualTo: end)
          .get();

      double cb = 0.0;
      for (var doc in walletHistSnap.docs) {
        final d = doc.data();
        if (d['type'] == 'cashback') {
          cb += (d['amount'] ?? 0.0).toDouble();
        }
      }
      cashbackEarned.value = cb;

      final withdrawSnap = await _db
          .collection('finances')
          .where('userId', isEqualTo: uid)
          .where('type', isEqualTo: 'withdrawal')
          .where('status', isEqualTo: 'approved')
          .where('processedAt', isGreaterThanOrEqualTo: start)
          .where('processedAt', isLessThanOrEqualTo: end)
          .get();

      double wTotal = 0.0;
      for (var doc in withdrawSnap.docs) {
        wTotal += (doc.data()['amountToReceive'] ?? doc.data()['amount'] ?? 0.0)
            .toDouble();
      }
      totalWithdrawn.value = wTotal;
    } catch (e) {
      debugPrint("Stat fetch error: $e");
    }
  }

  Future<void> adjustWallet(
    double amount,
    String reason,
    bool isDeduction,
  ) async {
    try {
      final double finalAmount = isDeduction ? -amount : amount;
      await _db.collection('users').doc(uid).update({
        'walletBalance': FieldValue.increment(finalAmount),
      });
      await _db.collection('users').doc(uid).collection('wallet_history').add({
        'amount': finalAmount,
        'type': isDeduction ? 'admin_deduction' : 'admin_credit',
        'description': 'Admin Adjust: $reason',
        'timestamp': FieldValue.serverTimestamp(),
      });
      final c = customer.value!;
      customer.value = CustomerModel(
        uid: c.uid,
        name: c.name,
        email: c.email,
        phone: c.phone,
        country: c.country,
        address: c.address,
        myReferralCode: c.myReferralCode,
        referralCode: c.referralCode,
        faceImage: c.faceImage,
        cnicNumber: c.cnicNumber,
        walletBalance: c.walletBalance + finalAmount,
        shoppingWalletBalance: c.shoppingWalletBalance,
        totalPoints: c.totalPoints,
        totalCashbackEarned: c.totalCashbackEarned,
        membershipStatus: c.membershipStatus,
        isMLMActive: c.isMLMActive,
        createdAt: c.createdAt,
      );
      Get.back();
      Get.snackbar(
        "Success",
        "Wallet adjusted successfully",
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar(
        "Error",
        "Failed to adjust wallet: $e",
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  Future<void> sendDirectMessage(
    String title,
    String body,
    String base64Image,
  ) async {
    try {
      await _db.collection('users').doc(uid).collection('notifications').add({
        'title': title,
        'body': body,
        'type': 'admin_message',
        'isRead': false,
        'image': base64Image,
        'timestamp': FieldValue.serverTimestamp(),
      });
      Get.back();
      Get.snackbar(
        "Sent",
        "Message sent to customer.",
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar(
        "Error",
        "Failed to send: $e",
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }
}
