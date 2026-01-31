import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../data/models/mlm_models.dart';
import '../../data/models/mlm_global_settings_model.dart';
import '../../data/repositories/mlm_repository.dart';

class MLMController extends GetxController {
  final MLMRepository _repository = MLMRepository();

  // Variables
  var isLoading = false.obs;
  var commissionLevels = <CommissionLevel>[].obs;
  var globalSettings = Rxn<MLMGlobalSettings>();

  // Cashback Variables (Reactive)
  var cashbackPercent = 5.0.obs;
  var isCashbackEnabled = true.obs;

  var rootNode = Rxn<MLMNode>();
  final TextEditingController levelCountInputController =
      TextEditingController();

  // Computed Property: Total % = (Cashback if enabled) + (Sum of Levels)
  double get totalCommission {
    double cashback = isCashbackEnabled.value ? cashbackPercent.value : 0.0;
    double levelsTotal = commissionLevels.fold(
      0,
      (sum, item) => sum + item.percentage,
    );
    return cashback + levelsTotal;
  }

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

      // 2. Fetch Global Settings
      var settingsDoc = await FirebaseFirestore.instance
          .collection('admin_settings')
          .doc('mlm_variables')
          .get();

      if (settingsDoc.exists) {
        var settings = MLMGlobalSettings.fromMap(settingsDoc.data()!);
        globalSettings.value = settings;

        // Initialize Cashback inputs from Firebase Data
        cashbackPercent.value = settings.cashbackPercent;
        isCashbackEnabled.value = settings.isCashbackEnabled;
      } else {
        var defaults = MLMGlobalSettings.defaults();
        globalSettings.value = defaults;
        cashbackPercent.value = defaults.cashbackPercent;
        isCashbackEnabled.value = defaults.isCashbackEnabled;
      }

      var tree = await _repository.getMLMTree();
      rootNode.value = tree;
    } catch (e) {
      print("Error loading MLM data: $e");
    } finally {
      isLoading(false);
    }
  }

  // Update Logic
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

  void updateLevelPercentage(int index, String value) {
    double? val = double.tryParse(value);
    if (val != null) {
      commissionLevels[index].percentage = val;
      commissionLevels.refresh();
    }
  }

  void toggleCashback(bool val) {
    isCashbackEnabled.value = val;
  }

  void updateCashbackPercent(String val) {
    double? v = double.tryParse(val);
    if (v != null) {
      cashbackPercent.value = v;
    }
  }

  // Save Config
  Future<void> saveConfig() async {
    // 1. Validation Logic: Block Save if > 100%
    if (totalCommission > 100.0) {
      Get.snackbar(
        "Critical Error",
        "Total Allocation (${totalCommission.toStringAsFixed(1)}%) exceeds 100%!\nPlease reduce percentages before saving.",
        backgroundColor: Colors.red[800],
        colorText: Colors.white,
        duration: const Duration(seconds: 4),
        snackPosition: SnackPosition.TOP,
        icon: const Icon(Icons.error, color: Colors.white),
      );
      return; // Stop execution
    }

    try {
      isLoading(true);

      // 2. Save Levels
      await _repository.saveCommissions(commissionLevels);

      // 3. Save Cashback Settings to MLM Variables in Firebase
      // FIX: Manually updating the settings object before saving
      if (globalSettings.value != null) {
        globalSettings.value!.cashbackPercent = cashbackPercent.value;
        globalSettings.value!.isCashbackEnabled = isCashbackEnabled.value;

        await FirebaseFirestore.instance
            .collection('admin_settings')
            .doc('mlm_variables')
            .set(globalSettings.value!.toMap(), SetOptions(merge: true));
      } else {
        // Fallback if settings are null
        var newSettings = MLMGlobalSettings.defaults();
        newSettings.cashbackPercent = cashbackPercent.value;
        newSettings.isCashbackEnabled = isCashbackEnabled.value;

        await FirebaseFirestore.instance
            .collection('admin_settings')
            .doc('mlm_variables')
            .set(newSettings.toMap(), SetOptions(merge: true));
      }

      Get.snackbar(
        "Success",
        "Structure Saved! Total Allocation: ${totalCommission.toStringAsFixed(1)}%",
        backgroundColor: Colors.green[800],
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
