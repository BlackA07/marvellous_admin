import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:marvellous_admin/core/theme/pallete.dart';

class TrapezoidButton extends StatefulWidget {
  final VoidCallback onTap;
  final bool hasGlowingAura;
  final double width;
  final double height;
  final String imagePath; // <-- NEW PARAMETER

  const TrapezoidButton({
    super.key,
    required this.onTap,
    this.hasGlowingAura = true,
    this.width = double.infinity,
    this.height = 100,
    this.imagePath = 'assets/images/button.png', // Default image
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
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    )..repeat(reverse: true);
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
              // --- LAYER 1: BASE GLOW ---
              AnimatedBuilder(
                animation: _pulseController,
                builder: (context, child) {
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 50),
                    curve: Curves.easeInOut,
                    width: activeWidth - 40,
                    height: 75,
                    margin: EdgeInsets.only(
                      top: 15.0 + (_isPressed ? 10.0 : 0.0),
                      bottom: 22.0 - (_isPressed ? 10.0 : 0.0),
                      left: 3,
                      right: 3,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        if (widget.hasGlowingAura)
                          BoxShadow(
                            color: Pallete.neonBlue.withOpacity(
                              0.6 + (0.4 * _pulseController.value),
                            ),
                            blurRadius: 15, // Thora zyada glow
                            spreadRadius: 2,
                            offset: const Offset(0, 0),
                          ),
                      ],
                    ),
                  );
                },
              ),

              // --- LAYER 2: IMAGE BUTTON ---
              AnimatedPositioned(
                duration: const Duration(milliseconds: 60),
                curve: Curves.easeInOut,
                top: _isPressed ? 12 : 0,
                bottom: _isPressed ? 0 : 2,
                child: SizedBox(
                  width: activeWidth,
                  height: widget.height,
                  child: Image.asset(
                    widget.imagePath, // <-- Yahan ab dynamic image ayegi
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
