import 'package:flutter/foundation.dart';

class StaffModel {
  final String? id;
  final String? uid;
  final DateTime joiningDate;
  final String? imageUrl;
  final String name;
  final String fatherName;
  final String cnic;
  final String mobile1;
  final String? mobile2;
  final String? email;
  final String? password; // Staff login password
  final String designation;
  final String address;
  final double? locationLat;
  final double? locationLng;

  // Employment
  final String employmentType; // 'salary', 'commission', 'both'

  // Salary
  final double? salaryAmount;
  final String salaryFrequency;

  // Commission & Fuel
  final List<String> commissionRegions;
  final double? productComFix;
  final double? productComPerc;
  final double? cashbackComFix;
  final double? cashbackComPerc;
  final double? deliveryKarachiFix;
  final double? deliveryKarachiPerc;
  final double? deliveryPakFix;
  final double? deliveryPakPerc;
  final double? deliveryWWFix;
  final double? deliveryWWPerc;
  final double? petrolRate;
  final double? avgRunning;
  final double? fuelPerKm;

  // Timing
  final int onTimeHour;
  final int onTimeMinute;
  final String onTimePeriod;
  final int offTimeHour;
  final int offTimeMinute;
  final String offTimePeriod;

  // Weekly offs
  final List<String> weeklyOffs;

  // Bonus
  final String bonusType;
  final int bonusYearlyCount;
  final List<BonusPayDate> bonusPayDates;

  // Attendance
  final bool attendanceByLocation;
  final String? attendanceLocation;

  // Calculated
  final double? totalMonthlyPayable;
  final double? bonusMonthlyAmount;

  final DateTime createdAt;

  StaffModel({
    this.id,
    this.uid,
    required this.joiningDate,
    required this.name,
    required this.fatherName,
    required this.cnic,
    required this.mobile1,
    this.mobile2,
    this.email,
    this.imageUrl,
    this.password,
    required this.designation,
    required this.address,
    this.locationLat,
    this.locationLng,
    required this.employmentType,
    this.salaryAmount,
    this.salaryFrequency = 'monthly',
    this.commissionRegions = const [],
    this.productComFix,
    this.productComPerc,
    this.cashbackComFix,
    this.cashbackComPerc,
    this.deliveryKarachiFix,
    this.deliveryKarachiPerc,
    this.deliveryPakFix,
    this.deliveryPakPerc,
    this.deliveryWWFix,
    this.deliveryWWPerc,
    this.petrolRate,
    this.avgRunning,
    this.fuelPerKm,
    required this.onTimeHour,
    required this.onTimeMinute,
    required this.onTimePeriod,
    required this.offTimeHour,
    required this.offTimeMinute,
    required this.offTimePeriod,
    required this.weeklyOffs,
    required this.bonusType,
    required this.bonusYearlyCount,
    required this.bonusPayDates,
    required this.attendanceByLocation,
    this.attendanceLocation,
    this.totalMonthlyPayable,
    this.bonusMonthlyAmount,
    required this.createdAt,
  });

