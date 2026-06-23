// lib/controller/products_controller.dart

import 'dart:convert';
import 'dart:typed_data';

import 'package:cloudinary_public/cloudinary_public.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/product_model.dart';
import '../repository/products_repository.dart';

class ProductsController extends GetxController {
  final ProductsRepository _repository = ProductsRepository();
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final cloudinary = CloudinaryPublic('dzluvpc34', 'marvellous', cache: false);

  var isLoading = true.obs;
  var isMigrating = false.obs;

  // --- MASTER LIST ---
  var productList = <ProductModel>[].obs;
  // ✅ NEW: Pending Requests List
  var pendingRequestsList = <ProductModel>[].obs;

  // --- SEARCH & HISTORY ---
  var searchQuery = ''.obs;
  var selectedCategory = 'All'.obs;
  var selectedSubCategory = 'All'.obs;

  // General Search History (for Home Screen)
  var searchHistoryList = <String>[].obs;

  // --- NEW: Specific History Lists (for Add Product Screen) ---
  var brandHistoryList = <String>[].obs;
  var productNameHistoryList = <String>[].obs;

  var showHistory = false.obs;

  // --- SETTINGS (Dynamic) ---
  var profitPerPoint = 100.0.obs; // Default
  var showDecimals = true.obs;

  // --- PACKAGES ---
  var selectedProductsForPackage = <ProductModel>[].obs;

  @override
  void onInit() {
    super.onInit();
    // ✅ FIX: Only fetch if user is logged in
    if (FirebaseAuth.instance.currentUser != null) {
      fetchAllData();
    } else {
      isLoading(false);
    }
  }

  // ✅ Extracted to a method so AuthController can call it after login
  void fetchAllData() {
    fetchProducts();
    fetchHistory();
    fetchGlobalSettings();
    _fetchPendingRequests();
  }

  // ✅ NEW: Listen to Pending Requests Stream
  void _fetchPendingRequests() {
    _repository.getPendingRequestsStream().listen((requests) {
      pendingRequestsList.assignAll(requests);
    });
  }

  // ✅ NEW: Reject Request Function
  Future<void> rejectRequest(String requestId) async {
    try {
      await _repository.rejectRequest(requestId);
      Get.snackbar(
        "Rejected",
        "Product request rejected successfully.",
        backgroundColor: Colors.orange,
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar(
        "Error",
        "Failed to reject request: $e",
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
      );
    }
  }

  Future<List<String>> uploadImagesToCloudinary(
    List<String> base64Images,
  ) async {
    final cloudinary = CloudinaryPublic(
      'dzluvpc34',
      'marvellous',
      cache: false,
    );

    // Future.wait se saari images ek saath upload hongi (fast performance)
    List<Future<String>> uploadTasks = base64Images.map((base64) async {
      if (base64.startsWith('http'))
        return base64; // Agar pehle se URL hai to skip karen

      try {
        Uint8List bytes = base64Decode(base64);
        final byteData = ByteData.view(bytes.buffer);

        CloudinaryResponse response = await cloudinary.uploadFile(
          CloudinaryFile.fromByteData(
            byteData,
            identifier:
                'prod_${DateTime.now().millisecondsSinceEpoch}_${base64.substring(0, 5)}.jpg',
            resourceType: CloudinaryResourceType.Image,
          ),
        );
        return response.secureUrl;
      } catch (e) {
        debugPrint("Error: $e");
        return ""; // Error ki surat men empty string
      }
    }).toList();

    List<String> results = await Future.wait(uploadTasks);
    return results
        .where((url) => url.isNotEmpty)
        .toList(); // Sirf valid URLs wapas bhejen
  }

  // --- ✨ MIGRATION FUNCTION: Add averageRating & totalReviews to old products ---
  Future<void> migrateOldProducts() async {
    try {
      isMigrating(true);
      Get.dialog(
        WillPopScope(
          onWillPop: () async => false,
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(color: Colors.white),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text(
                    "Migrating Products...\nPlease wait",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        barrierDismissible: false,
      );

      int productsUpdated = 0;
      int packagesUpdated = 0;

      // Migrate Products Collection
      QuerySnapshot productsSnapshot = await _db.collection('products').get();
      WriteBatch batch = _db.batch();
      int batchCount = 0;

      for (var doc in productsSnapshot.docs) {
        var data = doc.data() as Map<String, dynamic>;

        // Check if fields are missing
        if (!data.containsKey('averageRating') ||
            !data.containsKey('totalReviews')) {
          batch.update(doc.reference, {
            'averageRating': 0.0,
            'totalReviews': 0,
          });
          productsUpdated++;
          batchCount++;

          // Firestore batch limit is 500
          if (batchCount >= 500) {
            await batch.commit();
            batch = _db.batch();
            batchCount = 0;
          }
        }
      }

      if (batchCount > 0) {
        await batch.commit();
      }

      // Migrate Packages Collection
      QuerySnapshot packagesSnapshot = await _db.collection('packages').get();
      batch = _db.batch();
      batchCount = 0;

      for (var doc in packagesSnapshot.docs) {
        var data = doc.data() as Map<String, dynamic>;

        if (!data.containsKey('averageRating') ||
            !data.containsKey('totalReviews')) {
          batch.update(doc.reference, {
            'averageRating': 0.0,
            'totalReviews': 0,
          });
          packagesUpdated++;
          batchCount++;

          if (batchCount >= 500) {
            await batch.commit();
            batch = _db.batch();
            batchCount = 0;
          }
        }
      }

      if (batchCount > 0) {
        await batch.commit();
      }

      // Close loading dialog
      if (Get.isDialogOpen ?? false) {
        Get.back();
      }

      // Show success
      Get.dialog(
        Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.check_circle, color: Colors.green, size: 80),
                const SizedBox(height: 15),
                const Text(
                  "Migration Complete!",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                Text(
                  "Products Updated: $productsUpdated\nPackages Updated: $packagesUpdated",
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () => Get.back(),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                  child: const Text("Done"),
                ),
              ],
            ),
          ),
        ),
      );

      // Refresh product list
      fetchProducts();
    } catch (e) {
      if (Get.isDialogOpen ?? false) {
        Get.back();
      }
      Get.snackbar(
        "Migration Error",
        e.toString(),
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isMigrating(false);
    }
  }

