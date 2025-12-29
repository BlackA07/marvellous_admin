// File: lib/features/finance/presentation/widgets/earning_summary_card.dart

import 'package:flutter/material.dart';

class EarningSummaryCard extends StatefulWidget {
  final String title;
  final String amount;
  final IconData icon;
  final Color color;
  final VoidCallback onTap; // Click event add kiya

  const EarningSummaryCard({
    Key? key,
    required this.title,
    required this.amount,
    required this.icon,
    required this.color,
    required this.onTap,
  }) : super(key: key);

  @override
  State<EarningSummaryCard> createState() => _EarningSummaryCardState();
}

class _EarningSummaryCardState extends State<EarningSummaryCard> {
  bool isHovered = false;

  @override
  Widget build(BuildContext context) {
    // Responsive Font Sizes
    double width = MediaQuery.of(context).size.width;
    double titleSize = width > 600 ? 16 : 14;
    double amountSize = width > 600 ? 24 : 20;

    return MouseRegion(
      onEnter: (_) => setState(() => isHovered = true),
      onExit: (_) => setState(() => isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(16),
          // Hover hone par thora uper uthega aur shadow barh jayegi
          transform: isHovered
              ? Matrix4.translationValues(0, -5, 0)
              : Matrix4.identity(),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: widget.color.withOpacity(isHovered ? 0.3 : 0.1),
                blurRadius: isHovered ? 15 : 10,
                offset: isHovered ? const Offset(0, 8) : const Offset(0, 5),
              ),
            ],
            border: Border(left: BorderSide(color: widget.color, width: 4)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    widget.title,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: titleSize,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Icon(
                    widget.icon,
                    color: widget.color.withOpacity(0.8),
                    size: 24,
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                widget.amount,
                style: TextStyle(
                  fontSize: amountSize,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              // "View Details" text on hover (Optional, looks nice)
              if (isHovered)
                Text(
                  "Click to view details >",
                  style: TextStyle(fontSize: 10, color: widget.color),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
