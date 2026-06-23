// lib/features/reports/shared/widgets/report_filter_bar.dart
//
// Top filter bar — date range preset picker, search bar, sort dropdown.
// Har report screen isko use karega apne filter callback ke saath.

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../models/report_filter_model.dart';

class ReportFilterBar extends StatelessWidget {
  final BaseReportFilter filter;
  final ValueChanged<BaseReportFilter> onFilterChanged;
  final List<ReportSortOption> sortOptions;
  final String searchHint;
  final VoidCallback? onColumnsTap; // opens column selector sheet
  final int totalRecords;

  const ReportFilterBar({
    super.key,
    required this.filter,
    required this.onFilterChanged,
    required this.sortOptions,
    this.searchHint = 'Search...',
    this.onColumnsTap,
    this.totalRecords = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Row 1: Search + Columns button ──
          Row(
            children: [
              Expanded(
                child: _SearchBar(
                  hint: searchHint,
                  value: filter.searchQuery,
                  onChanged: (q) =>
                      onFilterChanged(filter.copyWith(searchQuery: q)),
                ),
              ),
              if (onColumnsTap != null) ...[
                const SizedBox(width: 8),
                _IconBtn(
                  icon: Icons.view_column_outlined,
                  tooltip: 'Choose columns',
                  onTap: onColumnsTap!,
                ),
              ],
            ],
          ),
          const SizedBox(height: 10),

          // ── Row 2: Date presets ──
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: DateRangePreset.values.map((preset) {
                final isSelected = filter.datePreset == preset;
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: _DateChip(
                    label: preset.label,
                    selected: isSelected,
                    onTap: () async {
                      if (preset == DateRangePreset.custom) {
                        final picked = await showDateRangePicker(
                          context: context,
                          firstDate: DateTime(2020),
                          lastDate: DateTime.now(),
                          initialDateRange: DateTimeRange(
                            start: filter.resolvedStart,
                            end: filter.resolvedEnd,
                          ),
                          builder: (ctx, child) => Theme(
                            data: Theme.of(ctx).copyWith(
                              colorScheme: const ColorScheme.light(
                                primary: Color(0xFF2563EB),
                              ),
                            ),
                            child: child!,
                          ),
                        );
                        if (picked != null) {
                          onFilterChanged(
                            filter.copyWith(
                              datePreset: DateRangePreset.custom,
                              startDate: picked.start,
                              endDate: picked.end,
                            ),
                          );
                        }
                      } else {
                        onFilterChanged(filter.copyWith(datePreset: preset));
                      }
                    },
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 10),

          // ── Row 3: Sort + active date range display + record count ──
          Row(
            children: [
              // Sort dropdown
              if (sortOptions.isNotEmpty)
                _SortDropdown(
                  options: sortOptions,
                  currentSortBy: filter.sortBy,
                  currentDir: filter.sortDir,
                  onChanged: (sortBy, dir) => onFilterChanged(
                    filter.copyWith(sortBy: sortBy, sortDir: dir),
                  ),
                ),
              const Spacer(),
              // Active date label
              _DateRangeLabel(filter: filter),
              const SizedBox(width: 10),
              // Record count
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFBFDBFE)),
                ),
                child: Text(
                  '$totalRecords records',
                  style: GoogleFonts.nunito(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF2563EB),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// SORT OPTION MODEL
// ─────────────────────────────────────────────
class ReportSortOption {
  final String key;
  final String label;
  const ReportSortOption({required this.key, required this.label});
}

// ─────────────────────────────────────────────
// INTERNAL WIDGETS
// ─────────────────────────────────────────────

class _SearchBar extends StatefulWidget {
  final String hint;
  final String value;
  final ValueChanged<String> onChanged;

  const _SearchBar({
    required this.hint,
    required this.value,
    required this.onChanged,
  });

  @override
  State<_SearchBar> createState() => _SearchBarState();
}

class _SearchBarState extends State<_SearchBar> {
  late final TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.value);
  }

  @override
  void didUpdateWidget(_SearchBar old) {
    super.didUpdateWidget(old);
    if (old.value != widget.value && _ctrl.text != widget.value) {
      _ctrl.text = widget.value;
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: TextField(
        controller: _ctrl,
        onChanged: widget.onChanged,
        style: GoogleFonts.nunito(fontSize: 13, color: const Color(0xFF1E293B)),
        decoration: InputDecoration(
          hintText: widget.hint,
          hintStyle: GoogleFonts.nunito(
            fontSize: 13,
            color: const Color(0xFF94A3B8),
          ),
          prefixIcon: const Icon(
            Icons.search,
            size: 18,
            color: Color(0xFF94A3B8),
          ),
          suffixIcon: _ctrl.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(
                    Icons.close,
                    size: 16,
                    color: Color(0xFF94A3B8),
                  ),
                  onPressed: () {
                    _ctrl.clear();
                    widget.onChanged('');
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 10),
        ),
      ),
    );
  }
}

class _DateChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _DateChip({
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
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF2563EB) : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? const Color(0xFF2563EB) : const Color(0xFFCBD5E1),
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.nunito(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: selected ? Colors.white : const Color(0xFF475569),
          ),
        ),
      ),
    );
  }
}

