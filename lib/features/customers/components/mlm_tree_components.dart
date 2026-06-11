import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../mlm/data/models/mlm_models.dart';
import '../presentation/screens/customer_detail_screen.dart';

class FullscreenTreePage extends StatefulWidget {
  final MLMNode node;
  const FullscreenTreePage({Key? key, required this.node}) : super(key: key);
  @override
  State<FullscreenTreePage> createState() => _FullscreenTreePageState();
}

class _FullscreenTreePageState extends State<FullscreenTreePage> {
  final TransformationController _ctrl = TransformationController();
  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4FF),
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Text(
          "Network Tree",
          style: GoogleFonts.comicNeue(
            fontWeight: FontWeight.w900,
            color: Colors.black,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.black),
        actions: [
          IconButton(
            icon: const Icon(Icons.fit_screen),
            onPressed: () => setState(() => _ctrl.value = Matrix4.identity()),
            tooltip: "Reset zoom",
          ),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
      body: InteractiveViewer(
        transformationController: _ctrl,
        boundaryMargin: const EdgeInsets.all(400),
        minScale: 0.2,
        maxScale: 4.0,
        constrained: false,
        panAxis: PanAxis.free,
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: AdminTreeNodeWidget(node: widget.node),
        ),
      ),
    );
  }
}

class AdminTreeViewport extends StatefulWidget {
  final MLMNode node;
  const AdminTreeViewport({Key? key, required this.node}) : super(key: key);
  @override
  State<AdminTreeViewport> createState() => _AdminTreeViewportState();
}

class _AdminTreeViewportState extends State<AdminTreeViewport> {
  final TransformationController _transformCtrl = TransformationController();
  bool _isInteracting = false;

  void _zoomIn() => _transformCtrl.value = Matrix4.identity()
    ..scale((_transformCtrl.value.getMaxScaleOnAxis() + 0.2).clamp(0.5, 4.0));
  void _zoomOut() => _transformCtrl.value = Matrix4.identity()
    ..scale((_transformCtrl.value.getMaxScaleOnAxis() - 0.2).clamp(0.5, 4.0));
  void _resetZoom() => _transformCtrl.value = Matrix4.identity();

