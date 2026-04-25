import 'package:cloud_firestore/cloud_firestore.dart';
import '../../staff/model/staff_model.dart';
import '../model/user_settings_model.dart';

class UserSettingsRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _staffCollection = 'staff';
  static const String _permissionsCollection = 'user_permissions';

  // Dropdown ke liye all staff fetch karna
  Future<List<StaffModel>> getAllStaffForDropdown() async {
    try {
      final snapshot = await _firestore
          .collection(_staffCollection)
          .orderBy('name')
          .get();
      return snapshot.docs
          .map((doc) => StaffModel.fromFirestore(doc.data(), doc.id))
          .toList();
    } catch (e) {
      throw Exception('Staff load karne mein error: $e');
    }
  }

  // Kisi specific staff ki permissions fetch karna
  Future<UserSettingsModel?> getStaffPermissions(String staffId) async {
    try {
      final doc = await _firestore
          .collection(_permissionsCollection)
          .doc(staffId)
          .get();
      if (!doc.exists || doc.data() == null) return null;
      return UserSettingsModel.fromFirestore(doc.data()!, doc.id);
    } catch (e) {
      throw Exception('Permissions load karne mein error: $e');
    }
  }

  // Permissions save ya update karna
  Future<void> saveStaffPermissions(UserSettingsModel settings) async {
    try {
      await _firestore
          .collection(_permissionsCollection)
          .doc(settings.staffId)
          .set(settings.toFirestore(), SetOptions(merge: true));
    } catch (e) {
      throw Exception('Permissions save karne mein error: $e');
    }
  }
}
