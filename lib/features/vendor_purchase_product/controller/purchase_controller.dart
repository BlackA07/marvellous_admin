import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../models/purchase_model.dart';
import '../repository/purchase_repository.dart';

class PurchaseController extends GetxController {
  final PurchaseRepository _repo = PurchaseRepository();
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  var isLoading = false.obs;
  var vendors = [].obs;
  var products = [].obs;

  var selectedVendor = Rxn<Map<String, dynamic>>();
  var previousBalance = 0.0.obs;
  var installmentChart = <Map<String, dynamic>>[].obs;
  var billDate = DateTime.now().obs;
  var addedItems = <Map<String, dynamic>>[].obs;

  @override
  void onInit() {
    super.onInit();
    loadInitialData();
  }

  void loadInitialData() async {
    var vDocs = await _repo.getVendors();
    vendors.assignAll(
      vDocs.docs
          .map((e) => {'id': e.id, ...e.data() as Map<String, dynamic>})
          .toList(),
    );

    var pDocs = await _repo.getProducts();
    products.assignAll(
      pDocs.docs
          .map((e) => {'id': e.id, ...e.data() as Map<String, dynamic>})
          .toList(),
    );
  }

  void setVendor(Map<String, dynamic> vendor) {
    selectedVendor.value = vendor;
    previousBalance.value = (vendor['beginningBalance'] ?? 0.0).toDouble();
  }

