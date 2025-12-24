import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/pallete.dart';

class MetallicTextField extends StatefulWidget {
  final String hintText;
  final IconData icon;
  final bool isPassword;
  final TextEditingController? controller;

  const MetallicTextField({
    super.key,
    required this.hintText,
    required this.icon,
    this.isPassword = false,
    this.controller,
  });

  @override
  State<MetallicTextField> createState() => _MetallicTextFieldState();
}

class _MetallicTextFieldState extends State<MetallicTextField>
    with SingleTickerProviderStateMixin {
  final FocusNode _focusNode = FocusNode();
  late AnimationController _snakeController;
  bool _hasFocus = false;

  @override
  void initState() {
    super.initState();
    _snakeController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );

    _focusNode.addListener(() {
      setState(() {
        _hasFocus = _focusNode.hasFocus;
        if (_hasFocus) {
          _snakeController.repeat();
        } else {
          _snakeController.stop();
          _snakeController.reset();
        }
      });
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _snakeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Gradient Setup
    const faceGradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        Colors.white, // Top Highlight
        Color(0xFFD0D5DD), // Light Silver
        Color(0xFF98A2B3), // Darker Silver
        Color(0xFF667085), // Shadow Base
      ],
      stops: [0.0, 0.4, 0.8, 1.0],
    );

    return Container(
      height: 65,
      margin: const EdgeInsets.symmetric(vertical: 10),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // --- LAYER 1: SILVER BASE ---
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFE0E0E0), Color(0xFF808080)],
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.6),
                  offset: const Offset(0, 8),
                  blurRadius: 10,
                ),
              ],
            ),
          ),

          // --- LAYER 2: SNAKE LIGHT ---
          if (_hasFocus)
            Padding(
              padding: const EdgeInsets.all(3.0),
              child: AnimatedBuilder(
                animation: _snakeController,
                builder: (context, child) {
                  return CustomPaint(
                    painter: _TextFieldSnakePainter(
                      animationValue: _snakeController.value,
                      color: Pallete.neonBlue,
                    ),
                    child: Container(),
                  );
                },
              ),
            ),

          // --- LAYER 3: DARK HOUSING ---
          Container(
            margin: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: const Color(0xFF151515),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black,
                  blurRadius: 4,
                  spreadRadius: 1,
                  offset: Offset(1, 1),
                ),
              ],
            ),
          ),

          // --- LAYER 4: FACE & INPUT ---
          Container(
            margin: const EdgeInsets.only(
              top: 6,
              bottom: 12,
              left: 6,
              right: 6,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              gradient: faceGradient,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.5),
                  offset: const Offset(0, 4),
                  blurRadius: 4,
                ),
                BoxShadow(
                  color: Colors.white.withOpacity(0.8),
                  offset: const Offset(0, 1),
                  blurRadius: 1,
                  spreadRadius: -1,
                ),
              ],
              border: Border.all(
                color: Colors.white.withOpacity(0.6),
                width: 1,
              ),
            ),
            child: Center(
              // Center widget zaroori hai
              child: TextField(
                focusNode: _focusNode,
                controller: widget.controller,
                obscureText: widget.isPassword,
                textAlignVertical:
                    TextAlignVertical.center, // Vertically Center
                style: GoogleFonts.comicNeue(
                  color: Colors.black87,
                  fontWeight: FontWeight.w900,
                  fontSize: 18,
                  letterSpacing: 1.0,
                ),
                decoration: InputDecoration(
                  isDense: true, // Compact mode on
                  prefixIcon: Padding(
                    padding: const EdgeInsets.only(
                      left: 12.0,
                      right: 8.0,
                    ), // Icon padding
                    child: ShaderMask(
                      shaderCallback: (bounds) => const LinearGradient(
                        colors: [Color(0xFF404040), Colors.black],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ).createShader(bounds),
                      child: Icon(widget.icon, color: Colors.black87, size: 24),
                    ),
                  ),
                  prefixIconConstraints: const BoxConstraints(
                    minWidth: 40,
                    minHeight: 24,
                  ), // Fix Icon size
                  hintText: widget.hintText,
                  hintStyle: GoogleFonts.comicNeue(
                    color: Colors.black45,
                    fontWeight: FontWeight.w600,
                  ),
                  border: InputBorder.none,
                  contentPadding:
                      EdgeInsets.zero, // Padding Zero (Sabse zaroori)
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// --- SNAKE PAINTER ---
class _TextFieldSnakePainter extends CustomPainter {
  final double animationValue;
  final Color color;

  _TextFieldSnakePainter({required this.animationValue, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final rRect = RRect.fromRectAndRadius(rect, const Radius.circular(14));

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..shader = SweepGradient(
        colors: [Colors.transparent, color, Colors.transparent],
        stops: const [0.0, 0.5, 1.0],
        transform: GradientRotation(animationValue * 6.28319),
      ).createShader(rect);

    canvas.drawRRect(rRect, paint);
  }

  @override
  bool shouldRepaint(covariant _TextFieldSnakePainter oldDelegate) => true;
}
