import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../models/category_model.dart';

class CategoryController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Observables
  var categories = <CategoryModel>[].obs;
  var isLoading = false.obs;
  var selectedCategory = Rxn<CategoryModel>(); // Nullable initially

  @override
  void onInit() {
    super.onInit();
    fetchCategories();
  }

  // Fetch Categories Real-time
  void fetchCategories() {
    isLoading.value = true;
    _firestore.collection('categories').snapshots().listen((snapshot) {
      categories.value = snapshot.docs
          .map((doc) => CategoryModel.fromMap(doc.data(), doc.id))
          .toList();
      isLoading.value = false;
    });
  }

  // Add Main Category
  Future<void> addCategory(String name) async {
    try {
      CategoryModel newCat = CategoryModel(name: name, subCategories: []);
      await _firestore.collection('categories').add(newCat.toMap());
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
    }
  }

  // Add Sub Category to Selected Category
  Future<void> addSubCategory(String subCatName) async {
    if (selectedCategory.value == null || selectedCategory.value!.id == null)
      return;

    try {
      String docId = selectedCategory.value!.id!;

      await _firestore.collection('categories').doc(docId).update({
        'subCategories': FieldValue.arrayUnion([subCatName]),
      });

      Get.back(); // Close dialog
      Get.snackbar(
        "Success",
        "Sub-Category Added",
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar("Error", e.toString(), backgroundColor: Colors.red);
    }
  }

  // Delete Main Category with Undo
  Future<void> deleteCategory(CategoryModel cat) async {
    try {
      // Delete
      await _firestore.collection('categories').doc(cat.id).delete();

      // If selected was deleted, deselect it
      if (selectedCategory.value?.id == cat.id) {
        selectedCategory.value = null;
      }

      // Undo Snackbar
      Get.snackbar(
        "Deleted",
        "${cat.name} removed",
        backgroundColor: Colors.orangeAccent,
        colorText: Colors.black,
        duration: const Duration(seconds: 4),
        mainButton: TextButton(
          onPressed: () async {
            // Restore logic
            await _firestore
                .collection('categories')
                .doc(cat.id)
                .set(cat.toMap());
            Get.back(); // Close snackbar
          },
          child: const Text(
            "UNDO",
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
          ),
        ),
      );
    } catch (e) {
      Get.snackbar("Error", "Could not delete", backgroundColor: Colors.red);
    }
  }

  // Delete Sub-Category with Undo
  Future<void> deleteSubCategory(
    CategoryModel parentCat,
    String subCatName,
  ) async {
    try {
      // Remove from array
      await _firestore.collection('categories').doc(parentCat.id).update({
        'subCategories': FieldValue.arrayRemove([subCatName]),
      });

      // Undo Snackbar
      Get.snackbar(
        "Deleted",
        "$subCatName removed",
        backgroundColor: Colors.orangeAccent,
        colorText: Colors.black,
        duration: const Duration(seconds: 4),
        mainButton: TextButton(
          onPressed: () async {
            // Restore logic (Add back to array)
            await _firestore.collection('categories').doc(parentCat.id).update({
              'subCategories': FieldValue.arrayUnion([subCatName]),
            });
            Get.back();
          },
          child: const Text(
            "UNDO",
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
          ),
        ),
      );
    } catch (e) {
      Get.snackbar(
        "Error",
        "Could not delete sub-category",
        backgroundColor: Colors.red,
      );
    }
  }

  // Select a category to view sub-categories
  void selectCategory(CategoryModel cat) {
    selectedCategory.value = cat;
  }
}
