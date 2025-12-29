// File: lib/features/mlm/presentation/controllers/mlm_controller.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../data/models/mlm_models.dart';
import '../../data/repositories/mlm_repository.dart';

class MLMController extends GetxController {
  final MLMRepository _repository = MLMRepository();

  // Variables
  var isLoading = false.obs;
  var commissionLevels = <CommissionLevel>[].obs;
  var rootNode = Rxn<MLMNode>();

  // Text Controller for "Total Levels" Input
  final TextEditingController levelCountInputController =
      TextEditingController();

  // Computed Property for Total %
  double get totalCommission =>
      commissionLevels.fold(0, (sum, item) => sum + item.percentage);

  @override
  void onInit() {
    super.onInit();
    loadData();
  }

  void loadData() async {
    try {
      isLoading(true);
      var levels = await _repository.getCommissionLevels();
      var tree = await _repository.getMLMTree();

      commissionLevels.assignAll(levels);
      // TextField ko bhi update karo current levels k hisab se
      levelCountInputController.text = levels.length.toString();

      rootNode.value = tree;
    } finally {
      isLoading(false);
    }
  }

  // --- NEW LOGIC: Total Levels Change karna ---
  void updateTotalLevels(String value) {
    int? newCount = int.tryParse(value);

    // Validation: 1 se 50 k darmiyan ho
    if (newCount == null || newCount < 1 || newCount > 50) return;

    int currentCount = commissionLevels.length;

    if (newCount > currentCount) {
      // Add new levels
      for (int i = currentCount; i < newCount; i++) {
        commissionLevels.add(CommissionLevel(level: i + 1, percentage: 0.0));
      }
    } else if (newCount < currentCount) {
      // Remove extra levels
      commissionLevels.removeRange(newCount, currentCount);
    }

    commissionLevels.refresh();
  }

  // Update logic for specific level percentage
  void updateLevelPercentage(int index, String value) {
    double? val = double.tryParse(value);
    if (val != null) {
      commissionLevels[index].percentage = val;
      commissionLevels.refresh();
    }
  }

  // Save Button Logic
  Future<void> saveConfig() async {
    // Validation
    if (totalCommission > 100) {
      Get.snackbar(
        "Error",
        "Total commission $totalCommission% hogaya hai. Ye 100 se uper nahi jasakta!",
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    try {
      isLoading(true);
      // Firebase Repository Call
      await _repository.saveCommissions(commissionLevels);

      Get.snackbar(
        "Success",
        "Commissions structure updated successfully!",
        backgroundColor: Colors.green,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      Get.snackbar(
        "Error",
        "Failed to save: $e",
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoading(false);
    }
  }
}
