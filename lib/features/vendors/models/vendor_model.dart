import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';

class VendorModel {
  String? id;

  // Basic info
  final String uid;
  final String storeName;
  final String storePhone;
  final String ownerName;
  final String ownerMobile;
  final String contactPersonName;
  final String contactPersonPhone;
  final String email;
  final String address;

  // Categories
  final List<String> categories;
  final List<String> subCategories;

  // Images
  final String? profileImage; // Base64
  final List<String> storePictures; // Base64 list

  // Finance & Status
  final double beginningBalance;
  final String status;

  // Extra Firestore fields
  final DateTime? approvedAt;
  final DateTime? rejectedAt;
  final String rejectionReason;
  final List<Map<String, dynamic>> pendingNewCategories;
  final List<Map<String, dynamic>> pendingNewSubCategories;

  VendorModel({
    this.id,
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
    this.profileImage,
    required this.storePictures,
    this.beginningBalance = 0.0,
    this.status = 'pending',
    this.approvedAt,
    this.rejectedAt,
    this.rejectionReason = '',
    this.pendingNewCategories = const [],
    this.pendingNewSubCategories = const [],
  });

  // ── Helpers ────────────────────────────────────────────────

  /// Old admin fields ke liye backwards compatibility
  /// (purane vendors jo admin ne banaye the un mein name/phone/speciality hoga)
  String get displayName => ownerName.trim().isNotEmpty ? ownerName.trim() : '';

  String get displayPhone => ownerMobile.trim().isNotEmpty
      ? ownerMobile.trim()
      : storePhone.trim().isNotEmpty
      ? storePhone.trim()
      : '';

  String get displaySpeciality =>
      categories.isNotEmpty ? categories.join(', ') : '';

  String get avatarLetter => storeName.trim().isNotEmpty
      ? storeName.trim()[0].toUpperCase()
      : ownerName.trim().isNotEmpty
      ? ownerName.trim()[0].toUpperCase()
      : 'V';

  // ── fromMap ────────────────────────────────────────────────

  factory VendorModel.fromMap(Map<String, dynamic> map, String docId) {
    DateTime? _parseTs(dynamic val) {
      if (val == null) return null;
      if (val is Timestamp) return val.toDate();
      return null;
    }

    List<String> _strList(dynamic val) {
      if (val == null) return [];
      if (val is List) return val.map((e) => e.toString()).toList();
      return [];
    }

    List<Map<String, dynamic>> _mapList(dynamic val) {
      if (val == null) return [];
      if (val is List) {
        return val
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
      }
      return [];
    }

    return VendorModel(
      id: docId,
      uid: map['uid'] ?? docId,
      storeName: map['storeName'] ?? '',
      storePhone: map['storePhone'] ?? '',
      ownerName: map['ownerName'] ?? map['name'] ?? '', // backwards compat
      ownerMobile: map['ownerMobile'] ?? map['phone'] ?? '',
      contactPersonName: map['contactPersonName'] ?? '',
      contactPersonPhone: map['contactPersonPhone'] ?? '',
      email: map['email'] ?? '',
      address: map['address'] ?? '',
      categories: _strList(map['categories']),
      subCategories: _strList(map['subCategories']),
      profileImage: map['profileImage'],
      storePictures: _strList(map['storePictures']),
      beginningBalance: (map['beginningBalance'] ?? 0.0).toDouble(),
      status: map['status'] ?? '',
      approvedAt: _parseTs(map['approvedAt']),
      rejectedAt: _parseTs(map['rejectedAt']),
      rejectionReason: map['rejectionReason'] ?? '',
      pendingNewCategories: _mapList(map['pendingNewCategories']),
      pendingNewSubCategories: _mapList(map['pendingNewSubCategories']),
    );
  }

  // ── toMap ──────────────────────────────────────────────────

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'storeName': storeName,
      'storePhone': storePhone,
      'ownerName': ownerName,
      'ownerMobile': ownerMobile,
      'contactPersonName': contactPersonName,
      'contactPersonPhone': contactPersonPhone,
      'email': email,
      'address': address,
      'categories': categories,
      'subCategories': subCategories,
      'profileImage': profileImage,
      'storePictures': storePictures,
      'beginningBalance': beginningBalance,
      'status': status,
    };
  }
}
