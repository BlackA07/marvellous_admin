// lib/features/coupons/controllers/coupon_editor_controller.dart
//
// Drives the Create / Edit Coupon screen. Every text field has its own
// TextEditingController whose listener writes straight into an Rx value, so
// the live preview updates on each keystroke.
//
// Styling is NOT edited here — it comes from the design picked at the top of
// the screen (see CouponDesignModel). The chosen design's colors are copied
// onto the coupon so the client app needs no extra lookup.

import 'dart:math';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../products/services/currency_service.dart';
import '../models/coupon_design_model.dart';
import '../models/coupon_model.dart';
import '../repository/coupon_designs_repository.dart';
import '../repository/coupons_repository.dart';

class CouponEditorController extends GetxController {
  final CouponsRepository _repository = CouponsRepository();
  final CouponDesignsRepository _designsRepository = CouponDesignsRepository();

  // ─── TEXT FIELDS ────────────────────────────────────────────────────────
  final codeController = TextEditingController();
  final titleController = TextEditingController();
  final descriptionController = TextEditingController();
  final termsController = TextEditingController();
  final discountValueController = TextEditingController();
  final maxDiscountController = TextEditingController();
  final freeDeliveryCapController = TextEditingController();
  final minPurchaseController = TextEditingController();
  final totalLimitController = TextEditingController();
  final perCustomerLimitController = TextEditingController();

  // ─── LIVE STATE ─────────────────────────────────────────────────────────
  final RxString code = ''.obs;
  final RxString title = ''.obs;
  final RxString description = ''.obs;
  final RxString terms = ''.obs;

  final Rx<CouponType> type = CouponType.percentageDiscount.obs;
  final RxDouble discountValue = 0.0.obs;
  final RxDouble maxDiscountAmount = 0.0.obs;
  final RxBool registrationDiscountIsPercent = true.obs;
  final RxDouble freeDeliveryCap = 0.0.obs;

  final Rxn<CouponProductRef> freeProduct = Rxn<CouponProductRef>();
  final RxInt freeProductQty = 1.obs;
  final RxInt buyQuantity = 1.obs;
  final RxInt getQuantity = 1.obs;

  final Rx<CouponScope> scope = CouponScope.allProducts.obs;
  final RxList<CouponProductRef> selectedProducts = <CouponProductRef>[].obs;
  final RxList<String> selectedCategories = <String>[].obs;

  final Rx<CouponAudience> audience = CouponAudience.allCustomers.obs;
  final RxList<CouponCustomerRef> selectedCustomers =
      <CouponCustomerRef>[].obs;

  final Rx<CouponLocationScope> locationScope =
      CouponLocationScope.everywhere.obs;
  final RxList<CouponLocationUnit> selectedLocations =
      <CouponLocationUnit>[].obs;

  final RxDouble minPurchaseAmount = 0.0.obs;
  final RxBool firstOrderOnly = false.obs;
  final RxBool autoApply = false.obs;

  final RxInt usageLimitTotal = 0.obs;
  final RxInt usageLimitPerCustomer = 1.obs;

  final Rx<DateTime> startAt = DateTime.now().obs;
  final Rx<DateTime> endAt = DateTime.now().add(const Duration(days: 7)).obs;
  final RxBool isActive = true.obs;

  // ─── DESIGN (chosen, not edited, on this screen) ────────────────────────
  final RxString designId = ''.obs;
  final RxString designName = ''.obs;
  final RxString backgroundColorHex = '#1E1B3A'.obs;
  final RxString textColorHex = '#FFFFFF'.obs;
  final RxString accentColorHex = '#00F7FF'.obs;
  final RxString fontFamily = 'Default'.obs;
  final RxBool isBold = true.obs;
  final RxString badgeText = ''.obs;

  final RxList<CouponDesignModel> allDesigns = <CouponDesignModel>[].obs;
  final RxBool isLoadingDesigns = false.obs;

  // ─── PICKER DATA (lazy loaded) ──────────────────────────────────────────
  final RxList<CouponProductRef> allProducts = <CouponProductRef>[].obs;
  final RxList<String> allCategories = <String>[].obs;
  final RxList<CouponCustomerRef> allCustomers = <CouponCustomerRef>[].obs;
  final RxBool isLoadingProducts = false.obs;
  final RxBool isLoadingCategories = false.obs;
  final RxBool isLoadingCustomers = false.obs;

