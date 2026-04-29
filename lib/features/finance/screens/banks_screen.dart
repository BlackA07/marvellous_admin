import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
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
          style: GoogleFonts.comicNeue(color: Colors.white),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.cyanAccent,
        child: const Icon(Icons.add, color: Colors.black),
        onPressed: () => _bankDialog(context),
      ),
      body: Obx(() {
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
            ],
          ),
        );
      }),
    );
  }

  Widget _buildBankCard(BuildContext context, BankModel bank) {
    bool isInternal =
        bank.isSystem && bank.name.toLowerCase().contains('internal');
    String displayBalance = isInternal
        ? controller.totalCompanyBalance.value.toString()
        : bank.balance.toString();

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
                  Row(
                    children: [
                      Text(
                        'IBAN: ${bank.iban}',
                        style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 12,
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
                  Row(
                    children: [
                      Text(
                        'A/C: ${bank.accountNo}',
                        style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 12,
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
        trailing: SizedBox(
          width: 100,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  'PKR $displayBalance',
                  style: GoogleFonts.comicNeue(
                    color: Colors.greenAccent,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
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

  void _bankDialog(BuildContext context, {BankModel? bank}) {
    final nameCtrl = TextEditingController(text: bank?.name);
    final titleCtrl = TextEditingController(text: bank?.accountTitle);
    final ibanCtrl = TextEditingController(text: bank?.iban);
    final acCtrl = TextEditingController(text: bank?.accountNo);
    final balCtrl = TextEditingController(text: bank?.balance.toString());

    bool isSystemAcc = bank?.isSystem ?? false;
    bool isInternal =
        isSystemAcc && (bank?.name.toLowerCase().contains('internal') ?? false);

    Get.defaultDialog(
      backgroundColor: const Color(0xFF2C2C2C),
      title: bank == null ? 'Add Bank / Cash' : 'Edit Account',
      titleStyle: const TextStyle(color: Colors.white),
      content: StatefulBuilder(
        builder: (ctx, setState) => Column(
          children: [
            _input(nameCtrl, 'Bank/Account Name (e.g. Cash, Internal)'),
            if (!isSystemAcc) ...[
              _input(titleCtrl, 'Account Title'),
              _input(ibanCtrl, 'IBAN'),
              _input(acCtrl, 'Account No'),
            ],

            if (!isInternal) _input(balCtrl, 'Balance', isNum: true),

            if (isInternal)
              const Padding(
                padding: EdgeInsets.only(bottom: 8),
                child: Text(
                  'Balance is auto-synced from Total Company Balance.',
                  style: TextStyle(color: Colors.cyanAccent, fontSize: 12),
                  textAlign: TextAlign.center,
                ),
              ),

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
                  isInternal =
                      isSystemAcc &&
                      nameCtrl.text.toLowerCase().contains('internal');
                }),
              ),
          ],
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
        child: StreamBuilder<List<BankTransactionModel>>(
          stream: controller.getBankHistory(bank.id!),
          builder: (ctx, snap) {
            if (!snap.hasData)
              return const Center(child: CircularProgressIndicator());
            return ListView.builder(
              itemCount: snap.data!.length,
              itemBuilder: (ctx, i) {
                final tx = snap.data![i];
                return ListTile(
                  title: Text(
                    tx.description,
                    style: const TextStyle(color: Colors.white),
                  ),
                  subtitle: Text(
                    tx.date.toString(),
                    style: const TextStyle(color: Colors.white54),
                  ),
                  trailing: Text(
                    '${tx.type == 'in' ? '+' : '-'} ${tx.amount}',
                    style: TextStyle(
                      color: tx.type == 'in' ? Colors.green : Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _input(TextEditingController c, String hint, {bool isNum = false}) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: TextField(
          controller: c,
          style: const TextStyle(color: Colors.white),
          keyboardType: isNum ? TextInputType.number : TextInputType.text,
          onChanged: (val) {
            // Internal name detect karne ke liye update if needed
          },
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
}
