// lib/features/reports/customers/repository/customer_report_repository.dart
//
// Fetches ALL customers (users collection) + cross-queries orders collection
// to compute total referrals (direct downline), total orders, total order value.
//
// NOTE: Firestore mein full collection scans hain (users + orders).
// Admin reports ke liye acceptable hai — agar future mein data bohot bara ho
// jaye to pagination / cloud function aggregation consider karna.

import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../customers/models/customer_model.dart';
import '../model/customer_report_model.dart';

class CustomerReportRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<List<CustomerReportModel>> getCustomerReportData() async {
    // ── 1. Fetch all users (customers) ──
    final usersSnap = await _db.collection('users').get();

    final customers = usersSnap.docs
        .map((doc) => CustomerModel.fromMap(doc.data(), doc.id))
        .where((c) => c.myReferralCode.isNotEmpty)
        .toList();

    // ── 2. Build referral count map: referralCode(parent's code) -> count ──
    final Map<String, int> referralCountMap = {};
    for (final c in customers) {
      final parentCode = c.referralCode;
      if (parentCode.isEmpty || parentCode == 'Top / Direct') continue;
      referralCountMap[parentCode] = (referralCountMap[parentCode] ?? 0) + 1;
    }

    // ── 3. Build myReferralCode -> name map (to resolve "referred by") ──
    final Map<String, String> codeToNameMap = {};
    for (final c in customers) {
      if (c.myReferralCode.isNotEmpty) {
        codeToNameMap[c.myReferralCode] = c.name;
      }
    }

    // ── 4. Fetch orders collection — count + total value per customer ──
    final Map<String, int> orderCountMap = {};
    final Map<String, double> orderValueMap = {};

    try {
      final ordersSnap = await _db.collection('orders').get();
      for (final doc in ordersSnap.docs) {
        final data = doc.data();
        final String? custId =
            data['userId'] ?? data['customerId'] ?? data['userEmail'];
        if (custId == null || custId.isEmpty) continue;

        orderCountMap[custId] = (orderCountMap[custId] ?? 0) + 1;

        final double amt = _extractOrderAmount(data);
        orderValueMap[custId] = (orderValueMap[custId] ?? 0) + amt;
      }
    } catch (_) {
      // Agar orders collection access fail ho, stats 0 reh jayenge — crash nahi hoga
    }

    // ── 5. Combine everything into CustomerReportModel list ──
    return customers.map((c) {
      final referrals = referralCountMap[c.myReferralCode] ?? 0;

      String referredBy;
      if (c.referralCode.isEmpty || c.referralCode == 'Top / Direct') {
        referredBy = 'Top / Direct';
      } else {
        referredBy = codeToNameMap[c.referralCode] ?? c.referralCode;
      }

      return CustomerReportModel(
        uid: c.uid,
        name: c.name,
        email: c.email,
        phone: c.phone,
        cnicNumber: c.cnicNumber,
        country: c.country,
        state: c.state,
        city: c.city,
        address: c.address,
        faceImage: c.faceImage,
        myReferralCode: c.myReferralCode,
        referralCode: c.referralCode,
        referredByName: referredBy,
        walletBalance: c.walletBalance,
        shoppingWalletBalance: c.shoppingWalletBalance,
        totalPoints: c.totalPoints,
        totalCashbackEarned: c.totalCashbackEarned,
        membershipStatus: c.membershipStatus,
        isMLMActive: c.isMLMActive,
        rank: c.rank,
        createdAt: c.createdAt,
        totalReferrals: referrals,
        totalOrders: orderCountMap[c.uid] ?? 0,
        totalOrderValue: orderValueMap[c.uid] ?? 0.0,
      );
    }).toList();
  }

  // ── Helper: extract order amount from various possible fields ──
  double _extractOrderAmount(Map<String, dynamic> data) {
    dynamic raw =
        data['grandTotal'] ??
        data['totalAmount'] ??
        data['subTotal'] ??
        data['price'] ??
        data['salePrice'] ??
        0;

    if (raw is double) return raw;
    if (raw is int) return raw.toDouble();
    if (raw is String) {
      return double.tryParse(raw.replaceAll(',', '')) ?? 0.0;
    }
    return 0.0;
  }
}
