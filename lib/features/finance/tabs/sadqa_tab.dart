// Path: lib/features/finances/presentation/tabs/sadqa_tab.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../controller/admin_finance_controller.dart';
import '../models/ledger_transaction_model.dart';

class SadqaTab extends StatefulWidget {
  final AdminFinanceController controller;
  const SadqaTab({super.key, required this.controller});

  @override
  State<SadqaTab> createState() => _SadqaTabState();
}

class _SadqaTabState extends State<SadqaTab> {
  final _amountController = TextEditingController();
  final _descController = TextEditingController();
  final _chequeNumController = TextEditingController();

  String _selectedMethod = kPayCash;
  String? _selectedBankId;
  DateTime _selectedDate = DateTime.now();
  DateTime? _chequeDate;

  @override
  void dispose() {
    _amountController.dispose();
    _descController.dispose();
    _chequeNumController.dispose();
    super.dispose();
  }

  void _submit() async {
    final amount = double.tryParse(_amountController.text) ?? 0.0;
    final desc = _descController.text.trim();

    if (amount <= 0) {
      Get.snackbar(
        'Invalid Input',
        'Valid amount enter karein.',
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
      );
      return;
    }
    if (desc.isEmpty) {
      Get.snackbar(
        'Invalid Input',
        'Description zaroori hai.',
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
      );
      return;
    }

    String? bankName;
    if (_selectedBankId != null) {
      final bank = widget.controller.banks.firstWhere(
        (b) => b['id'] == _selectedBankId,
        orElse: () => {},
      );
      bankName = bank['name'];
    }

    final success = await widget.controller.submitSadqa(
      amount: amount,
      paymentMethod: _selectedMethod,
      description: desc,
      date: _selectedDate,
      bankId: _selectedBankId,
      bankName: bankName,
      chequeNumber: _selectedMethod == kPayCheque
          ? _chequeNumController.text
          : null,
      chequeDate: _selectedMethod == kPayCheque ? _chequeDate : null,
    );

    if (success) {
      _amountController.clear();
      _descController.clear();
      _chequeNumController.clear();
      setState(() {
        _selectedMethod = kPayCash;
        _selectedBankId = null;
        _selectedDate = DateTime.now();
        _chequeDate = null;
      });
    }
  }

