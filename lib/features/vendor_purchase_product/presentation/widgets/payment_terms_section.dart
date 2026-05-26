import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
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

  // ✅ UPDATED MODES: Cash, Online, Credit, Both
  String paymentMode = "Cash";
  String creditType = "Daily";

  // Actual Transaction Mode for the Upfront part
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

  List<String> weekDays = [
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
    // Default Cash selection locks the amount to Total Bill
    paidAmountCtrl.text = widget.totalBill.toStringAsFixed(0);
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 50,
    );
    if (pickedFile != null) {
      CroppedFile? croppedFile = await ImageCropper().cropImage(
        sourcePath: pickedFile.path,
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Crop Screenshot',
            toolbarColor: Colors.black,
            toolbarWidgetColor: Colors.white,
            initAspectRatio: CropAspectRatioPreset.original,
            lockAspectRatio: false,
          ),
          IOSUiSettings(title: 'Crop Screenshot'),
          // ✅ FIX: Web UI Settings added to prevent crash on Flutter Web
          WebUiSettings(context: context, presentStyle: WebPresentStyle.dialog),
        ],
      );
      if (croppedFile != null) {
        final bytes = await croppedFile.readAsBytes();
        setState(() {
          bankScreenshotBase64 = base64Encode(bytes);
        });
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
      builder: (context, child) {
        return Theme(
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
        );
      },
    );
    if (picked != null) {
      setState(() => onPicked(picked));
    }
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

    // ✅ STRICT AMOUNT VALIDATIONS
    if (paymentMode == "Cash" || paymentMode == "Online") {
      if (cashPaid != widget.totalBill) {
        Get.snackbar(
          "Amount Limit",
          "For $paymentMode, paid amount must be exactly equal to Total Bill (PKR ${widget.totalBill}).",
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

    // ✅ REQUIRED BANK & CHEQUE VALIDATIONS
    if (transactionMode == 'Bank Transfer' && selectedBankId == null) {
      Get.snackbar(
        "Required",
        "Please select a bank.",
        backgroundColor: Colors.red.shade900,
        colorText: Colors.white,
      );
      return;
    }
    if (transactionMode == 'Cheque' && chequeNumberCtrl.text.isEmpty) {
      Get.snackbar(
        "Required",
        "Please enter cheque number.",
        backgroundColor: Colors.red.shade900,
        colorText: Colors.white,
      );
      return;
    }

    List<String> activeDays = [];
    if (creditType == "Daily") activeDays = selectedDailyDays;
    if (creditType == "Weekly") activeDays = [selectedWeeklyDay];

    bool success = await controller.submitTransaction(
      totalBill: widget.totalBill,
      paymentMode: paymentMode,
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

    if (success) {
      widget.onSaveSuccess();
    }
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

        // ✅ MODIFIED RADIO BUTTONS
        Row(
          children: ["Pay Now", "Online", "Credit", "Both"]
              .map(
                (mode) => Expanded(
                  child: Row(
                    children: [
                      Radio<String>(
                        value: mode,
                        groupValue: paymentMode,
                        activeColor: Colors.black,
                        visualDensity: VisualDensity.compact,
                        onChanged: (val) => setState(() {
                          paymentMode = val!;
                          controller.installmentChart.clear();
                          if (paymentMode == "Cash") {
                            paidAmountCtrl.text = widget.totalBill
                                .toStringAsFixed(0);
                            transactionMode = "Cash";
                          } else if (paymentMode == "Online") {
                            paidAmountCtrl.text = widget.totalBill
                                .toStringAsFixed(0);
                            transactionMode = "Bank Transfer";
                          } else if (paymentMode == "Credit") {
                            paidAmountCtrl.text = "0";
                            transactionMode = "Cash";
                          } else if (paymentMode == "Both") {
                            paidAmountCtrl.clear();
                            transactionMode = "Cash";
                          }
                        }),
                      ),
                      Expanded(
                        child: Text(
                          mode,
                          style: GoogleFonts.comicNeue(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              )
              .toList(),
        ),

        const SizedBox(height: 20),

        if (paymentMode != "Credit") ...[
          _buildSimpleInput(
            "Paid Amount Now",
            paidAmountCtrl,
            isNum: true,
            readOnly: paymentMode == "Cash" || paymentMode == "Online",
          ),
          const SizedBox(height: 15),

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
                  dropdownColor: Colors.white, // ✅ FIX: Force White Background
                  focusColor: Colors.white, // ✅ FIX: Force focus color to white
                  value: transactionMode,
                  style: GoogleFonts.comicNeue(
                    fontSize: 16,
                    color: Colors.black, // ✅ FIX: Force black text
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
                          ), // ✅ FIX
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

          // ✅ BANK TRANSFER DETAILS
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
                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('company_finances')
                        .doc('main_finances')
                        .collection('banks')
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData)
                        return const LinearProgressIndicator();
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
                            dropdownColor: Colors.white, // ✅ FIX: Background
                            focusColor: Colors.white, // ✅ FIX: Focus color
                            hint: Text(
                              "Choose a Bank...",
                              style: GoogleFonts.comicNeue(
                                color: Colors.black54,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            value: selectedBankId,
                            style: GoogleFonts.comicNeue(
                              color: Colors.black, // ✅ FIX: Black selected text
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                            icon: const Icon(
                              Icons.arrow_drop_down,
                              color: Colors.black,
                            ),
                            items: bankDocs.map((doc) {
                              var d = doc.data() as Map<String, dynamic>;
                              String name =
                                  "${d['name'] ?? d['bankName']} - ${d['accountTitle']}";
                              return DropdownMenuItem(
                                value: doc.id,
                                child: Text(
                                  name,
                                  style: const TextStyle(color: Colors.black),
                                ), // ✅ FIX
                              );
                            }).toList(),
                            onChanged: (v) {
                              setState(() {
                                selectedBankId = v;
                                var bDoc = bankDocs.firstWhere(
                                  (doc) => doc.id == v,
                                );
                                var d = bDoc.data() as Map<String, dynamic>;
                                selectedBankName =
                                    "${d['name'] ?? d['bankName']} - ${d['accountTitle']}";
                              });
                            },
                          ),
                        ),
                      );
                    },
                  ),
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
                      child: Image.memory(
                        base64Decode(bankScreenshotBase64!),
                        height: 100,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ] else if (transactionMode == 'Cheque') ...[
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.shade900),
              ),
              child: Column(
                children: [
                  _buildSimpleInput("Cheque Number", chequeNumberCtrl),
                  const SizedBox(height: 15),
                  _buildDatePicker(
                    "Cheque Date",
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
            ),
            const SizedBox(height: 15),
            Text(
              "Note: Custom mode does not generate a predefined chart. Rows will be managed manually from Ledger.",
              style: GoogleFonts.comicNeue(
                color: Colors.red.shade900,
                fontWeight: FontWeight.bold,
              ),
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
                        onSelected: (val) {
                          setState(() {
                            val
                                ? selectedDailyDays.add(day)
                                : selectedDailyDays.remove(day);
                          });
                        },
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
            fontSize: 18,
          ),
          dataTextStyle: GoogleFonts.comicNeue(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
          columnSpacing: 20,
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
          onChanged: (v) => setState(() {}),
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
