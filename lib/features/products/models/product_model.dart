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
  double originalPrice;
  int stockQuantity;
  int stockOut; // New field, default 0
  String vendorId;
  List<String> images;
  String? video;
  DateTime dateAdded;

  String deliveryLocation;
  String warranty;
  double productPoints;

  bool isPackage;
  List<String> includedItemIds;
  bool showDecimalPoints;

  String? ram;
  String? storage;

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
    this.stockOut = 0,
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
    this.ram,
    this.storage,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
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
      'stockOut': stockOut,
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
      stockOut: map['stockOut'] ?? 0,
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
      ram: map['ram'],
      storage: map['storage'],
    );
  }
}
