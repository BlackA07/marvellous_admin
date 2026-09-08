// lib/features/coupons/models/coupon_model.dart
//
// One model for every coupon type. Firestore collection: `coupons`.
// Every money value (min purchase, fixed discount, caps) is ALWAYS stored in
// the base currency PKR; the client app converts it for display. That way a
// rule like "over PKR 1000" means the same thing in every country.

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ─── ENUMS ────────────────────────────────────────────────────────────────

/// What benefit the coupon gives.
enum CouponType {
  /// X% off the order or product.
  percentageDiscount,

  /// Flat PKR X off the order or product.
  fixedAmountDiscount,

  /// Delivery fee waived.
  freeDelivery,

  /// Discount on the registration / membership fee (percent or flat).
  registrationFeeDiscount,

  /// Buy anything (or a specific product) and get a chosen product free.
  freeProduct,

  /// Same product: buy X, get Y free.
  buyOneGetOne,
}

extension CouponTypeX on CouponType {
  String get id {
    switch (this) {
      case CouponType.percentageDiscount:
        return 'percentage_discount';
      case CouponType.fixedAmountDiscount:
        return 'fixed_amount_discount';
      case CouponType.freeDelivery:
        return 'free_delivery';
      case CouponType.registrationFeeDiscount:
        return 'registration_fee_discount';
      case CouponType.freeProduct:
        return 'free_product';
      case CouponType.buyOneGetOne:
        return 'buy_one_get_one';
    }
  }

  String get label {
    switch (this) {
      case CouponType.percentageDiscount:
        return 'Percentage Discount';
      case CouponType.fixedAmountDiscount:
        return 'Fixed Amount Off';
      case CouponType.freeDelivery:
        return 'Free Delivery';
      case CouponType.registrationFeeDiscount:
        return 'Registration Fee Discount';
      case CouponType.freeProduct:
        return 'Free Product (Buy & Get)';
      case CouponType.buyOneGetOne:
        return 'Buy One Get One (Same Product)';
    }
  }

  String get hint {
    switch (this) {
      case CouponType.percentageDiscount:
        return 'X% off the order or the selected products';
      case CouponType.fixedAmountDiscount:
        return 'Flat PKR amount off, auto-converted to any currency';
      case CouponType.freeDelivery:
        return 'Delivery fee waived, fully or up to a limit';
      case CouponType.registrationFeeDiscount:
        return 'Discount on the membership / registration fee';
      case CouponType.freeProduct:
        return 'A product you choose is given free with the purchase';
      case CouponType.buyOneGetOne:
        return 'Same product: buy X, get Y free';
    }
  }

  /// Registration-fee coupons are charged on the membership fee, not on a
  /// cart, so product scope, buy limits and cart rules simply do not apply.
  bool get appliesToCart => this != CouponType.registrationFeeDiscount;

  /// Which extra sections the form should show for this type.
  bool get usesProductScope => appliesToCart;
  bool get usesMinPurchase => appliesToCart;
  bool get usesCartRules => appliesToCart;

  IconData get icon {
    switch (this) {
      case CouponType.percentageDiscount:
        return Icons.percent_rounded;
      case CouponType.fixedAmountDiscount:
        return Icons.money_off_csred_rounded;
      case CouponType.freeDelivery:
        return Icons.local_shipping_outlined;
      case CouponType.registrationFeeDiscount:
        return Icons.card_membership_outlined;
      case CouponType.freeProduct:
        return Icons.card_giftcard_rounded;
      case CouponType.buyOneGetOne:
        return Icons.filter_2_rounded;
    }
  }

  static CouponType fromId(String? value) {
    return CouponType.values.firstWhere(
      (t) => t.id == value,
      orElse: () => CouponType.percentageDiscount,
    );
  }
}

/// Which products the coupon works on.
enum CouponScope { allProducts, specificProducts, specificCategories }

