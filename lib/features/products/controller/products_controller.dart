import 'package:get/get.dart';
import '../models/product_model.dart';
import '../repository/products_repository.dart';

class ProductsController extends GetxController {
  final ProductsRepository _repository = ProductsRepository();

  var isLoading = true.obs;
  var productList = <ProductModel>[].obs;

  // Stats Logic
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
      Get.snackbar("Error", "Failed to fetch products");
    } finally {
      isLoading(false);
    }
  }

  Future<void> addNewProduct(ProductModel product) async {
    try {
      isLoading(true);
      await _repository.addProduct(product);
      productList.add(product); // Local update for instant feedback
      Get.back(); // Close form
      Get.snackbar("Success", "Product Added Successfully");
    } catch (e) {
      Get.snackbar("Error", "Failed to add product");
    } finally {
      isLoading(false);
    }
  }

  void deleteProduct(String id) async {
    try {
      await _repository.deleteProduct(id);
      productList.removeWhere((p) => p.id == id);
      Get.snackbar("Deleted", "Product removed");
    } catch (e) {
      Get.snackbar("Error", "Failed to delete");
    }
  }
}
