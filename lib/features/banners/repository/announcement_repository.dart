import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/announcement_model.dart';

class AnnouncementRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference get _ref => _firestore.collection('announcements');

  Stream<List<AnnouncementModel>> streamAnnouncements() {
    return _ref
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map(
                (doc) => AnnouncementModel.fromMap(
                  doc.id,
                  doc.data() as Map<String, dynamic>,
                ),
              )
              .toList(),
        );
  }

  Future<String> addAnnouncement(AnnouncementModel announcement) async {
    final doc = await _ref.add(announcement.toMap());
    return doc.id;
  }

  Future<void> updateAnnouncement(AnnouncementModel announcement) async {
    await _ref.doc(announcement.id).update(announcement.toMap());
  }

  Future<void> deleteAnnouncement(String id) async {
    await _ref.doc(id).delete();
  }
}
