// lib/features/reports/customers/controller/customer_report_controller.dart
//
// GetX controller — customer report ka poora state management:
// - data fetch
// - column visibility
// - filters (date, city, state, country, membership, mlm, rank, search)
// - sorting
// - summary stats (for top cards + PDF header)

import 'package:get/get.dart';
import '../../shared/models/report_filter_model.dart';
import '../../shared/widgets/report_filter_bar.dart';
import '../model/customer_report_model.dart';
import '../repository/customer_report_repository.dart';

// ─────────────────────────────────────────────
// COLUMN DEFINITIONS
// ─────────────────────────────────────────────
// Order yahan = default display order. `visible` = default state.
final List<ReportColumn> customerReportColumns = [
  const ReportColumn(key: 'name', label: 'Name', minWidth: 160),
  const ReportColumn(key: 'email', label: 'Email', minWidth: 190),
  const ReportColumn(key: 'phone', label: 'Phone', minWidth: 120),
  const ReportColumn(key: 'city', label: 'City', minWidth: 100),
  const ReportColumn(key: 'rank', label: 'Rank', minWidth: 100),
  const ReportColumn(
    key: 'membershipStatus',
    label: 'Membership',
    minWidth: 110,
  ),
  const ReportColumn(
    key: 'walletBalance',
    label: 'Wallet Balance',
    minWidth: 130,
  ),
  const ReportColumn(key: 'totalPoints', label: 'Total Points', minWidth: 110),
  const ReportColumn(key: 'totalReferrals', label: 'Referrals', minWidth: 100),
  const ReportColumn(key: 'totalOrders', label: 'Orders', minWidth: 90),
  const ReportColumn(key: 'createdAt', label: 'Joined Date', minWidth: 120),

  // ── Hidden by default — toggle via column selector ──
  const ReportColumn(
    key: 'country',
    label: 'Country',
    minWidth: 100,
    visible: false,
  ),
  const ReportColumn(
    key: 'state',
    label: 'State',
    minWidth: 100,
    visible: false,
  ),
  const ReportColumn(
    key: 'address',
    label: 'Address',
    minWidth: 200,
    visible: false,
  ),
  const ReportColumn(
    key: 'myReferralCode',
    label: 'Referral Code',
    minWidth: 140,
    visible: false,
  ),
  const ReportColumn(
    key: 'referredByName',
    label: 'Referred By',
    minWidth: 140,
    visible: false,
  ),
  const ReportColumn(
    key: 'shoppingWalletBalance',
    label: 'Shopping Wallet',
    minWidth: 130,
    visible: false,
  ),
  const ReportColumn(
    key: 'totalCashbackEarned',
    label: 'Cashback Earned',
    minWidth: 130,
    visible: false,
  ),
  const ReportColumn(
    key: 'isMLMActive',
    label: 'MLM Active',
    minWidth: 100,
    visible: false,
  ),
  const ReportColumn(
    key: 'totalOrderValue',
    label: 'Order Value',
    minWidth: 130,
    visible: false,
  ),
];

// ─────────────────────────────────────────────
// SORT OPTIONS
// ─────────────────────────────────────────────
final List<ReportSortOption> customerSortOptions = [
  const ReportSortOption(key: 'createdAt', label: 'Joined Date'),
  const ReportSortOption(key: 'name', label: 'Name (A-Z)'),
  const ReportSortOption(key: 'totalReferrals', label: 'Most Referrals'),
  const ReportSortOption(key: 'totalCashbackEarned', label: 'Cashback Earned'),
  const ReportSortOption(key: 'email', label: 'Email (A-Z)'), // ✅ ADDED
  const ReportSortOption(key: 'phone', label: 'Phone'), // ✅ ADDED
  const ReportSortOption(key: 'cnicNumber', label: 'CNIC'), // ✅ ADDED
  const ReportSortOption(key: 'rank', label: 'Rank'), // ✅ ADDED
  const ReportSortOption(
    key: 'membershipStatus',
    label: 'Membership',
  ), // ✅ ADDED
  const ReportSortOption(key: 'totalPoints', label: 'Total Points'),
  const ReportSortOption(key: 'walletBalance', label: 'Wallet Balance'),
  const ReportSortOption(
    key: 'shoppingWalletBalance',
    label: 'Shopping Wallet',
  ),
  const ReportSortOption(key: 'totalOrders', label: 'Total Orders'),
  const ReportSortOption(key: 'totalOrderValue', label: 'Order Value'),
  const ReportSortOption(key: 'city', label: 'City (A-Z)'),
];

