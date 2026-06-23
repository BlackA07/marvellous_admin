// lib/features/reports/shared/widgets/column_selector_widget.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/report_filter_model.dart';

class ColumnSelectorWidget extends StatefulWidget {
  final List<ReportColumn> columns;
  final ValueChanged<List<ReportColumn>> onChanged;

  const ColumnSelectorWidget({
    super.key,
    required this.columns,
    required this.onChanged,
  });

  @override
  State<ColumnSelectorWidget> createState() => _ColumnSelectorWidgetState();
}

class _ColumnSelectorWidgetState extends State<ColumnSelectorWidget> {
  late List<ReportColumn> _cols;

  @override
  void initState() {
    super.initState();
    _cols = List.from(widget.columns);
  }

  @override
  void didUpdateWidget(ColumnSelectorWidget old) {
    super.didUpdateWidget(old);
    if (old.columns != widget.columns) {
      _cols = List.from(widget.columns);
    }
  }

  void _toggle(int index) {
    final wouldHide = _cols[index].visible;
    final visibleCount = _cols.where((c) => c.visible).length;
    if (wouldHide && visibleCount <= 1) return;

    setState(() {
      _cols[index] = _cols[index].copyWith(visible: !_cols[index].visible);
    });
  }

  void _selectAll() {
    setState(() {
      _cols = _cols.map((c) => c.copyWith(visible: true)).toList();
    });
  }

  void _selectNone() {
    setState(() {
      _cols = _cols.asMap().entries.map((e) {
        return e.value.copyWith(visible: e.key == 0);
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final visibleCount = _cols.where((c) => c.visible).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(
              Icons.view_column_outlined,
              size: 18,
              color: Color(0xFF2563EB),
            ),
            const SizedBox(width: 8),
            Text(
              'Table columns',
              style: GoogleFonts.nunito(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF1E293B),
              ),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFF2563EB).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '$visibleCount / ${_cols.length}',
                style: GoogleFonts.nunito(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF2563EB),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            _ActionChip(label: 'Select all', onTap: _selectAll),
            const SizedBox(width: 8),
            _ActionChip(label: 'Minimum', onTap: _selectNone),
          ],
        ),
        const SizedBox(height: 14),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _cols.asMap().entries.map((entry) {
            final col = entry.value;
            final isVisible = col.visible;
            return GestureDetector(
              onTap: () => _toggle(entry.key),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: isVisible
                      ? const Color(0xFF2563EB)
                      : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isVisible
                        ? const Color(0xFF2563EB)
                        : const Color(0xFFCBD5E1),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isVisible
                          ? Icons.check_circle
                          : Icons.radio_button_unchecked,
                      size: 14,
                      color: isVisible ? Colors.white : const Color(0xFF94A3B8),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      col.label,
                      style: GoogleFonts.nunito(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: isVisible
                            ? Colors.white
                            : const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2563EB),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              elevation: 0,
            ),
            onPressed: () {
              Navigator.pop(context);
              WidgetsBinding.instance.addPostFrameCallback((_) {
                widget.onChanged(_cols);
              });
            },
            icon: const Icon(Icons.check, color: Colors.white, size: 20),
            label: Text(
              "Apply Columns",
              style: GoogleFonts.nunito(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ActionChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _ActionChip({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFCBD5E1)),
        ),
        child: Text(
          label,
          style: GoogleFonts.nunito(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF475569),
          ),
        ),
      ),
    );
  }
}
