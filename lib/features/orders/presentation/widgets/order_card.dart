import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class CommonListCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String imageUrl;
  final String price;
  final VoidCallback onView;
  final VoidCallback onAccept;
  final VoidCallback onReject;
  final bool isHistory;

  const CommonListCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.imageUrl,
    required this.price,
    required this.onView,
    required this.onAccept,
    required this.onReject,
    this.isHistory = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        children: [
          // SMART IMAGE BUILDER
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color: Colors.black26,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: _buildImage(imageUrl),
            ),
          ),
          const SizedBox(width: 15),
          // DETAILS
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.orbitron(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(color: Colors.white60, fontSize: 11),
                ),
                const SizedBox(height: 6),
                Text(
                  price,
                  style: const TextStyle(
                    color: Colors.redAccent,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          // ACTIONS
          Row(
            children: [
              _actionIcon(Icons.visibility, Colors.blue, onView),
              if (!isHistory) ...[
                _actionIcon(Icons.check_circle, Colors.green, onAccept),
                _actionIcon(Icons.cancel, Colors.redAccent, onReject),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _actionIcon(IconData icon, Color color, VoidCallback onTap) {
    return IconButton(
      onPressed: onTap,
      icon: Icon(icon, color: color, size: 22),
      visualDensity: VisualDensity.compact,
    );
  }

  Widget _buildImage(String data) {
    if (data.isEmpty) return const Icon(Icons.image, color: Colors.white24);
    try {
      if (data.startsWith('http')) {
        return Image.network(
          data,
          fit: BoxFit.cover,
          errorBuilder: (c, e, s) =>
              const Icon(Icons.broken_image, color: Colors.white24),
        );
      }
      return Image.memory(
        base64Decode(data.split(',').last),
        fit: BoxFit.cover,
        errorBuilder: (c, e, s) =>
            const Icon(Icons.broken_image, color: Colors.white24),
      );
    } catch (e) {
      return const Icon(Icons.error_outline, color: Colors.red);
    }
  }
}
