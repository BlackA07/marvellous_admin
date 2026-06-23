// lib/features/reports/vendors/model/vendor_report_model.dart
//
// VendorReportModel = VendorModel ke saare relevant fields + computed stats:
// totalBilled, totalPaid, remainingDue (from vendor_purchases / vendor_payment_history),
// totalProducts, totalBills (cross-query from products / vendor_purchases).

class VendorReportModel {
  final String id;
  final String uid;
  final String storeName;
  final String storePhone;
  final String ownerName;
  final String ownerMobile;
  final String contactPersonName;
  final String contactPersonPhone;
  final String email;
  final String address;

  final List<String> categories;
  final List<String> subCategories;

  final double beginningBalance;
  final String status; // approved | pending | hold | rejected

  final DateTime? approvedAt;
  final DateTime? rejectedAt;
  final String rejectionReason;

  // ── Computed (cross-query) ──
  final double totalBilled; // sum of totalBillAmount from vendor_purchases
  final double totalPaid; // sum of paidAmount from vendor_payment_history
  final double remainingDue; // sum of remainingBalance from vendor_purchases
  final int totalProducts; // count of products where vendorId == uid
  final int totalBills; // count of vendor_purchases entries

  const VendorReportModel({
    required this.id,
    required this.uid,
    required this.storeName,
    required this.storePhone,
    required this.ownerName,
    required this.ownerMobile,
    required this.contactPersonName,
    required this.contactPersonPhone,
    required this.email,
    required this.address,
    required this.categories,
    required this.subCategories,
    required this.beginningBalance,
    required this.status,
    required this.approvedAt,
    required this.rejectedAt,
    required this.rejectionReason,
    required this.totalBilled,
    required this.totalPaid,
    required this.remainingDue,
    required this.totalProducts,
    required this.totalBills,
  });

  /// Converts to a flat map for the report table / PDF / CSV export.
  /// Keys here MUST match the `key` values in `vendorReportColumns`.
  Map<String, dynamic> toRowMap() {
    return {
      'storeName': storeName,
      'ownerName': ownerName,
      'email': email,
      'ownerMobile': ownerMobile,
      'storePhone': storePhone,
      'contactPersonName': contactPersonName,
      'contactPersonPhone': contactPersonPhone,
      'address': address,
      'categories': categories.isEmpty ? '—' : categories.join(', '),
      'subCategories': subCategories.isEmpty ? '—' : subCategories.join(', '),
      'vendorStatus': status,
      'beginningBalance': beginningBalance,
      'totalBilled': totalBilled,
      'totalPaid': totalPaid,
      'remainingDue': remainingDue,
      'totalProducts': totalProducts,
      'totalBills': totalBills,
      'approvedAt': approvedAt,
      'rejectionReason': rejectionReason.isEmpty ? '—' : rejectionReason,
    };
  }
}
