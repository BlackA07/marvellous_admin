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

  // Rank Percentages
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

  void loadData() => _initializeData();

  Future<void> _initializeData() async {
    try {
      isLoading(true);

      var settingsDoc = await _db
          .collection('admin_settings')
          .doc('mlm_variables')
          .get();

      if (settingsDoc.exists) {
        var settingsMap = settingsDoc.data()!;
        var settings = MLMGlobalSettings.fromMap(settingsMap);
        globalSettings.value = settings;

        cashbackPercent.value = (settingsMap['cashbackPercent'] ?? 0.0)
            .toDouble();
        isCashbackEnabled.value = settingsMap['isCashbackEnabled'] ?? true;
        totalDistAmount.value = (settingsMap['totalDistAmount'] ?? 0.0)
            .toDouble();
        totalDistAmountController.text = totalDistAmount.value.toStringAsFixed(
          0,
        );
      }

      var levels = await _repository.getCommissionLevels();
      if (levels.isNotEmpty) {
        for (var lvl in levels) {
          lvl.amount = (lvl.percentage * totalDistAmount.value) / 100;
        }
        commissionLevels.assignAll(levels);
      }

      levelCountInputController.text = commissionLevels.length.toString();

      await loadMLMTree();
    } catch (e) {
      print("ERROR LOADING DATA: $e");
    } finally {
      isLoading(false);
    }
  }

  // ==========================================
  // TREE LOADING - SHOWS LEVEL 0, 1, 2
  // ==========================================
  Future<void> loadMLMTree() async {
    try {
      // Find root user
      QuerySnapshot rootQuery = await _db
          .collection('users')
          .where('myReferralCode', isEqualTo: 'BOSS')
          .limit(1)
          .get();

      if (rootQuery.docs.isEmpty) {
        rootQuery = await _db
            .collection('users')
            .where('isAdmin', isEqualTo: true)
            .limit(1)
            .get();
      }

      if (rootQuery.docs.isNotEmpty) {
        var rootDoc = rootQuery.docs.first;
        var rootData = rootDoc.data() as Map<String, dynamic>;

        rootNode.value = await _buildTreeRecursive(
          uid: rootDoc.id,
          name: rootData['username'] ?? rootData['name'] ?? 'Admin',
          image: rootData['faceImage'] ?? '',
          referralCode: rootData['myReferralCode'] ?? '',
          currentLevel: 0,
          isMLMActive: rootData['isMLMActive'] ?? true,
          visitedIds: {},
        );
      }
    } catch (e) {
      print("Error loading MLM tree: $e");
    }
  }

  Future<MLMNode> _buildTreeRecursive({
    required String uid,
    required String name,
    required String image,
    required String referralCode,
    required int currentLevel,
    required bool isMLMActive,
    required Set<String> visitedIds,
  }) async {
    // Prevent infinite loops
    if (visitedIds.contains(uid)) {
      return _emptyNode(uid, name, currentLevel);
    }
    visitedIds.add(uid);

    List<MLMNode> children = [];
    int totalMembers = 0;
    int paidMembers = 0;

    // Show children only if MLM active AND currentLevel < 3
    // This means we'll show: Level 0 (root), Level 1, Level 2
    // Level 3+ will only show summary
    if (isMLMActive && currentLevel < 3 && referralCode.isNotEmpty) {
      // Get direct referrals (max 7)
      QuerySnapshot recruits = await _db
          .collection('users')
          .where('referralCode', isEqualTo: referralCode)
          .orderBy('createdAt', descending: false)
          .limit(7)
          .get();

      for (var doc in recruits.docs) {
        var data = doc.data() as Map<String, dynamic>;

        MLMNode childNode = await _buildTreeRecursive(
          uid: doc.id,
          name: data['username'] ?? data['name'] ?? 'User',
          image: data['faceImage'] ?? '',
          referralCode: data['myReferralCode'] ?? '',
          currentLevel: currentLevel + 1,
          isMLMActive: data['isMLMActive'] ?? true,
          visitedIds: Set.from(visitedIds),
        );

        children.add(childNode);

        // Count totals recursively
        totalMembers += 1 + childNode.totalMembers;
        bool childPaid = data.containsKey('hasPaidFee')
            ? data['hasPaidFee'] == true
            : false;
        paidMembers += (childPaid ? 1 : 0) + childNode.paidMembers;
      }
    } else if (referralCode.isNotEmpty) {
      // For level 3+, just count downline
      totalMembers = await _countAllDownline(referralCode);
      paidMembers = await _countPaidDownline(referralCode);
    }

    // Get user data
    DocumentSnapshot userDoc = await _db.collection('users').doc(uid).get();
    Map<String, dynamic> userData = userDoc.exists
        ? userDoc.data() as Map<String, dynamic>
        : {};

    return MLMNode(
      uid: uid,
      name: name,
      image: image,
      myReferralCode: referralCode,
      level: currentLevel,
      isMLMActive: isMLMActive,
      hasPaidFee: userData.containsKey('hasPaidFee')
          ? userData['hasPaidFee'] == true
          : false,
      rank: userData['rank'] ?? 'bronze',
      totalCommissionEarned: (userData['walletBalance'] ?? 0.0).toDouble(),
      children: children,
      totalMembers: totalMembers,
      paidMembers: paidMembers,
      remainingSlots: 7 - children.length,
    );
  }

  MLMNode _emptyNode(String id, String n, int l) => MLMNode(
    uid: id,
    name: n,
    image: '',
    myReferralCode: '',
    level: l,
    isMLMActive: false,
    hasPaidFee: false,
    rank: 'bronze',
    totalCommissionEarned: 0,
    children: [],
  );

  Future<int> _countAllDownline(String refCode) async {
    if (refCode.isEmpty) return 0;
    QuerySnapshot snap = await _db
        .collection('users')
        .where('referralCode', isEqualTo: refCode)
        .get();
    int count = snap.docs.length;
    for (var doc in snap.docs) {
      count += await _countAllDownline(
        (doc.data() as Map)['myReferralCode'] ?? '',
      );
    }
    return count;
  }

  Future<int> _countPaidDownline(String refCode) async {
    if (refCode.isEmpty) return 0;
    QuerySnapshot snap = await _db
        .collection('users')
        .where('referralCode', isEqualTo: refCode)
        .get();
    int count = 0;
    for (var doc in snap.docs) {
      Map data = doc.data() as Map;
      bool paid = data.containsKey('hasPaidFee')
          ? data['hasPaidFee'] == true
          : false;
      if (paid) count++;
      count += await _countPaidDownline(data['myReferralCode'] ?? '');
    }
    return count;
  }

  // ==========================================
  // AUTO-PLACEMENT FUNCTION
  // Finds first available slot in tree
  // ==========================================
  Future<String> findAvailableParent(String rootReferralCode) async {
    try {
      // BFS (Breadth-First Search) to find first available slot
      List<String> queue = [rootReferralCode];
      Set<String> visited = {};

      while (queue.isNotEmpty) {
        String currentCode = queue.removeAt(0);

        if (visited.contains(currentCode)) continue;
        visited.add(currentCode);

        // Check how many direct children this user has
        QuerySnapshot children = await _db
            .collection('users')
            .where('referralCode', isEqualTo: currentCode)
            .get();

        if (children.docs.length < 7) {
          // Found available slot!
          return currentCode;
        }

        // Add children to queue for next level search
        for (var child in children.docs) {
          var childData = child.data() as Map<String, dynamic>;
          String childCode = childData['myReferralCode'] ?? '';
          if (childCode.isNotEmpty) {
            queue.add(childCode);
          }
        }
      }

      // If no slot found (shouldn't happen), return root
      return rootReferralCode;
    } catch (e) {
      print("Error finding available parent: $e");
      return rootReferralCode;
    }
  }

  // ==========================================
  // COMMISSION SETUP METHODS
  // ==========================================
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

      await _db.collection('admin_settings').doc('mlm_variables').set({
        'cashbackPercent': cashbackPercent.value,
        'isCashbackEnabled': isCashbackEnabled.value,
        'totalDistAmount': totalDistAmount.value,
        'totalLevels': commissionLevels.length,
      }, SetOptions(merge: true));

      Get.snackbar(
        "Success",
        "Settings saved!",
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
      _initializeData();
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
