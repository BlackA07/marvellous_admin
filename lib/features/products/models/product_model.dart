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
  double salePrice;
  double originalPrice; // Optional: 0.0 means hidden
  int stockQuantity;
  String vendorId;
  List<String> images;
  String? video;
  DateTime dateAdded;

  // --- Existing Extra Fields ---
  String deliveryLocation;
  String warranty;
  double productPoints;

  // --- NEW FIELDS FOR PACKAGES & SETTINGS ---
  bool isPackage;
  List<String> includedItemIds;
  bool showDecimalPoints;

  // --- NEW FIELDS FOR MOBILE SPECS ---
  String? ram; // e.g. "8GB"
  String? storage; // e.g. "128GB"

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
    required this.originalPrice,
    required this.stockQuantity,
    required this.vendorId,
    required this.images,
    this.video,
    required this.dateAdded,
    required this.deliveryLocation,
    required this.warranty,
    required this.productPoints,
    this.isPackage = false,
    this.includedItemIds = const [],
    this.showDecimalPoints = true,
    // New Params
    this.ram,
    this.storage,
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
      'originalPrice': originalPrice,
      'stockQuantity': stockQuantity,
      'vendorId': vendorId,
      'images': images,
      'video': video,
      'dateAdded': Timestamp.fromDate(dateAdded),
      'deliveryLocation': deliveryLocation,
      'warranty': warranty,
      'productPoints': productPoints,
      'isPackage': isPackage,
      'includedItemIds': includedItemIds,
      'showDecimalPoints': showDecimalPoints,
      // New Fields
      'ram': ram,
      'storage': storage,
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
      originalPrice: (map['originalPrice'] ?? 0).toDouble(),
      stockQuantity: map['stockQuantity'] ?? 0,
      vendorId: map['vendorId'] ?? '',
      images: List<String>.from(map['images'] ?? []),
      video: map['video'],
      dateAdded: (map['dateAdded'] as Timestamp).toDate(),
      deliveryLocation: map['deliveryLocation'] ?? 'Worldwide',
      warranty: map['warranty'] ?? 'No Warranty',
      productPoints: (map['productPoints'] ?? 0).toDouble(),
      isPackage: map['isPackage'] ?? false,
      includedItemIds: List<String>.from(map['includedItemIds'] ?? []),
      showDecimalPoints: map['showDecimalPoints'] ?? true,
      // New Fields Extraction
      ram: map['ram'],
      storage: map['storage'],
    );
  }
}
