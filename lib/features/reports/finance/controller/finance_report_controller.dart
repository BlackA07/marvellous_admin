// lib/features/reports/finance/controller/finance_report_controller.dart
//
// GetX controller — finance report ka poora state management.
//
// IMPORTANT: Date range Firestore query mein server-side filter hota hai,
// isliye jab bhi date range badle, hum fresh fetchData() call karte hain.
// Baaki filters (type/category/paymentMethod/linkedEntity/search) client-side
// instantly apply hote hain — koi refetch nahi.

import 'package:get/get.dart';
import '../../shared/models/report_filter_model.dart';
import '../../shared/widgets/report_filter_bar.dart';
import '../model/finance_report_model.dart';
import '../repository/finance_report_repository.dart';

// ─────────────────────────────────────────────
// COLUMN DEFINITIONS
// ─────────────────────────────────────────────
final List<ReportColumn> financeReportColumns = [
  const ReportColumn(key: 'date', label: 'Date', minWidth: 110),
  const ReportColumn(key: 'type', label: 'Type', minWidth: 80),
  const ReportColumn(key: 'categoryLabel', label: 'Category', minWidth: 170),
  const ReportColumn(key: 'amount', label: 'Amount', minWidth: 120),
  const ReportColumn(
    key: 'paymentMethod',
    label: 'Payment Method',
    minWidth: 130,
  ),
  const ReportColumn(key: 'bankName', label: 'Bank', minWidth: 130),
  const ReportColumn(key: 'linkedName', label: 'Linked To', minWidth: 150),
  const ReportColumn(key: 'linkedType', label: 'Linked Type', minWidth: 110),
  const ReportColumn(key: 'description', label: 'Description', minWidth: 220),
  const ReportColumn(key: 'createdBy', label: 'Created By', minWidth: 100),

  // ── Hidden by default — toggle via column selector ──
  const ReportColumn(
    key: 'linkedUserPhone',
    label: 'Linked Phone',
    minWidth: 130,
    visible: false,
  ),
  const ReportColumn(
    key: 'linkedUserEmail',
    label: 'Linked Email',
    minWidth: 180,
    visible: false,
  ),
  const ReportColumn(
    key: 'chequeNumber',
    label: 'Cheque Number',
    minWidth: 130,
    visible: false,
  ),
  const ReportColumn(
    key: 'chequeDate',
    label: 'Cheque Date',
    minWidth: 120,
    visible: false,
  ),
  const ReportColumn(
    key: 'subTotal',
    label: 'Sub Total',
    minWidth: 110,
    visible: false,
  ),
  const ReportColumn(
    key: 'shippingFee',
    label: 'Shipping Fee',
    minWidth: 110,
    visible: false,
  ),
  const ReportColumn(
    key: 'codCharges',
    label: 'COD Charges',
    minWidth: 110,
    visible: false,
  ),
  const ReportColumn(
    key: 'grossProfit',
    label: 'Gross Profit',
    minWidth: 120,
    visible: false,
  ),
  const ReportColumn(
    key: 'linkedOrderId',
    label: 'Order ID',
    minWidth: 130,
    visible: false,
  ),
  const ReportColumn(
    key: 'createdAt',
    label: 'Recorded At',
    minWidth: 120,
    visible: false,
  ),
];

// ─────────────────────────────────────────────
// SORT OPTIONS
// ─────────────────────────────────────────────
final List<ReportSortOption> financeSortOptions = [
  const ReportSortOption(key: 'date', label: 'Date'),
  const ReportSortOption(key: 'type', label: 'Type (IN/OUT)'),
  const ReportSortOption(key: 'categoryLabel', label: 'Category'),
  const ReportSortOption(key: 'amount', label: 'Amount'),
  const ReportSortOption(key: 'paymentMethod', label: 'Payment Method'),
  const ReportSortOption(key: 'bankName', label: 'Bank Name'),
  const ReportSortOption(key: 'linkedName', label: 'Linked To'),
  const ReportSortOption(key: 'linkedType', label: 'Linked Type'),
  const ReportSortOption(key: 'description', label: 'Description (A-Z)'),
  const ReportSortOption(key: 'createdBy', label: 'Created By'),
  const ReportSortOption(key: 'linkedUserPhone', label: 'Linked Phone'),
  const ReportSortOption(key: 'linkedUserEmail', label: 'Linked Email'),
  const ReportSortOption(key: 'chequeNumber', label: 'Cheque Number'),
  const ReportSortOption(key: 'chequeDate', label: 'Cheque Date'),
  const ReportSortOption(key: 'subTotal', label: 'Sub Total'),
  const ReportSortOption(key: 'shippingFee', label: 'Shipping Fee'),
  const ReportSortOption(key: 'codCharges', label: 'COD Charges'),
  const ReportSortOption(key: 'grossProfit', label: 'Gross Profit'),
  const ReportSortOption(key: 'linkedOrderId', label: 'Order ID'),
  const ReportSortOption(key: 'createdAt', label: 'Recorded At'),
];

