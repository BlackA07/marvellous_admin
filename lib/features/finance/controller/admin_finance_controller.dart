// Path: lib/features/finances/controller/admin_finance_controller.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../models/ledger_transaction_model.dart';
import '../repository/admin_finance_repository.dart';

/// AdminFinanceController
///
/// Ye controller AdminFinanceHomeScreen ke saare tabs manage karta hai:
/// - Overview tab: bank balances, totals
/// - Master ledger tab: full transaction list with filters
/// - Sadqa tab: record + history
/// - Customer Rewards tab: search customer + send reward
/// - Fines tab: history

class AdminFinanceController extends GetxController {
  final AdminFinanceRepository _repo = AdminFinanceRepository();

  // ─────────────────────────────────────────────────────────
  // DATE RANGE — shared across all tabs
  // Default: current month
  // ─────────────────────────────────────────────────────────

  late Rx<DateTime> startDate;
  late Rx<DateTime> endDate;

  @override
  void onInit() {
    super.onInit();
    final now = DateTime.now();
    startDate = DateTime(now.year, now.month, 1).obs;
    endDate = DateTime(now.year, now.month + 1, 0).obs;

    _bindStreams();
    fetchOverviewTotals();
  }

  void _bindStreams() {
    _bindLedgerStream();
    _bindBanksStream();
    _bindFinesStream();
    _bindRewardsHistoryStream();
  }

  // Date change hone par sab refresh karo
  void setDateRange(DateTime start, DateTime end) {
    startDate.value = start;
    endDate.value = end;
    _bindStreams();
    fetchOverviewTotals();
  }

  // ─────────────────────────────────────────────────────────
  // OVERVIEW
  // ─────────────────────────────────────────────────────────

  var banks = <Map<String, dynamic>>[].obs;
  var totalCompanyBalance = 0.0.obs;
  var overviewTotalIn = 0.0.obs;
  var overviewTotalOut = 0.0.obs;
  var isOverviewLoading = false.obs;

  // ✅ NAYI VARIABLES: User Wallets and Fees tracking
  var totalWalletBalance = 0.0.obs;
  var totalShoppingBalance = 0.0.obs;
  var totalPaidFees = 0.0.obs;
  var totalRemainingFees = 0.0.obs;

  void _bindBanksStream() {
    _repo.getBanksStream().listen((list) {
      banks.assignAll(list);
    });
    _repo.getTotalCompanyBalanceStream().listen((val) {
      totalCompanyBalance.value = val;
    });
  }

  Future<void> fetchOverviewTotals() async {
    isOverviewLoading.value = true;

    // Ledger sums
    final totals = await _repo.getLedgerTotals(
      startDate: startDate.value,
      endDate: endDate.value,
    );
    overviewTotalIn.value = totals['totalIn'] ?? 0.0;
    overviewTotalOut.value = totals['totalOut'] ?? 0.0;

    // Fetching Customer Aggregates
    final customerStats = await _repo.getCustomerAggregates();
    totalWalletBalance.value = customerStats['totalWalletBalance'] ?? 0.0;
    totalShoppingBalance.value = customerStats['totalShoppingBalance'] ?? 0.0;
    totalPaidFees.value = customerStats['totalPaidFees'] ?? 0.0;
    totalRemainingFees.value = customerStats['totalRemainingFees'] ?? 0.0;

    isOverviewLoading.value = false;
  }

  // ─────────────────────────────────────────────────────────
  // MASTER LEDGER
  // ─────────────────────────────────────────────────────────

  var allLedgerEntries = <LedgerTransactionModel>[].obs;
  var filteredLedgerEntries = <LedgerTransactionModel>[].obs;
  var isLedgerLoading = false.obs;

  // Filters — client side
  var filterType = 'all'.obs; // 'all' | 'in' | 'out'
  var filterCategory = ''.obs; // '' = all
  var filterPaymentMethod = ''.obs; // '' = all
  var searchQuery = ''.obs;

  void _bindLedgerStream() {
    isLedgerLoading.value = true;
    _repo
        .getLedgerStream(startDate: startDate.value, endDate: endDate.value)
        .listen((entries) {
          allLedgerEntries.assignAll(entries);
          applyLedgerFilters();
          isLedgerLoading.value = false;
        });
  }