  // ─── MISC ───────────────────────────────────────────────────────────────
  final RxBool isSaving = false.obs;
  final RxBool ratesReady = false.obs;
  CouponModel? editing;

  bool get isEditMode => editing != null;

  @override
  void onInit() {
    super.onInit();
    _wireTextListeners();
    _loadRates();
    ensureDesigns();
  }

  void _wireTextListeners() {
    codeController.addListener(
      () => code.value = codeController.text.toUpperCase(),
    );
    titleController.addListener(() => title.value = titleController.text);
    descriptionController.addListener(
      () => description.value = descriptionController.text,
    );
    termsController.addListener(() => terms.value = termsController.text);

    discountValueController.addListener(
      () => discountValue.value = _toDouble(discountValueController.text),
    );
    maxDiscountController.addListener(
      () => maxDiscountAmount.value = _toDouble(maxDiscountController.text),
    );
    freeDeliveryCapController.addListener(
      () => freeDeliveryCap.value = _toDouble(freeDeliveryCapController.text),
    );
    minPurchaseController.addListener(
      () => minPurchaseAmount.value = _toDouble(minPurchaseController.text),
    );
    totalLimitController.addListener(
      () => usageLimitTotal.value = _toInt(totalLimitController.text),
    );
    perCustomerLimitController.addListener(
      () =>
          usageLimitPerCustomer.value = _toInt(perCustomerLimitController.text),
    );
  }

  Future<void> _loadRates() async {
    await CurrencyService.ensureRates();
    ratesReady.value = CurrencyService.hasRates;
  }

  static double _toDouble(String raw) =>
      double.tryParse(raw.trim().replaceAll(',', '')) ?? 0;

  static int _toInt(String raw) => int.tryParse(raw.trim()) ?? 0;

  // ─── DESIGNS ────────────────────────────────────────────────────────────

  Future<void> ensureDesigns({bool force = false}) async {
    if (!force && allDesigns.isNotEmpty) return;
    try {
      isLoadingDesigns.value = true;
      allDesigns.assignAll(await _designsRepository.fetchDesigns());
      // Editing an old coupon whose design was deleted, or a brand new coupon:
      // fall back to the first saved design so the card never looks unstyled.
      if (designId.value.isEmpty && allDesigns.isNotEmpty && !isEditMode) {
        applyDesign(allDesigns.first);
      }
    } catch (e) {
      Get.snackbar('Error', 'Could not load designs: $e');
    } finally {
      isLoadingDesigns.value = false;
    }
  }

  void applyDesign(CouponDesignModel design) {
    designId.value = design.id;
    designName.value = design.name;
    backgroundColorHex.value = design.backgroundColorHex;
    textColorHex.value = design.textColorHex;
    accentColorHex.value = design.accentColorHex;
    fontFamily.value = design.fontFamily;
    isBold.value = design.isBold;
    badgeText.value = design.badgeText;
  }

  // ─── EDIT MODE ──────────────────────────────────────────────────────────

  void setEditing(CouponModel coupon) {
    editing = coupon;

    codeController.text = coupon.code;
    titleController.text = coupon.title;
    descriptionController.text = coupon.description;
    termsController.text = coupon.terms;
    discountValueController.text = _num(coupon.discountValue);
    maxDiscountController.text = coupon.maxDiscountAmount > 0
        ? _num(coupon.maxDiscountAmount)
        : '';
    freeDeliveryCapController.text = coupon.freeDeliveryCap > 0
        ? _num(coupon.freeDeliveryCap)
        : '';
    minPurchaseController.text = coupon.minPurchaseAmount > 0
        ? _num(coupon.minPurchaseAmount)
        : '';
    totalLimitController.text = coupon.usageLimitTotal > 0
        ? '${coupon.usageLimitTotal}'
        : '';
    perCustomerLimitController.text = coupon.usageLimitPerCustomer > 0
        ? '${coupon.usageLimitPerCustomer}'
        : '';

    type.value = coupon.type;
    registrationDiscountIsPercent.value = coupon.registrationDiscountIsPercent;
    freeProduct.value = coupon.freeProduct;
    freeProductQty.value = coupon.freeProductQty;
    buyQuantity.value = coupon.buyQuantity;
    getQuantity.value = coupon.getQuantity;

    scope.value = coupon.scope;
    selectedProducts.assignAll(coupon.products);
    selectedCategories.assignAll(coupon.categories);

    audience.value = coupon.audience;
    selectedCustomers.assignAll(coupon.customers);

    locationScope.value = coupon.locationScope;
    selectedLocations.assignAll(coupon.locations);

    firstOrderOnly.value = coupon.firstOrderOnly;
    autoApply.value = coupon.autoApply;

    startAt.value = coupon.startAt;
    endAt.value = coupon.endAt;
    isActive.value = coupon.isActive;

    designId.value = coupon.designId;
    designName.value = coupon.designName;
    backgroundColorHex.value = coupon.backgroundColorHex;
    textColorHex.value = coupon.textColorHex;
    accentColorHex.value = coupon.accentColorHex;
    fontFamily.value = coupon.fontFamily;
    isBold.value = coupon.isBold;
    badgeText.value = coupon.badgeText;
  }

