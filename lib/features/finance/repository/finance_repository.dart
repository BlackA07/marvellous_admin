// Path: lib/features/finances/repository/finance_repository.dart
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

  Future<void> updateBank(BankModel bank) async {
    await _banks.doc(bank.id).update(bank.toMap());

    // ✅ Agar Internal account hai to totalCompanyBalance bhi sync karo
    final isInternal =
        bank.isSystem && bank.name.toLowerCase().contains('internal');

    if (isInternal) {
      await _firestore.collection('company_finances').doc('balance').update({
        'totalCompanyBalance': bank.balance,
      });
    }
  }

  Future<void> deleteBank(String id) async => await _banks.doc(id).delete();

  Future<void> saveExpenseCategory(ExpenseCategoryModel cat) async {
    if (cat.id == null)
      await _expenseCategories.add(cat.toMap());
    else
      await _expenseCategories.doc(cat.id).update(cat.toMap());
  }

  Future<void> deleteExpenseCategory(String id) async =>
      await _expenseCategories.doc(id).delete();

  // ✅ Bank to Bank Transfer
  Future<bool> transferFunds({
    required BankModel fromBank,
    required BankModel toBank,
    required double amount,
    required String description,
  }) async {
    try {
      await _firestore.runTransaction((tx) async {
        final fromRef = _banks.doc(fromBank.id);
        final toRef = _banks.doc(toBank.id);

        final fromDoc = await tx.get(fromRef);
        final toDoc = await tx.get(toRef);

        if (!fromDoc.exists) throw Exception("Source account not found");
        if (!toDoc.exists) throw Exception("Destination account not found");

        final fromData = fromDoc.data() as Map<String, dynamic>;
        final toData = toDoc.data() as Map<String, dynamic>;

        final fromBalance = (fromData['balance'] ?? 0.0) as num;
        final toBalance = (toData['balance'] ?? 0.0) as num;

        if (fromBalance.toDouble() < amount) {
          throw Exception("Insufficient balance in ${fromBank.name}");
        }

        tx.update(fromRef, {'balance': fromBalance.toDouble() - amount});
        tx.update(toRef, {'balance': toBalance.toDouble() + amount});

        final now = DateTime.now();

        final fromTransRef = _transactions.doc();
        tx.set(fromTransRef, {
          'bankId': fromBank.id,
          'type': 'out',
          'amount': amount,
          'date': now,
          'description': 'Transfer to ${toBank.name}: $description',
        });

        final toTransRef = _transactions.doc();
        tx.set(toTransRef, {
          'bankId': toBank.id,
          'type': 'in',
          'amount': amount,
          'date': now,
          'description': 'Transfer from ${fromBank.name}: $description',
        });

        // ✅ FIX: Master ledger mein Bank Transfer show karne ke liye
        final ledgerOutRef = _firestore
            .collection('admin_ledger_transactions')
            .doc();
        tx.set(ledgerOutRef, {
          'type': 'out',
          'category': 'bank_transfer',
          'amount': amount,
          'bankId': fromBank.id,
          'bankName': fromBank.name,
          'description': 'Transfer to ${toBank.name}: $description',
          'createdBy': 'admin',
          'date': now,
          'createdAt': now,
        });

        final ledgerInRef = _firestore
            .collection('admin_ledger_transactions')
            .doc();
        tx.set(ledgerInRef, {
          'type': 'in',
          'category': 'bank_transfer',
          'amount': amount,
          'bankId': toBank.id,
          'bankName': toBank.name,
          'description': 'Transfer from ${fromBank.name}: $description',
          'createdBy': 'admin',
          'date': now,
          'createdAt': now,
        });

        final fromIsInternal =
            (fromData['isSystem'] ?? false) &&
            (fromData['name'] ?? '').toString().toLowerCase().contains(
              'internal',
            );
        final toIsInternal =
            (toData['isSystem'] ?? false) &&
            (toData['name'] ?? '').toString().toLowerCase().contains(
              'internal',
            );

        if (toIsInternal && !fromIsInternal) {
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
            tx.update(balRef, {'totalCompanyBalance': tcb.toDouble() + amount});
          }
        } else if (fromIsInternal && !toIsInternal) {
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
            tx.update(balRef, {'totalCompanyBalance': tcb.toDouble() - amount});
          }
        }
      });
      return true;
    } catch (e) {
      print('Transfer error: $e');
      return false;
    }
  }

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

        // ✅ FIX: ADD TO MASTER LEDGER (So it shows in Overview!)
        final ledgerRef = _firestore
            .collection('admin_ledger_transactions')
            .doc();
        tx.set(ledgerRef, {
          'type': 'out',
          'category': 'expense',
          'amount': expense.amount,
          'paymentMethod': 'bank',
          'bankId': expense.bankId,
          'bankName': bData['name'] ?? 'Bank',
          'description':
              'Expense: ${expense.category} - ${expense.subcategory} (${expense.description})',
          'createdBy': 'admin',
          'date': expense.date,
          'createdAt': DateTime.now(),
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

        tx.delete(_expenses.doc(expense.id));

        final transRef = _transactions.doc();
        tx.set(transRef, {
          'bankId': expense.bankId,
          'type': 'in',
          'amount': expense.amount,
          'date': DateTime.now(),
          'description': 'Expense Deleted Refund',
        });

        // ✅ FIX: ADD TO MASTER LEDGER (Refund)
        final ledgerRef = _firestore
            .collection('admin_ledger_transactions')
            .doc();
        tx.set(ledgerRef, {
          'type': 'in',
          'category': 'expense',
          'amount': expense.amount,
          'paymentMethod': 'bank',
          'bankId': expense.bankId,
          'bankName': bankName,
          'description': 'Expense Deleted Refund: ${expense.description}',
          'createdBy': 'admin',
          'date': DateTime.now(),
          'createdAt': DateTime.now(),
        });
      }
    });
  }

  Future<void> addTax(TaxModel tax) async => await _taxes.add(tax.toMap());

  Future<void> updateTax(TaxModel tax) async =>
      await _taxes.doc(tax.id).update(tax.toMap());

  Future<void> deleteTax(String id) async => await _taxes.doc(id).delete();

  // ─────────────────────────────────────────────────────────
  // ✅ NEW: UPDATE & TRANSFER LOGIC FOR SPLIT CARDS
  // ─────────────────────────────────────────────────────────

  Future<void> updateSplitBalance(String field, double newBalance) async {
    await _financeDoc.set({
      field: newBalance.toStringAsFixed(2),
    }, SetOptions(merge: true));
  }

  Future<bool> transferFromSplit({
    required String field,
    required double amount,
    required BankModel toBank,
    required String description,
  }) async {
    try {
      await _firestore.runTransaction((tx) async {
        final mainDoc = await tx.get(_financeDoc);
        double currentSplitBal = 0.0;
        if (mainDoc.exists && mainDoc.data() != null) {
          final data = mainDoc.data() as Map<String, dynamic>;
          currentSplitBal =
              double.tryParse(data[field]?.toString() ?? '0') ?? 0.0;
        }

        if (currentSplitBal < amount) {
          throw Exception("Insufficient balance in $field");
        }

        final toBankRef = _banks.doc(toBank.id);
        final toBankDoc = await tx.get(toBankRef);
        if (!toBankDoc.exists) throw Exception("Destination account not found");

        final toBankData = toBankDoc.data() as Map<String, dynamic>;
        final toBalance = (toBankData['balance'] ?? 0.0) as num;

        tx.set(_financeDoc, {
          field: (currentSplitBal - amount).toStringAsFixed(2),
        }, SetOptions(merge: true));

        tx.update(toBankRef, {'balance': toBalance.toDouble() + amount});

        final txRef = _transactions.doc();
        tx.set(txRef, {
          'bankId': toBank.id,
          'type': 'in',
          'amount': amount,
          'date': DateTime.now(),
          'description':
              'Transferred from Gross Profit Split ($field): $description',
        });

        // ✅ FIX: ADD TO MASTER LEDGER (So it's captured in Overview)
        final ledgerRef = _firestore
            .collection('admin_ledger_transactions')
            .doc();
        tx.set(ledgerRef, {
          'type': 'in', // Funds officially entering active bank
          'category': 'bank_transfer',
          'amount': amount,
          'bankId': toBank.id,
          'bankName': toBank.name,
          'description': 'Transferred from Split Pool ($field): $description',
          'createdBy': 'admin',
          'date': DateTime.now(),
          'createdAt': DateTime.now(),
        });

        final isInternal =
            (toBankData['isSystem'] ?? false) &&
            (toBankData['name'] ?? '').toString().toLowerCase().contains(
              'internal',
            );
        if (isInternal) {
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
            tx.update(balRef, {'totalCompanyBalance': tcb.toDouble() + amount});
          }
        }
      });
      return true;
    } catch (e) {
      print("Transfer from split error: $e");
      return false;
    }
  }
}
