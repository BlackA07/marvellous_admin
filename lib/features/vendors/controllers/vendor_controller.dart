import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../models/vendor_model.dart';
import '../../products/models/product_model.dart';

class VendorController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  var vendors = <VendorModel>[].obs;
  var categoryNames = <String>[].obs;
  var isLoading = false.obs;
  var isSaving = false.obs;

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
      await _firestore.collection('vendors').doc(vendor.id).delete();

      Get.snackbar(
        "Deleted",
        "${vendor.storeName.isNotEmpty ? vendor.storeName : vendor.ownerName} has been removed.",
        backgroundColor: Colors.orangeAccent,
        colorText: Colors.black,
        mainButton: TextButton(
          onPressed: () async {
            await _firestore
                .collection('vendors')
                .doc(vendor.id)
                .set(vendor.toMap());
            Get.back();
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

  // Approve Vendor
  Future<void> approveVendor(String docId) async {
    isSaving.value = true;
    try {
      await _firestore.collection('vendors').doc(docId).update({
        'status': 'approved',
        'approvedAt': FieldValue.serverTimestamp(),
        'rejectionReason': '',
        'holdReason': '',
      });
      Get.snackbar(
        "Approved",
        "Vendor approved successfully.",
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
    isSaving.value = false;
  }

  // Hold Vendor
  Future<void> holdVendor(String docId, String reason) async {
    isSaving.value = true;
    try {
      await _firestore.collection('vendors').doc(docId).update({
        'status': 'hold',
        'holdReason': reason,
      });
      Get.snackbar(
        "On Hold",
        "Vendor put on hold.",
        backgroundColor: Colors.orange,
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
    isSaving.value = false;
  }

  // Reject Vendor
  Future<void> rejectVendor(String docId, String reason) async {
    isSaving.value = true;
    try {
      await _firestore.collection('vendors').doc(docId).update({
        'status': 'rejected',
        'rejectionReason': reason,
        'rejectedAt': FieldValue.serverTimestamp(),
      });
      Get.snackbar(
        "Rejected",
        "Vendor rejected.",
        backgroundColor: Colors.redAccent,
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
    isSaving.value = false;
  }
}
