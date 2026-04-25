import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/purchase_model.dart';

class PurchaseRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // 1. Fetch Vendors for Search
  Future<QuerySnapshot> getVendors() => _db.collection('vendors').get();

  // 2. Fetch Products for Search
  Future<QuerySnapshot> getProducts() => _db.collection('products').get();

  // 3. Save Purchase Transaction
  Future<void> savePurchase(
    PurchaseModel purchase,
    List<Map<String, dynamic>> schedule,
  ) async {
    final batch = _db.batch();

    // 1. Save Purchase record
    DocumentReference purchaseRef = _db.collection('vendor_purchases').doc();
    batch.set(purchaseRef, purchase.toMap());

    // 2. Update Vendor's main profile (beginningBalance)
    DocumentReference vendorRef = _db
        .collection('vendors')
        .doc(purchase.vendorId);
    batch.update(vendorRef, {
      'beginningBalance': FieldValue.increment(purchase.remainingBalance),
    });

    // 3. Update Vendor Ledger (For tracking history)
    DocumentReference ledgerRef = _db
        .collection('vendor_ledger')
        .doc(purchase.vendorId);
    batch.set(ledgerRef, {
      'vendorId': purchase.vendorId,
      'vendorName': purchase.vendorName,
      'lastUpdated': FieldValue.serverTimestamp(),
      'totalOutstanding': FieldValue.increment(purchase.remainingBalance),
    }, SetOptions(merge: true));

    // ✅ FIX: Extract all product names from the list to show in Finance Screen
    String allProductsJoined = purchase.items
        .map((item) => item['productName'])
        .join(", ");

    // 4. Save Installment Schedule (These are the DUES to be paid in Finance screen)
    if (schedule.isNotEmpty) {
      for (var inst in schedule) {
        DocumentReference instRef = _db.collection('vendor_dues').doc();

        // ✅ originalAmountDue: paid hone ke baad bhi original amount yaad rahe
        double originalAmt = (inst['amountDue'] ?? 0.0).toDouble();

        inst.addAll({
          'purchaseId': purchaseRef.id,
          'vendorId': purchase.vendorId,
          'vendorName': purchase.vendorName,
          'productName': allProductsJoined,
          'isPaid': false,
          'originalAmountDue': originalAmt, // ✅ SIRF YEH EK LINE ADD HUI HAI
          'createdAt': FieldValue.serverTimestamp(),
        });
        batch.set(instRef, inst);
      }
    }

    await batch.commit();
  }
}
