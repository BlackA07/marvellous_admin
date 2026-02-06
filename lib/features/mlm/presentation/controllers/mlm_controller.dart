import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../data/models/mlm_models.dart';
import '../../data/models/mlm_global_settings_model.dart';
import '../../data/repositories/mlm_repository.dart';

class MLMController extends GetxController {
  final MLMRepository _repository = MLMRepository();
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  var isLoading = false.obs;
  var commissionLevels = <CommissionLevel>[].obs;
  var globalSettings = Rxn<MLMGlobalSettings>();

  var cashbackPercent = 0.0.obs;
  var isCashbackEnabled = true.obs;
  var totalDistAmount = 0.0.obs;

  var rootNode = Rxn<MLMNode>();
  final TextEditingController levelCountInputController =
      TextEditingController();
  final TextEditingController totalDistAmountController =
      TextEditingController();

  // Rank Percentage Constants
  double get bronzePercent => 25.0;
  double get silverPercent => 50.0;
  double get goldPercent => 75.0;
  double get diamondPercent => 100.0;

  double get totalCommission {
    double cashback = isCashbackEnabled.value ? cashbackPercent.value : 0.0;
    double levelsTotal = commissionLevels.fold(
      0.0,
      (sum, item) => sum + item.percentage,
    );
    return double.parse((cashback + levelsTotal).toStringAsFixed(4));
  }

  double get usedAmount {
    double cbAmt = isCashbackEnabled.value
        ? (cashbackPercent.value * totalDistAmount.value) / 100
        : 0.0;
    double lvAmt = commissionLevels.fold(0.0, (sum, item) {
      return sum + ((item.percentage * totalDistAmount.value) / 100);
    });
    return cbAmt + lvAmt;
  }

  @override
  void onInit() {
    super.onInit();
    loadData();
  }

  Future<void> loadData() async {
    try {
      isLoading(true);

      var settingsDoc = await FirebaseFirestore.instance
          .collection('admin_settings')
          .doc('mlm_variables')
          .get();

      double savedTotalDist = 0.0;
      int savedLevelCount = 11;

      if (settingsDoc.exists) {
        var settingsMap = settingsDoc.data()!;
        var settings = MLMGlobalSettings.fromMap(settingsMap);
        globalSettings.value = settings;

        cashbackPercent.value =
            (settingsMap['cashbackPercent'] ?? settings.cashbackPercent)
                .toDouble();
        isCashbackEnabled.value =
            settingsMap['isCashbackEnabled'] ?? settings.isCashbackEnabled;

        savedTotalDist = (settingsMap['totalDistAmount'] ?? 0.0).toDouble();
        savedLevelCount = (settingsMap['totalLevels'] ?? 11).toInt();

        totalDistAmount.value = savedTotalDist;
        totalDistAmountController.text = savedTotalDist.toStringAsFixed(0);
      } else {
        var defaults = MLMGlobalSettings.defaults();
        globalSettings.value = defaults;
        cashbackPercent.value = defaults.cashbackPercent;
        isCashbackEnabled.value = defaults.isCashbackEnabled;
      }

      var levels = await _repository.getCommissionLevels();

      if (levels.isNotEmpty) {
        for (var lvl in levels) {
          lvl.amount = (lvl.percentage * totalDistAmount.value) / 100;
        }
        commissionLevels.assignAll(levels);
      } else {
        commissionLevels.assignAll([
          CommissionLevel(
            level: 1,
            percentage: 25.0,
            amount: (25.0 * savedTotalDist) / 100,
          ),
          CommissionLevel(
            level: 2,
            percentage: 15.0,
            amount: (15.0 * savedTotalDist) / 100,
          ),
          CommissionLevel(
            level: 3,
            percentage: 10.0,
            amount: (10.0 * savedTotalDist) / 100,
          ),
          for (int i = 4; i <= savedLevelCount; i++)
            CommissionLevel(
              level: i,
              percentage: 3.0,
              amount: (3.0 * savedTotalDist) / 100,
            ),
        ]);
      }

      levelCountInputController.text = commissionLevels.length.toString();

      // Load MLM Tree
      await loadMLMTree();
    } catch (e) {
      print("ERROR LOADING DATA: $e");
    } finally {
      isLoading(false);
      commissionLevels.refresh();
      cashbackPercent.refresh();
    }
  }

