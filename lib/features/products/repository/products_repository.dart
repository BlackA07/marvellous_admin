import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/product_model.dart';

class ProductsRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference get _products => _firestore.collection('products');
  CollectionReference get _packages => _firestore.collection('packages');
  CollectionReference get _searchHistory =>
      _firestore.collection('admin_search_history');

  DocumentReference get _counterDoc =>
      _firestore.collection('admin_settings').doc('product_counter');

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
        String newId = await _firestore.runTransaction<String>((
          transaction,
        ) async {
          DocumentSnapshot counterSnap = await transaction.get(_counterDoc);
          int currentId = 0;
          if (counterSnap.exists) {
            currentId =
                (counterSnap.data() as Map<String, dynamic>)['lastProductId'] ??
                0;
          }
          int nextId = currentId + 1;
          transaction.set(_counterDoc, {
            'lastProductId': nextId,
            'updatedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));

          return nextId.toString();
        });

        product.id = newId;
        await _products.doc(product.id).set(product.toMap());
        print("✅ Product added successfully with ID: ${product.id}");
      } else {
        DocumentReference docRef = await _packages.add(product.toMap());
        product.id = docRef.id;
        print("✅ Package added successfully with ID: ${product.id}");
      }
    } catch (e) {
      print("❌ Error adding product: $e");
      throw Exception("Failed to add: $e");
    }
  }

  Future<void> updateProduct(ProductModel product) async {
    try {
      if (product.id == null || product.id!.isEmpty) {
        throw Exception("Product ID is missing");
      }
      if (product.isPackage) {
        await _packages.doc(product.id).update(product.toMap());
      } else {
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
