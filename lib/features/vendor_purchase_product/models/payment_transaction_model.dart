import 'package:cloud_firestore/cloud_firestore.dart';

class PaymentTransactionModel {
  String? id;
  String vendorId;
  String vendorName;
  String dueDocId; // Jis due/installment ko pay kiya gaya hai
  String billNumber;
  double paidAmount;
  DateTime paymentDate;
  String paymentMode; // Cash, Bank Transfer, etc.
  String note;
  DateTime createdAt;

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
  });

  Map<String, dynamic> toMap() {
    return {
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
    );
  }
}
