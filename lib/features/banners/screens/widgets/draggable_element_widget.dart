import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/banner_element_model.dart';

class DraggableElementWidget extends StatefulWidget {
  final BannerElementModel element;
  final Size canvasSize;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onDoubleTap;
  final VoidCallback onDragStart;
  final void Function(double dx, double dy) onDragEnd;

  const DraggableElementWidget({
    super.key,
    required this.element,
    required this.canvasSize,
    required this.isSelected,
    required this.onTap,
    required this.onDoubleTap,
    required this.onDragStart,
    required this.onDragEnd,
  });

  @override
  State<DraggableElementWidget> createState() => _DraggableElementWidgetState();
}

class _DraggableElementWidgetState extends State<DraggableElementWidget> {
  // local-only offset while a drag is in progress — keeps dragging smooth
  // (only this one widget rebuilds), position is only committed to the
  // controller once the finger/mouse lifts.
  Offset _dragDelta = Offset.zero;

  Color _colorFromHex(String hex) {
    if (hex == 'transparent') return Colors.transparent;
    final cleaned = hex.replaceAll('#', '');
    return Color(int.parse('FF$cleaned', radix: 16));
  }

  TextStyle _textStyle() {
    final base = TextStyle(
      fontSize: widget.element.fontSize,
      fontWeight: widget.element.isBold ? FontWeight.bold : FontWeight.normal,
      color: _colorFromHex(widget.element.colorHex),
    );
    if (widget.element.fontFamily == 'Default') return base;
    try {
      return GoogleFonts.getFont(widget.element.fontFamily, textStyle: base);
    } catch (_) {
      return base; // falls back safely if a font name isn't available
    }
  }

  @override
  Widget build(BuildContext context) {
    final baseLeft = widget.element.dx * widget.canvasSize.width;
    final baseTop = widget.element.dy * widget.canvasSize.height;
    final left = baseLeft + _dragDelta.dx;
    final top = baseTop + _dragDelta.dy;

    return Positioned(
      left: left,
      top: top,
      child: GestureDetector(
        onTap: widget.onTap,
        onDoubleTap: widget.onDoubleTap,
        onPanStart: (_) {
          widget.onDragStart();
        },
        onPanUpdate: (details) {
          setState(() => _dragDelta += details.delta);
        },
        onPanEnd: (_) {
          if (widget.canvasSize.width == 0 || widget.canvasSize.height == 0)
            return;
          final newDx = (baseLeft + _dragDelta.dx) / widget.canvasSize.width;
          final newDy = (baseTop + _dragDelta.dy) / widget.canvasSize.height;
          widget.onDragEnd(newDx, newDy);
          setState(() => _dragDelta = Offset.zero);
        },
        child: Transform.rotate(
          angle: widget.element.rotation * 3.1415926535 / 180,
          child: Container(
            decoration: widget.isSelected
                ? BoxDecoration(
                    border: Border.all(color: Colors.blueAccent, width: 1.5),
                  )
                : null,
            padding: widget.isSelected
                ? const EdgeInsets.all(2)
                : EdgeInsets.zero,
            child: _buildContent(),
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    switch (widget.element.type) {
      case BannerElementType.title:
      case BannerElementType.subtitle:
      case BannerElementType.message:
        return Text(widget.element.content, style: _textStyle());
      case BannerElementType.button:
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          decoration: BoxDecoration(
            color: widget.element.buttonBgColorHex != null
                ? _colorFromHex(widget.element.buttonBgColorHex!)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(
              widget.element.buttonBorderRadius,
            ),
            border: Border.all(
              color: widget.element.buttonBorderColorHex != null
                  ? _colorFromHex(widget.element.buttonBorderColorHex!)
                  : Colors.white,
              width: widget.element.buttonBorderWidth,
            ),
          ),
          child: Text(
            widget.element.content,
            style: _textStyle().copyWith(letterSpacing: 1),
          ),
        );
      case BannerElementType.image:
        final width = widget.element.widthFraction * widget.canvasSize.width;
        final height = widget.element.heightFraction * widget.canvasSize.height;
        return SizedBox(
          width: width,
          height: height,
          child: widget.element.content.isEmpty
              ? Container(color: Colors.black12, child: const Icon(Icons.image))
              : Image.network(widget.element.content, fit: BoxFit.contain),
        );
    }
  }
}
