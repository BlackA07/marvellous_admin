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
      // Data fetch karo aur level k hisab se sort karo (Level 1, 2, 3...)
      final snapshot = await _commissionCollection.orderBy('level').get();

      if (snapshot.docs.isEmpty) {
        print("Repository: No commission levels found in Firebase");
        // Agar Database khali hai to empty list return karo
        // Controller default data handle karega
        return [];
      }

      // Firebase docs ko Model men convert karo
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
        // Document ID ko 'level_1', 'level_2' set kar rahe hen taake duplicate na ho
        DocumentReference docRef = _commissionCollection.doc(
          'level_${item.level}',
        );

        // IMPORTANT: Amount bhi save kar rahe hain ab
        Map<String, dynamic> dataToSave = {
          'level': item.level,
          'percentage': item.percentage,
          'amount': item.amount,
        };

        batch.set(docRef, dataToSave);
      }

      // Commit changes to Firebase
      await batch.commit();
      print(
        "Repository: ${levels.length} Commission Levels saved to Firebase successfully!",
      );

      // Verification ke liye data print karo
      for (var lvl in levels) {
        print(
          "Saved Level ${lvl.level}: ${lvl.percentage}% = Rs ${lvl.amount}",
        );
      }
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
