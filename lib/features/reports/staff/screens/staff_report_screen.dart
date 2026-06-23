// lib/features/reports/staff/screens/staff_report_screen.dart
//
// Staff Report — main screen.
// Shows: summary cards, employment/designation/region filter chips,
// search+date+sort bar, scrollable data table with toggleable columns,
// export bottom sheet (PDF/CSV/Print/Share).

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../shared/models/report_filter_model.dart';
import '../../shared/widgets/report_filter_bar.dart';
import '../../shared/widgets/report_data_table.dart';
import '../../shared/widgets/report_summary_cards.dart';
import '../../shared/widgets/report_export_sheet.dart';
import '../../shared/widgets/column_selector_widget.dart';
import '../controller/staff_report_controller.dart';

class StaffReportScreen extends StatelessWidget {
  const StaffReportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(StaffReportController());

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.white,
        title: Text(
          'Staff Report',
          style: GoogleFonts.nunito(
            fontWeight: FontWeight.w800,
            color: const Color(0xFF1E293B),
            fontSize: 18,
          ),
        ),
        iconTheme: const IconThemeData(color: Color(0xFF1E293B)),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: controller.refresh,
            icon: const Icon(Icons.refresh),
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(
            child: CircularProgressIndicator(color: Color(0xFF2563EB)),
          );
        }

        if (controller.errorMessage.value.isNotEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.error_outline,
                    color: Colors.redAccent,
                    size: 48,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    controller.errorMessage.value,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.nunito(color: const Color(0xFF64748B)),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: controller.refresh,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          );
        }

        return Column(
          children: [
            const SizedBox(height: 14),

            // ── Summary cards ──
            ReportSummaryCards(stats: controller.summaryStats),
            const SizedBox(height: 14),

            // ── Employment / designation / region filter chips ──
            _StaffFilters(controller: controller),

            // ── Search / date / sort bar ──
            ReportFilterBar(
              filter: controller.filter.value,
              onFilterChanged: (f) =>
                  controller.updateFilter(f as StaffReportFilter),
              sortOptions: staffSortOptions,
              searchHint:
                  'Search name, father name, CNIC, mobile, designation...',
              totalRecords: controller.filteredStaff.length,
              onColumnsTap: () => _showColumnSelector(context, controller),
            ),

            // ── Data table ──
            Expanded(
              child: Column(
                children: [
                  Expanded(
                    child: Container(
                      margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: ReportDataTable(
                        columns: controller.columns,
                        rows: controller.tableRows,
                        currentSortBy: controller.filter.value.sortBy.isEmpty
                            ? null
                            : controller.filter.value.sortBy,
                        sortDir: controller.filter.value.sortDir,
                        onSort: (col, dir) => controller.updateFilter(
                          controller.filter.value.copyWith(
                            sortBy: col,
                            sortDir: dir,
                          ),
                        ),
                        emptyMessage:
                            'No staff match the selected filters.\nTry adjusting your filters.',
                      ),
                    ),
                  ),
                  // ✅ NAYA HISSA: Full Screen Button
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12.0),
                    child: OutlinedButton.icon(
                      onPressed: () => Get.to(
                        () => StaffReportFullScreen(controller: controller),
                      ),
                      icon: const Icon(
                        Icons.fullscreen,
                        color: Color(0xFF2563EB),
                      ),
                      label: Text(
                        "Open Table in Full Screen",
                        style: GoogleFonts.nunito(
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF2563EB),
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFF2563EB)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      }),
      floatingActionButton: Obx(
        () => FloatingActionButton.extended(
          backgroundColor: const Color(0xFF2563EB),
          onPressed: controller.filteredStaff.isEmpty
              ? null
              : () => ReportExportSheet.show(
                  context,
                  reportTitle: 'Staff Report',
                  columns: controller.columns,
                  rows: controller.tableRows,
                  filter: controller.filter.value,
                  summaryStats: controller.summaryStats,
                ),
          icon: const Icon(Icons.ios_share, color: Colors.white),
          label: Text(
            'Export',
            style: GoogleFonts.nunito(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }

  void _showColumnSelector(BuildContext context, dynamic controller) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
        child: SingleChildScrollView(
          child: ColumnSelectorWidget(
            columns: List<ReportColumn>.from(controller.columns),
            onChanged: (newCols) {
              controller.updateColumns(List<ReportColumn>.from(newCols));
            },
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// EMPLOYMENT / DESIGNATION / REGION FILTER CHIPS ROW
// ─────────────────────────────────────────────
class _StaffFilters extends StatelessWidget {
  final StaffReportController controller;
  const _StaffFilters({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final f = controller.filter.value;
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              // Employment type chips
              ...StaffReportController.employmentTypeOptions.map((type) {
                final isSelected = f.employmentType == type;
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: _TypeChip(
                    label: type == 'all'
                        ? 'All'
                        : type[0].toUpperCase() + type.substring(1),
                    selected: isSelected,
                    onTap: () => controller.updateFilter(
                      f.copyWith(employmentType: type),
                    ),
                  ),
                );
              }),
              const SizedBox(width: 4),
              // Designation dropdown
              _FilterDropdown(
                label: 'Designation',
                value: f.designation,
                options: controller.designationOptions,
                onChanged: (v) =>
                    controller.updateFilter(f.copyWith(designation: v)),
              ),
              const SizedBox(width: 8),
              // Commission region dropdown
              _FilterDropdown(
                label: 'Region',
                value: f.commissionRegion,
                options: controller.commissionRegionOptions,
                onChanged: (v) =>
                    controller.updateFilter(f.copyWith(commissionRegion: v)),
              ),
              const SizedBox(width: 8),
              // Reset button
              if (f.hasActiveFilters)
                GestureDetector(
                  onTap: controller.resetFilters,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF2F2),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFFCA5A5)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.close,
                          size: 14,
                          color: Color(0xFFDC2626),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Reset',
                          style: GoogleFonts.nunito(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFFDC2626),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              const SizedBox(width: 16),
            ],
          ),
        ),
      );
    });
  }
}

// ─────────────────────────────────────────────
// TYPE CHIP (employment type quick-tap filter)
// ─────────────────────────────────────────────
class _TypeChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _TypeChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        height: 38,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF2563EB) : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected ? const Color(0xFF2563EB) : const Color(0xFFE2E8F0),
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.nunito(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: selected ? Colors.white : const Color(0xFF475569),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// REUSABLE FILTER DROPDOWN CHIP
// ─────────────────────────────────────────────
class _FilterDropdown extends StatelessWidget {
  final String label;
  final String value;
  final List<String> options;
  final ValueChanged<String> onChanged;

  const _FilterDropdown({
    required this.label,
    required this.value,
    required this.options,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = value != 'all';
    final safeValue = options.contains(value) ? value : 'all';

    return Container(
      height: 38,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: isActive ? const Color(0xFFEFF6FF) : Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isActive ? const Color(0xFF2563EB) : const Color(0xFFE2E8F0),
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: safeValue,
          isDense: true,
          icon: Icon(
            Icons.arrow_drop_down,
            size: 18,
            color: isActive ? const Color(0xFF2563EB) : const Color(0xFF94A3B8),
          ),
          style: GoogleFonts.nunito(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isActive ? const Color(0xFF2563EB) : const Color(0xFF475569),
          ),
          items: options.map((opt) {
            return DropdownMenuItem(
              value: opt,
              child: Text(opt == 'all' ? 'All $label' : opt),
            );
          }).toList(),
          onChanged: (v) {
            if (v != null) onChanged(v);
          },
        ),
      ),
    );
  }
}

class StaffReportFullScreen extends StatelessWidget {
  final StaffReportController controller;
  const StaffReportFullScreen({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Text(
          "Staff Full Report",
          style: GoogleFonts.nunito(
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.black),
          onPressed: () => Get.back(),
        ),
      ),
      body: Obx(
        () => ReportDataTable(
          columns: controller.columns,
          rows: controller.tableRows,
          currentSortBy: controller.filter.value.sortBy.isEmpty
              ? null
              : controller.filter.value.sortBy,
          sortDir: controller.filter.value.sortDir,
          onSort: (col, dir) => controller.updateFilter(
            controller.filter.value.copyWith(sortBy: col, sortDir: dir),
          ),
          emptyMessage: 'No staff match the selected filters.',
        ),
      ),
    );
  }
}
