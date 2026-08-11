import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'dart:typed_data';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:cloudinary_public/cloudinary_public.dart';
import '../models/category_model.dart';

class CategoryController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ✅ Cloudinary Setup
  final cloudinary = CloudinaryPublic('dzluvpc34', 'marvellous', cache: false);

  // Observables
  var categories = <CategoryModel>[].obs;
  var isLoading = false.obs;
  var isUploading = false.obs; // Image upload loading state
  var selectedCategory = Rxn<CategoryModel>();
  var tempSelectedImageBytes = Rxn<Uint8List>();

  @override
  void onInit() {
    super.onInit();
    if (FirebaseAuth.instance.currentUser != null) {
      fetchCategories();
    }
  }

  // Fetch Categories Real-time
  void fetchCategories() {
    isLoading.value = true;
    _firestore.collection('categories').snapshots().listen((snapshot) {
      categories.value = snapshot.docs
          .map((doc) => CategoryModel.fromMap(doc.data(), doc.id))
          .toList();

      if (selectedCategory.value != null) {
        var updatedCat = categories.firstWhere(
          (c) => c.id == selectedCategory.value!.id,
          orElse: () => selectedCategory.value!,
        );
        if (categories.any((c) => c.id == updatedCat.id)) {
          selectedCategory.value = updatedCat;
        } else {
          selectedCategory.value = null;
        }
      }
      isLoading.value = false;
    });
  }

  // --- 1. PICK AND CROP (Web & Mobile Safe) ---
  Future<void> pickAndCropImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      if (kIsWeb) {
        tempSelectedImageBytes.value = await pickedFile.readAsBytes();
        return;
      }

      CroppedFile? croppedFile = await ImageCropper().cropImage(
        sourcePath: pickedFile.path,
        aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Crop Image',
            toolbarColor: const Color(0xFF2A2D3E),
            toolbarWidgetColor: Colors.white,
            initAspectRatio: CropAspectRatioPreset.square,
            lockAspectRatio: true,
            cropStyle: CropStyle.circle,
          ),
          IOSUiSettings(
            title: 'Crop Image',
            aspectRatioLockEnabled: true,
            cropStyle: CropStyle.circle,
          ),
        ],
      );

      if (croppedFile != null) {
        tempSelectedImageBytes.value = await croppedFile.readAsBytes();
      }
    }
  }

  // --- 2. UPLOAD TO CLOUDINARY ---
  Future<String?> uploadImageToCloudinary() async {
    try {
      if (tempSelectedImageBytes.value == null) return null;

      final byteData = ByteData.view(tempSelectedImageBytes.value!.buffer);
      CloudinaryResponse response = await cloudinary.uploadFile(
        CloudinaryFile.fromByteData(
          byteData,
          identifier: 'cat_${DateTime.now().millisecondsSinceEpoch}',
          folder: 'Categories',
        ),
      );
      return response.secureUrl;
    } catch (e) {
      Get.snackbar(
        "Upload Error",
        "Image upload failed: $e",
        backgroundColor: Colors.red,
      );
      return null;
    }
  }

  // --- 3. ADD CATEGORY ---
  Future<void> addCategory(String name) async {
    try {
      isUploading.value = true;
      String imageUrl = '';

      if (tempSelectedImageBytes.value != null) {
        imageUrl = await uploadImageToCloudinary() ?? '';
      }

      CategoryModel newCat = CategoryModel(
        name: name,
        imageUrl: imageUrl,
        subCategories: [],
      );
      await _firestore.collection('categories').add(newCat.toMap());

      Get.back();
      Get.snackbar(
        "Success",
        "Category Added Successfully",
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar(
        "Error",
        e.toString(),
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isUploading.value = false;
      tempSelectedImageBytes.value = null; // Clear bytes
    }
  }

  // --- 4. ADD SUB-CATEGORY ---
  Future<void> addSubCategory(
    String parentCategoryName,
    String subCatName,
  ) async {
    try {
      isUploading.value = true;
      String imageUrl = '';

      if (tempSelectedImageBytes.value != null) {
        imageUrl = await uploadImageToCloudinary() ?? '';
      }

      var query = await _firestore
          .collection('categories')
          .where('name', isEqualTo: parentCategoryName)
          .get();

      if (query.docs.isNotEmpty) {
        String docId = query.docs.first.id;
        await _firestore.collection('categories').doc(docId).update({
          'subCategories': FieldValue.arrayUnion([
            {'name': subCatName, 'imageUrl': imageUrl},
          ]),
        });

        Get.back();
        Get.snackbar(
          "Success",
          "Sub-Category Added",
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      Get.snackbar("Error", e.toString(), backgroundColor: Colors.red);
    } finally {
      isUploading.value = false;
      tempSelectedImageBytes.value = null;
    }
  }

  // --- 5. UPDATE CATEGORY ---
  Future<void> updateCategory(CategoryModel cat, String newName) async {
    try {
      isUploading.value = true;
      String updatedImageUrl = cat.imageUrl ?? '';

      if (tempSelectedImageBytes.value != null) {
        updatedImageUrl = await uploadImageToCloudinary() ?? updatedImageUrl;
      }

      await _firestore.collection('categories').doc(cat.id).update({
        'name': newName,
        'imageUrl': updatedImageUrl,
      });

      Get.back();
      Get.snackbar(
        "Updated",
        "Category Updated Successfully",
        backgroundColor: Colors.blueAccent,
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar(
        "Error",
        "Could not update category",
        backgroundColor: Colors.red,
      );
    } finally {
      isUploading.value = false;
      tempSelectedImageBytes.value = null;
    }
  }

  // --- 6. UPDATE SUB-CATEGORY (Duplicate Fix) ---
  Future<void> updateSubCategory(
    CategoryModel parentCat,
    Map<String, dynamic> oldSubCat,
    String newSubName,
  ) async {
    try {
      isUploading.value = true;
      String updatedImageUrl = oldSubCat['imageUrl'] ?? '';

      if (tempSelectedImageBytes.value != null) {
        updatedImageUrl = await uploadImageToCloudinary() ?? updatedImageUrl;
      }

      Map<String, dynamic> newSubCat = {
        'name': newSubName,
        'imageUrl': updatedImageUrl,
      };

      // ✅ FIX: List fetch karke usi index pe replace kar rahe hain
      List<Map<String, dynamic>> updatedList = List.from(
        parentCat.subCategories,
      );
      int index = updatedList.indexWhere(
        (sub) => sub['name'] == oldSubCat['name'],
      );

      if (index != -1) {
        updatedList[index] = newSubCat; // Overwrite purani wali
        await _firestore.collection('categories').doc(parentCat.id).update({
          'subCategories': updatedList,
        });
      }

      Get.back();
      Get.snackbar(
        "Updated",
        "Sub-category Updated",
        backgroundColor: Colors.blueAccent,
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar(
        "Error",
        "Could not update sub-category",
        backgroundColor: Colors.red,
      );
    } finally {
      isUploading.value = false;
      tempSelectedImageBytes.value = null;
    }
  }

  // --- DELETE METHODS ---
  Future<void> deleteCategory(CategoryModel cat) async {
    try {
      await _firestore.collection('categories').doc(cat.id).delete();
      if (selectedCategory.value?.id == cat.id) {
        selectedCategory.value = null;
      }
      Get.snackbar(
        "Deleted",
        "${cat.name} removed",
        backgroundColor: Colors.orangeAccent,
      );
    } catch (e) {
      Get.snackbar("Error", "Could not delete", backgroundColor: Colors.red);
    }
  }

  Future<void> deleteSubCategory(
    CategoryModel parentCat,
    Map<String, dynamic> subCat,
  ) async {
    try {
      await _firestore.collection('categories').doc(parentCat.id).update({
        'subCategories': FieldValue.arrayRemove([subCat]),
      });
      Get.snackbar(
        "Deleted",
        "${subCat['name']} removed",
        backgroundColor: Colors.orangeAccent,
      );
    } catch (e) {
      Get.snackbar(
        "Error",
        "Could not delete sub-category",
        backgroundColor: Colors.red,
      );
    }
  }

  void selectCategory(CategoryModel cat) {
    selectedCategory.value = cat;
  }
}
