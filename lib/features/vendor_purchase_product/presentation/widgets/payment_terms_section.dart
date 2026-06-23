import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show KIsWeb, kIsWeb;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import '../../controller/purchase_controller.dart';

class PaymentTermsSection extends StatefulWidget {
  final double totalBill;
  final VoidCallback onSaveSuccess;

  const PaymentTermsSection({
    super.key,
    required this.totalBill,
    required this.onSaveSuccess,
  });

  @override
  State<PaymentTermsSection> createState() => _PaymentTermsSectionState();
}

class _PaymentTermsSectionState extends State<PaymentTermsSection> {
  final controller = Get.find<PurchaseController>();

  String paymentMode = "Pay Now";
  String creditType = "Daily";

  String transactionMode = "Cash";
  String? selectedBankId;
  String? selectedBankName;
  String? bankScreenshotBase64;
  final chequeNumberCtrl = TextEditingController();
  DateTime? chequeDate;

  final paidAmountCtrl = TextEditingController();
  final perDayCtrl = TextEditingController();
  final firstPaymentAmtCtrl = TextEditingController();
  final customDaysLimitCtrl = TextEditingController();

  DateTime? firstPaymentDate;
  DateTime? startingDate;

  final List<String> weekDays = [
    "Monday",
    "Tuesday",
    "Wednesday",
    "Thursday",
    "Friday",
    "Saturday",
    "Sunday",
  ];

  List<String> selectedDailyDays = [
    "Monday",
    "Tuesday",
    "Wednesday",
    "Thursday",
    "Friday",
    "Saturday",
    "Sunday",
  ];
  String selectedWeeklyDay = "Monday";

  @override
  void initState() {
    super.initState();
    paidAmountCtrl.text = widget.totalBill.toStringAsFixed(0);
  }

  @override
  void dispose() {
    chequeNumberCtrl.dispose();
    paidAmountCtrl.dispose();
    perDayCtrl.dispose();
    firstPaymentAmtCtrl.dispose();
    customDaysLimitCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 50,
    );

