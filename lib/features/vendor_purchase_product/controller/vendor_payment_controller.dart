import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/payment_transaction_model.dart';

class VendorPaymentController extends GetxController {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  var isLoading = false.obs;
  var isDeleting = false.obs; // ✅ NAYA: Delete processing loader

  DateTime _parseDate(dynamic dateData) {
    if (dateData == null) return DateTime.now();
    if (dateData is Timestamp) return dateData.toDate();
    if (dateData is String)
      return DateTime.tryParse(dateData) ?? DateTime.now();
    return DateTime.now();
  }

  // ✅ FLEXIBLE PAYMENT PROCESSING LOGIC (Unchanged - Exact same as yours)
  Future<bool> processPayment({
    required String purchaseId,
    required String vendorId,
    required String vendorName,
    required String billNumber,
    required double totalBillRemaining,
    required double payingAmount,
    required DateTime paymentDate,
    required String paymentMode,
    required String note,
  }) async {
    // 1. Validations
    if (payingAmount <= 0) {
      Get.snackbar(
        "Invalid Amount",
        "Paying amount must be greater than zero.",
        backgroundColor: Colors.black,
        colorText: Colors.white,
      );
      return false;
    }

    if (payingAmount > totalBillRemaining) {
      Get.snackbar(
        "Amount Exceeded",
        "You cannot pay more than the remaining bill amount (PKR $totalBillRemaining).",
        backgroundColor: Colors.red.shade900,
        colorText: Colors.white,
      );
      return false;
    }

    isLoading.value = true;

    try {
      WriteBatch batch = _db.batch();

      // --- A. Update `vendor_purchases` (Main Bill Balance) ---
      DocumentReference purchaseRef = _db
          .collection('vendor_purchases')
          .doc(purchaseId);
      batch.update(purchaseRef, {
        'cashPaid': FieldValue.increment(payingAmount),
        'remainingBalance': FieldValue.increment(-payingAmount),
      });

      // --- B. Distribute Amount among Unpaid Installments (`vendor_dues`) ---
      QuerySnapshot duesSnapshot = await _db.collection('vendor_dues').get();

      var unpaidDues = duesSnapshot.docs.where((doc) {
        var d = doc.data() as Map<String, dynamic>;
        return d['purchaseId'] == purchaseId && d['isPaid'] == false;
      }).toList();

      // Safe Date Sorting
      unpaidDues.sort((a, b) {
        var dataA = a.data() as Map<String, dynamic>;
        var dataB = b.data() as Map<String, dynamic>;
        DateTime dA = dataA['dueDate'] is Timestamp
            ? (dataA['dueDate'] as Timestamp).toDate()
            : DateTime.now();
        DateTime dB = dataB['dueDate'] is Timestamp
            ? (dataB['dueDate'] as Timestamp).toDate()
            : DateTime.now();
        return dA.compareTo(dB);
      });

      double amountLeftToDistribute = payingAmount;

      for (var doc in unpaidDues) {
        if (amountLeftToDistribute <= 0) break;

        var dueData = doc.data() as Map<String, dynamic>;

        // ✅ LOGIC FIX: Never change original amountDue. Only compare with paidAmount.
        double originalDueAmount = (dueData['amountDue'] ?? 0.0).toDouble();
        double currentlyPaid = (dueData['paidAmount'] ?? 0.0).toDouble();
        double remainingForThisDue = originalDueAmount - currentlyPaid;

        if (remainingForThisDue < 0) remainingForThisDue = 0;

        if (amountLeftToDistribute >= remainingForThisDue) {
          batch.update(doc.reference, {
            'paidAmount': originalDueAmount, // Fully paid
            'isPaid': true,
            'lastPaymentDate': Timestamp.fromDate(paymentDate),
          });
          amountLeftToDistribute -= remainingForThisDue;
        } else {
          batch.update(doc.reference, {
            'paidAmount': FieldValue.increment(
              amountLeftToDistribute,
            ), // Partially paid
            'lastPaymentDate': Timestamp.fromDate(paymentDate),
          });
          amountLeftToDistribute = 0.0;
        }
      }

      // --- C. Create Payment History Record (`vendor_payment_history`) ---
      DocumentReference transactionRef = _db
          .collection('vendor_payment_history')
          .doc();
      PaymentTransactionModel transaction = PaymentTransactionModel(
        vendorId: vendorId,
        vendorName: vendorName,
        dueDocId: "BILL_PAYMENT",
        billNumber: billNumber,
        paidAmount: payingAmount,
        paymentDate: paymentDate,
        paymentMode: paymentMode,
        note: note,
        createdAt: DateTime.now(),
      );
      batch.set(transactionRef, transaction.toMap());

      // --- D. Update Vendor's Global Balance in `vendors` profile ---
      DocumentReference vendorRef = _db.collection('vendors').doc(vendorId);
      batch.update(vendorRef, {
        'beginningBalance': FieldValue.increment(-payingAmount),
      });

      await batch.commit();

      isLoading.value = false;
      Get.snackbar(
        "Success",
        "Payment of PKR $payingAmount applied successfully to Bill #$billNumber.",
        backgroundColor: Colors.green.shade900,
        colorText: Colors.white,
      );
      return true;
    } catch (e) {
      isLoading.value = false;
      Get.snackbar(
        "Processing Error",
        "Failed to process payment: $e",
        backgroundColor: Colors.red.shade900,
        colorText: Colors.white,
      );
      return false;
    }
  }