  /// Clears the form after a successful create (add mode only).
  void reset() {
    editing = null;
    for (final c in [
      codeController,
      titleController,
      descriptionController,
      termsController,
      discountValueController,
      maxDiscountController,
      freeDeliveryCapController,
      minPurchaseController,
      totalLimitController,
    ]) {
      c.clear();
    }
    perCustomerLimitController.text = '1';

    type.value = CouponType.percentageDiscount;
    registrationDiscountIsPercent.value = true;
    freeProduct.value = null;
    freeProductQty.value = 1;
    buyQuantity.value = 1;
    getQuantity.value = 1;

    scope.value = CouponScope.allProducts;
    selectedProducts.clear();
    selectedCategories.clear();

    audience.value = CouponAudience.allCustomers;
    selectedCustomers.clear();

    locationScope.value = CouponLocationScope.everywhere;
    selectedLocations.clear();

    firstOrderOnly.value = false;
    autoApply.value = false;

    startAt.value = DateTime.now();
    endAt.value = DateTime.now().add(const Duration(days: 7));
    isActive.value = true;
    // The picked design stays — the next coupon usually keeps the same look.
  }

  static String _num(double value) => value == value.roundToDouble()
      ? value.toStringAsFixed(0)
      : value.toString();

  // ─── CODE HELPERS ───────────────────────────────────────────────────────

  static const _codeAlphabet = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';

  /// Suggests a code that matches the type, e.g. "SAVE20-K4P9".
  void generateCode() {
    final rand = Random();
    final suffix = List.generate(
      4,
      (_) => _codeAlphabet[rand.nextInt(_codeAlphabet.length)],
    ).join();

    String prefix;
    switch (type.value) {
      case CouponType.percentageDiscount:
        prefix = discountValue.value > 0
            ? 'SAVE${discountValue.value.toStringAsFixed(0)}'
            : 'SAVE';
        break;
      case CouponType.fixedAmountDiscount:
        prefix = 'FLAT';
        break;
      case CouponType.freeDelivery:
        prefix = 'FREESHIP';
        break;
      case CouponType.registrationFeeDiscount:
        prefix = 'JOIN';
        break;
      case CouponType.freeProduct:
        prefix = 'GIFT';
        break;
      case CouponType.buyOneGetOne:
        prefix = 'BOGO';
        break;
    }
    codeController.text = '$prefix-$suffix';
  }

  // ─── PICKER DATA LOADERS ────────────────────────────────────────────────

  Future<void> ensureProducts({bool force = false}) async {
    if (!force && allProducts.isNotEmpty) return;
    try {
      isLoadingProducts.value = true;
      allProducts.assignAll(await _repository.fetchProducts());
    } catch (e) {
      Get.snackbar('Error', 'Could not load products: $e');
    } finally {
      isLoadingProducts.value = false;
    }
  }

  Future<void> ensureCategories({bool force = false}) async {
    if (!force && allCategories.isNotEmpty) return;
    try {
      isLoadingCategories.value = true;
      allCategories.assignAll(await _repository.fetchCategoryNames());
    } catch (e) {
      Get.snackbar('Error', 'Could not load categories: $e');
    } finally {
      isLoadingCategories.value = false;
    }
  }

