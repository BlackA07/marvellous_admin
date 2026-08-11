import 'package:cloud_firestore/cloud_firestore.dart';

class BannerProductOption {
  final String id;
  final String name;
  final String modelNumber;
  final String imageUrl;
  final String? ram;
  final String? storage;

  BannerProductOption({
    required this.id,
    required this.name,
    required this.modelNumber,
    required this.imageUrl,
    this.ram,
    this.storage,
  });
}

class BannerCategoryOption {
  final String name;
  final List<String> subCategories;

  BannerCategoryOption({required this.name, required this.subCategories});
}

/// Read-only helper for the banner "select target" picker.
/// Does NOT modify the existing products/categories collections or their
/// own controllers — just reads what's needed to populate the picker.
class BannerActionRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<List<BannerProductOption>> fetchProducts() async {
    final snap = await _firestore.collection('products').get();
    final list = snap.docs.map((doc) {
      final data = doc.data();
      final images = data['images'];
      final firstImage = (images is List && images.isNotEmpty)
          ? images[0].toString()
          : '';
      return BannerProductOption(
        id: doc.id,
        name: data['name']?.toString() ?? '',
        modelNumber: data['modelNumber']?.toString() ?? '',
        imageUrl: firstImage,
        ram: data['ram']?.toString(),
        storage: data['storage']?.toString(),
      );
    }).toList();

    // A → Z by product name (case-insensitive)
    list.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return list;
  }

  Future<List<BannerCategoryOption>> fetchCategories() async {
    final snap = await _firestore.collection('categories').get();
    final list = snap.docs.map((doc) {
      final data = doc.data();
      final rawSubs = data['subCategories'] as List<dynamic>? ?? [];
      final subs = rawSubs
          .map((e) {
            if (e is String) return e;
            if (e is Map) return (e['name'] ?? '').toString();
            return '';
          })
          .where((s) => s.isNotEmpty)
          .toList();
      return BannerCategoryOption(
        name: data['name']?.toString() ?? '',
        subCategories: List<String>.from(subs),
      );
    }).toList();

    // A → Z by category name too
    list.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return list;
  }
}
