// lib/features/coupons/models/coupon_design_model.dart
//
// A saved look for coupon cards. Designs live on their own screen so the
// "Create Coupon" flow stays about rules only: pick a design, then set up the
// offer. Firestore collection: `coupon_designs`.

import 'package:cloud_firestore/cloud_firestore.dart';

import 'coupon_model.dart';

class CouponDesignModel {
  final String id;
  final String name;

  final String backgroundColorHex;
  final String textColorHex;
  final String accentColorHex;
  final String fontFamily;
  final bool isBold;

  /// Optional ribbon printed on the card, e.g. "LIMITED".
  final String badgeText;

  final DateTime createdAt;
  final DateTime? updatedAt;

  const CouponDesignModel({
    required this.id,
    required this.name,
    this.backgroundColorHex = '#1E1B3A',
    this.textColorHex = '#FFFFFF',
    this.accentColorHex = '#00F7FF',
    this.fontFamily = 'Default',
    this.isBold = true,
    this.badgeText = '',
    required this.createdAt,
    this.updatedAt,
  });

  CouponDesignModel copyWith({
    String? id,
    String? name,
    String? backgroundColorHex,
    String? textColorHex,
    String? accentColorHex,
    String? fontFamily,
    bool? isBold,
    String? badgeText,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CouponDesignModel(
      id: id ?? this.id,
      name: name ?? this.name,
      backgroundColorHex: backgroundColorHex ?? this.backgroundColorHex,
      textColorHex: textColorHex ?? this.textColorHex,
      accentColorHex: accentColorHex ?? this.accentColorHex,
      fontFamily: fontFamily ?? this.fontFamily,
      isBold: isBold ?? this.isBold,
      badgeText: badgeText ?? this.badgeText,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() => {
    'name': name,
    'nameLower': name.toLowerCase(),
    'backgroundColorHex': backgroundColorHex,
    'textColorHex': textColorHex,
    'accentColorHex': accentColorHex,
    'fontFamily': fontFamily,
    'isBold': isBold,
    'badgeText': badgeText,
    'createdAt': Timestamp.fromDate(createdAt),
    'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
  };

  factory CouponDesignModel.fromMap(String id, Map<String, dynamic> map) {
    return CouponDesignModel(
      id: id,
      name: map['name']?.toString() ?? 'Untitled design',
      backgroundColorHex: map['backgroundColorHex']?.toString() ?? '#1E1B3A',
      textColorHex: map['textColorHex']?.toString() ?? '#FFFFFF',
      accentColorHex: map['accentColorHex']?.toString() ?? '#00F7FF',
      fontFamily: map['fontFamily']?.toString() ?? 'Default',
      isBold: map['isBold'] ?? true,
      badgeText: map['badgeText']?.toString() ?? '',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  /// The look every coupon starts with when no design is picked.
  static CouponDesignModel get fallback => CouponDesignModel(
    id: '',
    name: 'Default',
    createdAt: DateTime.now(),
  );

  /// A throwaway coupon used only to render this design in a preview card.
  CouponModel sampleCoupon({
    CouponType type = CouponType.percentageDiscount,
    String code = 'SAMPLE20',
  }) {
    final now = DateTime.now();
    return CouponModel(
      id: '',
      code: code,
      title: name,
      description: 'This is how the coupon card will look in the app.',
      type: type,
      discountValue: 20,
      minPurchaseAmount: 1000,
      startAt: now,
      endAt: now.add(const Duration(days: 30)),
      backgroundColorHex: backgroundColorHex,
      textColorHex: textColorHex,
      accentColorHex: accentColorHex,
      fontFamily: fontFamily,
      isBold: isBold,
      badgeText: badgeText,
      createdAt: now,
    );
  }
}
