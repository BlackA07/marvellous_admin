import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/mlm_models.dart';

class MLMRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // --- Collection References ---
  CollectionReference get _commissionCollection => _firestore
      .collection('admin_settings')
      .doc('mlm_variables')
      .collection('commission_levels');

  CollectionReference get _usersCollection => _firestore.collection('users');

  // ==========================================
  // 1. Commission Levels Fetch karna
  // ==========================================
  Future<List<CommissionLevel>> getCommissionLevels() async {
    try {
      final snapshot = await _commissionCollection.orderBy('level').get();

      if (snapshot.docs.isEmpty) {
        print("Repository: No commission levels found in Firebase");
        return [];
      }

      List<CommissionLevel> levels = snapshot.docs.map((doc) {
        var data = doc.data() as Map<String, dynamic>;
        return CommissionLevel.fromJson(data);
      }).toList();

      print(
        "Repository: Loaded ${levels.length} commission levels from Firebase",
      );
      return levels;
    } catch (e) {
      print("Error fetching commissions: $e");
      return [];
    }
  }

  // ==========================================
  // 2. Commission Levels Save karna
  // ==========================================
  Future<void> saveCommissions(List<CommissionLevel> levels) async {
    try {
      WriteBatch batch = _firestore.batch();

      for (var item in levels) {
        DocumentReference docRef = _commissionCollection.doc(
          'level_${item.level}',
        );

        Map<String, dynamic> dataToSave = {
          'level': item.level,
          'percentage': item.percentage,
          'amount': item.amount,
        };

        batch.set(docRef, dataToSave);
      }

      await batch.commit();
      print(
        "Repository: ${levels.length} Commission Levels saved to Firebase successfully!",
      );

      for (var lvl in levels) {
        print(
          "Saved Level ${lvl.level}: ${lvl.percentage}% = Rs ${lvl.amount}",
        );
      }
    } catch (e) {
      print("Error saving commissions: $e");
      throw e;
    }
  }

  // ==========================================
  // 3. Tree Data Fetch karna (UPDATED)
  // ==========================================
  Future<MLMNode?> getMLMTree() async {
    try {
      // Root Node dhundo (Admin user with isAdmin = true)
      final adminSnapshot = await _usersCollection
          .where('isAdmin', isEqualTo: true)
          .limit(1)
          .get();

      if (adminSnapshot.docs.isEmpty) {
        print("No Admin/Root user found in database");

        // Alternative: Find user with no referralCode (root user)
        final rootSnapshot = await _usersCollection
            .where('referralCode', isEqualTo: '')
            .limit(1)
            .get();

        if (rootSnapshot.docs.isEmpty) {
          print("No root user found");
          return null;
        }

        final rootDoc = rootSnapshot.docs.first;
        final rootData = rootDoc.data() as Map<String, dynamic>;
        return await _buildNodeRecursively(
          docId: rootDoc.id,
          data: rootData,
          currentLevel: 0,
        );
      }

      final rootDoc = adminSnapshot.docs.first;
      final rootData = rootDoc.data() as Map<String, dynamic>;

      return await _buildNodeRecursively(
        docId: rootDoc.id,
        data: rootData,
        currentLevel: 0,
      );
    } catch (e) {
      print("Error fetching tree: $e");
      return null;
    }
  }

  // ==========================================
  // 4. Recursive Node Builder (UPDATED)
  // ==========================================
  Future<MLMNode> _buildNodeRecursively({
    required String docId,
    required Map<String, dynamic> data,
    required int currentLevel,
  }) async {
    List<MLMNode> childrenNodes = [];
    int totalMembers = 0;
    int paidMembers = 0;
    double totalCommission = 0.0;

    String myReferralCode = data['myReferralCode'] ?? '';
    bool isMLMActive = data['isMLMActive'] ?? false;

    // Only build children if MLM is active and level <= 2 (to show till level 3)
    if (isMLMActive && currentLevel <= 2 && myReferralCode.isNotEmpty) {
      final childrenSnapshot = await _usersCollection
          .where('referralCode', isEqualTo: myReferralCode)
          .limit(7) // Max 7 children
          .get();

      for (var childDoc in childrenSnapshot.docs) {
        var childData = childDoc.data() as Map<String, dynamic>;

        MLMNode childNode = await _buildNodeRecursively(
          docId: childDoc.id,
          data: childData,
          currentLevel: currentLevel + 1,
        );

        childrenNodes.add(childNode);

        // Count totals
        totalMembers += 1 + childNode.totalMembers;
        paidMembers += childNode.paidMembers;
        if (childNode.hasPaidFee) paidMembers++;
        totalCommission += childNode.totalCommissionEarned;
      }
    } else if (isMLMActive && currentLevel >= 3 && myReferralCode.isNotEmpty) {
      // For level 3+, count all downline
      totalMembers = await _countAllDownline(myReferralCode);
      paidMembers = await _countPaidDownline(myReferralCode);
    }

    // Check fee status
    bool hasPaidFee = await _checkFeeStatus(docId);

    // Get rank
    String rank = data['rank'] ?? 'bronze';

    // Get commission earned
    double ownCommission = (data['totalCommissionEarned'] ?? 0).toDouble();
    totalCommission += ownCommission;

    // Calculate remaining slots
    int remainingSlots = 7 - childrenNodes.length;

    return MLMNode(
      uid: docId,
      name: data['username'] ?? data['name'] ?? 'User',
      image: data['faceImage'] ?? '',
      myReferralCode: myReferralCode,
      level: currentLevel,
      isMLMActive: isMLMActive,
      hasPaidFee: hasPaidFee,
      rank: rank,
      totalCommissionEarned: totalCommission,
      children: childrenNodes,
      totalMembers: totalMembers,
      paidMembers: paidMembers,
      remainingSlots: remainingSlots,
    );
  }

  // ==========================================
  // 5. Count All Downline Members
  // ==========================================
  Future<int> _countAllDownline(String referralCode) async {
    try {
      if (referralCode.isEmpty) return 0;

      final directReferrals = await _usersCollection
          .where('referralCode', isEqualTo: referralCode)
          .get();

      int count = directReferrals.docs.length;

      for (var doc in directReferrals.docs) {
        var data = doc.data() as Map<String, dynamic>;
        String childCode = data['myReferralCode'] ?? '';
        count += await _countAllDownline(childCode);
      }

      return count;
    } catch (e) {
      print("Error counting downline: $e");
      return 0;
    }
  }

  // ==========================================
  // 6. Count Paid Downline Members
  // ==========================================
  Future<int> _countPaidDownline(String referralCode) async {
    try {
      if (referralCode.isEmpty) return 0;

      final directReferrals = await _usersCollection
          .where('referralCode', isEqualTo: referralCode)
          .get();

      int count = 0;

      for (var doc in directReferrals.docs) {
        bool hasPaid = await _checkFeeStatus(doc.id);
        if (hasPaid) count++;

        var data = doc.data() as Map<String, dynamic>;
        String childCode = data['myReferralCode'] ?? '';
        count += await _countPaidDownline(childCode);
      }

      return count;
    } catch (e) {
      print("Error counting paid downline: $e");
      return 0;
    }
  }

  // ==========================================
  // 7. Check Fee Status
  // ==========================================
  Future<bool> _checkFeeStatus(String userId) async {
    try {
      // First check user document
      DocumentSnapshot userDoc = await _usersCollection.doc(userId).get();
      if (userDoc.exists) {
        var userData = userDoc.data() as Map<String, dynamic>;
        if (userData.containsKey('hasPaidFee')) {
          return userData['hasPaidFee'] ?? false;
        }
      }

      // Check fee_requests collection
      QuerySnapshot feeQuery = await _firestore
          .collection('fee_requests')
          .where('userId', isEqualTo: userId)
          .where('status', isEqualTo: 'approved')
          .limit(1)
          .get();

      bool hasPaid = feeQuery.docs.isNotEmpty;

      // Update user document for faster future checks
      if (hasPaid) {
        await _usersCollection.doc(userId).update({'hasPaidFee': true});
      }

      return hasPaid;
    } catch (e) {
      print("Error checking fee status: $e");
      return false;
    }
  }

  // ==========================================
  // 8. Delete Old Commission Levels (Helper)
  // ==========================================
  Future<void> deleteAllCommissions() async {
    try {
      final snapshot = await _commissionCollection.get();
      WriteBatch batch = _firestore.batch();

      for (var doc in snapshot.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
      print("All commission levels deleted");
    } catch (e) {
      print("Error deleting commissions: $e");
    }
  }
}
