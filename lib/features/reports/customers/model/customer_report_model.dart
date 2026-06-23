// lib/features/reports/customers/model/customer_report_model.dart
//
// CustomerReportModel = CustomerModel ke saare fields + computed stats:
// totalReferrals (direct downline count), totalOrders, totalOrderValue,
// referredByName (resolve referralCode -> parent ka naam).

class CustomerReportModel {
  final String uid;
  final String name;
  final String email;
  final String phone;
  final String cnicNumber;
  final String country;
  final String state;
  final String city;
  final String address;
  final String faceImage;
  final String myReferralCode;
  final String
  referralCode; // raw value (parent code / mlmReferrerUid / 'Top / Direct')
  final String referredByName; // resolved human-readable name
  final double walletBalance;
  final double shoppingWalletBalance;
  final double totalPoints;
  final double totalCashbackEarned;
  final String membershipStatus; // 'paid' | 'unpaid'
  final bool isMLMActive;
  final String rank; // Bronze / Silver / Gold / Diamond
  final DateTime? createdAt;

  // ── Computed (cross-query) ──
  final int totalReferrals;
  final int totalOrders;
  final double totalOrderValue;

  const CustomerReportModel({
    required this.uid,
    required this.name,
    required this.email,
    required this.phone,
    required this.cnicNumber,
    required this.country,
    required this.state,
    required this.city,
    required this.address,
    required this.faceImage,
    required this.myReferralCode,
    required this.referralCode,
    required this.referredByName,
    required this.walletBalance,
    required this.shoppingWalletBalance,
    required this.totalPoints,
    required this.totalCashbackEarned,
    required this.membershipStatus,
    required this.isMLMActive,
    required this.rank,
    required this.createdAt,
    required this.totalReferrals,
    required this.totalOrders,
    required this.totalOrderValue,
  });

  /// Converts to a flat map for the report table / PDF / CSV export.
  /// Keys here MUST match the `key` values in `customerReportColumns`.
  Map<String, dynamic> toRowMap() {
    return {
      'name': name,
      'email': email,
      'phone': phone,
      'cnicNumber': cnicNumber,
      'country': country,
      'state': state,
      'city': city,
      'address': address,
      'myReferralCode': myReferralCode,
      'referralCode': referralCode,
      'referredByName': referredByName,
      'hasPhoto': faceImage.trim().isNotEmpty && faceImage != 'null',
      'walletBalance': walletBalance,
      'shoppingWalletBalance': shoppingWalletBalance,
      'totalPoints': totalPoints,
      'totalCashbackEarned': totalCashbackEarned,
      'membershipStatus': membershipStatus,
      'isMLMActive': isMLMActive,
      'rank': rank,
      'totalReferrals': totalReferrals,
      'totalOrders': totalOrders,
      'totalOrderValue': totalOrderValue,
      'createdAt': createdAt,
    };
  }
}
