// lib/features/coupons/controllers/coupon_design_controller.dart
//
// Two controllers: one streams the saved designs (list screen and the design
// picker inside Create Coupon both use it), the other backs the design editor.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../models/coupon_design_model.dart';
import '../repository/coupon_designs_repository.dart';

class CouponDesignListController extends GetxController {
  final CouponDesignsRepository _repository = CouponDesignsRepository();

  final RxList<CouponDesignModel> designs = <CouponDesignModel>[].obs;
  final RxBool isLoading = true.obs;
  StreamSubscription? _sub;

  @override
  void onInit() {
    super.onInit();
    _sub = _repository.streamDesigns().listen(
      (data) {
        designs.value = data;
        isLoading.value = false;
      },
      onError: (e) {
        isLoading.value = false;
        Get.snackbar('Error', 'Could not load designs: $e');
      },
    );
  }

  @override
  void onClose() {
    _sub?.cancel();
    super.onClose();
  }

  Future<void> deleteDesign(String id) async {
    try {
      await _repository.deleteDesign(id);
      Get.snackbar(
        'Deleted',
        'Design removed',
        backgroundColor: Colors.red.shade700,
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar('Error', 'Could not delete: $e');
    }
  }

  Future<void> duplicateDesign(CouponDesignModel design) async {
    try {
      await _repository.addDesign(
        design.copyWith(
          name: '${design.name} (Copy)',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );
      Get.snackbar(
        'Duplicated',
        'A copy of "${design.name}" was created',
        backgroundColor: Colors.blueGrey.shade700,
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar('Error', 'Could not duplicate: $e');
    }
  }
}

class CouponDesignEditorController extends GetxController {
  final CouponDesignsRepository _repository = CouponDesignsRepository();

  final nameController = TextEditingController();
  final badgeController = TextEditingController();

  final RxString name = ''.obs;
  final RxString badgeText = ''.obs;
  final RxString backgroundColorHex = '#1E1B3A'.obs;
  final RxString textColorHex = '#FFFFFF'.obs;
  final RxString accentColorHex = '#00F7FF'.obs;
  final RxString fontFamily = 'Default'.obs;
  final RxBool isBold = true.obs;

  final RxBool isSaving = false.obs;
  CouponDesignModel? editing;

  bool get isEditMode => editing != null;

  @override
  void onInit() {
    super.onInit();
    nameController.addListener(() => name.value = nameController.text);
    badgeController.addListener(
      () => badgeText.value = badgeController.text.toUpperCase(),
    );
  }

  void setEditing(CouponDesignModel design) {
    editing = design;
    nameController.text = design.name;
    badgeController.text = design.badgeText;
    backgroundColorHex.value = design.backgroundColorHex;
    textColorHex.value = design.textColorHex;
    accentColorHex.value = design.accentColorHex;
    fontFamily.value = design.fontFamily;
    isBold.value = design.isBold;
  }

  void reset() {
    editing = null;
    nameController.clear();
    badgeController.clear();
    backgroundColorHex.value = '#1E1B3A';
    textColorHex.value = '#FFFFFF';
    accentColorHex.value = '#00F7FF';
    fontFamily.value = 'Default';
    isBold.value = true;
  }

  /// Ready-made looks so the first design is one tap away.
  static const List<Map<String, String>> presets = [
    {
      'name': 'Midnight Neon',
      'bg': '#1E1B3A',
      'text': '#FFFFFF',
      'accent': '#00F7FF',
    },
    {
      'name': 'Sunset Gold',
      'bg': '#2B1B0E',
      'text': '#FFFFFF',
      'accent': '#FAC775',
    },
    {
      'name': 'Fresh Mint',
      'bg': '#0E2B22',
      'text': '#FFFFFF',
      'accent': '#2ECC71',
    },
    {
      'name': 'Royal Purple',
      'bg': '#241436',
      'text': '#FFFFFF',
      'accent': '#9B59B6',
    },
    {
      'name': 'Clean Light',
      'bg': '#F5F5F5',
      'text': '#111827',
      'accent': '#E74C3C',
    },
    {
      'name': 'Deep Ocean',
      'bg': '#0B2239',
      'text': '#FFFFFF',
      'accent': '#3498DB',
    },
  ];

  void applyPreset(Map<String, String> preset) {
    backgroundColorHex.value = preset['bg']!;
    textColorHex.value = preset['text']!;
    accentColorHex.value = preset['accent']!;
    if (nameController.text.trim().isEmpty) {
      nameController.text = preset['name']!;
    }
  }

  CouponDesignModel get preview => CouponDesignModel(
    id: editing?.id ?? '',
    name: name.value.trim().isEmpty ? 'Untitled design' : name.value.trim(),
    backgroundColorHex: backgroundColorHex.value,
    textColorHex: textColorHex.value,
    accentColorHex: accentColorHex.value,
    fontFamily: fontFamily.value,
    isBold: isBold.value,
    badgeText: badgeText.value.trim(),
    createdAt: editing?.createdAt ?? DateTime.now(),
    updatedAt: DateTime.now(),
  );

  Future<bool> save() async {
    if (isSaving.value) return false;
    if (name.value.trim().isEmpty) {
      Get.snackbar(
        'Name required',
        'Give this design a name so you can pick it later',
        backgroundColor: Colors.red.shade700,
        colorText: Colors.white,
      );
      return false;
    }

    isSaving.value = true;
    try {
      final model = preview;
      if (editing != null) {
        await _repository.updateDesign(model);
      } else {
        await _repository.addDesign(model);
      }
      return true;
    } catch (e) {
      Get.snackbar(
        'Error',
        'Could not save design: $e',
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
    nameController.dispose();
    badgeController.dispose();
    super.onClose();
  }
}
