import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../models/purchase_model.dart';
import '../repository/purchase_repository.dart';

class PurchaseController extends GetxController {
  final PurchaseRepository _repo = PurchaseRepository();

  var isLoading = false.obs;
  var vendors = [].obs;
  var products = [].obs;

  // Form State
  var selectedVendor = Rxn<Map<String, dynamic>>();
  var previousBalance = 0.0.obs;
  var installmentChart = <Map<String, dynamic>>[].obs;

  var billDate = DateTime.now().obs;

  // Cart for multiple items
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

  // ITEM MANAGEMENT METHODS
  void addItemToBill(Map<String, dynamic> product, int qty, double price) {
    addedItems.add({
      'productId': product['id'],
      'productName': product['name'],
      'brand': product['brand'],
      'model': product['modelNumber'],
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

  // BILL NUMBER GENERATOR
  String _generateBillNumber(String paymentMode, String? creditType) {
    String prefix = 'B';
    if (paymentMode == 'Cash')
      prefix = 'C';
    else if (paymentMode == 'Both')
      prefix = 'M';
    else if (paymentMode == 'Credit') {
      if (creditType == 'Daily')
        prefix = 'D';
      else if (creditType == 'Weekly')
        prefix = 'W';
      else if (creditType == 'Monthly')
        prefix = 'MO';
      else
        prefix = 'CR'; // Custom
    }

    int randomNum = Random().nextInt(9000) + 1000;
    return "$prefix-$randomNum";
  }

  // Chart Generation Logic
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

  // REAL SAVE LOGIC
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
    int? customDaysLimit, // ✅ NAYA
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
        customDaysLimit: customDaysLimit, // ✅ NAYA
      );

      List<Map<String, dynamic>> realSchedule = [];

      if (paymentMode == "Credit" || paymentMode == "Both") {
        // Save First Payment explicitly for Custom too
        double scheduleRemaining = remainingForThisBill;
        if (firstPaymentAmount > 0 && firstPaymentDate != null) {
          scheduleRemaining -= firstPaymentAmount;
          realSchedule.add({
            'dueDate': Timestamp.fromDate(firstPaymentDate),
            'amountDue': firstPaymentAmount,
            'note': 'First/Advance Payment',
            'billNumber': generatedBillNumber,
            'isPaid': false, // Add this for consistency
            'paidAmount': 0.0,
          });
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
