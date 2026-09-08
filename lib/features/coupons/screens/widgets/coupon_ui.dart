// lib/features/coupons/screens/widgets/coupon_ui.dart
//
// Small reusable UI pieces for the coupons module. They follow the admin
// panel's dark theme (Pallete.metalDark + neonBlue) so these screens feel like
// part of the rest of the panel.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/pallete.dart';
import '../../models/coupon_model.dart';

// ─── COLORS ───────────────────────────────────────────────────────────────
const Color kCouponSurface = Color(0xFF23272E);
const Color kCouponSurfaceAlt = Color(0xFF2B3038);
const Color kCouponBorder = Color(0x1FFFFFFF);
const Color kCouponAccent = Pallete.neonBlue;

/// The same gradient the Announcements / Banners stats bars use.
const LinearGradient kCouponHeaderGradient = LinearGradient(
  colors: [Color(0xFF1E1B3A), Color(0xFF2A2450)],
);

/// Swatches offered by the design editor's color pickers.
const List<String> kCouponColorSwatches = [
  '#1E1B3A',
  '#2A2450',
  '#111827',
  '#000000',
  '#FFFFFF',
  '#F5F5F5',
  '#00F7FF',
  '#1ABC9C',
  '#2ECC71',
  '#27AE60',
  '#3498DB',
  '#2980B9',
  '#7F77DD',
  '#9B59B6',
  '#8E44AD',
  '#E74C3C',
  '#C0392B',
  '#D4537E',
  '#FF69B4',
  '#E67E22',
  '#F39C12',
  '#FAC775',
  '#FFD700',
  '#A0522D',
];

/// Curated fonts for the coupon card (a short version of the announcement list).
const List<String> kCouponFonts = [
  'Default',
  'Poppins',
  'Montserrat',
  'Inter',
  'Roboto',
  'Oswald',
  'Bebas Neue',
  'Anton',
  'Staatliches',
  'Righteous',
  'Orbitron',
  'Russo One',
  'Playfair Display',
  'Lobster',
  'Pacifico',
  'Permanent Marker',
];

// ─── SECTION CARD ─────────────────────────────────────────────────────────

/// One block of the form: icon + title + optional subtitle + content.
class CouponSection extends StatelessWidget {
  final String title;
  final IconData icon;
  final String? subtitle;
  final Widget child;
  final Widget? trailing;

  const CouponSection({
    super.key,
    required this.title,
    required this.icon,
    required this.child,
    this.subtitle,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      decoration: BoxDecoration(
        color: kCouponSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kCouponBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: kCouponAccent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(icon, size: 17, color: kCouponAccent),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.comicNeue(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    if (subtitle != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          subtitle!,
                          style: const TextStyle(
                            fontSize: 11.5,
                            color: Colors.white54,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              if (trailing != null) trailing!,
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

// ─── TEXT FIELD ───────────────────────────────────────────────────────────

class CouponTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String? hint;
  final String? helper;
  final IconData? icon;
  final Widget? suffix;
  final String? prefixText;
  final bool numeric;
  final bool uppercase;
  final int maxLines;
  final int? maxLength;

  const CouponTextField({
    super.key,
    required this.controller,
    required this.label,
    this.hint,
    this.helper,
    this.icon,
    this.suffix,
    this.prefixText,
    this.numeric = false,
    this.uppercase = false,
    this.maxLines = 1,
    this.maxLength,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      maxLength: maxLength,
      keyboardType: numeric
          ? const TextInputType.numberWithOptions(decimal: true)
          : (maxLines > 1 ? TextInputType.multiline : TextInputType.text),
      textCapitalization: uppercase
          ? TextCapitalization.characters
          : TextCapitalization.none,
      inputFormatters: [
        if (numeric) FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
        if (uppercase) UpperCaseTextFormatter(),
      ],
      style: const TextStyle(color: Colors.white, fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        helperText: helper,
        counterText: '',
        prefixText: prefixText,
        prefixStyle: const TextStyle(color: Colors.white70, fontSize: 14),
        prefixIcon: icon == null
            ? null
            : Icon(icon, size: 18, color: Colors.white38),
        suffixIcon: suffix,
        filled: true,
        fillColor: kCouponSurfaceAlt,
        labelStyle: const TextStyle(color: Colors.white60, fontSize: 13),
        hintStyle: const TextStyle(color: Colors.white24, fontSize: 13),
        helperStyle: const TextStyle(color: Colors.white38, fontSize: 11),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: kCouponBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: kCouponBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: kCouponAccent, width: 1.4),
        ),
      ),
    );
  }
}

class UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    return TextEditingValue(
      text: newValue.text.toUpperCase(),
      selection: newValue.selection,
    );
  }
}

// ─── OPTION TILE (radio-style choice) ─────────────────────────────────────

class CouponOptionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final bool selected;
  final VoidCallback onTap;
  final Widget? trailing;

  const CouponOptionTile({
    super.key,
    required this.icon,
    required this.title,
    required this.selected,
    required this.onTap,
    this.subtitle,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        decoration: BoxDecoration(
          color: selected
              ? kCouponAccent.withValues(alpha: 0.10)
              : kCouponSurfaceAlt,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? kCouponAccent : kCouponBorder,
            width: selected ? 1.4 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 19,
              color: selected ? kCouponAccent : Colors.white38,
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                      color: selected ? Colors.white : Colors.white70,
                    ),
                  ),
                  if (subtitle != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        subtitle!,
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.white38,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            if (trailing != null) trailing!,
            if (trailing == null && selected)
              const Icon(Icons.check_circle, size: 18, color: kCouponAccent),
          ],
        ),
      ),
    );
  }
}

