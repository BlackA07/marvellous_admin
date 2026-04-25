import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class StaffUiHelpers {
  static const Color bg = Color(0xFF0D0D1A);
  static const Color surface = Color(0xFF1A1A2E);
  static const Color card = Color(0xFF16213E);
  static const Color cardBorder = Color(0xFF2A2A4A);
  static const Color accent = Color(0xFF4F8EF7);
  static const Color accentDark = Color(0xFF1A237E);
  static const Color green = Color(0xFF00E5CC);
  static const Color amber = Color(0xFFFFB300);
  static const Color textWhite = Color(0xFFEAEAFF);
  static const Color textMid = Color(0xFF9090B0);
  static const Color red = Color(0xFFFF5252);

  static Widget sectionCard({required List<Widget> children}) {
    return Container(
      decoration: BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cardBorder, width: 1.2),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  static Widget sectionTitle(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: accent.withOpacity(0.18),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: accent, size: 22),
          ),
          const SizedBox(width: 12),
          Text(
            title,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: textWhite,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }

  static InputDecoration inputDeco({
    required String label,
    String? hint,
    Widget? prefix,
    Widget? suffix,
    Widget? prefixIcon,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: prefixIcon,
      suffixIcon: suffix,
      labelStyle: const TextStyle(
        fontSize: 15,
        color: textMid,
        fontWeight: FontWeight.w500,
      ),
      hintStyle: TextStyle(fontSize: 14, color: textMid.withOpacity(0.5)),
      filled: true,
      fillColor: surface,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: cardBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: cardBorder, width: 1.2),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: accent, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: red, width: 1.5),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: red, width: 2),
      ),
      errorStyle: const TextStyle(fontSize: 13, color: red),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }

  static Widget inputField({
    required String label,
    required TextEditingController fieldController,
    String? hint,
    TextInputType keyboardType = TextInputType.text,
    bool optional = false,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
    int maxLines = 1,
    Widget? prefixIcon,
    Widget? suffixIcon,
    void Function(String)? onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: fieldController,
        keyboardType: keyboardType,
        maxLines: maxLines,
        inputFormatters: inputFormatters,
        onChanged: onChanged,
        validator:
            validator ??
            (optional
                ? null
                : (v) => (v == null || v.trim().isEmpty)
                      ? '$label is required'
                      : null),
        style: const TextStyle(
          fontSize: 15,
          color: textWhite,
          fontWeight: FontWeight.w500,
        ),
        cursorColor: accent,
        decoration: inputDeco(
          label: label + (optional ? ' (Optional)' : ''),
          hint: hint,
          prefixIcon: prefixIcon,
          suffix: suffixIcon,
        ),
      ),
    );
  }
}
