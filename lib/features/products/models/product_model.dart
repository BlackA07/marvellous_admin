import 'package:cloud_firestore/cloud_firestore.dart';

class ProductModel {
  String? id;
  String name;
  String modelNumber;
  String description;
  String category;
  String subCategory;
  String brand;
  double purchasePrice;
  double salePrice; // The actual selling price (Discounted)
  double originalPrice; // The fake/high price (to be crossed out)
  int stockQuantity;
  String vendorId;
  List<String> images;
  String? video;
  DateTime dateAdded;

  // New Fields
  String deliveryLocation; // e.g., "Karachi Only", "Pakistan"
  String warranty; // e.g., "1 Year"
  double productPoints; // Points earned by user on this product

  ProductModel({
    this.id,
    required this.name,
    required this.modelNumber,
    required this.description,
    required this.category,
    required this.subCategory,
    required this.brand,
    required this.purchasePrice,
    required this.salePrice,
    required this.originalPrice, // New
    required this.stockQuantity,
    required this.vendorId,
    required this.images,
    this.video,
    required this.dateAdded,
    required this.deliveryLocation, // New
    required this.warranty, // New
    required this.productPoints, // New
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'modelNumber': modelNumber,
      'description': description,
      'category': category,
      'subCategory': subCategory,
      'brand': brand,
      'purchasePrice': purchasePrice,
      'salePrice': salePrice,
      'originalPrice': originalPrice, // New
      'stockQuantity': stockQuantity,
      'vendorId': vendorId,
      'images': images,
      'video': video,
      'dateAdded': Timestamp.fromDate(dateAdded),
      'deliveryLocation': deliveryLocation, // New
      'warranty': warranty, // New
      'productPoints': productPoints, // New
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
      brand: map['brand'] ?? '',
      purchasePrice: (map['purchasePrice'] ?? 0).toDouble(),
      salePrice: (map['salePrice'] ?? 0).toDouble(),
      originalPrice: (map['originalPrice'] ?? 0).toDouble(), // New
      stockQuantity: map['stockQuantity'] ?? 0,
      vendorId: map['vendorId'] ?? '',
      images: List<String>.from(map['images'] ?? []),
      video: map['video'],
      dateAdded: (map['dateAdded'] as Timestamp).toDate(),
      deliveryLocation: map['deliveryLocation'] ?? 'Worldwide', // New
      warranty: map['warranty'] ?? 'No Warranty', // New
      productPoints: (map['productPoints'] ?? 0).toDouble(), // New
    );
  }
}
