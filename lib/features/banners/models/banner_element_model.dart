enum BannerElementType { title, subtitle, message, button, image }

BannerElementType elementTypeFromString(String value) {
  return BannerElementType.values.firstWhere(
    (e) => e.name == value,
    orElse: () => BannerElementType.title,
  );
}

/// Represents a single editable item placed on a custom banner canvas
/// (a title, subtitle, message, button, or product image).
/// Position (dx/dy) and size are stored as FRACTIONS (0.0 - 1.0) of the
/// canvas width/height so the layout stays identical on every screen size
/// (phone, tablet, web/PC) — this is what makes it responsive.
class BannerElementModel {
  final String id;
  final BannerElementType type;
  final String content; // text content OR image url (for type == image)

  final double dx; // left position, fraction of canvas width
  final double dy; // top position, fraction of canvas height
  final double widthFraction; // used for image/button sizing
  final double heightFraction;

  final double fontSize;
  final String fontFamily;
  final String colorHex; // text color / button text color
  final bool isBold;
  final double rotation; // degrees

  // button-only styling
  final String? buttonBgColorHex; // null or 'transparent' = no fill
  final String? buttonBorderColorHex;
  final double buttonBorderRadius;
  final double buttonBorderWidth;

  const BannerElementModel({
    required this.id,
    required this.type,
    required this.content,
    this.dx = 0.1,
    this.dy = 0.1,
    this.widthFraction = 0.3,
    this.heightFraction = 0.15,
    this.fontSize = 18,
    this.fontFamily = 'Default',
    this.colorHex = '#FFFFFF',
    this.isBold = false,
    this.rotation = 0,
    this.buttonBgColorHex,
    this.buttonBorderColorHex,
    this.buttonBorderRadius = 24,
    this.buttonBorderWidth = 1.5,
  });

  BannerElementModel copyWith({
    String? content,
    double? dx,
    double? dy,
    double? widthFraction,
    double? heightFraction,
    double? fontSize,
    String? fontFamily,
    String? colorHex,
    bool? isBold,
    double? rotation,
    String? buttonBgColorHex,
    String? buttonBorderColorHex,
    double? buttonBorderRadius,
    double? buttonBorderWidth,
  }) {
    return BannerElementModel(
      id: id,
      type: type,
      content: content ?? this.content,
      dx: dx ?? this.dx,
      dy: dy ?? this.dy,
      widthFraction: widthFraction ?? this.widthFraction,
      heightFraction: heightFraction ?? this.heightFraction,
      fontSize: fontSize ?? this.fontSize,
      fontFamily: fontFamily ?? this.fontFamily,
      colorHex: colorHex ?? this.colorHex,
      isBold: isBold ?? this.isBold,
      rotation: rotation ?? this.rotation,
      buttonBgColorHex: buttonBgColorHex ?? this.buttonBgColorHex,
      buttonBorderColorHex: buttonBorderColorHex ?? this.buttonBorderColorHex,
      buttonBorderRadius: buttonBorderRadius ?? this.buttonBorderRadius,
      buttonBorderWidth: buttonBorderWidth ?? this.buttonBorderWidth,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type.name,
      'content': content,
      'dx': dx,
      'dy': dy,
      'widthFraction': widthFraction,
      'heightFraction': heightFraction,
      'fontSize': fontSize,
      'fontFamily': fontFamily,
      'colorHex': colorHex,
      'isBold': isBold,
      'rotation': rotation,
      'buttonBgColorHex': buttonBgColorHex,
      'buttonBorderColorHex': buttonBorderColorHex,
      'buttonBorderRadius': buttonBorderRadius,
      'buttonBorderWidth': buttonBorderWidth,
    };
  }

  factory BannerElementModel.fromMap(Map<String, dynamic> map) {
    return BannerElementModel(
      id: map['id'] ?? '',
      type: elementTypeFromString(map['type'] ?? 'title'),
      content: map['content'] ?? '',
      dx: (map['dx'] ?? 0.1).toDouble(),
      dy: (map['dy'] ?? 0.1).toDouble(),
      widthFraction: (map['widthFraction'] ?? 0.3).toDouble(),
      heightFraction: (map['heightFraction'] ?? 0.15).toDouble(),
      fontSize: (map['fontSize'] ?? 18).toDouble(),
      fontFamily: map['fontFamily'] ?? 'Default',
      colorHex: map['colorHex'] ?? '#FFFFFF',
      isBold: map['isBold'] ?? false,
      rotation: (map['rotation'] ?? 0).toDouble(),
      buttonBgColorHex: map['buttonBgColorHex'],
      buttonBorderColorHex: map['buttonBorderColorHex'],
      buttonBorderRadius: (map['buttonBorderRadius'] ?? 24).toDouble(),
      buttonBorderWidth: (map['buttonBorderWidth'] ?? 1.5).toDouble(),
    );
  }
}
