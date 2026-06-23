// lib/features/reports/shared/services/report_export_service.dart

import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import 'package:open_filex/open_filex.dart';
import 'package:universal_html/html.dart'
    as html; // ✅ NAYA: Web par download ke liye
import '../models/report_filter_model.dart';

// ─────────────────────────────────────────────
// EXPORT RESULT
// ─────────────────────────────────────────────
class ExportResult {
  final bool success;
  final String? filePath;
  final Uint8List? fileBytes; // ✅ NAYA: Web ke liye bytes lazmi hote hain
  final String? errorMessage;

  const ExportResult({
    required this.success,
    this.filePath,
    this.fileBytes,
    this.errorMessage,
  });
}

// ─────────────────────────────────────────────
// REPORT EXPORT SERVICE
// ─────────────────────────────────────────────
class ReportExportService {
  static final ReportExportService _instance = ReportExportService._();
  factory ReportExportService() => _instance;
  ReportExportService._();

  // ── PDF EXPORT ──────────────────────────────
  Future<ExportResult> exportPdf({
    required String reportTitle,
    required List<ReportColumn> columns,
    required List<Map<String, dynamic>> rows,
    required BaseReportFilter filter,
    Map<String, String>? summaryStats,
  }) async {
    try {
      final visibleColumns = columns.where((c) => c.visible).toList();
      if (visibleColumns.isEmpty) {
        return const ExportResult(
          success: false,
          errorMessage: 'No columns selected.',
        );
      }

      final pdf = pw.Document();
      final dateFormat = DateFormat('dd MMM yyyy');
      final nowStr = DateFormat('dd-MMM-yyyy HH:mm').format(DateTime.now());
      final font = await PdfGoogleFonts.nunitoRegular();
      final fontBold = await PdfGoogleFonts.nunitoBold();

      const headerBg = PdfColor.fromInt(0xFF1E3A5F);
      const headerText = PdfColors.white;
      const rowEven = PdfColor.fromInt(0xFFF8F9FA);
      const rowOdd = PdfColors.white;
      const accentColor = PdfColor.fromInt(0xFF2563EB);
      const borderColor = PdfColor.fromInt(0xFFE2E8F0);
      const summaryBg = PdfColor.fromInt(0xFFEFF6FF);

      final pageWidth = PdfPageFormat.a4.availableWidth - 40;
      final colCount = visibleColumns.length;
      final colWidth = (pageWidth / colCount).clamp(60.0, 180.0);

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4.landscape,
          margin: const pw.EdgeInsets.all(24),
          header: (ctx) => _buildHeader(
            ctx,
            reportTitle: reportTitle,
            dateRange:
                '${dateFormat.format(filter.resolvedStart)} — ${dateFormat.format(filter.resolvedEnd)}',
            generatedAt: nowStr,
            font: font,
            fontBold: fontBold,
            accentColor: accentColor,
          ),
          footer: (ctx) => _buildFooter(ctx, font: font),
          build: (ctx) => [
            if (summaryStats != null && summaryStats.isNotEmpty)
              _buildSummaryRow(
                summaryStats,
                font: font,
                fontBold: fontBold,
                summaryBg: summaryBg,
                accentColor: accentColor,
              ),
            pw.SizedBox(height: 12),
            pw.Align(
              alignment: pw.Alignment.centerLeft,
              child: pw.Container(
                padding: const pw.EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: pw.BoxDecoration(
                  color: accentColor,
                  borderRadius: pw.BorderRadius.circular(4),
                ),
                child: pw.Text(
                  'Total records: ${rows.length}',
                  style: pw.TextStyle(
                    font: fontBold,
                    fontSize: 9,
                    color: PdfColors.white,
                  ),
                ),
              ),
            ),
            pw.SizedBox(height: 8),
            pw.Table(
              border: pw.TableBorder.all(color: borderColor, width: 0.5),
              columnWidths: {
                for (int i = 0; i < colCount; i++)
                  i: pw.FixedColumnWidth(
                    visibleColumns[i].minWidth > colWidth
                        ? visibleColumns[i].minWidth
                        : colWidth,
                  ),
              },
              children: [
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: headerBg),
                  children: visibleColumns
                      .map(
                        (col) => pw.Padding(
                          padding: const pw.EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 6,
                          ),
                          child: pw.Text(
                            col.label,
                            style: pw.TextStyle(
                              font: fontBold,
                              fontSize: 8,
                              color: headerText,
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
                ...rows.asMap().entries.map((entry) {
                  final isEven = entry.key.isEven;
                  final row = entry.value;
                  return pw.TableRow(
                    decoration: pw.BoxDecoration(
                      color: isEven ? rowEven : rowOdd,
                    ),
                    children: visibleColumns.map((col) {
                      return pw.Padding(
                        padding: const pw.EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 5,
                        ),
                        child: pw.Text(
                          _formatCellValue(row[col.key]),
                          style: pw.TextStyle(font: font, fontSize: 8),
                        ),
                      );
                    }).toList(),
                  );
                }),
              ],
            ),
          ],
        ),
      );

      final bytes = await pdf.save();
      final fileName =
          '${_sanitizeFileName(reportTitle)}_${DateFormat('yyyyMMdd_HHmm').format(DateTime.now())}.pdf';

      // ✅ FIX: Mobile par local file system mein save, aur Web par download
      String? filePath;
      if (!kIsWeb) {
        filePath = await _saveFileToMobile(bytes: bytes, fileName: fileName);
      } else {
        _downloadFileWeb(bytes: bytes, fileName: fileName);
      }

      return ExportResult(success: true, filePath: filePath, fileBytes: bytes);
    } catch (e) {
      return ExportResult(success: false, errorMessage: e.toString());
    }
  }

  // ── CSV EXPORT ──────────────────────────────
  Future<ExportResult> exportCsv({
    required String reportTitle,
    required List<ReportColumn> columns,
    required List<Map<String, dynamic>> rows,
  }) async {
    try {
      final visibleColumns = columns.where((c) => c.visible).toList();
      if (visibleColumns.isEmpty) {
        return const ExportResult(
          success: false,
          errorMessage: 'No columns selected.',
        );
      }

      final buffer = StringBuffer();
      buffer.writeln(visibleColumns.map((c) => _csvEscape(c.label)).join(','));

      for (final row in rows) {
        buffer.writeln(
          visibleColumns
              .map((col) => _csvEscape(_formatCellValue(row[col.key])))
              .join(','),
        );
      }

      final bytes = Uint8List.fromList(buffer.toString().codeUnits);
      final fileName =
          '${_sanitizeFileName(reportTitle)}_${DateFormat('yyyyMMdd_HHmm').format(DateTime.now())}.csv';

      String? filePath;
      if (!kIsWeb) {
        filePath = await _saveFileToMobile(bytes: bytes, fileName: fileName);
      } else {
        _downloadFileWeb(bytes: bytes, fileName: fileName);
      }

      return ExportResult(success: true, filePath: filePath, fileBytes: bytes);
    } catch (e) {
      return ExportResult(success: false, errorMessage: e.toString());
    }
  }

  // ── PRINT ───────────────────────────────────
  Future<void> printReport({
    required String reportTitle,
    required List<ReportColumn> columns,
    required List<Map<String, dynamic>> rows,
    required BaseReportFilter filter,
    Map<String, String>? summaryStats,
  }) async {
    final result = await exportPdf(
      reportTitle: reportTitle,
      columns: columns,
      rows: rows,
      filter: filter,
      summaryStats: summaryStats,
    );
    if (result.success && result.fileBytes != null) {
      // ✅ FIX: Mobile/Web dono pe Print kaam karega bytes use karne se
      await Printing.layoutPdf(onLayout: (_) async => result.fileBytes!);
    }
  }

  // ── SHARE ───────────────────────────────────
  Future<void> shareFile(
    String filePath,
    Uint8List? fileBytes,
    String fileName,
  ) async {
    // ✅ FIX: Web par Share button supported nahi hota natively isliye download hoga. Mobile par share option khulega.
    if (kIsWeb && fileBytes != null) {
      _downloadFileWeb(bytes: fileBytes, fileName: fileName);
    } else {
      await Share.shareXFiles([XFile(filePath)]);
    }
  }

  // ── OPEN ────────────────────────────────────
  Future<void> openFile(String filePath) async {
    if (!kIsWeb) {
      await OpenFilex.open(filePath);
    }
  }

  // ─────────────────────────────────────────────
  // PRIVATE HELPERS
  // ─────────────────────────────────────────────

  // ... (baki _buildHeader, _buildFooter, _buildSummaryRow wese hi rahenge jese thay)
  pw.Widget _buildHeader(
    pw.Context ctx, {
    required String reportTitle,
    required String dateRange,
    required String generatedAt,
    required pw.Font font,
    required pw.Font fontBold,
    required PdfColor accentColor,
  }) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'Marvellous Admin',
                  style: pw.TextStyle(
                    font: fontBold,
                    fontSize: 10,
                    color: accentColor,
                  ),
                ),
                pw.SizedBox(height: 2),
                pw.Text(
                  reportTitle,
                  style: pw.TextStyle(font: fontBold, fontSize: 16),
                ),
              ],
            ),
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                pw.Text(
                  'Period: $dateRange',
                  style: pw.TextStyle(font: font, fontSize: 9),
                ),
                pw.Text(
                  'Generated: $generatedAt',
                  style: pw.TextStyle(
                    font: font,
                    fontSize: 8,
                    color: PdfColors.grey600,
                  ),
                ),
              ],
            ),
          ],
        ),
        pw.SizedBox(height: 6),
        pw.Divider(color: accentColor, thickness: 1.5),
        pw.SizedBox(height: 4),
      ],
    );
  }

  pw.Widget _buildFooter(pw.Context ctx, {required pw.Font font}) {
    return pw.Column(
      children: [
        pw.Divider(color: PdfColors.grey300, thickness: 0.5),
        pw.SizedBox(height: 4),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              'Marvellous Admin — Confidential',
              style: pw.TextStyle(
                font: font,
                fontSize: 7,
                color: PdfColors.grey500,
              ),
            ),
            pw.Text(
              'Page ${ctx.pageNumber} of ${ctx.pagesCount}',
              style: pw.TextStyle(
                font: font,
                fontSize: 7,
                color: PdfColors.grey500,
              ),
            ),
          ],
        ),
      ],
    );
  }

  pw.Widget _buildSummaryRow(
    Map<String, String> stats, {
    required pw.Font font,
    required pw.Font fontBold,
    required PdfColor summaryBg,
    required PdfColor accentColor,
  }) {
    return pw.Wrap(
      spacing: 8,
      runSpacing: 8,
      children: stats.entries.map((e) {
        return pw.Container(
          padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: pw.BoxDecoration(
            color: summaryBg,
            borderRadius: pw.BorderRadius.circular(6),
            border: pw.Border.all(color: accentColor, width: 0.5),
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                e.key,
                style: pw.TextStyle(
                  font: font,
                  fontSize: 7,
                  color: PdfColors.grey600,
                ),
              ),
              pw.SizedBox(height: 2),
              pw.Text(
                e.value,
                style: pw.TextStyle(font: fontBold, fontSize: 11),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  String _formatCellValue(dynamic val) {
    if (val == null) return '—';
    if (val is bool) return val ? 'Yes' : 'No';
    if (val is double) {
      if (val == val.truncateToDouble()) return val.toStringAsFixed(0);
      return val.toStringAsFixed(2);
    }
    if (val is DateTime) return DateFormat('dd MMM yyyy').format(val);
    return val.toString();
  }

  String _csvEscape(String value) {
    if (value.contains(',') || value.contains('"') || value.contains('\n')) {
      return '"${value.replaceAll('"', '""')}"';
    }
    return value;
  }

  String _sanitizeFileName(String name) {
    return name
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9_]'), '_')
        .replaceAll(RegExp(r'_+'), '_');
  }

  // ── MOBILE SAVE ──
  Future<String> _saveFileToMobile({
    required Uint8List bytes,
    required String fileName,
  }) async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/$fileName');
    await file.writeAsBytes(bytes);
    return file.path;
  }

  // ── WEB DOWNLOAD ──
  void _downloadFileWeb({required Uint8List bytes, required String fileName}) {
    final blob = html.Blob([bytes]);
    final url = html.Url.createObjectUrlFromBlob(blob);
    final anchor = html.AnchorElement(href: url)
      ..setAttribute("download", fileName)
      ..click();
    html.Url.revokeObjectUrl(url);
  }
}
