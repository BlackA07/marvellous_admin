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
    _pulseController = AnimationController(
      vsync: this,
      //duration: const Duration(milliseconds: 200),
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

    // Total Height ko tight kar diya
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
              // --- LAYER 1: BASE (Moves with button press) ---
              AnimatedBuilder(
                animation: _pulseController,
                builder: (context, child) {
                  // Container ko AnimatedContainer bana diya taake ye bhi press ho
                  return AnimatedContainer(
                    duration: const Duration(
                      milliseconds: 50,
                    ), // Speed matching button
                    curve: Curves.easeInOut,
                    width: activeWidth - 40,
                    height: 75,

                    // --- POSITION CONTROL & PRESS LOGIC ---
                    margin: EdgeInsets.only(
                      // Jab press ho to top margin barhao (neeche dhakelo)
                      top: 15.0 + (_isPressed ? 10.0 : 0.0),
                      // Bottom margin kam karo taake layout na toote
                      bottom: 22.0 - (_isPressed ? 10.0 : 0.0),
                      left: 3,
                      right: 3,
                    ),

                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(8),
                        topLeft: Radius.circular(8),
                        topRight: Radius.circular(8),
                        bottomRight: Radius.circular(8),
                      ),
                      // color: const Color.fromARGB(255, 87, 86, 86),
                      boxShadow: [
                        // --- EQUAL GLOW ON 4 SIDES ---
                        if (widget.hasGlowingAura)
                          BoxShadow(
                            color: Pallete.neonBlue.withOpacity(
                              0.6 + (0.4 * _pulseController.value),
                            ),
                            offset: const Offset(0, 0),
                          ),
                      ],
                    ),
                  );
                },
              ),

              // --- LAYER 2: IMAGE BUTTON (Press Effect) ---
              AnimatedPositioned(
                duration: const Duration(milliseconds: 60),
                curve: Curves.easeInOut,
                // Jab press ho to image neeche aaye
                top: _isPressed ? 12 : 0,
                bottom: _isPressed ? 0 : 2,
                child: SizedBox(
                  width: activeWidth,
                  height: widget.height,
                  child: Stack(
                    children: [
                      // 1. The Image itself
                      Container(
                        width: activeWidth,
                        height: widget.height,
                        decoration: const BoxDecoration(
                          // Shadows...
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(0),
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
            ],
          ),
        ),
      ),
    );
  }
}