  @override
  void dispose() {
    _transformCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 460,
      decoration: BoxDecoration(
        color: const Color(0xFFF0F4FF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.indigo.shade100, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.indigo.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(15),
            child: Listener(
              onPointerDown: (_) => setState(() => _isInteracting = true),
              onPointerUp: (_) => setState(() => _isInteracting = false),
              onPointerCancel: (_) => setState(() => _isInteracting = false),
              child: InteractiveViewer(
                transformationController: _transformCtrl,
                boundaryMargin: const EdgeInsets.all(200),
                minScale: 0.5,
                maxScale: 4.0,
                constrained: false,
                panAxis: PanAxis.free,
                scaleEnabled: true,
                onInteractionStart: (_) =>
                    setState(() => _isInteracting = true),
                onInteractionEnd: (_) => setState(() => _isInteracting = false),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: AdminTreeNodeWidget(node: widget.node),
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 12,
            right: 12,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.zoom_out, size: 22),
                    onPressed: _zoomOut,
                    constraints: const BoxConstraints(
                      minWidth: 40,
                      minHeight: 40,
                    ),
                    padding: EdgeInsets.zero,
                  ),
                  const VerticalDivider(
                    width: 1,
                    thickness: 1,
                    color: Colors.grey,
                  ),
                  IconButton(
                    icon: const Icon(Icons.zoom_in, size: 22),
                    onPressed: _zoomIn,
                    constraints: const BoxConstraints(
                      minWidth: 40,
                      minHeight: 40,
                    ),
                    padding: EdgeInsets.zero,
                  ),
                  const VerticalDivider(
                    width: 1,
                    thickness: 1,
                    color: Colors.grey,
                  ),
                  IconButton(
                    icon: const Icon(Icons.fit_screen, size: 22),
                    onPressed: _resetZoom,
                    constraints: const BoxConstraints(
                      minWidth: 40,
                      minHeight: 40,
                    ),
                    padding: EdgeInsets.zero,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class AdminTreeNodeWidget extends StatelessWidget {
  final MLMNode node;
  const AdminTreeNodeWidget({Key? key, required this.node}) : super(key: key);

  static Color _borderColor(int level) {
    const colors = [
      Color(0xFF3B5BDB),
      Color(0xFF2E7D32),
      Color(0xFFE65100),
      Color(0xFF6A1B9A),
      Color(0xFF00695C),
      Color(0xFFC62828),
      Color(0xFF1565C0),
    ];
    return colors[level % colors.length];
  }

  static Color _rankColor(String rank) {
    switch (rank.toLowerCase()) {
      case 'silver':
        return Colors.blueGrey.shade600;
      case 'gold':
        return const Color(0xFFB8860B);
      case 'diamond':
        return const Color(0xFF1565C0);
      default:
        return const Color(0xFF6D4C41);
    }
  }

  Widget _smallBadge(String text, Color textColor, Color bgColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: textColor, width: 1),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w900,
          color: textColor,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildImage(String data) {
    if (data.trim().isEmpty)
      return const Icon(Icons.person, color: Colors.grey, size: 36);
    try {
      String cleanData = data.trim();
      if (cleanData.startsWith('http')) {
        return Image.network(
          cleanData,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) =>
              const Icon(Icons.person, color: Colors.grey),
        );
      }
      if (cleanData.contains(',')) cleanData = cleanData.split(',').last;
      cleanData = cleanData.replaceAll(RegExp(r'\s+'), '');
      return Image.memory(
        base64Decode(cleanData),
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) =>
            const Icon(Icons.person, color: Colors.grey),
      );
    } catch (_) {
      return const Icon(Icons.person, color: Colors.grey, size: 36);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool hasChildren = node.children.isNotEmpty;
    final Color borderClr = _borderColor(node.level);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: () {
            if (node.level > 0)
              Get.to(
                () => CustomerDetailScreen(uid: node.uid),
                preventDuplicates: false,
              );
          },
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 76,
                height: 76,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  border: Border.all(color: borderClr, width: 3),
                  boxShadow: [
                    BoxShadow(
                      color: borderClr.withOpacity(0.25),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: ClipOval(child: _buildImage(node.image)),
              ),
              const SizedBox(height: 6),
              Container(
                constraints: const BoxConstraints(maxWidth: 96),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: borderClr,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  node.name.length > 13
                      ? '${node.name.substring(0, 13)}…'
                      : node.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                  ),
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(height: 3),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: _rankColor(node.rank).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(7),
                  border: Border.all(color: _rankColor(node.rank), width: 1),
                ),
                child: Text(
                  node.rank.toUpperCase(),
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                    color: _rankColor(node.rank),
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              const SizedBox(height: 3),
              Text(
                node.level == 0 ? "YOU" : "Level ${node.level}",
                style: TextStyle(
                  fontSize: 11,
                  color: borderClr,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 3),
              if (node.level > 0)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (node.isDirectReferral)
                      _smallBadge(
                        "D",
                        Colors.green.shade700,
                        Colors.green.shade50,
                      ),
                    if (node.isDirectReferral && node.isOverflow)
                      const SizedBox(width: 4),
                    if (node.isOverflow)
                      _smallBadge(
                        "OF",
                        Colors.purple.shade700,
                        Colors.purple.shade50,
                      ),
                  ],
                ),
              if (node.level == 0) ...[
                const SizedBox(height: 4),
                Text(
                  "Rs.${node.totalCommissionEarned.toStringAsFixed(0)}",
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    color: borderClr,
                  ),
                ),
              ],
              if (node.level > 0)
                const Text(
                  "tap to view",
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.black38,
                    fontStyle: FontStyle.italic,
                  ),
                ),
            ],
          ),
        ),
        if (hasChildren) ...[
          Container(width: 2, height: 24, color: Colors.grey.shade400),
          if (node.children.length > 1)
            CustomPaint(
              size: Size((node.children.length * 116.0) - 20, 2),
              painter: LinePainter(color: Colors.grey.shade400),
            ),
          Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: node.children
                .map(
                  (child) => Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 2,
                          height: 24,
                          color: Colors.grey.shade400,
                        ),
                        AdminTreeNodeWidget(node: child),
                      ],
                    ),
                  ),
                )
                .toList(),
          ),
        ],
      ],
    );
  }
}

class LinePainter extends CustomPainter {
  final Color color;
  const LinePainter({required this.color});
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawLine(
      Offset.zero,
      Offset(size.width, 0),
      Paint()
        ..color = color
        ..strokeWidth = 2,
    );
  }

  @override
  bool shouldRepaint(LinePainter old) => false;
}