  // ==============================================================
  // ✅ NEW: DELETE BILL LOGIC (Without Reversing Vendor Balance)
  // ==============================================================
  Future<bool> deleteBillTransaction({
    required String purchaseId,
    required String vendorId,
    required String billNumber,
  }) async {
    isDeleting.value = true;

    try {
      WriteBatch batch = _db.batch();

      // 1. Delete the Main Purchase Record
      DocumentReference purchaseRef = _db
          .collection('vendor_purchases')
          .doc(purchaseId);
      batch.delete(purchaseRef);

      // 2. Delete all Installments/Dues related to this bill
      QuerySnapshot duesSnapshot = await _db
          .collection('vendor_dues')
          .where('purchaseId', isEqualTo: purchaseId)
          .get();
      for (var doc in duesSnapshot.docs) {
        batch.delete(doc.reference);
      }

      // 3. Delete all Payment History related to this bill
      QuerySnapshot historySnapshot = await _db
          .collection('vendor_payment_history')
          .where('vendorId', isEqualTo: vendorId)
          .where('billNumber', isEqualTo: billNumber)
          .get();
      for (var doc in historySnapshot.docs) {
        batch.delete(doc.reference);
      }

      // NOTE: Vendor Balance is INTENTIONALLY NOT REVERSED here as per requirement.

      await batch.commit();

      isDeleting.value = false;

      // ✅ Success Alert with Manual Update Notice
      Get.defaultDialog(
        title: "Bill Deleted Successfully",
        titleStyle: GoogleFonts.comicNeue(
          fontWeight: FontWeight.w900,
          color: Colors.green.shade900,
          fontSize: 24,
        ),
        content: Text(
          "Bill #$billNumber has been permanently deleted.\n\nNOTE: The Vendor's ledger balance has NOT been reversed. Please adjust the vendor's beginning balance manually if required.",
          textAlign: TextAlign.center,
          style: GoogleFonts.comicNeue(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        confirm: ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: Colors.black),
          onPressed: () => Get.back(),
          child: Text(
            "Understood",
            style: GoogleFonts.comicNeue(
              color: const Color.fromARGB(255, 255, 255, 255),
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      );

      return true;
    } catch (e) {
      isDeleting.value = false;
      Get.snackbar(
        "Delete Error",
        "Failed to delete bill: $e",
        backgroundColor: Colors.red.shade900,
        colorText: Colors.white,
      );
      return false;
    }
  }
}
