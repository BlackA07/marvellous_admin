// lib/features/reports/vendors/repository/vendor_report_repository.dart
//
// Fetches 'vendors' collection + cross-queries:
//  - 'products'              -> count of products per vendor
//  - 'vendor_purchases'      -> total billed amount, remaining due, bill count
//  - 'vendor_payment_history'-> total paid amount
//
// NOTE: Full collection scans — acceptable for admin reports. Agar data
// bohot bara ho jaye to per-vendor subcollection queries consider karna.

import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../vendors/models/vendor_model.dart';
import '../model/vendor_report_model.dart';

class VendorReportRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<List<VendorReportModel>> getVendorReportData() async {
    // ── 1. Fetch all vendors ──
    final vendorsSnap = await _db.collection('vendors').get();
    final vendors = vendorsSnap.docs
        .map(
          (doc) =>
              VendorModel.fromMap(doc.data() as Map<String, dynamic>, doc.id),
        )
        .toList();

    // ── 2. Products count per vendor ──
    final Map<String, int> productCountMap = {};
    try {
      final productsSnap = await _db.collection('products').get();
      for (final doc in productsSnap.docs) {
        final data = doc.data();
        final vid = data['vendorId']?.toString();
        if (vid == null || vid.isEmpty) continue;
        productCountMap[vid] = (productCountMap[vid] ?? 0) + 1;
      }
    } catch (_) {}

    // ── 3. Vendor purchases (bills) -> totalBilled, remainingDue, billCount ──
    final Map<String, double> billedMap = {};
    final Map<String, double> remainingMap = {};
    final Map<String, int> billCountMap = {};
    try {
      final purchasesSnap = await _db.collection('vendor_purchases').get();
      for (final doc in purchasesSnap.docs) {
        final data = doc.data();
        final vid = data['vendorId']?.toString();
        if (vid == null || vid.isEmpty) continue;

        final total = _parseDouble(
          data['totalBillAmount'] ?? data['totalPrice'],
        );
        final remaining = _parseDouble(data['remainingBalance']);

        billedMap[vid] = (billedMap[vid] ?? 0) + total;
        remainingMap[vid] = (remainingMap[vid] ?? 0) + remaining;
        billCountMap[vid] = (billCountMap[vid] ?? 0) + 1;
      }
    } catch (_) {}

    // ── 4. Vendor payment history -> totalPaid ──
    final Map<String, double> paidMap = {};
    try {
      final paymentsSnap = await _db.collection('vendor_payment_history').get();
      for (final doc in paymentsSnap.docs) {
        final data = doc.data();
        final vid = data['vendorId']?.toString();
        if (vid == null || vid.isEmpty) continue;

        final paid = _parseDouble(data['paidAmount']);
        paidMap[vid] = (paidMap[vid] ?? 0) + paid;
      }
    } catch (_) {}

    // ── 5. Combine into VendorReportModel list ──
    return vendors.map((v) {
      final uid = v.uid;
      return VendorReportModel(
        id: v.id ?? uid,
        uid: uid,
        storeName: v.storeName,
        storePhone: v.storePhone,
        ownerName: v.ownerName,
        ownerMobile: v.ownerMobile,
        contactPersonName: v.contactPersonName,
        contactPersonPhone: v.contactPersonPhone,
        email: v.email,
        address: v.address,
        categories: v.categories,
        subCategories: v.subCategories,
        beginningBalance: v.beginningBalance,
        status: v.status,
        approvedAt: v.approvedAt,
        rejectedAt: v.rejectedAt,
        rejectionReason: v.rejectionReason,
        totalBilled: billedMap[uid] ?? 0.0,
        totalPaid: paidMap[uid] ?? 0.0,
        remainingDue: remainingMap[uid] ?? 0.0,
        totalProducts: productCountMap[uid] ?? 0,
        totalBills: billCountMap[uid] ?? 0,
      );
    }).toList();
  }

  // ── Helper: safely parse numeric values from Firestore ──
  double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is num) return value.toDouble();
    if (value is String) {
      return double.tryParse(value.replaceAll(',', '')) ?? 0.0;
    }
    return 0.0;
  }
}
