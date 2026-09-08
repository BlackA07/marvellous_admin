import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/common/widgets/user_avatar.dart';

class CustomerModel {
  final String uid;
  final String name;
  final String email;
  final String phone;
  final String country;
  final String state;
  final String city;
  final String address;
  final String myReferralCode;
  final String referralCode;
  final String faceImage;
  final String cnicNumber;
  final double walletBalance;
  final double shoppingWalletBalance;
  final double totalPoints;
  final double totalCashbackEarned;
  final String membershipStatus;
  final bool isMLMActive;
  final DateTime? createdAt;
  final String appVersion;
  final String osVersion; // ✅ NEW — e.g. "Android 13" / "iOS 17.2"

  // Device Info — common
  final bool isGuest;
  final String devicePlatform; // 'android' | 'ios' | 'web' | ''
  final String deviceModel;

  final DateTime? lastSeenAt;

  // ✅ NEW: Baaki saari device fields jo DeviceInfoService save karta hai
  final String ipAddress;
  final String deviceBrand; // Android: e.g. "samsung"
  final int? sdkInt; // Android: e.g. 33
  final bool? isPhysicalDevice; // Dono: real device ya emulator/simulator
  final String deviceName; // iOS: e.g. "Arslan's iPhone"
  final String appBuildNumber; // e.g. "5"

  CustomerModel({
    required this.uid,
    required this.name,
    required this.email,
    required this.phone,
    required this.country,
    required this.state,
    required this.city,
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
    this.isGuest = false,
    this.devicePlatform = '',
    this.deviceModel = '',
    this.appVersion = '',

    this.osVersion = '',
    this.lastSeenAt,
    // ✅ NEW — sab optional/safe defaults
    this.ipAddress = '',
    this.deviceBrand = '',
    this.sdkInt,
    this.isPhysicalDevice,
    this.deviceName = '',
    this.appBuildNumber = '',
  });

  bool get hasDeviceInfo => devicePlatform.trim().isNotEmpty;
  bool get isAndroid => devicePlatform.toLowerCase() == 'android';
  bool get isIOS => devicePlatform.toLowerCase() == 'ios';
  bool get isWeb => devicePlatform.toLowerCase() == 'web';

  // ✅ NEW: Har platform ke liye behtareen "display name" nikalta hai
  String get deviceDisplayName {
    if (isIOS) {
      if (deviceName.isNotEmpty) return deviceName;
      if (deviceModel.isNotEmpty) return deviceModel;
      return 'iOS Device';
    }
    if (isAndroid) {
      final parts = [
        if (deviceBrand.isNotEmpty) deviceBrand,
        if (deviceModel.isNotEmpty) deviceModel,
      ];
      return parts.isEmpty ? 'Android Device' : parts.join(' ');
    }
    if (isWeb) return 'Web Browser';
    return deviceModel.isNotEmpty ? deviceModel : 'Unknown Device';
  }

