// Path: lib/features/finances/presentation/screens/BanksScreen.dart
import 'dart:convert';
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
                  if (bank.iban.isNotEmpty)
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
                  if (bank.accountNo.isNotEmpty)
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

    // Settings
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

                    // ✅ FIXED IMAGE PICKER LOGIC HERE
                    GestureDetector(
                      onTap: () async {
                        try {
                          final img = await ImagePicker().pickImage(
                            source: ImageSource.gallery,
                            imageQuality: 50, // Image compress ho jaye
                          );
                          if (img != null) {
                            final bytes = await img.readAsBytes();

                            // Check size: Firestore document limit is 1MB.
                            // Base64 increases size by ~33%.
                            // Raw bytes should be max ~700KB.
                            if (bytes.lengthInBytes > 700 * 1024) {
                              Get.snackbar(
                                "Image Too Large ❌",
                                "QR Code must be smaller than 700KB. Try taking a screenshot to compress it.",
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