  // Load MLM Tree starting from admin/root user
  Future<void> loadMLMTree() async {
    try {
      // Find admin user (you can change this logic based on your needs)
      // Option 1: Find user with isAdmin = true
      QuerySnapshot adminQuery = await _db
          .collection('users')
          .where('isAdmin', isEqualTo: true)
          .limit(1)
          .get();

      String rootUserId;
      DocumentSnapshot rootDoc;

      if (adminQuery.docs.isNotEmpty) {
        rootDoc = adminQuery.docs.first;
        rootUserId = rootDoc.id;
      } else {
        // Option 2: Use specific UID (replace with your admin UID)
        // rootUserId = 'YOUR_ADMIN_UID_HERE';
        // rootDoc = await _db.collection('users').doc(rootUserId).get();

        // Option 3: Find first user with no referralCode (root user)
        QuerySnapshot rootQuery = await _db
            .collection('users')
            .where('referralCode', isEqualTo: '')
            .limit(1)
            .get();

        if (rootQuery.docs.isEmpty) {
          print("No root user found");
          rootNode.value = null;
          return;
        }

        rootDoc = rootQuery.docs.first;
        rootUserId = rootDoc.id;
      }

      if (!rootDoc.exists) {
        print("Root user document does not exist");
        rootNode.value = null;
        return;
      }

      var rootData = rootDoc.data() as Map<String, dynamic>;

      // Build tree recursively with visited IDs
      MLMNode root = await _buildTreeRecursive(
        uid: rootUserId,
        name: rootData['username'] ?? rootData['name'] ?? 'Admin',
        image: rootData['faceImage'] ?? '',
        referralCode: rootData['myReferralCode'] ?? '',
        currentLevel: 0,
        isMLMActive: rootData['isMLMActive'] ?? true,
        visitedIds: {}, // NEW: Track visited IDs to prevent circular reference
      );

      rootNode.value = root;
      print("Admin MLM Tree loaded successfully");
    } catch (e) {
      print("Error loading MLM tree: $e");
      rootNode.value = null;
    }
  }

