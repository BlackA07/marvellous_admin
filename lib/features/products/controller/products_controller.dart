import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../models/product_model.dart';
import '../repository/products_repository.dart';

class ProductsController extends GetxController {
  final ProductsRepository _repository = ProductsRepository();

  var isLoading = true.obs;

  // Master list (jo DB se ayegi)
  var productList = <ProductModel>[].obs;

  // Search & Filter Variables
  var searchQuery = ''.obs;
  var selectedCategory = 'All'.obs;

  // --- FILTERED LIST LOGIC (Table men ye use hoga) ---
  List<ProductModel> get filteredProducts {
    return productList.where((product) {
      // 1. Apply Search
      String search = searchQuery.value.toLowerCase();
      bool matchesSearch =
          search.isEmpty ||
          product.name.toLowerCase().contains(search) ||
          product.modelNumber.toLowerCase().contains(search) ||
          product.category.toLowerCase().contains(search);

      // 2. Apply Category Filter
      bool matchesCategory =
          selectedCategory.value == 'All' ||
          product.category == selectedCategory.value;

      return matchesSearch && matchesCategory;
    }).toList();
  }

  // --- Dynamic Categories ---
  List<String> get availableCategories {
    Set<String> categories = productList.map((p) => p.category).toSet();
    return ['All', ...categories];
  }

  // --- Stats ---
  int get totalProducts => productList.length;
  int get lowStockCount =>
      productList.where((p) => p.stockQuantity < 10).length;
  double get totalInventoryValue => productList.fold(
    0,
    (sum, p) => sum + (p.purchasePrice * p.stockQuantity),
  );

  @override
  void onInit() {
    super.onInit();
    fetchProducts();
  }

  void fetchProducts() async {
    try {
      isLoading(true);
      var products = await _repository.fetchProducts();
      productList.assignAll(products);
    } catch (e) {
      Get.snackbar(
        "Error",
        "Failed to fetch products: $e",
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
      );
    } finally {
      isLoading(false);
    }
  }

  // Search Function
  void updateSearch(String val) {
    searchQuery.value = val;
  }

  // Filter Functions
  void updateCategoryFilter(String category) {
    selectedCategory.value = category;
  }

  void clearAllFilters() {
    searchQuery.value = '';
    selectedCategory.value = 'All';
  }

  // --- CRUD Operations ---

  // 1. Add Product
  Future<bool> addNewProduct(ProductModel product) async {
    try {
      isLoading(true);
      await _repository.addProduct(product);
      productList.insert(0, product);
      Get.snackbar(
        "Success",
        "Product Added",
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

  // 2. Update Product (Ye Missing tha - Ab add kardiya hai)
  Future<bool> updateProduct(ProductModel product) async {
    try {
      isLoading(true);
      // Repository call (Make sure repository has updateProduct method too)
      await _repository.updateProduct(product);

      // Local List Update
      int index = productList.indexWhere((p) => p.id == product.id);
      if (index != -1) {
        productList[index] = product;
        productList.refresh(); // UI Refresh
      }

      Get.snackbar(
        "Success",
        "Product Updated",
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

  // 3. Delete Product
  Future<void> deleteProduct(String id) async {
    try {
      await _repository.deleteProduct(id);
      productList.removeWhere((p) => p.id == id);
      Get.snackbar(
        "Deleted",
        "Product removed",
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar(
        "Error",
        "Failed to delete",
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
      );
    }
  }
}
