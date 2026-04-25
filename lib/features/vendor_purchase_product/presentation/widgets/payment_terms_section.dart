import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
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
  String paymentMode = "Cash";
  String creditType = "Daily";

  final paidAmountCtrl = TextEditingController();
  final perDayCtrl = TextEditingController();
  final firstPaymentAmtCtrl = TextEditingController();
  final customDaysLimitCtrl = TextEditingController(); // ✅ NAYA CONTROLLER

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

  Future<void> _selectDate(BuildContext context, bool isFirstPayment) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
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
      setState(() {
        if (isFirstPayment) {
          firstPaymentDate = picked;
        } else {
          startingDate = picked;
        }
      });
    }
  }

  // ✅ Validation & Saving process
  void _processSave() async {
    if (widget.totalBill <= 0) {
      Get.snackbar(
        "Required",
        "Please add at least one product to the bill.",
        backgroundColor: Colors.orange,
        colorText: Colors.white,
      );
      return;
    }

    double cashPaid = double.tryParse(paidAmountCtrl.text) ?? 0.0;

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
      customDaysLimit: int.tryParse(customDaysLimitCtrl.text), // ✅ NAYA
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

        Row(
          children: ["Cash", "Credit", "Both"]
              .map(
                (mode) => Expanded(
                  child: RadioListTile(
                    title: Text(
                      mode,
                      style: GoogleFonts.comicNeue(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    value: mode,
                    groupValue: paymentMode,
                    activeColor: Colors.black,
                    onChanged: (val) => setState(() {
                      paymentMode = val!;
                      controller.installmentChart.clear();
                    }),
                  ),
                ),
              )
              .toList(),
        ),

        const SizedBox(height: 20),

        if (paymentMode == "Cash" || paymentMode == "Both") ...[
          _buildSimpleInput("Paid Amount (Cash)", paidAmountCtrl, isNum: true),
          const SizedBox(height: 10),
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

          // ✅ NAYA: Custom Mode UI Update
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
                    "First Payment Amount",
                    firstPaymentAmtCtrl,
                    isNum: true,
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: _buildDatePicker(
                    "First Payment Date",
                    firstPaymentDate,
                    () => _selectDate(context, true),
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
            // ✅ Standard Credit Mode Inputs
            Row(
              children: [
                Expanded(
                  child: _buildSimpleInput(
                    "First Payment Amount",
                    firstPaymentAmtCtrl,
                    isNum: true,
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: _buildDatePicker(
                    "First Payment Date",
                    firstPaymentDate,
                    () => _selectDate(context, true),
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
                    () => _selectDate(context, false),
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
          keyboardType: isNum ? TextInputType.number : TextInputType.text,
          onChanged: (v) => setState(() {}),
          style: GoogleFonts.comicNeue(
            fontSize: 16,
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white,
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