  Future<void> _pickDate(bool isCheque) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isCheque ? (_chequeDate ?? DateTime.now()) : _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      builder: (context, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: const ColorScheme.dark(
            primary: Colors.cyanAccent,
            onPrimary: Colors.black,
            surface: Color(0xFF2C2C2C),
            onSurface: Colors.white,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() {
        if (isCheque) {
          _chequeDate = picked;
        } else {
          _selectedDate = picked;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildAddForm(),
        const Divider(color: Colors.white10, height: 1),
        Expanded(child: _buildHistoryList()),
      ],
    );
  }

  Widget _buildAddForm() {
    return Container(
      color: const Color(0xFF1E1E1E),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'RECORD SADQA',
            style: GoogleFonts.orbitron(
              color: Colors.cyanAccent,
              fontSize: 13,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildTextField(
                  _amountController,
                  'Amount',
                  icon: Icons.money,
                  isNum: true,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildDropdown(
                  value: _selectedMethod,
                  items: [kPayCash, kPayOnline, kPayCheque],
                  onChanged: (val) => setState(() {
                    _selectedMethod = val!;
                    if (val == kPayCash) _selectedBankId = null;
                  }),
                  labelMaker: AdminFinanceController.paymentMethodLabel,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (_selectedMethod != kPayCash) ...[
            Obx(
              () => _buildDropdown(
                hint: 'Select Bank Account',
                value: _selectedBankId,
                items: widget.controller.banks
                    .map((b) => b['id'].toString())
                    .toList(),
                onChanged: (val) => setState(() => _selectedBankId = val),
                labelMaker: (id) =>
                    widget.controller.banks.firstWhere(
                      (b) => b['id'] == id,
                    )['name'] ??
                    'Unknown',
              ),
            ),
            const SizedBox(height: 10),
          ],
          if (_selectedMethod == kPayCheque) ...[
            Row(
              children: [
                Expanded(
                  child: _buildTextField(
                    _chequeNumController,
                    'Cheque Number',
                    icon: Icons.numbers,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: InkWell(
                    onTap: () => _pickDate(true),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 12,
                        horizontal: 10,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2C2C2C),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _chequeDate == null
                                ? 'Cheque Date'
                                : DateFormat(
                                    'dd MMM yyyy',
                                  ).format(_chequeDate!),
                            style: GoogleFonts.comicNeue(
                              color: _chequeDate == null
                                  ? Colors.white38
                                  : Colors.white,
                            ),
                          ),
                          const Icon(
                            Icons.calendar_today,
                            color: Colors.cyanAccent,
                            size: 16,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
          ],
          _buildTextField(
            _descController,
            'Description (Madrasa / Person etc.)',
            icon: Icons.description,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () => _pickDate(false),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 12,
                      horizontal: 10,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2C2C2C),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.calendar_today,
                          color: Colors.cyanAccent,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          DateFormat('dd MMM yyyy').format(_selectedDate),
                          style: GoogleFonts.comicNeue(color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Obx(
                  () => ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.cyanAccent.withOpacity(0.15),
                      side: const BorderSide(color: Colors.cyanAccent),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: widget.controller.isSadqaSubmitting.value
                        ? null
                        : _submit,
                    child: widget.controller.isSadqaSubmitting.value
                        ? const SizedBox(
                            height: 16,
                            width: 16,
                            child: CircularProgressIndicator(
                              color: Colors.cyanAccent,
                              strokeWidth: 2,
                            ),
                          )
                        : Text(
                            'SUBMIT SADQA',
                            style: GoogleFonts.orbitron(
                              color: Colors.cyanAccent,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryList() {
    return Obx(() {
      final list = widget.controller.sadqaEntries;
      if (list.isEmpty) {
        return Center(
          child: Text(
            'No sadqa records found for this period.',
            style: GoogleFonts.comicNeue(color: Colors.white38, fontSize: 14),
          ),
        );
      }
      return ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: list.length,
        itemBuilder: (context, i) {
          final entry = list[i];
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF252525),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.white10),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.redAccent.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.favorite,
                    color: Colors.redAccent,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        entry.description,
                        style: GoogleFonts.comicNeue(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            AdminFinanceController.paymentMethodLabel(
                              entry.paymentMethod,
                            ),
                            style: GoogleFonts.comicNeue(
                              color: Colors.cyanAccent,
                              fontSize: 11,
                            ),
                          ),
                          if (entry.bankName != null) ...[
                            Text(
                              ' • ',
                              style: TextStyle(color: Colors.white38),
                            ),
                            Text(
                              entry.bankName!,
                              style: GoogleFonts.comicNeue(
                                color: Colors.white54,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Rs. ${entry.amount.toStringAsFixed(0)}',
                      style: GoogleFonts.comicNeue(
                        color: Colors.redAccent,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      DateFormat('dd MMM yy').format(entry.date),
                      style: GoogleFonts.comicNeue(
                        color: Colors.white38,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      );
    });
  }

  Widget _buildTextField(
    TextEditingController ctrl,
    String hint, {
    IconData? icon,
    bool isNum = false,
  }) {
    return TextField(
      controller: ctrl,
      keyboardType: isNum ? TextInputType.number : TextInputType.text,
      style: GoogleFonts.comicNeue(color: Colors.white, fontSize: 13),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white38, fontSize: 12),
        prefixIcon: icon != null
            ? Icon(icon, color: Colors.white38, size: 16)
            : null,
        filled: true,
        fillColor: const Color(0xFF2C2C2C),
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 10,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget _buildDropdown({
    required String? value,
    required List<String> items,
    required Function(String?) onChanged,
    required String Function(String) labelMaker,
    String? hint,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF2C2C2C),
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          hint: hint != null
              ? Text(
                  hint,
                  style: const TextStyle(color: Colors.white38, fontSize: 12),
                )
              : null,
          isExpanded: true,
          dropdownColor: const Color(0xFF2C2C2C),
          icon: const Icon(Icons.arrow_drop_down, color: Colors.cyanAccent),
          style: GoogleFonts.comicNeue(color: Colors.white, fontSize: 13),
          items: items
              .map(
                (e) => DropdownMenuItem(value: e, child: Text(labelMaker(e))),
              )
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}