  CustomerModel copyWith({
    String? uid,
    String? name,
    String? email,
    String? phone,
    String? country,
    String? state,
    String? city,
    String? address,
    String? myReferralCode,
    String? referralCode,
    String? faceImage,
    String? cnicNumber,
    double? walletBalance,
    double? shoppingWalletBalance,
    double? totalPoints,
    double? totalCashbackEarned,
    String? membershipStatus,
    bool? isMLMActive,
    DateTime? createdAt,
    bool? isGuest,
    String? devicePlatform,
    String? deviceModel,
    String? appVersion,
    DateTime? lastSeenAt,
    String? ipAddress,
    String? deviceBrand,
    int? sdkInt,
    bool? isPhysicalDevice,
    String? deviceName,
    String? appBuildNumber,

    String? osVersion,
  }) {
    return CustomerModel(
      uid: uid ?? this.uid,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      country: country ?? this.country,
      state: state ?? this.state,
      city: city ?? this.city,
      address: address ?? this.address,
      myReferralCode: myReferralCode ?? this.myReferralCode,
      referralCode: referralCode ?? this.referralCode,
      faceImage: faceImage ?? this.faceImage,
      cnicNumber: cnicNumber ?? this.cnicNumber,
      walletBalance: walletBalance ?? this.walletBalance,
      shoppingWalletBalance:
          shoppingWalletBalance ?? this.shoppingWalletBalance,
      totalPoints: totalPoints ?? this.totalPoints,
      totalCashbackEarned: totalCashbackEarned ?? this.totalCashbackEarned,
      membershipStatus: membershipStatus ?? this.membershipStatus,
      isMLMActive: isMLMActive ?? this.isMLMActive,
      createdAt: createdAt ?? this.createdAt,
      isGuest: isGuest ?? this.isGuest,
      devicePlatform: devicePlatform ?? this.devicePlatform,
      deviceModel: deviceModel ?? this.deviceModel,
      appVersion: appVersion ?? this.appVersion,
      osVersion: osVersion ?? this.osVersion,
      lastSeenAt: lastSeenAt ?? this.lastSeenAt,
      ipAddress: ipAddress ?? this.ipAddress,
      deviceBrand: deviceBrand ?? this.deviceBrand,
      sdkInt: sdkInt ?? this.sdkInt,
      isPhysicalDevice: isPhysicalDevice ?? this.isPhysicalDevice,
      deviceName: deviceName ?? this.deviceName,
      appBuildNumber: appBuildNumber ?? this.appBuildNumber,
    );
  }

  factory CustomerModel.fromMap(Map<String, dynamic> map, String docId) {
    final Map<String, dynamic>? deviceInfo =
        map['lastDeviceInfo'] as Map<String, dynamic>?;

    return CustomerModel(
      uid: map['uid'] ?? docId,
      name: map['name'] ?? map['username'] ?? 'Unknown',
      email: map['email'] ?? 'N/A',
      phone: map['phone'] ?? 'N/A',
      country: map['country'] ?? 'N/A',
      state: map['state'] ?? 'N/A',
      city: map['city'] ?? 'N/A',
      address: map['address'] ?? 'N/A',
      myReferralCode: map['myReferralCode'] ?? '',
      referralCode:
          map['referralCode'] ?? map['mlmReferrerUid'] ?? 'Top / Direct',
      // Cleaned here so the literal strings 'null' / 'undefined' that some old
      // records hold never masquerade as a real photo.
      faceImage: UserImage.fromMap(map),
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
      isGuest: map['isGuest'] ?? false,
      devicePlatform: deviceInfo?['platform']?.toString() ?? '',
      deviceModel: deviceInfo?['deviceModel']?.toString() ?? '',
      appVersion: deviceInfo?['appVersion']?.toString() ?? '',
      osVersion: deviceInfo?['osVersion']?.toString() ?? '',
      lastSeenAt: deviceInfo?['lastSeenAt'] != null
          ? (deviceInfo!['lastSeenAt'] as Timestamp).toDate()
          : null,
      // ✅ NEW — sab safe null-checks ke sath, koi bhi missing ho to error nahi
      ipAddress: deviceInfo?['ipAddress']?.toString() ?? '',
      deviceBrand: deviceInfo?['deviceBrand']?.toString() ?? '',
      sdkInt: deviceInfo?['sdkInt'] != null
          ? int.tryParse(deviceInfo!['sdkInt'].toString())
          : null,
      isPhysicalDevice: deviceInfo?['isPhysicalDevice'] is bool
          ? deviceInfo!['isPhysicalDevice'] as bool
          : null,
      deviceName: deviceInfo?['deviceName']?.toString() ?? '',
      appBuildNumber: deviceInfo?['appBuildNumber']?.toString() ?? '',
    );
  }

  String get rank {
    if (totalPoints <= 100) return 'Bronze';
    if (totalPoints <= 200) return 'Silver';
    if (totalPoints <= 300) return 'Gold';
    return 'Diamond';
  }
}
