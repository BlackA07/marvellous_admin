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
  double _paidFee = 0.0;

  // Dates
  var startDate = DateTime(DateTime.now().year, DateTime.now().month, 1).obs;
  var endDate = DateTime(DateTime.now().year, DateTime.now().month + 1, 0).obs;
  var isAllTime = false.obs;

  // Stats
  var ownSaleAmount = 0.0.obs;
  var receiptCount = 0.obs;
  var referralSaleTotal = 0.0.obs;
  var allLevelEarnings = 0.0.obs;
  var cashbackEarned = 0.0.obs;
  var totalWithdrawn = 0.0.obs;

  // Profile extras
  var downlineCount = 0.obs;
  var directActiveCount = 0.obs;
  var totalActiveCount = 0.obs;
  var paidStatus = "".obs;
  var remainingFee = 0.0.obs;
  var membershipStatus = "".obs;
  var uplineCode = "".obs;

  // Level-wise earnings
  var levelEarnings = <Map<String, dynamic>>[].obs;
  var directReferralCount = 0.obs;

  var directMembersList = <Map<String, dynamic>>[].obs;
  var otherMembersList = <Map<String, dynamic>>[].obs;

  var networkLevelBreakdown = <Map<String, dynamic>>[].obs;
  var ordersList = <Map<String, dynamic>>[].obs;

  // Points config from Firestore
  double _profitPerPoint = 199.0;
  bool showDecimals = false;

  CustomerDetailController({required this.uid});

  @override
  void onInit() {
    super.onInit();
    _setCurrentMonthRange();
    loadAllData();
  }

  void _setCurrentMonthRange() {
    final now = DateTime.now();
    startDate.value = DateTime(now.year, now.month, 1);
    endDate.value = DateTime(now.year, now.month + 1, 0);
    isAllTime.value = false;
  }

  void setAllTime() {
    isAllTime.value = true;
    startDate.value = DateTime(2020, 1, 1);
    endDate.value = DateTime(2100, 12, 31);
    fetchStatsForDateRange();
    fetchLevelEarnings();
  }

  void setCurrentMonth() {
    _setCurrentMonthRange();
    isAllTime.value = false;
    fetchStatsForDateRange();
    fetchLevelEarnings();
  }

  Future<void> loadAllData() async {
    isLoading(true);
    await _fetchPointsConfig();
    await _fetchCustomerData();
    await fetchStatsForDateRange();
    await _loadMLMTree();
    await _fetchProfileExtras();
    await fetchLevelEarnings();
    isLoading(false);
  }

  Future<void> _fetchPointsConfig() async {
    try {
      final doc = await _db
          .collection('admin_settings')
          .doc('global_config')
          .get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        _profitPerPoint = (data['profitPerPoint'] ?? 199.0).toDouble();
        showDecimals = data['showDecimals'] ?? false;
      }
    } catch (e) {
      debugPrint("Points config fetch error: $e");
    }
  }

  // ✅ Customer App Wali EXACT Points Logic
  Map<String, dynamic> getOrderPointsData(Map<String, dynamic> order) {
    double grossProfit =
        double.tryParse(order['grossProfit']?.toString() ?? '0') ?? 0.0;
    double ppp = _profitPerPoint > 0 ? _profitPerPoint : 199.0;
    double totalPoints = grossProfit > 0 ? grossProfit / ppp : 0.0;

    List items = order['items'] ?? [];
    double totalSale = 0.0;
    for (var item in items) {
      double sp =
          double.tryParse(
            item['salePrice']?.toString() ?? item['price']?.toString() ?? '0',
          ) ??
          0.0;
      int qty = int.tryParse(item['quantity']?.toString() ?? '1') ?? 1;
      totalSale += sp * qty;
    }

    List<double> itemPts = [];
    for (var item in items) {
      double sp =
          double.tryParse(
            item['salePrice']?.toString() ?? item['price']?.toString() ?? '0',
          ) ??
          0.0;
      int qty = int.tryParse(item['quantity']?.toString() ?? '1') ?? 1;
      double itemSale = sp * qty;

      double itemP = 0.0;
      if (totalSale > 0 && itemSale > 0) {
        itemP = (itemSale / totalSale) * totalPoints;
      }
      itemPts.add(itemP);
    }

    return {'grandTotalPoints': totalPoints, 'itemPoints': itemPts};
  }

  String formatPoints(double points) {
    if (showDecimals) return points.toStringAsFixed(2);
    return points.toInt().toString();
  }

  Future<void> _fetchCustomerData() async {
    try {
      var doc = await _db.collection('users').doc(uid).get();
      if (doc.exists) {
        var data = doc.data() as Map<String, dynamic>;

        // ✅ FIX: Image Fetching Logic from Subcollection for Detail Screen
        String userImage = data['faceImage'] ?? '';
        if (userImage.isEmpty) {
          try {
            var imgDoc = await _db
                .collection('users')
                .doc(uid)
                .collection('profile_data')
                .doc('image')
                .get();
            if (imgDoc.exists && imgDoc.data() != null) {
              userImage = imgDoc.data()!['faceImage'] ?? '';
            }
          } catch (_) {}
        }
        // Override faceImage in data so the model gets the correct image
        data['faceImage'] = userImage;

        customer.value = CustomerModel.fromMap(data, doc.id);
        _paidFee = (data['paidFees'] ?? 0.0).toDouble();
      }
    } catch (e) {
      Get.snackbar("Error", "Failed to load user info");
    }
  }

  Future<void> _fetchProfileExtras() async {
    if (customer.value == null) return;
    try {
      uplineCode.value =
          customer.value!.referralCode == "null" ||
              customer.value!.referralCode.isEmpty
          ? "Top / Direct"
          : customer.value!.referralCode;

      membershipStatus.value = customer.value!.membershipStatus ?? "pending";

      double requiredFee = 15000;
      double paidFee = 0.0;

      if (membershipStatus.value.toLowerCase() == "approved") {
        paidFee = requiredFee;
      } else {
        paidFee = _paidFee;
      }

      paidStatus.value = paidFee >= requiredFee
          ? "Paid"
          : paidFee > 0
          ? "Partial (Rs. ${paidFee.toStringAsFixed(0)})"
          : "Unpaid";
      remainingFee.value = (requiredFee - paidFee).clamp(0, double.infinity);

      final String myCode = customer.value!.myReferralCode;

      final directByReferrerSnap = await _db
          .collection('users')
          .where('mlmReferrerUid', isEqualTo: uid)
          .get();

      int directActive = 0;
      List<Map<String, dynamic>> directList = [];

      final commSnap = await _db
          .collection('users')
          .doc(uid)
          .collection('commission_history')
          .where('type', isEqualTo: 'direct_sale_bonus')
          .get();

      Map<String, double> directCommMap = {};
      for (var doc in commSnap.docs) {
        final d = doc.data() as Map<String, dynamic>;
        String fromUid = d['fromUid'] ?? '';
        double amt = (d['amount'] ?? 0.0).toDouble();
        if (fromUid.isNotEmpty) {
          directCommMap[fromUid] = (directCommMap[fromUid] ?? 0.0) + amt;
        }
      }

      for (var doc in directByReferrerSnap.docs) {
        final data = doc.data() as Map<String, dynamic>;
        if (data['isMLMActive'] == true) {
          directActive++;
          directList.add({
            'uid': doc.id,
            'name': data['name'] ?? data['username'] ?? 'User',
            'image': data['faceImage'] ?? '',
            'amount': directCommMap[doc.id] ?? 0.0,
            'isMLMActive': true,
          });
        }
      }

      if (directActive == 0 && myCode.isNotEmpty) {
        final directByCodeSnap = await _db
            .collection('users')
            .where('referralCode', isEqualTo: myCode)
            .get();

        for (var doc in directByCodeSnap.docs) {
          final data = doc.data() as Map<String, dynamic>;
          if (data['isMLMActive'] == true) {
            directActive++;
            directList.add({
              'uid': doc.id,
              'name': data['name'] ?? data['username'] ?? 'User',
              'image': data['faceImage'] ?? '',
              'amount': directCommMap[doc.id] ?? 0.0,
              'isMLMActive': true,
            });
          }
        }
      }

      directList.sort(
        (a, b) => (b['amount'] as double).compareTo(a['amount'] as double),
      );

      directActiveCount.value = directActive;
      directReferralCount.value = directActive;
      directMembersList.assignAll(directList);
    } catch (e) {
      debugPrint("Profile extras error: $e");
    }
  }

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
        parentUid: '',
        referrerUid: '',
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

    try {
      final downlineSnap = await _db
          .collection('users')
          .doc(nodeUid)
          .collection('mlm_downline')
          .get();

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

          if (childData['isMLMActive'] != true) continue;

          final childPoints = (childData['totalPoints'] ?? 0.0).toDouble();
          final childComm = (childData['totalCashbackEarned'] ?? 0.0)
              .toDouble();
          final childRank = _calcRank(childPoints);
          final childReferralCode = childData['referralCode'] ?? '';
          final childParentUid = childData['mlmParentUid'] ?? '';
          final childReferrerUid = childData['mlmReferrerUid'] ?? '';
          final childMyCode = childData['myReferralCode'] ?? '';

          final bool isDirectReferral =
              childReferrerUid == rootUid ||
              childReferralCode == customer.value!.myReferralCode;

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
      totalMembers: children.length,
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

  // ✅ FIX: Exact BFS mapping for absolute level/depth accuracy
  Future<void> fetchLevelEarnings() async {
    try {
      // Step 1: Run BFS from root user's downline to map exact depth
      QuerySnapshot downlineSnap = await _db
          .collection('users')
          .doc(uid)
          .collection('mlm_downline')
          .get();
      Map<int, int> depthCounts = {};

      for (var doc in downlineSnap.docs) {
        int depth = (doc.data() as Map<String, dynamic>)['level'] ?? 1;
        depthCounts[depth] = (depthCounts[depth] ?? 0) + 1;
      }

      depthCounts.clear();
      List<Map<String, dynamic>> queue = [
        {'uid': uid, 'depth': 0},
      ];
      Set<String> visitedNodes = {uid};
      Map<String, int> uidToExactDepth = {};

      while (queue.isNotEmpty) {
        var current = queue.removeAt(0);
        String cUid = current['uid'];
        int cDepth = current['depth'] as int;

        uidToExactDepth[cUid] = cDepth;

        if (cDepth > 0) {
          depthCounts[cDepth] = (depthCounts[cDepth] ?? 0) + 1;
        }

        if (cDepth < 13) {
          try {
            QuerySnapshot snap = await _db
                .collection('users')
                .doc(cUid)
                .collection('mlm_downline')
                .get();
            for (var doc in snap.docs) {
              if (!visitedNodes.contains(doc.id)) {
                visitedNodes.add(doc.id);
                queue.add({'uid': doc.id, 'depth': cDepth + 1});
              }
            }
          } catch (_) {}
        }
      }

      // Step 2: Fetch Commission History
      Query commQuery = _db
          .collection('users')
          .doc(uid)
          .collection('commission_history')
          .where(
            'type',
            whereIn: ['downline_purchase', 'direct_sale_bonus', 'commission'],
          );

      if (!isAllTime.value) {
        final start = Timestamp.fromDate(startDate.value);
        final end = Timestamp.fromDate(
          endDate.value.add(const Duration(hours: 23, minutes: 59)),
        );
        commQuery = commQuery
            .where('timestamp', isGreaterThanOrEqualTo: start)
            .where('timestamp', isLessThanOrEqualTo: end);
      }

      final commSnap = await commQuery.get();
      Map<int, double> depthCommissions = {};
      Map<String, Map<String, dynamic>> memberDetailMap = {};

      for (var doc in commSnap.docs) {
        var data = doc.data() as Map<String, dynamic>;
        int cLevel = data['level'] ?? 2;
        String fromUid = data['fromUid'] ?? doc.id;
        String fromUser = data['fromUser'] ?? 'Unknown';
        double amount = (data['amount'] ?? 0.0).toDouble();

        // Cross-reference with BFS depth
        int depth =
            uidToExactDepth[fromUid] ??
            data['depth'] ??
            (data['type'] == 'direct_sale_bonus' ? 1 : (cLevel - 1));

        if (depth == 0) continue;

        depthCommissions[depth] = (depthCommissions[depth] ?? 0.0) + amount;

        if (fromUid.isNotEmpty && fromUid != doc.id) {
          if (memberDetailMap.containsKey(fromUid)) {
            memberDetailMap[fromUid]!['amount'] += amount;
          } else {
            memberDetailMap[fromUid] = {
              'uid': fromUid,
              'name': fromUser,
              'image': '',
              'amount': amount,
              'level': depth,
            };
          }
        }
      }

      // Assemble final level array
      List<Map<String, dynamic>> breakdown = [];
      for (int i = 1; i <= 13; i++) {
        int filled = depthCounts[i] ?? 0;
        double commission = depthCommissions[i] ?? 0.0;

        if (filled > 0 || commission > 0) {
          breakdown.add({
            'level': i,
            'peopleCount': filled,
            'totalCommission': commission,
          });
        }
      }
      levelEarnings.value = breakdown;

      // Fetch images
      final uidsToFetch = memberDetailMap.keys.toList();
      for (int i = 0; i < uidsToFetch.length; i += 10) {
        final batch = uidsToFetch.skip(i).take(10).toList();
        for (var mUid in batch) {
          try {
            final mDoc = await _db.collection('users').doc(mUid).get();
            if (mDoc.exists) {
              final mData = mDoc.data() as Map<String, dynamic>;
              memberDetailMap[mUid]!['image'] = mData['faceImage'] ?? '';
              memberDetailMap[mUid]!['name'] =
                  mData['name'] ??
                  mData['username'] ??
                  memberDetailMap[mUid]!['name'];
            }
          } catch (_) {}
        }
      }

      // Populate Other Members (Level 2+ ONLY based on exact depth)
      List<Map<String, dynamic>> otherList = [];
      for (var entry in memberDetailMap.values) {
        // ✅ FIX: Check karen k kahin ye user already Direct list mein to nahi hai?
        bool isAlreadyDirect = directMembersList.any(
          (d) => d['uid'] == entry['uid'],
        );

        // Agar direct nahi hai, tabhi Other network mein daalo
        if (!isAlreadyDirect && (entry['level'] as int) > 1) {
          otherList.add(Map<String, dynamic>.from(entry));
        }
      }
      otherList.sort(
        (a, b) => (b['amount'] as double).compareTo(a['amount'] as double),
      );
      otherMembersList.assignAll(otherList);
    } catch (e) {
      debugPrint("Level earnings error: $e");
    }
  }

  Future<void> fetchStatsForDateRange() async {
    try {
      Query ordersQuery = _db
          .collection('orders')
          .where('userId', isEqualTo: uid);

      if (!isAllTime.value) {
        final Timestamp start = Timestamp.fromDate(startDate.value);
        final Timestamp end = Timestamp.fromDate(
          endDate.value.add(const Duration(hours: 23, minutes: 59)),
        );
        ordersQuery = ordersQuery
            .where('createdAt', isGreaterThanOrEqualTo: start)
            .where('createdAt', isLessThanOrEqualTo: end);
      }

      final ordersSnap = await ordersQuery.get();

      double sale = 0.0;
      final List<Map<String, dynamic>> fetchedOrders = [];

      for (var doc in ordersSnap.docs) {
        final d = doc.data() as Map<String, dynamic>;
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

      Query commQuery = _db
          .collection('users')
          .doc(uid)
          .collection('commission_history');

      if (!isAllTime.value) {
        final start = Timestamp.fromDate(startDate.value);
        final end = Timestamp.fromDate(
          endDate.value.add(const Duration(hours: 23, minutes: 59)),
        );
        commQuery = commQuery
            .where('timestamp', isGreaterThanOrEqualTo: start)
            .where('timestamp', isLessThanOrEqualTo: end);
      }

      final commSnap = await commQuery.get();

      double allEarnings = 0.0;
      double refSalesEst = 0.0;
      for (var doc in commSnap.docs) {
        final d = doc.data() as Map<String, dynamic>;
        final String type = d['type'] ?? '';
        if (type == 'direct_sale_bonus' ||
            type == 'commission' ||
            type == 'downline_purchase') {
          final double amt = (d['amount'] ?? 0.0).toDouble();
          allEarnings += amt;
          refSalesEst += (d['baseAmount'] ?? amt) * 10;
        }
      }
      allLevelEarnings.value = allEarnings;
      referralSaleTotal.value = refSalesEst;

      Query walletQuery = _db
          .collection('users')
          .doc(uid)
          .collection('wallet_history');

      if (!isAllTime.value) {
        final start = Timestamp.fromDate(startDate.value);
        final end = Timestamp.fromDate(
          endDate.value.add(const Duration(hours: 23, minutes: 59)),
        );
        walletQuery = walletQuery
            .where('timestamp', isGreaterThanOrEqualTo: start)
            .where('timestamp', isLessThanOrEqualTo: end);
      }

      final walletHistSnap = await walletQuery.get();

      double cb = 0.0;
      for (var doc in walletHistSnap.docs) {
        final d = doc.data() as Map<String, dynamic>;
        if (d['type'] == 'cashback') {
          cb += (d['amount'] ?? 0.0).toDouble();
        }
      }
      cashbackEarned.value = cb;

      Query withdrawQuery = _db
          .collection('finances')
          .where('userId', isEqualTo: uid)
          .where('type', isEqualTo: 'withdrawal')
          .where('status', isEqualTo: 'approved');

      if (!isAllTime.value) {
        final start = Timestamp.fromDate(startDate.value);
        final end = Timestamp.fromDate(
          endDate.value.add(const Duration(hours: 23, minutes: 59)),
        );
        withdrawQuery = withdrawQuery
            .where('processedAt', isGreaterThanOrEqualTo: start)
            .where('processedAt', isLessThanOrEqualTo: end);
      }

      final withdrawSnap = await withdrawQuery.get();

      double wTotal = 0.0;
      for (var doc in withdrawSnap.docs) {
        final data = doc.data() as Map<String, dynamic>?;
        if (data == null) continue;
        wTotal += (data['amountToReceive'] ?? data['amount'] ?? 0.0).toDouble();
      }
      totalWithdrawn.value = wTotal;
    } catch (e) {
      debugPrint("Stat fetch error: $e");
    }
  }

  // Path: lib/features/finances/controller/customer_detail_controller.dart
  // (Baaki poora code same rakhein, sirf adjustWallet method ko is se replace karein)

  Future<void> adjustWallet(
    double amount,
    String reason,
    bool isDeduction,
    String? selectedBankId,
    String? selectedBankName,
  ) async {
    try {
      final double finalAmount = isDeduction ? -amount : amount;

      // 1. User Wallet Update
      await _db.collection('users').doc(uid).update({
        'walletBalance': FieldValue.increment(finalAmount),
      });

      // 2. User Wallet History Update
      await _db.collection('users').doc(uid).collection('wallet_history').add({
        'amount': finalAmount,
        'type': isDeduction ? 'admin_deduction' : 'admin_credit',
        'description': 'Admin Adjust: $reason',
        'timestamp': FieldValue.serverTimestamp(),
      });

      // 3. Bank and Master Ledger Logic
      if (!isDeduction) {
        // ✅ FIX: Agar ADD kar rahe hain (Credit / Reward)
        if (selectedBankId != null && selectedBankId.isNotEmpty) {
          await _db
              .collection('company_finances')
              .doc('main_finances')
              .collection('banks')
              .doc(selectedBankId)
              .update({'balance': FieldValue.increment(-amount)});

          await _db
              .collection('company_finances')
              .doc('main_finances')
              .collection('banks')
              .doc(selectedBankId)
              .collection('transactions')
              .add({
                'amount': -amount,
                'type': 'admin_wallet_credit',
                'description': 'Admin credited to user wallet: $reason',
                'userId': uid,
                'timestamp': FieldValue.serverTimestamp(),
              });
        }

        // ✅ FIX: Add to MASTER LEDGER as OUT (Kyunke admin ki taraf se paise customer ko ja rahe hain)
        await _db.collection('admin_ledger_transactions').add({
          'type': 'out',
          'category': 'customer_reward',
          'amount': amount,
          'paymentMethod': selectedBankId != null && selectedBankId.isNotEmpty
              ? 'online'
              : 'main_wallet',
          'bankId': selectedBankId,
          'bankName': selectedBankName,
          'description': 'Admin Wallet Credit: $reason',
          'linkedUserId': uid,
          'linkedUserName': customer.value?.name ?? '',
          'linkedUserPhone': customer.value?.phone ?? '',
          'linkedUserEmail': customer.value?.email ?? '',
          'createdBy': 'admin',
          'date': FieldValue.serverTimestamp(),
          'createdAt': FieldValue.serverTimestamp(),
        });

        // ✅ FIX: Add to REWARDS HISTORY (Taake rewards tab mein show ho)
        await _db.collection('admin_rewards').add({
          'userId': uid,
          'userName': customer.value?.name ?? 'Unknown',
          'userPhone': customer.value?.phone ?? '',
          'userEmail': customer.value?.email ?? '',
          'amount': amount,
          'bankId': selectedBankId ?? '',
          'bankName': selectedBankName ?? 'Main Wallet',
          'note': 'Wallet Credit: $reason',
          'date': FieldValue.serverTimestamp(),
          'createdAt': FieldValue.serverTimestamp(),
        });
      } else if (isDeduction) {
        // Agar MINUS kar rahe hain (Deduction / Fine)
        await _db.collection('company_finances').doc('balance').set({
          'totalCompanyBalance': FieldValue.increment(amount),
        }, SetOptions(merge: true));

        await _db
            .collection('company_finances')
            .doc('balance')
            .collection('history')
            .add({
              'amount': amount,
              'source': 'Admin Deduction from user wallet',
              'userId': uid,
              'reason': reason,
              'timestamp': FieldValue.serverTimestamp(),
            });

        // Master Ledger mein IN
        await _db.collection('admin_ledger_transactions').add({
          'type': 'in',
          'category': 'fine',
          'amount': amount,
          'paymentMethod': 'main_wallet',
          'description': 'Admin Fine: $reason',
          'linkedUserId': uid,
          'linkedUserName': customer.value?.name ?? '',
          'linkedUserPhone': customer.value?.phone ?? '',
          'linkedUserEmail': customer.value?.email ?? '',
          'createdBy': 'admin',
          'date': FieldValue.serverTimestamp(),
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      // 4. Send Notification
      await _db.collection('users').doc(uid).collection('notifications').add({
        'title': isDeduction ? 'Wallet Deduction 💳' : 'Wallet Credit 💰',
        'body': isDeduction
            ? 'Rs. ${amount.toStringAsFixed(0)} has been deducted from your wallet. Reason: $reason'
            : 'Rs. ${amount.toStringAsFixed(0)} has been added to your wallet${selectedBankName != null ? ' from $selectedBankName' : ''}. Reason: $reason',
        'type': 'wallet_adjustment',
        'isRead': false,
        'timestamp': FieldValue.serverTimestamp(),
      });

      final c = customer.value!;
      customer.value = c.copyWith(walletBalance: c.walletBalance + finalAmount);

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

  Future<List<Map<String, dynamic>>> fetchMemberCommissionHistory(
    String memberUid,
  ) async {
    try {
      final snap = await _db
          .collection('users')
          .doc(uid)
          .collection('commission_history')
          .where('fromUid', isEqualTo: memberUid)
          .orderBy('timestamp', descending: true)
          .get();

      return snap.docs.map((doc) {
        final d = Map<String, dynamic>.from(doc.data());
        if (d['timestamp'] is Timestamp) {
          d['timestamp'] = (d['timestamp'] as Timestamp).toDate();
        }
        return d;
      }).toList();
    } catch (e) {
      debugPrint("Member commission history error: $e");
      return [];
    }
  }
}
