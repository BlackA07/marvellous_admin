// lib/features/reports/staff/controller/staff_report_controller.dart
//
// GetX controller — staff report ka poora state management.

import 'package:get/get.dart';
import '../../shared/models/report_filter_model.dart';

import '../../shared/widgets/report_filter_bar.dart';
import '../model/staff_report_model.dart';
import '../repository/staff_report_repository.dart';

// ─────────────────────────────────────────────
// COLUMN DEFINITIONS
// ─────────────────────────────────────────────
// lib/features/reports/staff/controller/staff_report_controller.dart

// ─────────────────────────────────────────────
// COLUMN DEFINITIONS
// ─────────────────────────────────────────────
final List<ReportColumn> staffReportColumns = [
  const ReportColumn(key: 'name', label: 'Name', minWidth: 160),
  const ReportColumn(key: 'designation', label: 'Designation', minWidth: 130),
  const ReportColumn(key: 'mobile1', label: 'Mobile', minWidth: 120),
  const ReportColumn(
    key: 'employmentType',
    label: 'Employment Type',
    minWidth: 130,
  ),
  const ReportColumn(
    key: 'presentsThisMonth',
    label: 'Presents (This Mth)',
    minWidth: 140,
  ), // ✅ NAYA
  const ReportColumn(
    key: 'absentsThisMonth',
    label: 'Absents (This Mth)',
    minWidth: 140,
  ), // ✅ NAYA
  const ReportColumn(
    key: 'earnedSalaryThisMonth',
    label: 'Earned Salary',
    minWidth: 150,
  ), // ✅ NAYA
  const ReportColumn(key: 'salaryAmount', label: 'Base Salary', minWidth: 110),
  const ReportColumn(
    key: 'totalMonthlyPayable',
    label: 'Total Payable',
    minWidth: 130,
  ),
  const ReportColumn(key: 'joiningDate', label: 'Joining Date', minWidth: 120),

  // ── Hidden by default ──
  const ReportColumn(
    key: 'salaryFrequency',
    label: 'Salary Frequency',
    minWidth: 130,
    visible: false,
  ),
  const ReportColumn(
    key: 'bonusMonthlyAmount',
    label: 'Bonus / Month',
    minWidth: 120,
    visible: false,
  ),
  const ReportColumn(
    key: 'commissionRegions',
    label: 'Commission Regions',
    minWidth: 160,
    visible: false,
  ),
  const ReportColumn(
    key: 'fatherName',
    label: 'Father Name',
    minWidth: 150,
    visible: false,
  ),
  const ReportColumn(key: 'cnic', label: 'CNIC', minWidth: 130, visible: false),
  const ReportColumn(
    key: 'mobile2',
    label: 'Mobile 2',
    minWidth: 120,
    visible: false,
  ),
  const ReportColumn(
    key: 'email',
    label: 'Email',
    minWidth: 180,
    visible: false,
  ),
  const ReportColumn(
    key: 'address',
    label: 'Address',
    minWidth: 200,
    visible: false,
  ),
  const ReportColumn(
    key: 'bonusType',
    label: 'Bonus Type',
    minWidth: 110,
    visible: false,
  ),
  const ReportColumn(
    key: 'bonusYearlyCount',
    label: 'Bonus / Year',
    minWidth: 100,
    visible: false,
  ),
  const ReportColumn(
    key: 'petrolRate',
    label: 'Petrol Rate',
    minWidth: 110,
    visible: false,
  ),
  const ReportColumn(
    key: 'avgRunning',
    label: 'Avg Running (km)',
    minWidth: 130,
    visible: false,
  ),
  const ReportColumn(
    key: 'fuelPerKm',
    label: 'Fuel / Km',
    minWidth: 100,
    visible: false,
  ),
  const ReportColumn(
    key: 'workingHours',
    label: 'Working Hours',
    minWidth: 150,
    visible: false,
  ),
  const ReportColumn(
    key: 'weeklyOffs',
    label: 'Weekly Offs',
    minWidth: 140,
    visible: false,
  ),
  const ReportColumn(
    key: 'attendanceByLocation',
    label: 'Location Attendance',
    minWidth: 140,
    visible: false,
  ),
  const ReportColumn(
    key: 'attendanceLocation',
    label: 'Attendance Location',
    minWidth: 160,
    visible: false,
  ),
  const ReportColumn(
    key: 'createdAt',
    label: 'Created Date',
    minWidth: 120,
    visible: false,
  ),
];

