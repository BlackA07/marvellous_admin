import 'package:cloud_firestore/cloud_firestore.dart';

class ProductModel {
  String? id;
  String name;
  String modelNumber;
  String description;
  String category;
  String subCategory; // Already thi, ab UI se connect hogi
  String brand; // NEW FIELD
  double purchasePrice;
  double salePrice;
  int stockQuantity;
  String vendorId;
  List<String> images;
  String? video;
  DateTime dateAdded;

  ProductModel({
    this.id,
    required this.name,
    required this.modelNumber,
    required this.description,
    required this.category,
    required this.subCategory,
    required this.brand, // New
    required this.purchasePrice,
    required this.salePrice,
    required this.stockQuantity,
    required this.vendorId,
    required this.images,
    this.video,
    required this.dateAdded,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'modelNumber': modelNumber,
      'description': description,
      'category': category,
      'subCategory': subCategory,
      'brand': brand, // New
      'purchasePrice': purchasePrice,
      'salePrice': salePrice,
      'stockQuantity': stockQuantity,
      'vendorId': vendorId,
      'images': images,
      'video': video,
      'dateAdded': Timestamp.fromDate(dateAdded),
    };
  }

  factory ProductModel.fromMap(Map<String, dynamic> map, String docId) {
    return ProductModel(
      id: docId,
      name: map['name'] ?? '',
      modelNumber: map['modelNumber'] ?? '',
      description: map['description'] ?? '',
      category: map['category'] ?? '',
      subCategory: map['subCategory'] ?? '',
      brand: map['brand'] ?? '', // New
      purchasePrice: (map['purchasePrice'] ?? 0).toDouble(),
      salePrice: (map['salePrice'] ?? 0).toDouble(),
      stockQuantity: map['stockQuantity'] ?? 0,
      vendorId: map['vendorId'] ?? '',
      images: List<String>.from(map['images'] ?? []),
      video: map['video'],
      dateAdded: (map['dateAdded'] as Timestamp).toDate(),
    );
  }
}
