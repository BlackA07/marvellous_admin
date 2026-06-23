// lib/features/reports/shared/widgets/report_export_sheet.dart
import 'dart:typed_data'; // ✅ NAYA
import 'package:flutter/foundation.dart'; // ✅ NAYA
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/report_filter_model.dart';
import '../services/report_export_service.dart';

class ReportExportSheet extends StatefulWidget {
  final String reportTitle;
  final List<ReportColumn> columns;
  final List<Map<String, dynamic>> rows;
  final BaseReportFilter filter;
  final Map<String, String>? summaryStats;

  const ReportExportSheet({
    super.key,
    required this.reportTitle,
    required this.columns,
    required this.rows,
    required this.filter,
    this.summaryStats,
  });

  static Future<void> show(
    BuildContext context, {
    required String reportTitle,
    required List<ReportColumn> columns,
    required List<Map<String, dynamic>> rows,
    required BaseReportFilter filter,
    Map<String, String>? summaryStats,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ReportExportSheet(
        reportTitle: reportTitle,
        columns: columns,
        rows: rows,
        filter: filter,
        summaryStats: summaryStats,
      ),
    );
  }

  @override
  State<ReportExportSheet> createState() => _ReportExportSheetState();
}

class _ReportExportSheetState extends State<ReportExportSheet> {
  final _service = ReportExportService();
  bool _isWorking = false;
  String? _lastFilePath;
  Uint8List? _lastFileBytes; // ✅ NAYA: For web share
  String? _statusMessage;
  bool _isError = false;

  void _setStatus(String msg, {bool error = false}) {
    setState(() {
      _statusMessage = msg;
      _isError = error;
    });
  }

  Future<void> _exportPdf() async {
    setState(() => _isWorking = true);
    _setStatus('Generating PDF...');
    final result = await _service.exportPdf(
      reportTitle: widget.reportTitle,
      columns: widget.columns,
      rows: widget.rows,
      filter: widget.filter,
      summaryStats: widget.summaryStats,
    );
    setState(() {
      _isWorking = false;
      _lastFilePath = result.filePath;
      _lastFileBytes = result.fileBytes; // ✅ NAYA
    });
    if (result.success) {
      _setStatus(kIsWeb ? 'PDF Downloaded!' : 'PDF saved successfully!');
    } else {
      _setStatus(result.errorMessage ?? 'Export failed.', error: true);
    }
  }

  Future<void> _exportCsv() async {
    setState(() => _isWorking = true);
    _setStatus('Generating CSV...');
    final result = await _service.exportCsv(
      reportTitle: widget.reportTitle,
      columns: widget.columns,
      rows: widget.rows,
    );
    setState(() {
      _isWorking = false;
      _lastFilePath = result.filePath;
      _lastFileBytes = result.fileBytes; // ✅ NAYA
    });
    if (result.success) {
      _setStatus(kIsWeb ? 'CSV Downloaded!' : 'CSV saved successfully!');
    } else {
      _setStatus(result.errorMessage ?? 'Export failed.', error: true);
    }
  }

  Future<void> _print() async {
    setState(() => _isWorking = true);
    _setStatus('Preparing print...');
    await _service.printReport(
      reportTitle: widget.reportTitle,
      columns: widget.columns,
      rows: widget.rows,
      filter: widget.filter,
      summaryStats: widget.summaryStats,
    );
    setState(() => _isWorking = false);
    _setStatus('');
  }

  Future<void> _share() async {
    if (_lastFilePath == null && _lastFileBytes == null) {
      await _exportPdf();
    }
    if (_lastFilePath != null || _lastFileBytes != null) {
      await _service.shareFile(
        _lastFilePath ?? '',
        _lastFileBytes,
        "${widget.reportTitle}.pdf",
      );
    }
  }

  Future<void> _open() async {
    if (_lastFilePath == null || kIsWeb)
      return; // ✅ Web par Open file nahi chalti direct download hota hai
    await _service.openFile(_lastFilePath!);
  }

  @override
  Widget build(BuildContext context) {
    final visibleCount = widget.columns.where((c) => c.visible).length;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 30),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFE2E8F0),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),

          Text(
            'Export report',
            style: GoogleFonts.nunito(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 4),

          Text(
            '${widget.reportTitle}  ·  ${widget.rows.length} records  ·  $visibleCount columns',
            style: GoogleFonts.nunito(
              fontSize: 12,
              color: const Color(0xFF94A3B8),
            ),
          ),
          const SizedBox(height: 20),

          if (_isWorking)
            const Padding(
              padding: EdgeInsets.only(bottom: 16),
              child: LinearProgressIndicator(
                color: Color(0xFF2563EB),
                backgroundColor: Color(0xFFEFF6FF),
              ),
            ),

          if (_statusMessage != null && _statusMessage!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Row(
                children: [
                  Icon(
                    _isError ? Icons.error_outline : Icons.check_circle_outline,
                    size: 16,
                    color: _isError
                        ? const Color(0xFFDC2626)
                        : const Color(0xFF16A34A),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _statusMessage!,
                    style: GoogleFonts.nunito(
                      fontSize: 13,
                      color: _isError
                          ? const Color(0xFFDC2626)
                          : const Color(0xFF16A34A),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),

          Row(
            children: [
              Expanded(
                child: _ExportBtn(
                  icon: Icons.picture_as_pdf_outlined,
                  label: kIsWeb ? 'Download PDF' : 'PDF', // ✅ FIX
                  subtitle: 'Formatted report',
                  color: const Color(0xFFDC2626),
                  bgColor: const Color(0xFFFEF2F2),
                  onTap: _isWorking ? null : _exportPdf,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _ExportBtn(
                  icon: Icons.table_chart_outlined,
                  label: kIsWeb ? 'Download CSV' : 'CSV', // ✅ FIX
                  subtitle: 'Excel / Sheets',
                  color: const Color(0xFF16A34A),
                  bgColor: const Color(0xFFDCFCE7),
                  onTap: _isWorking ? null : _exportCsv,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _ExportBtn(
                  icon: Icons.print_outlined,
                  label: 'Print',
                  subtitle: 'System print',
                  color: const Color(0xFF2563EB),
                  bgColor: const Color(0xFFEFF6FF),
                  onTap: _isWorking ? null : _print,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _ExportBtn(
                  icon: Icons.share_outlined,
                  label: 'Share',
                  subtitle: (_lastFilePath != null || _lastFileBytes != null)
                      ? 'File ready'
                      : 'Creates PDF',
                  color: const Color(0xFF7C3AED),
                  bgColor: const Color(0xFFF3E8FF),
                  onTap: _isWorking ? null : _share,
                ),
              ),
            ],
          ),

          // Open file button is hidden for web because web downloads directly
          if (_lastFilePath != null && !kIsWeb) ...[
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _open,
                icon: const Icon(Icons.open_in_new, size: 16),
                label: Text(
                  'Open file',
                  style: GoogleFonts.nunito(fontWeight: FontWeight.w700),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF2563EB),
                  side: const BorderSide(color: Color(0xFF2563EB)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ... _ExportBtn widget wese hi rahega.
class _ExportBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final Color color;
  final Color bgColor;
  final VoidCallback? onTap;

  const _ExportBtn({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.color,
    required this.bgColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final disabled = onTap == null;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedOpacity(
        opacity: disabled ? 0.5 : 1,
        duration: const Duration(milliseconds: 150),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withOpacity(0.25)),
          ),
          child: Row(
            children: [
              Icon(icon, color: color, size: 22),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: GoogleFonts.nunito(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: color,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: GoogleFonts.nunito(
                      fontSize: 11,
                      color: color.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