class _SortDropdown extends StatelessWidget {
  final List<ReportSortOption> options;
  final String currentSortBy;
  final SortDirection currentDir;
  final void Function(String sortBy, SortDirection dir) onChanged;

  const _SortDropdown({
    required this.options,
    required this.currentSortBy,
    required this.currentDir,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Sort field dropdown
        Container(
          height: 34,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: const Color(0xFF1E293B),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFF334155)),
          ),
          child: DropdownButtonHideUnderline(
            child: Theme(
              data: Theme.of(context).copyWith(
                canvasColor: const Color(
                  0xFF1E293B,
                ), // dropdown menu background
              ),
              child: DropdownButton<String>(
                dropdownColor: const Color.fromARGB(255, 255, 255, 255),
                value: currentSortBy.isEmpty ? null : currentSortBy,
                hint: Text(
                  'Sort by',
                  style: GoogleFonts.nunito(fontSize: 12, color: Colors.white),
                ),
                style: GoogleFonts.nunito(fontSize: 12, color: Colors.white),
                iconEnabledColor: Colors.white70,
                isDense: true,
                items: options
                    .map(
                      (o) =>
                          DropdownMenuItem(value: o.key, child: Text(o.label)),
                    )
                    .toList(),
                onChanged: (val) {
                  if (val != null) onChanged(val, currentDir);
                },
              ),
            ),
          ),
        ),
        const SizedBox(width: 6),
        // Direction toggle
        GestureDetector(
          onTap: () => onChanged(
            currentSortBy,
            currentDir == SortDirection.ascending
                ? SortDirection.descending
                : SortDirection.ascending,
          ),
          child: Container(
            height: 34,
            width: 34,
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Icon(
              currentDir == SortDirection.ascending
                  ? Icons.arrow_upward_rounded
                  : Icons.arrow_downward_rounded,
              size: 16,
              color: const Color(0xFF2563EB),
            ),
          ),
        ),
      ],
    );
  }
}

class _DateRangeLabel extends StatelessWidget {
  final BaseReportFilter filter;
  const _DateRangeLabel({required this.filter});

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('dd MMM yy');
    final label = filter.datePreset == DateRangePreset.allTime
        ? 'All time'
        : '${fmt.format(filter.resolvedStart)} — ${fmt.format(filter.resolvedEnd)}';
    return Text(
      label,
      style: GoogleFonts.nunito(
        fontSize: 11,
        color: const Color(0xFF64748B),
        fontWeight: FontWeight.w500,
      ),
    );
  }
}

class _IconBtn extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  const _IconBtn({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 40,
          width: 40,
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Icon(icon, size: 18, color: const Color(0xFF2563EB)),
        ),
      ),
    );
  }
}
