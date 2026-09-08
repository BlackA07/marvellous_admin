import 'package:cloud_firestore/cloud_firestore.dart';

/// Product kis kis jagah available hai — ek "unit".
/// level: 'country' (poori country) | 'state' (poora state) | 'city' (sirf city)
class ProductAvailabilityUnit {
  final String level;
  final String countryId;
  final String countryName;
  final String? stateId;
  final String? stateName;
  final String? cityId;
  final String? cityName;

  ProductAvailabilityUnit({
    required this.level,
    required this.countryId,
    required this.countryName,
    this.stateId,
    this.stateName,
    this.cityId,
    this.cityName,
  });

  /// Delivery fee/time maps mein isi key se entry hoti hai.
  String get key => [
    countryId,
    if (stateId != null) stateId,
    if (cityId != null) cityId,
  ].join('|');

  /// Sab se choti unit ka naam (city > state > country).
  String get label => cityName ?? stateName ?? countryName;

  /// "Pakistan › Sindh › Karachi"
  String get pathLabel => [
    countryName,
    if (stateName != null) stateName,
    if (cityName != null) cityName,
  ].join(' › ');

  ProductAvailabilityUnit copyWith({String? level}) => ProductAvailabilityUnit(
    level: level ?? this.level,
    countryId: countryId,
    countryName: countryName,
    stateId: stateId,
    stateName: stateName,
    cityId: cityId,
    cityName: cityName,
  );

  Map<String, dynamic> toMap() => {
    'level': level,
    'countryId': countryId,
    'countryName': countryName,
    'stateId': stateId,
    'stateName': stateName,
    'cityId': cityId,
    'cityName': cityName,
    'key': key,
  };

  factory ProductAvailabilityUnit.fromMap(Map<String, dynamic> map) {
    return ProductAvailabilityUnit(
      level: map['level']?.toString() ?? 'country',
      countryId: map['countryId']?.toString() ?? '',
      countryName: map['countryName']?.toString() ?? '',
      stateId: map['stateId']?.toString(),
      stateName: map['stateName']?.toString(),
      cityId: map['cityId']?.toString(),
      cityName: map['cityName']?.toString(),
    );
  }

  @override
  bool operator ==(Object other) =>
      other is ProductAvailabilityUnit && other.key == key;

