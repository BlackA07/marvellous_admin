// lib/features/coupons/screens/widgets/coupon_preview_card.dart
//
// The ticket-shaped coupon card. It is both the editor's live preview and the
// card on the list screen. Colours and font come from the coupon's own design,
// so what the admin sees here is what the client app renders.

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../models/coupon_model.dart';

class CouponPreviewCard extends StatelessWidget {
  final CouponModel coupon;

  /// Slightly tighter layout for the list screen.
  final bool compact;

  const CouponPreviewCard({
    super.key,
    required this.coupon,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final bg = coupon.backgroundColor;
    final accent = coupon.accentColor;
    final text = coupon.textColor;

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: accent.withValues(alpha: 0.45)),
        ),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _LeftStub(coupon: coupon, compact: compact),
              _TicketNotchDivider(accent: accent, background: bg),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    14,
                    compact ? 12 : 16,
                    14,
                    compact ? 12 : 16,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Headline — "20% OFF", "FREE DELIVERY", etc.
                      Text(
                        coupon.headline,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: coupon.textStyle(
                          size: compact ? 17 : 21,
                          weight: FontWeight.w900,
                        ),
                      ),
                      if (coupon.title.trim().isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          coupon.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: coupon.textStyle(
                            size: compact ? 12.5 : 14,
                            weight: FontWeight.w700,
                            color: text.withValues(alpha: 0.92),
                          ),
                        ),
                      ],
                      if (!compact &&
                          coupon.description.trim().isNotEmpty) ...[
                        const SizedBox(height: 5),
                        Text(
                          coupon.description,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: coupon.textStyle(
                            size: 11.5,
                            weight: FontWeight.w400,
                            color: text.withValues(alpha: 0.72),
                            height: 1.3,
                          ),
                        ),
                      ],
                      const SizedBox(height: 9),
                      _MetaLine(
                        icon: Icons.rule_rounded,
                        text: coupon.conditionSummary,
                        color: text.withValues(alpha: 0.72),
                      ),
                      const SizedBox(height: 4),
                      _MetaLine(
                        icon: Icons.schedule_rounded,
                        text:
                            '${_fmt(coupon.startAt)}  →  ${_fmt(coupon.endAt)}',
                        color: text.withValues(alpha: 0.72),
                      ),
                      if (!compact && coupon.minPurchaseAmount > 0) ...[
                        const SizedBox(height: 4),
                        _MetaLine(
                          icon: Icons.shopping_bag_outlined,
                          text:
                              'Orders of PKR ${_money(coupon.minPurchaseAmount)}+ '
                              '(any currency)',
                          color: accent,
                        ),
                      ],
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

  static String _fmt(DateTime d) => DateFormat('dd MMM yy, h:mm a').format(d);

  static String _money(double v) => v == v.roundToDouble()
      ? NumberFormat('#,##0').format(v)
      : NumberFormat('#,##0.00').format(v);
}

/// Left half of the card: icon, code and badge.
class _LeftStub extends StatelessWidget {
  final CouponModel coupon;
  final bool compact;
  const _LeftStub({required this.coupon, required this.compact});

  @override
  Widget build(BuildContext context) {
    final accent = coupon.accentColor;
    return Container(
      width: compact ? 96 : 112,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
      color: accent.withValues(alpha: 0.10),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(coupon.type.icon, size: compact ? 22 : 26, color: accent),
          const SizedBox(height: 8),
          // Code, in a cut-out style box
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 5),
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(7),
              border: Border.all(color: accent.withValues(alpha: 0.55)),
            ),
            child: Text(
              coupon.code,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: coupon.textStyle(
                size: compact ? 10.5 : 12,
                weight: FontWeight.w900,
                color: accent,
              ),
            ),
          ),
          if (coupon.badgeText.trim().isNotEmpty) ...[
            const SizedBox(height: 7),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
              decoration: BoxDecoration(
                color: accent,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                coupon.badgeText.toUpperCase(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 8.5,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.4,
                  color: _readableOn(accent),
                ),
              ),
            ),
          ],
          if (coupon.autoApply) ...[
            const SizedBox(height: 6),
            Text(
              'AUTO APPLY',
              style: coupon.textStyle(
                size: 8,
                weight: FontWeight.w800,
                color: coupon.textColor.withValues(alpha: 0.55),
              ),
            ),
          ],
        ],
      ),
    );
  }

  static Color _readableOn(Color background) =>
      background.computeLuminance() > 0.55 ? Colors.black : Colors.white;
}

/// The dashed cut plus the two notches that make it look like a ticket.
class _TicketNotchDivider extends StatelessWidget {
  final Color accent;
  final Color background;
  const _TicketNotchDivider({required this.accent, required this.background});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 14,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Dashed line drawn with Positioned.fill + CustomPaint so that
          // IntrinsicHeight never tries to measure this child.
          Positioned.fill(
            child: CustomPaint(
              painter: _DashedLinePainter(accent.withValues(alpha: 0.45)),
            ),
          ),
          // Notches
          Align(
            alignment: Alignment.topCenter,
            child: Transform.translate(
              offset: const Offset(0, -7),
              child: _notch(),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Transform.translate(
              offset: const Offset(0, 7),
              child: _notch(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _notch() => Container(
    width: 14,
    height: 14,
    decoration: BoxDecoration(
      color: background,
      shape: BoxShape.circle,
      border: Border.all(color: accent.withValues(alpha: 0.45)),
    ),
  );
}

class _DashedLinePainter extends CustomPainter {
  final Color color;
  const _DashedLinePainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.round;
    const dash = 4.0;
    const gap = 4.0;
    final x = size.width / 2;
    for (double y = 2; y < size.height - 2; y += dash + gap) {
      final end = (y + dash).clamp(0.0, size.height - 2);
      canvas.drawLine(Offset(x, y), Offset(x, end), paint);
    }
  }

  @override
  bool shouldRepaint(_DashedLinePainter oldDelegate) =>
      oldDelegate.color != color;
}

class _MetaLine extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;
  const _MetaLine({
    required this.icon,
    required this.text,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 12, color: color),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 10.5, color: color, height: 1.3),
          ),
        ),
      ],
    );
  }
}