  // Recursive function to build tree - FIXED with visitedIds
  Future<MLMNode> _buildTreeRecursive({
    required String uid,
    required String name,
    required String image,
    required String referralCode,
    required int currentLevel,
    required bool isMLMActive,
    Set<String> visitedIds = const {}, // NEW: Track visited IDs
  }) async {
    // Prevent circular reference
    if (visitedIds.contains(uid)) {
      print("Circular reference detected for user: $uid");
      return MLMNode(
        uid: uid,
        name: name,
        image: image,
        myReferralCode: referralCode,
        level: currentLevel,
        isMLMActive: isMLMActive,
        hasPaidFee: false,
        rank: 'bronze',
        totalCommissionEarned: 0,
        children: [],
        totalMembers: 0,
        paidMembers: 0,
        remainingSlots: 7,
      );
    }

    // Add current user to visited IDs
    Set<String> newVisitedIds = Set<String>.from(visitedIds);
    newVisitedIds.add(uid);

    List<MLMNode> children = [];
    int totalMembers = 0;
    int paidMembers = 0;
    double totalCommission = 0.0;

    // IMPORTANT CHANGE: Show children for level 0-2 (not just <= 2)
    if (isMLMActive && currentLevel < 3) {
      // Changed from <= 2 to < 3
      try {
        // Find direct referrals
        QuerySnapshot recruits = await _db
            .collection('users')
            .where('referralCode', isEqualTo: referralCode)
            .limit(7) // Limit to 7 children
            .get();

        print(
          "Admin: Found ${recruits.docs.length} recruits for code: $referralCode (Level: $currentLevel)",
        );

        int childCount = 0;
        for (var doc in recruits.docs) {
          if (childCount >= 7) break; // Max 7 children per level

          var childData = doc.data() as Map<String, dynamic>;
          bool childMLMActive = childData['isMLMActive'] ?? false;
          String childReferralCode = childData['myReferralCode'] ?? '';

          // Prevent self-referral and empty codes
          if (childReferralCode.isEmpty || childReferralCode == referralCode) {
            continue;
          }

          MLMNode childNode = await _buildTreeRecursive(
            uid: doc.id,
            name: childData['username'] ?? childData['name'] ?? 'User',
            image: childData['faceImage'] ?? '',
            referralCode: childReferralCode,
            currentLevel: currentLevel + 1,
            isMLMActive: childMLMActive,
            visitedIds: newVisitedIds, // Pass visited IDs
          );

          children.add(childNode);
          childCount++;

          // Count total members recursively (this child + all their downline)
          totalMembers += 1 + childNode.totalMembers;
          paidMembers += childNode.paidMembers;
          if (childNode.hasPaidFee) paidMembers++;

          // Calculate commission from this branch
          totalCommission += childNode.totalCommissionEarned;
        }
      } catch (e) {
        print("Error loading children: $e");
      }
    }
    // Level 3+ ke liye sirf summary dikhao
    else if (isMLMActive && currentLevel >= 3 && referralCode.isNotEmpty) {
      try {
        totalMembers = await _countAllDownline(referralCode);
        paidMembers = await _countPaidDownline(referralCode);
        print(
          "Level $currentLevel summary: total=$totalMembers, paid=$paidMembers",
        );
      } catch (e) {
        print("Error counting downline: $e");
      }
    }

    // Check fee status for current user
    bool hasPaidFee = await _checkFeeStatus(uid);

    // Get user's rank
    String rank = await _getUserRank(uid);

    // Calculate commission earned from this user's purchases
    double ownCommission = await _calculateUserCommission(uid, currentLevel);
    totalCommission += ownCommission;

    // Calculate remaining slots (max 7 per level)
    int remainingSlots = 7 - children.length;

    return MLMNode(
      uid: uid,
      name: name,
      image: image,
      myReferralCode: referralCode,
      level: currentLevel,
      isMLMActive: isMLMActive,
      hasPaidFee: hasPaidFee,
      rank: rank,
      totalCommissionEarned: totalCommission,
      children: children,
      totalMembers: totalMembers,
      paidMembers: paidMembers,
      remainingSlots: remainingSlots,
    );
  }

  // OPTIMIZED: Count all downline members
  Future<int> _countAllDownline(String referralCode) async {
    try {
      if (referralCode.isEmpty) return 0;

      int totalCount = 0;
      List<String> codesToProcess = [referralCode];
      Set<String> processedCodes = {};

      while (codesToProcess.isNotEmpty) {
        String currentCode = codesToProcess.removeAt(0);

        // Avoid processing same code multiple times
        if (processedCodes.contains(currentCode)) continue;
        processedCodes.add(currentCode);

        QuerySnapshot directReferrals = await _db
            .collection('users')
            .where('referralCode', isEqualTo: currentCode)
            .get();

        totalCount += directReferrals.docs.length;

        // Add child referral codes for next level
        for (var doc in directReferrals.docs) {
          var data = doc.data() as Map<String, dynamic>;
          String childCode = data['myReferralCode'] ?? '';
          if (childCode.isNotEmpty && !processedCodes.contains(childCode)) {
            codesToProcess.add(childCode);
          }
        }
      }

      return totalCount;
    } catch (e) {
      print("Error in _countAllDownline: $e");
      return 0;
    }
  }

