// lib/features/reports/products/screens/product_report_screen.dart
//
// Products Report — main screen.
// Shows: summary cards, category/vendor/status filter chips, search+date+sort bar,
// scrollable data table with toggleable columns, export bottom sheet (PDF/CSV/Print/Share).

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../shared/models/report_filter_model.dart';
import '../../shared/widgets/report_filter_bar.dart';
import '../../shared/widgets/report_data_table.dart';
import '../../shared/widgets/report_summary_cards.dart';
import '../../shared/widgets/report_export_sheet.dart';
import '../../shared/widgets/column_selector_widget.dart';
import '../controller/product_report_controller.dart';

class ProductReportScreen extends StatelessWidget {
  const ProductReportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(ProductReportController());

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.white,
        title: Text(
          'Products Report',
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

            // ── Category / vendor / status filter chips ──
            _ProductFilters(controller: controller),

            // ── Search / date / sort bar ──
            ReportFilterBar(
              filter: controller.filter.value,
              onFilterChanged: (f) =>
                  controller.updateFilter(f as ProductReportFilter),
              sortOptions: productSortOptions,
              searchHint: 'Search name, model no, brand, vendor...',
              totalRecords: controller.filteredProducts.length,
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
                        emptyMessage: 'No products match the selected filters.',
                      ),
                    ),
                  ),
                  // ✅ NAYA HISSA: Full Screen Button
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12.0),
                    child: OutlinedButton.icon(
                      onPressed: () => Get.to(
                        () => ProductReportFullScreen(controller: controller),
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
          onPressed: controller.filteredProducts.isEmpty
              ? null
              : () => ReportExportSheet.show(
                  context,
                  reportTitle: 'Products Report',
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

  void _showColumnSelector(
    BuildContext context,
    dynamic controller, // ✅ Dynamic takay GetX ka error na aaye
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
        child: SingleChildScrollView(
          // ✅ FIX: 'Obx' hata diya gaya hai crash bachane ke liye
          child: ColumnSelectorWidget(
            columns: List<ReportColumn>.from(controller.columns),
            onChanged: (newCols) {
              controller.columns.clear();
              controller.columns.addAll(List<ReportColumn>.from(newCols));
            },
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// FULL SCREEN TABLE SCREEN FOR PRODUCTS
// ─────────────────────────────────────────────
class ProductReportFullScreen extends StatelessWidget {
  final ProductReportController controller;
  const ProductReportFullScreen({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Text(
          "Products Full Report",
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
          emptyMessage: 'No products match the selected filters.',
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// CATEGORY / VENDOR / STATUS FILTER CHIPS ROW
// ─────────────────────────────────────────────
class _ProductFilters extends StatelessWidget {
  final ProductReportController controller;
  const _ProductFilters({required this.controller});

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
              _FilterDropdown(
                label: 'Type',
                value: f.itemType,
                options: ProductReportController.itemTypeOptions,
                onChanged: (v) =>
                    controller.updateFilter(f.copyWith(itemType: v)),
              ),
              const SizedBox(width: 8),
              _FilterDropdown(
                label: 'Category',
                value: f.category,
                options: controller.categoryOptions,
                onChanged: (v) => controller.updateFilter(
                  // Reset subCategory when category changes
                  f.copyWith(category: v, subCategory: 'all'),
                ),
              ),
              const SizedBox(width: 8),
              _FilterDropdown(
                label: 'Sub-Category',
                value: f.subCategory,
                options: controller.subCategoryOptions,
                onChanged: (v) =>
                    controller.updateFilter(f.copyWith(subCategory: v)),
              ),
              const SizedBox(width: 8),
              _FilterDropdown(
                label: 'Vendor',
                value: f.vendorName,
                options: controller.vendorOptions,
                onChanged: (v) =>
                    controller.updateFilter(f.copyWith(vendorName: v)),
              ),
              const SizedBox(width: 8),
              _FilterDropdown(
                label: 'Status',
                value: f.status,
                options: controller.statusOptions,
                onChanged: (v) =>
                    controller.updateFilter(f.copyWith(status: v)),
              ),
              const SizedBox(width: 8),
              _FilterDropdown(
                label: 'Location',
                value: f.deliveryLocation,
                options: controller.deliveryLocationOptions,
                onChanged: (v) =>
                    controller.updateFilter(f.copyWith(deliveryLocation: v)),
              ),
              const SizedBox(width: 8),
              // Low stock toggle
              _ToggleChip(
                label: 'Low Stock',
                icon: Icons.warning_amber_rounded,
                selected: f.lowStockOnly,
                onTap: () => controller.updateFilter(
                  f.copyWith(lowStockOnly: !f.lowStockOnly),
                ),
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
    // Ensure current value is in the options list (avoids dropdown crash
    // when subCategory list changes after category switch)
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
            String displayLabel;
            if (opt == 'all') {
              displayLabel = 'All $label';
            } else if (label == 'Type') {
              displayLabel = opt[0].toUpperCase() + opt.substring(1);
            } else {
              displayLabel = opt;
            }
            return DropdownMenuItem(value: opt, child: Text(displayLabel));
          }).toList(),
          onChanged: (v) {
            if (v != null) onChanged(v);
          },
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// TOGGLE CHIP (for boolean filters like Low Stock)
// ─────────────────────────────────────────────
class _ToggleChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _ToggleChip({
    required this.label,
    required this.icon,
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
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFFEF3C7) : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected ? const Color(0xFFD97706) : const Color(0xFFE2E8F0),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 15,
              color: selected
                  ? const Color(0xFFD97706)
                  : const Color(0xFF94A3B8),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.nunito(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: selected
                    ? const Color(0xFFD97706)
                    : const Color(0xFF475569),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