class CustomerReportController extends GetxController {
  final CustomerReportRepository _repo = CustomerReportRepository();

  // ── State ──
  var isLoading = true.obs;
  var errorMessage = ''.obs;

  var allCustomers = <CustomerReportModel>[].obs;
  var filter = CustomerReportFilter().obs;
  var columns = <ReportColumn>[].obs;

  @override
  void onInit() {
    super.onInit();
    columns.assignAll(customerReportColumns);
    fetchData();
  }

  // ── Fetch ──
  Future<void> fetchData() async {
    isLoading(true);
    errorMessage('');
    try {
      final data = await _repo.getCustomerReportData();
      allCustomers.assignAll(data);
    } catch (e) {
      errorMessage('Failed to load customers: $e');
    } finally {
      isLoading(false);
    }
  }

  void refresh() => fetchData();

  // ── Filter / column updates ──
  void updateFilter(CustomerReportFilter newFilter) {
    filter.value = newFilter;
  }

  void updateColumns(List<ReportColumn> newCols) {
    columns.assignAll(newCols);
  }

  void resetFilters() {
    filter.value = const CustomerReportFilter();
  }

  // ── Dropdown options (derived from data) ──
  List<String> get cityOptions {
    final set = allCustomers
        .map((c) => c.city.trim())
        .where((c) => c.isNotEmpty && c != 'N/A')
        .toSet()
        .toList();
    set.sort();
    return ['all', ...set];
  }

  List<String> get stateOptions {
    final set = allCustomers
        .map((c) => c.state.trim())
        .where((c) => c.isNotEmpty && c != 'N/A')
        .toSet()
        .toList();
    set.sort();
    return ['all', ...set];
  }

  List<String> get countryOptions {
    final set = allCustomers
        .map((c) => c.country.trim())
        .where((c) => c.isNotEmpty && c != 'N/A')
        .toSet()
        .toList();
    set.sort();
    return ['all', ...set];
  }

  static const List<String> membershipOptions = ['all', 'paid', 'unpaid'];
  static const List<String> mlmStatusOptions = ['all', 'active', 'inactive'];
  static const List<String> rankOptions = [
    'all',
    'Bronze',
    'Silver',
    'Gold',
    'Diamond',
  ];