  // OPTIMIZED: Count paid members in downline
  Future<int> _countPaidDownline(String referralCode) async {
    try {
      if (referralCode.isEmpty) return 0;

      int paidCount = 0;
      List<String> codesToProcess = [referralCode];
      Set<String> processedCodes = {};

      while (codesToProcess.isNotEmpty) {
        String currentCode = codesToProcess.removeAt(0);

        if (processedCodes.contains(currentCode)) continue;
        processedCodes.add(currentCode);

        QuerySnapshot directReferrals = await _db
            .collection('users')
            .where('referralCode', isEqualTo: currentCode)
            .get();

        for (var doc in directReferrals.docs) {
          bool hasPaid = await _checkFeeStatus(doc.id);
          if (hasPaid) paidCount++;

          var data = doc.data() as Map<String, dynamic>;
          String childCode = data['myReferralCode'] ?? '';
          if (childCode.isNotEmpty && !processedCodes.contains(childCode)) {
            codesToProcess.add(childCode);
          }
        }
      }

      return paidCount;
    } catch (e) {
      print("Error in _countPaidDownline: $e");
      return 0;
    }
  }

  // Check if user has paid fee
  Future<bool> _checkFeeStatus(String userId) async {
    try {
      // First check if field exists in user doc
      DocumentSnapshot userDoc = await _db
          .collection('users')
          .doc(userId)
          .get();
      if (userDoc.exists) {
        var userData = userDoc.data() as Map<String, dynamic>;
        if (userData.containsKey('hasPaidFee')) {
          return userData['hasPaidFee'] ?? false;
        }
      }

      // Check fee_requests collection
      QuerySnapshot feeQuery = await _db
          .collection('fee_requests')
          .where('userId', isEqualTo: userId)
          .where('status', isEqualTo: 'approved')
          .limit(1)
          .get();

      bool hasPaid = feeQuery.docs.isNotEmpty;

      // Update user document with fee status for faster future checks
      if (hasPaid) {
        await _db.collection('users').doc(userId).update({'hasPaidFee': true});
      }

      return hasPaid;
    } catch (e) {
      print("Error checking fee status: $e");
      return false;
    }
  }

  // Get user's rank
  Future<String> _getUserRank(String userId) async {
    try {
      DocumentSnapshot userDoc = await _db
          .collection('users')
          .doc(userId)
          .get();
      if (userDoc.exists) {
        var userData = userDoc.data() as Map<String, dynamic>;

        // Check if rank field exists
        if (userData.containsKey('rank')) {
          return userData['rank'] ?? 'bronze';
        }

        // Calculate rank based on downline count (if rank field doesn't exist)
        int downlineCount = userData['totalDownline'] ?? 0;

        if (downlineCount >= 300) {
          return 'diamond';
        } else if (downlineCount >= 200) {
          return 'gold';
        } else if (downlineCount >= 100) {
          return 'silver';
        } else {
          return 'bronze';
        }
      }
      return 'bronze';
    } catch (e) {
      print("Error getting user rank: $e");
      return 'bronze';
    }
  }