  Future<void> loadOrderRequest(Map<String, dynamic> requestData) async {
    isLoading.value = true;
    clearData();

    try {
      var vDoc = await _db
          .collection('vendors')
          .doc(requestData['vendorId'])
          .get();
      if (vDoc.exists) {
        setVendor({'id': vDoc.id, ...vDoc.data() as Map<String, dynamic>});
      }

      List reqItems = requestData['items'] ?? [];
      for (var item in reqItems) {
        if (item['isAvailable'] != false) {
          int qty = item['requestQty'] ?? 1;
          double price = (item['purchasePrice'] ?? 0).toDouble();

          String prodImg = item['image'] ?? '';
          if (prodImg.isEmpty) {
            try {
              var pDoc = await _db
                  .collection('products')
                  .doc(item['productId'])
                  .get();
              if (pDoc.exists) {
                var pData = pDoc.data() as Map<String, dynamic>;
                if (pData['images'] != null &&
                    (pData['images'] as List).isNotEmpty) {
                  prodImg = pData['images'][0];
                }
              }
            } catch (e) {}
          }

          addedItems.add({
            'productId': item['productId'],
            'productName': item['productName'],
            'brand': item['brand'] ?? 'N/A',
            'model': item['model'] ?? 'N/A',
            'image': prodImg,
            'quantity': qty,
            'unitPrice': price,
            'totalItemPrice': qty * price,
          });
        }
      }
    } catch (e) {
      Get.snackbar(
        "Error",
        "Could not load order request: $e",
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }

    isLoading.value = false;
  }

  void addItemToBill(Map<String, dynamic> product, int qty, double price) {
    String prodImg = '';
    if (product['images'] != null && (product['images'] as List).isNotEmpty) {
      prodImg = product['images'][0];
    }

    addedItems.add({
      'productId': product['id'],
      'productName': product['name'],
      'brand': product['brand'],
      'model': product['modelNumber'],
      'image': prodImg,
      'quantity': qty,
      'unitPrice': price,
      'totalItemPrice': qty * price,
    });
  }

  void removeItemFromBill(int index) {
    addedItems.removeAt(index);
  }

  double calculateGrandTotal() {
    double total = 0;
    for (var item in addedItems) {
      total += item['totalItemPrice'];
    }
    return total;
  }

  void clearData() {
    selectedVendor.value = null;
    addedItems.clear();
    previousBalance.value = 0.0;
    billDate.value = DateTime.now();
    installmentChart.clear();
  }

  String _generateBillNumber(String paymentMode, String? creditType) {
    String prefix = 'B';
    if (paymentMode == 'Cash') {
      prefix = 'CA';
    } else if (paymentMode == 'Both') {
      if (creditType == 'Daily')
        prefix = 'BD';
      else if (creditType == 'Weekly')
        prefix = 'BW';
      else if (creditType == 'Monthly')
        prefix = 'BM';
      else
        prefix = 'BC';
    } else if (paymentMode == 'Credit') {
      if (creditType == 'Daily')
        prefix = 'D';
      else if (creditType == 'Weekly')
        prefix = 'W';
      else if (creditType == 'Monthly')
        prefix = 'M';
      else
        prefix = 'C';
    }

    int randomNum = Random().nextInt(9000) + 1000;
    return "$prefix-$randomNum";
  }

  void generatePreviewChart({
    required double currentBill,
    required double firstPaymentAmount,
    required DateTime? firstPaymentDate,
    required double perInstallment,
    required DateTime? startDate,
    required String type,
  }) {
    installmentChart.clear();
    double totalAmount = currentBill + previousBalance.value;
    double tempRemainingTotal = totalAmount;
    double tempRemainingProduct = currentBill;

    installmentChart.add({
      'date': '-',
      'day': '-',
      'amount': '-',
      'paid': '-',
      'remaining_product': tempRemainingProduct.toStringAsFixed(0),
      'remaining_total': tempRemainingTotal.toStringAsFixed(0),
      'note': 'Total Balance',
    });

    if (firstPaymentAmount > 0 && firstPaymentDate != null) {
      tempRemainingTotal -= firstPaymentAmount;
      tempRemainingProduct = tempRemainingProduct >= firstPaymentAmount
          ? tempRemainingProduct - firstPaymentAmount
          : 0;

      installmentChart.add({
        'date': DateFormat('dd-MMM-yy').format(firstPaymentDate),
        'day': DateFormat('EEEE').format(firstPaymentDate).substring(0, 3),
        'amount': firstPaymentAmount.toStringAsFixed(0),
        'paid': '0',
        'remaining_product': tempRemainingProduct.toStringAsFixed(0),
        'remaining_total': tempRemainingTotal.toStringAsFixed(0),
        'note': 'First Payment',
      });
    }

    if (type != 'Custom' &&
        startDate != null &&
        perInstallment > 0 &&
        tempRemainingTotal > 0) {
      double nextPay = tempRemainingTotal > perInstallment
          ? perInstallment
          : tempRemainingTotal;
      tempRemainingTotal -= nextPay;
      tempRemainingProduct = tempRemainingProduct >= nextPay
          ? tempRemainingProduct - nextPay
          : 0;

      installmentChart.add({
        'date': DateFormat('dd-MMM-yy').format(startDate),
        'day': DateFormat('EEEE').format(startDate).substring(0, 3),
        'amount': nextPay.toStringAsFixed(0),
        'paid': '0',
        'remaining_product': tempRemainingProduct.toStringAsFixed(0),
        'remaining_total': tempRemainingTotal.toStringAsFixed(0),
        'note': 'Next Installment',
      });
    }
  }

  Future<bool> submitTransaction({
    required double totalBill,
    required String paymentMode,
    required double cashPaid,
    required String creditType,
    required List<String> selectedDays,
    required DateTime? firstPaymentDate,
    required double firstPaymentAmount,
    required DateTime? startingDate,
    required double perInstallmentAmount,
    int? customDaysLimit,
    required String transactionMode,
    String? bankId,
    String? bankName,
    String? screenshotBase64,
    String? chequeNumber,
    DateTime? chequeDate,
  }) async {
    if (selectedVendor.value == null || addedItems.isEmpty) {
      Get.snackbar(
        "Error",
        "Please select a vendor and add at least one product.",
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
      );
      return false;
    }

    isLoading.value = true;

    try {
      double remainingForThisBill = totalBill - cashPaid;
      String generatedBillNumber = _generateBillNumber(paymentMode, creditType);

      PurchaseModel newPurchase = PurchaseModel(
        billNumber: generatedBillNumber,
        date: billDate.value,
        vendorId: selectedVendor.value!['id'],
        vendorName:
            "${selectedVendor.value!['storeName']} (${selectedVendor.value!['ownerName']})",
        items: addedItems,
        totalBillAmount: totalBill,
        paymentMode: paymentMode,
        cashPaid: cashPaid,
        remainingBalance: remainingForThisBill,
        creditType: creditType,
        selectedDays: selectedDays,
        firstPaymentDate: firstPaymentDate,
        startingDate: startingDate,
        perInstallmentAmount: perInstallmentAmount,
        customDaysLimit: customDaysLimit,
      );

      List<Map<String, dynamic>> realSchedule = [];

      Future<void> _recordPaymentHistory(
        String docIdNote,
        DateTime payDate,
        double amt,
        String noteText,
      ) async {
        var historyData = {
          'vendorId': selectedVendor.value!['id'],
          'vendorName':
              "${selectedVendor.value!['storeName']} (${selectedVendor.value!['ownerName']})",
          'dueDocId': docIdNote,
          'billNumber': generatedBillNumber,
          'paidAmount': amt,
          'paymentDate': Timestamp.fromDate(payDate),
          'paymentMode': transactionMode,
          'note': noteText,
          'createdAt': Timestamp.now(),
        };

        if (transactionMode == 'Bank Transfer') {
          historyData['bankId'] = bankId ?? '';
          historyData['bankName'] = bankName ?? '';
          historyData['screenshot'] = screenshotBase64 ?? '';
        } else if (transactionMode == 'Cheque') {
          historyData['chequeNumber'] = chequeNumber ?? '';
          historyData['chequeDate'] = chequeDate != null
              ? Timestamp.fromDate(chequeDate)
              : null;
        }

        await _db.collection('vendor_payment_history').add(historyData);
      }

      if (paymentMode == "Cash") {
        realSchedule.add({
          'dueDate': Timestamp.fromDate(billDate.value),
          'amountDue': totalBill,
          'note': 'Cash Payment Full',
          'billNumber': generatedBillNumber,
          'isPaid': true,
          'paidAmount': cashPaid,
        });

        await _recordPaymentHistory(
          'CASH_PAYMENT',
          billDate.value,
          cashPaid,
          'Cash Payment Full for Bill #$generatedBillNumber',
        );
      } else if (paymentMode == "Credit" || paymentMode == "Both") {
        double scheduleRemaining = remainingForThisBill;
        if (firstPaymentAmount > 0 && firstPaymentDate != null) {
          scheduleRemaining -= firstPaymentAmount;
          realSchedule.add({
            'dueDate': Timestamp.fromDate(firstPaymentDate),
            'amountDue': firstPaymentAmount,
            'note': 'First/Advance Payment',
            'billNumber': generatedBillNumber,
            'isPaid': false,
            'paidAmount': 0.0,
          });

          if (cashPaid > 0) {
            await _recordPaymentHistory(
              'ADVANCE_PAYMENT',
              firstPaymentDate,
              cashPaid,
              'Advance Payment for Bill #$generatedBillNumber',
            );
          }
        }

        if (creditType != "Custom") {
          DateTime currentDate = startingDate ?? DateTime.now();
          int safetyCounter = 0;

          while (scheduleRemaining > 0 && safetyCounter < 1000) {
            safetyCounter++;
            String dayName = DateFormat('EEEE').format(currentDate);
            bool shouldPay = false;

            if (creditType == 'Daily' || creditType == 'Weekly') {
              if (selectedDays.contains(dayName)) shouldPay = true;
            } else if (creditType == 'Monthly') {
              shouldPay = true;
            }

            if (shouldPay) {
              double currentPay = scheduleRemaining > perInstallmentAmount
                  ? perInstallmentAmount
                  : scheduleRemaining;
              scheduleRemaining -= currentPay;

              realSchedule.add({
                'dueDate': Timestamp.fromDate(currentDate),
                'amountDue': currentPay,
                'note': 'Regular Installment',
                'billNumber': generatedBillNumber,
                'isPaid': false,
                'paidAmount': 0.0,
              });
            }

            if (creditType == 'Monthly') {
              currentDate = DateTime(
                currentDate.year,
                currentDate.month + 1,
                currentDate.day,
              );
            } else {
              currentDate = currentDate.add(const Duration(days: 1));
            }
          }
        }
      }

      await _repo.savePurchase(newPurchase, realSchedule);

      // ✅ FIX: BANK AND CASH DEDUCTION LOGIC
      if (cashPaid > 0) {
        if (transactionMode == 'Bank Transfer' &&
            bankId != null &&
            bankId.isNotEmpty) {
          DocumentReference bankRef = _db
              .collection('company_finances')
              .doc('main_finances')
              .collection('banks')
              .doc(bankId);
          await bankRef.update({'balance': FieldValue.increment(-cashPaid)});
        } else if (transactionMode == 'Cash') {
          // Cash bank se deduct karo jahan name 'Cash' ho
          var cashBankQuery = await _db
              .collection('company_finances')
              .doc('main_finances')
              .collection('banks')
              .where('bankName', isEqualTo: 'Cash')
              .limit(1)
              .get();
          if (cashBankQuery.docs.isNotEmpty) {
            await cashBankQuery.docs.first.reference.update({
              'balance': FieldValue.increment(-cashPaid),
            });
          }
        }
      }

      if (Get.arguments != null && Get.arguments['orderRequest'] != null) {
        String reqId = Get.arguments['orderRequest']['requestId'];
        if (reqId.isNotEmpty) {
          await _db.collection('order_requests').doc(reqId).update({
            'status': 'completed',
          });
        }
      }

      isLoading.value = false;
      return true;
    } catch (e) {
      isLoading.value = false;
      Get.snackbar(
        "Error",
        "Transaction failed: $e",
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
      );
      return false;
    }
  }
}
