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

    String allProductsJoined = purchase.items
        .map((item) => item['productName'])
        .join(", ");

    // 4. Save Installment Schedule
    if (schedule.isNotEmpty) {
      for (var inst in schedule) {
        DocumentReference instRef = _db.collection('vendor_dues').doc();
        double originalAmt = (inst['amountDue'] ?? 0.0).toDouble();

        inst.addAll({
          'purchaseId': purchaseRef.id,
          'vendorId': purchase.vendorId,
          'vendorName': purchase.vendorName,
          'productName': allProductsJoined,
          'isPaid': false,
          'originalAmountDue': originalAmt,
          'createdAt': FieldValue.serverTimestamp(),
        });
        batch.set(instRef, inst);
      }
    }

    // ✅ 5. INITIAL PAYMENT DEDUCTION LOGIC (Bank / Cash Deduction & Payment History)
    if (purchase.cashPaid > 0) {
      // 5A. Save Payment History Record
      DocumentReference transactionRef = _db
          .collection('vendor_payment_history')
          .doc();
      batch.set(transactionRef, {
        'vendorId': purchase.vendorId,
        'vendorName': purchase.vendorName,
        'dueDocId': "INITIAL_PAYMENT",
        'billNumber': purchase.billNumber,
        'paidAmount': purchase.cashPaid,
        'paymentDate': Timestamp.fromDate(purchase.date),
        'paymentMode': purchase.initialTransactionMode ?? 'Cash',
        'note': "Upfront payment at bill generation",
        'createdAt': FieldValue.serverTimestamp(),
        'bankId': purchase.initialBankId,
        'bankName': purchase.initialBankName,
        'screenshot': purchase.initialScreenshot,
        'chequeNumber': purchase.initialChequeNumber,
        'chequeDate': purchase.initialChequeDate != null
            ? Timestamp.fromDate(purchase.initialChequeDate!)
            : null,
      });

      // 5B. Real-Time Bank/Cash Money Deduction
      if (purchase.initialTransactionMode == 'Bank Transfer' &&
          purchase.initialBankId != null &&
          purchase.initialBankId!.isNotEmpty) {
        DocumentReference bankRef = _db
            .collection('company_finances')
            .doc('main_finances')
            .collection('banks')
            .doc(purchase.initialBankId);
        batch.update(bankRef, {
          'balance': FieldValue.increment(-purchase.cashPaid),
        });
      } else if (purchase.initialTransactionMode == 'Cash' ||
          purchase.initialTransactionMode == null) {
        var cashBankQuery = await _db
            .collection('company_finances')
            .doc('main_finances')
            .collection('banks')
            .where('name', isEqualTo: 'Cash')
            .limit(1)
            .get();
        if (cashBankQuery.docs.isNotEmpty) {
          batch.update(cashBankQuery.docs.first.reference, {
            'balance': FieldValue.increment(-purchase.cashPaid),
          });
        }
      }
    }

    await batch.commit();
  }
}