// ─────────────────────────────────────────────
// SORT OPTIONS (ALL COLUMNS ADDED)
// ─────────────────────────────────────────────
final List<ReportSortOption> staffSortOptions = [
  const ReportSortOption(key: 'joiningDate', label: 'Joining Date'),
  const ReportSortOption(key: 'name', label: 'Name (A-Z)'),
  const ReportSortOption(key: 'designation', label: 'Designation'),
  const ReportSortOption(key: 'employmentType', label: 'Employment Type'),
  const ReportSortOption(key: 'salaryAmount', label: 'Highest Base Salary'),
  const ReportSortOption(key: 'totalMonthlyPayable', label: 'Highest Payable'),
  const ReportSortOption(
    key: 'presentsThisMonth',
    label: 'Most Presents (Month)',
  ),
  const ReportSortOption(
    key: 'absentsThisMonth',
    label: 'Most Absents (Month)',
  ),
  const ReportSortOption(
    key: 'earnedSalaryThisMonth',
    label: 'Highest Earned Salary',
  ),
  const ReportSortOption(key: 'bonusMonthlyAmount', label: 'Highest Bonus'),
  const ReportSortOption(key: 'commissionRegions', label: 'Regions'),
  const ReportSortOption(key: 'cnic', label: 'CNIC'),
  const ReportSortOption(key: 'createdAt', label: 'Created Date'),
];

class StaffReportController extends GetxController {
  final StaffReportRepository _repo = StaffReportRepository();

  // ── State ──
  var isLoading = true.obs;
  var errorMessage = ''.obs;

  var allStaff = <StaffReportModel>[].obs;
  var filter = StaffReportFilter().obs;
  var columns = <ReportColumn>[].obs;

  @override
  void onInit() {
    super.onInit();
    columns.assignAll(staffReportColumns);
    fetchData();
  }

  // ── Fetch ──
  Future<void> fetchData() async {
    isLoading(true);
    errorMessage('');
    try {
      final data = await _repo.getStaffReportData();
      allStaff.assignAll(data);
    } catch (e) {
      errorMessage('Failed to load staff: $e');
    } finally {
      isLoading(false);
    }
  }

  void refresh() => fetchData();

  // ── Filter / column updates ──
  void updateFilter(StaffReportFilter newFilter) {
    filter.value = newFilter;
  }

  void updateColumns(List<ReportColumn> newCols) {
    columns.assignAll(newCols);
  }

  void resetFilters() {
    filter.value = const StaffReportFilter();
  }

  // ── Dropdown options (derived from data) ──
  static const List<String> employmentTypeOptions = [
    'all',
    'salary',
    'commission',
    'both',
  ];

  List<String> get designationOptions {
    final set = allStaff
        .map((s) => s.designation.trim())
        .where((d) => d.isNotEmpty)
        .toSet()
        .toList();
    set.sort();
    return ['all', ...set];
  }

  List<String> get commissionRegionOptions {
    final set = <String>{};
    for (final s in allStaff) {
      for (final r in s.commissionRegions) {
        if (r.trim().isNotEmpty) set.add(r.trim());
      }
    }
    final list = set.toList();
    list.sort();
    return ['all', ...list];
  }