  void applyLedgerFilters() {
    var list = allLedgerEntries.toList();

    // Type filter
    if (filterType.value != 'all') {
      list = list.where((e) => e.type == filterType.value).toList();
    }

    // Category filter
    if (filterCategory.value.isNotEmpty) {
      list = list.where((e) => e.category == filterCategory.value).toList();
    }

    // Payment method filter
    if (filterPaymentMethod.value.isNotEmpty) {
      list = list
          .where((e) => e.paymentMethod == filterPaymentMethod.value)
          .toList();
    }

    // Search filter
    final q = searchQuery.value.trim().toLowerCase();
    if (q.isNotEmpty) {
      list = list.where((e) {
        return (e.linkedUserName?.toLowerCase().contains(q) ?? false) ||
            (e.linkedUserPhone?.toLowerCase().contains(q) ?? false) ||
            (e.linkedUserEmail?.toLowerCase().contains(q) ?? false) ||
            (e.linkedVendorName?.toLowerCase().contains(q) ?? false) ||
            (e.linkedStaffName?.toLowerCase().contains(q) ?? false) ||
            (e.linkedOrderId?.toLowerCase().contains(q) ?? false) ||
            e.description.toLowerCase().contains(q) ||
            (e.bankName?.toLowerCase().contains(q) ?? false);
      }).toList();
    }

    filteredLedgerEntries.assignAll(list);
  }

  double get ledgerTotalIn {
    return filteredLedgerEntries
        .where((e) => e.type == 'in')
        .fold(0.0, (sum, e) => sum + e.amount);
  }

  double get ledgerTotalOut {
    return filteredLedgerEntries
        .where((e) => e.type == 'out')
        .fold(0.0, (sum, e) => sum + e.amount);
  }

  void resetLedgerFilters() {
    filterType.value = 'all';
    filterCategory.value = '';
    filterPaymentMethod.value = '';
    searchQuery.value = '';
    applyLedgerFilters();
  }

  // ─────────────────────────────────────────────────────────
  // SADQA
  // ─────────────────────────────────────────────────────────

  var isSadqaSubmitting = false.obs;
  var sadqaEntries = <LedgerTransactionModel>[].obs;

  void _bindSadqaFromLedger() {
    ever(allLedgerEntries, (_) {
      sadqaEntries.assignAll(
        allLedgerEntries.where((e) => e.category == kCatSadqa).toList(),
      );
    });
  }

