import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/product_model.dart';

class ProductsRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference get _products => _firestore.collection('products');
  // New Collection for Packages
  CollectionReference get _packages => _firestore.collection('packages');

  CollectionReference get _searchHistory =>
      _firestore.collection('admin_search_history');

  // --- FETCH ALL (Products + Packages) ---
  // To keep existing logic working, we can fetch both and merge,
  // OR if you want them strictly separate, we handle them separately.
  // Assuming 'products_controller' wants a master list.

  Future<List<ProductModel>> fetchProducts() async {
    try {
      List<ProductModel> allItems = [];

      // 1. Fetch Products
      QuerySnapshot productSnap = await _products
          .orderBy('dateAdded', descending: true)
          .get();
      allItems.addAll(
        productSnap.docs.map((doc) {
          return ProductModel.fromMap(
            doc.data() as Map<String, dynamic>,
            doc.id,
          );
        }),
      );

      // 2. Fetch Packages
      QuerySnapshot packageSnap = await _packages
          .orderBy('dateAdded', descending: true)
          .get();
      allItems.addAll(
        packageSnap.docs.map((doc) {
          var p = ProductModel.fromMap(
            doc.data() as Map<String, dynamic>,
            doc.id,
          );
          p.isPackage = true; // Ensure flag is set
          return p;
        }),
      );

      // Sort combined list by date
      allItems.sort((a, b) => b.dateAdded.compareTo(a.dateAdded));

      return allItems;
    } catch (e) {
      throw Exception("Failed to load items: $e");
    }
  }

  // --- ADD ---
  Future<void> addProduct(ProductModel product) async {
    try {
      if (product.isPackage) {
        await _packages.add(product.toMap());
      } else {
        await _products.add(product.toMap());
      }
    } catch (e) {
      throw Exception("Failed to add: $e");
    }
  }

  // --- UPDATE ---
  Future<void> updateProduct(ProductModel product) async {
    try {
      if (product.id == null) throw Exception("ID missing");

      if (product.isPackage) {
        await _packages.doc(product.id).update(product.toMap());
      } else {
        await _products.doc(product.id).update(product.toMap());
      }
    } catch (e) {
      throw Exception("Failed to update: $e");
    }
  }

  // --- DELETE ---
  // Since we don't know if ID belongs to product or package easily without checking,
  // we try deleting from both (or check isPackage in controller before calling).
  // Better approach: Pass isPackage flag to delete.
  Future<void> deleteProduct(String id, {bool isPackage = false}) async {
    try {
      if (isPackage) {
        await _packages.doc(id).delete();
      } else {
        await _products.doc(id).delete();
      }
    } catch (e) {
      throw Exception("Failed to delete: $e");
    }
  }

  // --- HISTORY ---
  Future<List<String>> fetchSearchHistory() async {
    try {
      QuerySnapshot snapshot = await _searchHistory.orderBy('term').get();
      return snapshot.docs.map((doc) => doc['term'] as String).toList();
    } catch (e) {
      return [];
    }
  }

  Future<void> addSearchTerm(String term) async {
    try {
      if (term.trim().isEmpty) return;
      await _searchHistory.doc(term.toLowerCase()).set({
        'term': term,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print("Error adding history: $e");
    }
  }

  Future<void> deleteSearchTerm(String term) async {
    try {
      await _searchHistory.doc(term.toLowerCase()).delete();
    } catch (e) {
      throw Exception("Failed to delete term");
    }
  }

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
