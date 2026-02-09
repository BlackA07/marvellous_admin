import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/product_model.dart';
import '../repository/products_repository.dart';

class ProductsController extends GetxController {
  final ProductsRepository _repository = ProductsRepository();

  var isLoading = true.obs;

  // --- MASTER LIST ---
  var productList = <ProductModel>[].obs;

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
    fetchProducts();
    fetchHistory();
    fetchGlobalSettings();
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

      // Logistic fields defaults are already handled by the Model/UI passing
      // But we ensure averageRating and totalReviews are reset for new items
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

  Future<bool> updateProduct(ProductModel product) async {
    try {
      isLoading(true);

      // Apply latest decimal settings during update
      product.showDecimalPoints = showDecimals.value;

      await _repository.updateProduct(product);
      int index = productList.indexWhere((p) => p.id == product.id);
      if (index != -1) {
        productList[index] = product;
        productList.refresh();
      }

      addToHistory(product.name);
      addToHistory(product.brand);

      // --- Update Specific Lists ---
      addToSpecificHistory(product.name, 'product');
      addToSpecificHistory(product.brand, 'brand');

      Get.snackbar(
        "Success",
        "Updated Successfully",
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
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

  void fetchHistory() async {
    var history = await _repository.fetchSearchHistory();
    searchHistoryList.assignAll(history);
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
