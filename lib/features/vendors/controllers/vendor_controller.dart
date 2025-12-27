import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../models/vendor_model.dart';
import '../../products/models/product_model.dart'; // Import Product Model

class VendorController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  var vendors = <VendorModel>[].obs;
  var categoryNames = <String>[].obs; // Dropdown ke liye
  var isLoading = false.obs;
  var isSaving = false.obs; // Save button loading state

  // Vendor Specific Products
  var vendorProducts = <ProductModel>[].obs;
  var isProductsLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    fetchVendors();
    fetchCategoriesForDropdown();
  }

  // Vendors List Fetch
  void fetchVendors() {
    isLoading.value = true;
    _firestore.collection('vendors').snapshots().listen((snapshot) {
      vendors.value = snapshot.docs
          .map((doc) => VendorModel.fromMap(doc.data(), doc.id))
          .toList();
      isLoading.value = false;
    });
  }

  // Fetch Products for Specific Vendor
  void fetchVendorProducts(String vendorId) {
    isProductsLoading.value = true;
    // Listening to products where vendorId matches
    _firestore
        .collection('products')
        .where('vendorId', isEqualTo: vendorId)
        .snapshots()
        .listen((snapshot) {
          vendorProducts.value = snapshot.docs
              .map((doc) => ProductModel.fromMap(doc.data(), doc.id))
              .toList();
          isProductsLoading.value = false;
        });
  }

  // Categories Fetch
  void fetchCategoriesForDropdown() {
    _firestore.collection('categories').snapshots().listen((snapshot) {
      categoryNames.value = snapshot.docs
          .map((doc) => doc['name'] as String)
          .toList();
    });
  }

  // Add Vendor (Returns TRUE if successful)
  Future<bool> addVendor(VendorModel vendor) async {
    isSaving.value = true;
    try {
      await _firestore.collection('vendors').add(vendor.toMap());
      isSaving.value = false;
      return true; // Signal success
    } catch (e) {
      isSaving.value = false;
      Get.snackbar(
        "Error",
        e.toString(),
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return false; // Signal failure
    }
  }

  // Update Vendor (Returns TRUE if successful)
  Future<bool> updateVendor(VendorModel vendor, String docId) async {
    isSaving.value = true;
    try {
      await _firestore.collection('vendors').doc(docId).update(vendor.toMap());
      isSaving.value = false;
      return true;
    } catch (e) {
      isSaving.value = false;
      Get.snackbar(
        "Error",
        e.toString(),
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return false;
    }
  }

  // Delete Vendor with UNDO
  Future<void> deleteVendor(VendorModel vendor) async {
    try {
      // 1. Delete Document
      await _firestore.collection('vendors').doc(vendor.id).delete();

      // 2. Show Snackbar with Undo
      Get.snackbar(
        "Deleted",
        "${vendor.name} has been removed.",
        backgroundColor: Colors.orangeAccent,
        colorText: Colors.black,
        mainButton: TextButton(
          onPressed: () async {
            // UNDO LOGIC: Re-set the document with same ID
            await _firestore
                .collection('vendors')
                .doc(vendor.id)
                .set(vendor.toMap());
            Get.back(); // Close snackbar
          },
          child: const Text(
            "UNDO",
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
          ),
        ),
        duration: const Duration(seconds: 4),
      );
    } catch (e) {
      Get.snackbar(
        "Error",
        "Could not delete: $e",
        backgroundColor: Colors.red,
      );
    }
  }

  // Delete Product from Vendor Screen
  Future<void> deleteProductFromVendor(ProductModel product) async {
    try {
      await _firestore.collection('products').doc(product.id).delete();
      Get.snackbar(
        "Deleted",
        "Product removed",
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
        mainButton: TextButton(
          onPressed: () async {
            // UNDO Logic for Product
            await _firestore
                .collection('products')
                .doc(product.id)
                .set(product.toMap());
            Get.back();
          },
          child: const Text(
            "UNDO",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
      );
    } catch (e) {
      Get.snackbar(
        "Error",
        "Failed to delete",
        backgroundColor: Colors.redAccent,
      );
    }
  }
}
