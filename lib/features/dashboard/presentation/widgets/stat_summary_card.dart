import 'package:flutter/material.dart';
import '../../models/dashboard_stats_model.dart';

class StatSummaryCard extends StatelessWidget {
  final DashboardStatsModel info;

  const StatSummaryCard({Key? key, required this.info}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Screen width check for font scaling
    double width = MediaQuery.of(context).size.width;
    bool isDesktop = width > 1100;

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2D3E),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: info.color.withOpacity(0.1),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Top Row: Icon
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: info.color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(
                  info.icon,
                  color: info.color,
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

          const Spacer(), // Use spacer to push content down properly
          // Value (FittedBox prevents overflow)
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              info.value,
              style: TextStyle(
                fontFamily: 'Comic Sans MS',
                color: Colors.white,
                // Mobile: 18, Desktop: 24
                fontSize: isDesktop ? 24 : 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          // Title
          Text(
            info.title,
            style: TextStyle(
              fontFamily: 'Comic Sans MS',
              color: Colors.white70,
              // Mobile: 11, Desktop: 14
              fontSize: isDesktop ? 14 : 11,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),

          const SizedBox(height: 6),

          // Bottom Row: Change
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Row(
              children: [
                Icon(
                  info.isIncrease ? Icons.arrow_upward : Icons.arrow_downward,
                  color: info.isIncrease
                      ? Colors.greenAccent
                      : Colors.redAccent,
                  size: isDesktop ? 12 : 10,
                ),
                const SizedBox(width: 2),
                Text(
                  info.change,
                  style: TextStyle(
                    fontFamily: 'Comic Sans MS',
                    color: info.isIncrease
                        ? Colors.greenAccent
                        : Colors.redAccent,
                    // Mobile: 10, Desktop: 12
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
                    // Mobile: 9, Desktop: 11
                    fontSize: isDesktop ? 11 : 8,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
