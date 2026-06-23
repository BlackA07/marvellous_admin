// Path: lib/features/finances/presentation/screens/ExpensesScreen.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../controller/finance_controller.dart';
import '../models/finance_models.dart';

class ExpensesScreen extends StatefulWidget {
  @override
  _ExpensesScreenState createState() => _ExpensesScreenState();
}

class _ExpensesScreenState extends State<ExpensesScreen> {
  final FinanceController controller = Get.put(FinanceController());
  String? selectedCategory;
  String? selectedSubcategory;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Expenses',
          style: GoogleFonts.orbitron(color: Colors.white),
        ),
        actions: [
          TextButton.icon(
            icon: const Icon(Icons.settings, color: Colors.cyanAccent),
            label: Text(
              'Manage Categories',
              style: GoogleFonts.orbitron(color: Colors.cyanAccent),
            ),
            onPressed: () => _manageCategoriesDialog(),
          ),
        ],
      ),
      body: Obx(() {
        final categories = controller.expenseCategories
            .map((e) => e.name)
            .toList();
        final catModel = controller.expenseCategories.firstWhereOrNull(
          (c) => c.name == selectedCategory,
        );
        final subcategories =
            catModel?.subcategories.map((s) => s.name).toList() ?? [];

        if (selectedCategory != null &&
            !categories.contains(selectedCategory)) {
          selectedCategory = null;
          selectedSubcategory = null;
        }
        if (selectedSubcategory != null &&
            !subcategories.contains(selectedSubcategory)) {
          selectedSubcategory = null;
        }

        final selectedSubModel = catModel?.subcategories.firstWhereOrNull(
          (s) => s.name == selectedSubcategory,
        );

        double catTotal = 0.0;
        double subcatTotal = 0.0;
        List<ExpenseModel> tableData = [];
        for (var e in controller.expenses) {
          if (e.category == selectedCategory) catTotal += e.amount;
          if (e.category == selectedCategory &&
              e.subcategory == selectedSubcategory) {
            subcatTotal += e.amount;
            tableData.add(e);
          }
        }
        tableData.sort((a, b) => a.date.compareTo(b.date));

        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: _dropdown(
                      'Select Category',
                      categories,
                      selectedCategory,
                      (val) => setState(() {
                        selectedCategory = val;
                        selectedSubcategory = null;
                      }),
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: _dropdown(
                      'Select Subcategory',
                      subcategories,
                      selectedSubcategory,
                      (val) => setState(() => selectedSubcategory = val),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              if (selectedCategory != null)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Category Total: PKR ${catTotal.toStringAsFixed(0)}',
                      style: GoogleFonts.comicNeue(
                        color: Colors.white70,
                        fontSize: 16,
                      ),
                    ),
                    if (selectedSubcategory != null)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            'Subcategory Total: PKR ${subcatTotal.toStringAsFixed(0)}',
                            style: GoogleFonts.comicNeue(
                              color: Colors.cyanAccent,
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                          if (selectedSubModel != null)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: selectedSubModel.type == 'fixed'
                                    ? Colors.amberAccent.withOpacity(0.2)
                                    : Colors.greenAccent.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: selectedSubModel.type == 'fixed'
                                      ? Colors.amberAccent
                                      : Colors.greenAccent,
                                ),
                              ),
                              child: Text(
                                selectedSubModel.type == 'fixed'
                                    ? '📌 Fixed: PKR ${selectedSubModel.fixedAmount.toStringAsFixed(0)}'
                                    : '📊 Variable Expense',
                                style: TextStyle(
                                  color: selectedSubModel.type == 'fixed'
                                      ? Colors.amberAccent
                                      : Colors.greenAccent,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                        ],
                      ),
                  ],
                ),
              const SizedBox(height: 20),
              if (selectedSubcategory != null) ...[
                Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.cyanAccent,
                    ),
                    icon: const Icon(Icons.add, color: Colors.black),
                    label: const Text(
                      'Add Entry',
                      style: TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    onPressed: () => _expenseDialog(
                      fixedAmount: selectedSubModel?.type == 'fixed'
                          ? selectedSubModel?.fixedAmount
                          : null,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF2C2C2C),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.white24),
                    ),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: SingleChildScrollView(
                        child: DataTable(
                          headingTextStyle: GoogleFonts.orbitron(
                            color: Colors.cyanAccent,
                            fontWeight: FontWeight.bold,
                          ),
                          dataTextStyle: const TextStyle(color: Colors.white),
                          columns: const [
                            DataColumn(label: Text('Date')),
                            DataColumn(label: Text('Description')),
                            DataColumn(label: Text('Bank/Cash')),
                            DataColumn(label: Text('Amount')),
                            DataColumn(label: Text('Actions')),
                          ],
                          rows: _buildRows(tableData),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      }),
    );
  }

  List<DataRow> _buildRows(List<ExpenseModel> sortedData) {
    List<DataRow> rows = [];
    for (var exp in sortedData) {
      final bankName =
          controller.banks.firstWhereOrNull((b) => b.id == exp.bankId)?.name ??
          'Unknown';
      rows.add(
        DataRow(
          cells: [
            DataCell(Text(exp.date.toString().substring(0, 10))),
            DataCell(Text(exp.description)),
            DataCell(Text(bankName)),
            DataCell(
              Text(
                exp.amount.toStringAsFixed(0),
                style: const TextStyle(color: Colors.redAccent),
              ),
            ),
            DataCell(
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit, color: Colors.white, size: 18),
                    onPressed: () => _expenseDialog(expToEdit: exp),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red, size: 18),
                    onPressed: () => _confirmDelete(exp),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }
    return rows.reversed.toList();
  }

  Widget _dropdown(
    String hint,
    List<String> items,
    String? val,
    Function(String?) onChanged,
  ) {
    return DropdownButtonFormField<String>(
      decoration: const InputDecoration(
        filled: true,
        fillColor: Color(0xFF2C2C2C),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.white24),
        ),
      ),
      dropdownColor: const Color(0xFF2C2C2C),
      hint: Text(hint, style: const TextStyle(color: Colors.white54)),
      value: val,
      items: items
          .map(
            (e) => DropdownMenuItem(
              value: e,
              child: Text(e, style: const TextStyle(color: Colors.white)),
            ),
          )
          .toList(),
      onChanged: onChanged,
    );
  }

  void _manageCategoriesDialog() {
    Get.defaultDialog(
      backgroundColor: const Color(0xFF2C2C2C),
      title: 'Manage Categories',
      titleStyle: const TextStyle(color: Colors.white),
      content: SizedBox(
        height: 300,
        width: 300,
        child: Obx(
          () => ListView.builder(
            itemCount: controller.expenseCategories.length,
            itemBuilder: (ctx, i) {
              final cat = controller.expenseCategories[i];
              return ListTile(
                title: Text(
                  cat.name,
                  style: const TextStyle(
                    color: Colors.cyanAccent,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: Text(
                  cat.subcategories
                      .map(
                        (s) =>
                            '${s.name} (${s.type == 'fixed' ? 'Fixed: ${s.fixedAmount.toStringAsFixed(0)}' : 'Variable'})',
                      )
                      .join(', '),
                  style: const TextStyle(color: Colors.white70, fontSize: 11),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(
                        Icons.edit,
                        color: Colors.white,
                        size: 16,
                      ),
                      onPressed: () {
                        Get.back();
                        _addCategoryDialog(cat: cat);
                      },
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.delete,
                        color: Colors.red,
                        size: 16,
                      ),
                      onPressed: () => controller.removeCategory(cat.id!),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
      confirm: ElevatedButton(
        style: ElevatedButton.styleFrom(backgroundColor: Colors.cyanAccent),
        onPressed: () {
          Get.back();
          _addCategoryDialog();
        },
        child: const Text(
          'Add New Category',
          style: TextStyle(color: Colors.black),
        ),
      ),
    );
  }

  void _addCategoryDialog({ExpenseCategoryModel? cat}) {
    final nameCtrl = TextEditingController(text: cat?.name);
    List<SubcategoryModel> subcategories =
        cat?.subcategories
            .map(
              (s) => SubcategoryModel(
                name: s.name,
                type: s.type,
                fixedAmount: s.fixedAmount,
              ),
            )
            .toList() ??
        [];

    final newSubNameCtrl = TextEditingController();
    String newSubType = 'variable';
    final newSubAmtCtrl = TextEditingController();

    Get.defaultDialog(
      backgroundColor: const Color(0xFF2C2C2C),
      title: cat == null ? 'Add Category' : 'Edit Category',
      titleStyle: const TextStyle(color: Colors.white),
      content: StatefulBuilder(
        builder: (ctx, setState) => SizedBox(
          width: Get.width * 0.85,
          height: Get.height * 0.65,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: nameCtrl,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    hintText: 'Category Name',
                    hintStyle: TextStyle(color: Colors.white54),
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.cyanAccent),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Subcategories:',
                  style: TextStyle(
                    color: Colors.cyanAccent,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                if (subcategories.isEmpty)
                  const Text(
                    'Koi subcategory nahi. Neeche se add karo.',
                    style: TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                ...subcategories.asMap().entries.map((entry) {
                  final idx = entry.key;
                  final sub = entry.value;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 6),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white10,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: sub.type == 'fixed'
                            ? Colors.amberAccent.withOpacity(0.5)
                            : Colors.greenAccent.withOpacity(0.5),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                sub.name,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                sub.type == 'fixed'
                                    ? '📌 Fixed: PKR ${sub.fixedAmount.toStringAsFixed(0)}'
                                    : '📊 Variable',
                                style: TextStyle(
                                  color: sub.type == 'fixed'
                                      ? Colors.amberAccent
                                      : Colors.greenAccent,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.delete,
                            color: Colors.redAccent,
                            size: 16,
                          ),
                          onPressed: () =>
                              setState(() => subcategories.removeAt(idx)),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                  );
                }).toList(),
                const Divider(color: Colors.white24),
                const Text(
                  'Nai Subcategory Add Karo:',
                  style: TextStyle(
                    color: Colors.white70,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: newSubNameCtrl,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    hintText: 'Subcategory Name (e.g. Office Rent)',
                    hintStyle: TextStyle(color: Colors.white54, fontSize: 13),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.white24),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.cyanAccent),
                    ),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 10,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Text(
                      'Type: ',
                      style: TextStyle(color: Colors.white70),
                    ),
                    const SizedBox(width: 8),
                    ChoiceChip(
                      label: const Text('Fixed'),
                      selected: newSubType == 'fixed',
                      selectedColor: Colors.amberAccent,
                      labelStyle: TextStyle(
                        color: newSubType == 'fixed'
                            ? Colors.black
                            : Colors.white70,
                      ),
                      onSelected: (v) => setState(() => newSubType = 'fixed'),
                    ),
                    const SizedBox(width: 8),
                    ChoiceChip(
                      label: const Text('Variable'),
                      selected: newSubType == 'variable',
                      selectedColor: Colors.greenAccent,
                      labelStyle: TextStyle(
                        color: newSubType == 'variable'
                            ? Colors.black
                            : Colors.white70,
                      ),
                      onSelected: (v) =>
                          setState(() => newSubType = 'variable'),
                    ),
                  ],
                ),
                if (newSubType == 'fixed') ...[
                  const SizedBox(height: 8),
                  TextField(
                    controller: newSubAmtCtrl,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      hintText: 'Fixed Amount (e.g. 30000)',
                      hintStyle: TextStyle(color: Colors.white54, fontSize: 13),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.amberAccent),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.white),
                      ),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 10,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white12,
                      side: const BorderSide(color: Colors.cyanAccent),
                    ),
                    icon: const Icon(Icons.add, color: Colors.cyanAccent),
                    label: const Text(
                      'Add Subcategory',
                      style: TextStyle(color: Colors.cyanAccent),
                    ),
                    onPressed: () {
                      final subName = newSubNameCtrl.text.trim();
                      if (subName.isEmpty) {
                        Get.snackbar(
                          'Error',
                          'Subcategory ka naam likho',
                          backgroundColor: Colors.red,
                          colorText: Colors.white,
                        );
                        return;
                      }
                      setState(() {
                        subcategories.add(
                          SubcategoryModel(
                            name: subName,
                            type: newSubType,
                            fixedAmount: newSubType == 'fixed'
                                ? (double.tryParse(newSubAmtCtrl.text) ?? 0)
                                : 0,
                          ),
                        );
                        newSubNameCtrl.clear();
                        newSubAmtCtrl.clear();
                        newSubType = 'variable';
                      });
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      confirm: ElevatedButton(
        style: ElevatedButton.styleFrom(backgroundColor: Colors.cyanAccent),
        onPressed: () {
          if (nameCtrl.text.trim().isEmpty) return;
          controller.saveCategory(
            ExpenseCategoryModel(
              id: cat?.id,
              name: nameCtrl.text.trim(),
              subcategories: subcategories,
            ),
          );
          Get.back();
        },
        child: const Text('Save', style: TextStyle(color: Colors.black)),
      ),
    );
  }

  void _expenseDialog({ExpenseModel? expToEdit, double? fixedAmount}) {
    final descCtrl = TextEditingController(text: expToEdit?.description);
    final amtCtrl = TextEditingController(
      text:
          expToEdit?.amount.toStringAsFixed(0) ??
          (fixedAmount != null && fixedAmount > 0
              ? fixedAmount.toStringAsFixed(0)
              : ''),
    );
    String? bankId = expToEdit?.bankId;
    DateTime d = expToEdit?.date ?? DateTime.now();

    Get.defaultDialog(
      backgroundColor: const Color(0xFF2C2C2C),
      title: expToEdit == null ? 'Add Entry' : 'Edit Entry',
      titleStyle: const TextStyle(color: Colors.white),
      content: StatefulBuilder(
        builder: (ctx, setDState) => SizedBox(
          width: Get.width * 0.85,
          child: Column(
            children: [
              TextField(
                controller: descCtrl,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  hintText: 'Description',
                  hintStyle: TextStyle(color: Colors.white54),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: amtCtrl,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Amount',
                  hintStyle: const TextStyle(color: Colors.white54),
                  suffixIcon: fixedAmount != null && fixedAmount > 0
                      ? Tooltip(
                          message: 'Fixed expense',
                          child: const Icon(
                            Icons.lock,
                            color: Colors.amberAccent,
                            size: 18,
                          ),
                        )
                      : null,
                ),
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  filled: true,
                  fillColor: Color(0xFF2C2C2C),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.white24),
                  ),
                ),
                dropdownColor: const Color(0xFF2C2C2C),
                value: bankId,
                hint: const Text(
                  'Select Bank/Cash',
                  style: TextStyle(color: Colors.white54),
                ),
                items: controller.banks.map((b) {
                  return DropdownMenuItem(
                    value: b.id,
                    child: Text(
                      '${b.name}  (PKR ${b.balance.toStringAsFixed(0)})',
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                    ),
                  );
                }).toList(),
                onChanged: (val) => setDState(() => bankId = val),
              ),
              ListTile(
                title: Text(
                  d.toString().substring(0, 10),
                  style: const TextStyle(color: Colors.white),
                ),
                trailing: const Icon(
                  Icons.calendar_today,
                  color: Colors.cyanAccent,
                ),
                onTap: () async {
                  DateTime? dt = await showDatePicker(
                    context: context,
                    initialDate: d,
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2100),
                  );
                  if (dt != null) setDState(() => d = dt);
                },
              ),
            ],
          ),
        ),
      ),
      confirm: ElevatedButton(
        style: ElevatedButton.styleFrom(backgroundColor: Colors.cyanAccent),
        onPressed: () async {
          if (bankId == null || amtCtrl.text.isEmpty) return;
          final e = ExpenseModel(
            id: expToEdit?.id,
            category: selectedCategory!,
            subcategory: selectedSubcategory!,
            description: descCtrl.text,
            amount: double.tryParse(amtCtrl.text) ?? 0,
            date: d,
            bankId: bankId!,
          );
          if (expToEdit == null) {
            await controller.createExpense(e);
          } else {
            await controller.editExpense(expToEdit, e);
          }

          Get.back();
        },
        child: const Text('Save', style: TextStyle(color: Colors.black)),
      ),
    );
  }

  void _confirmDelete(ExpenseModel exp) {
    Get.defaultDialog(
      backgroundColor: const Color(0xFF2C2C2C),
      title: 'Confirm Delete',
      titleStyle: const TextStyle(color: Colors.redAccent),
      middleText: 'Delete this entry? Amount will be refunded.',
      middleTextStyle: const TextStyle(color: Colors.white),
      textConfirm: 'Delete',
      textCancel: 'Cancel',
      confirmTextColor: Colors.white,
      cancelTextColor: Colors.cyanAccent,
      buttonColor: Colors.redAccent,
      onConfirm: () {
        controller.removeExpense(exp);
        Get.back();
      },
    );
  }
}
