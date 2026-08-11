import 'package:cloud_firestore/cloud_firestore.dart';
import 'banner_element_model.dart';

enum BannerType { static_, custom }

BannerType bannerTypeFromString(String value) =>
    value == 'custom' ? BannerType.custom : BannerType.static_;

String bannerTypeToString(BannerType type) =>
    type == BannerType.custom ? 'custom' : 'static';

/// Where a banner should take the customer when tapped.
/// - none: no navigation configured yet
/// - product: opens a specific product's detail screen
/// - category: opens the product listing filtered by category (+ optional subcategory)
enum BannerActionType { none, product, category }

BannerActionType bannerActionTypeFromString(String value) {
  switch (value) {
    case 'product':
      return BannerActionType.product;
    case 'category':
      return BannerActionType.category;
    default:
      return BannerActionType.none;
  }
}

String bannerActionTypeToString(BannerActionType type) {
  switch (type) {
    case BannerActionType.product:
      return 'product';
    case BannerActionType.category:
      return 'category';
    default:
      return 'none';
  }
}

class BannerModel {
  final String id;
  final BannerType type;
  final String? backgroundImageUrl; // only for custom type
  final String finalImageUrl; // flattened PNG shown in the app, both types
  final List<BannerElementModel> elements; // only for custom type
  final bool isActive;
  final int order;
  final int views;
  final int clicks;
  final DateTime createdAt;
  final DateTime? updatedAt;

  // ---- where tapping this banner should navigate ----
  final BannerActionType actionType;
  final String? actionProductId;
  final String?
  actionProductName; // stored for display in admin list, not required for navigation
  final String? actionCategoryName;
  final String? actionSubCategoryName;

  const BannerModel({
    required this.id,
    required this.type,
    this.backgroundImageUrl,
    required this.finalImageUrl,
    this.elements = const [],
    this.isActive = true,
    this.order = 0,
    this.views = 0,
    this.clicks = 0,
    required this.createdAt,
    this.updatedAt,
    this.actionType = BannerActionType.none,
    this.actionProductId,
    this.actionProductName,
    this.actionCategoryName,
    this.actionSubCategoryName,
  });

  BannerModel copyWith({
    BannerType? type,
    String? backgroundImageUrl,
    String? finalImageUrl,
    List<BannerElementModel>? elements,
    bool? isActive,
    int? order,
    int? views,
    int? clicks,
    DateTime? updatedAt,
    BannerActionType? actionType,
    String? actionProductId,
    String? actionProductName,
    String? actionCategoryName,
    String? actionSubCategoryName,
  }) {
    return BannerModel(
      id: id,
      type: type ?? this.type,
      backgroundImageUrl: backgroundImageUrl ?? this.backgroundImageUrl,
      finalImageUrl: finalImageUrl ?? this.finalImageUrl,
      elements: elements ?? this.elements,
      isActive: isActive ?? this.isActive,
      order: order ?? this.order,
      views: views ?? this.views,
      clicks: clicks ?? this.clicks,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      actionType: actionType ?? this.actionType,
      actionProductId: actionProductId ?? this.actionProductId,
      actionProductName: actionProductName ?? this.actionProductName,
      actionCategoryName: actionCategoryName ?? this.actionCategoryName,
      actionSubCategoryName:
          actionSubCategoryName ?? this.actionSubCategoryName,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'type': bannerTypeToString(type),
      'backgroundImageUrl': backgroundImageUrl,
      'finalImageUrl': finalImageUrl,
      'elements': elements.map((e) => e.toMap()).toList(),
      'isActive': isActive,
      'order': order,
      'views': views,
      'clicks': clicks,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      'actionType': bannerActionTypeToString(actionType),
      'actionProductId': actionProductId,
      'actionProductName': actionProductName,
      'actionCategoryName': actionCategoryName,
      'actionSubCategoryName': actionSubCategoryName,
    };
  }

  factory BannerModel.fromMap(String id, Map<String, dynamic> map) {
    return BannerModel(
      id: id,
      type: bannerTypeFromString(map['type'] ?? 'static'),
      backgroundImageUrl: map['backgroundImageUrl'],
      finalImageUrl: map['finalImageUrl'] ?? '',
      elements: (map['elements'] as List<dynamic>? ?? [])
          .map((e) => BannerElementModel.fromMap(Map<String, dynamic>.from(e)))
          .toList(),
      isActive: map['isActive'] ?? true,
      order: map['order'] ?? 0,
      views: map['views'] ?? 0,
      clicks: map['clicks'] ?? 0,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate(),
      actionType: bannerActionTypeFromString(map['actionType'] ?? 'none'),
      actionProductId: map['actionProductId'],
      actionProductName: map['actionProductName'],
      actionCategoryName: map['actionCategoryName'],
      actionSubCategoryName: map['actionSubCategoryName'],
    );
  }
}
