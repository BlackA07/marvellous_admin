// lib/features/reports/vendors/controller/vendor_report_controller.dart
import 'package:get/get.dart';
import '../../shared/models/report_filter_model.dart';
import '../../shared/widgets/report_filter_bar.dart';
import '../model/vendor_report_model.dart';
import '../repository/vendor_report_repository.dart';

final List<ReportColumn> vendorReportColumns = [
  const ReportColumn(key: 'storeName', label: 'Store Name', minWidth: 170),
  const ReportColumn(key: 'ownerName', label: 'Owner Name', minWidth: 150),
  const ReportColumn(key: 'email', label: 'Email', minWidth: 190),
  const ReportColumn(key: 'ownerMobile', label: 'Mobile', minWidth: 120),
  const ReportColumn(key: 'categories', label: 'Categories', minWidth: 160),
  const ReportColumn(key: 'vendorStatus', label: 'Status', minWidth: 100),
  const ReportColumn(
    key: 'beginningBalance',
    label: 'Beginning Balance',
    minWidth: 140,
  ),
  const ReportColumn(key: 'totalBilled', label: 'Total Billed', minWidth: 130),
  const ReportColumn(key: 'totalPaid', label: 'Total Paid', minWidth: 130),
  const ReportColumn(
    key: 'remainingDue',
    label: 'Remaining Due',
    minWidth: 130,
  ),
  const ReportColumn(
    key: 'storePhone',
    label: 'Store Phone',
    minWidth: 120,
    visible: false,
  ),
  const ReportColumn(
    key: 'contactPersonName',
    label: 'Contact Person',
    minWidth: 150,
    visible: false,
  ),
  const ReportColumn(
    key: 'contactPersonPhone',
    label: 'Contact Phone',
    minWidth: 130,
    visible: false,
  ),
  const ReportColumn(
    key: 'address',
    label: 'Address',
    minWidth: 200,
    visible: false,
  ),
  const ReportColumn(
    key: 'subCategories',
    label: 'Sub-Categories',
    minWidth: 160,
    visible: false,
  ),
  const ReportColumn(
    key: 'totalProducts',
    label: 'Products Listed',
    minWidth: 120,
    visible: false,
  ),
  const ReportColumn(
    key: 'totalBills',
    label: 'Total Bills',
    minWidth: 110,
    visible: false,
  ),
  const ReportColumn(
    key: 'approvedAt',
    label: 'Approved Date',
    minWidth: 130,
    visible: false,
  ),
  const ReportColumn(
    key: 'rejectionReason',
    label: 'Rejection/Hold Reason',
    minWidth: 180,
    visible: false,
  ),
];

final List<ReportSortOption> vendorSortOptions = [
  const ReportSortOption(key: 'storeName', label: 'Store Name (A-Z)'),
  const ReportSortOption(
    key: 'ownerName',
    label: 'Owner Name',
  ), // ✅ FIX: Missing sort option
  const ReportSortOption(key: 'email', label: 'Email'), // ✅ FIX
  const ReportSortOption(key: 'ownerMobile', label: 'Mobile'), // ✅ FIX
  const ReportSortOption(key: 'vendorStatus', label: 'Status'), // ✅ FIX
  const ReportSortOption(key: 'totalBilled', label: 'Highest Billed'),
  const ReportSortOption(key: 'totalPaid', label: 'Highest Paid'),
  const ReportSortOption(key: 'remainingDue', label: 'Most Dues Pending'),
  const ReportSortOption(key: 'totalProducts', label: 'Most Products Listed'),
  const ReportSortOption(key: 'totalBills', label: 'Most Bills'),
  const ReportSortOption(key: 'beginningBalance', label: 'Beginning Balance'),
  const ReportSortOption(key: 'approvedAt', label: 'Approved Date'),
];

class VendorReportController extends GetxController {
  final VendorReportRepository _repo = VendorReportRepository();

  var isLoading = true.obs;
  var errorMessage = ''.obs;

  var allVendors = <VendorReportModel>[].obs;
  var filter = VendorReportFilter().obs;
  var columns = <ReportColumn>[].obs;

  @override
  void onInit() {
    super.onInit();
    columns.assignAll(vendorReportColumns);
    fetchData();
  }

  Future<void> fetchData() async {
    isLoading(true);
    errorMessage('');
    try {
      final data = await _repo.getVendorReportData();
      allVendors.assignAll(data);
    } catch (e) {
      errorMessage('Failed to load vendors: $e');
    } finally {
      isLoading(false);
    }
  }

  void refreshData() =>
      fetchData(); // ✅ Changed to refreshData to match other screens

  void updateFilter(VendorReportFilter newFilter) {
    filter.value = newFilter;
  }

  void updateColumns(List<ReportColumn> newCols) {
    columns.clear();
    columns.addAll(newCols);
  }

  void resetFilters() {
    filter.value = const VendorReportFilter();
  }

  static const List<String> vendorStatusOptions = [
    'all',
    'approved',
    'pending',
    'hold',
    'rejected',
  ];

  // ✅ NAYA: Performance Filter (Zero Products, Most Bills etc.)
  static const List<String> performanceFilterOptions = [
    'all',
    'Zero Products Listed',
    'Has Listed Products',
    'Has Bills (Active)',
  ];