  // --- SETTINGS LOGIC ---
  Future<void> fetchGlobalSettings() async {
    try {
      DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection('admin_settings')
          .doc('global_config')
          .get();

      if (doc.exists) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        profitPerPoint.value = (data['profitPerPoint'] ?? 100.0).toDouble();
        showDecimals.value = data['showDecimals'] ?? true;
      }
    } catch (e) {
      print("Settings fetch error: $e");
    }
  }

  // Points Calculation (Uses current profitPerPoint)
  double calculatePoints(double purchase, double sale) {
    if (purchase >= sale) return 0;
    double profit = sale - purchase;
    return (profit / profitPerPoint.value);
  }

  // --- CRUD Operations ---

  Future<bool> addNewProduct(ProductModel product) async {
    try {
      isLoading(true);

      // 1. Refresh Settings to ensure we use the very latest config
      await fetchGlobalSettings();

      // 2. Apply current settings to the new product
      product.showDecimalPoints = showDecimals.value;

      // Ensure rating fields are initialized
      product.averageRating = 0.0;
      product.totalReviews = 0;

      // 3. Save to DB (Repository will handle ID generation)
      await _repository.addProduct(product);

      // 4. Add to local list at top
      productList.insert(0, product);

      // --- Add to History ---
      addToHistory(product.name);
      addToHistory(product.brand);

      // --- Add to Specific History Lists ---
      addToSpecificHistory(product.name, 'product');
      addToSpecificHistory(product.brand, 'brand');

      Get.snackbar(
        "Success",
        "Product saved successfully with ID: ${product.id}",
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );

      // ✅ Ask admin which users to notify — show dialog after success snackbar
      await Future.delayed(const Duration(milliseconds: 400));
      _showNotificationAudienceDialog(product, isUpdate: false);

      return true;
    } catch (e) {
      print("❌ Controller Error: $e");
      Get.snackbar(
        "Error",
        "Failed to add product: $e",
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
      );
      return false;
    } finally {
      isLoading(false);
    }
  }

  // ✅ NEW: Add Package with notification dialog
  Future<bool> addNewPackage(ProductModel package) async {
    try {
      isLoading(true);

      await fetchGlobalSettings();
      package.showDecimalPoints = showDecimals.value;
      package.averageRating = 0.0;
      package.totalReviews = 0;
      package.isPackage = true;

      await _repository.addProduct(package);
      productList.insert(0, package);

      addToHistory(package.name);
      addToHistory(package.brand);
      addToSpecificHistory(package.name, 'product');
      addToSpecificHistory(package.brand, 'brand');

      Get.snackbar(
        "Success",
        "Package saved successfully with ID: ${package.id}",
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );

      // ✅ Show notification dialog for new package
      await Future.delayed(const Duration(milliseconds: 400));
      _showNotificationAudienceDialog(
        package,
        isUpdate: false,
        isPackage: true,
      );

      return true;
    } catch (e) {
      print("❌ Controller Error: $e");
      Get.snackbar(
        "Error",
        "Failed to add package: $e",
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
      );
      return false;
    } finally {
      isLoading(false);
    }
  }

  // ✅ MODIFIED: Updated notification dialog signature — isUpdate & isPackage params added
  void _showNotificationAudienceDialog(
    ProductModel product, {
    bool isUpdate = false,
    bool isPackage = false,
  }) {
    final isSending = false.obs;

    // --- Audience selection (single select) ---
    final selectedAudience = 'all'.obs;

    // --- Location selection (multi-select) ---
    final String prodLoc = product.deliveryLocation.toLowerCase();
    final selectedLocations = <String>{}.obs;

    if (prodLoc.contains('karachi')) {
      selectedLocations.add('karachi');
    } else if (prodLoc.contains('pakistan')) {
      selectedLocations.add('karachi');
      selectedLocations.add('pakistan');
    } else {
      selectedLocations.add('karachi');
      selectedLocations.add('pakistan');
      selectedLocations.add('worldwide');
    }

    // ── Labels based on context ─────────────────────────────────
    final String itemType = isPackage ? 'Package' : 'Product';
    final String dialogTitle = isUpdate
        ? "Update Notification Bhejein?"
        : "New Notification Bhejein?";
    final String dialogSubtitle = isUpdate
        ? "\"${product.name}\" update ho gaya."
        : "\"${product.name}\" add ho gaya.";
    final String notifTitlePrefix = isUpdate
        ? (isPackage ? '📦 Package Updated: ' : '✏️ Product Updated: ')
        : (isPackage ? '📦 New Package: ' : '🛍️ New Product: ');
    final String notifType = isUpdate
        ? (isPackage ? 'package_updated' : 'product_updated')
        : (isPackage ? 'new_package' : 'new_product');

    Get.dialog(
      barrierDismissible: false,
      Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Colors.black, width: 1.5),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header ──────────────────────────────────────────────
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isUpdate
                          ? Colors.orange.shade50
                          : Colors.deepPurple.shade50,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      isUpdate
                          ? Icons.edit_notifications_outlined
                          : Icons.notifications_active_outlined,
                      color: isUpdate ? Colors.orange : Colors.deepPurple,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      dialogTitle,
                      style: GoogleFonts.orbitron(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              // ── Context badge (New / Updated | Product / Package) ──
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: isUpdate
                          ? Colors.orange.shade50
                          : Colors.green.shade50,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: isUpdate
                            ? Colors.orange.shade200
                            : Colors.green.shade200,
                      ),
                    ),
                    child: Text(
                      isUpdate ? "✏️ Updated" : "🆕 New",
                      style: GoogleFonts.comicNeue(
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        color: isUpdate
                            ? Colors.orange.shade700
                            : Colors.green.shade700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: isPackage
                          ? Colors.blue.shade50
                          : Colors.purple.shade50,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: isPackage
                            ? Colors.blue.shade200
                            : Colors.purple.shade200,
                      ),
                    ),
                    child: Text(
                      isPackage ? "📦 Package" : "🛍️ Product",
                      style: GoogleFonts.comicNeue(
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        color: isPackage
                            ? Colors.blue.shade700
                            : Colors.purple.shade700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                dialogSubtitle,
                style: GoogleFonts.comicNeue(
                  fontSize: 14,
                  color: Colors.black54,
                  fontWeight: FontWeight.w600,
                ),
              ),

              const SizedBox(height: 20),

              // ── Section 1: Audience ──────────────────────────────────
              Text(
                "Audience",
                style: GoogleFonts.orbitron(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Colors.black54,
                ),
              ),
              const SizedBox(height: 10),

              Obx(
                () => _audienceOption(
                  icon: Icons.people_alt_outlined,
                  label: "Sab Users",
                  sublabel: "All registered users",
                  value: 'all',
                  color: Colors.blue.shade700,
                  bgColor: Colors.blue.shade50,
                  selected: selectedAudience.value == 'all',
                  onTap: () => selectedAudience.value = 'all',
                ),
              ),
              const SizedBox(height: 8),
              Obx(
                () => _audienceOption(
                  icon: Icons.check_circle_outline,
                  label: "Sirf Active Members",
                  sublabel: "isMLMActive = true",
                  value: 'active',
                  color: Colors.green.shade700,
                  bgColor: Colors.green.shade50,
                  selected: selectedAudience.value == 'active',
                  onTap: () => selectedAudience.value = 'active',
                ),
              ),
              const SizedBox(height: 8),
              Obx(
                () => _audienceOption(
                  icon: Icons.cancel_outlined,
                  label: "Sirf Inactive Members",
                  sublabel: "isMLMActive = false",
                  value: 'inactive',
                  color: Colors.orange.shade700,
                  bgColor: Colors.orange.shade50,
                  selected: selectedAudience.value == 'inactive',
                  onTap: () => selectedAudience.value = 'inactive',
                ),
              ),

              const SizedBox(height: 20),
              const Divider(thickness: 1, color: Colors.black12),
              const SizedBox(height: 12),

              // ── Section 2: Location (multi-select) ──────────────────
              Row(
                children: [
                  Text(
                    "Delivery Location",
                    style: GoogleFonts.orbitron(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Colors.black54,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.deepPurple.shade50,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      "Multi-select",
                      style: GoogleFonts.comicNeue(
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        color: Colors.deepPurple,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                "$itemType location: ${product.deliveryLocation}",
                style: GoogleFonts.comicNeue(
                  fontSize: 12,
                  color: Colors.black38,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 10),

              Obx(
                () => _locationCheckbox(
                  icon: Icons.location_city_outlined,
                  label: "Karachi Only",
                  sublabel: "deliveryLocationPreference = Karachi",
                  value: 'karachi',
                  color: Colors.teal.shade700,
                  bgColor: Colors.teal.shade50,
                  isChecked: selectedLocations.contains('karachi'),
                  onToggle: () {
                    if (selectedLocations.contains('karachi')) {
                      selectedLocations.remove('karachi');
                    } else {
                      selectedLocations.add('karachi');
                    }
                  },
                ),
              ),
              const SizedBox(height: 8),
              Obx(
                () => _locationCheckbox(
                  icon: Icons.flag_outlined,
                  label: "Whole Pakistan",
                  sublabel: "deliveryLocationPreference = Outside Karachi",
                  value: 'pakistan',
                  color: Colors.indigo.shade700,
                  bgColor: Colors.indigo.shade50,
                  isChecked: selectedLocations.contains('pakistan'),
                  onToggle: () {
                    if (selectedLocations.contains('pakistan')) {
                      selectedLocations.remove('pakistan');
                    } else {
                      selectedLocations.add('pakistan');
                    }
                  },
                ),
              ),
              const SizedBox(height: 8),
              Obx(
                () => _locationCheckbox(
                  icon: Icons.language_outlined,
                  label: "Worldwide",
                  sublabel: "deliveryLocationPreference = Outside Pakistan",
                  value: 'worldwide',
                  color: Colors.purple.shade700,
                  bgColor: Colors.purple.shade50,
                  isChecked: selectedLocations.contains('worldwide'),
                  onToggle: () {
                    if (selectedLocations.contains('worldwide')) {
                      selectedLocations.remove('worldwide');
                    } else {
                      selectedLocations.add('worldwide');
                    }
                  },
                ),
              ),

              const SizedBox(height: 20),
              const Divider(thickness: 1, color: Colors.black12),
              const SizedBox(height: 14),

              // ── Action Buttons ───────────────────────────────────────
              Obx(
                () => SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isSending.value
                          ? Colors.grey.shade400
                          : (isUpdate ? Colors.orange : Colors.deepPurple),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: isSending.value
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Icon(
                            Icons.send_rounded,
                            color: Colors.white,
                            size: 18,
                          ),
                    label: Text(
                      isSending.value
                          ? "Bhej raha hai..."
                          : "Notification Bhejo",
                      style: GoogleFonts.comicNeue(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                      ),
                    ),
                    onPressed: isSending.value || selectedLocations.isEmpty
                        ? null
                        : () async {
                            isSending.value = true;
                            await _sendNotification(
                              product: product,
                              audienceFilter: selectedAudience.value,
                              locationFilters: Set<String>.from(
                                selectedLocations,
                              ),
                              notifTitlePrefix: notifTitlePrefix,
                              notifType: notifType,
                            );
                            isSending.value = false;
                            if (Get.isDialogOpen ?? false) Get.back();
                            _showNotifSentSnackbar(
                              selectedAudience.value,
                              Set<String>.from(selectedLocations),
                            );
                          },
                  ),
                ),
              ),
              const SizedBox(height: 10),

              SizedBox(
                width: double.infinity,
                height: 46,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.black26),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(
                    Icons.notifications_off_outlined,
                    color: Colors.black45,
                    size: 18,
                  ),
                  label: Text(
                    "Kisi Ko Na Bhejo",
                    style: GoogleFonts.comicNeue(
                      color: Colors.black45,
                      fontWeight: FontWeight.w900,
                      fontSize: 15,
                    ),
                  ),
                  onPressed: () {
                    if (Get.isDialogOpen ?? false) Get.back();
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ✅ Single-select audience option tile
  Widget _audienceOption({
    required IconData icon,
    required String label,
    required String sublabel,
    required String value,
    required Color color,
    required Color bgColor,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        decoration: BoxDecoration(
          color: selected ? bgColor : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? color.withOpacity(0.6) : Colors.black12,
            width: selected ? 1.8 : 1.0,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: selected ? color : Colors.black38, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: GoogleFonts.comicNeue(
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      color: selected ? color : Colors.black54,
                    ),
                  ),
                  Text(
                    sublabel,
                    style: GoogleFonts.comicNeue(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: selected ? color.withOpacity(0.7) : Colors.black38,
                    ),
                  ),
                ],
              ),
            ),
            // Radio indicator
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: selected ? color : Colors.black26,
                  width: 2,
                ),
                color: selected ? color : Colors.transparent,
              ),
              child: selected
                  ? const Icon(Icons.check, color: Colors.white, size: 13)
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  // ✅ Multi-select location checkbox tile
  Widget _locationCheckbox({
    required IconData icon,
    required String label,
    required String sublabel,
    required String value,
    required Color color,
    required Color bgColor,
    required bool isChecked,
    required VoidCallback onToggle,
  }) {
    return GestureDetector(
      onTap: onToggle,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        decoration: BoxDecoration(
          color: isChecked ? bgColor : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isChecked ? color.withOpacity(0.6) : Colors.black12,
            width: isChecked ? 1.8 : 1.0,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: isChecked ? color : Colors.black38, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: GoogleFonts.comicNeue(
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      color: isChecked ? color : Colors.black54,
                    ),
                  ),
                  Text(
                    sublabel,
                    style: GoogleFonts.comicNeue(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: isChecked
                          ? color.withOpacity(0.7)
                          : Colors.black38,
                    ),
                  ),
                ],
              ),
            ),
            // Checkbox indicator
            AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: isChecked ? color : Colors.black26,
                  width: 2,
                ),
                color: isChecked ? color : Colors.transparent,
              ),
              child: isChecked
                  ? const Icon(Icons.check, color: Colors.white, size: 14)
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  void _showNotifSentSnackbar(String audience, Set<String> locations) {
    final String audienceLabel = audience == 'all'
        ? 'Sab users'
        : audience == 'active'
        ? 'Active members'
        : 'Inactive members';

    final List<String> locLabels = [];
    if (locations.contains('karachi')) locLabels.add('Karachi');
    if (locations.contains('pakistan')) locLabels.add('Pakistan');
    if (locations.contains('worldwide')) locLabels.add('Worldwide');

    Get.snackbar(
      "Notification Sent ✅",
      "$audienceLabel ko bheja gaya — ${locLabels.join(', ')}",
      backgroundColor: Colors.green,
      colorText: Colors.white,
      snackPosition: SnackPosition.BOTTOM,
      duration: const Duration(seconds: 4),
    );
  }

  // ✅ UNIFIED: Core notification sender
  // Works for: new product, updated product, new package, updated package
  // notifTitlePrefix controls the emoji+label in title
  // notifType controls the 'type' field in Firestore
  Future<void> _sendNotification({
    required ProductModel product,
    required String audienceFilter,
    required Set<String> locationFilters,
    required String notifTitlePrefix,
    required String notifType,
  }) async {
    try {
      final usersSnap = await _db.collection('users').get();

      final String firstImage = product.images.isNotEmpty
          ? product.images[0]
          : '';
      final String priceText = "Rs. ${product.salePrice.toStringAsFixed(0)}";
      final String notifBody =
          "${product.brand.isNotEmpty ? product.brand : 'New'} · $priceText"
          "${product.modelNumber.isNotEmpty ? ' · ${product.modelNumber}' : ''}";

      final List<QueryDocumentSnapshot> targetUsers = [];

      for (final userDoc in usersSnap.docs) {
        final data = userDoc.data() as Map<String, dynamic>;
        final bool isMLMActive = data['isMLMActive'] == true;

        // ── Audience filter ──────────────────────────────────────────
        final bool passesAudience =
            audienceFilter == 'all' ||
            (audienceFilter == 'active' && isMLMActive) ||
            (audienceFilter == 'inactive' && !isMLMActive);

        if (!passesAudience) continue;

        // ── Location filter ──────────────────────────────────────────
        final String userLocPref = (data['deliveryLocationPreference'] ?? '')
            .toString()
            .trim();

        bool passesLocation;

        if (userLocPref.isEmpty) {
          passesLocation = true;
        } else if (userLocPref == 'Karachi') {
          passesLocation = locationFilters.contains('karachi');
        } else if (userLocPref.contains('Pakistan')) {
          passesLocation = locationFilters.contains('pakistan');
        } else if (userLocPref.contains('Worldwide') ||
            userLocPref.contains('Outside Pakistan')) {
          passesLocation = locationFilters.contains('worldwide');
        } else {
          passesLocation = true;
        }

        if (!passesLocation) continue;

        targetUsers.add(userDoc);
      }

      // ── Send in batches of 500 (Firestore limit) ─────────────────
      for (int i = 0; i < targetUsers.length; i += 500) {
        final chunk = targetUsers.sublist(
          i,
          (i + 500) > targetUsers.length ? targetUsers.length : (i + 500),
        );
        final WriteBatch batch = _db.batch();

        for (final userDoc in chunk) {
          final notifRef = _db
              .collection('users')
              .doc(userDoc.id)
              .collection('notifications')
              .doc();

          batch.set(notifRef, {
            'title': '$notifTitlePrefix${product.name}',
            'body': notifBody,
            'type': notifType,
            'isRead': false,
            'timestamp': FieldValue.serverTimestamp(),
            'data': {
              'productId': product.id,
              'productName': product.name,
              'productImage': firstImage,
              'salePrice': product.salePrice,
              'originalPrice': product.originalPrice,
              'modelNumber': product.modelNumber,
              'brand': product.brand,
              'isPackage': product.isPackage,
            },
          });
        }

        await batch.commit();
      }

      debugPrint(
        "✅ Notifications sent to ${targetUsers.length} users"
        " (type: $notifType, audience: $audienceFilter, locations: $locationFilters)",
      );
    } catch (e) {
      debugPrint("❌ Failed to send notifications: $e");
      Get.snackbar(
        "Notification Error",
        "Could not send notifications: $e",
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  // ✅ KEPT for backward compatibility — delegates to unified sender
  Future<void> _sendNewProductNotification({
    required ProductModel product,
    required String audienceFilter,
    required Set<String> locationFilters,
  }) async {
    await _sendNotification(
      product: product,
      audienceFilter: audienceFilter,
      locationFilters: locationFilters,
      notifTitlePrefix: '🛍️ New Product: ',
      notifType: 'new_product',
    );
  }

  Future<bool> updateProduct(ProductModel product) async {
    try {
      isLoading(true);

      // Apply latest decimal settings during update
      product.showDecimalPoints = showDecimals.value;

      // ✅ SMART APPROVE LOGIC FOR PENDING VENDOR REQUESTS
      if (product.status == 'pending') {
        _showNotificationAudienceDialog(product, isUpdate: false);
        product.status = 'approved';
        String requestId = product.id!;

        // 1. Save to original 'products' collection (Repo handles new ID generation)
        product.id = null;
        await _repository.addProduct(product);

        // 2. Mark the request doc as 'approved' so vendor sees status change
        await _db.collection('product_requests').doc(requestId).update({
          'status': 'approved',
        });

        // 3. Add to local UI list
        productList.insert(0, product);

        Get.snackbar(
          "Approved!",
          "Vendor product approved and added successfully.",
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
        // NOTE: No notification dialog for vendor approval flow (intentional)
        // Vendor ko notification bhejo
        await _db
            .collection('vendors')
            .doc(product.vendorId)
            .collection('notifications')
            .add({
              'title': '✅ Product Approved',
              'body': '${product.name} approved ho gaya aur ab live hai.',
              'type': 'product_approved',
              'isRead': false,
              'timestamp': FieldValue.serverTimestamp(),
              'data': {'productId': product.id, 'productName': product.name},
            });
      } else {
        // ── Normal Edit/Update Flow ───────────────────────────────
        await _repository.updateProduct(product);
        int index = productList.indexWhere((p) => p.id == product.id);
        if (index != -1) {
          productList[index] = product;
          productList.refresh();
        }
        Get.snackbar(
          "Success",
          "Updated Successfully",
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );

        // ✅ Show notification dialog on edit — with isUpdate:true
        await Future.delayed(const Duration(milliseconds: 400));
        _showNotificationAudienceDialog(
          product,
          isUpdate: true,
          isPackage: product.isPackage,
        );
      }

      // Refresh history suggestions
      addToHistory(product.name);
      addToHistory(product.brand);
      addToSpecificHistory(product.name, 'product');
      addToSpecificHistory(product.brand, 'brand');

      return true;
    } catch (e) {
      Get.snackbar(
        "Error",
        "Failed to update: $e",
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
      );
      return false;
    } finally {
      isLoading(false);
    }
  }

  Future<void> deleteProduct(String id, {bool isPackage = false}) async {
    try {
      await _repository.deleteProduct(id, isPackage: isPackage);
      productList.removeWhere((p) => p.id == id);

      // Refresh suggestions after delete to remove deleted item's brand/name if no other product uses it
      updateSuggestionLists();

      // No snackbar here (handled by UI)
    } catch (e) {
      Get.snackbar(
        "Error",
        "Failed to delete",
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
      );
    }
  }

  // Fetching
  void fetchProducts() async {
    try {
      isLoading(true);
      var items = await _repository.fetchProducts();
      productList.assignAll(items);

      // --- Populate specific history lists from existing products ---
      updateSuggestionLists();
    } catch (e) {
      Get.snackbar(
        "Error",
        "Failed to fetch: $e",
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
      );
    } finally {
      isLoading(false);
    }
  }

  Future<void> holdRequest(String requestId, String reason) async {
    try {
      // Product request ka vendorId fetch karo
      var reqDoc = await _db
          .collection('product_requests')
          .doc(requestId)
          .get();
      String vendorId =
          (reqDoc.data() as Map<String, dynamic>)['vendorId'] ?? '';
      String productName =
          (reqDoc.data() as Map<String, dynamic>)['name'] ?? 'Product';

      await _db.collection('product_requests').doc(requestId).update({
        'status': 'hold',
        'holdReason': reason,
      });

      // ✅ Vendor ko notification
      if (vendorId.isNotEmpty) {
        await _db
            .collection('vendors')
            .doc(vendorId)
            .collection('notifications')
            .add({
              'title': '⏸ Product On Hold',
              'body': '$productName hold pe hai. Reason: $reason',
              'type': 'product_hold',
              'isRead': false,
              'timestamp': FieldValue.serverTimestamp(),
              'data': {
                'requestId': requestId,
                'productName': productName,
                'holdReason': reason,
              },
            });
      }

      Get.snackbar(
        "On Hold",
        "Request put on hold.",
        backgroundColor: Colors.orange,
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar(
        "Error",
        "$e",
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  void fetchHistory() async {
    try {
      // ✅ FIX: Permission check aur try-catch
      if (FirebaseAuth.instance.currentUser == null) return;

      // Check karen ke kya user admin hai, agar nahi to request na bhejain
      var userDoc = await _db
          .collection('users')
          .doc(FirebaseAuth.instance.currentUser!.uid)
          .get();
      if (userDoc.exists && userDoc.data()?['role'] == 'admin') {
        var history = await _repository.fetchSearchHistory();
        searchHistoryList.assignAll(history);
      }
    } catch (e) {
      // Agar permission denied ho, to silent rahein, app crash na hone dein
      debugPrint("Search history access denied or failed: $e");
    }
  }

  // --- Helper to populate autocomplete lists from existing data ---
  void updateSuggestionLists() {
    // Extract unique brands
    var brands = productList
        .map((p) => p.brand)
        .where((b) => b.isNotEmpty)
        .toSet()
        .toList();

    // Extract unique product names
    var names = productList
        .map((p) => p.name)
        .where((n) => n.isNotEmpty)
        .toSet()
        .toList();

    // Update Observables
    brandHistoryList.assignAll(brands);
    productNameHistoryList.assignAll(names);
  }

  // --- PUBLIC GETTERS ---
  List<ProductModel> get productsOnly =>
      productList.where((p) => !p.isPackage).toList();

  List<ProductModel> get packagesOnly =>
      productList.where((p) => p.isPackage).toList();

  int get totalProducts => productsOnly.length;

  int get lowStockCount =>
      productsOnly.where((p) => p.stockQuantity < 10).length;

  double get totalInventoryValue => productsOnly.fold(
    0,
    (sum, p) => sum + (p.purchasePrice * p.stockQuantity),
  );

  List<String> get availableCategories {
    Set<String> categories = productList.map((p) => p.category).toSet();
    return ['All', ...categories];
  }

  // ✅ Get available subcategories based on selected category
  List<String> get availableSubCategories {
    if (selectedCategory.value == 'All') {
      Set<String> allSubs = productList.map((p) => p.subCategory).toSet();
      return ['All', ...allSubs];
    }

    Set<String> subs = productList
        .where((p) => p.category == selectedCategory.value)
        .map((p) => p.subCategory)
        .toSet();
    return ['All', ...subs];
  }

  // Combined History + Existing Brands/Names for suggestions (General Search)
  List<String> getSuggestions(String query) {
    Set<String> suggestions = {...searchHistoryList};
    suggestions.addAll(
      productList.map((p) => p.brand).where((b) => b.isNotEmpty),
    );
    suggestions.addAll(
      productList.map((p) => p.name).where((n) => n.isNotEmpty),
    );

    if (query.isEmpty) return suggestions.toList();
    return suggestions
        .where((s) => s.toLowerCase().contains(query.toLowerCase()))
        .toList();
  }

  // Filter Logic
  List<ProductModel> get filteredProducts {
    return productList.where((product) {
      String search = searchQuery.value.toLowerCase();
      bool matchesSearch =
          search.isEmpty ||
          product.name.toLowerCase().contains(search) ||
          product.modelNumber.toLowerCase().contains(search) ||
          product.category.toLowerCase().contains(search);

      bool matchesCategory =
          selectedCategory.value == 'All' ||
          product.category == selectedCategory.value;

      bool matchesSubCategory =
          selectedSubCategory.value == 'All' ||
          product.subCategory == selectedSubCategory.value;

      return matchesSearch && matchesCategory && matchesSubCategory;
    }).toList();
  }

  // --- History Logic ---
  void updateSearch(String val) {
    searchQuery.value = val;
  }

  // General History (Search Bar)
  void addToHistory(String term) async {
    if (term.trim().isNotEmpty && !searchHistoryList.contains(term)) {
      searchHistoryList.add(term);
      await _repository.addSearchTerm(term);
    }
  }

  // General Remove
  void removeHistoryItem(String term) async {
    searchHistoryList.remove(term);
    await _repository.deleteSearchTerm(term);
  }

  // --- Specific History Logic (Brand vs Name) ---
  void addToSpecificHistory(String term, String type) {
    if (term.trim().isEmpty) return;

    if (type == 'brand') {
      // Avoid duplicates
      if (!brandHistoryList.contains(term)) {
        brandHistoryList.add(term);
      }
    } else {
      if (!productNameHistoryList.contains(term)) {
        productNameHistoryList.add(term);
      }
    }
  }

  void removeSpecificHistoryItem(String term, String type) {
    if (type == 'brand') {
      brandHistoryList.remove(term);
    } else {
      productNameHistoryList.remove(term);
    }
  }

  Future<void> clearAllHistory() async {
    searchHistoryList.clear();
    await _repository.clearAllHistory();
  }

  void clearAllFilters() {
    searchQuery.value = '';
    selectedCategory.value = 'All';
    selectedSubCategory.value = 'All';
  }

  void updateCategoryFilter(String category) {
    selectedCategory.value = category;
    // Reset subcategory when category changes
    selectedSubCategory.value = 'All';
  }

  // Update subcategory filter
  void updateSubCategoryFilter(String subCategory) {
    selectedSubCategory.value = subCategory;
  }

  // --- Packages Helper Logic ---
  void toggleProductForPackage(ProductModel product) {
    if (selectedProductsForPackage.contains(product)) {
      selectedProductsForPackage.remove(product);
    } else {
      selectedProductsForPackage.add(product);
    }
  }

  double get packageTotalPurchasePrice => selectedProductsForPackage.fold(
    0,
    (sum, item) => sum + item.purchasePrice,
  );

  String get generatePackageName =>
      selectedProductsForPackage.map((e) => e.name).join(' + ');

  void clearPackageSelection() {
    selectedProductsForPackage.clear();
  }
}
