// Path: lib/features/finances/models/ledger_transaction_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

/// Firestore collection: admin_ledger_transactions
///
/// Har cheez jo paise move karti hai — IN ya OUT —
/// is model ke zariye record hoti hai.
///
/// createdBy = 'system' jab automatic (order deliver, withdrawal approve, etc.)
/// createdBy = 'admin'  jab admin manually kuch add karta hai (sadqa, reward, fine, etc.)

class LedgerTransactionModel {
  final String? id;

  /// 'in' ya 'out'
  final String type;

  /// Category — kahan se aya ya kahan gaya
  /// Values:
  ///   IN  side: 'product_purchase_cod', 'product_purchase_online',
  ///             'product_purchase_wallet', 'registration_fee',
  ///             'platform_fee', 'fine', 'vendor_payment_refund'
  ///   OUT side: 'vendor_payment', 'expense', 'sadqa', 'salary',
  ///             'customer_withdrawal', 'government_tax', 'customer_reward',
  ///             'bank_transfer'
  final String category;

  final double amount;

  /// 'cash' | 'online' | 'cheque' | 'main_wallet' | 'shopping_wallet'
  final String paymentMethod;

  // Bank details (agar online/cheque)
  final String? bankId;
  final String? bankName;

  // Cheque details
  final String? chequeNumber;
  final DateTime? chequeDate;

  // Screenshot (base64) — deposit confirm, sadqa receipt, etc.
  final String? screenshotBase64;

  /// Human-readable description
  final String description;

  // Linked entities — jitne available hon utne bharo
  final String? linkedUserId;
  final String? linkedUserName;
  final String? linkedUserPhone;
  final String? linkedUserEmail;

  final String? linkedVendorId;
  final String? linkedVendorName;

  final String? linkedStaffId;
  final String? linkedStaffName;

  final String? linkedOrderId;

  // ── NEW FIELDS FOR ORDER BREAKDOWN ──
  final double? subTotal;
  final double? shippingFee;
  final double? codCharges;
  final double? grossProfit;

  /// 'admin' ya 'system'
  final String createdBy;

  /// Transaction ki actual date (admin choose kar sakta hai)
  final DateTime date;

  /// Jab Firestore mein likha gaya
  final DateTime createdAt;

  LedgerTransactionModel({
    this.id,
    required this.type,
    required this.category,
    required this.amount,
    required this.paymentMethod,
    this.bankId,
    this.bankName,
    this.chequeNumber,
    this.chequeDate,
    this.screenshotBase64,
    required this.description,
    this.linkedUserId,
    this.linkedUserName,
    this.linkedUserPhone,
    this.linkedUserEmail,
    this.linkedVendorId,
    this.linkedVendorName,
    this.linkedStaffId,
    this.linkedStaffName,
    this.linkedOrderId,
    this.subTotal,
    this.shippingFee,
    this.codCharges,
    this.grossProfit,
    required this.createdBy,
    required this.date,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'type': type,
      'category': category,
      'amount': amount,
      'paymentMethod': paymentMethod,
      'description': description,
      'createdBy': createdBy,
      'date': Timestamp.fromDate(date),
      'createdAt': Timestamp.fromDate(createdAt),
    };

    // Optional fields — sirf tab add karo jab value ho
    if (bankId != null && bankId!.isNotEmpty) map['bankId'] = bankId;
    if (bankName != null && bankName!.isNotEmpty) map['bankName'] = bankName;
    if (chequeNumber != null && chequeNumber!.isNotEmpty) {
      map['chequeNumber'] = chequeNumber;
    }
    if (chequeDate != null) {
      map['chequeDate'] = Timestamp.fromDate(chequeDate!);
    }
    if (screenshotBase64 != null && screenshotBase64!.isNotEmpty) {
      map['screenshotBase64'] = screenshotBase64;
    }

    if (linkedUserId != null && linkedUserId!.isNotEmpty) {
      map['linkedUserId'] = linkedUserId;
    }
    if (linkedUserName != null && linkedUserName!.isNotEmpty) {
      map['linkedUserName'] = linkedUserName;
    }
    if (linkedUserPhone != null && linkedUserPhone!.isNotEmpty) {
      map['linkedUserPhone'] = linkedUserPhone;
    }
    if (linkedUserEmail != null && linkedUserEmail!.isNotEmpty) {
      map['linkedUserEmail'] = linkedUserEmail;
    }

    if (linkedVendorId != null && linkedVendorId!.isNotEmpty) {
      map['linkedVendorId'] = linkedVendorId;
    }
    if (linkedVendorName != null && linkedVendorName!.isNotEmpty) {
      map['linkedVendorName'] = linkedVendorName;
    }

    if (linkedStaffId != null && linkedStaffId!.isNotEmpty) {
      map['linkedStaffId'] = linkedStaffId;
    }
    if (linkedStaffName != null && linkedStaffName!.isNotEmpty) {
      map['linkedStaffName'] = linkedStaffName;
    }

    if (linkedOrderId != null && linkedOrderId!.isNotEmpty) {
      map['linkedOrderId'] = linkedOrderId;
    }

    // New Fields
    if (subTotal != null) map['subTotal'] = subTotal;
    if (shippingFee != null) map['shippingFee'] = shippingFee;
    if (codCharges != null) map['codCharges'] = codCharges;
    if (grossProfit != null) map['grossProfit'] = grossProfit;

    return map;
  }

