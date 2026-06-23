// lib/features/reports/shared/widgets/report_summary_cards.dart
//
// Horizontal scrollable summary stat cards — shown at the top of every report.
// Har report apna summaryStats map pass karta hai.

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ReportSummaryCards extends StatelessWidget {
  /// key = label, value = display value string
  final Map<String, String> stats;
  final List<Color>? colors; // optional per-card accent colors

  const ReportSummaryCards({super.key, required this.stats, this.colors});

  static const _defaultColors = [
    Color(0xFF2563EB),
    Color(0xFF16A34A),
    Color(0xFFD97706),
    Color(0xFF7C3AED),
    Color(0xFFDC2626),
    Color(0xFF0891B2),
    Color(0xFF059669),
    Color(0xFFDB2777),
  ];

  @override
  Widget build(BuildContext context) {
    if (stats.isEmpty) return const SizedBox.shrink();

    final entries = stats.entries.toList();

    return SizedBox(
      height: 86,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: entries.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (_, i) {
          final color = (colors != null && i < colors!.length)
              ? colors![i]
              : _defaultColors[i % _defaultColors.length];
          return _SummaryCard(
            label: entries[i].key,
            value: entries[i].value,
            color: color,
          );
        },
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _SummaryCard({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 150,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Color accent bar
          Container(
            width: 28,
            height: 3,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.nunito(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF1E293B),
              height: 1.1,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 3),
          Text(
            label,
            style: GoogleFonts.nunito(
              fontSize: 11,
              color: const Color(0xFF94A3B8),
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
