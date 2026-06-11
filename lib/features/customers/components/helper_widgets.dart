import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

Widget buildDivider() => const Divider(height: 1, indent: 16, endIndent: 16);

Widget buildInfoRowCopyable(String label, String value, IconData icon) {
  return GestureDetector(
    onTap: () {
      Clipboard.setData(ClipboardData(text: value));
      Get.snackbar(
        "Copied",
        "$label copied",
        snackPosition: SnackPosition.BOTTOM,
      );
    },
    child: Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey.shade700),
        const SizedBox(width: 6),
        Text(
          "$label: ",
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w900,
              color: Colors.black,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const Icon(Icons.copy, size: 14, color: Colors.blue),
      ],
    ),
  );
}

Widget buildInfoRowIcon(
  String label,
  String value,
  IconData icon,
  Color valueColor,
) {
  return Row(
    children: [
      Icon(icon, size: 16, color: Colors.grey.shade700),
      const SizedBox(width: 8),
      Text(
        "$label: ",
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
      ),
      Expanded(
        child: Text(
          value,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w900,
            color: valueColor,
          ),
          overflow: TextOverflow.ellipsis,
        ),
      ),
    ],
  );
}

Widget buildInfoRowCompact(
  String label,
  String value,
  IconData icon,
  Color color,
) {
  return Row(
    children: [
      Icon(icon, size: 14, color: color),
      const SizedBox(width: 4),
      Text(
        "$label: ",
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
      ),
      Text(
        value,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w900,
          color: color,
        ),
      ),
    ],
  );
}

Widget buildInfoRowMultiLine(
  String label,
  String value,
  IconData icon,
  Color valueColor,
) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey.shade700),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: Colors.black87,
            ),
          ),
        ],
      ),
      const SizedBox(height: 6),
      Text(
        value,
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w900,
          color: valueColor,
        ),
      ),
    ],
  );
}

Widget buildStatRow(
  String title,
  String value,
  IconData icon,
  Color color, {
  bool isFirst = false,
  bool isLast = false,
}) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.only(
        topLeft: isFirst ? const Radius.circular(20) : Radius.zero,
        topRight: isFirst ? const Radius.circular(20) : Radius.zero,
        bottomLeft: isLast ? const Radius.circular(20) : Radius.zero,
        bottomRight: isLast ? const Radius.circular(20) : Radius.zero,
      ),
    ),
    child: Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            title,
            style: GoogleFonts.comicNeue(
              fontSize: 17,
              fontWeight: FontWeight.w900,
              color: Colors.black87,
            ),
          ),
        ),
        Text(
          value,
          style: GoogleFonts.comicNeue(
            fontSize: 20,
            fontWeight: FontWeight.w900,
            color: Colors.black,
          ),
        ),
      ],
    ),
  );
}

Widget buildStatRowTappable(
  String title,
  String value,
  IconData icon,
  Color color, {
  required VoidCallback onTap,
}) {
  return InkWell(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              title,
              style: GoogleFonts.comicNeue(
                fontSize: 17,
                fontWeight: FontWeight.w900,
                color: Colors.black87,
              ),
            ),
          ),
          Text(
            value,
            style: GoogleFonts.comicNeue(
              fontSize: 17,
              fontWeight: FontWeight.w900,
              color: color,
            ),
          ),
          const SizedBox(width: 4),
          Icon(Icons.chevron_right, color: Colors.grey.shade500, size: 24),
        ],
      ),
    ),
  );
}

Widget buildBadge(String text, Color textColor, Color bgColor) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    decoration: BoxDecoration(
      color: bgColor,
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: textColor.withOpacity(0.6), width: 1.5),
    ),
    child: Text(
      text,
      style: GoogleFonts.comicNeue(
        fontWeight: FontWeight.w900,
        color: textColor,
        fontSize: 13,
      ),
    ),
  );
}

Widget buildBase64Image(String imageData) {
  if (imageData.trim().isEmpty)
    return const Icon(Icons.person, color: Colors.grey, size: 80);
  try {
    String cleanData = imageData.trim();
    if (cleanData.startsWith('http')) {
      return Image.network(
        cleanData,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) =>
            const Icon(Icons.person, color: Colors.grey, size: 80),
      );
    }
    if (cleanData.contains(',')) cleanData = cleanData.split(',').last;
    cleanData = cleanData.replaceAll(RegExp(r'\s+'), '');
    return Image.memory(
      base64Decode(cleanData),
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) =>
          const Icon(Icons.person, color: Colors.grey, size: 80),
    );
  } catch (_) {
    return const Icon(Icons.person, color: Colors.grey, size: 80);
  }
}

Widget buildDatePickerBtn(
  String label,
  DateTime date,
  BuildContext context,
  Function(DateTime) onPicked,
) {
  return InkWell(
    onTap: () async {
      final picked = await showDatePicker(
        context: context,
        initialDate: date,
        firstDate: DateTime(2020),
        lastDate: DateTime(2100),
      );
      if (picked != null) onPicked(picked);
    },
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade300, width: 1.5),
      ),
      child: Row(
        children: [
          Icon(Icons.calendar_month, color: Colors.grey.shade700, size: 22),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 11,
                  color: Colors.black54,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                DateFormat('dd MMM, yy').format(date),
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 14,
                  color: Colors.black,
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}

Widget buildLegendItem(Color color, String label) {
  return Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: 12,
        height: 12,
        decoration: BoxDecoration(shape: BoxShape.circle, color: color),
      ),
      const SizedBox(width: 5),
      Text(
        label,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
      ),
    ],
  );
}