/// Small pill-shaped toggle chip.
class CouponChip extends StatelessWidget {
  final String label;
  final IconData? icon;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback? onDelete;
  final Color? color;

  const CouponChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
    this.onDelete,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final tint = color ?? kCouponAccent;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(30),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? tint.withValues(alpha: 0.16) : kCouponSurfaceAlt,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: selected ? tint : kCouponBorder),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 14, color: selected ? tint : Colors.white38),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: selected ? FontWeight.w800 : FontWeight.w500,
                color: selected ? Colors.white : Colors.white60,
              ),
            ),
            if (onDelete != null) ...[
              const SizedBox(width: 6),
              InkWell(
                onTap: onDelete,
                child: const Icon(Icons.close, size: 14, color: Colors.white54),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ─── NUMBER STEPPER ───────────────────────────────────────────────────────

class CouponStepper extends StatelessWidget {
  final String label;
  final int value;
  final int min;
  final int max;
  final ValueChanged<int> onChanged;

  const CouponStepper({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.min = 1,
    this.max = 99,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: kCouponSurfaceAlt,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kCouponBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 12.5, color: Colors.white70),
          ),
          const SizedBox(width: 10),
          _RoundButton(
            icon: Icons.remove,
            onTap: value > min ? () => onChanged(value - 1) : null,
          ),
          SizedBox(
            width: 34,
            child: Text(
              '$value',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
          ),
          _RoundButton(
            icon: Icons.add,
            onTap: value < max ? () => onChanged(value + 1) : null,
          ),
        ],
      ),
    );
  }
}

class _RoundButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  const _RoundButton({required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(5),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: enabled
              ? kCouponAccent.withValues(alpha: 0.14)
              : Colors.white10,
        ),
        child: Icon(
          icon,
          size: 15,
          color: enabled ? kCouponAccent : Colors.white24,
        ),
      ),
    );
  }
}

// ─── COLOR PICKER ROW ─────────────────────────────────────────────────────

class CouponColorRow extends StatelessWidget {
  final String selectedHex;
  final ValueChanged<String> onPick;

  const CouponColorRow({
    super.key,
    required this.selectedHex,
    required this.onPick,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        ...kCouponColorSwatches.map((hex) {
          final selected = hex.toUpperCase() == selectedHex.toUpperCase();
          return GestureDetector(
            onTap: () => onPick(hex),
            child: Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: CouponModel.colorFromHex(hex),
                shape: BoxShape.circle,
                border: Border.all(
                  color: selected ? kCouponAccent : Colors.white24,
                  width: selected ? 3 : 1,
                ),
              ),
            ),
          );
        }),
        GestureDetector(
          onTap: () async {
            final picked = await _customHexDialog(context, selectedHex);
            if (picked != null) onPick(picked);
          },
          child: Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white38),
              gradient: const SweepGradient(
                colors: [
                  Colors.red,
                  Colors.yellow,
                  Colors.green,
                  Colors.blue,
                  Colors.purple,
                  Colors.red,
                ],
              ),
            ),
            child: const Icon(Icons.add, size: 15, color: Colors.white),
          ),
        ),
      ],
    );
  }

  Future<String?> _customHexDialog(BuildContext context, String current) {
    final field = TextEditingController(text: current);
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: kCouponSurface,
        title: const Text('Custom color', style: TextStyle(fontSize: 16)),
        content: TextField(
          controller: field,
          maxLength: 7,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: '#RRGGBB',
            counterText: '',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              var value = field.text.trim();
              if (!value.startsWith('#')) value = '#$value';
              if (value.length == 7) {
                Navigator.pop(context, value.toUpperCase());
              }
            },
            child: const Text('Apply'),
          ),
        ],
      ),
    );
  }
}

// ─── MISC ─────────────────────────────────────────────────────────────────

/// A light info / warning strip.
class CouponHint extends StatelessWidget {
  final String text;
  final IconData icon;
  final Color color;

  const CouponHint({
    super.key,
    required this.text,
    this.icon = Icons.info_outline,
    this.color = kCouponAccent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 15, color: color),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 11.5,
                height: 1.35,
                color: color.withValues(alpha: 0.92),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Switch + title + subtitle, so toggles look consistent across the form.
class CouponSwitchTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  final IconData icon;

  const CouponSwitchTile({
    super.key,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
    this.icon = Icons.tune,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: kCouponSurfaceAlt,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kCouponBorder),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 18,
            color: value ? kCouponAccent : Colors.white38,
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(fontSize: 11, color: Colors.white38),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            activeThumbColor: kCouponAccent,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

/// The search box that sits at the top of every picker.
class CouponSearchField extends StatelessWidget {
  final ValueChanged<String> onChanged;
  final String hint;
  final TextEditingController? controller;

  const CouponSearchField({
    super.key,
    required this.onChanged,
    this.hint = 'Search...',
    this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      style: const TextStyle(color: Colors.white, fontSize: 13.5),
      decoration: InputDecoration(
        hintText: hint,
        isDense: true,
        prefixIcon: const Icon(Icons.search, size: 18, color: Colors.white38),
        hintStyle: const TextStyle(color: Colors.white30, fontSize: 13),
        filled: true,
        fillColor: kCouponSurfaceAlt,
        contentPadding: const EdgeInsets.symmetric(vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: kCouponBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: kCouponBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: kCouponAccent),
        ),
      ),
    );
  }
}
