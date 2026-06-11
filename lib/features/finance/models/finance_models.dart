// Path: lib/features/finances/models/finance_models.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class BankModel {
  String? id;
  String name;
  String accountTitle;
  String iban;
  String accountNo;
  double balance;
  bool isSystem;

  // ✅ NEW FIELDS FOR CUSTOMER APP CONTROL
  String qrCodeBase64;
  bool showInCustomerApp;
  bool showTitle;
  bool showIban;
  bool showAccountNo;
  bool showQr;

  BankModel({
    this.id,
    required this.name,
    required this.accountTitle,
    required this.iban,
    required this.accountNo,
    required this.balance,
    this.isSystem = false,
    this.qrCodeBase64 = '',
    this.showInCustomerApp = true,
    this.showTitle = true,
    this.showIban = true,
    this.showAccountNo = true,
    this.showQr = true,
  });

  Map<String, dynamic> toMap() => {
    'name': name,
    'accountTitle': accountTitle,
    'iban': iban,
    'accountNo': accountNo,
    'balance': balance,
    'isSystem': isSystem,
    'qrCodeBase64': qrCodeBase64,
    'showInCustomerApp': showInCustomerApp,
    'showTitle': showTitle,
    'showIban': showIban,
    'showAccountNo': showAccountNo,
    'showQr': showQr,
  };

  factory BankModel.fromMap(Map<String, dynamic> map, String id) => BankModel(
    id: id,
    name: map['name'] ?? '',
    accountTitle: map['accountTitle'] ?? '',
    iban: map['iban'] ?? '',
    accountNo: map['accountNo'] ?? '',
    balance: (map['balance'] ?? 0).toDouble(),
    isSystem: map['isSystem'] ?? false,
    qrCodeBase64: map['qrCodeBase64'] ?? '',
    showInCustomerApp: map['showInCustomerApp'] ?? true,
    showTitle: map['showTitle'] ?? true,
    showIban: map['showIban'] ?? true,
    showAccountNo: map['showAccountNo'] ?? true,
    showQr: map['showQr'] ?? true,
  );
}

class BankTransactionModel {
  String? id;
  String bankId;
  String type;
  double amount;
  DateTime date;
  String description;
  BankTransactionModel({
    this.id,
    required this.bankId,
    required this.type,
    required this.amount,
    required this.date,
    required this.description,
  });
  Map<String, dynamic> toMap() => {
    'bankId': bankId,
    'type': type,
    'amount': amount,
    'date': date,
    'description': description,
  };
  factory BankTransactionModel.fromMap(
    Map<String, dynamic> map,
    String id,
  ) => BankTransactionModel(
    id: id,
    bankId: map['bankId'] ?? '',
    type: map['type'] ?? '',
    amount: (map['amount'] ?? 0).toDouble(),
    // ✅ CRASH FIX: FieldValue.serverTimestamp() sometimes returns null locally before sync
    date: map['date'] is Timestamp
        ? (map['date'] as Timestamp).toDate()
        : DateTime.now(),
    description: map['description'] ?? '',
  );
}

class ExpenseCategoryModel {
  String? id;
  String name;
  List<SubcategoryModel> subcategories; // ✅ String se SubcategoryModel

  ExpenseCategoryModel({
    this.id,
    required this.name,
    required this.subcategories,
  });

  Map<String, dynamic> toMap() => {
    'name': name,
    'subcategories': subcategories.map((s) => s.toMap()).toList(),
  };

  factory ExpenseCategoryModel.fromMap(Map<String, dynamic> map, String id) =>
      ExpenseCategoryModel(
        id: id,
        name: map['name'] ?? '',
        subcategories: (map['subcategories'] as List? ?? []).map((s) {
          // ✅ Agar string hai (purana data) to variable banao
          if (s is String) {
            return SubcategoryModel(name: s, type: 'variable', fixedAmount: 0);
          }
          // ✅ Agar Map hai (naya data) to properly parse karo
          if (s is Map<String, dynamic>) {
            return SubcategoryModel.fromMap(s);
          }
          // ✅ Fallback
          return SubcategoryModel(
            name: s.toString(),
            type: 'variable',
            fixedAmount: 0,
          );
        }).toList(),
      );
}

// Subcategory ki naye model
class SubcategoryModel {
  String name;
  String type; // 'fixed' ya 'variable'
  double fixedAmount;

  SubcategoryModel({
    required this.name,
    required this.type,
    this.fixedAmount = 0,
  });

  Map<String, dynamic> toMap() => {
    'name': name,
    'type': type,
    'fixedAmount': fixedAmount,
  };

  factory SubcategoryModel.fromMap(Map<String, dynamic> map) =>
      SubcategoryModel(
        name: map['name'] ?? '',
        type: map['type'] ?? 'variable',
        fixedAmount: (map['fixedAmount'] ?? 0).toDouble(),
      );
}

class ExpenseModel {
  String? id;
  String category;
  String subcategory;
  String description;
  double amount;
  DateTime date;
  String bankId;
  ExpenseModel({
    this.id,
    required this.category,
    required this.subcategory,
    required this.description,
    required this.amount,
    required this.date,
    required this.bankId,
  });
  Map<String, dynamic> toMap() => {
    'category': category,
    'subcategory': subcategory,
    'description': description,
    'amount': amount,
    'date': date,
    'bankId': bankId,
  };
  factory ExpenseModel.fromMap(Map<String, dynamic> map, String id) =>
      ExpenseModel(
        id: id,
        category: map['category'] ?? '',
        subcategory: map['subcategory'] ?? '',
        description: map['description'] ?? '',
        amount: (map['amount'] ?? 0).toDouble(),
        date: map['date'] is Timestamp
            ? (map['date'] as Timestamp).toDate()
            : DateTime.now(),
        bankId: map['bankId'] ?? '',
      );
}

class TaxModel {
  String? id;
  String category;
  String subcategory;
  double percentage;
  bool appearInCheckout;
  TaxModel({
    this.id,
    required this.category,
    required this.subcategory,
    required this.percentage,
    required this.appearInCheckout,
  });
  Map<String, dynamic> toMap() => {
    'category': category,
    'subcategory': subcategory,
    'percentage': percentage,
    'appearInCheckout': appearInCheckout,
  };
  factory TaxModel.fromMap(Map<String, dynamic> map, String id) => TaxModel(
    id: id,
    category: map['category'] ?? '',
    subcategory: map['subcategory'] ?? '',
    percentage: (map['percentage'] ?? 0).toDouble(),
    appearInCheckout: map['appearInCheckout'] ?? false,
  );
}