  Future<bool> submitSadqa({
    required double amount,
    required String paymentMethod,
    required String description,
    required DateTime date,
    String? bankId,
    String? bankName,
    String? chequeNumber,
    DateTime? chequeDate,
    String? screenshotBase64,
  }) async {
    isSadqaSubmitting.value = true;
    final success = await _repo.recordSadqa(
      amount: amount,
      paymentMethod: paymentMethod,
      description: description,
      date: date,
      bankId: bankId,
      bankName: bankName,
      chequeNumber: chequeNumber,
      chequeDate: chequeDate,
      screenshotBase64: screenshotBase64,
    );
    isSadqaSubmitting.value = false;

    if (success) {
      Get.snackbar(
        'Sadqa Recorded ✅',
        'Rs.${amount.toStringAsFixed(0)} sadqa recorded.',
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } else {
      Get.snackbar(
        'Error ❌',
        'Failed to record sadqa. Please try again.',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
    return success;
  }

  // ─────────────────────────────────────────────────────────
  // CUSTOMER REWARDS
  // ─────────────────────────────────────────────────────────

  var isSearchingCustomer = false.obs;
  var customerSearchResults = <Map<String, dynamic>>[].obs;
  var selectedCustomer = Rxn<Map<String, dynamic>>();
  var isRewardSubmitting = false.obs;

  var rewardsHistory = <Map<String, dynamic>>[].obs;

  void _bindRewardsHistoryStream() {
    // ✅ FIX: Rewards History ko bhi ALL TIME hardcode kar diya
    _repo
        .getRewardsHistoryStream(
          startDate: DateTime(2000, 1, 1),
          endDate: DateTime(2100, 12, 31),
        )
        .listen((list) {
          rewardsHistory.assignAll(list);
        });
  }

  Future<void> searchCustomers(String query) async {
    if (query.trim().length < 2) {
      customerSearchResults.clear();
      return;
    }
    isSearchingCustomer.value = true;
    final results = await _repo.searchCustomers(query);
    customerSearchResults.assignAll(results);
    isSearchingCustomer.value = false;
  }

  void selectCustomer(Map<String, dynamic> customer) {
    selectedCustomer.value = customer;
    customerSearchResults.clear();
  }

  void clearCustomerSelection() {
    selectedCustomer.value = null;
    customerSearchResults.clear();
  }

  Future<bool> submitCustomerReward({
    required double amount,
    required String bankId,
    required String bankName,
    required String note,
    required DateTime date,
  }) async {
    final customer = selectedCustomer.value;
    if (customer == null) {
      Get.snackbar(
        'Error',
        'Pehle customer select karo.',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return false;
    }

    if (amount <= 0) {
      Get.snackbar(
        'Error',
        'Valid amount enter karo.',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return false;
    }

    isRewardSubmitting.value = true;
    final success = await _repo.processCustomerReward(
      userId: customer['id'],
      userName: customer['name'],
      userPhone: customer['phone'] ?? '',
      userEmail: customer['email'] ?? '',
      amount: amount,
      bankId: bankId,
      bankName: bankName,
      note: note,
      date: date,
    );
    isRewardSubmitting.value = false;

    if (success) {
      clearCustomerSelection();
      Get.snackbar(
        'Reward Sent ✅',
        'Rs.${amount.toStringAsFixed(0)} sent to ${customer['name']}.',
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } else {
      Get.snackbar(
        'Failed ❌',
        'Reward send karne mein error. Dobara try karo.',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
    return success;
  }

  // ─────────────────────────────────────────────────────────
  // FINES HISTORY
  // ─────────────────────────────────────────────────────────

  var finesEntries = <LedgerTransactionModel>[].obs;
  var finesSearchQuery = ''.obs;
  var filteredFinesEntries = <LedgerTransactionModel>[].obs;

  void _bindFinesStream() {
    // ✅ FIX: Fines History ko ALL TIME fetch karwaya taake date change se ghaib na ho
    _repo
        .getFinesStream(
          startDate: DateTime(2000, 1, 1),
          endDate: DateTime(2100, 12, 31),
        )
        .listen((entries) {
          finesEntries.assignAll(entries);
          applyFinesFilter();
        });
  }

  void applyFinesFilter() {
    final q = finesSearchQuery.value.trim().toLowerCase();
    if (q.isEmpty) {
      filteredFinesEntries.assignAll(finesEntries);
      return;
    }
    filteredFinesEntries.assignAll(
      finesEntries.where((e) {
        return (e.linkedUserName?.toLowerCase().contains(q) ?? false) ||
            (e.linkedUserPhone?.toLowerCase().contains(q) ?? false) ||
            (e.linkedUserEmail?.toLowerCase().contains(q) ?? false) ||
            e.description.toLowerCase().contains(q);
      }).toList(),
    );
  }

  // ─────────────────────────────────────────────────────────
  // HELPERS — ✅ YEH WAPIS AA GAYE HAIN (DO NOT REMOVE)
  // ─────────────────────────────────────────────────────────

  /// Human-readable category label
  static String categoryLabel(String cat) {
    const labels = {
      kCatProductPurchaseCod: 'Product Purchase (COD)',
      kCatProductPurchaseOnline: 'Product Purchase (Online)',
      kCatProductPurchaseWallet: 'Product Purchase (Wallet)',
      kCatRegistrationFee: 'Registration Fee',
      kCatPlatformFee: 'Platform/Milestone Fee',
      kCatFine: 'Fine / Penalty',
      kCatVendorPayment: 'Vendor Payment',
      kCatExpense: 'Expense',
      kCatSadqa: 'Sadqa / Charity',
      kCatSalary: 'Salary',
      kCatCustomerWithdrawal: 'Customer Withdrawal',
      kCatGovernmentTax: 'Government Tax',
      kCatCustomerReward: 'Customer Reward',
      kCatBankTransfer: 'Bank Transfer',
    };
    return labels[cat] ?? cat;
  }

  static String paymentMethodLabel(String method) {
    const labels = {
      kPayCash: 'Cash',
      kPayOnline: 'Online',
      kPayCheque: 'Cheque',
      kPayMainWallet: 'Main Wallet',
      kPayShoppingWallet: 'Shopping Wallet',
    };
    return labels[method] ?? method;
  }

  /// All category values for dropdown
  static List<String> get allCategories => [
    kCatProductPurchaseCod,
    kCatProductPurchaseOnline,
    kCatProductPurchaseWallet,
    kCatRegistrationFee,
    kCatPlatformFee,
    kCatFine,
    kCatVendorPayment,
    kCatExpense,
    kCatSadqa,
    kCatSalary,
    kCatCustomerWithdrawal,
    kCatGovernmentTax,
    kCatCustomerReward,
    kCatBankTransfer,
  ];

  static List<String> get allPaymentMethods => [
    kPayCash,
    kPayOnline,
    kPayCheque,
    kPayMainWallet,
    kPayShoppingWallet,
  ];
}
