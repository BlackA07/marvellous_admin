// lib/features/reports/shared/widgets/report_data_table.dart
import 'package:data_table_2/data_table_2.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/report_filter_model.dart';

class ReportDataTable extends StatefulWidget {
  final List<ReportColumn> columns;
  final List<Map<String, dynamic>> rows;
  final String? currentSortBy;
  final SortDirection sortDir;
  final void Function(String col, SortDirection dir)? onSort;
  final void Function(Map<String, dynamic> row)? onRowTap;
  final bool isLoading;
  final String emptyMessage;

  const ReportDataTable({
    super.key,
    required this.columns,
    required this.rows,
    this.currentSortBy,
    this.sortDir = SortDirection.descending,
    this.onSort,
    this.onRowTap,
    this.isLoading = false,
    this.emptyMessage = 'No data found for the selected filters.',
  });

  @override
  State<ReportDataTable> createState() => _ReportDataTableState();
}

class _ReportDataTableState extends State<ReportDataTable> {
  // ✅ FIX: 2 alag controllers banaye hain taake error na aaye
  final ScrollController _topScrollController = ScrollController();
  final ScrollController _tableScrollController = ScrollController();
  bool _isSyncing = false;

  @override
  void initState() {
    super.initState();
    // ✅ Dono ko aapas mein jodh diya
    _topScrollController.addListener(_syncTopToTable);
    _tableScrollController.addListener(_syncTableToTop);
  }

  void _syncTopToTable() {
    if (_isSyncing) return;
    if (_topScrollController.hasClients && _tableScrollController.hasClients) {
      _isSyncing = true;
      _tableScrollController.jumpTo(_topScrollController.position.pixels);
      _isSyncing = false;
    }
  }

  void _syncTableToTop() {
    if (_isSyncing) return;
    if (_topScrollController.hasClients && _tableScrollController.hasClients) {
      _isSyncing = true;
      _topScrollController.jumpTo(_tableScrollController.position.pixels);
      _isSyncing = false;
    }
  }

