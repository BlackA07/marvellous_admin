import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ProfileRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Current User ID get karna
  String get currentUserId => _auth.currentUser?.uid ?? '';

  // 1. Get Admin Profile
  Future<Map<String, dynamic>?> getAdminProfile() async {
    try {
      if (currentUserId.isEmpty) return null;

      DocumentSnapshot doc = await _firestore
          .collection('users')
          .doc(currentUserId)
          .get();
      if (doc.exists) {
        return doc.data() as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      throw Exception("Profile load error: $e");
    }
  }

  // 2. Update Admin Profile
  Future<void> updateProfile({
    required String name,
    required String phone,
    String? base64Image,
  }) async {
    try {
      Map<String, dynamic> data = {
        'name': name,
        'phone': phone, // Sirf ye fields update hongi
      };

      // Agar image change hui hai to hi update karo
      if (base64Image != null && base64Image.isNotEmpty) {
        data['profileImage'] = base64Image;
      }

      await _firestore.collection('users').doc(currentUserId).update(data);
    } catch (e) {
      throw Exception("Update error: $e");
    }
  }
}
