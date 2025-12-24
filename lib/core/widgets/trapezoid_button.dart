import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/pallete.dart';

class TrapezoidButton extends StatefulWidget {
  final VoidCallback onTap;
  final bool hasGlowingAura;
  final double width;
  final double height;

  const TrapezoidButton({
    super.key,
    required this.onTap,
    this.hasGlowingAura = true,
    this.width = double.infinity,
    this.height = 100,
  });

  @override
  State<TrapezoidButton> createState() => _TrapezoidButtonState();
}

class _TrapezoidButtonState extends State<TrapezoidButton>
    with SingleTickerProviderStateMixin {
  bool _isPressed = false;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    // --- NEON PULSE ANIMATION ---
    // Ye controller light ko chamkane (pulse) ke liye hai
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500), // 1.5 seconds speed
    )..repeat(reverse: true); // Loop mein chalega (bright -> dim -> bright)
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _handleTap() async {
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
    final double activeWidth = widget.width == double.infinity
        ? 300
        : widget.width;

    // Total height slightly barha di taake depth adjust ho sake
    final double totalHeight = widget.height + 6;

    return Center(
      child: SizedBox(
        width: activeWidth,
        height: totalHeight,
        child: GestureDetector(
          onTapDown: (_) => setState(() => _isPressed = true),
          onTapUp: (_) => _handleTap(),
          onTapCancel: () => setState(() => _isPressed = false),
          child: Stack(
            alignment: Alignment.bottomCenter,
            children: [
              // --- LAYER 1: ATTACHED BASE & PULSING NEON ---
              AnimatedBuilder(
                animation: _pulseController,
                builder: (context, child) {
                  return Container(
                    // Width thori kam rakhi hai taake trapezoid shape ke neeche fit ho
                    width: activeWidth - 32,
                    height: 21, // Height adjust ki taake button se jud jaye
                    margin: const EdgeInsets.only(bottom: 0), // Margin hataya
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(12),
                        bottomRight: Radius.circular(12),
                      ),
                      // Dark Metallic Color (Base Thickness)
                      color: const Color(0xFF2C2C2C),
                      boxShadow: [
                        // --- CHAMAKTI HUI NEON LIGHT ---
                        if (widget.hasGlowingAura)
                          BoxShadow(
                            color: Pallete.neonBlue.withOpacity(
                              0.6 + (0.4 * _pulseController.value),
                            ), // Opacity change hogi
                            blurRadius:
                                10 +
                                (15 * _pulseController.value), // Glow phaile ga
                            spreadRadius:
                                1 +
                                (3 * _pulseController.value), // Light bari hogi
                            offset: const Offset(0, 4),
                          ),
                      ],
                    ),
                  );
                },
              ),

              // --- LAYER 2: THE IMAGE BUTTON ---
              AnimatedPositioned(
                duration: const Duration(milliseconds: 60),
                curve: Curves.easeInOut,
                // Movement adjust ki taake gap na aaye
                top: _isPressed ? 6 : 0,
                bottom: _isPressed ? 0 : 6,
                child: Container(
                  width: activeWidth,
                  height: widget.height,
                  decoration: BoxDecoration(
                    // Image ka apna Shadow (Realistic contact shadow)
                    boxShadow: _isPressed
                        ? []
                        : [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.5),
                              blurRadius: 4,
                              offset: const Offset(0, 4),
                            ),
                          ],
                  ),
                  child: Image.asset(
                    'assets/images/button.png',
                    fit: BoxFit.fill,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