  // Calculate commission earned by a user from their upline perspective
  Future<double> _calculateUserCommission(String userId, int userLevel) async {
    try {
      // This calculates how much commission the UPLINE has earned from THIS user
      // Get user's total purchases/orders
      QuerySnapshot orders = await _db
          .collection('orders')
          .where('userId', isEqualTo: userId)
          .where('status', isEqualTo: 'completed') // Only completed orders
          .get();

      if (orders.docs.isEmpty) return 0.0;

      double totalOrderAmount = 0.0;
      for (var order in orders.docs) {
        var orderData = order.data() as Map<String, dynamic>;
        totalOrderAmount += (orderData['totalAmount'] ?? 0).toDouble();
      }

      if (totalOrderAmount == 0) return 0.0;

      // Get MLM distribution percentage
      double mlmDistPercent =
          globalSettings.value?.mlmDistributionPercent ?? 25.0;
      double mlmAmount = (totalOrderAmount * mlmDistPercent) / 100;

      // Get commission percentage for this level
      double levelCommission = 0.0;
      if (userLevel > 0 && userLevel <= commissionLevels.length) {
        levelCommission = commissionLevels[userLevel - 1].percentage;
      }

      // Calculate base commission
      double baseCommission = (mlmAmount * levelCommission) / 100;

      // Get user's rank and fee status
      String userRank = await _getUserRank(userId);
      bool hasPaidFee = await _checkFeeStatus(userId);

      // Apply rank bonus
      double rankBonus = 0.0;
      switch (userRank) {
        case 'bronze':
          rankBonus = bronzePercent;
          break;
        case 'silver':
          rankBonus = silverPercent;
          break;
        case 'gold':
          rankBonus = goldPercent;
          break;
        case 'diamond':
          rankBonus = diamondPercent;
          break;
      }

      // Apply rank bonus to base commission
      double commissionWithRank = baseCommission * (1 + rankBonus / 100);

      // Apply fee bonus (extra 25% if fee paid, but NOT for diamond)
      double finalCommission = commissionWithRank;
      if (hasPaidFee && userRank != 'diamond') {
        finalCommission = commissionWithRank * 1.25;
      }

      return finalCommission;
    } catch (e) {
      print("Error calculating commission: $e");
      return 0.0;
    }
  }

  // Rest of the methods remain the same...
  void updateTotalLevels(String value) {
    int? newCount = int.tryParse(value);
    if (newCount == null || newCount < 1 || newCount > 50) return;
    int current = commissionLevels.length;

    if (newCount > current) {
      for (int i = current; i < newCount; i++) {
        commissionLevels.add(
          CommissionLevel(level: i + 1, percentage: 0, amount: 0),
        );
      }
    } else {
      commissionLevels.removeRange(newCount, current);
    }
    commissionLevels.refresh();
  }

  void updateTotalDistAmount(String value) {
    final v = double.tryParse(value);
    if (v != null && v >= 0) {
      totalDistAmount.value = v;
      for (var lvl in commissionLevels) {
        lvl.amount = (lvl.percentage * v) / 100;
      }
      commissionLevels.refresh();
      cashbackPercent.refresh();
    }
  }

  void updateLevelPercentage(int index, String value) {
    final p = double.tryParse(value) ?? 0.0;
    commissionLevels[index].percentage = p;
    commissionLevels[index].amount = (p * totalDistAmount.value) / 100;
    commissionLevels.refresh();
  }

  void updateLevelByAmount(int index, double amount) {
    if (totalDistAmount.value > 0) {
      commissionLevels[index].amount = amount;
      commissionLevels[index].percentage =
          (amount / totalDistAmount.value) * 100;
      commissionLevels.refresh();
    }
  }

  void toggleCashback(bool val) => isCashbackEnabled.value = val;

  void updateCashbackPercent(String val) =>
      cashbackPercent.value = double.tryParse(val) ?? 0.0;

  void updateCashbackByAmount(double amount) {
    if (totalDistAmount.value > 0) {
      cashbackPercent.value = (amount / totalDistAmount.value) * 100;
    }
  }

  Future<void> saveConfig() async {
    if (totalCommission > 100.0001) {
      Get.snackbar(
        "Error",
        "Total allocation exceeds 100%",
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    try {
      isLoading(true);
      await _repository.saveCommissions(commissionLevels);

      Map<String, dynamic> settingsData = {
        'cashbackPercent': cashbackPercent.value,
        'isCashbackEnabled': isCashbackEnabled.value,
        'totalDistAmount': totalDistAmount.value,
        'totalLevels': commissionLevels.length,
      };

      await FirebaseFirestore.instance
          .collection('admin_settings')
          .doc('mlm_variables')
          .set(settingsData, SetOptions(merge: true));

      Get.snackbar(
        "Success",
        "Settings saved!",
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
      await loadData();
    } catch (e) {
      Get.snackbar(
        "Error",
        "Failed to save: $e",
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoading(false);
    }
  }

  @override
  void onClose() {
    levelCountInputController.dispose();
    totalDistAmountController.dispose();
    super.onClose();
  }
}