  Future<void> ensureCustomers({bool force = false}) async {
    if (!force && allCustomers.isNotEmpty) return;
    try {
      isLoadingCustomers.value = true;
      allCustomers.assignAll(await _repository.fetchCustomers());
    } catch (e) {
      Get.snackbar('Error', 'Could not load customers: $e');
    } finally {
      isLoadingCustomers.value = false;
    }
  }

  // ─── CURRENCY PREVIEW ───────────────────────────────────────────────────

  /// Shows a PKR amount in a few common currencies, so it is obvious what
  /// "PKR 1000" means for a customer shopping in USD or GBP.
  List<String> convertedPreview(double pkrAmount) {
    if (pkrAmount <= 0 || !CurrencyService.hasRates) return const [];
    const codes = ['USD', 'GBP', 'EUR', 'AED', 'SAR', 'INR'];
    return codes
        .map((c) => CurrencyService.formatted(pkrAmount, c))
        .whereType<String>()
        .toList();
  }

  // ─── SCHEDULE HELPERS ───────────────────────────────────────────────────

  Duration get validityDuration => endAt.value.difference(startAt.value);

  void applyQuickDuration(Duration duration) {
    endAt.value = startAt.value.add(duration);
  }

  void setStart(DateTime value) {
    startAt.value = value;
    if (!endAt.value.isAfter(value)) {
      endAt.value = value.add(const Duration(days: 7));
    }
  }

  void setEnd(DateTime value) => endAt.value = value;

  // ─── SELECTION HELPERS ──────────────────────────────────────────────────

  void toggleCategory(String category) {
    selectedCategories.contains(category)
        ? selectedCategories.remove(category)
        : selectedCategories.add(category);
  }

  // ─── PREVIEW MODEL ──────────────────────────────────────────────────────

  /// The exact model that will be saved. Fields that do not apply to the
  /// chosen type are zeroed out here, so a fee coupon can never carry stale
  /// cart rules from an earlier selection.
  CouponModel get preview {
    final t = type.value;
    final cartBased = t.appliesToCart;

    return CouponModel(
      id: editing?.id ?? '',
      code: code.value.trim().isEmpty ? 'YOUR-CODE' : code.value.trim(),
      title: title.value.trim(),
      description: description.value.trim(),
      terms: terms.value.trim(),
      type: t,
      discountValue: discountValue.value,
      maxDiscountAmount: t == CouponType.percentageDiscount
          ? maxDiscountAmount.value
          : 0,
      registrationDiscountIsPercent: registrationDiscountIsPercent.value,
      freeDeliveryCap: t == CouponType.freeDelivery ? freeDeliveryCap.value : 0,
      freeProduct: t == CouponType.freeProduct ? freeProduct.value : null,
      freeProductQty: freeProductQty.value,
      buyQuantity: buyQuantity.value,
      getQuantity: getQuantity.value,

      scope: cartBased ? scope.value : CouponScope.allProducts,
      products: cartBased && scope.value == CouponScope.specificProducts
          ? List<CouponProductRef>.from(selectedProducts)
          : const [],
      categories: cartBased && scope.value == CouponScope.specificCategories
          ? List<String>.from(selectedCategories)
          : const [],

      audience: audience.value,
      customers: audience.value == CouponAudience.specificCustomers
          ? List<CouponCustomerRef>.from(selectedCustomers)
          : const [],

      locationScope: locationScope.value,
      locations: locationScope.value == CouponLocationScope.specific
          ? List<CouponLocationUnit>.from(selectedLocations)
          : const [],

      minPurchaseAmount: cartBased ? minPurchaseAmount.value : 0,
      firstOrderOnly: cartBased && firstOrderOnly.value,
      autoApply: cartBased && autoApply.value,

      usageLimitTotal: usageLimitTotal.value,
      usageLimitPerCustomer: usageLimitPerCustomer.value,
      usedCount: editing?.usedCount ?? 0,

      startAt: startAt.value,
      endAt: endAt.value,
      isActive: isActive.value,

      designId: designId.value,
      designName: designName.value,
      backgroundColorHex: backgroundColorHex.value,
      textColorHex: textColorHex.value,
      accentColorHex: accentColorHex.value,
      fontFamily: fontFamily.value,
      isBold: isBold.value,
      badgeText: badgeText.value.trim(),

      createdAt: editing?.createdAt ?? DateTime.now(),
      updatedAt: DateTime.now(),
      createdBy:
          editing?.createdBy ?? (FirebaseAuth.instance.currentUser?.uid ?? ''),
    );
  }

