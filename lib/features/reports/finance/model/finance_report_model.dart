// lib/features/reports/finance/model/finance_report_model.dart
//
// FinanceReportModel = LedgerTransactionModel flattened for the report table,
// with human-readable category & payment method labels.

// ─────────────────────────────────────────────
// CATEGORY LABELS (matches kCat* constants in ledger_transaction_model.dart)
// ─────────────────────────────────────────────
const Map<String, String> financeCategoryLabels = {
  // IN side
  'product_purchase_cod': 'Product Sale (COD)',
  'product_purchase_online': 'Product Sale (Online)',
  'product_purchase_wallet': 'Product Sale (Wallet)',
  'registration_fee': 'Registration Fee',
  'platform_fee': 'Platform Fee',
  'fine': 'Fine / Penalty',
  'vendor_payment_refund': 'Vendor Payment Refund',

  // OUT side
  'vendor_payment': 'Vendor Payment',
  'expense': 'Expense',
  'sadqa': 'Sadqa / Charity',
  'salary': 'Salary',
  'customer_withdrawal': 'Customer Withdrawal',
  'government_tax': 'Government Tax',
  'customer_reward': 'Customer Reward',
  'bank_transfer': 'Bank Transfer',
};

String financeCategoryLabel(String category) =>
    financeCategoryLabels[category] ?? category;

// ─────────────────────────────────────────────
// PAYMENT METHOD LABELS
// ─────────────────────────────────────────────
const Map<String, String> financePaymentMethodLabels = {
  'cash': 'Cash',
  'Cash': 'Cash',
  'online': 'Online',
  'Bank Transfer': 'Bank Transfer', // ✅ Added
  'cheque': 'Cheque',
  'Cheque': 'Cheque', // ✅ Added
  'main_wallet': 'Main Wallet',
  'shopping_wallet': 'Shopping Wallet',
};

String financePaymentMethodLabel(String method) =>
    financePaymentMethodLabels[method] ?? method;

// ─────────────────────────────────────────────
// FINANCE REPORT MODEL
// ─────────────────────────────────────────────
class FinanceReportModel {
  final String id;
  final String type; // 'in' | 'out'
  final String category; // raw category key
  final double amount;
  final String paymentMethod;

  final String? bankName;
  final String? chequeNumber;
  final DateTime? chequeDate;

  final String description;

  // Linked entity (whichever is present)
  final String? linkedUserName;
  final String? linkedUserPhone;
  final String? linkedUserEmail;
  final String? linkedVendorName;
  final String? linkedStaffName;
  final String? linkedOrderId;

  // Order breakdown (optional)
  final double? subTotal;
  final double? shippingFee;
  final double? codCharges;
  final double? grossProfit;

  final String createdBy; // 'admin' | 'system'
  final DateTime date;
  final DateTime createdAt;

  const FinanceReportModel({
    required this.id,
    required this.type,
    required this.category,
    required this.amount,
    required this.paymentMethod,
    required this.bankName,
    required this.chequeNumber,
    required this.chequeDate,
    required this.description,
    required this.linkedUserName,
    required this.linkedUserPhone,
    required this.linkedUserEmail,
    required this.linkedVendorName,
    required this.linkedStaffName,
    required this.linkedOrderId,
    required this.subTotal,
    required this.shippingFee,
    required this.codCharges,
    required this.grossProfit,
    required this.createdBy,
    required this.date,
    required this.createdAt,
  });

  /// Resolved linked entity name — whichever of user/vendor/staff is set.
  String get linkedName {
    if (linkedUserName != null && linkedUserName!.isNotEmpty)
      return linkedUserName!;
    if (linkedVendorName != null && linkedVendorName!.isNotEmpty)
      return linkedVendorName!;
    if (linkedStaffName != null && linkedStaffName!.isNotEmpty)
      return linkedStaffName!;
    return '—';
  }

  /// Resolved linked entity type — 'customer' | 'vendor' | 'staff' | 'none'.
  String get linkedType {
    if (linkedUserName != null && linkedUserName!.isNotEmpty) return 'customer';
    if (linkedVendorName != null && linkedVendorName!.isNotEmpty)
      return 'vendor';
    if (linkedStaffName != null && linkedStaffName!.isNotEmpty) return 'staff';
    return 'none';
  }

  /// Converts to a flat map for the report table / PDF / CSV export.
  /// Keys here MUST match the `key` values in `financeReportColumns`.
  Map<String, dynamic> toRowMap() {
    return {
      'date': date,
      'type': type,
      'categoryLabel': financeCategoryLabel(category),
      'amount': amount,
      'paymentMethod': financePaymentMethodLabel(paymentMethod),
      'bankName': bankName?.isNotEmpty == true ? bankName : '—',
      'linkedName': linkedName,
      'linkedType': linkedType,
      'description': description.isEmpty ? '—' : description,
      'createdBy': createdBy,

      // Hidden by default
      'linkedUserPhone': linkedUserPhone?.isNotEmpty == true
          ? linkedUserPhone
          : '—',
      'linkedUserEmail': linkedUserEmail?.isNotEmpty == true
          ? linkedUserEmail
          : '—',
      'chequeNumber': chequeNumber?.isNotEmpty == true ? chequeNumber : '—',
      'chequeDate': chequeDate,
      'subTotal': subTotal ?? 0.0,
      'shippingFee': shippingFee ?? 0.0,
      'codCharges': codCharges ?? 0.0,
      'grossProfit': grossProfit ?? 0.0,
      'linkedOrderId': linkedOrderId?.isNotEmpty == true ? linkedOrderId : '—',
      'createdAt': createdAt,
    };
  }
}
