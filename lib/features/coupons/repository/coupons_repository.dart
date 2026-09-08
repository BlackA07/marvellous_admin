// lib/features/coupons/repository/coupons_repository.dart
//
// All Firestore work for coupons lives here; controllers only call this repo.
// The products / customers / categories fetches are deliberately "lite": they
// read just the fields a picker needs instead of parsing the heavy models.

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/common/widgets/user_avatar.dart';
import '../models/coupon_model.dart';

class CouponsRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _ref =>
      _firestore.collection('coupons');

  // ─── COUPONS CRUD ───────────────────────────────────────────────────────

  Stream<List<CouponModel>> streamCoupons() {
    return _ref
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((doc) => CouponModel.fromMap(doc.id, doc.data()))
              .toList(),
        );
  }

  Future<String> addCoupon(CouponModel coupon) async {
    final doc = await _ref.add(coupon.toMap());
    return doc.id;
  }

  Future<void> updateCoupon(CouponModel coupon) async {
    await _ref.doc(coupon.id).update(coupon.toMap());
  }

  Future<void> deleteCoupon(String id) async {
    await _ref.doc(id).delete();
  }

  /// Is this code already used? While editing, the coupon's own doc is skipped.
  Future<bool> isCodeTaken(String code, {String? ignoreId}) async {
    final trimmed = code.trim().toLowerCase();
    if (trimmed.isEmpty) return false;
    final snap = await _ref
        .where('codeLower', isEqualTo: trimmed)
        .limit(2)
        .get();
    return snap.docs.any((d) => d.id != ignoreId);
  }

  // ─── PRODUCTS (lite) ────────────────────────────────────────────────────

  /// Only the fields the product picker needs.
  Future<List<CouponProductRef>> fetchProducts() async {
    final snap = await _firestore.collection('products').get();
    final list = snap.docs.map((doc) {
      final data = doc.data();
      final images = (data['images'] as List?) ?? const [];
      return CouponProductRef(
        id: doc.id,
        name: data['name']?.toString() ?? 'Unnamed product',
        image: images.isEmpty ? '' : images.first.toString(),
        price: (data['salePrice'] as num?)?.toDouble() ?? 0,
        category: data['category']?.toString() ?? '',
      );
    }).toList();
    list.sort(
      (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
    );
    return list;
  }

  // ─── CATEGORIES (names only) ────────────────────────────────────────────

  Future<List<String>> fetchCategoryNames() async {
    final snap = await _firestore.collection('categories').get();
    final names = snap.docs
        .map((doc) => doc.data()['name']?.toString().trim() ?? '')
        .where((name) => name.isNotEmpty)
        .toSet()
        .toList();
    names.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    return names;
  }

  // ─── CUSTOMERS (lite) ───────────────────────────────────────────────────

  /// Lightweight list for the customer picker. "Active member" means the same
  /// thing here as everywhere else in the panel: `isMLMActive`, or a paid
  /// membership status.
  Future<List<CouponCustomerRef>> fetchCustomers() async {
    final snap = await _firestore.collection('users').get();
    var list = <CouponCustomerRef>[];

    for (final doc in snap.docs) {
      final data = doc.data();
      if (data['role'] == 'admin') continue; // admins are not an audience
      if (data['isGuest'] == true) continue;

      final status = data['membershipStatus']?.toString().toLowerCase() ?? '';
      list.add(
        CouponCustomerRef(
          uid: doc.id,
          name:
              data['name']?.toString() ??
              data['username']?.toString() ??
              'Unknown',
          email: data['email']?.toString() ?? '',
          phone: data['phone']?.toString() ?? '',
          image: UserImage.fromMap(data),
          isActiveMember: data['isMLMActive'] == true || status == 'paid',
        ),
      );
    }

    // Most accounts keep the photo in users/{uid}/profile_data/image rather
    // than on the user document — and some hold the literal string 'null',
    // which used to pass as a real photo. UserImage handles both, and caches
    // what it finds so the avatars render without fetching again.
    list = await Future.wait(
      list.map((customer) async {
        final image = await UserImage.resolve(
          customer.uid,
          known: customer.image,
        );
        if (image.isEmpty || image == customer.image) return customer;
        return customer.copyWith(image: image);
      }),
    );

    list.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return list;
  }
}