  factory LedgerTransactionModel.fromMap(
    Map<String, dynamic> map,
    String docId,
  ) {
    return LedgerTransactionModel(
      id: docId,
      type: map['type'] ?? 'in',
      category: map['category'] ?? '',
      amount: (map['amount'] ?? 0.0).toDouble(),
      paymentMethod: map['paymentMethod'] ?? 'cash',
      bankId: map['bankId'],
      bankName: map['bankName'],
      chequeNumber: map['chequeNumber'],
      chequeDate: map['chequeDate'] != null
          ? (map['chequeDate'] as Timestamp).toDate()
          : null,
      screenshotBase64: map['screenshotBase64'],
      description: map['description'] ?? '',
      linkedUserId: map['linkedUserId'],
      linkedUserName: map['linkedUserName'],
      linkedUserPhone: map['linkedUserPhone'],
      linkedUserEmail: map['linkedUserEmail'],
      linkedVendorId: map['linkedVendorId'],
      linkedVendorName: map['linkedVendorName'],
      linkedStaffId: map['linkedStaffId'],
      linkedStaffName: map['linkedStaffName'],
      linkedOrderId: map['linkedOrderId'],
      subTotal: map['subTotal'] != null
          ? (map['subTotal'] as num).toDouble()
          : null,
      shippingFee: map['shippingFee'] != null
          ? (map['shippingFee'] as num).toDouble()
          : null,
      codCharges: map['codCharges'] != null
          ? (map['codCharges'] as num).toDouble()
          : null,
      grossProfit: map['grossProfit'] != null
          ? (map['grossProfit'] as num).toDouble()
          : null,
      createdBy: map['createdBy'] ?? 'system',
      date: map['date'] != null
          ? (map['date'] as Timestamp).toDate()
          : DateTime.now(),
      createdAt: map['createdAt'] != null
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  /// Helper — system transactions banane ke liye shortcut
  factory LedgerTransactionModel.system({
    required String type,
    required String category,
    required double amount,
    required String paymentMethod,
    required String description,
    String? bankId,
    String? bankName,
    String? linkedUserId,
    String? linkedUserName,
    String? linkedUserPhone,
    String? linkedUserEmail,
    String? linkedVendorId,
    String? linkedVendorName,
    String? linkedOrderId,
    double? subTotal,
    double? shippingFee,
    double? codCharges,
    double? grossProfit,
  }) {
    final now = DateTime.now();
    return LedgerTransactionModel(
      type: type,
      category: category,
      amount: amount,
      paymentMethod: paymentMethod,
      description: description,
      bankId: bankId,
      bankName: bankName,
      linkedUserId: linkedUserId,
      linkedUserName: linkedUserName,
      linkedUserPhone: linkedUserPhone,
      linkedUserEmail: linkedUserEmail,
      linkedVendorId: linkedVendorId,
      linkedVendorName: linkedVendorName,
      linkedOrderId: linkedOrderId,
      subTotal: subTotal,
      shippingFee: shippingFee,
      codCharges: codCharges,
      grossProfit: grossProfit,
      createdBy: 'system',
      date: now,
      createdAt: now,
    );
  }
}

/// Valid category values — reference ke liye
const String kCatProductPurchaseCod = 'product_purchase_cod';
const String kCatProductPurchaseOnline = 'product_purchase_online';
const String kCatProductPurchaseWallet = 'product_purchase_wallet';
const String kCatRegistrationFee = 'registration_fee';
const String kCatPlatformFee = 'platform_fee';
const String kCatFine = 'fine';

const String kCatVendorPayment = 'vendor_payment';
const String kCatExpense = 'expense';
const String kCatSadqa = 'sadqa';
const String kCatSalary = 'salary';
const String kCatCustomerWithdrawal = 'customer_withdrawal';
const String kCatGovernmentTax = 'government_tax';
const String kCatCustomerReward = 'customer_reward';
const String kCatBankTransfer = 'bank_transfer';

const String kPayCash = 'cash';
const String kPayOnline = 'online';
const String kPayCheque = 'cheque';
const String kPayMainWallet = 'main_wallet';
const String kPayShoppingWallet = 'shopping_wallet';