  // ── Filtered + sorted list ──
  List<StaffReportModel> get filteredStaff {
    final f = filter.value;
    var list = allStaff.where((s) {
      // Date range (joining date)
      if (f.datePreset != DateRangePreset.allTime) {
        if (s.joiningDate.isBefore(f.resolvedStart) ||
            s.joiningDate.isAfter(f.resolvedEnd)) {
          return false;
        }
      }

      // Search — name, father name, cnic, mobile, designation, email
      if (f.searchQuery.trim().isNotEmpty) {
        final q = f.searchQuery.trim().toLowerCase();
        final matches =
            s.name.toLowerCase().contains(q) ||
            s.fatherName.toLowerCase().contains(q) ||
            s.cnic.toLowerCase().contains(q) ||
            s.mobile1.toLowerCase().contains(q) ||
            s.designation.toLowerCase().contains(q) ||
            (s.email ?? '').toLowerCase().contains(q);
        if (!matches) return false;
      }

      // Employment type
      if (f.employmentType != 'all' &&
          s.employmentType.toLowerCase() != f.employmentType.toLowerCase()) {
        return false;
      }

      // Designation
      if (f.designation != 'all' && s.designation != f.designation) {
        return false;
      }

      // Commission region (staff must have this region in their list)
      if (f.commissionRegion != 'all' &&
          !s.commissionRegions.contains(f.commissionRegion)) {
        return false;
      }

      return true;
    }).toList();

    // ── Sorting ──
    if (f.sortBy.isNotEmpty) {
      // Controller ke andar sorting update (switch-case) 👇
      // List<StaffReportModel> get filteredStaff ke andar list.sort() mein:

      list.sort((a, b) {
        int cmp;
        switch (f.sortBy) {
          case 'name':
            cmp = a.name.toLowerCase().compareTo(b.name.toLowerCase());
            break;
          case 'joiningDate':
            cmp = a.joiningDate.compareTo(b.joiningDate);
            break;
          case 'designation':
            cmp = a.designation.toLowerCase().compareTo(
              b.designation.toLowerCase(),
            );
            break;
          case 'employmentType':
            cmp = a.employmentType.compareTo(b.employmentType);
            break;
          case 'salaryAmount':
            cmp = (a.salaryAmount ?? 0).compareTo(b.salaryAmount ?? 0);
            break;
          case 'totalMonthlyPayable':
            cmp = (a.totalMonthlyPayable ?? 0).compareTo(
              b.totalMonthlyPayable ?? 0,
            );
            break;
          case 'bonusMonthlyAmount':
            cmp = (a.bonusMonthlyAmount ?? 0).compareTo(
              b.bonusMonthlyAmount ?? 0,
            );
            break;
          case 'presentsThisMonth':
            cmp = a.presentsThisMonth.compareTo(b.presentsThisMonth);
            break;
          case 'absentsThisMonth':
            cmp = a.absentsThisMonth.compareTo(b.absentsThisMonth);
            break;
          case 'earnedSalaryThisMonth':
            cmp = a.earnedSalaryThisMonth.compareTo(b.earnedSalaryThisMonth);
            break;
          case 'commissionRegions':
            cmp = a.commissionRegions.join().compareTo(
              b.commissionRegions.join(),
            );
            break;
          case 'cnic':
            cmp = a.cnic.compareTo(b.cnic);
            break;
          case 'createdAt':
            cmp = a.createdAt.compareTo(b.createdAt);
            break;
          default:
            cmp = 0;
        }
        return f.sortDir == SortDirection.ascending ? cmp : -cmp;
      });
    } else {
      // Default: newest joined first
      list.sort((a, b) => b.joiningDate.compareTo(a.joiningDate));
    }

    return list;
  }

  // ── Table rows for export/display ──
  List<Map<String, dynamic>> get tableRows =>
      filteredStaff.map((s) => s.toRowMap()).toList();

  // ── Summary stats (top cards + PDF header) ──
  Map<String, String> get summaryStats {
    final list = filteredStaff;
    final total = list.length;
    final onSalary = list
        .where(
          (s) => s.employmentType == 'salary' || s.employmentType == 'both',
        )
        .length;
    final onCommission = list
        .where(
          (s) => s.employmentType == 'commission' || s.employmentType == 'both',
        )
        .length;

    final totalSalary = list.fold<double>(
      0,
      (sum, s) => sum + (s.salaryAmount ?? 0),
    );
    final totalPayable = list.fold<double>(
      0,
      (sum, s) => sum + (s.totalMonthlyPayable ?? 0),
    );
    final totalBonus = list.fold<double>(
      0,
      (sum, s) => sum + (s.bonusMonthlyAmount ?? 0),
    );

    return {
      'Total Staff': '$total',
      'On Salary': '$onSalary',
      'On Commission': '$onCommission',
      'Total Salaries': 'Rs. ${_fmt(totalSalary)}',
      'Total Bonus/Month': 'Rs. ${_fmt(totalBonus)}',
      'Total Payable/Month': 'Rs. ${_fmt(totalPayable)}',
    };
  }

  String _fmt(double v) {
    if (v >= 1000000) return '${(v / 1000000).toStringAsFixed(1)}M';
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(1)}K';
    return v.toStringAsFixed(0);
  }
}
