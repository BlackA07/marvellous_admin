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

      // 1. Load Global Settings Pehle (Total Rs aur Levels count ke liye)
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
        cashbackPercent.value = settings.cashbackPercent;
        isCashbackEnabled.value = settings.isCashbackEnabled;

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

      // 2. Load Levels from Firebase
      var levels = await _repository.getCommissionLevels();

      // Agar Firebase se levels aaye hain to unko use karo
      if (levels.isNotEmpty) {
        // Har level ka amount percentage se calculate karo
        for (var lvl in levels) {
          lvl.amount = (lvl.percentage * savedTotalDist) / 100;
        }
        commissionLevels.assignAll(levels);
      } else {
        // Agar Firebase empty hai to default levels banao
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

      // 3. Load MLM Tree
      var tree = await _repository.getMLMTree();
      rootNode.value = tree;

      print(
        "DATA LOADED: Levels=${commissionLevels.length}, TotalAmount=$savedTotalDist",
      );
    } catch (e) {
      print("ERROR LOADING DATA: $e");
      Get.snackbar(
        "Error",
        "Failed to load data: $e",
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
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
        final amount = (0.0 * totalDistAmount.value) / 100;
        commissionLevels.add(
          CommissionLevel(level: i + 1, percentage: 0, amount: amount),
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

      // Saare levels ka amount update karo
      for (var lvl in commissionLevels) {
        lvl.amount = (lvl.percentage * v) / 100;
      }

      commissionLevels.refresh();
      cashbackPercent.refresh();
    }
  }

  void updateLevelPercentage(int index, String value) {
    final p = double.tryParse(value) ?? 0.0;
    final total = totalDistAmount.value;

    commissionLevels[index].percentage = p;
    commissionLevels[index].amount = (p * total) / 100;

    commissionLevels.refresh();
  }

  void updateLevelByAmount(int index, double amount) {
    final total = totalDistAmount.value;
    if (total > 0) {
      commissionLevels[index].amount = amount;
      commissionLevels[index].percentage = (amount / total) * 100;
      commissionLevels.refresh();
    }
  }

  void toggleCashback(bool val) {
    isCashbackEnabled.value = val;
  }

  void updateCashbackPercent(String val) {
    final p = double.tryParse(val) ?? 0.0;
    cashbackPercent.value = p;
  }

  void updateCashbackByAmount(double amount) {
    final total = totalDistAmount.value;
    if (total > 0) {
      cashbackPercent.value = (amount / total) * 100;
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
      final total = totalDistAmount.value;

      // Pehle saare levels ka amount calculate karo
      for (var lvl in commissionLevels) {
        lvl.amount = (lvl.percentage * total) / 100;
      }

      // 1. Commission Levels save karo with amounts
      await _repository.saveCommissions(commissionLevels);

      // 2. Global Settings save karo
      Map<String, dynamic> settingsData = globalSettings.value?.toMap() ?? {};
      settingsData['cashbackPercent'] = cashbackPercent.value;
      settingsData['isCashbackEnabled'] = isCashbackEnabled.value;
      settingsData['totalDistAmount'] = total;
      settingsData['totalLevels'] = commissionLevels.length;

      await FirebaseFirestore.instance
          .collection('admin_settings')
          .doc('mlm_variables')
          .set(settingsData, SetOptions(merge: true));

      print(
        "CONFIG SAVED: Total=$total, Levels=${commissionLevels.length}, Cashback=${cashbackPercent.value}",
      );

      Get.snackbar(
        "Success",
        "All settings saved successfully!",
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );

      // Data reload karo taake confirm ho ke save hua hai
      await loadData();
    } catch (e) {
      print("ERROR SAVING CONFIG: $e");
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
