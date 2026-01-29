// File: lib/features/mlm/presentation/controllers/mlm_controller.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../data/models/mlm_models.dart';
import '../../data/models/mlm_global_settings_model.dart'; // Import Settings Model
import '../../data/repositories/mlm_repository.dart';

class MLMController extends GetxController {
  final MLMRepository _repository = MLMRepository();

  // Variables
  var isLoading = false.obs;
  var commissionLevels = <CommissionLevel>[].obs;

  // Settings for Calculation Display
  var globalSettings = Rxn<MLMGlobalSettings>();

  // --- RESTORED: Tree View Variable ---
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

      // 1. Fetch Levels
      var levels = await _repository.getCommissionLevels();
      commissionLevels.assignAll(levels);
      levelCountInputController.text = levels.length.toString();

      // 2. Fetch Global Settings (For Rank Breakdown Calculation)
      var settingsDoc = await FirebaseFirestore.instance
          .collection('admin_settings')
          .doc('mlm_variables')
          .get();

      if (settingsDoc.exists) {
        globalSettings.value = MLMGlobalSettings.fromMap(settingsDoc.data()!);
      } else {
        globalSettings.value = MLMGlobalSettings.defaults();
      }

      // --- RESTORED: Fetch Tree Structure ---
      var tree = await _repository.getMLMTree();
      rootNode.value = tree;
    } catch (e) {
      print("Error loading MLM data: $e");
    } finally {
      isLoading(false);
    }
  }

  // Update Total Levels Logic
  void updateTotalLevels(String value) {
    int? newCount = int.tryParse(value);
    if (newCount == null || newCount < 1 || newCount > 50) return;

    int currentCount = commissionLevels.length;

    if (newCount > currentCount) {
      for (int i = currentCount; i < newCount; i++) {
        commissionLevels.add(CommissionLevel(level: i + 1, percentage: 0.0));
      }
    } else if (newCount < currentCount) {
      commissionLevels.removeRange(newCount, currentCount);
    }
    commissionLevels.refresh();
  }

  // Update Percentage Logic
  void updateLevelPercentage(int index, String value) {
    double? val = double.tryParse(value);
    if (val != null) {
      commissionLevels[index].percentage = val;
      commissionLevels.refresh();
    }
  }

  // Save Config
  Future<void> saveConfig() async {
    if (totalCommission > 100) {
      Get.snackbar(
        "Error",
        "Total commission $totalCommission% exceeds 100%!",
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
      );
      return;
    }

    try {
      isLoading(true);
      await _repository.saveCommissions(commissionLevels);
      Get.snackbar(
        "Success",
        "Commissions structure updated successfully!",
        backgroundColor: Colors.green,
        colorText: Colors.white,
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
