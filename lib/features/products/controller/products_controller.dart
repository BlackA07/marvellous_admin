import 'package:flutter/material.dart';
import 'package:get/get.dart';
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

  // --- SETTINGS ---
  var profitPerPoint = 100.0.obs;

  // --- PACKAGES ---
  var selectedProductsForPackage = <ProductModel>[].obs;

  @override
  void onInit() {
    super.onInit();
    fetchProducts();
    fetchHistory();
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

  double calculatePoints(double purchase, double sale) {
    if (purchase >= sale) return 0;
    double profit = sale - purchase;
    return (profit / profitPerPoint.value);
  }

  // --- CRUD Operations ---

  Future<bool> addNewProduct(ProductModel product) async {
    try {
      isLoading(true);
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

  // FIX: Added 'isPackage' parameter and passed it to repository
  Future<void> deleteProduct(String id, {bool isPackage = false}) async {
    try {
      // 1. Delete from Firebase
      await _repository.deleteProduct(id, isPackage: isPackage);

      // 2. Remove from Local List
      productList.removeWhere((p) => p.id == id);

      // NOTE: Removed Get.snackbar here to avoid double popups
      // (Screen handles the Undo Snackbar)
    } catch (e) {
      Get.snackbar(
        "Error",
        "Failed to delete",
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
      );
    }
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
