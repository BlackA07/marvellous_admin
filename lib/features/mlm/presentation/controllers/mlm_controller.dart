import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../data/models/mlm_models.dart';
import '../../data/models/mlm_global_settings_model.dart';
import '../../data/repositories/mlm_repository.dart';

class MLMController extends GetxController {
  final MLMRepository _repository = MLMRepository();

  var isLoading = false.obs;
  var commissionLevels = <CommissionLevel>[].obs;
  var globalSettings = Rxn<MLMGlobalSettings>();

  var cashbackPercent = 0.0.obs;
  var isCashbackEnabled = true.obs;
  var totalDistAmount = 0.0.obs;

  var rootNode = Rxn<MLMNode>();
  final TextEditingController levelCountInputController =
      TextEditingController();
  final TextEditingController totalDistAmountController =
      TextEditingController();

  // Rank Percentage Constants (Example Logic)
  double get bronzePercent => 10.0;
  double get silverPercent => 15.0;
  double get goldPercent => 20.0;
  double get diamondPercent => 25.0;

  double get totalCommission {
    double cashback = isCashbackEnabled.value ? cashbackPercent.value : 0.0;
    double levelsTotal = commissionLevels.fold(
      0.0,
      (sum, item) => sum + item.percentage,
    );
    return double.parse((cashback + levelsTotal).toStringAsFixed(4));
  }

  double get usedAmount {
    double cbAmt = isCashbackEnabled.value
        ? (cashbackPercent.value * totalDistAmount.value) / 100
        : 0.0;
    double lvAmt = commissionLevels.fold(0.0, (sum, item) {
      return sum + ((item.percentage * totalDistAmount.value) / 100);
    });
    return cbAmt + lvAmt;
  }

  @override
  void onInit() {
    super.onInit();
    loadData();
  }

  Future<void> loadData() async {
    try {
      isLoading(true);

      var settingsDoc = await FirebaseFirestore.instance
          .collection('admin_settings')
          .doc('mlm_variables')
          .get();

      double savedTotalDist = 0.0;
      int savedLevelCount = 11;

      if (settingsDoc.exists) {
        var settingsMap = settingsDoc.data()!;
        var settings = MLMGlobalSettings.fromMap(settingsMap);
        globalSettings.value = settings;

        // YAHAN FIX HAI: Purani value prioritize hogi
        cashbackPercent.value =
            (settingsMap['cashbackPercent'] ?? settings.cashbackPercent)
                .toDouble();
        isCashbackEnabled.value =
            settingsMap['isCashbackEnabled'] ?? settings.isCashbackEnabled;

        savedTotalDist = (settingsMap['totalDistAmount'] ?? 0.0).toDouble();
        savedLevelCount = (settingsMap['totalLevels'] ?? 11).toInt();

        totalDistAmount.value = savedTotalDist;
        totalDistAmountController.text = savedTotalDist.toStringAsFixed(0);
      } else {
        var defaults = MLMGlobalSettings.defaults();
        globalSettings.value = defaults;
        cashbackPercent.value = defaults.cashbackPercent;
        isCashbackEnabled.value = defaults.isCashbackEnabled;
      }

      var levels = await _repository.getCommissionLevels();

      if (levels.isNotEmpty) {
        for (var lvl in levels) {
          lvl.amount = (lvl.percentage * totalDistAmount.value) / 100;
        }
        commissionLevels.assignAll(levels);
      } else {
        commissionLevels.assignAll([
          CommissionLevel(
            level: 1,
            percentage: 25.0,
            amount: (25.0 * savedTotalDist) / 100,
          ),
          CommissionLevel(
            level: 2,
            percentage: 15.0,
            amount: (15.0 * savedTotalDist) / 100,
          ),
          CommissionLevel(
            level: 3,
            percentage: 10.0,
            amount: (10.0 * savedTotalDist) / 100,
          ),
          for (int i = 4; i <= savedLevelCount; i++)
            CommissionLevel(
              level: i,
              percentage: 3.0,
              amount: (3.0 * savedTotalDist) / 100,
            ),
        ]);
      }

      levelCountInputController.text = commissionLevels.length.toString();
      var tree = await _repository.getMLMTree();
      rootNode.value = tree;
    } catch (e) {
      print("ERROR LOADING DATA: $e");
    } finally {
      isLoading(false);
      commissionLevels.refresh();
      cashbackPercent.refresh();
    }
  }

  void updateTotalLevels(String value) {
    int? newCount = int.tryParse(value);
    if (newCount == null || newCount < 1 || newCount > 50) return;
    int current = commissionLevels.length;

    if (newCount > current) {
      for (int i = current; i < newCount; i++) {
        commissionLevels.add(
          CommissionLevel(level: i + 1, percentage: 0, amount: 0),
        );
      }
    } else {
      commissionLevels.removeRange(newCount, current);
    }
    commissionLevels.refresh();
  }

  void updateTotalDistAmount(String value) {
    final v = double.tryParse(value);
    if (v != null && v >= 0) {
      totalDistAmount.value = v;
      for (var lvl in commissionLevels) {
        lvl.amount = (lvl.percentage * v) / 100;
      }
      commissionLevels.refresh();
      cashbackPercent.refresh();
    }
  }

  void updateLevelPercentage(int index, String value) {
    final p = double.tryParse(value) ?? 0.0;
    commissionLevels[index].percentage = p;
    commissionLevels[index].amount = (p * totalDistAmount.value) / 100;
    commissionLevels.refresh();
  }

  void updateLevelByAmount(int index, double amount) {
    if (totalDistAmount.value > 0) {
      commissionLevels[index].amount = amount;
      commissionLevels[index].percentage =
          (amount / totalDistAmount.value) * 100;
      commissionLevels.refresh();
    }
  }

  void toggleCashback(bool val) => isCashbackEnabled.value = val;

  void updateCashbackPercent(String val) =>
      cashbackPercent.value = double.tryParse(val) ?? 0.0;

  void updateCashbackByAmount(double amount) {
    if (totalDistAmount.value > 0) {
      cashbackPercent.value = (amount / totalDistAmount.value) * 100;
    }
  }

  Future<void> saveConfig() async {
    if (totalCommission > 100.0001) {
      Get.snackbar(
        "Error",
        "Total allocation exceeds 100%",
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    try {
      isLoading(true);
      await _repository.saveCommissions(commissionLevels);

      Map<String, dynamic> settingsData = {
        'cashbackPercent': cashbackPercent.value,
        'isCashbackEnabled': isCashbackEnabled.value,
        'totalDistAmount': totalDistAmount.value,
        'totalLevels': commissionLevels.length,
      };

      await FirebaseFirestore.instance
          .collection('admin_settings')
          .doc('mlm_variables')
          .set(settingsData, SetOptions(merge: true));

      Get.snackbar(
        "Success",
        "Settings saved!",
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
      await loadData();
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

  @override
  void onClose() {
    levelCountInputController.dispose();
    totalDistAmountController.dispose();
    super.onClose();
  }
}
