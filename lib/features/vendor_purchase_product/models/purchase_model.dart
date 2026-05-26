import 'package:cloud_firestore/cloud_firestore.dart';

class PurchaseModel {
  String? id;
  String billNumber;
  DateTime date;
  String vendorId;
  String vendorName;

  List<Map<String, dynamic>> items;
  double totalBillAmount;

  // Payment Status
  String paymentMode; // 'Cash', 'Online', 'Credit', 'Both'
  double cashPaid;
  double remainingBalance;

  // Credit Details
  String? creditType;
  List<String>? selectedDays;
  DateTime? firstPaymentDate;
  DateTime? startingDate;
  double? perInstallmentAmount;
  int? customDaysLimit;

  // ✅ NEW FIELDS FOR INITIAL PAYMENT TRACKING & BANK DEDUCTIONS
  String? initialTransactionMode; // 'Cash', 'Bank Transfer', 'Cheque'
  String? initialBankId;
  String? initialBankName;
  String? initialScreenshot;
  String? initialChequeNumber;
  DateTime? initialChequeDate;

  PurchaseModel({
    this.id,
    required this.billNumber,
    required this.date,
    required this.vendorId,
    required this.vendorName,
    required this.items,
    required this.totalBillAmount,
    required this.paymentMode,
    this.cashPaid = 0.0,
    this.remainingBalance = 0.0,
    this.creditType,
    this.selectedDays,
    this.firstPaymentDate,
    this.startingDate,
    this.perInstallmentAmount,
    this.customDaysLimit,
    this.initialTransactionMode,
    this.initialBankId,
    this.initialBankName,
    this.initialScreenshot,
    this.initialChequeNumber,
    this.initialChequeDate,
  });

  Map<String, dynamic> toMap() {
    return {
      'billNumber': billNumber,
      'date': Timestamp.fromDate(date),
      'vendorId': vendorId,
      'vendorName': vendorName,
      'items': items,
      'totalBillAmount': totalBillAmount,
      'paymentMode': paymentMode,
      'cashPaid': cashPaid,
      'remainingBalance': remainingBalance,
      'creditType': creditType,
      'selectedDays': selectedDays,
      'firstPaymentDate': firstPaymentDate != null
          ? Timestamp.fromDate(firstPaymentDate!)
          : null,
      'startingDate': startingDate != null
          ? Timestamp.fromDate(startingDate!)
          : null,
      'perInstallmentAmount': perInstallmentAmount,
      'customDaysLimit': customDaysLimit,
      'initialTransactionMode': initialTransactionMode,
      'initialBankId': initialBankId,
      'initialBankName': initialBankName,
      'initialScreenshot': initialScreenshot,
      'initialChequeNumber': initialChequeNumber,
      'initialChequeDate': initialChequeDate != null
          ? Timestamp.fromDate(initialChequeDate!)
          : null,
    };
  }
}
