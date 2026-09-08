// lib/features/coupons/controllers/coupon_list_controller.dart

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../models/coupon_model.dart';
import '../repository/coupons_repository.dart';

class CouponListController extends GetxController {
  final CouponsRepository _repository = CouponsRepository();

  final RxList<CouponModel> coupons = <CouponModel>[].obs;
  final RxBool isLoading = true.obs;

  // Filters
  final RxString searchQuery = ''.obs;
  final Rxn<CouponStatus> statusFilter = Rxn<CouponStatus>();
  final Rxn<CouponType> typeFilter = Rxn<CouponType>();

  StreamSubscription? _sub;

  @override
  void onInit() {
    super.onInit();
    _sub = _repository.streamCoupons().listen(
      (data) {
        coupons.value = data;
        isLoading.value = false;
      },
      onError: (e) {
        isLoading.value = false;
        Get.snackbar('Error', 'Could not load coupons: $e');
      },
    );
  }

  @override
  void onClose() {
    _sub?.cancel();
    super.onClose();
  }

  // ─── DERIVED LISTS ──────────────────────────────────────────────────────

  List<CouponModel> get filteredCoupons {
    final query = searchQuery.value.trim().toLowerCase();
    return coupons.where((c) {
      if (statusFilter.value != null && c.status != statusFilter.value) {
        return false;
      }
      if (typeFilter.value != null && c.type != typeFilter.value) return false;
      if (query.isEmpty) return true;
      return c.code.toLowerCase().contains(query) ||
          c.title.toLowerCase().contains(query) ||
          c.description.toLowerCase().contains(query) ||
          c.type.label.toLowerCase().contains(query);
    }).toList();
  }

  int countOf(CouponStatus status) =>
      coupons.where((c) => c.status == status).length;

  int get liveCount => countOf(CouponStatus.live);
  int get scheduledCount => countOf(CouponStatus.scheduled);
  int get expiredCount => countOf(CouponStatus.expired);
  int get pausedCount => countOf(CouponStatus.paused);
  int get totalRedemptions =>
      coupons.fold<int>(0, (sum, c) => sum + c.usedCount);

  bool get hasActiveFilters =>
      statusFilter.value != null ||
      typeFilter.value != null ||
      searchQuery.value.trim().isNotEmpty;

  void clearFilters() {
    statusFilter.value = null;
    typeFilter.value = null;
    searchQuery.value = '';
  }

  // ─── ACTIONS ────────────────────────────────────────────────────────────

  Future<void> toggleActive(CouponModel coupon) async {
    try {
      await _repository.updateCoupon(
        coupon.copyWith(isActive: !coupon.isActive, updatedAt: DateTime.now()),
      );
    } catch (e) {
      Get.snackbar('Error', 'Could not update the status: $e');
    }
  }

  Future<void> deleteCoupon(String id) async {
    try {
      await _repository.deleteCoupon(id);
      Get.snackbar(
        'Deleted',
        'Coupon removed',
        backgroundColor: Colors.red.shade700,
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar('Error', 'Could not delete: $e');
    }
  }

  /// A new coupon with the same settings; only the code and usage reset.
  Future<void> duplicateCoupon(CouponModel coupon) async {
    try {
      var code = '${coupon.code}-COPY';
      var attempt = 1;
      while (await _repository.isCodeTaken(code)) {
        attempt++;
        code = '${coupon.code}-COPY$attempt';
      }

      await _repository.addCoupon(
        coupon.copyWith(
          code: code,
          title: '${coupon.title} (Copy)',
          usedCount: 0,
          isActive: false,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );
      Get.snackbar(
        'Duplicated',
        'Copy created as $code — it starts paused',
        backgroundColor: Colors.blueGrey.shade700,
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar('Error', 'Could not duplicate: $e');
    }
  }
}
