import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import '../models/finance_models.dart';
import '../repository/finance_repository.dart';

class FinanceController extends GetxController {
  final FinanceRepository _repo = FinanceRepository();
  RxList<BankModel> banks = <BankModel>[].obs;
  RxList<ExpenseModel> expenses = <ExpenseModel>[].obs;
  RxList<TaxModel> taxes = <TaxModel>[].obs;
  RxList<ExpenseCategoryModel> expenseCategories = <ExpenseCategoryModel>[].obs;
  RxDouble totalCompanyBalance = 0.0.obs;
  RxBool isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    FirebaseAuth.instance.authStateChanges().listen((User? user) {
      if (user != null) {
        banks.bindStream(_repo.getBanksStream());
        expenses.bindStream(_repo.getExpensesStream());
        taxes.bindStream(_repo.getTaxesStream());
        expenseCategories.bindStream(_repo.getExpenseCategoriesStream());
        totalCompanyBalance.bindStream(_repo.getTotalCompanyBalanceStream());
      } else {
        banks.clear();
        expenses.clear();
        taxes.clear();
        expenseCategories.clear();
        totalCompanyBalance.value = 0.0;
      }
    });
  }

  Future<void> addBank(BankModel bank) async {
    isLoading.value = true;
    await _repo.addBank(bank);
    isLoading.value = false;
  }

  Future<void> updateBank(BankModel bank) async {
    isLoading.value = true;
    await _repo.updateBank(bank);
    isLoading.value = false;
  }

  Future<void> deleteBank(String id) async => await _repo.deleteBank(id);

  Future<void> saveCategory(ExpenseCategoryModel cat) async {
    isLoading.value = true;
    await _repo.saveExpenseCategory(cat);
    isLoading.value = false;
  }

  Future<void> removeCategory(String id) async =>
      await _repo.deleteExpenseCategory(id);

  Future<bool> createExpense(ExpenseModel exp) async {
    isLoading.value = true;
    bool success = await _repo.addExpenseAndDeduct(exp);
    isLoading.value = false;
    return success;
  }

  Future<void> editExpense(ExpenseModel oldExp, ExpenseModel newExp) async {
    isLoading.value = true;
    await _repo.updateExpense(oldExp, newExp);
    isLoading.value = false;
  }

  Future<void> removeExpense(ExpenseModel exp) async =>
      await _repo.deleteExpense(exp);

  Future<void> saveTax(TaxModel tax) async {
    isLoading.value = true;
    if (tax.id == null)
      await _repo.addTax(tax);
    else
      await _repo.updateTax(tax);
    isLoading.value = false;
  }

  Future<void> removeTax(String id) async => await _repo.deleteTax(id);

  Stream<List<BankTransactionModel>> getBankHistory(String bankId) =>
      _repo.getBankTransactions(bankId);
}
