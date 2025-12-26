class ProductModel {
  String? id;
  String name;
  String modelNumber;
  String description;
  String category;
  String subCategory;
  double purchasePrice;
  double salePrice;
  int stockQuantity;
  String vendorId;
  List<String> images; // Paths to images
  String? video; // Path to video
  DateTime dateAdded;

  ProductModel({
    this.id,
    required this.name,
    required this.modelNumber,
    required this.description,
    required this.category,
    required this.subCategory,
    required this.purchasePrice,
    required this.salePrice,
    required this.stockQuantity,
    required this.vendorId,
    required this.images,
    this.video,
    required this.dateAdded,
  });

  // Convert to Map (for Database/API)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'modelNumber': modelNumber,
      'description': description,
      'category': category,
      'subCategory': subCategory,
      'purchasePrice': purchasePrice,
      'salePrice': salePrice,
      'stockQuantity': stockQuantity,
      'vendorId': vendorId,
      'images': images,
      'video': video,
      'dateAdded': dateAdded.toIso8601String(),
    };
  }

  // Create from Map
  factory ProductModel.fromMap(Map<String, dynamic> map, String id) {
    return ProductModel(
      id: id,
      name: map['name'] ?? '',
      modelNumber: map['modelNumber'] ?? '',
      description: map['description'] ?? '',
      category: map['category'] ?? '',
      subCategory: map['subCategory'] ?? '',
      purchasePrice: (map['purchasePrice'] ?? 0).toDouble(),
      salePrice: (map['salePrice'] ?? 0).toDouble(),
      stockQuantity: map['stockQuantity'] ?? 0,
      vendorId: map['vendorId'] ?? '',
      images: List<String>.from(map['images'] ?? []),
      video: map['video'],
      dateAdded: DateTime.parse(map['dateAdded']),
    );
  }
}
