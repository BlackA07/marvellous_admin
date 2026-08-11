import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class AppUpdateController extends GetxController {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final _docRef = FirebaseFirestore.instance
      .collection('admin_settings')
      .doc('global_config');

  final versionCtrl = TextEditingController();
  final playStoreCtrl = TextEditingController();
  final appStoreCtrl = TextEditingController();

  var isLoading = true.obs;
  var isSaving = false.obs;
  var forceUpdate = false.obs;

  @override
  void onInit() {
    super.onInit();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      isLoading(true);
      final doc = await _docRef.get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        versionCtrl.text = (data['latestAppVersion'] ?? '').toString();
        playStoreCtrl.text = (data['playStoreUrl'] ?? '').toString();
        appStoreCtrl.text = (data['appStoreUrl'] ?? '').toString();
        forceUpdate.value = data['forceUpdate'] == true;
      }
    } catch (e) {
      Get.snackbar(
        "Error",
        "Could not load settings: $e",
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoading(false);
    }
  }

  void toggleForceUpdate(bool val) {
    forceUpdate.value = val;
  }

  Future<void> saveSettings() async {
    if (versionCtrl.text.trim().isEmpty) {
      Get.snackbar(
        "Error",
        "App Version is required (e.g. 1.0.1)",
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    try {
      isSaving(true);
      await _docRef.set({
        'latestAppVersion': versionCtrl.text.trim(),
        'playStoreUrl': playStoreCtrl.text.trim(),
        'appStoreUrl': appStoreCtrl.text.trim(),
        'forceUpdate': forceUpdate.value,
        'updateConfigUpdatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      Get.snackbar(
        "Saved!",
        "Update settings saved successfully.",
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
      isSaving(false);
    }
  }

  @override
  void onClose() {
    versionCtrl.dispose();
    playStoreCtrl.dispose();
    appStoreCtrl.dispose();
    super.onClose();
  }
}
