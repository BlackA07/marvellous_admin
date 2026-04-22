import 'package:cloud_firestore/cloud_firestore.dart';
import '../model/staff_model.dart';

class StaffRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _collection = 'staff';

  Future<String> addStaff(StaffModel staff) async {
    try {
      final docRef = await _firestore
          .collection(_collection)
          .add(staff.toFirestore());
      return docRef.id;
    } catch (e) {
      throw Exception('Staff save karne mein error: $e');
    }
  }

  Future<void> updateStaff(StaffModel staff) async {
    if (staff.id == null) throw Exception('Staff ID nahi mili');
    try {
      await _firestore
          .collection(_collection)
          .doc(staff.id)
          .update(staff.toFirestore());
    } catch (e) {
      throw Exception('Staff update karne mein error: $e');
    }
  }

  Future<void> deleteStaff(String staffId) async {
    try {
      await _firestore.collection(_collection).doc(staffId).delete();
    } catch (e) {
      throw Exception('Staff delete karne mein error: $e');
    }
  }

  Future<StaffModel?> getStaffById(String staffId) async {
    try {
      final doc = await _firestore.collection(_collection).doc(staffId).get();
      if (!doc.exists) return null;
      return StaffModel.fromFirestore(doc.data()!, doc.id);
    } catch (e) {
      throw Exception('Staff fetch karne mein error: $e');
    }
  }

  Stream<List<StaffModel>> getAllStaffStream() {
    return _firestore
        .collection(_collection)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => StaffModel.fromFirestore(doc.data(), doc.id))
              .toList(),
        );
  }

  Future<List<StaffModel>> getAllStaff() async {
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .orderBy('createdAt', descending: true)
          .get();
      return snapshot.docs
          .map((doc) => StaffModel.fromFirestore(doc.data(), doc.id))
          .toList();
    } catch (e) {
      throw Exception('Staff list fetch karne mein error: $e');
    }
  }
}
