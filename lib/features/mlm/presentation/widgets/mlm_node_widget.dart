import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../data/models/mlm_models.dart';

class MLMNodeWidget extends StatelessWidget {
  final MLMNode node;
  final bool isRoot;

  const MLMNodeWidget({Key? key, required this.node, this.isRoot = false})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Top Vertical Line (unless root)
        if (!isRoot)
          Container(width: 2, height: 30, color: Colors.grey.shade400),

        // The Node Card
        _buildNodeCard(context),

        // Children or Summary
        if (node.isMLMActive) ...[
          if (node.children.isNotEmpty && node.level < 3) ...[
            // Vertical line down
            Container(width: 2, height: 30, color: Colors.grey.shade400),

            // Children Row
            _buildChildrenRow(),
          ] else if (node.level >= 3 && node.totalMembers > 0) ...[
            // Show summary dots for level 3+
            Container(width: 2, height: 20, color: Colors.grey.shade400),
            _buildSummaryDots(),
          ],
        ],
      ],
    );
  }

  Widget _buildNodeCard(BuildContext context) {
    Color rankColor = _getRankColor(node.rank);

    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: node.hasPaidFee ? Colors.green : rankColor.withOpacity(0.5),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: rankColor.withOpacity(0.3),
            blurRadius: 8,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Image
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: rankColor, width: 3),
            ),
            child: ClipOval(
              child: node.image.isNotEmpty
                  ? _buildImage(node.image)
                  : CircleAvatar(
                      backgroundColor: rankColor,
                      child: Text(
                        node.initials,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 8),

          // Name
          Text(
            node.name,
            style: GoogleFonts.comicNeue(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),

          // Level Badge
          Container(
            margin: const EdgeInsets.only(top: 4),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: rankColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              'Level ${node.level}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          const SizedBox(height: 8),

          // Stats Row
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _statBadge('${node.children.length}/7', Colors.blue, 'Direct'),
              const SizedBox(width: 6),
              _statBadge('${node.remainingSlots}', Colors.orange, 'Slots'),
            ],
          ),

          const SizedBox(height: 6),

          // Total Members
          _statBadge(
            'Total: ${node.totalMembers}',
            Colors.purple,
            'All Members',
          ),

          const SizedBox(height: 6),

          // Paid Members
          _statBadge(
            'Paid: ${node.paidMembers}/${node.totalMembers}',
            Colors.green,
            'Fee Status',
          ),

          const SizedBox(height: 6),

          // Total Commission
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.purple.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.purple.shade200),
            ),
            child: Column(
              children: [
                Text(
                  'Commission',
                  style: TextStyle(
                    fontSize: 9,
                    color: Colors.purple.shade900,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Rs ${node.totalCommissionEarned.toStringAsFixed(0)}',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.purple.shade900,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),

          // Rank Badge
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: rankColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(_getRankIcon(node.rank), size: 12, color: rankColor),
                const SizedBox(width: 4),
                Text(
                  node.rank.toUpperCase(),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: rankColor,
                  ),
                ),
              ],
            ),
          ),

          // Fee Status Indicator
          if (node.hasPaidFee)
            Container(
              margin: const EdgeInsets.only(top: 4),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.green.shade100,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(Icons.check_circle, size: 10, color: Colors.green),
                  SizedBox(width: 3),
                  Text(
                    'Fee Paid',
                    style: TextStyle(
                      fontSize: 9,
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildChildrenRow() {
    return Stack(
      children: [
        // Horizontal connecting line
        if (node.children.length > 1)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(height: 2, color: Colors.grey.shade400),
          ),

        // Children
        Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: node.children.map((child) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0),
              child: Column(
                children: [
                  // Top connector
                  if (node.children.length > 1)
                    Container(
                      width: 2,
                      height: 30,
                      color: Colors.grey.shade400,
                    ),
                  MLMNodeWidget(node: child, isRoot: false),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildSummaryDots() {
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: Colors.grey.shade400,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 4),
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: Colors.grey.shade400,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 4),
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: Colors.grey.shade400,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Total: ${node.totalMembers}',
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: Colors.black54,
            ),
          ),
          Text(
            'Paid: ${node.paidMembers}',
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: Colors.green,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Rs ${node.totalCommissionEarned.toStringAsFixed(0)}',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: Colors.purple.shade700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _statBadge(String text, Color color, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: Colors.black,
        ),
      ),
    );
  }

  Widget _buildImage(String data) {
    if (data.isEmpty)
      return const Icon(Icons.person, size: 40, color: Colors.grey);
    try {
      if (data.startsWith('http')) {
        return Image.network(data, fit: BoxFit.cover);
      }
      return Image.memory(base64Decode(data), fit: BoxFit.cover);
    } catch (e) {
      return const Icon(Icons.person, size: 40, color: Colors.grey);
    }
  }

  Color _getRankColor(String rank) {
    switch (rank.toLowerCase()) {
      case 'bronze':
        return Colors.brown;
      case 'silver':
        return Colors.grey.shade600;
      case 'gold':
        return Colors.amber.shade700;
      case 'diamond':
        return Colors.blue.shade700;
      default:
        return Colors.grey;
    }
  }

  IconData _getRankIcon(String rank) {
    switch (rank.toLowerCase()) {
      case 'bronze':
        return Icons.emoji_events;
      case 'silver':
        return Icons.emoji_events;
      case 'gold':
        return Icons.emoji_events;
      case 'diamond':
        return Icons.diamond;
      default:
        return Icons.star;
    }
  }
}
