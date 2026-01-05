import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/product_model.dart';

class ProductsRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  CollectionReference get _products => _firestore.collection('products');

  // 1. Fetch
  Future<List<ProductModel>> fetchProducts() async {
    try {
      QuerySnapshot snapshot = await _products
          .orderBy('dateAdded', descending: true)
          .get();
      return snapshot.docs.map((doc) {
        return ProductModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }).toList();
    } catch (e) {
      throw Exception("Failed to load products: $e");
    }
  }

  // 2. Add
  Future<void> addProduct(ProductModel product) async {
    try {
      await _products.add(product.toMap());
    } catch (e) {
      throw Exception("Failed to add product: $e");
    }
  }

  // 3. Update
  Future<void> updateProduct(ProductModel product) async {
    try {
      if (product.id == null) {
        throw Exception("Product ID is missing for update");
      }
      await _products.doc(product.id).update(product.toMap());
    } catch (e) {
      throw Exception("Failed to update product: $e");
    }
  }

  // 4. Delete
  Future<void> deleteProduct(String id) async {
    try {
      await _products.doc(id).delete();
    } catch (e) {
      throw Exception("Failed to delete product: $e");
    }
  }
}