extension CouponScopeX on CouponScope {
  String get id {
    switch (this) {
      case CouponScope.allProducts:
        return 'all_products';
      case CouponScope.specificProducts:
        return 'specific_products';
      case CouponScope.specificCategories:
        return 'specific_categories';
    }
  }

  String get label {
    switch (this) {
      case CouponScope.allProducts:
        return 'All Products';
      case CouponScope.specificProducts:
        return 'Specific Products';
      case CouponScope.specificCategories:
        return 'Specific Categories';
    }
  }

  IconData get icon {
    switch (this) {
      case CouponScope.allProducts:
        return Icons.select_all_rounded;
      case CouponScope.specificProducts:
        return Icons.inventory_2_outlined;
      case CouponScope.specificCategories:
        return Icons.category_outlined;
    }
  }

  static CouponScope fromId(String? value) {
    return CouponScope.values.firstWhere(
      (s) => s.id == value,
      orElse: () => CouponScope.allProducts,
    );
  }
}

/// Which customers get the coupon.
enum CouponAudience {
  allCustomers,
  activeMembers,
  inactiveMembers,
  specificCustomers,
}

extension CouponAudienceX on CouponAudience {
  String get id {
    switch (this) {
      case CouponAudience.allCustomers:
        return 'all_customers';
      case CouponAudience.activeMembers:
        return 'active_members';
      case CouponAudience.inactiveMembers:
        return 'inactive_members';
      case CouponAudience.specificCustomers:
        return 'specific_customers';
    }
  }

  String get label {
    switch (this) {
      case CouponAudience.allCustomers:
        return 'All Customers';
      case CouponAudience.activeMembers:
        return 'All Active Members';
      case CouponAudience.inactiveMembers:
        return 'All Inactive Members';
      case CouponAudience.specificCustomers:
        return 'Specific Customers';
    }
  }

  IconData get icon {
    switch (this) {
      case CouponAudience.allCustomers:
        return Icons.groups_2_outlined;
      case CouponAudience.activeMembers:
        return Icons.verified_user_outlined;
      case CouponAudience.inactiveMembers:
        return Icons.person_off_outlined;
      case CouponAudience.specificCustomers:
        return Icons.person_search_outlined;
    }
  }

  static CouponAudience fromId(String? value) {
    return CouponAudience.values.firstWhere(
      (a) => a.id == value,
      orElse: () => CouponAudience.allCustomers,
    );
  }
}

/// Which locations the coupon is meant for.
enum CouponLocationScope { everywhere, specific }

extension CouponLocationScopeX on CouponLocationScope {
  String get id =>
      this == CouponLocationScope.everywhere ? 'everywhere' : 'specific';

  String get label => this == CouponLocationScope.everywhere
      ? 'Everywhere (Worldwide)'
      : 'Selected Countries / States / Cities';

  static CouponLocationScope fromId(String? value) =>
      value == 'specific'
      ? CouponLocationScope.specific
      : CouponLocationScope.everywhere;
}

/// Live status shown on the list screen and in the client app.
enum CouponStatus { live, scheduled, expired, paused, exhausted }

extension CouponStatusX on CouponStatus {
  String get label {
    switch (this) {
      case CouponStatus.live:
        return 'Live';
      case CouponStatus.scheduled:
        return 'Scheduled';
      case CouponStatus.expired:
        return 'Expired';
      case CouponStatus.paused:
        return 'Paused';
      case CouponStatus.exhausted:
        return 'Fully Used';
    }
  }

  Color get color {
    switch (this) {
      case CouponStatus.live:
        return const Color(0xFF2ECC71);
      case CouponStatus.scheduled:
        return const Color(0xFF3498DB);
      case CouponStatus.expired:
        return const Color(0xFFE74C3C);
      case CouponStatus.paused:
        return const Color(0xFF95A5A6);
      case CouponStatus.exhausted:
        return const Color(0xFFE67E22);
    }
  }
}

// ─── SMALL VALUE OBJECTS ──────────────────────────────────────────────────

