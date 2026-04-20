import 'package:cloud_firestore/cloud_firestore.dart';

class CustomerModel {
  final String uid;
  final String name;
  final String email;
  final String phone;
  final String country;
  final String address;
  final String myReferralCode;
  final String referralCode;
  final String faceImage;
  final String cnicNumber;
  final double walletBalance;
  final double shoppingWalletBalance;
  final double totalPoints;
  final double totalCashbackEarned; // Added
  final String membershipStatus;
  final bool isMLMActive;
  final DateTime? createdAt;

  CustomerModel({
    required this.uid,
    required this.name,
    required this.email,
    required this.phone,
    required this.country,
    required this.address,
    required this.myReferralCode,
    required this.referralCode,
    required this.faceImage,
    required this.cnicNumber,
    required this.walletBalance,
    required this.shoppingWalletBalance,
    required this.totalPoints,
    required this.totalCashbackEarned,
    required this.membershipStatus,
    required this.isMLMActive,
    this.createdAt,
  });

  factory CustomerModel.fromMap(Map<String, dynamic> map, String docId) {
    return CustomerModel(
      uid: map['uid'] ?? docId,
      name: map['name'] ?? map['username'] ?? 'Unknown',
      email: map['email'] ?? 'N/A',
      phone: map['phone'] ?? 'N/A',
      country: map['country'] ?? 'N/A',
      address: map['address'] ?? 'N/A',
      myReferralCode: map['myReferralCode'] ?? '',
      referralCode:
          map['referralCode'] ?? map['mlmReferrerUid'] ?? 'Top / Direct',
      faceImage: map['faceImage'] ?? '',
      cnicNumber: map['cnicNumber'] ?? 'N/A',
      walletBalance: (map['walletBalance'] ?? 0.0).toDouble(),
      shoppingWalletBalance: (map['shoppingWalletBalance'] ?? 0.0).toDouble(),
      totalPoints: (map['totalPoints'] ?? 0.0).toDouble(),
      totalCashbackEarned: (map['totalCashbackEarned'] ?? 0.0).toDouble(),
      membershipStatus: map['membershipStatus'] ?? 'unpaid',
      isMLMActive: map['isMLMActive'] ?? false,
      createdAt: map['createdAt'] != null
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  // Calculate Rank based on points (Using standard limits)
  String get rank {
    if (totalPoints <= 100) return 'Bronze';
    if (totalPoints <= 200) return 'Silver';
    if (totalPoints <= 300) return 'Gold';
    return 'Diamond';
  }
}