// ─────────────────────────────────────────────
// CATEGORY GROUPS (IN / OUT)
// ─────────────────────────────────────────────
const List<String> financeInCategories = [
  'product_purchase_cod',
  'product_purchase_online',
  'product_purchase_wallet',
  'registration_fee',
  'platform_fee',
  'fine',
  'vendor_payment_refund',
];

const List<String> financeOutCategories = [
  'vendor_payment',
  'expense',
  'sadqa',
  'salary',
  'customer_withdrawal',
  'government_tax',
  'customer_reward',
  'bank_transfer',
];

class FinanceReportController extends GetxController {
  final FinanceReportRepository _repo = FinanceReportRepository();

  // ── State ──
  var isLoading = true.obs;
  var errorMessage = ''.obs;

  var allTransactions = <FinanceReportModel>[].obs;
  var filter = FinanceReportFilter().obs;
  var columns = <ReportColumn>[].obs;

  @override
  void onInit() {
    super.onInit();
    columns.assignAll(financeReportColumns);
    fetchData();
  }

  // ── Fetch (uses current filter's resolved date range) ──
  Future<void> fetchData() async {
    isLoading(true);
    errorMessage('');
    try {
      final data = await _repo.getLedgerData(
        startDate: filter.value.resolvedStart,
        endDate: filter.value.resolvedEnd,
      );
      allTransactions.assignAll(data);
    } catch (e) {
      errorMessage('Failed to load finance data: $e');
    } finally {
      isLoading(false);
    }
  }

  void refresh() => fetchData();

  // ── Filter / column updates ──
  // Date range changes require a fresh Firestore query (server-side filter).
  // All other filter changes are instant (client-side).
  void updateFilter(FinanceReportFilter newFilter) {
    final oldStart = filter.value.resolvedStart;
    final oldEnd = filter.value.resolvedEnd;
    final newStart = newFilter.resolvedStart;
    final newEnd = newFilter.resolvedEnd;

    final dateChanged = oldStart != newStart || oldEnd != newEnd;

    filter.value = newFilter;

    if (dateChanged) {
      fetchData();
    }
  }

  void updateColumns(List<ReportColumn> newCols) {
    columns.assignAll(newCols);
  }

  void resetFilters() {
    final wasCustomRange = filter.value.datePreset != DateRangePreset.thisMonth;
    filter.value = const FinanceReportFilter();
    if (wasCustomRange) fetchData();
  }

  // ── Dropdown options ──
  static const List<String> transactionTypeOptions = ['all', 'in', 'out'];

  static const List<String> paymentMethodOptions = [
    'all',
    'cash',
    'online',
    'cheque',
    'main_wallet',
    'shopping_wallet',
  ];

  static const List<String> linkedEntityOptions = [
    'all',
    'customer',
    'vendor',
    'staff',
    'none',
  ];

  /// Category options depend on the selected transaction type.
  List<String> get categoryOptions {
    List<String> cats;
    switch (filter.value.transactionType) {
      case 'in':
        cats = financeInCategories;
        break;
      case 'out':
        cats = financeOutCategories;
        break;
      default:
        cats = [...financeInCategories, ...financeOutCategories];
    }
    return ['all', ...cats];
  }

