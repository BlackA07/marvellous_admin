// lib/features/products/services/currency_service.dart
//
// Live exchange rates (base: PKR) — open.er-api.com, koi API key nahi.
// Rates din mein ek baar update hote hain, is liye 6 ghante cache karte hain.
// Internet na ho to last cached rates (SharedPreferences) use hote hain.

import 'dart:convert';

import 'package:flutter/foundation.dart' show debugPrint;
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class CurrencyService {
  static const String baseCurrency = 'PKR';
  static const String _prefsKey = 'fx_rates_pkr_v1';
  static const String _prefsTimeKey = 'fx_rates_pkr_time_v1';

  /// 1 PKR = rates[code] units of that currency.
  static Map<String, double> _rates = {};
  static DateTime? _fetchedAt;
  static Future<void>? _inFlight;

  static bool get hasRates => _rates.isNotEmpty;
  static DateTime? get lastUpdated => _fetchedAt;

  /// Sab se zyada use hone wali currencies — dropdown mein sab se upar.
  static const List<String> popular = [
    'PKR',
    'USD',
    'GBP',
    'EUR',
    'INR',
    'AED',
    'SAR',
    'JPY',
    'CNY',
    'CAD',
    'AUD',
    'TRY',
  ];

  /// Country ka naam → uski currency. Jo yahan na ho uske liye USD fallback.
  static const Map<String, String> _countryCurrency = {
    'pakistan': 'PKR',
    'india': 'INR',
    'bangladesh': 'BDT',
    'sri lanka': 'LKR',
    'nepal': 'NPR',
    'afghanistan': 'AFN',
    'china': 'CNY',
    'japan': 'JPY',
    'south korea': 'KRW',
    'malaysia': 'MYR',
    'singapore': 'SGD',
    'indonesia': 'IDR',
    'thailand': 'THB',
    'philippines': 'PHP',
    'vietnam': 'VND',
    'united arab emirates': 'AED',
    'uae': 'AED',
    'saudi arabia': 'SAR',
    'qatar': 'QAR',
    'kuwait': 'KWD',
    'bahrain': 'BHD',
    'oman': 'OMR',
    'turkey': 'TRY',
    'iran': 'IRR',
    'iraq': 'IQD',
    'egypt': 'EGP',
    'south africa': 'ZAR',
    'nigeria': 'NGN',
    'kenya': 'KES',
    'united states': 'USD',
    'usa': 'USD',
    'united states of america': 'USD',
    'canada': 'CAD',
    'mexico': 'MXN',
    'brazil': 'BRL',
    'argentina': 'ARS',
    'united kingdom': 'GBP',
    'uk': 'GBP',
    'england': 'GBP',
    'germany': 'EUR',
    'france': 'EUR',
    'italy': 'EUR',
    'spain': 'EUR',
    'netherlands': 'EUR',
    'belgium': 'EUR',
    'ireland': 'EUR',
    'portugal': 'EUR',
    'greece': 'EUR',
    'switzerland': 'CHF',
    'sweden': 'SEK',
    'norway': 'NOK',
    'denmark': 'DKK',
    'poland': 'PLN',
    'russia': 'RUB',
    'australia': 'AUD',
    'new zealand': 'NZD',
  };

  /// Currency code → [country name, flag emoji].
  /// Jo yahan na ho uske liye khaali country + neutral flag dikhta hai.
  static const Map<String, List<String>> currencyMeta = {
    'PKR': ['Pakistan', '🇵🇰'],
    'INR': ['India', '🇮🇳'],
    'BDT': ['Bangladesh', '🇧🇩'],
    'LKR': ['Sri Lanka', '🇱🇰'],
    'NPR': ['Nepal', '🇳🇵'],
    'AFN': ['Afghanistan', '🇦🇫'],
    'CNY': ['China', '🇨🇳'],
    'JPY': ['Japan', '🇯🇵'],
    'KRW': ['South Korea', '🇰🇷'],
    'MYR': ['Malaysia', '🇲🇾'],
    'SGD': ['Singapore', '🇸🇬'],
    'IDR': ['Indonesia', '🇮🇩'],
    'THB': ['Thailand', '🇹🇭'],
    'PHP': ['Philippines', '🇵🇭'],
    'VND': ['Vietnam', '🇻🇳'],
    'HKD': ['Hong Kong', '🇭🇰'],
    'TWD': ['Taiwan', '🇹🇼'],
    'AED': ['United Arab Emirates', '🇦🇪'],
    'SAR': ['Saudi Arabia', '🇸🇦'],
    'QAR': ['Qatar', '🇶🇦'],
    'KWD': ['Kuwait', '🇰🇼'],
    'BHD': ['Bahrain', '🇧🇭'],
    'OMR': ['Oman', '🇴🇲'],
    'JOD': ['Jordan', '🇯🇴'],
    'ILS': ['Israel', '🇮🇱'],
    'TRY': ['Turkey', '🇹🇷'],
    'IRR': ['Iran', '🇮🇷'],
    'IQD': ['Iraq', '🇮🇶'],
    'EGP': ['Egypt', '🇪🇬'],
    'MAD': ['Morocco', '🇲🇦'],
    'ZAR': ['South Africa', '🇿🇦'],
    'NGN': ['Nigeria', '🇳🇬'],
    'KES': ['Kenya', '🇰🇪'],
    'GHS': ['Ghana', '🇬🇭'],
    'TZS': ['Tanzania', '🇹🇿'],
    'ETB': ['Ethiopia', '🇪🇹'],
    'USD': ['United States', '🇺🇸'],
    'CAD': ['Canada', '🇨🇦'],
    'MXN': ['Mexico', '🇲🇽'],
    'BRL': ['Brazil', '🇧🇷'],
    'ARS': ['Argentina', '🇦🇷'],
    'CLP': ['Chile', '🇨🇱'],
    'COP': ['Colombia', '🇨🇴'],
    'PEN': ['Peru', '🇵🇪'],
    'GBP': ['United Kingdom', '🇬🇧'],
    'EUR': ['Euro Zone', '🇪🇺'],
    'CHF': ['Switzerland', '🇨🇭'],
    'SEK': ['Sweden', '🇸🇪'],
    'NOK': ['Norway', '🇳🇴'],
    'DKK': ['Denmark', '🇩🇰'],
    'PLN': ['Poland', '🇵🇱'],
    'CZK': ['Czech Republic', '🇨🇿'],
    'HUF': ['Hungary', '🇭🇺'],
    'RON': ['Romania', '🇷🇴'],
    'BGN': ['Bulgaria', '🇧🇬'],
    'UAH': ['Ukraine', '🇺🇦'],
    'RUB': ['Russia', '🇷🇺'],
    'KZT': ['Kazakhstan', '🇰🇿'],
    'UZS': ['Uzbekistan', '🇺🇿'],
    'AZN': ['Azerbaijan', '🇦🇿'],
    'AUD': ['Australia', '🇦🇺'],
    'NZD': ['New Zealand', '🇳🇿'],
    'FJD': ['Fiji', '🇫🇯'],
    'MUR': ['Mauritius', '🇲🇺'],
    'MVR': ['Maldives', '🇲🇻'],
    'BND': ['Brunei', '🇧🇳'],
    'MMK': ['Myanmar', '🇲🇲'],
    'KHR': ['Cambodia', '🇰🇭'],
    'LAK': ['Laos', '🇱🇦'],
    'MNT': ['Mongolia', '🇲🇳'],
    'ISK': ['Iceland', '🇮🇸'],
    'RSD': ['Serbia', '🇷🇸'],
    'HRK': ['Croatia', '🇭🇷'],
  };

  static String countryOfCurrency(String code) =>
      currencyMeta[code.toUpperCase()]?[0] ?? '';

  static String flagOfCurrency(String code) =>
      currencyMeta[code.toUpperCase()]?[1] ?? '🏳️';

  /// Country ke naam se currency code (na mile to USD).
  static String currencyForCountry(String countryName) {
    final key = countryName.trim().toLowerCase();
    return _countryCurrency[key] ?? 'USD';
  }

  /// Rates load karta hai (cache → network). Ek waqt mein ek hi request.
  static Future<void> ensureRates({bool force = false}) {
    if (!force && _isFresh) return Future.value();
    return _inFlight ??= _load(force: force).whenComplete(() {
      _inFlight = null;
    });
  }

  static bool get _isFresh {
    if (_rates.isEmpty || _fetchedAt == null) return false;
    return DateTime.now().difference(_fetchedAt!) < const Duration(hours: 6);
  }

  static Future<void> _load({bool force = false}) async {
    if (!force && _rates.isEmpty) {
      await _loadFromPrefs(); // pehle cache — UI turant kuch dikha sake
    }

    try {
      final res = await http
          .get(Uri.parse('https://open.er-api.com/v6/latest/$baseCurrency'))
          .timeout(const Duration(seconds: 15));

      if (res.statusCode != 200) return;

      final Map<String, dynamic> body = json.decode(res.body);
      if (body['result'] != 'success' || body['rates'] is! Map) return;

      final Map<String, double> parsed = {};
      (body['rates'] as Map).forEach((k, v) {
        final d = (v as num?)?.toDouble();
        if (d != null && d > 0) parsed[k.toString().toUpperCase()] = d;
      });

      if (parsed.isEmpty) return;

      _rates = parsed;
      _fetchedAt = DateTime.now();
      await _saveToPrefs();
    } catch (e) {
      debugPrint("Currency rates fetch failed: $e");
      // Cache pe hi chalte rahenge.
    }
  }

  static Future<void> _loadFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_prefsKey);
      if (raw == null) return;
      final Map<String, dynamic> map = json.decode(raw);
      _rates = map.map((k, v) => MapEntry(k, (v as num).toDouble()));
      _fetchedAt = DateTime.tryParse(prefs.getString(_prefsTimeKey) ?? '');
    } catch (_) {}
  }

  static Future<void> _saveToPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefsKey, json.encode(_rates));
      await prefs.setString(_prefsTimeKey, _fetchedAt!.toIso8601String());
    } catch (_) {}
  }

  /// PKR amount ko kisi bhi currency mein convert karta hai.
  /// Rate available na ho to null.
  static double? convertFromBase(double amount, String toCurrency) {
    final code = toCurrency.toUpperCase();
    if (code == baseCurrency) return amount;
    final rate = _rates[code];
    if (rate == null) return null;
    return amount * rate;
  }

  /// Display ke liye formatted string, e.g. "USD 12.45".
  static String? formatted(double amount, String toCurrency) {
    final v = convertFromBase(amount, toCurrency);
    if (v == null) return null;
    final code = toCurrency.toUpperCase();
    // Choti values par zyada decimals taake 0.00 na dikhe.
    final digits = v.abs() >= 100
        ? 0
        : v.abs() >= 1
        ? 2
        : 4;
    return "$code ${v.toStringAsFixed(digits)}";
  }

  /// Dropdown ke liye currency list — popular pehle, phir baqi sab.
  static List<String> get availableCurrencies {
    final all = _rates.keys.toList()..sort();
    final list = <String>[];
    for (final c in popular) {
      if (c == baseCurrency || all.contains(c)) list.add(c);
    }
    for (final c in all) {
      if (!list.contains(c)) list.add(c);
    }
    return list;
  }
}
