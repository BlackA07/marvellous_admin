import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/pallete.dart';

class MetallicButton extends StatefulWidget {
  final String text;
  final VoidCallback onTap;
  final bool hasGlowingAura;
  final double width;
  final double height;
  final bool isSelected;

  // --- NEW OPTIONS ---
  final List<Color>? customGradientColors; // Apni marzi ka gradient
  final Color? textColor; // Apni marzi ka text color

  const MetallicButton({
    super.key,
    required this.text,
    required this.onTap,
    this.hasGlowingAura = false,
    this.width = double.infinity,
    this.height = 65,
    this.isSelected = true,
    this.customGradientColors,
    this.textColor,
  });

  @override
  State<MetallicButton> createState() => _MetallicButtonState();
}

class _MetallicButtonState extends State<MetallicButton>
    with SingleTickerProviderStateMixin {
  bool _isPressed = false;
  late AnimationController _snakeController;

  @override
  void initState() {
    super.initState();
    _snakeController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _snakeController.dispose();
    super.dispose();
  }

  void _handleTap() async {
    if (!widget.isSelected) {
      widget.onTap();
      return;
    }

    setState(() => _isPressed = true);
    HapticFeedback.lightImpact();

    await Future.delayed(const Duration(milliseconds: 100));
    if (mounted) {
      setState(() => _isPressed = false);
      widget.onTap();
    }
  }

  @override
  Widget build(BuildContext context) {
    // --- FIX: LOGIC FOR GRADIENT STOPS ---
    // Agar custom colors hain, to stops null rakho (taake crash na ho),
    // Agar default colors hain, to unke hisaab se stops lagao.

    Gradient faceGradient;

    if (!widget.isSelected) {
      faceGradient = const LinearGradient(
        colors: [Color(0xFF404040), Color(0xFF202020)],
      );
    } else if (widget.customGradientColors != null) {
      // Custom Colors provided (No fixed stops to avoid length mismatch error)
      faceGradient = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: widget.customGradientColors!,
      );
    } else {
      // Default Silver Theme (Fixed stops match the 4 colors)
      faceGradient = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.white, // Highlight
          Color(0xFFD0D5DD), // Light Silver
          Color(0xFF98A2B3), // Darker Silver
          Color(0xFF667085), // Shadow Base
        ],
        stops: [0.0, 0.4, 0.8, 1.0],
      );
    }

    return SizedBox(
      height: widget.height,
      width: widget.width,
      child: GestureDetector(
        onTapDown: (_) {
          if (widget.isSelected) setState(() => _isPressed = true);
        },
        onTapUp: (_) => _handleTap(),
        onTapCancel: () => setState(() => _isPressed = false),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Layer 1: Silver Base
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

            // Layer 2: Snake Light
            if (widget.hasGlowingAura)
              Padding(
                padding: const EdgeInsets.all(3.0),
                child: AnimatedBuilder(
                  animation: _snakeController,
                  builder: (context, child) {
                    return CustomPaint(
                      painter: _SnakeBorderPainter(
                        animationValue: _snakeController.value,
                        color: Pallete.neonBlue,
                      ),
                      child: Container(),
                    );
                  },
                ),
              ),

            // Layer 3: Dark Housing
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

            // Layer 4: Face
            AnimatedContainer(
              duration: const Duration(milliseconds: 60),
              curve: Curves.easeInOut,
              margin: EdgeInsets.only(
                top: _isPressed ? 12 : 6,
                bottom: _isPressed ? 6 : 12,
                left: 6,
                right: 6,
              ),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                gradient: faceGradient,
                boxShadow: _isPressed
                    ? []
                    : [
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
              alignment: Alignment.center,
              child: Text(
                widget.text.toUpperCase(),
                style: GoogleFonts.comicNeue(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  // Agar custom color diya he to wo use karo
                  color:
                      widget.textColor ??
                      (_isPressed ? Pallete.neonBlue : Colors.black87),
                  letterSpacing: 1.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SnakeBorderPainter extends CustomPainter {
  final double animationValue;
  final Color color;
  _SnakeBorderPainter({required this.animationValue, required this.color});

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
  bool shouldRepaint(covariant _SnakeBorderPainter oldDelegate) => true;
}
