class CategoryModel {
  String? id;
  String name;
  List<String> subCategories;

  CategoryModel({this.id, required this.name, required this.subCategories});

  Map<String, dynamic> toMap() {
    return {'name': name, 'subCategories': subCategories};
  }

  factory CategoryModel.fromMap(Map<String, dynamic> map, String docId) {
    return CategoryModel(
      id: docId,
      name: map['name'] ?? '',
      subCategories: List<String>.from(map['subCategories'] ?? []),
    );
  }
}
