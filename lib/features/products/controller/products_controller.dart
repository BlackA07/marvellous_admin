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
  var searchHistoryList = <String>[].obs;
  var showHistory = false.obs;

  // --- SETTINGS (Dynamic) ---
  var profitPerPoint = 100.0.obs; // Default
  var globalShowDecimals = true.obs; // Default

  // --- PACKAGES ---
  var selectedProductsForPackage = <ProductModel>[].obs;

  @override
  void onInit() {
    super.onInit();
    fetchProducts();
    fetchHistory();
    fetchGlobalSettings(); // Load variables
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
        globalShowDecimals.value = data['showDecimals'] ?? true;
      }
    } catch (e) {
      print("Settings fetch error: $e");
    }
  }

  // Points Calculation (Uses current profitPerPoint)
  double calculatePoints(double purchase, double sale) {
    if (purchase >= sale) return 0;

    // Ensure we have latest settings just in case (optional, but safer)
    // fetchGlobalSettings();

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
      // Note: Points are typically calculated in UI before passing here,
      // but we ensure the 'showDecimalPoints' flag is set correctly based on global settings.
      product.showDecimalPoints = globalShowDecimals.value;

      // 3. Save to DB
      await _repository.addProduct(product);
      productList.insert(0, product);

      addToHistory(product.name);
      addToHistory(product.brand);

      Get.snackbar(
        "Success",
        "Saved Successfully",
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
      return true;
    } catch (e) {
      Get.snackbar(
        "Error",
        "Failed: $e",
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

      // When updating, we usually KEEP the product's original settings
      // unless you specifically want to overwrite them.
      // Here we respect the product's existing configuration or update if you prefer.
      // For now, we update the DB normally.

      await _repository.updateProduct(product);
      int index = productList.indexWhere((p) => p.id == product.id);
      if (index != -1) {
        productList[index] = product;
        productList.refresh();
      }

      addToHistory(product.name);
      addToHistory(product.brand);

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

  // Combined History + Existing Brands/Names for suggestions
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

      return matchesSearch && matchesCategory;
    }).toList();
  }

  // --- History Logic ---
  void updateSearch(String val) {
    searchQuery.value = val;
  }

  void addToHistory(String term) async {
    if (term.trim().isNotEmpty && !searchHistoryList.contains(term)) {
      searchHistoryList.add(term);
      await _repository.addSearchTerm(term);
    }
  }

  void removeHistoryItem(String term) async {
    searchHistoryList.remove(term);
    await _repository.deleteSearchTerm(term);
  }

  void clearAllHistory() async {
    searchHistoryList.clear();
    await _repository.clearAllHistory();
  }

  void clearAllFilters() {
    searchQuery.value = '';
    selectedCategory.value = 'All';
  }

  void updateCategoryFilter(String category) {
    selectedCategory.value = category;
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
