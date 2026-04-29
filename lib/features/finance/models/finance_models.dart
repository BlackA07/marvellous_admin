import 'package:cloud_firestore/cloud_firestore.dart';

class BankModel {
  String? id;
  String name;
  String accountTitle;
  String iban;
  String accountNo;
  double balance;
  bool isSystem;
  BankModel({
    this.id,
    required this.name,
    required this.accountTitle,
    required this.iban,
    required this.accountNo,
    required this.balance,
    this.isSystem = false,
  });
  Map<String, dynamic> toMap() => {
    'name': name,
    'accountTitle': accountTitle,
    'iban': iban,
    'accountNo': accountNo,
    'balance': balance,
    'isSystem': isSystem,
  };
  factory BankModel.fromMap(Map<String, dynamic> map, String id) => BankModel(
    id: id,
    name: map['name'] ?? '',
    accountTitle: map['accountTitle'] ?? '',
    iban: map['iban'] ?? '',
    accountNo: map['accountNo'] ?? '',
    balance: (map['balance'] ?? 0).toDouble(),
    isSystem: map['isSystem'] ?? false,
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
  factory BankTransactionModel.fromMap(Map<String, dynamic> map, String id) =>
      BankTransactionModel(
        id: id,
        bankId: map['bankId'] ?? '',
        type: map['type'] ?? '',
        amount: (map['amount'] ?? 0).toDouble(),
        date: (map['date'] as Timestamp).toDate(),
        description: map['description'] ?? '',
      );
}

class ExpenseCategoryModel {
  String? id;
  String name;
  List<String> subcategories;
  ExpenseCategoryModel({
    this.id,
    required this.name,
    required this.subcategories,
  });
  Map<String, dynamic> toMap() => {
    'name': name,
    'subcategories': subcategories,
  };
  factory ExpenseCategoryModel.fromMap(Map<String, dynamic> map, String id) =>
      ExpenseCategoryModel(
        id: id,
        name: map['name'] ?? '',
        subcategories: List<String>.from(map['subcategories'] ?? []),
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
        date: (map['date'] as Timestamp).toDate(),
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