  // ── Filtered + sorted list ──
  List<CustomerReportModel> get filteredCustomers {
    final f = filter.value;
    var list = allCustomers.where((c) {
      if (f.datePreset != DateRangePreset.allTime && c.createdAt != null) {
        if (c.createdAt!.isBefore(f.resolvedStart) ||
            c.createdAt!.isAfter(f.resolvedEnd)) {
          return false;
        }
      }

      if (f.searchQuery.trim().isNotEmpty) {
        final q = f.searchQuery.trim().toLowerCase();
        final matches =
            c.name.toLowerCase().contains(q) ||
            c.email.toLowerCase().contains(q) ||
            c.phone.toLowerCase().contains(q) ||
            c.cnicNumber.toLowerCase().contains(q) ||
            c.myReferralCode.toLowerCase().contains(q);
        if (!matches) return false;
      }

      if (f.city != 'all' && c.city != f.city) return false;
      if (f.state != 'all' && c.state != f.state) return false;
      if (f.country != 'all' && c.country != f.country) return false;

      // ✅ FIX: "approved" aur "paid" dono ko paid count karega
      if (f.membershipStatus != 'all') {
        bool isPaid =
            c.membershipStatus.toLowerCase() == 'paid' ||
            c.membershipStatus.toLowerCase() == 'approved';
        if (f.membershipStatus == 'paid' && !isPaid) return false;
        if (f.membershipStatus == 'unpaid' && isPaid) return false;
      }

      if (f.mlmStatus == 'active' && !c.isMLMActive) return false;
      if (f.mlmStatus == 'inactive' && c.isMLMActive) return false;

      if (f.rank != 'all' && c.rank != f.rank) return false;

      return true;
    }).toList();

    // ── Sorting (Missing columns add kiye gaye hain) ──
    if (f.sortBy.isNotEmpty) {
      list.sort((a, b) {
        int cmp;
        switch (f.sortBy) {
          case 'name':
            cmp = a.name.toLowerCase().compareTo(b.name.toLowerCase());
            break;
          case 'email': // ✅ ADDED
            cmp = a.email.toLowerCase().compareTo(b.email.toLowerCase());
            break;
          case 'phone': // ✅ ADDED
            cmp = a.phone.toLowerCase().compareTo(b.phone.toLowerCase());
            break;
          case 'cnicNumber': // ✅ ADDED
            cmp = a.cnicNumber.toLowerCase().compareTo(
              b.cnicNumber.toLowerCase(),
            );
            break;
          case 'rank': // ✅ ADDED
            cmp = a.rank.toLowerCase().compareTo(b.rank.toLowerCase());
            break;
          case 'membershipStatus': // ✅ ADDED
            cmp = a.membershipStatus.toLowerCase().compareTo(
              b.membershipStatus.toLowerCase(),
            );
            break;
          case 'city':
            cmp = a.city.toLowerCase().compareTo(b.city.toLowerCase());
            break;
          case 'createdAt':
            final ad = a.createdAt ?? DateTime(2000);
            final bd = b.createdAt ?? DateTime(2000);
            cmp = ad.compareTo(bd);
            break;
          case 'totalReferrals':
            cmp = a.totalReferrals.compareTo(b.totalReferrals);
            break;
          case 'totalOrders':
            cmp = a.totalOrders.compareTo(b.totalOrders);
            break;
          case 'totalOrderValue':
            cmp = a.totalOrderValue.compareTo(b.totalOrderValue);
            break;
          case 'totalCashbackEarned':
            cmp = a.totalCashbackEarned.compareTo(b.totalCashbackEarned);
            break;
          case 'totalPoints':
            cmp = a.totalPoints.compareTo(b.totalPoints);
            break;
          case 'walletBalance':
            cmp = a.walletBalance.compareTo(b.walletBalance);
            break;
          case 'shoppingWalletBalance':
            cmp = a.shoppingWalletBalance.compareTo(b.shoppingWalletBalance);
            break;
          default:
            cmp = 0;
        }
        return f.sortDir == SortDirection.ascending ? cmp : -cmp;
      });
    } else {
      list.sort((a, b) {
        final ad = a.createdAt ?? DateTime(2000);
        final bd = b.createdAt ?? DateTime(2000);
        return bd.compareTo(ad);
      });
    }

    return list;
  }

  List<Map<String, dynamic>> get tableRows =>
      filteredCustomers.map((c) => c.toRowMap()).toList();

  Map<String, String> get summaryStats {
    final list = filteredCustomers;
    final total = list.length;
    final activeMlm = list.where((c) => c.isMLMActive).length;
    // ✅ FIX: "approved" walo ko bhi Paid members mein count karo
    final paidMembers = list
        .where(
          (c) =>
              c.membershipStatus.toLowerCase() == 'paid' ||
              c.membershipStatus.toLowerCase() == 'approved',
        )
        .length;

    final totalWallet = list.fold<double>(0, (s, c) => s + c.walletBalance);
    final totalCashback = list.fold<double>(
      0,
      (s, c) => s + c.totalCashbackEarned,
    );
    final totalReferrals = list.fold<int>(0, (s, c) => s + c.totalReferrals);
    final totalOrders = list.fold<int>(0, (s, c) => s + c.totalOrders);

    return {
      'Total Customers': '$total',
      'Active MLM': '$activeMlm',
      'Paid Members': '$paidMembers',
      'Total Wallet': 'Rs. ${_fmt(totalWallet)}',
      'Total Cashback': 'Rs. ${_fmt(totalCashback)}',
      'Total Referrals': '$totalReferrals',
      'Total Orders': '$totalOrders',
    };
  }

  String _fmt(double v) {
    if (v >= 1000000) return '${(v / 1000000).toStringAsFixed(1)}M';
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(1)}K';
    return v.toStringAsFixed(0);
  }
}
