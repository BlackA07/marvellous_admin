// File: lib/features/mlm/presentation/widgets/mlm_node_widget.dart

import 'package:flutter/material.dart';
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
        // 1. Top Vertical Line (Parent se connect hone k liye)
        if (!isRoot)
          Container(width: 2, height: 20, color: Colors.grey.shade400),

        // 2. The Node Card (Avatar + Name)
        _buildNodeCard(context),

        // 3. Children Lines and Nodes
        if (node.children.isNotEmpty) ...[
          // Card se niche nikalne wali line
          Container(width: 2, height: 20, color: Colors.grey.shade400),

          // Children Container
          Stack(
            children: [
              // Horizontal Line (Connects first child to last child)
              if (node.children.length > 1)
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    height: 2,
                    color: Colors.grey.shade400,
                    // Note: In a pure custom widget, aligning this perfectly
                    // to the center of first and last child needs strict width constraints.
                    // This is a simplified visual representation.
                  ),
                ),

              // Row of Children
              Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: node.children.map((child) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12.0),
                    child: Column(
                      children: [
                        // Line from Horizontal bar down to child
                        Container(
                          width: 2,
                          height: 20,
                          // Only show this top line if we are under the horizontal bar
                          // Logic handled by padding mostly
                          color: node.children.length > 1
                              ? Colors.grey.shade400
                              : Colors.transparent,
                        ),
                        MLMNodeWidget(node: child, isRoot: false),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildNodeCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blueAccent.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            blurRadius: 6,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: Colors.blueAccent,
            child: Text(
              node.initials,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            node.name,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            overflow: TextOverflow.ellipsis,
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            margin: const EdgeInsets.only(top: 2),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              node.role,
              style: TextStyle(fontSize: 10, color: Colors.grey.shade800),
            ),
          ),
        ],
      ),
    );
  }
}
