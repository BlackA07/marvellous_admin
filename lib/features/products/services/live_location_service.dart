// lib/features/products/services/live_location_service.dart
//
// Admin ki current (live) location + poora address.
// GPS: geolocator | Reverse geocoding: OpenStreetMap Nominatim (free, no API key).

import 'dart:convert';

import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

class LiveLocationResult {
  final double latitude;
  final double longitude;
  final String houseNumber;
  final String building; // building / shop / plaza ka naam
  final String street;
  final String area; // suburb / neighbourhood / town
  final String city;
  final String state;
  final String country;
  final String postalCode;
  final String fullAddress;
  final DateTime capturedAt;

  LiveLocationResult({
    required this.latitude,
    required this.longitude,
    this.houseNumber = '',
    this.building = '',
    this.street = '',
    this.area = '',
    this.city = '',
    this.state = '',
    this.country = '',
    this.postalCode = '',
    this.fullAddress = '',
    DateTime? capturedAt,
  }) : capturedAt = capturedAt ?? DateTime.now();

  bool get hasAddress => fullAddress.trim().isNotEmpty;

  String get shortLine {
    final parts = [
      if (houseNumber.isNotEmpty) houseNumber,
      building,
      area,
      city,
      country,
    ].where((e) => e.trim().isNotEmpty).toList();
    return parts.isEmpty
        ? "${latitude.toStringAsFixed(5)}, ${longitude.toStringAsFixed(5)}"
        : parts.join(', ');
  }

  Map<String, dynamic> toMap() => {
    'latitude': latitude,
    'longitude': longitude,
    'houseNumber': houseNumber,
    'building': building,
    'street': street,
    'area': area,
    'city': city,
    'state': state,
    'country': country,
    'postalCode': postalCode,
    'fullAddress': fullAddress,
    'capturedAt': capturedAt.toIso8601String(),
  };

  factory LiveLocationResult.fromMap(Map<String, dynamic> map) {
    return LiveLocationResult(
      latitude: (map['latitude'] as num?)?.toDouble() ?? 0,
      longitude: (map['longitude'] as num?)?.toDouble() ?? 0,
      houseNumber: map['houseNumber']?.toString() ?? '',
      building: map['building']?.toString() ?? '',
      street: map['street']?.toString() ?? '',
      area: map['area']?.toString() ?? '',
      city: map['city']?.toString() ?? '',
      state: map['state']?.toString() ?? '',
      country: map['country']?.toString() ?? '',
      postalCode: map['postalCode']?.toString() ?? '',
      fullAddress: map['fullAddress']?.toString() ?? '',
      capturedAt:
          DateTime.tryParse(map['capturedAt']?.toString() ?? '') ??
          DateTime.now(),
    );
  }
}

/// Location fetch fail hone par ye exception phenka jata hai — message
/// seedha UI par dikhaya ja sakta hai.
class LiveLocationException implements Exception {
  final String message;
  LiveLocationException(this.message);
  @override
  String toString() => message;
}

class LiveLocationService {
  /// GPS se coordinates leta hai, phir unhen poore address mein badalta hai.
  static Future<LiveLocationResult> fetchCurrentLocation() async {
    final Position position = await _getPosition();

    try {
      final address = await _reverseGeocode(
        position.latitude,
        position.longitude,
      );
      return address;
    } catch (e) {
      // Address na mile to bhi coordinates wapas de do — form khaali na rahe.
      debugPrint("Reverse geocode failed: $e");
      return LiveLocationResult(
        latitude: position.latitude,
        longitude: position.longitude,
      );
    }
  }

  static Future<Position> _getPosition() async {
    // Web par service-enabled check hamesha reliable nahi, is liye sirf
    // non-web par check karte hain.
    if (!kIsWeb) {
      final bool serviceEnabled =
          await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw LiveLocationException(
          "Location service band hai. Please GPS on karein.",
        );
      }
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied) {
      throw LiveLocationException(
        "Location permission deny kar di gayi hai. Allow karein.",
      );
    }
    if (permission == LocationPermission.deniedForever) {
      throw LiveLocationException(
        "Location permission permanently blocked hai. Browser/App settings se allow karein.",
      );
    }

    return Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 25),
      ),
    );
  }

  static Future<LiveLocationResult> _reverseGeocode(
    double lat,
    double lng,
  ) async {
    final uri = Uri.parse(
      'https://nominatim.openstreetmap.org/reverse'
      '?format=jsonv2&lat=$lat&lon=$lng&zoom=18'
      '&addressdetails=1&namedetails=1&extratags=1',
    );

    // Nominatim ko User-Agent chahiye. Browser ise set nahi karne deta
    // (forbidden header), is liye sirf non-web par bhejte hain.
    final headers = kIsWeb
        ? <String, String>{'Accept': 'application/json'}
        : <String, String>{
            'Accept': 'application/json',
            'User-Agent': 'MarvellousAdmin/1.0 (product-location)',
          };

    final res = await http
        .get(uri, headers: headers)
        .timeout(const Duration(seconds: 20));

    if (res.statusCode != 200) {
      throw LiveLocationException("Address fetch failed (${res.statusCode})");
    }

    final Map<String, dynamic> body = json.decode(res.body);
    final Map<String, dynamic> addr =
        (body['address'] as Map?)?.cast<String, dynamic>() ?? {};

    String pick(List<String> keys) {
      for (final k in keys) {
        final v = addr[k]?.toString().trim() ?? '';
        if (v.isNotEmpty) return v;
      }
      return '';
    }

    final String displayName = body['display_name']?.toString() ?? '';

    // Nominatim har point par house_number nahi deta. Aise mein us jagah ka
    // jo bhi sab se specific naam mojood ho (building / shop / plaza / point
    // ka apna naam, ya display_name ka pehla hissa) wohi use kar lete hain.
    String houseNumber = pick([
      'house_number',
      'housenumber',
      'street_number',
    ]);

    String building = pick([
      'building',
      'house_name',
      'shop',
      'amenity',
      'office',
      'mall',
      'retail',
      'commercial',
      'industrial',
      'residential',
      'tourism',
      'leisure',
      'historic',
      'public_building',
      'apartments',
    ]);

    if (building.isEmpty) {
      final nameDetails =
          (body['namedetails'] as Map?)?.cast<String, dynamic>() ?? {};
      building =
          (nameDetails['name'] ?? body['name'] ?? '').toString().trim();
    }

    final String road = pick(['road', 'pedestrian', 'footway', 'residential']);

    // Aakhri fallback: display_name ka pehla tukra (sab se specific).
    if (houseNumber.isEmpty && building.isEmpty && displayName.isNotEmpty) {
      final first = displayName.split(',').first.trim();
      if (first.isNotEmpty && first != road) {
        // Agar pehla tukra sirf number hai to usay house number maan lo.
        if (RegExp(r'^[0-9][0-9A-Za-z\-/ ]*$').hasMatch(first)) {
          houseNumber = first;
        } else {
          building = first;
        }
      }
    }

    return LiveLocationResult(
      latitude: lat,
      longitude: lng,
      houseNumber: houseNumber,
      building: building,
      street: road,
      area: pick([
        'neighbourhood',
        'suburb',
        'quarter',
        'city_block',
        'village',
        'hamlet',
      ]),
      city: pick(['city', 'town', 'municipality', 'county']),
      state: pick(['state', 'region', 'state_district']),
      country: pick(['country']),
      postalCode: pick(['postcode']),
      fullAddress: displayName,
    );
  }
}
