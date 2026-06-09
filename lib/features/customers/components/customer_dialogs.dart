import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'helper_widgets.dart';
import '../controller/customer_detail_controller.dart';

void showFullImageDialog(BuildContext context, String imageData) {
  Get.dialog(
    Dialog(
      backgroundColor: Colors.black,
      insetPadding: const EdgeInsets.all(12),
      child: SizedBox(
        width: double.infinity,
        height: MediaQuery.of(Get.context!).size.height * 0.6,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Get.back(),
                ),
              ],
            ),
            Expanded(
              child: InteractiveViewer(
                minScale: 0.5,
                maxScale: 4.0,
                child: Center(child: buildBase64Image(imageData)),
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    ),
  );
}

void showAdjustWalletDialog(
  BuildContext context,
  CustomerDetailController controller,
) async {
  final amtCtrl = TextEditingController();
  final reasonCtrl = TextEditingController();
  bool isDeduction = false;
  String? selectedBankId;
  String? selectedBankName;
  List<Map<String, dynamic>> banks = [];

  try {
    final banksSnap = await FirebaseFirestore.instance
        .collection('company_finances')
        .doc('main_finances')
        .collection('banks')
        .get();
    banks = banksSnap.docs
        .map((d) {
          final data = d.data();
          return {
            'id': d.id,
            'name': data['name'] ?? 'Bank',
            'balance': (data['balance'] ?? 0.0).toDouble(),
            'isSystem': data['isSystem'] ?? false,
          };
        })
        .where((b) => !(b['isSystem'] as bool))
        .toList(); // internal/system banks hide karo
  } catch (_) {}

  Get.dialog(
    StatefulBuilder(
      builder: (context, setState) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(width: 2),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "Adjust Wallet",
                style: GoogleFonts.comicNeue(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 15),
              Row(
                children: [
                  Expanded(
                    child: RadioListTile(
                      title: const Text("Add"),
                      value: false,
                      groupValue: isDeduction,
                      activeColor: Colors.black,
                      onChanged: (v) => setState(() {
                        isDeduction = v as bool;
                        selectedBankId = null;
                        selectedBankName = null;
                      }),
                    ),
                  ),
                  Expanded(
                    child: RadioListTile(
                      title: const Text("Deduct"),
                      value: true,
                      groupValue: isDeduction,
                      activeColor: Colors.black,
                      onChanged: (v) => setState(() {
                        isDeduction = v as bool;
                        selectedBankId = null;
                        selectedBankName = null;
                      }),
                    ),
                  ),
                ],
              ),
              // Add mode: bank select karo (us bank se amount cut hoga)
              if (!isDeduction && banks.isNotEmpty) ...[
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  value: selectedBankId,
                  decoration: const InputDecoration(
                    labelText:
                        "Select Bank (amount will be deducted from bank)",
                    border: OutlineInputBorder(),
                  ),
                  items: banks
                      .map(
                        (b) => DropdownMenuItem<String>(
                          value: b['id'] as String,
                          child: Text(
                            "${b['name']}  (Rs. ${(b['balance'] as double).toStringAsFixed(0)})",
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (v) {
                    setState(() {
                      selectedBankId = v;
                      selectedBankName =
                          banks.firstWhere((b) => b['id'] == v)['name']
                              as String?;
                    });
                  },
                ),
              ],
              // Deduct mode: internal payment mein add hoga (info text)
              if (isDeduction) ...[
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: Colors.orange.shade700,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          "Deducted amount will be added to Internal Payment balance.",
                          style: TextStyle(fontSize: 12, color: Colors.black87),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 10),
              TextField(
                controller: amtCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: "Amount",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: reasonCtrl,
                decoration: const InputDecoration(
                  labelText: "Reason",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: isDeduction ? Colors.red : Colors.green,
                  minimumSize: const Size(double.infinity, 50),
                ),
                onPressed: () {
                  double amt = double.tryParse(amtCtrl.text) ?? 0;
                  if (amt <= 0) {
                    Get.snackbar(
                      "Error",
                      "Enter a valid amount",
                      backgroundColor: Colors.red,
                      colorText: Colors.white,
                    );
                    return;
                  }
                  if (reasonCtrl.text.isEmpty) {
                    Get.snackbar(
                      "Error",
                      "Reason required",
                      backgroundColor: Colors.red,
                      colorText: Colors.white,
                    );
                    return;
                  }
                  if (!isDeduction && selectedBankId == null) {
                    Get.snackbar(
                      "Error",
                      "Please select a bank",
                      backgroundColor: Colors.red,
                      colorText: Colors.white,
                    );
                    return;
                  }
                  controller.adjustWallet(
                    amt,
                    reasonCtrl.text,
                    isDeduction,
                    selectedBankId,
                    selectedBankName,
                  );
                },
                child: const Text(
                  "SUBMIT",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

void showSendMessageDialog(
  BuildContext context,
  CustomerDetailController controller,
) {
  final titleCtrl = TextEditingController();
  final bodyCtrl = TextEditingController();
  String? selectedImageBase64;

  Get.dialog(
    StatefulBuilder(
      builder: (context, setState) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(width: 2),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "Send Message",
                style: GoogleFonts.comicNeue(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 15),
              TextField(
                controller: titleCtrl,
                decoration: const InputDecoration(
                  labelText: "Title",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: bodyCtrl,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: "Message",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 15),
              selectedImageBase64 != null
                  ? Stack(
                      alignment: Alignment.topRight,
                      children: [
                        Container(
                          height: 120,
                          width: 120,
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Image.memory(
                            base64Decode(selectedImageBase64!),
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) =>
                                const Icon(Icons.broken_image),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.red),
                          onPressed: () =>
                              setState(() => selectedImageBase64 = null),
                        ),
                      ],
                    )
                  : OutlinedButton.icon(
                      icon: const Icon(Icons.image, color: Colors.black),
                      label: const Text(
                        "Add Image",
                        style: TextStyle(color: Colors.black),
                      ),
                      onPressed: () async {
                        final picker = ImagePicker();
                        final XFile? xfile = await picker.pickImage(
                          source: ImageSource.gallery,
                          imageQuality: 50,
                        );
                        if (xfile != null) {
                          final bytes = await xfile.readAsBytes();
                          setState(
                            () => selectedImageBase64 = base64Encode(bytes),
                          );
                        }
                      },
                    ),
              const SizedBox(height: 20),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.indigo,
                  minimumSize: const Size(double.infinity, 50),
                ),
                onPressed: () {
                  if (titleCtrl.text.isNotEmpty) {
                    controller.sendDirectMessage(
                      titleCtrl.text,
                      bodyCtrl.text,
                      selectedImageBase64 ?? '',
                    );
                  }
                },
                child: const Text(
                  "SEND",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
