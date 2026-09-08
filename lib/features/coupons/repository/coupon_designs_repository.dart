// lib/features/coupons/repository/coupon_designs_repository.dart

import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/coupon_design_model.dart';

class CouponDesignsRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _ref =>
      _firestore.collection('coupon_designs');

  Stream<List<CouponDesignModel>> streamDesigns() {
    return _ref
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((doc) => CouponDesignModel.fromMap(doc.id, doc.data()))
              .toList(),
        );
  }

  Future<List<CouponDesignModel>> fetchDesigns() async {
    final snap = await _ref.orderBy('createdAt', descending: true).get();
    return snap.docs
        .map((doc) => CouponDesignModel.fromMap(doc.id, doc.data()))
        .toList();
  }

  Future<String> addDesign(CouponDesignModel design) async {
    final doc = await _ref.add(design.toMap());
    return doc.id;
  }

  Future<void> updateDesign(CouponDesignModel design) async {
    await _ref.doc(design.id).update(design.toMap());
  }

  Future<void> deleteDesign(String id) async {
    await _ref.doc(id).delete();
  }
}
