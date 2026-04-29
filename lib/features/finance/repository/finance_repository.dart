import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/finance_models.dart';

class FinanceRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  DocumentReference get _financeDoc =>
      _firestore.collection('company_finances').doc('main_finances');
  CollectionReference get _banks => _financeDoc.collection('banks');
  CollectionReference get _transactions =>
      _financeDoc.collection('transactions');
  CollectionReference get _expenses => _firestore.collection('expenses');
  CollectionReference get _taxes => _firestore.collection('taxes');
  CollectionReference get _expenseCategories =>
      _firestore.collection('expense_categories');

  Stream<List<BankModel>> getBanksStream() => _banks.snapshots().map(
    (snap) => snap.docs
        .map(
          (doc) =>
              BankModel.fromMap(doc.data() as Map<String, dynamic>, doc.id),
        )
        .toList(),
  );

  Stream<List<BankTransactionModel>> getBankTransactions(String bankId) =>
      _transactions
          .where('bankId', isEqualTo: bankId)
          .orderBy('date', descending: true)
          .snapshots()
          .map(
            (snap) => snap.docs
                .map(
                  (doc) => BankTransactionModel.fromMap(
                    doc.data() as Map<String, dynamic>,
                    doc.id,
                  ),
                )
                .toList(),
          );

  Stream<List<ExpenseModel>> getExpensesStream() => _expenses
      .orderBy('date', descending: true)
      .snapshots()
      .map(
        (snap) => snap.docs
            .map(
              (doc) => ExpenseModel.fromMap(
                doc.data() as Map<String, dynamic>,
                doc.id,
              ),
            )
            .toList(),
      );

  Stream<List<TaxModel>> getTaxesStream() => _taxes.snapshots().map(
    (snap) => snap.docs
        .map(
          (doc) => TaxModel.fromMap(doc.data() as Map<String, dynamic>, doc.id),
        )
        .toList(),
  );

  Stream<List<ExpenseCategoryModel>> getExpenseCategoriesStream() =>
      _expenseCategories.snapshots().map(
        (snap) => snap.docs
            .map(
              (doc) => ExpenseCategoryModel.fromMap(
                doc.data() as Map<String, dynamic>,
                doc.id,
              ),
            )
            .toList(),
      );

  Stream<double> getTotalCompanyBalanceStream() => _firestore
      .collection('company_finances')
      .doc('balance')
      .snapshots()
      .map(
        (doc) => doc.exists
            ? ((doc.data()?['totalCompanyBalance'] ?? 0.0) as num).toDouble()
            : 0.0,
      );

  Future<void> addBank(BankModel bank) async => await _banks.add(bank.toMap());

  Future<void> updateBank(BankModel bank) async =>
      await _banks.doc(bank.id).update(bank.toMap());

  Future<void> deleteBank(String id) async => await _banks.doc(id).delete();

  Future<void> saveExpenseCategory(ExpenseCategoryModel cat) async {
    if (cat.id == null)
      await _expenseCategories.add(cat.toMap());
    else
      await _expenseCategories.doc(cat.id).update(cat.toMap());
  }

  Future<void> deleteExpenseCategory(String id) async =>
      await _expenseCategories.doc(id).delete();

  Future<bool> addExpenseAndDeduct(ExpenseModel expense) async {
    try {
      await _firestore.runTransaction((tx) async {
        final bankRef = _banks.doc(expense.bankId);
        final bankDoc = await tx.get(bankRef);
        if (!bankDoc.exists) throw Exception("Bank not found");

        final bData = bankDoc.data() as Map<String, dynamic>;
        final currentBalance = bData['balance'] ?? 0.0;
        final isSystem = bData['isSystem'] ?? false;
        final bankName = (bData['name'] ?? '').toString().toLowerCase();

        tx.update(bankRef, {'balance': currentBalance - expense.amount});

        if (isSystem && bankName.contains('internal')) {
          final balRef = _firestore
              .collection('company_finances')
              .doc('balance');
          final balDoc = await tx.get(balRef);
          if (balDoc.exists) {
            final tcb =
                ((balDoc.data()
                            as Map<String, dynamic>)['totalCompanyBalance'] ??
                        0.0)
                    as num;
            tx.update(balRef, {
              'totalCompanyBalance': tcb.toDouble() - expense.amount,
            });
          }
        }

        final expRef = _expenses.doc();
        tx.set(expRef, expense.toMap());

        final transRef = _transactions.doc();
        tx.set(transRef, {
          'bankId': expense.bankId,
          'type': 'out',
          'amount': expense.amount,
          'date': expense.date,
          'description':
              'Expense: ${expense.category} - ${expense.subcategory} (${expense.description})',
        });
      });
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<void> updateExpense(ExpenseModel oldExp, ExpenseModel newExp) async {
    await _firestore.runTransaction((tx) async {
      final oldBankRef = _banks.doc(oldExp.bankId);
      final oldBankDoc = await tx.get(oldBankRef);
      if (oldBankDoc.exists) {
        final oldBData = oldBankDoc.data() as Map<String, dynamic>;
        final bal = oldBData['balance'] ?? 0.0;
        tx.update(oldBankRef, {'balance': bal + oldExp.amount});

        if (oldBData['isSystem'] == true &&
            (oldBData['name'] ?? '').toString().toLowerCase().contains(
              'internal',
            )) {
          final balRef = _firestore
              .collection('company_finances')
              .doc('balance');
          final balDoc = await tx.get(balRef);
          if (balDoc.exists) {
            final tcb =
                ((balDoc.data()
                            as Map<String, dynamic>)['totalCompanyBalance'] ??
                        0.0)
                    as num;
            tx.update(balRef, {
              'totalCompanyBalance': tcb.toDouble() + oldExp.amount,
            });
          }
        }
      }

      final newBankRef = _banks.doc(newExp.bankId);
      final newBankDoc = await tx.get(newBankRef);
      if (newBankDoc.exists) {
        final newBData = newBankDoc.data() as Map<String, dynamic>;
        final bal = newBData['balance'] ?? 0.0;
        tx.update(newBankRef, {'balance': bal - newExp.amount});

        if (newBData['isSystem'] == true &&
            (newBData['name'] ?? '').toString().toLowerCase().contains(
              'internal',
            )) {
          final balRef = _firestore
              .collection('company_finances')
              .doc('balance');
          final balDoc = await tx.get(balRef);
          if (balDoc.exists) {
            final tcb =
                ((balDoc.data()
                            as Map<String, dynamic>)['totalCompanyBalance'] ??
                        0.0)
                    as num;
            tx.update(balRef, {
              'totalCompanyBalance': tcb.toDouble() - newExp.amount,
            });
          }
        }
      }
      tx.update(_expenses.doc(newExp.id), newExp.toMap());
    });
  }

  Future<void> deleteExpense(ExpenseModel expense) async {
    await _firestore.runTransaction((tx) async {
      final bankRef = _banks.doc(expense.bankId);
      final bankDoc = await tx.get(bankRef);
      if (bankDoc.exists) {
        final bData = bankDoc.data() as Map<String, dynamic>;
        final currentBalance = bData['balance'] ?? 0.0;
        final isSystem = bData['isSystem'] ?? false;
        final bankName = (bData['name'] ?? '').toString().toLowerCase();

        tx.update(bankRef, {'balance': currentBalance + expense.amount});

        if (isSystem && bankName.contains('internal')) {
          final balRef = _firestore
              .collection('company_finances')
              .doc('balance');
          final balDoc = await tx.get(balRef);
          if (balDoc.exists) {
            final tcb =
                ((balDoc.data()
                            as Map<String, dynamic>)['totalCompanyBalance'] ??
                        0.0)
                    as num;
            tx.update(balRef, {
              'totalCompanyBalance': tcb.toDouble() + expense.amount,
            });
          }
        }
      }

      tx.delete(_expenses.doc(expense.id));

      final transRef = _transactions.doc();
      tx.set(transRef, {
        'bankId': expense.bankId,
        'type': 'in',
        'amount': expense.amount,
        'date': DateTime.now(),
        'description': 'Expense Deleted Refund',
      });
    });
  }

  Future<void> addTax(TaxModel tax) async => await _taxes.add(tax.toMap());

  Future<void> updateTax(TaxModel tax) async =>
      await _taxes.doc(tax.id).update(tax.toMap());

  Future<void> deleteTax(String id) async => await _taxes.doc(id).delete();
}
