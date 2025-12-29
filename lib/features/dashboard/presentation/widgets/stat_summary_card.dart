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
        padding: const EdgeInsets.all(10),
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
                : Colors.white.withOpacity(0.1),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Top Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    color: widget.info.color.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(
                    widget.info.icon,
                    color: widget.info.color,
                    size: isDesktop ? 20 : 16,
                  ),
                ),
                Icon(
                  Icons.more_vert,
                  color: Colors.white54,
                  size: isDesktop ? 20 : 16,
                ),
              ],
            ),

            const Spacer(),

            // Value
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                widget.info.value,
                style: TextStyle(
                  fontFamily: 'Comic Sans MS',
                  color: Colors.white,
                  fontSize: isDesktop ? 24 : 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            // Title
            Text(
              widget.info.title,
              style: TextStyle(
                fontFamily: 'Comic Sans MS',
                color: Colors.white70,
                fontSize: isDesktop ? 14 : 11,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),

            const SizedBox(height: 6),

            // Bottom Row: Percent Change
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Row(
                children: [
                  Icon(
                    widget.info.isIncrease
                        ? Icons.arrow_upward
                        : Icons.arrow_downward,
                    color: widget.info.isIncrease
                        ? Colors.greenAccent
                        : Colors.redAccent,
                    size: isDesktop ? 12 : 10,
                  ),
                  const SizedBox(width: 2),
                  Text(
                    widget.info.change,
                    style: TextStyle(
                      fontFamily: 'Comic Sans MS',
                      color: widget.info.isIncrease
                          ? Colors.greenAccent
                          : Colors.redAccent,
                      fontSize: isDesktop ? 12 : 8,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    "vs last month",
                    style: TextStyle(
                      fontFamily: 'Comic Sans MS',
                      color: Colors.white38,
                      fontSize: isDesktop ? 11 : 8,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
