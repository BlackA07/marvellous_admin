// File: lib/features/mlm/data/repositories/mlm_repository.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/mlm_models.dart';

class MLMRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // --- Collection References for cleaner code ---
  // Commissions yahan save honge: mlm_settings > config > commissions > level_x
  CollectionReference get _commissionCollection => _firestore
      .collection('mlm_settings')
      .doc('config')
      .collection('commissions');

  // Users yahan se fetch honge
  CollectionReference get _usersCollection => _firestore.collection('users');

  // ==========================================
  // 1. Commission Levels Fetch karna (Real Firebase)
  // ==========================================
  Future<List<CommissionLevel>> getCommissionLevels() async {
    try {
      // Data fetch karo aur level k hisab se sort karo (Level 0, 1, 2, 3...)
      final snapshot = await _commissionCollection.orderBy('level').get();

      if (snapshot.docs.isEmpty) {
        // Agar Database khali hai to Default/Initial data return karo
        // Taake app crash na ho pehli baar chalne par
        // Added Level 0 (Cashback) to defaults
        return [
          CommissionLevel(level: 0, percentage: 5.0), // Cashback Level
          CommissionLevel(level: 1, percentage: 25.0),
          CommissionLevel(level: 2, percentage: 15.0),
          CommissionLevel(level: 3, percentage: 10.0),
          for (int i = 4; i <= 11; i++)
            CommissionLevel(level: i, percentage: 3.0),
        ];
      }

      // Firebase docs ko Model men convert karo
      List<CommissionLevel> levels = snapshot.docs.map((doc) {
        return CommissionLevel.fromJson(doc.data() as Map<String, dynamic>);
      }).toList();

      // Ensure Level 0 exists in the fetched list (if not, add a default 0)
      // This handles cases where older data might not have level 0 yet
      bool hasLevel0 = levels.any((l) => l.level == 0);
      if (!hasLevel0) {
        levels.insert(0, CommissionLevel(level: 0, percentage: 0.0));
      }

      // Sort again just to be safe
      levels.sort((a, b) => a.level.compareTo(b.level));

      return levels;
    } catch (e) {
      print("Error fetching commissions: $e");
      return []; // Error aye to khali list
    }
  }

  // ==========================================
  // 2. Commission Levels Save karna (Real Firebase)
  // ==========================================
  Future<void> saveCommissions(List<CommissionLevel> levels) async {
    try {
      // Batch write use kar rahe hen taake saari changes ek sath save hon (Fast & Safe)
      WriteBatch batch = _firestore.batch();

      for (var item in levels) {
        // Document ID ko 'level_0', 'level_1', etc set kar rahe hen
        DocumentReference docRef = _commissionCollection.doc(
          'level_${item.level}',
        );

        batch.set(docRef, item.toJson());
      }

      // Commit changes to Firebase
      await batch.commit();
      print(
        "Repository: Commissions (including Level 0) Saved to Firebase successfully!",
      );
    } catch (e) {
      print("Error saving commissions: $e");
      throw e; // Error controller tak pohnchaye
    }
  }

  // ==========================================
  // 3. Tree Data Fetch karna (Real Firebase)
  // ==========================================
  Future<MLMNode?> getMLMTree() async {
    try {
      // Step 1: Root Node (Admin) ko dhundo
      // Hum maan rahe hen k Admin ka role 'admin' hai.
      final adminSnapshot = await _usersCollection
          .where(
            'role',
            isEqualTo: 'admin',
          ) // Apne hisab se filter change karsakte hen
          .limit(1)
          .get();

      if (adminSnapshot.docs.isEmpty) {
        print("No Admin/Root user found in database");
        return null;
      }

      // Root Admin Data
      final rootDoc = adminSnapshot.docs.first;
      final rootData = rootDoc.data() as Map<String, dynamic>;

      // Step 2: Recursive Function call karke pura tree banao
      return await _buildNodeRecursively(rootDoc.id, rootData);
    } catch (e) {
      print("Error fetching tree: $e");
      return null;
    }
  }

  // --- Helper Function: Recursively Children Dhundne k liye ---
  Future<MLMNode> _buildNodeRecursively(
    String docId,
    Map<String, dynamic> data,
  ) async {
    List<MLMNode> childrenNodes = [];

    // Is user ka Referral Code nikalo
    String? myReferralCode = data['referralCode'];

    if (myReferralCode != null && myReferralCode.isNotEmpty) {
      // Database men wo users dhundo jinka 'referredBy' == 'myReferralCode' ho
      final childrenSnapshot = await _usersCollection
          .where('referredBy', isEqualTo: myReferralCode)
          .get();

      // Har child k liye dobara yahi function call karo (Recursion)
      for (var childDoc in childrenSnapshot.docs) {
        var childData = childDoc.data() as Map<String, dynamic>;
        childrenNodes.add(await _buildNodeRecursively(childDoc.id, childData));
      }
    }

    // Node return karo with Children
    return MLMNode(
      id: docId,
      name: data['name'] ?? 'Unknown User',
      role: data['role'] ?? 'User',
      children: childrenNodes,
    );
  }
}