  List<String> get categoryOptions {
    final set = <String>{};
    for (final v in allVendors) {
      for (final cat in v.categories) {
        if (cat.trim().isNotEmpty) set.add(cat.trim());
      }
    }
    final list = set.toList();
    list.sort();
    return ['all', ...list];
  }

  List<VendorReportModel> get filteredVendors {
    final f = filter.value;
    var list = allVendors.where((v) {
      if (f.datePreset != DateRangePreset.allTime && v.approvedAt != null) {
        if (v.approvedAt!.isBefore(f.resolvedStart) ||
            v.approvedAt!.isAfter(f.resolvedEnd)) {
          return false;
        }
      }

      if (f.searchQuery.trim().isNotEmpty) {
        final q = f.searchQuery.trim().toLowerCase();
        final matches =
            v.storeName.toLowerCase().contains(q) ||
            v.ownerName.toLowerCase().contains(q) ||
            v.email.toLowerCase().contains(q) ||
            v.ownerMobile.toLowerCase().contains(q) ||
            v.contactPersonName.toLowerCase().contains(q);
        if (!matches) return false;
      }

      if (f.vendorStatus != 'all' &&
          v.status.toLowerCase() != f.vendorStatus.toLowerCase())
        return false;
      if (f.category != 'all' && !v.categories.contains(f.category))
        return false;

      // ✅ NAYA: Checking performance filter
      if (f.performanceFilter != 'all') {
        if (f.performanceFilter == 'Zero Products Listed' &&
            v.totalProducts > 0)
          return false;
        if (f.performanceFilter == 'Has Listed Products' &&
            v.totalProducts == 0)
          return false;
        if (f.performanceFilter == 'Has Bills (Active)' && v.totalBills == 0)
          return false;
      }

      return true;
    }).toList();

    if (f.sortBy.isNotEmpty) {
      list.sort((a, b) {
        int cmp;
        switch (f.sortBy) {
          case 'storeName':
            cmp = a.storeName.toLowerCase().compareTo(
              b.storeName.toLowerCase(),
            );
            break;
          case 'ownerName': // ✅ FIXED
            cmp = a.ownerName.toLowerCase().compareTo(
              b.ownerName.toLowerCase(),
            );
            break;
          case 'email': // ✅ FIXED
            cmp = a.email.toLowerCase().compareTo(b.email.toLowerCase());
            break;
          case 'ownerMobile': // ✅ FIXED
            cmp = a.ownerMobile.compareTo(b.ownerMobile);
            break;
          case 'vendorStatus': // ✅ FIXED
            cmp = a.status.toLowerCase().compareTo(b.status.toLowerCase());
            break;
          case 'approvedAt':
            final ad = a.approvedAt ?? DateTime(2000);
            final bd = b.approvedAt ?? DateTime(2000);
            cmp = ad.compareTo(bd);
            break;
          case 'totalBilled':
            cmp = a.totalBilled.compareTo(b.totalBilled);
            break;
          case 'totalPaid':
            cmp = a.totalPaid.compareTo(b.totalPaid);
            break;
          case 'remainingDue':
            cmp = a.remainingDue.compareTo(b.remainingDue);
            break;
          case 'totalProducts':
            cmp = a.totalProducts.compareTo(b.totalProducts);
            break;
          case 'totalBills':
            cmp = a.totalBills.compareTo(b.totalBills);
            break;
          case 'beginningBalance':
            cmp = a.beginningBalance.compareTo(b.beginningBalance);
            break;
          default:
            cmp = 0;
        }
        return f.sortDir == SortDirection.ascending ? cmp : -cmp;
      });
    } else {
      list.sort((a, b) {
        final aApproved = a.status.toLowerCase() == 'approved';
        final bApproved = b.status.toLowerCase() == 'approved';
        if (aApproved != bApproved) return aApproved ? -1 : 1;
        return a.storeName.toLowerCase().compareTo(b.storeName.toLowerCase());
      });
    }

    return list;
  }

  List<Map<String, dynamic>> get tableRows =>
      filteredVendors.map((v) => v.toRowMap()).toList();

  Map<String, String> get summaryStats {
    final list = filteredVendors;
    final total = list.length;
    final approved = list
        .where((v) => v.status.toLowerCase() == 'approved')
        .length;
    final pending = list
        .where((v) => v.status.toLowerCase() == 'pending')
        .length;
    final hold = list.where((v) => v.status.toLowerCase() == 'hold').length;
    final rejected = list
        .where((v) => v.status.toLowerCase() == 'rejected')
        .length;

    final totalBilled = list.fold<double>(0, (s, v) => s + v.totalBilled);
    final totalPaid = list.fold<double>(0, (s, v) => s + v.totalPaid);
    final totalDue = list.fold<double>(0, (s, v) => s + v.remainingDue);
    final totalProducts = list.fold<int>(0, (s, v) => s + v.totalProducts);

    return {
      'Total Vendors': '$total',
      'Approved': '$approved',
      'Pending': '$pending',
      'Hold/Rejected': '${hold + rejected}',
      'Products Listed': '$totalProducts',
      'Total Billed': 'Rs. ${_fmt(totalBilled)}',
      'Total Paid': 'Rs. ${_fmt(totalPaid)}',
      'Total Due': 'Rs. ${_fmt(totalDue)}',
    };
  }

  String _fmt(double v) {
    if (v >= 1000000) return '${(v / 1000000).toStringAsFixed(1)}M';
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(1)}K';
    return v.toStringAsFixed(0);
  }
}
