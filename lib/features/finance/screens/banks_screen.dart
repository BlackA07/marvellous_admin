// Path: lib/features/finances/presentation/screens/BanksScreen.dart
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../controller/finance_controller.dart';
import '../models/finance_models.dart';

class BanksScreen extends StatelessWidget {
  final FinanceController controller = Get.put(FinanceController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Banks & Finances',
          style: GoogleFonts.comicNeue(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton.extended(
            heroTag: 'transfer',
            backgroundColor: Colors.deepPurpleAccent,
            icon: const Icon(Icons.swap_horiz, color: Colors.white),
            label: const Text(
              'Transfer',
              style: TextStyle(color: Colors.white),
            ),
            onPressed: () => _transferDialog(context),
          ),
          const SizedBox(height: 12),
          FloatingActionButton(
            heroTag: 'add',
            backgroundColor: Colors.cyanAccent,
            child: const Icon(Icons.add, color: Colors.black),
            onPressed: () => _bankDialog(context),
          ),
        ],
      ),
      body: Obx(() {
        double totalExpense = controller.expenses.fold(
          0.0,
          (sum, e) => sum + e.amount,
        );
        final systemAccounts = controller.banks
            .where((b) => b.isSystem)
            .toList();
        final bankAccounts = controller.banks
            .where((b) => !b.isSystem)
            .toList();

        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── ✅ NAYA SECTION: FINANCIAL SPLITS (PROFIT, TAX, SADQA, EXPENSE POOL) ──
              Text(
                'Financial Splits Overview',
                style: GoogleFonts.comicNeue(
                  color: Colors.cyanAccent,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 15),
              StreamBuilder<DocumentSnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('company_finances')
                    .doc('main_finances')
                    .snapshots(),
                builder: (context, snapshot) {
                  double taxes = 0.0;
                  double sadqa = 0.0;
                  double profit = 0.0;
                  double expPool = 0.0; // ✅ Real Expense Pool from Gross Split

                  if (snapshot.hasData && snapshot.data!.exists) {
                    var data =
                        snapshot.data!.data() as Map<String, dynamic>? ?? {};
                    // Parsing strings to double with rounding (toInt)
                    taxes =
                        double.tryParse(data['taxes']?.toString() ?? '0') ??
                        0.0;
                    sadqa =
                        double.tryParse(data['sadqa']?.toString() ?? '0') ??
                        0.0;
                    profit =
                        double.tryParse(
                          data['main_profit']?.toString() ?? '0',
                        ) ??
                        0.0;
                    expPool =
                        double.tryParse(
                          data['expense_product']?.toString() ?? '0',
                        ) ??
                        0.0;
                  }

                  return Row(
                    children: [
                      // ✅ ROUNDING: .toInt() ya .round() use kiya taake decimal na aaye
                      _buildSplitSummaryCard(
                        context,
                        "Main Profit",
                        'main_profit',
                        profit.toInt().toDouble(),
                        Colors.greenAccent,
                        Icons.monetization_on,
                      ),
                      const SizedBox(width: 8),
                      _buildSplitSummaryCard(
                        context,
                        "Taxes",
                        'taxes',
                        taxes.toInt().toDouble(),
                        Colors.orangeAccent,
                        Icons.account_balance,
                      ),
                      const SizedBox(width: 8),
                      _buildSplitSummaryCard(
                        context,
                        "Sadqa",
                        'sadqa',
                        sadqa.toInt().toDouble(),
                        Colors.purpleAccent,
                        Icons.volunteer_activism,
                      ),
                      const SizedBox(width: 8),
                      _buildSplitSummaryCard(
                        context,
                        "Expenses",
                        'expenses_pool',
                        expPool.toInt().toDouble(),
                        Colors.redAccent,
                        Icons.money_off,
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 30),

              if (systemAccounts.isNotEmpty) ...[
                Text(
                  'System Accounts (Default)',
                  style: GoogleFonts.comicNeue(
                    color: Colors.cyanAccent,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 15),
                ...systemAccounts
                    .map((bank) => _buildBankCard(context, bank))
                    .toList(),
                const SizedBox(height: 30),
              ],
              Text(
                'Bank Accounts',
                style: GoogleFonts.comicNeue(
                  color: Colors.cyanAccent,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 15),
              ...bankAccounts
                  .map((bank) => _buildBankCard(context, bank))
                  .toList(),
              const SizedBox(height: 100),
            ],
          ),
        );
      }),
    );
  }

  // ── ✅ WIDGET: SPLIT CARD (Clickable & Vertical Layout) ──
  Widget _buildSplitSummaryCard(
    BuildContext context,
    String title,
    String dbField,
    double amount,
    Color color,
    IconData icon,
  ) {
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _splitOptionsDialog(context, title, dbField, amount),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
          decoration: BoxDecoration(
            color: const Color(0xFF252525),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(height: 6),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  'Rs. ${_fmt(amount)}',
                  style: TextStyle(
                    color: color,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── ✅ ACTION: OPTIONS DIALOG FOR SPLIT CARDS ──
  void _splitOptionsDialog(
    BuildContext context,
    String title,
    String dbField,
    double currentAmt,
  ) {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Color(0xFF2C2C2C),
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "$title Settings",
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              "Current Balance: PKR ${_fmt(currentAmt)}",
              style: const TextStyle(color: Colors.cyanAccent, fontSize: 14),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.edit, color: Colors.orangeAccent),
              title: const Text(
                "Edit Balance Manually",
                style: TextStyle(color: Colors.white),
              ),
              onTap: () {
                Get.back();
                _editSplitDialog(title, dbField, currentAmt);
              },
            ),
            const Divider(color: Colors.white12),
            ListTile(
              leading: const Icon(Icons.swap_horiz, color: Colors.greenAccent),
              title: const Text(
                "Transfer Funds to Bank",
                style: TextStyle(color: Colors.white),
              ),
              onTap: () {
                Get.back();
                _transferSplitDialog(title, dbField, currentAmt);
              },
            ),
          ],
        ),
      ),
    );
  }

  // ── ✅ ACTION: EDIT SPLIT BALANCE ──
  void _editSplitDialog(String title, String dbField, double currentAmt) {
    final ctrl = TextEditingController(text: currentAmt.toStringAsFixed(0));
    Get.defaultDialog(
      backgroundColor: const Color(0xFF2C2C2C),
      title: 'Edit $title',
      titleStyle: const TextStyle(color: Colors.white),
      content: _input(ctrl, 'New Amount', isNum: true),
      confirm: ElevatedButton(
        style: ElevatedButton.styleFrom(backgroundColor: Colors.cyanAccent),
        onPressed: () {
          double newAmt = double.tryParse(ctrl.text) ?? 0.0;
          controller.updateSplitBalance(dbField, newAmt);
          Get.back();
          Get.snackbar(
            "Success",
            "$title updated to PKR $newAmt",
            backgroundColor: Colors.green,
            colorText: Colors.white,
          );
        },
        child: const Text('Save', style: TextStyle(color: Colors.black)),
      ),
      cancel: TextButton(
        onPressed: () => Get.back(),
        child: const Text("Cancel", style: TextStyle(color: Colors.white54)),
      ),
    );
  }

  // ── ✅ ACTION: TRANSFER FROM SPLIT TO BANK ──
  void _transferSplitDialog(String title, String dbField, double currentAmt) {
    final amtCtrl = TextEditingController();
    final descCtrl = TextEditingController(
      text: 'Funds transferred from $title',
    );
    BankModel? toBank = controller.banks.isNotEmpty
        ? controller.banks.first
        : null;

    Get.defaultDialog(
      backgroundColor: const Color(0xFF2C2C2C),
      title: 'Transfer from $title',
      titleStyle: const TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.bold,
      ),
      content: StatefulBuilder(
        builder: (ctx, setState) => SizedBox(
          width: Get.width * 0.9,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Available Balance: PKR ${_fmt(currentAmt)}',
                style: const TextStyle(color: Colors.cyanAccent, fontSize: 13),
              ),
              const SizedBox(height: 15),
              const Text(
                'Transfer To Bank:',
                style: TextStyle(color: Colors.white70, fontSize: 12),
              ),
              const SizedBox(height: 4),
              DropdownButtonFormField<BankModel>(
                value: toBank,
                dropdownColor: const Color(0xFF2C2C2C),
                decoration: const InputDecoration(
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.cyanAccent),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.white),
                  ),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                ),
                items: controller.banks
                    .map(
                      (b) => DropdownMenuItem(
                        value: b,
                        child: Text(
                          '${b.name} (PKR ${b.balance.toStringAsFixed(0)})',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (val) => setState(() => toBank = val),
              ),
              const SizedBox(height: 12),
              _input(amtCtrl, 'Amount (PKR)', isNum: true),
              _input(descCtrl, 'Note / Reason'),
            ],
          ),
        ),
      ),
      confirm: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.deepPurpleAccent,
        ),
        onPressed: () async {
          final amount = double.tryParse(amtCtrl.text) ?? 0;
          if (amount <= 0 || amount > currentAmt) {
            Get.snackbar(
              'Error',
              'Valid amount likhein (Max: $currentAmt)',
              backgroundColor: Colors.red,
              colorText: Colors.white,
            );
            return;
          }
          if (toBank == null) return;

          Get.back();
          final success = await controller.transferFromSplit(
            field: dbField,
            amount: amount,
            toBank: toBank!,
            description: descCtrl.text,
          );

          if (success) {
            Get.snackbar(
              '✅ Transfer Complete',
              'PKR ${amount.toStringAsFixed(0)} sent to ${toBank!.name}',
              backgroundColor: Colors.green,
              colorText: Colors.white,
            );
          } else {
            Get.snackbar(
              '❌ Failed',
              'Transfer could not be processed.',
              backgroundColor: Colors.redAccent,
              colorText: Colors.white,
            );
          }
        },
        child: const Text('Transfer', style: TextStyle(color: Colors.white)),
      ),
    );
  }

  Widget _buildBankCard(BuildContext context, BankModel bank) {
    bool isInternal =
        bank.isSystem && bank.name.toLowerCase().contains('internal');
    String displayBalance = bank.balance.toStringAsFixed(0);

    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      decoration: BoxDecoration(
        color: const Color(0xFF2C2C2C),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: bank.isSystem
              ? Colors.amberAccent.withOpacity(0.5)
              : Colors.cyanAccent.withOpacity(0.5),
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        title: Text(
          bank.name,
          style: GoogleFonts.comicNeue(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        subtitle: bank.isSystem
            ? const Text(
                'Internal System Ledger',
                style: TextStyle(color: Colors.white54),
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    bank.accountTitle,
                    style: const TextStyle(color: Colors.white70),
                  ),
                  if (bank.iban.isNotEmpty)
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            'IBAN: ${bank.iban}',
                            style: const TextStyle(
                              color: Colors.white54,
                              fontSize: 12,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.copy,
                            size: 14,
                            color: Colors.cyanAccent,
                          ),
                          onPressed: () => _copy(bank.iban),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                  if (bank.accountNo.isNotEmpty)
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            'A/C: ${bank.accountNo}',
                            style: const TextStyle(
                              color: Colors.white54,
                              fontSize: 12,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.copy,
                            size: 14,
                            color: Colors.cyanAccent,
                          ),
                          onPressed: () => _copy(bank.accountNo),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                ],
              ),
        trailing: IntrinsicHeight(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'PKR $displayBalance',
                style: GoogleFonts.comicNeue(
                  color: Colors.greenAccent,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
                maxLines: 1,
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit, color: Colors.white, size: 18),
                    onPressed: () => _bankDialog(context, bank: bank),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  if (!bank.isSystem) ...[
                    const SizedBox(width: 10),
                    IconButton(
                      icon: const Icon(
                        Icons.delete,
                        color: Colors.redAccent,
                        size: 18,
                      ),
                      onPressed: () => controller.deleteBank(bank.id!),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
        onTap: () => _showHistory(context, bank),
      ),
    );
  }

  void _copy(String text) {
    Clipboard.setData(ClipboardData(text: text));
    Get.snackbar(
      'Copied',
      text,
      backgroundColor: Colors.green,
      colorText: Colors.white,
    );
  }

  void _transferDialog(BuildContext context) {
    final amountCtrl = TextEditingController();
    final descCtrl = TextEditingController(text: 'Internal Transfer');

    final allBanks = controller.banks.toList();
    if (allBanks.length < 2) {
      Get.snackbar(
        'Not Enough Accounts',
        'Kam az kam 2 accounts hone chahiye transfer ke liye.',
        backgroundColor: Colors.orangeAccent,
        colorText: Colors.white,
      );
      return;
    }

    BankModel? fromBank = allBanks.first;
    BankModel? toBank = allBanks.length > 1 ? allBanks[1] : null;

    Get.defaultDialog(
      backgroundColor: const Color(0xFF2C2C2C),
      title: '💸 Transfer Funds',
      titleStyle: const TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.bold,
      ),
      content: StatefulBuilder(
        builder: (ctx, setState) => SizedBox(
          width: Get.width * 0.9,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'From Account:',
                style: TextStyle(color: Colors.white70, fontSize: 12),
              ),
              const SizedBox(height: 4),
              DropdownButtonFormField<BankModel>(
                value: fromBank,
                dropdownColor: const Color(0xFF2C2C2C),
                decoration: const InputDecoration(
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.cyanAccent),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.white),
                  ),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                ),
                items: allBanks
                    .map(
                      (b) => DropdownMenuItem(
                        value: b,
                        child: Text(
                          '${b.name} (PKR ${b.balance.toStringAsFixed(0)})',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (val) => setState(() {
                  fromBank = val;
                  if (toBank?.id == val?.id) {
                    toBank = allBanks.firstWhere(
                      (b) => b.id != val?.id,
                      orElse: () => allBanks.first,
                    );
                  }
                }),
              ),
              const SizedBox(height: 12),
              const Text(
                'To Account:',
                style: TextStyle(color: Colors.white70, fontSize: 12),
              ),
              const SizedBox(height: 4),
              DropdownButtonFormField<BankModel>(
                value: toBank,
                dropdownColor: const Color(0xFF2C2C2C),
                decoration: const InputDecoration(
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.deepPurpleAccent),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.white),
                  ),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                ),
                items: allBanks
                    .where((b) => b.id != fromBank?.id)
                    .map(
                      (b) => DropdownMenuItem(
                        value: b,
                        child: Text(
                          '${b.name} (PKR ${b.balance.toStringAsFixed(0)})',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (val) => setState(() => toBank = val),
              ),
              const SizedBox(height: 12),
              _input(amountCtrl, 'Amount (PKR)', isNum: true),
              _input(descCtrl, 'Description / Note'),
            ],
          ),
        ),
      ),
      confirm: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.deepPurpleAccent,
        ),
        onPressed: () async {
          final amount = double.tryParse(amountCtrl.text) ?? 0;
          if (amount <= 0) {
            Get.snackbar(
              'Error',
              'Valid amount enter karein',
              backgroundColor: Colors.red,
              colorText: Colors.white,
            );
            return;
          }
          if (fromBank == null || toBank == null) {
            Get.snackbar(
              'Error',
              'Dono accounts select karein',
              backgroundColor: Colors.red,
              colorText: Colors.white,
            );
            return;
          }
          if (fromBank!.id == toBank!.id) {
            Get.snackbar(
              'Error',
              'From aur To account alag hone chahiye',
              backgroundColor: Colors.red,
              colorText: Colors.white,
            );
            return;
          }

          Get.back();
          final success = await controller.transferFunds(
            fromBank: fromBank!,
            toBank: toBank!,
            amount: amount,
            description: descCtrl.text.isEmpty
                ? 'Internal Transfer'
                : descCtrl.text,
          );

          if (success) {
            Get.snackbar(
              '✅ Transfer Complete',
              'PKR ${amount.toStringAsFixed(0)} transferred from ${fromBank!.name} to ${toBank!.name}',
              backgroundColor: Colors.green,
              colorText: Colors.white,
              duration: const Duration(seconds: 3),
            );
          } else {
            Get.snackbar(
              '❌ Transfer Failed',
              'Insufficient balance ya koi error. Dobara try karein.',
              backgroundColor: Colors.redAccent,
              colorText: Colors.white,
            );
          }
        },
        child: const Text('Transfer', style: TextStyle(color: Colors.white)),
      ),
      cancel: TextButton(
        onPressed: () => Get.back(),
        child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
      ),
    );
  }

  void _bankDialog(BuildContext context, {BankModel? bank}) {
    final nameCtrl = TextEditingController(text: bank?.name);
    final titleCtrl = TextEditingController(text: bank?.accountTitle);
    final ibanCtrl = TextEditingController(text: bank?.iban);
    final acCtrl = TextEditingController(text: bank?.accountNo);
    final balCtrl = TextEditingController(
      text: bank?.balance.toStringAsFixed(0),
    );

    bool isSystemAcc = bank?.isSystem ?? false;
    bool showInCustomerApp = bank?.showInCustomerApp ?? true;
    bool showTitle = bank?.showTitle ?? true;
    bool showIban = bank?.showIban ?? true;
    bool showAccountNo = bank?.showAccountNo ?? true;
    bool showQr = bank?.showQr ?? true;
    String qrCodeBase64 = bank?.qrCodeBase64 ?? '';

    Get.defaultDialog(
      backgroundColor: const Color(0xFF2C2C2C),
      title: bank == null ? 'Add Bank / Cash' : 'Edit Account',
      titleStyle: const TextStyle(color: Colors.white),
      content: StatefulBuilder(
        builder: (ctx, setState) => SizedBox(
          width: Get.width * 0.9,
          height: Get.height * 0.6,
          child: SingleChildScrollView(
            child: Column(
              children: [
                _input(nameCtrl, 'Bank/Account Name (e.g. Cash, Internal)'),
                if (!isSystemAcc) ...[
                  _input(titleCtrl, 'Account Title'),
                  _input(ibanCtrl, 'IBAN'),
                  _input(acCtrl, 'Account No'),
                ],
                _input(balCtrl, 'Balance', isNum: true),
                if (bank == null)
                  CheckboxListTile(
                    title: const Text(
                      'Is System Account (Cash/Internal)',
                      style: TextStyle(color: Colors.white, fontSize: 12),
                    ),
                    value: isSystemAcc,
                    activeColor: Colors.cyanAccent,
                    onChanged: (val) => setState(() {
                      isSystemAcc = val ?? false;
                    }),
                  ),
                const Divider(color: Colors.white24),
                if (!isSystemAcc) ...[
                  const Text(
                    "CUSTOMER APP SETTINGS",
                    style: TextStyle(
                      color: Colors.cyanAccent,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  CheckboxListTile(
                    title: const Text(
                      'Show this Bank in Customer App',
                      style: TextStyle(color: Colors.white, fontSize: 13),
                    ),
                    value: showInCustomerApp,
                    activeColor: Colors.green,
                    onChanged: (val) =>
                        setState(() => showInCustomerApp = val ?? true),
                  ),
                  if (showInCustomerApp) ...[
                    CheckboxListTile(
                      title: const Text(
                        'Show Account Title',
                        style: TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                      value: showTitle,
                      dense: true,
                      onChanged: (val) =>
                          setState(() => showTitle = val ?? true),
                    ),
                    CheckboxListTile(
                      title: const Text(
                        'Show Account Number',
                        style: TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                      value: showAccountNo,
                      dense: true,
                      onChanged: (val) =>
                          setState(() => showAccountNo = val ?? true),
                    ),
                    CheckboxListTile(
                      title: const Text(
                        'Show IBAN',
                        style: TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                      value: showIban,
                      dense: true,
                      onChanged: (val) =>
                          setState(() => showIban = val ?? true),
                    ),
                    CheckboxListTile(
                      title: const Text(
                        'Show QR Code',
                        style: TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                      value: showQr,
                      dense: true,
                      onChanged: (val) => setState(() => showQr = val ?? true),
                    ),
                    const SizedBox(height: 10),
                    GestureDetector(
                      onTap: () async {
                        try {
                          final img = await ImagePicker().pickImage(
                            source: ImageSource.gallery,
                            imageQuality: 50,
                          );
                          if (img != null) {
                            final bytes = await img.readAsBytes();
                            if (bytes.lengthInBytes > 700 * 1024) {
                              Get.snackbar(
                                "Image Too Large ❌",
                                "QR Code must be smaller than 700KB.",
                                backgroundColor: Colors.orangeAccent,
                                colorText: Colors.white,
                                duration: const Duration(seconds: 4),
                              );
                              return;
                            }
                            setState(() => qrCodeBase64 = base64Encode(bytes));
                          }
                        } catch (e) {
                          Get.snackbar(
                            "Error",
                            "Could not load image: $e",
                            backgroundColor: Colors.redAccent,
                            colorText: Colors.white,
                          );
                        }
                      },
                      child: Container(
                        height: 100,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.white12,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.cyanAccent),
                        ),
                        child: qrCodeBase64.isEmpty
                            ? const Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.qr_code,
                                    color: Colors.white54,
                                    size: 30,
                                  ),
                                  Text(
                                    "Upload QR Code",
                                    style: TextStyle(color: Colors.white54),
                                  ),
                                ],
                              )
                            : Image.memory(
                                base64Decode(qrCodeBase64),
                                fit: BoxFit.contain,
                              ),
                      ),
                    ),
                    if (qrCodeBase64.isNotEmpty)
                      TextButton(
                        onPressed: () => setState(() => qrCodeBase64 = ''),
                        child: const Text(
                          "Remove QR",
                          style: TextStyle(color: Colors.redAccent),
                        ),
                      ),
                  ],
                ],
              ],
            ),
          ),
        ),
      ),
      confirm: ElevatedButton(
        style: ElevatedButton.styleFrom(backgroundColor: Colors.cyanAccent),
        onPressed: () {
          final b = BankModel(
            id: bank?.id,
            name: nameCtrl.text,
            accountTitle: isSystemAcc ? '' : titleCtrl.text,
            iban: isSystemAcc ? '' : ibanCtrl.text,
            accountNo: isSystemAcc ? '' : acCtrl.text,
            balance: double.tryParse(balCtrl.text) ?? 0,
            isSystem: isSystemAcc,
            showInCustomerApp: showInCustomerApp,
            showTitle: showTitle,
            showIban: showIban,
            showAccountNo: showAccountNo,
            showQr: showQr,
            qrCodeBase64: qrCodeBase64,
          );
          bank == null ? controller.addBank(b) : controller.updateBank(b);
          Get.back();
        },
        child: const Text('Save', style: TextStyle(color: Colors.black)),
      ),
    );
  }

  void _showHistory(BuildContext context, BankModel bank) {
    Get.bottomSheet(
      Container(
        color: const Color(0xFF1A1A1A),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                '${bank.name} - Transaction History',
                style: GoogleFonts.comicNeue(
                  color: Colors.cyanAccent,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Expanded(
              child: StreamBuilder<List<BankTransactionModel>>(
                stream: controller.getBankHistory(bank.id!),
                builder: (ctx, snap) {
                  if (!snap.hasData)
                    return const Center(child: CircularProgressIndicator());
                  if (snap.data!.isEmpty)
                    return const Center(
                      child: Text(
                        'Koi transaction nahi',
                        style: TextStyle(color: Colors.white54),
                      ),
                    );
                  return ListView.builder(
                    itemCount: snap.data!.length,
                    itemBuilder: (ctx, i) {
                      final tx = snap.data![i];
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: tx.type == 'in'
                              ? Colors.green.withOpacity(0.2)
                              : Colors.red.withOpacity(0.2),
                          child: Icon(
                            tx.type == 'in'
                                ? Icons.arrow_downward
                                : Icons.arrow_upward,
                            color: tx.type == 'in'
                                ? Colors.greenAccent
                                : Colors.redAccent,
                            size: 18,
                          ),
                        ),
                        title: Text(
                          tx.description,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                          ),
                        ),
                        subtitle: Text(
                          tx.date.toString().substring(0, 16),
                          style: const TextStyle(
                            color: Colors.white54,
                            fontSize: 11,
                          ),
                        ),
                        trailing: Text(
                          '${tx.type == 'in' ? '+' : '-'} PKR ${tx.amount.toStringAsFixed(0)}',
                          style: TextStyle(
                            color: tx.type == 'in'
                                ? Colors.greenAccent
                                : Colors.redAccent,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      isScrollControlled: true,
    );
  }

  Widget _input(TextEditingController c, String hint, {bool isNum = false}) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: TextField(
          controller: c,
          style: const TextStyle(color: Colors.white),
          keyboardType: isNum ? TextInputType.number : TextInputType.text,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Colors.white54),
            enabledBorder: const OutlineInputBorder(
              borderSide: BorderSide(color: Colors.cyanAccent),
            ),
            focusedBorder: const OutlineInputBorder(
              borderSide: BorderSide(color: Colors.white),
            ),
          ),
        ),
      );

  String _fmt(double v) {
    if (v == 0) return '0';
    return v
        .toStringAsFixed(0)
        .replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]},',
        );
  }
}
