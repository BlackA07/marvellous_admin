import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../models/order_request_model.dart';

class OrderRequestController extends GetxController {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  var isLoading = false.obs;
  var vendors = [].obs;
  var products = [].obs;

  var selectedVendor = Rxn<Map<String, dynamic>>();
  var cartItems = <Map<String, dynamic>>[].obs;

  // ✅ Product Search aur Totals k variables
  var productSearchQuery = "".obs;
  var grandTotal = 0.0.obs;
  var orderDate = DateTime.now().obs;

  @override
  void onInit() {
    super.onInit();
    loadInitialData();
  }

  void loadInitialData() async {
    isLoading.value = true;
    try {
      var vDocs = await _db.collection('vendors').get();
      vendors.assignAll(
        vDocs.docs
            .map((e) => {'id': e.id, ...e.data() as Map<String, dynamic>})
            .toList(),
      );

      var pDocs = await _db.collection('products').get();
      products.assignAll(
        pDocs.docs
            .map((e) => {'id': e.id, ...e.data() as Map<String, dynamic>})
            .toList(),
      );
    } catch (e) {
      Get.snackbar(
        "Error",
        "Failed to load data.",
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
    isLoading.value = false;
  }

  void setVendor(Map<String, dynamic> vendor) {
    selectedVendor.value = vendor;
  }

  void calculateTotals() {
    double total = 0;
    for (var item in cartItems) {
      total += (item['purchasePrice'] * item['requestQty']);
    }
    grandTotal.value = total;
  }

  void handleProductSelection(String val) {
    try {
      var product = products.firstWhere(
        (e) => "${e['name']} - ${e['modelNumber']}" == val,
      );

      int existingIndex = cartItems.indexWhere(
        (item) => item['productId'] == product['id'],
      );
      if (existingIndex != -1) {
        cartItems[existingIndex]['requestQty'] += 1;
      } else {
        // ✅ Product ki pehli image extract karo
        String prodImg = '';
        if (product['images'] != null &&
            (product['images'] as List).isNotEmpty) {
          prodImg = product['images'][0];
        }

        cartItems.add({
          'productId': product['id'],
          'productName': product['name'],
          'brand': product['brand'] ?? 'N/A',
          'model': product['modelNumber'] ?? 'N/A',
          'image': prodImg, // ✅ Image store
          'purchasePrice': product['purchasePrice'] ?? 0,
          'requestQty': 1,
          'isAvailable': true,
        });
      }
      productSearchQuery.value = ""; // Text box clear karo naye item k liye
      calculateTotals();
      cartItems.refresh(); // Naya item add hone par screen update
    } catch (e) {
      debugPrint("Product not found from dropdown string");
    }
  }

  // ✅ FIX: Text field update logic (Without refreshing list to prevent focus loss)
  void updateItemQty(String productId, int newQty) {
    int existingIndex = cartItems.indexWhere(
      (item) => item['productId'] == productId,
    );
    if (existingIndex != -1) {
      cartItems[existingIndex]['requestQty'] = newQty;
      // Yahan cartItems.refresh() NAHI lagana, warna typing k doran cursor jump karega.
      // Sirf Totals calculate karwa lo, UI automatically update hoga.
      calculateTotals();
    }
  }

  void removeFromCart(int index) {
    cartItems.removeAt(index);
    calculateTotals();
    cartItems.refresh();
  }

  Future<void> sendOrderRequest() async {
    if (selectedVendor.value == null || cartItems.isEmpty) {
      Get.snackbar(
        "Missing Details",
        "Please select a vendor and add at least one product.",
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
      );
      return;
    }

    // ✅ FIX: Check if any item has 0 quantity
    if (cartItems.any((item) => item['requestQty'] <= 0)) {
      Get.snackbar(
        "Invalid Quantity",
        "Please remove items with 0 quantity or enter a valid number.",
        backgroundColor: Colors.orange.shade900,
        colorText: Colors.white,
      );
      return;
    }

    isLoading.value = true;
    try {
      OrderRequestModel request = OrderRequestModel(
        vendorId: selectedVendor.value!['id'],
        vendorName:
            "${selectedVendor.value!['storeName']} (${selectedVendor.value!['ownerName']})",
        items: cartItems,
        createdAt: orderDate.value,
        status: 'pending',
      );

      await _db.collection('order_requests').add(request.toMap());

      selectedVendor.value = null;
      cartItems.clear();
      grandTotal.value = 0.0;
      orderDate.value = DateTime.now();

      Get.defaultDialog(
        title: "Request Sent!",
        middleText:
            "Order Request has been sent to the vendor successfully. Waiting for their confirmation.",
        confirm: ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: Colors.black),
          onPressed: () => Get.back(),
          child: const Text("OK", style: TextStyle(color: Colors.white)),
        ),
      );
    } catch (e) {
      Get.snackbar(
        "Error",
        "Failed to send request: $e",
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
    isLoading.value = false;
  }
}