  @override
  void dispose() {
    _topScrollController.removeListener(_syncTopToTable);
    _tableScrollController.removeListener(_syncTableToTop);
    _topScrollController.dispose();
    _tableScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final visibleCols = widget.columns.where((c) => c.visible).toList();

    if (widget.isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Color(0xFF2563EB), strokeWidth: 2),
            SizedBox(height: 14),
            Text(
              'Loading report data...',
              style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
            ),
          ],
        ),
      );
    }

    if (widget.rows.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox_outlined, size: 52, color: Colors.grey.shade300),
            const SizedBox(height: 12),
            Text(
              widget.emptyMessage,
              style: GoogleFonts.nunito(
                fontSize: 14,
                color: const Color(0xFF94A3B8),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    double tableMinWidth = visibleCols.length * 120.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ════════════════════════════════════════════════════════════════════
        // ✅ TOP SCROLLBAR (Dark aur Moti Line)
        // ════════════════════════════════════════════════════════════════════
        Theme(
          data: Theme.of(context).copyWith(
            scrollbarTheme: ScrollbarThemeData(
              thumbColor: MaterialStateProperty.all(Colors.black87),
              trackColor: MaterialStateProperty.all(Colors.black12),
              thickness: MaterialStateProperty.all(12.0),
              radius: const Radius.circular(8),
              interactive: true,
              crossAxisMargin: 2,
            ),
          ),
          child: RawScrollbar(
            controller: _topScrollController,
            thumbVisibility: true,
            trackVisibility: true,
            thickness: 12.0,
            thumbColor: Colors.black87,
            trackColor: Colors.black12,
            radius: const Radius.circular(8),
            interactive: true,
            child: SingleChildScrollView(
              controller:
                  _topScrollController, // ✅ Top Controller assigned here
              scrollDirection: Axis.horizontal,
              child: SizedBox(width: tableMinWidth + 32, height: 16),
            ),
          ),
        ),

        // ════════════════════════════════════════════════════════════════════
        // ── DATA TABLE ──
        // ════════════════════════════════════════════════════════════════════
        Expanded(
          child: DataTable2(
            horizontalScrollController:
                _tableScrollController, // ✅ Table Controller assigned here
            columnSpacing: 12,
            horizontalMargin: 16,
            minWidth: tableMinWidth,
            headingRowHeight: 44,
            dataRowHeight: 48,
            border: TableBorder(
              horizontalInside: BorderSide(
                color: Colors.grey.shade100,
                width: 1,
              ),
            ),
            headingRowDecoration: const BoxDecoration(color: Color(0xFFF8FAFC)),
            sortColumnIndex: widget.currentSortBy != null
                ? visibleCols.indexWhere((c) => c.key == widget.currentSortBy)
                : null,
            sortAscending: widget.sortDir == SortDirection.ascending,
            columns: visibleCols.map((col) {
              return DataColumn2(
                label: Text(
                  col.label,
                  style: GoogleFonts.nunito(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF475569),
                  ),
                ),
                size: _colSize(col),
                onSort: col.sortable && widget.onSort != null
                    ? (_, ascending) => widget.onSort!(
                        col.key,
                        ascending
                            ? SortDirection.ascending
                            : SortDirection.descending,
                      )
                    : null,
              );
            }).toList(),
            rows: widget.rows.asMap().entries.map((entry) {
              final row = entry.value;
              final isEven = entry.key.isEven;
              return DataRow2(
                color: MaterialStateProperty.all(
                  isEven ? Colors.white : const Color(0xFFFAFAFA),
                ),
                onTap: widget.onRowTap != null
                    ? () => widget.onRowTap!(row)
                    : null,
                cells: visibleCols.map((col) {
                  return DataCell(
                    _CellWidget(value: row[col.key], colKey: col.key),
                  );
                }).toList(),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  ColumnSize _colSize(ReportColumn col) {
    if (col.minWidth >= 160) return ColumnSize.L;
    if (col.minWidth >= 120) return ColumnSize.M;
    return ColumnSize.S;
  }
}

// ─────────────────────────────────────────────
// CELL WIDGET
// ─────────────────────────────────────────────
class _CellWidget extends StatelessWidget {
  final dynamic value;
  final String colKey;

  const _CellWidget({required this.value, required this.colKey});

  @override
  Widget build(BuildContext context) {
    if (value == null || value.toString().isEmpty) {
      // ✅ Null or empty check improved
      return Text(
        '—',
        style: GoogleFonts.nunito(fontSize: 12, color: const Color(0xFFCBD5E1)),
      );
    }

    if (value is bool) {
      return _Badge(
        label: value ? 'Yes' : 'No',
        color: value ? const Color(0xFF16A34A) : const Color(0xFF94A3B8),
        bgColor: value ? const Color(0xFFDCFCE7) : const Color(0xFFF1F5F9),
      );
    }

    if (colKey == 'type' &&
        (value.toString() == 'in' || value.toString() == 'out')) {
      final isIn = value.toString() == 'in';
      return _Badge(
        label: isIn ? 'IN' : 'OUT',
        color: isIn ? const Color(0xFF16A34A) : const Color(0xFFDC2626),
        bgColor: isIn ? const Color(0xFFDCFCE7) : const Color(0xFFFEF2F2),
      );
    }

    if (_isStatusKey(colKey)) {
      return _statusBadge(value.toString());
    }

    if (colKey == 'rank') {
      return _rankBadge(value.toString());
    }
    // ✅ NAYA HISSA: RAM aur Storage (ROM) ke liye bold styling
    if (colKey == 'ram' || colKey == 'storage') {
      String displayValue = value.toString().toUpperCase();
      // Agar N/A hai toh grey dikhaye, warna bold black
      bool isNa = displayValue == 'N/A';
      return Text(
        displayValue,
        style: GoogleFonts.nunito(
          fontSize: 12,
          fontWeight: isNa ? FontWeight.normal : FontWeight.w800,
          color: isNa ? const Color(0xFF94A3B8) : const Color(0xFF1E293B),
        ),
      );
    }

    if (colKey == 'membershipStatus') {
      final isPaid =
          value.toString().toLowerCase() == 'paid' ||
          value.toString().toLowerCase() == 'approved';
      return _Badge(
        label: value.toString().toUpperCase(),
        color: isPaid ? const Color(0xFF16A34A) : const Color(0xFFDC2626),
        bgColor: isPaid ? const Color(0xFFDCFCE7) : const Color(0xFFFEF2F2),
      );
    }

    if (colKey.toLowerCase().endsWith('percent')) {
      final num = _toDouble(value);
      return Text(
        '${num.toStringAsFixed(1)}%',
        style: GoogleFonts.nunito(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: num >= 0 ? const Color(0xFF16A34A) : const Color(0xFFDC2626),
        ),
      );
    }

    if (_isCurrencyKey(colKey)) {
      final num = _toDouble(value);
      return Text(
        'Rs. ${_formatNum(num)}',
        style: GoogleFonts.nunito(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: num > 0 ? const Color(0xFF1E3A5F) : const Color(0xFF94A3B8),
        ),
      );
    }

    if (value is DateTime) {
      return Text(
        _formatDate(value),
        style: GoogleFonts.nunito(fontSize: 12, color: const Color(0xFF475569)),
      );
    }

    return Tooltip(
      message: value.toString(),
      child: Text(
        value.toString(),
        overflow: TextOverflow.ellipsis,
        maxLines: 1,
        style: GoogleFonts.nunito(fontSize: 12, color: const Color(0xFF1E293B)),
      ),
    );
  }

  bool _isStatusKey(String key) =>
      key == 'status' || key == 'vendorStatus' || key == 'mlmActive';

  bool _isCurrencyKey(String key) {
    final k = key.toLowerCase();
    if (k == 'subtotal') return true;
    return k.contains('balance') ||
        k.contains('amount') ||
        k.contains('salary') ||
        k.contains('payable') ||
        k.contains('price') ||
        k.contains('cashback') ||
        k.contains('due') ||
        k.contains('billed') ||
        k.contains('received') ||
        k.contains('revenue') ||
        k.contains('profit') ||
        k.contains('value') ||
        k.contains('fee') ||
        k.contains('charges') ||
        k.endsWith('fix') ||
        k.contains('rate');
  }

  Widget _statusBadge(String status) {
    Color color;
    Color bg;
    switch (status.toLowerCase()) {
      case 'approved':
        color = const Color(0xFF16A34A);
        bg = const Color(0xFFDCFCE7);
        break;
      case 'pending':
        color = const Color(0xFFD97706);
        bg = const Color(0xFFFEF3C7);
        break;
      case 'rejected':
        color = const Color(0xFFDC2626);
        bg = const Color(0xFFFEF2F2);
        break;
      case 'hold':
        color = const Color(0xFF9333EA);
        bg = const Color(0xFFF3E8FF);
        break;
      case 'active':
        color = const Color(0xFF2563EB);
        bg = const Color(0xFFEFF6FF);
        break;
      default:
        color = const Color(0xFF64748B);
        bg = const Color(0xFFF1F5F9);
    }
    return _Badge(label: status.toUpperCase(), color: color, bgColor: bg);
  }

  Widget _rankBadge(String rank) {
    Color color;
    Color bg;
    switch (rank.toLowerCase()) {
      case 'diamond':
        color = const Color(0xFF6D28D9);
        bg = const Color(0xFFEDE9FE);
        break;
      case 'gold':
        color = const Color(0xFFB45309);
        bg = const Color(0xFFFEF3C7);
        break;
      case 'silver':
        color = const Color(0xFF475569);
        bg = const Color(0xFFF1F5F9);
        break;
      default:
        color = const Color(0xFF92400E);
        bg = const Color(0xFFFEF9C3);
        break;
    }
    return _Badge(label: rank, color: color, bgColor: bg);
  }

  double _toDouble(dynamic v) {
    if (v is double) return v;
    if (v is int) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0;
  }

  String _formatNum(double v) {
    if (v >= 1000000) return '${(v / 1000000).toStringAsFixed(1)}M';
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(1)}K';
    return v.toStringAsFixed(0);
  }

  String _formatDate(DateTime dt) {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final Color color;
  final Color bgColor;

  const _Badge({
    required this.label,
    required this.color,
    required this.bgColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        label,
        style: GoogleFonts.nunito(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}
