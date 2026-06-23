// lib/features/reports/shared/widgets/stat_summary_card.dart

import 'package:flutter/material.dart';
import '../../models/dashboard_stats_model.dart';

class StatSummaryCard extends StatefulWidget {
  final DashboardStatsModel info;
  const StatSummaryCard({Key? key, required this.info}) : super(key: key);

  @override
  State<StatSummaryCard> createState() => _StatSummaryCardState();
}

class _StatSummaryCardState extends State<StatSummaryCard> {
  bool isHovered = false;

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    bool isDesktop = width > 1100;

    return MouseRegion(
      onEnter: (_) => setState(() => isHovered = true),
      onExit: (_) => setState(() => isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        transform: isHovered
            ? Matrix4.identity().scaled(1.05)
            : Matrix4.identity(),
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: isHovered
              ? widget.info.color.withOpacity(0.15)
              : const Color(0xFF2A2D3E),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: isHovered
                  ? widget.info.color.withOpacity(0.3)
                  : widget.info.color.withOpacity(0.1),
              blurRadius: isHovered ? 12 : 6,
              offset: const Offset(0, 3),
            ),
          ],
          border: Border.all(
            color: isHovered
                ? widget.info.color.withOpacity(0.5)
                : const Color.fromARGB(255, 0, 0, 0).withOpacity(0.1),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icon without forward arrow
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: widget.info.color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(widget.info.icon, color: widget.info.color, size: 24),
            ),
            const Spacer(),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                widget.info.value,
                style: const TextStyle(
                  fontFamily: 'Comic Sans MS',
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              widget.info.title,
              style: const TextStyle(
                fontFamily: 'Comic Sans MS',
                color: Colors.white70,
                fontSize: 13,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            if (widget.info.subtitle.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                widget.info.subtitle,
                style: TextStyle(
                  fontFamily: 'Comic Sans MS',
                  color: widget.info.color,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
