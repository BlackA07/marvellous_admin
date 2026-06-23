// lib/features/reports/finance/repository/finance_report_repository.dart
//
// Fetches 'admin_ledger_transactions' collection for the given date range
// (one-time .get(), not a stream — report needs a stable snapshot for
// filtering/sorting/export).
//
// NOTE: Firestore limitation — only ONE field can have inequality filters,
// so date range is server-side; type/category/paymentMethod/linkedEntity/search
// filters are applied client-side in the controller.

import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../finance/models/ledger_transaction_model.dart';
import '../model/finance_report_model.dart';

class FinanceReportRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference get _ledger =>
      _db.collection('admin_ledger_transactions');

  Future<List<FinanceReportModel>> getLedgerData({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final snap = await _ledger
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
        .where(
          'date',
          isLessThanOrEqualTo: Timestamp.fromDate(
            endDate.add(const Duration(hours: 23, minutes: 59, seconds: 59)),
          ),
        )
        .orderBy('date', descending: true)
        .get();

    return snap.docs.map((doc) {
      final txn = LedgerTransactionModel.fromMap(
        doc.data() as Map<String, dynamic>,
        doc.id,
      );

      return FinanceReportModel(
        id: txn.id ?? doc.id,
        type: txn.type,
        category: txn.category,
        amount: txn.amount,
        paymentMethod: txn.paymentMethod,
        bankName: txn.bankName,
        chequeNumber: txn.chequeNumber,
        chequeDate: txn.chequeDate,
        description: txn.description,
        linkedUserName: txn.linkedUserName,
        linkedUserPhone: txn.linkedUserPhone,
        linkedUserEmail: txn.linkedUserEmail,
        linkedVendorName: txn.linkedVendorName,
        linkedStaffName: txn.linkedStaffName,
        linkedOrderId: txn.linkedOrderId,
        subTotal: txn.subTotal,
        shippingFee: txn.shippingFee,
        codCharges: txn.codCharges,
        grossProfit: txn.grossProfit,
        createdBy: txn.createdBy,
        date: txn.date,
        createdAt: txn.createdAt,
      );
    }).toList();
  }
}