  @override
  int get hashCode => key.hashCode;
}

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
  int stockQuantity; // Available Stock (Left)
  int stockOut; // Total Sold
  int stockIn; // Total Bought (In)
  String vendorId;
  String vendorName;
  List<String> images;
  String? video;
  DateTime dateAdded;
  String deliveryLocation;
  String warranty;
  double productPoints;
  String? tiktokVideoUrl; // ✅ NAYA FIELD ADDED
  int views; // ✅ NEW

  Map<String, double> deliveryFeesMap;
  Map<String, String> deliveryTimeMap;
  double codFee;
  double averageRating;
  int totalReviews;

  // ── NAYE FIELDS (purane products par koi asar nahi — sab optional) ──
  /// Admin ki live location jahan se product add kiya gaya.
  Map<String, dynamic>? adminLiveLocation;

  /// Product kin kin countries/states/cities mein available hai.
  List<ProductAvailabilityUnit> availabilityUnits;

  /// Har availability unit ki apni delivery fee (base currency: PKR).
  Map<String, double> regionFeesMap;

  /// Har availability unit ka apna delivery time.
  Map<String, String> regionTimeMap;

  /// Product khareedne mein jo extra kharcha aaya (transport, packing waghera).
  double goodsExpense;

  /// Product ki quality (admin khud type karta hai — e.g. "A Grade", "Original").
  String quality;

  bool isPackage;
  List<String> includedItemIds;
  bool showDecimalPoints;
  String? ram;
  String? storage;
  String status;
  String? holdReason; // ✅ NAYA FIELD ADDED

  ProductModel({
    this.id,
    required this.name,
    required this.modelNumber,
    required this.description,
    required this.category,
    required this.subCategory,
    this.tiktokVideoUrl, // ✅ ADDED
    required this.brand,
    required this.purchasePrice,
    required this.salePrice,
    required this.originalPrice,
    required this.stockQuantity,
    this.stockOut = 0,
    this.stockIn = 0,
    this.views = 0, // ✅ NEW
    required this.vendorId,
    this.vendorName = 'Admin',
    required this.images,
    this.video,
    required this.dateAdded,
    required this.deliveryLocation,
    required this.warranty,
    required this.productPoints,
    required this.deliveryFeesMap,
    required this.deliveryTimeMap,
    this.codFee = 0.0,
    this.averageRating = 0.0,
    this.totalReviews = 0,
    this.adminLiveLocation,
    this.availabilityUnits = const [],
    this.regionFeesMap = const {},
    this.regionTimeMap = const {},
    this.goodsExpense = 0.0,
    this.quality = '',
    this.isPackage = false,
    this.includedItemIds = const [],
    this.showDecimalPoints = true,
    this.ram,
    this.storage,
    this.status = 'approved',
    this.holdReason, // ✅ ADDED
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'modelNumber': modelNumber,
      'description': description,
      'category': category,
      'views': views, // ✅ NEW
      'subCategory': subCategory,
      'brand': brand,
      'purchasePrice': purchasePrice,
      'salePrice': salePrice,
      'originalPrice': originalPrice,
      'stockQuantity': stockQuantity,
      'tiktokVideoUrl': tiktokVideoUrl, // ✅ ADDED
      'stockOut': stockOut,
      'stockIn': stockIn,
      'vendorId': vendorId,
      'vendorName': vendorName,
      'images': images,
      'video': video,
      'dateAdded': Timestamp.fromDate(dateAdded),
      'deliveryLocation': deliveryLocation,
      'warranty': warranty,
      'productPoints': productPoints,
      'deliveryFeesMap': deliveryFeesMap,
      'deliveryTimeMap': deliveryTimeMap,
      'codFee': codFee,
      'averageRating': averageRating,
      'totalReviews': totalReviews,
      'adminLiveLocation': adminLiveLocation,
      'availabilityUnits': availabilityUnits.map((e) => e.toMap()).toList(),
      'regionFeesMap': regionFeesMap,
      'regionTimeMap': regionTimeMap,
      'goodsExpense': goodsExpense,
      'quality': quality,
      'isPackage': isPackage,
      'includedItemIds': includedItemIds,
      'showDecimalPoints': showDecimalPoints,
      'ram': ram,
      'storage': storage,
      'status': status,
      'holdReason': holdReason, // ✅ ADDED
    };
  }

  factory ProductModel.fromMap(Map<String, dynamic> map, String docId) {
    return ProductModel(
      id: docId,
      name: map['name']?.toString() ?? '',
      modelNumber: map['modelNumber']?.toString() ?? '',
      description: map['description']?.toString() ?? '',
      category: map['category']?.toString() ?? '',
      subCategory: map['subCategory']?.toString() ?? '',
      brand: map['brand']?.toString() ?? '',
      purchasePrice: (map['purchasePrice'] as num?)?.toDouble() ?? 0.0,
      tiktokVideoUrl: map['tiktokVideoUrl']?.toString(), // ✅ ADDED
      salePrice: (map['salePrice'] as num?)?.toDouble() ?? 0.0,
      originalPrice: (map['originalPrice'] as num?)?.toDouble() ?? 0.0,
      stockQuantity: (map['stockQuantity'] as num?)?.toInt() ?? 0,
      stockOut: (map['stockOut'] as num?)?.toInt() ?? 0,
      views: (map['views'] as num?)?.toInt() ?? 0, // ✅ NEW
      stockIn: (map['stockIn'] ?? map['stockQuantity'] as num?)?.toInt() ?? 0,
      vendorId: map['vendorId']?.toString() ?? '',
      vendorName: map['vendorName']?.toString() ?? 'Admin',
      images: map['images'] is List
          ? (map['images'] as List).map((e) => e.toString()).toList()
          : [],
      video: map['video']?.toString(),
      dateAdded: map['dateAdded'] is Timestamp
          ? (map['dateAdded'] as Timestamp).toDate()
          : DateTime.now(),
      deliveryLocation: map['deliveryLocation']?.toString() ?? 'Worldwide',
      warranty: map['warranty']?.toString() ?? 'No Warranty',
      productPoints: (map['productPoints'] as num?)?.toDouble() ?? 0.0,
      deliveryFeesMap: map['deliveryFeesMap'] is Map
          ? (map['deliveryFeesMap'] as Map).map(
              (key, value) =>
                  MapEntry(key.toString(), (value as num).toDouble()),
            )
          : {},
      deliveryTimeMap: map['deliveryTimeMap'] is Map
          ? (map['deliveryTimeMap'] as Map).map(
              (key, value) => MapEntry(key.toString(), value.toString()),
            )
          : {},
      codFee: (map['codFee'] as num?)?.toDouble() ?? 0.0,
      averageRating: (map['averageRating'] as num?)?.toDouble() ?? 0.0,
      totalReviews: (map['totalReviews'] as num?)?.toInt() ?? 0,
      adminLiveLocation: map['adminLiveLocation'] is Map
          ? (map['adminLiveLocation'] as Map).cast<String, dynamic>()
          : null,
      availabilityUnits: map['availabilityUnits'] is List
          ? (map['availabilityUnits'] as List)
                .whereType<Map>()
                .map(
                  (e) => ProductAvailabilityUnit.fromMap(
                    e.cast<String, dynamic>(),
                  ),
                )
                .toList()
          : const [],
      regionFeesMap: map['regionFeesMap'] is Map
          ? (map['regionFeesMap'] as Map).map(
              (key, value) => MapEntry(
                key.toString(),
                (value as num?)?.toDouble() ?? 0.0,
              ),
            )
          : const {},
      regionTimeMap: map['regionTimeMap'] is Map
          ? (map['regionTimeMap'] as Map).map(
              (key, value) => MapEntry(key.toString(), value.toString()),
            )
          : const {},
      goodsExpense: (map['goodsExpense'] as num?)?.toDouble() ?? 0.0,
      quality: map['quality']?.toString() ?? '',
      isPackage: map['isPackage'] ?? false,
      includedItemIds: map['includedItemIds'] is List
          ? (map['includedItemIds'] as List).map((e) => e.toString()).toList()
          : [],
      showDecimalPoints: map['showDecimalPoints'] ?? true,
      ram: map['ram']?.toString(),
      storage: map['storage']?.toString(),
      status: map['status']?.toString() ?? 'approved',
      holdReason: map['holdReason']?.toString(), // ✅ ADDED
    );
  }
}