/// One targeted location — a whole country, a whole state, or a single city.
/// The shape mirrors `ProductAvailabilityUnit` on purpose so the client app can
/// handle both the same way.
class CouponLocationUnit {
  final String level; // 'country' | 'state' | 'city'
  final String countryId;
  final String countryName;
  final String? stateId;
  final String? stateName;
  final String? cityId;
  final String? cityName;

  const CouponLocationUnit({
    required this.level,
    required this.countryId,
    required this.countryName,
    this.stateId,
    this.stateName,
    this.cityId,
    this.cityName,
  });

  String get key => [
    countryId,
    if (stateId != null) stateId,
    if (cityId != null) cityId,
  ].join('|');

  String get label => cityName ?? stateName ?? countryName;

  String get pathLabel => [
    countryName,
    if (stateName != null) stateName,
    if (cityName != null) cityName,
  ].join(' › ');

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

  factory CouponLocationUnit.fromMap(Map<String, dynamic> map) {
    return CouponLocationUnit(
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
      other is CouponLocationUnit && other.key == key;

  @override
  int get hashCode => key.hashCode;
}

/// A small product snapshot stored inside the coupon doc, so the client does
/// not have to fetch each product separately.
class CouponProductRef {
  final String id;
  final String name;
  final String image;
  final double price;
  final String category;

  const CouponProductRef({
    required this.id,
    required this.name,
    this.image = '',
    this.price = 0,
    this.category = '',
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'image': image,
    'price': price,
    'category': category,
  };

  factory CouponProductRef.fromMap(Map<String, dynamic> map) {
    return CouponProductRef(
      id: map['id']?.toString() ?? '',
      name: map['name']?.toString() ?? '',
      image: map['image']?.toString() ?? '',
      price: (map['price'] as num?)?.toDouble() ?? 0,
      category: map['category']?.toString() ?? '',
    );
  }

  @override
  bool operator ==(Object other) => other is CouponProductRef && other.id == id;

  @override
  int get hashCode => id.hashCode;
}

/// A small customer snapshot, used by specific-customer coupons.
class CouponCustomerRef {
  final String uid;
  final String name;
  final String email;
  final String phone;
  final String image;
  final bool isActiveMember;

  const CouponCustomerRef({
    required this.uid,
    required this.name,
    this.email = '',
    this.phone = '',
    this.image = '',
    this.isActiveMember = false,
  });

  CouponCustomerRef copyWith({String? image}) => CouponCustomerRef(
    uid: uid,
    name: name,
    email: email,
    phone: phone,
    image: image ?? this.image,
    isActiveMember: isActiveMember,
  );

  Map<String, dynamic> toMap() => {
    'uid': uid,
    'name': name,
    'email': email,
    'phone': phone,
    'image': image,
    'isActiveMember': isActiveMember,
  };

  factory CouponCustomerRef.fromMap(Map<String, dynamic> map) {
    return CouponCustomerRef(
      uid: map['uid']?.toString() ?? '',
      name: map['name']?.toString() ?? '',
      email: map['email']?.toString() ?? '',
      phone: map['phone']?.toString() ?? '',
      image: map['image']?.toString() ?? '',
      isActiveMember: map['isActiveMember'] == true,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is CouponCustomerRef && other.uid == uid;

  @override
  int get hashCode => uid.hashCode;
}

// ─── MAIN MODEL ───────────────────────────────────────────────────────────

class CouponModel {
  final String id;

  // Identity
  final String code;
  final String title;
  final String description;
  final String terms;

  // Benefit
  final CouponType type;

  /// percentage → %, fixedAmount → PKR, registrationFee → % or PKR
  final double discountValue;

  /// Upper cap on a percentage discount, in PKR. 0 = no cap.
  final double maxDiscountAmount;

  /// Whether the registration fee discount is a percentage or a flat amount.
  final bool registrationDiscountIsPercent;

  /// Upper limit on the waived delivery fee, in PKR. 0 = fully free.
  final double freeDeliveryCap;

  /// The gift given by a free-product coupon.
  final CouponProductRef? freeProduct;
  final int freeProductQty;

  /// BOGO: buy X, get Y free (same product).
  final int buyQuantity;
  final int getQuantity;

  // Product scope
  final CouponScope scope;
  final List<CouponProductRef> products;
  final List<String> categories;

  // Audience
  final CouponAudience audience;
  final List<CouponCustomerRef> customers;

  // Location
  final CouponLocationScope locationScope;
  final List<CouponLocationUnit> locations;

  // Conditions
  /// Minimum cart total in PKR. 0 = no minimum.
  final double minPurchaseAmount;
  final bool firstOrderOnly;
  final bool autoApply;

  // Limits
  final int usageLimitTotal; // 0 = unlimited
  final int usageLimitPerCustomer; // 0 = unlimited
  final int usedCount;

  // Schedule
  final DateTime startAt;
  final DateTime endAt;
  final bool isActive;

  // Appearance — the client app renders the coupon card with exactly this
  // styling. Copied from the chosen design so no extra lookup is needed.
  final String designId;
  final String designName;
  final String backgroundColorHex;
  final String textColorHex;
  final String accentColorHex;
  final String fontFamily;
  final bool isBold;
  final String badgeText;

  // Meta
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String createdBy;

  const CouponModel({
    required this.id,
    required this.code,
    required this.title,
    this.description = '',
    this.terms = '',
    this.type = CouponType.percentageDiscount,
    this.discountValue = 0,
    this.maxDiscountAmount = 0,
    this.registrationDiscountIsPercent = true,
    this.freeDeliveryCap = 0,
    this.freeProduct,
    this.freeProductQty = 1,
    this.buyQuantity = 1,
    this.getQuantity = 1,
    this.scope = CouponScope.allProducts,
    this.products = const [],
    this.categories = const [],
    this.audience = CouponAudience.allCustomers,
    this.customers = const [],
    this.locationScope = CouponLocationScope.everywhere,
    this.locations = const [],
    this.minPurchaseAmount = 0,
    this.firstOrderOnly = false,
    this.autoApply = false,
    this.usageLimitTotal = 0,
    this.usageLimitPerCustomer = 1,
    this.usedCount = 0,
    required this.startAt,
    required this.endAt,
    this.isActive = true,
    this.designId = '',
    this.designName = '',
    this.backgroundColorHex = '#1E1B3A',
    this.textColorHex = '#FFFFFF',
    this.accentColorHex = '#00F7FF',
    this.fontFamily = 'Default',
    this.isBold = true,
    this.badgeText = '',
    required this.createdAt,
    this.updatedAt,
    this.createdBy = '',
  });

  CouponModel copyWith({
    String? id,
    String? code,
    String? title,
    String? description,
    String? terms,
    CouponType? type,
    double? discountValue,
    double? maxDiscountAmount,
    bool? registrationDiscountIsPercent,
    double? freeDeliveryCap,
    CouponProductRef? freeProduct,
    bool clearFreeProduct = false,
    int? freeProductQty,
    int? buyQuantity,
    int? getQuantity,
    CouponScope? scope,
    List<CouponProductRef>? products,
    List<String>? categories,
    CouponAudience? audience,
    List<CouponCustomerRef>? customers,
    CouponLocationScope? locationScope,
    List<CouponLocationUnit>? locations,
    double? minPurchaseAmount,
    bool? firstOrderOnly,
    bool? autoApply,
    int? usageLimitTotal,
    int? usageLimitPerCustomer,
    int? usedCount,
    DateTime? startAt,
    DateTime? endAt,
    bool? isActive,
    String? designId,
    String? designName,
    String? backgroundColorHex,
    String? textColorHex,
    String? accentColorHex,
    String? fontFamily,
    bool? isBold,
    String? badgeText,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? createdBy,
  }) {
    return CouponModel(
      id: id ?? this.id,
      code: code ?? this.code,
      title: title ?? this.title,
      description: description ?? this.description,
      terms: terms ?? this.terms,
      type: type ?? this.type,
      discountValue: discountValue ?? this.discountValue,
      maxDiscountAmount: maxDiscountAmount ?? this.maxDiscountAmount,
      registrationDiscountIsPercent:
          registrationDiscountIsPercent ?? this.registrationDiscountIsPercent,
      freeDeliveryCap: freeDeliveryCap ?? this.freeDeliveryCap,
      freeProduct: clearFreeProduct ? null : (freeProduct ?? this.freeProduct),
      freeProductQty: freeProductQty ?? this.freeProductQty,
      buyQuantity: buyQuantity ?? this.buyQuantity,
      getQuantity: getQuantity ?? this.getQuantity,
      scope: scope ?? this.scope,
      products: products ?? this.products,
      categories: categories ?? this.categories,
      audience: audience ?? this.audience,
      customers: customers ?? this.customers,
      locationScope: locationScope ?? this.locationScope,
      locations: locations ?? this.locations,
      minPurchaseAmount: minPurchaseAmount ?? this.minPurchaseAmount,
      firstOrderOnly: firstOrderOnly ?? this.firstOrderOnly,
      autoApply: autoApply ?? this.autoApply,
      usageLimitTotal: usageLimitTotal ?? this.usageLimitTotal,
      usageLimitPerCustomer:
          usageLimitPerCustomer ?? this.usageLimitPerCustomer,
      usedCount: usedCount ?? this.usedCount,
      startAt: startAt ?? this.startAt,
      endAt: endAt ?? this.endAt,
      isActive: isActive ?? this.isActive,
      designId: designId ?? this.designId,
      designName: designName ?? this.designName,
      backgroundColorHex: backgroundColorHex ?? this.backgroundColorHex,
      textColorHex: textColorHex ?? this.textColorHex,
      accentColorHex: accentColorHex ?? this.accentColorHex,
      fontFamily: fontFamily ?? this.fontFamily,
      isBold: isBold ?? this.isBold,
      badgeText: badgeText ?? this.badgeText,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      createdBy: createdBy ?? this.createdBy,
    );
  }

  // ─── FIRESTORE ──────────────────────────────────────────────────────────

  Map<String, dynamic> toMap() {
    return {
      'code': code.toUpperCase(),
      'codeLower': code.toLowerCase(),
      'title': title,
      'description': description,
      'terms': terms,

      'type': type.id,
      'discountValue': discountValue,
      'maxDiscountAmount': maxDiscountAmount,
      'registrationDiscountIsPercent': registrationDiscountIsPercent,
      'freeDeliveryCap': freeDeliveryCap,
      'freeProduct': freeProduct?.toMap(),
      'freeProductQty': freeProductQty,
      'buyQuantity': buyQuantity,
      'getQuantity': getQuantity,

      'scope': scope.id,
      'products': products.map((p) => p.toMap()).toList(),
      'productIds': products.map((p) => p.id).toList(),
      'categories': categories,

      'audience': audience.id,
      'customers': customers.map((c) => c.toMap()).toList(),
      'customerIds': customers.map((c) => c.uid).toList(),

      'locationScope': locationScope.id,
      'locations': locations.map((l) => l.toMap()).toList(),
      'locationKeys': locations.map((l) => l.key).toList(),

      'minPurchaseAmount': minPurchaseAmount,
      'baseCurrency': 'PKR',
      'firstOrderOnly': firstOrderOnly,
      'autoApply': autoApply,

      'usageLimitTotal': usageLimitTotal,
      'usageLimitPerCustomer': usageLimitPerCustomer,
      'usedCount': usedCount,

      'startAt': Timestamp.fromDate(startAt),
      'endAt': Timestamp.fromDate(endAt),
      'isActive': isActive,

      'designId': designId,
      'designName': designName,
      'backgroundColorHex': backgroundColorHex,
      'textColorHex': textColorHex,
      'accentColorHex': accentColorHex,
      'fontFamily': fontFamily,
      'isBold': isBold,
      'badgeText': badgeText,

      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      'createdBy': createdBy,
    };
  }

  factory CouponModel.fromMap(String id, Map<String, dynamic> map) {
    List<T> listOf<T>(String key, T Function(Map<String, dynamic>) build) {
      final raw = map[key];
      if (raw is! List) return <T>[];
      return raw
          .whereType<Map>()
          .map((e) => build(Map<String, dynamic>.from(e)))
          .toList();
    }

    final freeProductRaw = map['freeProduct'];

    return CouponModel(
      id: id,
      code: map['code']?.toString() ?? '',
      title: map['title']?.toString() ?? '',
      description: map['description']?.toString() ?? '',
      terms: map['terms']?.toString() ?? '',

      type: CouponTypeX.fromId(map['type']?.toString()),
      discountValue: (map['discountValue'] as num?)?.toDouble() ?? 0,
      maxDiscountAmount: (map['maxDiscountAmount'] as num?)?.toDouble() ?? 0,
      registrationDiscountIsPercent:
          map['registrationDiscountIsPercent'] ?? true,
      freeDeliveryCap: (map['freeDeliveryCap'] as num?)?.toDouble() ?? 0,
      freeProduct: freeProductRaw is Map
          ? CouponProductRef.fromMap(Map<String, dynamic>.from(freeProductRaw))
          : null,
      freeProductQty: (map['freeProductQty'] as num?)?.toInt() ?? 1,
      buyQuantity: (map['buyQuantity'] as num?)?.toInt() ?? 1,
      getQuantity: (map['getQuantity'] as num?)?.toInt() ?? 1,

      scope: CouponScopeX.fromId(map['scope']?.toString()),
      products: listOf('products', CouponProductRef.fromMap),
      categories: (map['categories'] as List?)?.map((e) => '$e').toList() ?? [],

      audience: CouponAudienceX.fromId(map['audience']?.toString()),
      customers: listOf('customers', CouponCustomerRef.fromMap),

      locationScope: CouponLocationScopeX.fromId(
        map['locationScope']?.toString(),
      ),
      locations: listOf('locations', CouponLocationUnit.fromMap),

      minPurchaseAmount: (map['minPurchaseAmount'] as num?)?.toDouble() ?? 0,
      firstOrderOnly: map['firstOrderOnly'] ?? false,
      autoApply: map['autoApply'] ?? false,

      usageLimitTotal: (map['usageLimitTotal'] as num?)?.toInt() ?? 0,
      usageLimitPerCustomer:
          (map['usageLimitPerCustomer'] as num?)?.toInt() ?? 0,
      usedCount: (map['usedCount'] as num?)?.toInt() ?? 0,

      startAt: (map['startAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      endAt:
          (map['endAt'] as Timestamp?)?.toDate() ??
          DateTime.now().add(const Duration(days: 7)),
      isActive: map['isActive'] ?? true,

      designId: map['designId']?.toString() ?? '',
      designName: map['designName']?.toString() ?? '',
      backgroundColorHex: map['backgroundColorHex']?.toString() ?? '#1E1B3A',
      textColorHex: map['textColorHex']?.toString() ?? '#FFFFFF',
      accentColorHex: map['accentColorHex']?.toString() ?? '#00F7FF',
      fontFamily: map['fontFamily']?.toString() ?? 'Default',
      isBold: map['isBold'] ?? true,
      badgeText: map['badgeText']?.toString() ?? '',

      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate(),
      createdBy: map['createdBy']?.toString() ?? '',
    );
  }

  // ─── DERIVED / HELPERS ──────────────────────────────────────────────────

  bool get isExpired => DateTime.now().isAfter(endAt);
  bool get isScheduled => DateTime.now().isBefore(startAt);
  bool get isExhausted =>
      usageLimitTotal > 0 && usedCount >= usageLimitTotal;

  CouponStatus get status {
    if (!isActive) return CouponStatus.paused;
    if (isExpired) return CouponStatus.expired;
    if (isExhausted) return CouponStatus.exhausted;
    if (isScheduled) return CouponStatus.scheduled;
    return CouponStatus.live;
  }

  /// Redemptions left, or null when the coupon is unlimited.
  int? get remainingUses =>
      usageLimitTotal > 0 ? (usageLimitTotal - usedCount).clamp(0, 1 << 31) : null;

  /// The big line on the card, e.g. "20% OFF" or "FREE DELIVERY".
  String get headline {
    switch (type) {
      case CouponType.percentageDiscount:
        return '${_trim(discountValue)}% OFF';
      case CouponType.fixedAmountDiscount:
        return 'PKR ${_trim(discountValue)} OFF';
      case CouponType.freeDelivery:
        return 'FREE DELIVERY';
      case CouponType.registrationFeeDiscount:
        return registrationDiscountIsPercent
            ? '${_trim(discountValue)}% OFF REGISTRATION'
            : 'PKR ${_trim(discountValue)} OFF REGISTRATION';
      case CouponType.freeProduct:
        return freeProduct == null
            ? 'FREE PRODUCT'
            : 'FREE: ${freeProduct!.name.toUpperCase()}';
      case CouponType.buyOneGetOne:
        return 'BUY $buyQuantity GET $getQuantity FREE';
    }
  }

  /// One-line rule summary, used by both the list card and the preview.
  String get conditionSummary {
    final parts = <String>[];
    if (type.usesMinPurchase && minPurchaseAmount > 0) {
      parts.add('Min PKR ${_trim(minPurchaseAmount)}');
    }
    if (type.usesProductScope) parts.add(scopeSummary);
    parts.add(audienceSummary);
    parts.add(locationSummary);
    return parts.join(' · ');
  }

  String get scopeSummary {
    switch (scope) {
      case CouponScope.allProducts:
        return 'All products';
      case CouponScope.specificProducts:
        return '${products.length} product${products.length == 1 ? '' : 's'}';
      case CouponScope.specificCategories:
        return '${categories.length} categor${categories.length == 1 ? 'y' : 'ies'}';
    }
  }

  String get audienceSummary {
    if (audience == CouponAudience.specificCustomers) {
      return '${customers.length} customer${customers.length == 1 ? '' : 's'}';
    }
    return audience.label;
  }

  String get locationSummary {
    if (locationScope == CouponLocationScope.everywhere) return 'Worldwide';
    if (locations.isEmpty) return 'No location';
    if (locations.length == 1) return locations.first.pathLabel;
    return '${locations.length} locations';
  }

  static String _trim(double value) {
    if (value == value.roundToDouble()) return value.toStringAsFixed(0);
    return value.toStringAsFixed(2);
  }

  // ─── STYLING ────────────────────────────────────────────────────────────

  static Color colorFromHex(String hex, {Color fallback = Colors.white}) {
    var value = hex.replaceAll('#', '').trim();
    if (value.length == 6) value = 'FF$value';
    final parsed = int.tryParse(value, radix: 16);
    return parsed == null ? fallback : Color(parsed);
  }

  static String colorToHex(Color color) =>
      '#${color.toARGB32().toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}';

  Color get backgroundColor =>
      colorFromHex(backgroundColorHex, fallback: const Color(0xFF1E1B3A));
  Color get textColor => colorFromHex(textColorHex);
  Color get accentColor =>
      colorFromHex(accentColorHex, fallback: const Color(0xFF00F7FF));

  TextStyle textStyle({
    double size = 14,
    FontWeight? weight,
    Color? color,
    double height = 1.25,
  }) {
    final base = TextStyle(
      color: color ?? textColor,
      fontSize: size,
      fontWeight: weight ?? (isBold ? FontWeight.w800 : FontWeight.w500),
      height: height,
    );
    if (fontFamily == 'Default') return base;
    try {
      return GoogleFonts.getFont(fontFamily, textStyle: base);
    } catch (_) {
      return base;
    }
  }
}