  Map<String, dynamic> toFirestore() {
    return {
      'joiningDate': joiningDate.toIso8601String(),
      'uid': uid,
      'name': name,
      'fatherName': fatherName,
      'imageUrl': imageUrl,
      'cnic': cnic,
      'mobile1': mobile1,
      'mobile2': mobile2,
      'email': email,
      'password': password,
      'designation': designation,
      'address': address,
      'locationLat': locationLat,
      'locationLng': locationLng,
      'employmentType': employmentType,
      'salaryAmount': salaryAmount,
      'salaryFrequency': salaryFrequency,
      'commissionRegions': commissionRegions,
      'productComFix': productComFix,
      'productComPerc': productComPerc,
      'cashbackComFix': cashbackComFix,
      'cashbackComPerc': cashbackComPerc,
      'deliveryKarachiFix': deliveryKarachiFix,
      'deliveryKarachiPerc': deliveryKarachiPerc,
      'deliveryPakFix': deliveryPakFix,
      'deliveryPakPerc': deliveryPakPerc,
      'deliveryWWFix': deliveryWWFix,
      'deliveryWWPerc': deliveryWWPerc,
      'petrolRate': petrolRate,
      'avgRunning': avgRunning,
      'fuelPerKm': fuelPerKm,
      'onTimeHour': onTimeHour,
      'onTimeMinute': onTimeMinute,
      'onTimePeriod': onTimePeriod,
      'offTimeHour': offTimeHour,
      'offTimeMinute': offTimeMinute,
      'offTimePeriod': offTimePeriod,
      'weeklyOffs': weeklyOffs,
      'bonusType': bonusType,
      'bonusYearlyCount': bonusYearlyCount,
      'bonusPayDates': bonusPayDates.map((e) => e.toMap()).toList(),
      'attendanceByLocation': attendanceByLocation,
      'attendanceLocation': attendanceLocation,
      'totalMonthlyPayable': totalMonthlyPayable,
      'bonusMonthlyAmount': bonusMonthlyAmount,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory StaffModel.fromFirestore(Map<String, dynamic> map, String docId) {
    return StaffModel(
      id: docId,
      uid: map['uid'] as String?,
      joiningDate: DateTime.parse(map['joiningDate']),
      name: map['name'] ?? '',
      fatherName: map['fatherName'] ?? '',
      imageUrl: map['imageUrl'],
      cnic: map['cnic'] ?? '',
      mobile1: map['mobile1'] ?? '',
      mobile2: map['mobile2'],
      email: map['email'],
      password: map['password'],
      designation: map['designation'] ?? '',
      address: map['address'] ?? '',
      locationLat: map['locationLat']?.toDouble(),
      locationLng: map['locationLng']?.toDouble(),
      employmentType: map['employmentType'] ?? 'salary',
      salaryAmount: map['salaryAmount']?.toDouble(),
      salaryFrequency: map['salaryFrequency'] ?? 'monthly',
      commissionRegions: List<String>.from(map['commissionRegions'] ?? []),
      productComFix: map['productComFix']?.toDouble(),
      productComPerc: map['productComPerc']?.toDouble(),
      cashbackComFix: map['cashbackComFix']?.toDouble(),
      cashbackComPerc: map['cashbackComPerc']?.toDouble(),
      deliveryKarachiFix: map['deliveryKarachiFix']?.toDouble(),
      deliveryKarachiPerc: map['deliveryKarachiPerc']?.toDouble(),
      deliveryPakFix: map['deliveryPakFix']?.toDouble(),
      deliveryPakPerc: map['deliveryPakPerc']?.toDouble(),
      deliveryWWFix: map['deliveryWWFix']?.toDouble(),
      deliveryWWPerc: map['deliveryWWPerc']?.toDouble(),
      petrolRate: map['petrolRate']?.toDouble(),
      avgRunning: map['avgRunning']?.toDouble(),
      fuelPerKm: map['fuelPerKm']?.toDouble(),
      onTimeHour: map['onTimeHour'] ?? 9,
      onTimeMinute: map['onTimeMinute'] ?? 0,
      onTimePeriod: map['onTimePeriod'] ?? 'AM',
      offTimeHour: map['offTimeHour'] ?? 5,
      offTimeMinute: map['offTimeMinute'] ?? 0,
      offTimePeriod: map['offTimePeriod'] ?? 'PM',
      weeklyOffs: List<String>.from(map['weeklyOffs'] ?? ['Sunday']),
      bonusType: map['bonusType'] ?? 'full',
      bonusYearlyCount: map['bonusYearlyCount'] ?? 1,
      bonusPayDates: (map['bonusPayDates'] as List<dynamic>? ?? [])
          .map((e) => BonusPayDate.fromMap(e))
          .toList(),
      attendanceByLocation: map['attendanceByLocation'] ?? false,
      attendanceLocation: map['attendanceLocation'],
      totalMonthlyPayable: map['totalMonthlyPayable']?.toDouble(),
      bonusMonthlyAmount: map['bonusMonthlyAmount']?.toDouble(),
      createdAt: DateTime.parse(map['createdAt']),
    );
  }
}

class BonusPayDate {
  final int bonusIndex;
  final int day;
  final int month;

  BonusPayDate({
    required this.bonusIndex,
    required this.day,
    required this.month,
  });
  Map<String, dynamic> toMap() => {
    'bonusIndex': bonusIndex,
    'day': day,
    'month': month,
  };
  factory BonusPayDate.fromMap(Map<String, dynamic> map) => BonusPayDate(
    bonusIndex: map['bonusIndex'] ?? 1,
    day: map['day'] ?? 1,
    month: map['month'] ?? 1,
  );
}