  // ─── VALIDATION ─────────────────────────────────────────────────────────

  /// The first problem found, or null when the coupon is ready to publish.
  String? validate() {
    final trimmedCode = code.value.trim();
    if (trimmedCode.length < 3) {
      return 'Coupon code must be at least 3 characters';
    }
    if (!RegExp(r'^[A-Z0-9_-]+$').hasMatch(trimmedCode)) {
      return 'Code can only use A-Z, 0-9, - and _';
    }
    if (title.value.trim().isEmpty) return 'Add a title for this coupon';

    switch (type.value) {
      case CouponType.percentageDiscount:
        if (discountValue.value <= 0 || discountValue.value > 100) {
          return 'Discount percentage must be between 1 and 100';
        }
        break;
      case CouponType.fixedAmountDiscount:
        if (discountValue.value <= 0) {
          return 'Enter the flat discount amount in PKR';
        }
        break;
      case CouponType.registrationFeeDiscount:
        if (discountValue.value <= 0) {
          return 'Enter the registration fee discount value';
        }
        if (registrationDiscountIsPercent.value && discountValue.value > 100) {
          return 'Registration discount cannot be more than 100%';
        }
        break;
      case CouponType.freeProduct:
        if (freeProduct.value == null) {
          return 'Choose the product that will be given free';
        }
        break;
      case CouponType.buyOneGetOne:
        if (buyQuantity.value < 1 || getQuantity.value < 1) {
          return 'Buy and Get quantities must be at least 1';
        }
        break;
      case CouponType.freeDelivery:
        break;
    }

    if (type.value.usesProductScope) {
      if (scope.value == CouponScope.specificProducts &&
          selectedProducts.isEmpty) {
        return 'Select at least one product';
      }
      if (scope.value == CouponScope.specificCategories &&
          selectedCategories.isEmpty) {
        return 'Select at least one category';
      }
    }
    if (audience.value == CouponAudience.specificCustomers &&
        selectedCustomers.isEmpty) {
      return 'Select at least one customer';
    }
    if (locationScope.value == CouponLocationScope.specific &&
        selectedLocations.isEmpty) {
      return 'Select at least one country, state or city';
    }
    if (!endAt.value.isAfter(startAt.value)) {
      return 'The end date must come after the start date';
    }
    if (usageLimitTotal.value < 0 || usageLimitPerCustomer.value < 0) {
      return 'Usage limits cannot be negative';
    }
    return null;
  }

  // ─── SAVE ───────────────────────────────────────────────────────────────

  Future<bool> save() async {
    if (isSaving.value) return false;

    final error = validate();
    if (error != null) {
      Get.snackbar(
        'Incomplete',
        error,
        backgroundColor: Colors.red.shade700,
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );
      return false;
    }

    isSaving.value = true;
    try {
      final taken = await _repository.isCodeTaken(
        code.value.trim(),
        ignoreId: editing?.id,
      );
      if (taken) {
        Get.snackbar(
          'Duplicate code',
          'This coupon code already exists — pick another one',
          backgroundColor: Colors.red.shade700,
          colorText: Colors.white,
        );
        return false;
      }

      final model = preview;
      if (editing != null) {
        await _repository.updateCoupon(model);
      } else {
        await _repository.addCoupon(model);
      }
      return true;
    } catch (e) {
      Get.snackbar(
        'Error',
        'Could not save coupon: $e',
        backgroundColor: Colors.red.shade700,
        colorText: Colors.white,
      );
      return false;
    } finally {
      isSaving.value = false;
    }
  }

  @override
  void onClose() {
    codeController.dispose();
    titleController.dispose();
    descriptionController.dispose();
    termsController.dispose();
    discountValueController.dispose();
    maxDiscountController.dispose();
    freeDeliveryCapController.dispose();
    minPurchaseController.dispose();
    totalLimitController.dispose();
    perCustomerLimitController.dispose();
    super.onClose();
  }
}
