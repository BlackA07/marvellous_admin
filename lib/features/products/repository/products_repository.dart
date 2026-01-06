import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/product_model.dart';

class ProductsRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference get _products => _firestore.collection('products');
  // New Collection for storing Search History/Keywords
  CollectionReference get _searchHistory =>
      _firestore.collection('admin_search_history');

  // --- PRODUCT CRUD ---

  // 1. Fetch All (Products & Packages)
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
      if (product.id == null) throw Exception("Product ID missing");
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

  // --- SEARCH HISTORY / KEYWORDS MANAGEMENT ---

  // Fetch History List
  Future<List<String>> fetchSearchHistory() async {
    try {
      QuerySnapshot snapshot = await _searchHistory.orderBy('term').get();
      return snapshot.docs.map((doc) => doc['term'] as String).toList();
    } catch (e) {
      return []; // Return empty if fail/first time
    }
  }

  // Add Term to History
  Future<void> addSearchTerm(String term) async {
    try {
      if (term.trim().isEmpty) return;
      // Check if exists logic can be handled here or by using doc id as term
      await _searchHistory.doc(term.toLowerCase()).set({
        'term': term,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print("Error adding history: $e");
    }
  }

  // Delete Single Term
  Future<void> deleteSearchTerm(String term) async {
    try {
      await _searchHistory.doc(term.toLowerCase()).delete();
    } catch (e) {
      throw Exception("Failed to delete term");
    }
  }

  // Clear All History
  Future<void> clearAllHistory() async {
    try {
      var snapshot = await _searchHistory.get();
      for (var doc in snapshot.docs) {
        await doc.reference.delete();
      }
    } catch (e) {
      throw Exception("Failed to clear history");
    }
  }
}
