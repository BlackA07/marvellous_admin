import '../models/product_model.dart';

class ProductsRepository {
  // Simulate API Call
  Future<List<ProductModel>> fetchProducts() async {
    await Future.delayed(const Duration(seconds: 1)); // Fake Delay

    return [
      ProductModel(
        id: '1',
        name: 'Smart Fridge X1',
        modelNumber: 'SF-2024',
        description: 'Double door smart fridge with wifi.',
        category: 'Electronics',
        subCategory: 'Refrigerator',
        purchasePrice: 120000,
        salePrice: 150000,
        stockQuantity: 15,
        vendorId: 'v1',
        images: ['assets/images/fridge.png'], // Placeholder
        dateAdded: DateTime.now(),
      ),
      ProductModel(
        id: '2',
        name: 'Gaming Laptop Pro',
        modelNumber: 'GL-990',
        description: 'High performance gaming laptop.',
        category: 'Electronics',
        subCategory: 'Laptops',
        purchasePrice: 250000,
        salePrice: 280000,
        stockQuantity: 5, // Low Stock Example
        vendorId: 'v2',
        images: ['assets/images/laptop.png'], // Placeholder
        dateAdded: DateTime.now().subtract(const Duration(days: 2)),
      ),
    ];
  }

  // Simulate Add Product
  Future<void> addProduct(ProductModel product) async {
    await Future.delayed(const Duration(seconds: 2));
    print("Product Added: ${product.name}");
  }

  // Simulate Delete
  Future<void> deleteProduct(String id) async {
    await Future.delayed(const Duration(milliseconds: 500));
    print("Product Deleted: $id");
  }
}
