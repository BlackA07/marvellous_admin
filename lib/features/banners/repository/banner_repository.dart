import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/banner_model.dart';
import 'cloudinary_service.dart';

class BannerRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final CloudinaryService _cloudinary = const CloudinaryService(
    cloudName: 'dzluvpc34',
    uploadPreset: 'marvellous',
  );

  final String _bannersCollection = 'banners';
  final String _backgroundsCollection = 'banner_backgrounds';

  CollectionReference get _bannersRef =>
      _firestore.collection(_bannersCollection);
  CollectionReference get _backgroundsRef =>
      _firestore.collection(_backgroundsCollection);

  Stream<List<BannerModel>> streamBanners() {
    return _bannersRef
        .orderBy('order')
        .snapshots()
        .map(
          (snap) => snap.docs
              .map(
                (doc) => BannerModel.fromMap(
                  doc.id,
                  doc.data() as Map<String, dynamic>,
                ),
              )
              .toList(),
        );
  }

  Future<String> addBanner(BannerModel banner) async {
    final doc = await _bannersRef.add(banner.toMap());
    return doc.id;
  }

  Future<void> updateBanner(BannerModel banner) async {
    await _bannersRef.doc(banner.id).update(banner.toMap());
  }

  Future<void> deleteBanner(String id) async {
    await _bannersRef.doc(id).delete();
  }

  Future<void> incrementViews(String id) async {
    await _bannersRef.doc(id).update({'views': FieldValue.increment(1)});
  }

  Future<void> incrementClicks(String id) async {
    await _bannersRef.doc(id).update({'clicks': FieldValue.increment(1)});
  }

  /// Every image upload (static banner, custom-banner export, background
  /// templates, element product photos) goes through this ONE bytes-based
  /// method — safe on Web, Android, and iOS.
  Future<String> uploadImageBytes(
    Uint8List bytes, {
    String folder = 'banners',
    String? fileName,
  }) async {
    return _cloudinary.uploadBytes(bytes, folder: folder, fileName: fileName);
  }

  Future<List<String>> getBackgroundImages() async {
    final snap = await _backgroundsRef
        .orderBy('createdAt', descending: true)
        .get();
    return snap.docs
        .map((d) => (d.data() as Map<String, dynamic>)['url'] as String)
        .toList();
  }

  Future<void> addBackgroundImage(String url) async {
    await _backgroundsRef.add({'url': url, 'createdAt': Timestamp.now()});
  }
}
