import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/payment_transaction_model.dart';

class VendorPaymentController extends GetxController {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  var isLoading = false.obs;
  var isDeleting = false.obs;

  DateTime _parseDate(dynamic dateData) {
    if (dateData == null) return DateTime.now();
    if (dateData is Timestamp) return dateData.toDate();
    if (dateData is String)
      return DateTime.tryParse(dateData) ?? DateTime.now();
    return DateTime.now();
  }

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
    bool isEditMode = false,
    String? bankId,
    String? bankName,
    String? screenshotBase64,
    String? chequeNumber,
    DateTime? chequeDate,
  }) async {
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

      DocumentReference purchaseRef = _db
          .collection('vendor_purchases')
          .doc(purchaseId);
      batch.update(purchaseRef, {
        'cashPaid': FieldValue.increment(payingAmount),
        'remainingBalance': FieldValue.increment(-payingAmount),
      });

      QuerySnapshot duesSnapshot = await _db.collection('vendor_dues').get();

      var unpaidDues = duesSnapshot.docs.where((doc) {
        var d = doc.data() as Map<String, dynamic>;
        return d['purchaseId'] == purchaseId && d['isPaid'] == false;
      }).toList();

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

        double originalDueAmount = (dueData['amountDue'] ?? 0.0).toDouble();
        double currentlyPaid = (dueData['paidAmount'] ?? 0.0).toDouble();
        double remainingForThisDue = originalDueAmount - currentlyPaid;

        if (remainingForThisDue < 0) remainingForThisDue = 0;

        if (amountLeftToDistribute >= remainingForThisDue) {
          batch.update(doc.reference, {
            'paidAmount': originalDueAmount,
            'isPaid': true,
            'lastPaymentDate': Timestamp.fromDate(paymentDate),
          });
          amountLeftToDistribute -= remainingForThisDue;
        } else {
          batch.update(doc.reference, {
            'paidAmount': FieldValue.increment(amountLeftToDistribute),
            'lastPaymentDate': Timestamp.fromDate(paymentDate),
          });
          amountLeftToDistribute = 0.0;
        }
      }

      // ✅ FIX: Determine if it's a cheque payment
      bool isCheque = paymentMode == 'Cheque';

      DocumentReference transactionRef = _db
          .collection('vendor_payment_history')
          .doc();

      // ✅ Using regular map instead of model to force isCleared field
      batch.set(transactionRef, {
        'vendorId': vendorId,
        'vendorName': vendorName,
        'dueDocId': "BILL_PAYMENT",
        'billNumber': billNumber,
        'paidAmount': payingAmount,
        'paymentDate': Timestamp.fromDate(paymentDate),
        'paymentMode': paymentMode,
        'note': note,
        'createdAt': FieldValue.serverTimestamp(),
        'bankId': bankId,
        'bankName': bankName,
        'screenshot': screenshotBase64,
        'chequeNumber': chequeNumber,
        'chequeDate': chequeDate != null
            ? Timestamp.fromDate(chequeDate)
            : null,
        'chequeBankId': isCheque ? bankId : null,
        'chequeBankName': isCheque ? bankName : null,
        'isCleared': isCheque ? false : true, // NAYA LOGIC
      });

      // --- NEW LEDGER HOOK: VENDOR PAYMENT ---
      DocumentReference ledgerRef = _db
          .collection('admin_ledger_transactions')
          .doc();
      batch.set(ledgerRef, {
        'type': 'out',
        'category': 'vendor_payment',
        'amount': payingAmount,
        'paymentMethod': paymentMode == 'Cash'
            ? 'cash'
            : (paymentMode == 'Bank Transfer' ? 'online' : 'cheque'),
        'bankId': bankId,
        'bankName': bankName,
        'chequeNumber': chequeNumber,
        'chequeDate': chequeDate != null
            ? Timestamp.fromDate(chequeDate)
            : null,
        'billNumber': billNumber, // ✅ NAYA FIELD ADD KIYA
        'description': 'Payment to Vendor ($vendorName) for Bill #$billNumber',
        'linkedVendorId': vendorId,
        'linkedVendorName': vendorName,
        'screenshotBase64': screenshotBase64,
        'createdBy': isEditMode ? 'admin' : 'system',
        'date': Timestamp.fromDate(paymentDate),
        'createdAt': FieldValue.serverTimestamp(),
        'isCleared': isCheque ? false : true, // NAYA LOGIC
      });

      DocumentReference vendorRef = _db.collection('vendors').doc(vendorId);
      batch.update(vendorRef, {
        'beginningBalance': FieldValue.increment(-payingAmount),
      });

      // ✅ FIX: REAL DEDUCTION FROM BANK OR CASH WITH CORRECT PATH AND CHEQUE CHECK
      if (!isCheque) {
        if (paymentMode == 'Bank Transfer' &&
            bankId != null &&
            bankId.isNotEmpty) {
          DocumentReference bankRef = _db
              .collection('company_finances')
              .doc('main_finances')
              .collection('banks')
              .doc(bankId);
          batch.update(bankRef, {
            'balance': FieldValue.increment(-payingAmount),
          });
        } else if (paymentMode == 'Cash') {
          var cashBankQuery = await _db
              .collection('company_finances')
              .doc('main_finances')
              .collection('banks')
              .where('name', isEqualTo: 'Cash')
              .limit(1)
              .get();
          if (cashBankQuery.docs.isNotEmpty) {
            batch.update(cashBankQuery.docs.first.reference, {
              'balance': FieldValue.increment(-payingAmount),
            });
          }
        }
      }

      await batch.commit();

      isLoading.value = false;
      if (!isEditMode) {
        Get.snackbar(
          "Success",
          "Payment of PKR $payingAmount applied successfully to Bill #$billNumber.",
          backgroundColor: Colors.green.shade900,
          colorText: Colors.white,
        );
      }
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

  Future<bool> editPaymentTransaction({
    required String paymentDocId,
    required String purchaseId,
    required String vendorId,
    required String vendorName,
    required String billNumber,
    required double oldAmount,
    required double newAmount,
    required DateTime paymentDate,
    required String paymentMode,
    required String note,
    String? bankId,
    String? bankName,
    String? screenshotBase64,

    String? chequeNumber,
    DateTime? chequeDate,
  }) async {
    isLoading.value = true;
    try {
      var purchaseSnap = await _db
          .collection('vendor_purchases')
          .doc(purchaseId)
          .get();
      if (!purchaseSnap.exists) throw "Purchase record not found!";

      var pData = purchaseSnap.data() as Map<String, dynamic>;
      double currentRemaining =
          double.tryParse(pData['remainingBalance']?.toString() ?? '0') ?? 0.0;

      double trueRemainingCapacity = currentRemaining + oldAmount;

      if (newAmount > trueRemainingCapacity) {
        Get.snackbar(
          "Limit Exceeded",
          "New amount cannot be greater than Total Bill limit (PKR $trueRemainingCapacity)",
          backgroundColor: Colors.red.shade900,
          colorText: Colors.white,
        );
        isLoading.value = false;
        return false;
      }

      WriteBatch batch = _db.batch();

      // ── REVERSAL PROCESS (Undoing the old payment) ──
      var oldPaySnap = await _db
          .collection('vendor_payment_history')
          .doc(paymentDocId)
          .get();

      if (oldPaySnap.exists) {
        var oldData = oldPaySnap.data() as Map<String, dynamic>;

        // ✅ FIX: Agar old payment Cheque thi aur wo clear nahi hui thi, tou refund ki zaroorat nahi.
        bool oldIsCleared = oldData['isCleared'] ?? true;

        if (oldIsCleared) {
          if (oldData['paymentMode'] == 'Bank Transfer' &&
              oldData['bankId'] != null) {
            batch.update(
              _db
                  .collection('company_finances')
                  .doc('main_finances')
                  .collection('banks')
                  .doc(oldData['bankId']),
              {'balance': FieldValue.increment(oldAmount)},
            );
          } else if (oldData['paymentMode'] == 'Cash') {
            var cashBankQuery = await _db
                .collection('company_finances')
                .doc('main_finances')
                .collection('banks')
                .where('name', isEqualTo: 'Cash')
                .limit(1)
                .get();
            if (cashBankQuery.docs.isNotEmpty) {
              batch.update(cashBankQuery.docs.first.reference, {
                'balance': FieldValue.increment(oldAmount),
              });
            }
          }
        }
      }

      batch.update(purchaseSnap.reference, {
        'cashPaid': FieldValue.increment(-oldAmount),
        'remainingBalance': FieldValue.increment(oldAmount),
      });

      batch.update(_db.collection('vendors').doc(vendorId), {
        'beginningBalance': FieldValue.increment(oldAmount),
      });

      batch.delete(_db.collection('vendor_payment_history').doc(paymentDocId));

      // --- NEW LEDGER HOOK: VENDOR PAYMENT REVERSAL (EDIT) ---
      DocumentReference ledgerReversalRef = _db
          .collection('admin_ledger_transactions')
          .doc();
      batch.set(ledgerReversalRef, {
        'type': 'in', // Reversing an 'out' payment makes it an 'in'
        'category': 'vendor_payment_refund',
        'billNumber': billNumber,
        'amount': oldAmount,
        'paymentMethod': paymentMode == 'Cash'
            ? 'cash'
            : (paymentMode == 'Bank Transfer' ? 'online' : 'cheque'),
        'description':
            'Reversal: Edited Payment to Vendor ($vendorName) for Bill #$billNumber',
        'linkedVendorId': vendorId,
        'linkedVendorName': vendorName,
        'createdBy': 'admin',
        'date': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
      });

      QuerySnapshot duesSnapshot = await _db
          .collection('vendor_dues')
          .where('purchaseId', isEqualTo: purchaseId)
          .get();
      var allDues = duesSnapshot.docs.toList();

      allDues.sort((a, b) {
        var dA = (a.data() as Map)['dueDate'] as Timestamp?;
        var dB = (b.data() as Map)['dueDate'] as Timestamp?;
        return (dB?.toDate() ?? DateTime.now()).compareTo(
          dA?.toDate() ?? DateTime.now(),
        );
      });

      double amountToReverse = oldAmount;

      for (var doc in allDues) {
        if (amountToReverse <= 0) break;

        var dData = doc.data() as Map<String, dynamic>;
        double currentlyPaid = (dData['paidAmount'] ?? 0.0).toDouble();

        if (currentlyPaid > 0) {
          if (currentlyPaid <= amountToReverse) {
            batch.update(doc.reference, {'paidAmount': 0.0, 'isPaid': false});
            amountToReverse -= currentlyPaid;
          } else {
            batch.update(doc.reference, {
              'paidAmount': FieldValue.increment(-amountToReverse),
              'isPaid': false,
            });
            amountToReverse = 0.0;
          }
        }
      }

      await batch.commit();

      // ── RE-APPLY PROCESS (Process payment with new amount) ──
      bool success = await processPayment(
        purchaseId: purchaseId,
        vendorId: vendorId,
        vendorName: vendorName,
        billNumber: billNumber,
        totalBillRemaining: trueRemainingCapacity,
        payingAmount: newAmount,
        paymentDate: paymentDate,
        paymentMode: paymentMode,
        note: "$note (Edited Payment)",
        isEditMode: true,
        bankId: bankId,
        bankName: bankName,
        screenshotBase64: screenshotBase64,
        chequeNumber: chequeNumber,
        chequeDate: chequeDate,
      );

      if (success) {
        Get.snackbar(
          "Payment Edited",
          "Transaction has been successfully updated.",
          backgroundColor: Colors.blue.shade900,
          colorText: Colors.white,
        );
        return true;
      } else {
        throw "Failed to re-apply payment.";
      }
    } catch (e) {
      isLoading.value = false;
      Get.snackbar(
        "Error Editing",
        "Failed to edit payment: $e",
        backgroundColor: Colors.red.shade900,
        colorText: Colors.white,
      );
      return false;
    }
  }

  Future<bool> deleteBillTransaction({
    required String purchaseId,
    required String vendorId,
    required String billNumber,
  }) async {
    isDeleting.value = true;

    try {
      WriteBatch batch = _db.batch();

      DocumentReference purchaseRef = _db
          .collection('vendor_purchases')
          .doc(purchaseId);
      batch.delete(purchaseRef);

      QuerySnapshot duesSnapshot = await _db
          .collection('vendor_dues')
          .where('purchaseId', isEqualTo: purchaseId)
          .get();
      for (var doc in duesSnapshot.docs) {
        batch.delete(doc.reference);
      }

      QuerySnapshot historySnapshot = await _db
          .collection('vendor_payment_history')
          .where('vendorId', isEqualTo: vendorId)
          .where('billNumber', isEqualTo: billNumber)
          .get();
      for (var doc in historySnapshot.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();

      isDeleting.value = false;

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
        colorText: const Color.fromRGBO(255, 255, 255, 1),
      );
      return false;
    }
  }
}
