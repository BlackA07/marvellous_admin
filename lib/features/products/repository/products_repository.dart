import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/product_model.dart';

class ProductsRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference get _products => _firestore.collection('products');
  CollectionReference get _packages => _firestore.collection('packages');
  CollectionReference get _searchHistory =>
      _firestore.collection('admin_search_history');

  Future<List<ProductModel>> fetchProducts() async {
    try {
      List<ProductModel> allItems = [];

      QuerySnapshot productSnap = await _products
          .orderBy('dateAdded', descending: true)
          .get();
      allItems.addAll(
        productSnap.docs.map(
          (doc) =>
              ProductModel.fromMap(doc.data() as Map<String, dynamic>, doc.id),
        ),
      );

      QuerySnapshot packageSnap = await _packages
          .orderBy('dateAdded', descending: true)
          .get();
      allItems.addAll(
        packageSnap.docs.map((doc) {
          var p = ProductModel.fromMap(
            doc.data() as Map<String, dynamic>,
            doc.id,
          );
          p.isPackage = true;
          return p;
        }),
      );

      allItems.sort((a, b) => b.dateAdded.compareTo(a.dateAdded));

      return allItems;
    } catch (e) {
      throw Exception("Failed to load items: $e");
    }
  }

  Future<void> addProduct(ProductModel product) async {
    try {
      if (!product.isPackage) {
        // 1. Get the last ID to increment correctly
        QuerySnapshot snap = await _products
            .orderBy(
              'id',
              descending: true,
            ) // Assuming 'id' field exists as string/number in doc
            .limit(1)
            .get();

        // Fallback: If ordering by string ID gives issues, you might need a separate counter document.
        // But for now, fixing the .set() logic:

        int lastId = 0;
        if (snap.docs.isNotEmpty) {
          // Try to parse the document ID itself if it's stored as "1", "2"
          // Or the 'id' field inside the data
          var data = snap.docs.first.data() as Map<String, dynamic>;
          lastId =
              int.tryParse(data['id']?.toString() ?? snap.docs.first.id) ?? 0;
        }

        product.id = (lastId + 1).toString();

        // --- FIX IS HERE: Use .doc().set() instead of .add() ---
        // This ensures the Document ID matches '1', '2', etc.
        await _products.doc(product.id).set(product.toMap());
      } else {
        // Packages can use auto-ID or specific logic
        await _packages.add(product.toMap());
      }
    } catch (e) {
      throw Exception("Failed to add: $e");
    }
  }

  Future<void> updateProduct(ProductModel product) async {
    try {
      if (product.id == null) throw Exception("ID missing");

      if (product.isPackage) {
        await _packages.doc(product.id).update(product.toMap());
      } else {
        // This line caused error before because doc(1) didn't exist. Now it will work.
        await _products.doc(product.id).update(product.toMap());
      }
    } catch (e) {
      throw Exception("Failed to update: $e");
    }
  }

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
