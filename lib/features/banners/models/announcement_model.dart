import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// A styled text announcement saved in Firestore so any client project can
/// read it and render it exactly as the admin designed it here.
/// Colors are stored as '#RRGGBB' strings, alignment as 'left' | 'center' | 'right'.
class AnnouncementModel {
  final String id;
  final String message;

  final String textColorHex;
  final String backgroundColorHex;
  final String fontFamily; // 'Default' = app default font
  final double fontSize;
  final bool isBold;
  final bool isItalic;
  final String textAlign;

  final bool isActive;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const AnnouncementModel({
    required this.id,
    required this.message,
    this.textColorHex = '#FFFFFF',
    this.backgroundColorHex = '#1E1B3A',
    this.fontFamily = 'Default',
    this.fontSize = 16,
    this.isBold = false,
    this.isItalic = false,
    this.textAlign = 'center',
    this.isActive = true,
    required this.createdAt,
    this.updatedAt,
  });

  AnnouncementModel copyWith({
    String? message,
    String? textColorHex,
    String? backgroundColorHex,
    String? fontFamily,
    double? fontSize,
    bool? isBold,
    bool? isItalic,
    String? textAlign,
    bool? isActive,
    DateTime? updatedAt,
  }) {
    return AnnouncementModel(
      id: id,
      message: message ?? this.message,
      textColorHex: textColorHex ?? this.textColorHex,
      backgroundColorHex: backgroundColorHex ?? this.backgroundColorHex,
      fontFamily: fontFamily ?? this.fontFamily,
      fontSize: fontSize ?? this.fontSize,
      isBold: isBold ?? this.isBold,
      isItalic: isItalic ?? this.isItalic,
      textAlign: textAlign ?? this.textAlign,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'message': message,
      'textColorHex': textColorHex,
      'backgroundColorHex': backgroundColorHex,
      'fontFamily': fontFamily,
      'fontSize': fontSize,
      'isBold': isBold,
      'isItalic': isItalic,
      'textAlign': textAlign,
      'isActive': isActive,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
    };
  }

  factory AnnouncementModel.fromMap(String id, Map<String, dynamic> map) {
    return AnnouncementModel(
      id: id,
      message: map['message']?.toString() ?? '',
      textColorHex: map['textColorHex']?.toString() ?? '#FFFFFF',
      backgroundColorHex: map['backgroundColorHex']?.toString() ?? '#1E1B3A',
      fontFamily: map['fontFamily']?.toString() ?? 'Default',
      fontSize: (map['fontSize'] ?? 16).toDouble(),
      isBold: map['isBold'] ?? false,
      isItalic: map['isItalic'] ?? false,
      textAlign: map['textAlign']?.toString() ?? 'center',
      isActive: map['isActive'] ?? true,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  // ---------------- render helpers ----------------

  static Color colorFromHex(String hex, {Color fallback = Colors.white}) {
    var value = hex.replaceAll('#', '').trim();
    if (value.length == 6) value = 'FF$value';
    final parsed = int.tryParse(value, radix: 16);
    return parsed == null ? fallback : Color(parsed);
  }

  static String colorToHex(Color color) =>
      '#${color.toARGB32().toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}';

  Color get textColor => colorFromHex(textColorHex);
  Color get backgroundColor =>
      colorFromHex(backgroundColorHex, fallback: Colors.black);

  TextAlign get align {
    switch (textAlign) {
      case 'left':
        return TextAlign.left;
      case 'right':
        return TextAlign.right;
      default:
        return TextAlign.center;
    }
  }

  TextStyle toTextStyle() {
    final base = TextStyle(
      color: textColor,
      fontSize: fontSize,
      fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
      fontStyle: isItalic ? FontStyle.italic : FontStyle.normal,
      height: 1.35,
    );
    if (fontFamily == 'Default') return base;
    try {
      return GoogleFonts.getFont(fontFamily, textStyle: base);
    } catch (_) {
      return base;
    }
  }
}
