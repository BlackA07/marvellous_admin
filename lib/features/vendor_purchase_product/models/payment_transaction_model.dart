import 'package:cloud_firestore/cloud_firestore.dart';

class PaymentTransactionModel {
  String? id;
  String vendorId;
  String vendorName;
  String dueDocId; // Jis due/installment ko pay kiya gaya hai
  String billNumber;
  double paidAmount;
  DateTime paymentDate;
  String paymentMode; // Cash, Bank Transfer, Cheque
  String note;
  DateTime createdAt;

  // ✅ NEW FIELDS FOR BANK & CHEQUE
  String? bankId;
  String? bankName;
  String? screenshot; // Base64
  String? chequeNumber;
  DateTime? chequeDate;

  PaymentTransactionModel({
    this.id,
    required this.vendorId,
    required this.vendorName,
    required this.dueDocId,
    required this.billNumber,
    required this.paidAmount,
    required this.paymentDate,
    required this.paymentMode,
    required this.note,
    required this.createdAt,
    this.bankId,
    this.bankName,
    this.screenshot,
    this.chequeNumber,
    this.chequeDate,
  });

  Map<String, dynamic> toMap() {
    // ✅ FIX 1: Explicitly defined the map as Map<String, dynamic>
    Map<String, dynamic> map = {
      'vendorId': vendorId,
      'vendorName': vendorName,
      'dueDocId': dueDocId,
      'billNumber': billNumber,
      'paidAmount': paidAmount,
      'paymentDate': Timestamp.fromDate(paymentDate),
      'paymentMode': paymentMode,
      'note': note,
      'createdAt': Timestamp.fromDate(createdAt),
    };

    // ✅ FIX 2: Added Null Assertion Operator (!) for public fields
    if (bankId != null) map['bankId'] = bankId!;
    if (bankName != null) map['bankName'] = bankName!;
    if (screenshot != null) map['screenshot'] = screenshot!;
    if (chequeNumber != null) map['chequeNumber'] = chequeNumber!;
    if (chequeDate != null) map['chequeDate'] = Timestamp.fromDate(chequeDate!);

    return map;
  }

  factory PaymentTransactionModel.fromMap(
    Map<String, dynamic> map,
    String docId,
  ) {
    return PaymentTransactionModel(
      id: docId,
      vendorId: map['vendorId'] ?? '',
      vendorName: map['vendorName'] ?? '',
      dueDocId: map['dueDocId'] ?? '',
      billNumber: map['billNumber'] ?? '',
      paidAmount: (map['paidAmount'] ?? 0.0).toDouble(),
      paymentDate: (map['paymentDate'] as Timestamp).toDate(),
      paymentMode: map['paymentMode'] ?? '',
      note: map['note'] ?? '',
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      bankId: map['bankId'],
      bankName: map['bankName'],
      screenshot: map['screenshot'],
      chequeNumber: map['chequeNumber'],
      chequeDate: map['chequeDate'] != null
          ? (map['chequeDate'] as Timestamp).toDate()
          : null,
    );
  }
}