    if (pickedFile != null) {
      // ✅ Agar app Web par chal rahi hai, toh direct image read kar lo (No Cropper issues)
      if (kIsWeb) {
        final bytes = await pickedFile.readAsBytes();
        setState(() => bankScreenshotBase64 = base64Encode(bytes));
      }
      // ✅ Agar app Mobile (Android/iOS) par chal rahi hai, toh Cropper use karo
      else {
        CroppedFile? croppedFile = await ImageCropper().cropImage(
          sourcePath: pickedFile.path,
          uiSettings: [
            AndroidUiSettings(
              toolbarTitle: 'Crop Screenshot',
              toolbarColor: Colors.black,
              toolbarWidgetColor: Colors.white,
              initAspectRatio: CropAspectRatioPreset.original,
              lockAspectRatio: false,
              hideBottomControls: true, // Android pe overflow rokne ke liye
            ),
            IOSUiSettings(title: 'Crop Screenshot'),
          ],
        );

        if (croppedFile != null) {
          final bytes = await croppedFile.readAsBytes();
          setState(() => bankScreenshotBase64 = base64Encode(bytes));
        }
      }
    }
  }

  Future<void> _selectDate(
    BuildContext context, {
    required Function(DateTime) onPicked,
  }) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      builder: (context, child) => Theme(
        data: ThemeData.light().copyWith(
          colorScheme: const ColorScheme.light(
            primary: Colors.black,
            onPrimary: Colors.white,
          ),
          textButtonTheme: TextButtonThemeData(
            style: TextButton.styleFrom(foregroundColor: Colors.black),
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => onPicked(picked));
  }

  void _processSave() async {
    if (widget.totalBill <= 0) {
      Get.snackbar(
        "Required",
        "Please add at least one product.",
        backgroundColor: Colors.orange,
        colorText: Colors.white,
      );
      return;
    }

    double cashPaid = double.tryParse(paidAmountCtrl.text) ?? 0.0;

    // Amount validations
    if (paymentMode == "Pay Now" ||
        paymentMode == "Online" ||
        paymentMode == "Cheque") {
      if (cashPaid != widget.totalBill) {
        Get.snackbar(
          "Amount Limit",
          "For $paymentMode, paid amount must equal Total Bill (PKR ${widget.totalBill}).",
          backgroundColor: Colors.red.shade900,
          colorText: Colors.white,
        );
        return;
      }
    } else if (paymentMode == "Both") {
      if (cashPaid <= 0 || cashPaid >= widget.totalBill) {
        Get.snackbar(
          "Amount Limit",
          "For 'Both', paid amount must be greater than 0 and less than Total Bill.",
          backgroundColor: Colors.red.shade900,
          colorText: Colors.white,
        );
        return;
      }
    }

    // Bank/Cheque validations
    if (transactionMode == 'Bank Transfer' && selectedBankId == null) {
      Get.snackbar(
        "Required",
        "Please select a bank.",
        backgroundColor: Colors.red.shade900,
        colorText: Colors.white,
      );
      return;
    }
    if (transactionMode == 'Cheque') {
      if (selectedBankId == null) {
        Get.snackbar(
          "Required",
          "Please select a bank for cheque.",
          backgroundColor: Colors.red.shade900,
          colorText: Colors.white,
        );
        return;
      }
      if (chequeNumberCtrl.text.isEmpty) {
        Get.snackbar(
          "Required",
          "Please enter cheque number.",
          backgroundColor: Colors.red.shade900,
          colorText: Colors.white,
        );
        return;
      }
    }

    List<String> activeDays = [];
    if (creditType == "Daily") activeDays = selectedDailyDays;
    if (creditType == "Weekly") activeDays = [selectedWeeklyDay];

    // paymentMode mapping for submitTransaction
    String mappedPaymentMode = paymentMode;
    if (paymentMode == "Pay Now") mappedPaymentMode = "Cash";
    if (paymentMode == "Cheque") mappedPaymentMode = "Cash";

    bool success = await controller.submitTransaction(
      totalBill: widget.totalBill,
      paymentMode: mappedPaymentMode,
      cashPaid: cashPaid,
      creditType: creditType,
      selectedDays: activeDays,
      firstPaymentDate: firstPaymentDate,
      firstPaymentAmount: double.tryParse(firstPaymentAmtCtrl.text) ?? 0.0,
      startingDate: startingDate,
      perInstallmentAmount: double.tryParse(perDayCtrl.text) ?? 0.0,
      customDaysLimit: int.tryParse(customDaysLimitCtrl.text),
      transactionMode: transactionMode,
      bankId: selectedBankId,
      bankName: selectedBankName,
      screenshotBase64: bankScreenshotBase64,
      chequeNumber: chequeNumberCtrl.text,
      chequeDate: chequeDate,
    );

    if (success) widget.onSaveSuccess();
  }

  // ── Bank dropdown widget (reusable) ──
  Widget _buildBankDropdown() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('company_finances')
          .doc('main_finances')
          .collection('banks')
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData)
          return const LinearProgressIndicator(color: Colors.black);
        var bankDocs = snapshot.data!.docs;
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: Colors.black45),
            borderRadius: BorderRadius.circular(8),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              isExpanded: true,
              dropdownColor: Colors.white,
              focusColor: Colors.white,
              hint: Text(
                "Choose a Bank...",
                style: GoogleFonts.comicNeue(
                  color: Colors.black54,
                  fontWeight: FontWeight.bold,
                ),
              ),
              value: selectedBankId,
              style: GoogleFonts.comicNeue(
                color: Colors.black,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
              icon: const Icon(Icons.arrow_drop_down, color: Colors.black),
              items: bankDocs.map((doc) {
                var d = doc.data() as Map<String, dynamic>;
                String name =
                    "${d['name'] ?? d['bankName']} - ${d['accountTitle'] ?? ''}";
                return DropdownMenuItem(
                  value: doc.id,
                  child: Text(
                    name,
                    style: const TextStyle(color: Colors.black),
                  ),
                );
              }).toList(),
              onChanged: (v) {
                setState(() {
                  selectedBankId = v;
                  var bDoc = bankDocs.firstWhere((doc) => doc.id == v);
                  var d = bDoc.data() as Map<String, dynamic>;
                  selectedBankName =
                      "${d['name'] ?? d['bankName']} - ${d['accountTitle'] ?? ''}";
                });
              },
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    double tempRemaining =
        widget.totalBill - (double.tryParse(paidAmountCtrl.text) ?? 0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Payment Terms",
          style: GoogleFonts.comicNeue(
            fontWeight: FontWeight.bold,
            fontSize: 20,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 15),

        // ── Radio Buttons ──
        Wrap(
          spacing: 4,
          children: ["Pay Now", "Online", "Cheque", "Credit", "Both"].map((
            mode,
          ) {
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Radio<String>(
                  value: mode,
                  groupValue: paymentMode,
                  activeColor: Colors.black,
                  visualDensity: VisualDensity.compact,
                  onChanged: (val) => setState(() {
                    paymentMode = val!;
                    controller.installmentChart.clear();
                    selectedBankId = null;
                    selectedBankName = null;
                    bankScreenshotBase64 = null;
                    chequeDate = null;
                    chequeNumberCtrl.clear();

                    if (paymentMode == "Pay Now") {
                      paidAmountCtrl.text = widget.totalBill.toStringAsFixed(
                        0,
                      ); // ✅ Full amount set karo
                      transactionMode = "Cash";
                    } else if (paymentMode == "Online") {
                      paidAmountCtrl.text = widget.totalBill.toStringAsFixed(0);
                      transactionMode = "Bank Transfer";
                    } else if (paymentMode == "Cheque") {
                      paidAmountCtrl.text = widget.totalBill.toStringAsFixed(0);
                      transactionMode = "Cheque";
                    } else if (paymentMode == "Credit") {
                      paidAmountCtrl.text = "0";
                      transactionMode = "Cash";
                    } else if (paymentMode == "Both") {
                      paidAmountCtrl.clear();
                      transactionMode = "Cash";
                    }
                  }),
                ),
                Text(
                  mode,
                  style: GoogleFonts.comicNeue(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(width: 8),
              ],
            );
          }).toList(),
        ),

        const SizedBox(height: 20),

        if (paymentMode != "Credit") ...[
          _buildSimpleInput(
            "Paid Amount Now",
            paidAmountCtrl,
            isNum: true,
            readOnly:
                paymentMode == "Pay Now" ||
                paymentMode == "Online" ||
                paymentMode == "Cheque",
          ),
          const SizedBox(height: 15),

          // ── Pay Now: Cash or Bank Transfer ──
          if (paymentMode == "Pay Now") ...[
            Text(
              "Transaction Mode:",
              style: GoogleFonts.comicNeue(
                fontSize: 16,
                color: Colors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 5),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: Colors.black87, width: 1.5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  isExpanded: true,
                  dropdownColor: Colors.white,
                  focusColor: Colors.white,
                  value: transactionMode,
                  style: GoogleFonts.comicNeue(
                    fontSize: 16,
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                  icon: const Icon(Icons.arrow_drop_down, color: Colors.black),
                  items: ["Cash", "Bank Transfer"]
                      .map(
                        (e) => DropdownMenuItem(
                          value: e,
                          child: Text(
                            e,
                            style: const TextStyle(color: Colors.black),
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (v) => setState(() {
                    transactionMode = v!;
                    selectedBankId = null;
                    selectedBankName = null;
                    bankScreenshotBase64 = null;
                  }),
                ),
              ),
            ),
            const SizedBox(height: 15),
          ],

          // ── Both: transaction mode dropdown ──
          if (paymentMode == "Both") ...[
            Text(
              "Transaction Mode for Upfront Payment:",
              style: GoogleFonts.comicNeue(
                fontSize: 16,
                color: Colors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 5),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: Colors.black87, width: 1.5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  isExpanded: true,
                  dropdownColor: Colors.white,
                  focusColor: Colors.white,
                  value: transactionMode,
                  style: GoogleFonts.comicNeue(
                    fontSize: 16,
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                  icon: const Icon(Icons.arrow_drop_down, color: Colors.black),
                  items: ["Cash", "Bank Transfer", "Cheque"]
                      .map(
                        (e) => DropdownMenuItem(
                          value: e,
                          child: Text(
                            e,
                            style: const TextStyle(color: Colors.black),
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (v) => setState(() {
                    transactionMode = v!;
                    selectedBankId = null;
                    selectedBankName = null;
                    bankScreenshotBase64 = null;
                    chequeDate = null;
                    chequeNumberCtrl.clear();
                  }),
                ),
              ),
            ),
            const SizedBox(height: 15),
          ],

          // ── Bank Transfer section ──
          if (transactionMode == 'Bank Transfer') ...[
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade900),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Select Bank",
                    style: GoogleFonts.comicNeue(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 5),
                  _buildBankDropdown(),
                  const SizedBox(height: 15),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                    ),
                    onPressed: _pickImage,
                    icon: const Icon(Icons.image, color: Colors.white),
                    label: Text(
                      bankScreenshotBase64 == null
                          ? "Attach Screenshot"
                          : "Change Screenshot",
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                  if (bankScreenshotBase64 != null) ...[
                    const SizedBox(height: 10),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        height: 120,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.black26),
                        ),
                        child: Image.memory(
                          base64Decode(bankScreenshotBase64!),
                          height: 120,
                          width: double.infinity,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],

          // ── Cheque section (paymentMode==Cheque OR transactionMode==Cheque) ──
          if (paymentMode == 'Cheque' || transactionMode == 'Cheque') ...[
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.shade900),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Select Bank (Cheque ka)",
                    style: GoogleFonts.comicNeue(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 5),
                  _buildBankDropdown(),
                  const SizedBox(height: 15),
                  _buildSimpleInput("Cheque Number", chequeNumberCtrl),
                  const SizedBox(height: 15),
                  _buildDatePicker(
                    "Cheque Date (jab cash hoga)",
                    chequeDate,
                    () => _selectDate(context, onPicked: (d) => chequeDate = d),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 15),
          _buildInfoDisplay(
            "Remaining (This Bill)",
            "PKR ${tempRemaining.toStringAsFixed(0)}",
          ),
        ],

        // ── Credit / Both schedule ──
        if (paymentMode == "Credit" || paymentMode == "Both") ...[
          const Divider(height: 40, color: Colors.black54),
          Text(
            "Credit Schedule Options",
            style: GoogleFonts.comicNeue(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 15),
          Wrap(
            spacing: 10,
            children: ["Daily", "Weekly", "Monthly", "Custom"]
                .map(
                  (type) => ChoiceChip(
                    label: Text(
                      type,
                      style: GoogleFonts.comicNeue(
                        fontWeight: FontWeight.bold,
                        color: creditType == type ? Colors.white : Colors.black,
                      ),
                    ),
                    selected: creditType == type,
                    selectedColor: Colors.black,
                    backgroundColor: Colors.grey.shade300,
                    onSelected: (val) => setState(() {
                      creditType = type;
                      controller.installmentChart.clear();
                    }),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 20),

          if (creditType == "Custom") ...[
            Text(
              "Custom Settlement Strategy:",
              style: GoogleFonts.comicNeue(
                fontWeight: FontWeight.w900,
                fontSize: 18,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 15),
            Row(
              children: [
                Expanded(
                  child: _buildSimpleInput(
                    "First Scheduled Payment",
                    firstPaymentAmtCtrl,
                    isNum: true,
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: _buildDatePicker(
                    "First Payment Date",
                    firstPaymentDate,
                    () => _selectDate(
                      context,
                      onPicked: (d) => firstPaymentDate = d,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 15),
            _buildSimpleInput(
              "Maximum Days Limit (e.g. 45)",
              customDaysLimitCtrl,
              isNum: true,
              onChanged: (val) {
                int? days = int.tryParse(val);
                if (days != null && days > 0 && widget.totalBill > 0) {
                  _generateCustomChart(days);
                }
              },
            ),
            const SizedBox(height: 15),
            Text(
              "Chart auto-generates as you type days. Rows can also be managed manually from Ledger.",
              style: GoogleFonts.comicNeue(
                color: Colors.red.shade900,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Obx(
              () => controller.installmentChart.isEmpty
                  ? const SizedBox()
                  : _buildInstallmentTable(),
            ),
          ] else ...[
            Row(
              children: [
                Expanded(
                  child: _buildSimpleInput(
                    "First Scheduled Payment",
                    firstPaymentAmtCtrl,
                    isNum: true,
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: _buildDatePicker(
                    "First Payment Date",
                    firstPaymentDate,
                    () => _selectDate(
                      context,
                      onPicked: (d) => firstPaymentDate = d,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _buildDatePicker(
                    "Starting Date (Regular)",
                    startingDate,
                    () =>
                        _selectDate(context, onPicked: (d) => startingDate = d),
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: _buildSimpleInput(
                    "Installment Amount",
                    perDayCtrl,
                    isNum: true,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            if (creditType == "Daily") ...[
              Text(
                "Select Payment Days:",
                style: GoogleFonts.comicNeue(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                children: weekDays
                    .map(
                      (day) => FilterChip(
                        label: Text(
                          day.substring(0, 3),
                          style: GoogleFonts.comicNeue(
                            fontWeight: FontWeight.bold,
                            color: selectedDailyDays.contains(day)
                                ? Colors.white
                                : Colors.black,
                          ),
                        ),
                        selected: selectedDailyDays.contains(day),
                        selectedColor: Colors.black,
                        backgroundColor: Colors.grey.shade300,
                        onSelected: (val) => setState(() {
                          val
                              ? selectedDailyDays.add(day)
                              : selectedDailyDays.remove(day);
                        }),
                      ),
                    )
                    .toList(),
              ),
            ],

            if (creditType == "Weekly") ...[
              Text(
                "Select Day of Week:",
                style: GoogleFonts.comicNeue(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 5),
              DropdownButtonFormField<String>(
                value: selectedWeeklyDay,
                dropdownColor: Colors.white,
                items: weekDays
                    .map(
                      (e) => DropdownMenuItem(
                        value: e,
                        child: Text(
                          e,
                          style: GoogleFonts.comicNeue(
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (v) => setState(() => selectedWeeklyDay = v!),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(
                      color: Colors.black87,
                      width: 1.5,
                    ),
                  ),
                ),
              ),
            ],

            const SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                minimumSize: const Size.fromHeight(50),
              ),
              onPressed: () {
                controller.generatePreviewChart(
                  currentBill: tempRemaining,
                  firstPaymentAmount:
                      double.tryParse(firstPaymentAmtCtrl.text) ?? 0,
                  firstPaymentDate: firstPaymentDate,
                  perInstallment: double.tryParse(perDayCtrl.text) ?? 0,
                  startDate: startingDate,
                  type: creditType,
                );
              },
              child: Text(
                "Generate Projection Preview",
                style: GoogleFonts.comicNeue(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ),
            Obx(
              () => controller.installmentChart.isEmpty
                  ? const SizedBox()
                  : _buildInstallmentTable(),
            ),
          ],
        ],

        const SizedBox(height: 40),

        SizedBox(
          width: double.infinity,
          height: 60,
          child: Obx(
            () => ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green.shade900,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: controller.isLoading.value ? null : _processSave,
              child: controller.isLoading.value
                  ? const CircularProgressIndicator(color: Colors.white)
                  : Text(
                      "SAVE TRANSACTION",
                      style: GoogleFonts.comicNeue(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                        letterSpacing: 1.5,
                      ),
                    ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDatePicker(
    String label,
    DateTime? selected,
    VoidCallback onTap,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.comicNeue(
            fontSize: 16,
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 5),
        InkWell(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.black87, width: 1.5),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  selected == null
                      ? "Select Date"
                      : DateFormat('dd MMM, yyyy').format(selected),
                  style: GoogleFonts.comicNeue(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: selected == null ? Colors.black54 : Colors.black,
                  ),
                ),
                const Icon(Icons.calendar_month, color: Colors.black),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInstallmentTable() {
    return Container(
      margin: const EdgeInsets.only(top: 20),
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.black, width: 1.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          headingRowColor: MaterialStateProperty.all(Colors.grey.shade200),
          headingTextStyle: GoogleFonts.comicNeue(
            color: Colors.black,
            fontWeight: FontWeight.w900,
            fontSize: 16,
          ),
          dataTextStyle: GoogleFonts.comicNeue(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
          columnSpacing: 16,
          columns: const [
            DataColumn(label: Text("Date")),
            DataColumn(label: Text("Amt")),
            DataColumn(label: Text("Paid")),
            DataColumn(label: Text("Rem(Bill)")),
            DataColumn(label: Text("Rem(Tot)")),
            DataColumn(label: Text("Note")),
          ],
          rows: controller.installmentChart
              .map(
                (inst) => DataRow(
                  cells: [
                    DataCell(
                      Text(
                        inst['date'] == '-'
                            ? "-"
                            : "${inst['date']}\n${inst['day']}",
                      ),
                    ),
                    DataCell(Text(inst['amount'].toString())),
                    DataCell(
                      Text(
                        inst['paid'].toString(),
                        style: const TextStyle(color: Colors.green),
                      ),
                    ),
                    DataCell(
                      Text(
                        inst['remaining_product'].toString(),
                        style: const TextStyle(color: Colors.redAccent),
                      ),
                    ),
                    DataCell(
                      Text(
                        inst['remaining_total'].toString(),
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                    DataCell(
                      Text(
                        inst['note'].toString(),
                        style: const TextStyle(color: Colors.blueAccent),
                      ),
                    ),
                  ],
                ),
              )
              .toList(),
        ),
      ),
    );
  }

  Widget _buildSimpleInput(
    String label,
    TextEditingController ctrl, {
    bool isNum = false,
    bool readOnly = false,
    Function(String)? onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.comicNeue(
            fontSize: 16,
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 5),
        TextField(
          controller: ctrl,
          readOnly: readOnly,
          keyboardType: isNum ? TextInputType.number : TextInputType.text,
          onChanged: (v) {
            setState(() {});
            onChanged?.call(v);
          },
          style: GoogleFonts.comicNeue(
            fontSize: 16,
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
          decoration: InputDecoration(
            filled: true,
            fillColor: readOnly ? Colors.grey.shade200 : Colors.white,
            border: OutlineInputBorder(
              borderSide: const BorderSide(color: Colors.black87),
              borderRadius: BorderRadius.circular(8),
            ),
            enabledBorder: OutlineInputBorder(
              borderSide: const BorderSide(color: Colors.black54),
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ],
    );
  }

  void _generateCustomChart(int days) {
    double remaining =
        widget.totalBill - (double.tryParse(paidAmountCtrl.text) ?? 0);
    if (remaining <= 0) return;

    double perDay = remaining / days;
    DateTime startDate = firstPaymentDate ?? DateTime.now();

    controller.installmentChart.clear();
    controller.installmentChart.add({
      'date': '-',
      'day': '-',
      'amount': remaining.toStringAsFixed(0),
      'paid': '0',
      'remaining_product': remaining.toStringAsFixed(0),
      'remaining_total': remaining.toStringAsFixed(0),
      'note': 'Total Balance',
    });

    double runningRemaining = remaining;
    for (int i = 0; i < days; i++) {
      DateTime date = startDate.add(Duration(days: i));
      double payment = (i == days - 1) ? runningRemaining : perDay;
      runningRemaining -= payment;
      controller.installmentChart.add({
        'date': DateFormat('dd-MMM-yy').format(date),
        'day': DateFormat('EEE').format(date),
        'amount': payment.toStringAsFixed(0),
        'paid': '0',
        'remaining_product': runningRemaining
            .clamp(0, double.infinity)
            .toStringAsFixed(0),
        'remaining_total': runningRemaining
            .clamp(0, double.infinity)
            .toStringAsFixed(0),
        'note': 'Day ${i + 1}',
      });
    }
  }

  Widget _buildInfoDisplay(String label, String val) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.black45),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.comicNeue(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          Text(
            val,
            style: GoogleFonts.comicNeue(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: Colors.red.shade800,
            ),
          ),
        ],
      ),
    );
  }
}
