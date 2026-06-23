// lib/features/reports/finance/screens/finance_report_screen.dart
//
// Finance Report — main screen.
// Shows: summary cards (in/out/net/profit), type/category/payment/linked filters,
// search+date+sort bar, scrollable data table with toggleable columns,
// export bottom sheet (PDF/CSV/Print/Share).
//
// NOTE: Date range change triggers a fresh Firestore query (handled in
// controller.updateFilter) since date filtering is server-side here.

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../shared/models/report_filter_model.dart';
import '../../shared/widgets/report_filter_bar.dart';
import '../../shared/widgets/report_data_table.dart';
import '../../shared/widgets/report_summary_cards.dart';
import '../../shared/widgets/report_export_sheet.dart';
import '../../shared/widgets/column_selector_widget.dart';
import '../controller/finance_report_controller.dart';
import '../model/finance_report_model.dart';

class FinanceReportScreen extends StatelessWidget {
  const FinanceReportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(FinanceReportController());

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.white,
        title: Text(
          'Finance Report',
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
            ReportSummaryCards(
              stats: controller.summaryStats,
              colors: const [
                Color(0xFF16A34A), // Total In
                Color(0xFFDC2626), // Total Out
                Color(0xFF2563EB), // Net Balance
                Color(0xFF7C3AED), // Gross Profit
                Color(0xFF059669), // IN Entries
                Color(0xFFD97706), // OUT Entries
                Color(0xFF0891B2), // Total Entries
              ],
            ),
            const SizedBox(height: 14),

            // ── Type / category / payment / linked filter chips ──
            _FinanceFilters(controller: controller),

            // ── Search / date / sort bar ──
            ReportFilterBar(
              filter: controller.filter.value,
              onFilterChanged: (f) =>
                  controller.updateFilter(f as FinanceReportFilter),
              sortOptions: financeSortOptions,
              searchHint: 'Search description, linked name, order ID...',
              totalRecords: controller.filteredTransactions.length,
              onColumnsTap: () => _showColumnSelector(context, controller),
            ),

            // lib/features/reports/finance/screens/finance_report_screen.dart

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
                            'No transactions found for the selected filters.',
                      ),
                    ),
                  ),
                  // ✅ NAYA HISSA: Full Screen Button
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12.0),
                    child: OutlinedButton.icon(
                      onPressed: () => Get.to(
                        () => FinanceReportFullScreen(controller: controller),
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
          onPressed: controller.filteredTransactions.isEmpty
              ? null
              : () => ReportExportSheet.show(
                  context,
                  reportTitle: 'Finance Report',
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
          // ✅ FIX: Hata diya gaya Obx yahan se
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
// FULL SCREEN TABLE SCREEN FOR FINANCE
// ─────────────────────────────────────────────
class FinanceReportFullScreen extends StatelessWidget {
  final FinanceReportController controller;
  const FinanceReportFullScreen({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Text(
          "Finance Full Report",
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
          emptyMessage: 'No transactions match the selected filters.',
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// TYPE / CATEGORY / PAYMENT / LINKED FILTER CHIPS ROW
// ─────────────────────────────────────────────
class _FinanceFilters extends StatelessWidget {
  final FinanceReportController controller;
  const _FinanceFilters({required this.controller});

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
              // Type chips: All / In / Out
              ...FinanceReportController.transactionTypeOptions.map((type) {
                final isSelected = f.transactionType == type;
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: _TypeChip(
                    label: type == 'all' ? 'All' : type.toUpperCase(),
                    selected: isSelected,
                    color: type == 'in'
                        ? const Color(0xFF16A34A)
                        : type == 'out'
                        ? const Color(0xFFDC2626)
                        : const Color(0xFF2563EB),
                    onTap: () => controller.updateFilter(
                      // Reset category when type changes (category list depends on type)
                      f.copyWith(transactionType: type, category: 'all'),
                    ),
                  ),
                );
              }),
              const SizedBox(width: 4),

              // Category dropdown (depends on selected type)
              _FilterDropdown(
                label: 'Category',
                value: f.category,
                options: controller.categoryOptions,
                labelMapper: (v) =>
                    v == 'all' ? 'All Category' : financeCategoryLabel(v),
                onChanged: (v) =>
                    controller.updateFilter(f.copyWith(category: v)),
              ),
              const SizedBox(width: 8),

              // Payment method dropdown
              _FilterDropdown(
                label: 'Payment',
                value: f.paymentMethod,
                options: FinanceReportController.paymentMethodOptions,
                labelMapper: (v) =>
                    v == 'all' ? 'All Payment' : financePaymentMethodLabel(v),
                onChanged: (v) =>
                    controller.updateFilter(f.copyWith(paymentMethod: v)),
              ),
              const SizedBox(width: 8),

              // Linked entity dropdown
              _FilterDropdown(
                label: 'Linked',
                value: f.linkedEntity,
                options: FinanceReportController.linkedEntityOptions,
                labelMapper: (v) {
                  if (v == 'all') return 'All Linked';
                  return v[0].toUpperCase() + v.substring(1);
                },
                onChanged: (v) =>
                    controller.updateFilter(f.copyWith(linkedEntity: v)),
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
// TYPE CHIP (in/out/all quick-tap filter)
// ─────────────────────────────────────────────
class _TypeChip extends StatelessWidget {
  final String label;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  const _TypeChip({
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

// ─────────────────────────────────────────────
// REUSABLE FILTER DROPDOWN CHIP (with custom label mapper)
// ─────────────────────────────────────────────
class _FilterDropdown extends StatelessWidget {
  final String label;
  final String value;
  final List<String> options;
  final ValueChanged<String> onChanged;
  final String Function(String value)? labelMapper;

  const _FilterDropdown({
    required this.label,
    required this.value,
    required this.options,
    required this.onChanged,
    this.labelMapper,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = value != 'all';
    final safeValue = options.contains(value) ? value : 'all';

    return Container(
      height: 38,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      constraints: const BoxConstraints(maxWidth: 170),
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
          isExpanded: true,
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
            final text = labelMapper != null
                ? labelMapper!(opt)
                : (opt == 'all' ? 'All $label' : opt);
            return DropdownMenuItem(
              value: opt,
              child: Text(text, overflow: TextOverflow.ellipsis),
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