  // ── Filtered + sorted list ──
  List<FinanceReportModel> get filteredTransactions {
    final f = filter.value;
    var list = allTransactions.where((t) {
      if (f.searchQuery.trim().isNotEmpty) {
        final q = f.searchQuery.trim().toLowerCase();
        final matches =
            t.description.toLowerCase().contains(q) ||
            t.linkedName.toLowerCase().contains(q) ||
            financeCategoryLabel(t.category).toLowerCase().contains(q) ||
            (t.linkedUserPhone ?? '').toLowerCase().contains(q) ||
            (t.linkedUserEmail ?? '').toLowerCase().contains(q) ||
            (t.linkedOrderId ?? '').toLowerCase().contains(q);
        if (!matches) return false;
      }

      if (f.transactionType != 'all' && t.type != f.transactionType)
        return false;
      if (f.category != 'all' && t.category != f.category) return false;
      // ✅ FIX: ignore case for payment method
      if (f.paymentMethod != 'all' &&
          t.paymentMethod.toLowerCase() != f.paymentMethod.toLowerCase())
        return false;
      if (f.linkedEntity != 'all' && t.linkedType != f.linkedEntity)
        return false;

      return true;
    }).toList();

    // ── Sorting Logic for ALL Columns ──
    if (f.sortBy.isNotEmpty) {
      list.sort((a, b) {
        int cmp;
        switch (f.sortBy) {
          case 'date':
            cmp = a.date.compareTo(b.date);
            break;
          case 'type':
            cmp = a.type.compareTo(b.type);
            break;
          case 'categoryLabel':
            cmp = financeCategoryLabel(
              a.category,
            ).compareTo(financeCategoryLabel(b.category));
            break;
          case 'amount':
            cmp = a.amount.compareTo(b.amount);
            break;
          case 'paymentMethod':
            cmp = a.paymentMethod.compareTo(b.paymentMethod);
            break;
          case 'bankName':
            cmp = (a.bankName ?? '').compareTo(b.bankName ?? '');
            break;
          case 'linkedName':
            cmp = a.linkedName.compareTo(b.linkedName);
            break;
          case 'linkedType':
            cmp = a.linkedType.compareTo(b.linkedType);
            break;
          case 'description':
            cmp = a.description.toLowerCase().compareTo(
              b.description.toLowerCase(),
            );
            break;
          case 'createdBy':
            cmp = a.createdBy.compareTo(b.createdBy);
            break;
          case 'linkedUserPhone':
            cmp = (a.linkedUserPhone ?? '').compareTo(b.linkedUserPhone ?? '');
            break;
          case 'linkedUserEmail':
            cmp = (a.linkedUserEmail ?? '').compareTo(b.linkedUserEmail ?? '');
            break;
          case 'chequeNumber':
            cmp = (a.chequeNumber ?? '').compareTo(b.chequeNumber ?? '');
            break;
          case 'chequeDate':
            cmp = (a.chequeDate ?? DateTime(2000)).compareTo(
              b.chequeDate ?? DateTime(2000),
            );
            break;
          case 'subTotal':
            cmp = (a.subTotal ?? 0).compareTo(b.subTotal ?? 0);
            break;
          case 'shippingFee':
            cmp = (a.shippingFee ?? 0).compareTo(b.shippingFee ?? 0);
            break;
          case 'codCharges':
            cmp = (a.codCharges ?? 0).compareTo(b.codCharges ?? 0);
            break;
          case 'grossProfit':
            cmp = (a.grossProfit ?? 0).compareTo(b.grossProfit ?? 0);
            break;
          case 'linkedOrderId':
            cmp = (a.linkedOrderId ?? '').compareTo(b.linkedOrderId ?? '');
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
      // Default: newest first
      list.sort((a, b) => b.date.compareTo(a.date));
    }

    return list;
  }

  // ── Table rows for export/display ──
  List<Map<String, dynamic>> get tableRows =>
      filteredTransactions.map((t) => t.toRowMap()).toList();

  // ── Summary stats (top cards + PDF header) ──
  Map<String, String> get summaryStats {
    final list = filteredTransactions;
    final totalIn = list
        .where((t) => t.type == 'in')
        .fold<double>(0, (s, t) => s + t.amount);
    final totalOut = list
        .where((t) => t.type == 'out')
        .fold<double>(0, (s, t) => s + t.amount);
    final net = totalIn - totalOut;
    final totalProfit = list.fold<double>(
      0,
      (s, t) => s + (t.grossProfit ?? 0),
    );
    final inCount = list.where((t) => t.type == 'in').length;
    final outCount = list.where((t) => t.type == 'out').length;

    return {
      'Total In': 'Rs. ${_fmt(totalIn)}',
      'Total Out': 'Rs. ${_fmt(totalOut)}',
      'Net Balance': 'Rs. ${_fmt(net)}',
      'Gross Profit': 'Rs. ${_fmt(totalProfit)}',
      'IN Entries': '$inCount',
      'OUT Entries': '$outCount',
      'Total Entries': '${list.length}',
    };
  }

  String _fmt(double v) {
    final neg = v < 0;
    final av = v.abs();
    String s;
    if (av >= 1000000) {
      s = '${(av / 1000000).toStringAsFixed(1)}M';
    } else if (av >= 1000) {
      s = '${(av / 1000).toStringAsFixed(1)}K';
    } else {
      s = av.toStringAsFixed(0);
    }
    return neg ? '-$s' : s;
  }
}
