import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import '../../data/profile_repository.dart';

class ProfileController extends GetxController {
  final ProfileRepository _repo = ProfileRepository();
  final ImagePicker _picker = ImagePicker();

  // Text Controllers
  final nameController = TextEditingController();
  final phoneController = TextEditingController();
  final emailController = TextEditingController();
  final roleController = TextEditingController();

  // Observables
  var isLoading = false.obs;
  var isEditing = false.obs; // Edit mode toggle
  var profileImageBase64 = ''.obs;

  @override
  void onInit() {
    super.onInit();
    loadProfile();
  }

  // Controller dispose hone par memory clear karo
  @override
  void onClose() {
    nameController.dispose();
    phoneController.dispose();
    emailController.dispose();
    roleController.dispose();
    super.onClose();
  }

  // --- 1. Load Data ---
  void loadProfile() async {
    try {
      isLoading(true);
      var data = await _repo.getAdminProfile();
      if (data != null) {
        nameController.text = data['name'] ?? '';
        phoneController.text = data['phone'] ?? '';
        emailController.text = data['email'] ?? '';
        roleController.text = data['role'] ?? 'Admin';

        if (data['profileImage'] != null) {
          profileImageBase64.value = data['profileImage'];
        }
      }
    } catch (e) {
      Get.snackbar("Error", "Could not load profile");
    } finally {
      isLoading(false);
    }
  }

  // --- 2. Pick Image ---
  Future<void> pickImage() async {
    if (!isEditing.value) return;

    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 50,
        maxWidth: 500,
      );

      if (image != null) {
        final bytes = await File(image.path).readAsBytes();
        String base64String = base64Encode(bytes);
        profileImageBase64.value = base64String;
      }
    } catch (e) {
      Get.snackbar("Error", "Image pick failed: $e");
    }
  }

  // --- 3. Toggle Edit ---
  void toggleEdit() {
    if (isEditing.value) {
      _saveChanges();
    } else {
      isEditing.value = true;
    }
  }

  // Helper to reset mode (Screen dispose pe call hoga)
  void resetEditMode() {
    isEditing.value = false;
  }

  // --- 4. Save Logic ---
  void _saveChanges() async {
    try {
      isLoading(true);

      // REPO Note: Make sure apka repo ab 'email' accept kare aur 'phone' ko ignore kare
      await _repo.updateProfile(
        name: nameController.text,
        // Phone number ab update nahi hoga requirement k mutabiq
        // phone: phoneController.text,
        // Email update ho sakta hai ab:
        // email: emailController.text, // (Apne Repo men ye parameter add karlena)
        phone: phoneController
            .text, // Filhal repo purana hai to phone bhej rahe hen taake crash na ho
        base64Image: profileImageBase64.value,
      );

      isEditing.value = false;
      Get.snackbar(
        "Success",
        "Profile Updated Successfully!",
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar(
        "Error",
        "Update failed: $e",
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoading(false);
    }
  }
}
