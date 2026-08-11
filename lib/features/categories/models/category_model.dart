class CategoryModel {
  String? id;
  String name;
  String? imageUrl; // Main Category Image
  List<Map<String, dynamic>>
  subCategories; // Sub-category ab Map hai (name + imageUrl)

  CategoryModel({
    this.id,
    required this.name,
    this.imageUrl,
    required this.subCategories,
  });

  Map<String, dynamic> toMap() {
    return {'name': name, 'imageUrl': imageUrl, 'subCategories': subCategories};
  }

  factory CategoryModel.fromMap(Map<String, dynamic> map, String docId) {
    // 🛡️ SAFEGUARD (hardened): purana data teen tarah ka ho sakta hai —
    // 1) plain String   2) proper Map {name, imageUrl}   3) null / garbage
    // Teenon cases ko safely handle karte hain taake "type X is not a
    // subtype of Y" wala crash kabhi na aaye.
    var rawSubCategories = map['subCategories'] as List<dynamic>? ?? [];

    List<Map<String, dynamic>> parsedSubCats = rawSubCategories
        .map<Map<String, dynamic>?>((e) {
          // Case 1: entry null hai — ignore karein
          if (e == null) return null;

          // Case 2: purana format — sirf String tha
          if (e is String) {
            final trimmed = e.trim();
            if (trimmed.isEmpty) return null;
            return {'name': trimmed, 'imageUrl': ''};
          }

          // Case 3: normal format — Map hai (LinkedMap ho ya kuch bhi)
          if (e is Map) {
            final safeMap = Map<String, dynamic>.from(e);
            final name = safeMap['name']?.toString().trim() ?? '';
            if (name.isEmpty) return null; // Bina naam ke entry drop karein
            return {
              'name': name,
              'imageUrl': safeMap['imageUrl']?.toString() ?? '',
            };
          }

          // Case 4: koi anjaan/ghalat type — crash hone se bachne ke liye ignore
          return null;
        })
        .whereType<Map<String, dynamic>>() // nulls hata dein
        .toList();

    return CategoryModel(
      id: docId,
      name: map['name']?.toString() ?? '',
      imageUrl: map['imageUrl']?.toString() ?? '',
      subCategories: parsedSubCats,
    );
  }
}
