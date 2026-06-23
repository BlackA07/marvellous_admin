// lib/features/reports/vendors/screens/vendor_report_screen.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../shared/models/report_filter_model.dart';
import '../../shared/widgets/report_filter_bar.dart';
import '../../shared/widgets/report_data_table.dart';
import '../../shared/widgets/report_summary_cards.dart';
import '../../shared/widgets/report_export_sheet.dart';
import '../../shared/widgets/column_selector_widget.dart';
import '../controller/vendor_report_controller.dart';

class VendorReportScreen extends StatelessWidget {
  const VendorReportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(VendorReportController());

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.white,
        title: Text(
          'Vendors Report',
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
            onPressed: controller.refreshData, // ✅ FIXED name
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
                    onPressed: controller.refreshData, // ✅ FIXED name
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
            ReportSummaryCards(stats: controller.summaryStats),
            const SizedBox(height: 14),
            _VendorFilters(controller: controller),
            ReportFilterBar(
              filter: controller.filter.value,
              onFilterChanged: (f) =>
                  controller.updateFilter(f as VendorReportFilter),
              sortOptions: vendorSortOptions,
              searchHint:
                  'Search store, owner, email, mobile, contact person...',
              totalRecords: controller.filteredVendors.length,
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
                        emptyMessage: 'No vendors match the selected filters.',
                      ),
                    ),
                  ),
                  // ✅ NAYA HISSA: Full Screen Button
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12.0),
                    child: OutlinedButton.icon(
                      onPressed: () => Get.to(
                        () => VendorReportFullScreen(controller: controller),
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
          onPressed: controller.filteredVendors.isEmpty
              ? null
              : () => ReportExportSheet.show(
                  context,
                  reportTitle: 'Vendors Report',
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
// FULL SCREEN TABLE SCREEN FOR VENDORS
// ─────────────────────────────────────────────
class VendorReportFullScreen extends StatelessWidget {
  final VendorReportController controller;
  const VendorReportFullScreen({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Text(
          "Vendors Full Report",
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
          emptyMessage: 'No vendors match the selected filters.',
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// STATUS / CATEGORY FILTER CHIPS ROW
// ─────────────────────────────────────────────
class _VendorFilters extends StatelessWidget {
  final VendorReportController controller;
  const _VendorFilters({required this.controller});

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
              ...VendorReportController.vendorStatusOptions.map((status) {
                final isSelected = f.vendorStatus == status;
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: _StatusChip(
                    label: status == 'all'
                        ? 'All'
                        : status[0].toUpperCase() + status.substring(1),
                    selected: isSelected,
                    color: _statusColor(status),
                    onTap: () => controller.updateFilter(
                      f.copyWith(vendorStatus: status),
                    ),
                  ),
                );
              }),
              const SizedBox(width: 4),
              _FilterDropdown(
                label: 'Category',
                value: f.category,
                options: controller.categoryOptions,
                onChanged: (v) =>
                    controller.updateFilter(f.copyWith(category: v)),
              ),
              const SizedBox(width: 8),
              // ✅ NAYA: Performance Filter Add Kiya
              _FilterDropdown(
                label: 'Performance',
                value: f.performanceFilter,
                options: VendorReportController.performanceFilterOptions,
                onChanged: (v) =>
                    controller.updateFilter(f.copyWith(performanceFilter: v)),
              ),
              const SizedBox(width: 8),
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

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return const Color(0xFF16A34A);
      case 'pending':
        return const Color(0xFFD97706);
      case 'hold':
        return const Color(0xFF9333EA);
      case 'rejected':
        return const Color(0xFFDC2626);
      default:
        return const Color(0xFF2563EB);
    }
  }
}

class _StatusChip extends StatelessWidget {
  final String label;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  const _StatusChip({
    required this.label,
    required this.selected,
    required this.color,
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
          color: selected ? color : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: selected ? color : const Color(0xFFE2E8F0)),
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
          dropdownColor: Colors.white, // ✅ Dropdown Menu White Background
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
