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
  String? editingRequestId;

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
      var vDocs = await _db
          .collection('vendors')
          .where('status', isEqualTo: 'approved')
          .get();
      vendors.assignAll(
        vDocs.docs
            .map((e) => {'id': e.id, ...e.data() as Map<String, dynamic>})
            .toList(),
      );

      var pDocs = await _db.collection('products').get();
      products.assignAll(
        pDocs.docs.map((e) {
          var data = e.data() as Map<String, dynamic>;
          return {'id': e.id, ...data};
        }).toList(),
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
      var product = products.firstWhere((e) {
        String label = "${e['name']} - ${e['modelNumber']}";
        String brand = e['brand'] ?? '';
        String ram = e['ram'] ?? '';
        String storage = e['storage'] ?? '';
        List<String> extra = [
          if (brand.isNotEmpty) brand,
          if (ram.isNotEmpty) 'RAM:$ram',
          if (storage.isNotEmpty) 'ROM:$storage',
        ];
        if (extra.isNotEmpty) label += ' (${extra.join(' | ')})';
        return label == val;
      });

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
          'brand': product['brand'] ?? '',
          'model': product['modelNumber'] ?? 'N/A',
          'ram': product['ram'] ?? '',
          'storage': product['storage'] ?? '',
          'image': prodImg,
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

  void updateItemPrice(String productId, double newPrice) {
    final index = cartItems.indexWhere((i) => i['productId'] == productId);
    if (index != -1) {
      cartItems[index]['purchasePrice'] = newPrice;
      calculateTotals();
    }
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

    // ✅ Check if any item has 0 quantity
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
      // ✅ Vendor ID theek se uthana taake Vendor app mein show ho
      String correctVendorId =
          selectedVendor.value!['uid'] ??
          selectedVendor.value!['userId'] ??
          selectedVendor.value!['id'];

      OrderRequestModel request = OrderRequestModel(
        vendorId: correctVendorId,
        vendorName:
            "${selectedVendor.value!['storeName']} (${selectedVendor.value!['ownerName']})",
        items: cartItems,
        createdAt: orderDate.value,
        status: 'pending', // Edit hone ke baad status dubara pending hojayega
      );

      if (editingRequestId != null) {
        // 🔥 EDIT MODE: Purana document update hoga (naya card nahi banega)
        await _db
            .collection('order_requests')
            .doc(editingRequestId)
            .update(request.toMap());
        editingRequestId = null; // Edit mode reset kar diya
      } else {
        // 🔥 NEW MODE: Naya order create hoga
        await _db.collection('order_requests').add(request.toMap());
      }

      // State reset kar do
      selectedVendor.value = null;
      cartItems.clear();
      grandTotal.value = 0.0;
      orderDate.value = DateTime.now();

      Get.defaultDialog(
        title: "Success!",
        middleText: "Order Request has been sent to the vendor successfully.",
        confirm: ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: Colors.black),
          onPressed: () {
            Get.back(); // Dialog close karega
            Get.back(); // Wapis All Orders wali screen par bheje ga taake user edit ke baad list dekh sake
          },
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

  void populateForEditing(Map<String, dynamic> data, String id) {
    editingRequestId = id;
    orderDate.value = (data['createdAt'] as Timestamp).toDate();

    // Find vendor from list or set manually
    var v = vendors.firstWhereOrNull(
      (element) => element['id'] == data['vendorId'],
    );
    if (v != null) {
      selectedVendor.value = v;
    } else {
      selectedVendor.value = {
        'id': data['vendorId'],
        'storeName': data['vendorName'].toString().split(' (')[0],
        'ownerName': data['vendorName'].toString().contains('(')
            ? data['vendorName'].toString().split('(')[1].replaceAll(')', '')
            : '',
      };
    }

    // Load existing items into cart
    cartItems.assignAll(List<Map<String, dynamic>>.from(data['items'] ?? []));
    calculateTotals();
    cartItems.refresh();
  }
}
