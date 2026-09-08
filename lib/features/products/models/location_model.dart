// lib/features/products/models/location_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';

/// Ek hi model teeno levels (Country / State / City) ke liye use hota hai,
/// kyunke teeno ka shape same hai — sirf Firestore path alag hai.
class LocationModel {
  String id;
  String name;
  DateTime dateAdded;

  LocationModel({required this.id, required this.name, DateTime? dateAdded})
    : dateAdded = dateAdded ?? DateTime.now();

  factory LocationModel.fromMap(Map<String, dynamic> map, String id) {
    return LocationModel(
      id: id,
      name: (map['name'] ?? '').toString(),
      dateAdded: (map['dateAdded'] is Timestamp)
          ? (map['dateAdded'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'nameLower': name.toLowerCase(),
      'dateAdded': FieldValue.serverTimestamp(),
    };
  }

  /// Document ID banane ke liye — isi wajah se same naam dobara add karne par
  /// duplicate entry nahi banti (overwrite ho jati hai).
  static String slug(String name) {
    final s = name
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'^_+|_+$'), '');
    return s.isEmpty ? DateTime.now().millisecondsSinceEpoch.toString() : s;
  }
}

/// Global search ka ek result — kis level ka hai aur uska poora path.
class LocationSearchResult {
  final String level; // "Country" | "State" | "City"
  final String name;
  final LocationModel country;
  final LocationModel? state;

  LocationSearchResult({
    required this.level,
    required this.name,
    required this.country,
    this.state,
  });

  /// "Pakistan › Sindh" — city ke liye; state ke liye sirf "Pakistan";
  /// country ke liye khaali.
  String get path {
    if (level == 'Country') return '';
    if (level == 'State') return country.name;
    return '${country.name} › ${state?.name ?? ''}';
  }
}
