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
  final FinanceController controller = Get.find();
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
        final subcategories = catModel?.subcategories ?? [];
        if (selectedCategory != null &&
            !categories.contains(selectedCategory)) {
          selectedCategory = null;
          selectedSubcategory = null;
        }
        if (selectedSubcategory != null &&
            !subcategories.contains(selectedSubcategory))
          selectedSubcategory = null;
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
                      'Category Total: PKR $catTotal',
                      style: GoogleFonts.comicNeue(
                        color: Colors.white70,
                        fontSize: 16,
                      ),
                    ),
                    if (selectedSubcategory != null)
                      Text(
                        'Subcategory Total: PKR $subcatTotal',
                        style: GoogleFonts.comicNeue(
                          color: Colors.cyanAccent,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
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
                    onPressed: () => _expenseDialog(),
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
                            DataColumn(label: Text('Prev Balance')),
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
    double runningBalance = 0.0;
    List<DataRow> rows = [];
    for (var exp in sortedData) {
      final prev = runningBalance;
      runningBalance += exp.amount;
      final bankName =
          controller.banks.firstWhereOrNull((b) => b.id == exp.bankId)?.name ??
          'Unknown';
      rows.add(
        DataRow(
          cells: [
            DataCell(Text(exp.date.toString().substring(0, 10))),
            DataCell(Text(exp.description)),
            DataCell(Text(bankName)),
            DataCell(Text(prev.toString())),
            DataCell(
              Text(
                exp.amount.toString(),
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
                  cat.subcategories.join(', '),
                  style: const TextStyle(color: Colors.white70),
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
    final subsCtrl = TextEditingController(text: cat?.subcategories.join(','));
    Get.defaultDialog(
      backgroundColor: const Color(0xFF2C2C2C),
      title: cat == null ? 'Add Category' : 'Edit Category',
      titleStyle: const TextStyle(color: Colors.white),
      content: Column(
        children: [
          TextField(
            controller: nameCtrl,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              hintText: 'Category Name',
              hintStyle: TextStyle(color: Colors.white54),
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: subsCtrl,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              hintText: 'Subcategories (comma separated)',
              hintStyle: TextStyle(color: Colors.white54),
            ),
          ),
        ],
      ),
      confirm: ElevatedButton(
        style: ElevatedButton.styleFrom(backgroundColor: Colors.cyanAccent),
        onPressed: () {
          final subs = subsCtrl.text
              .split(',')
              .map((e) => e.trim())
              .where((e) => e.isNotEmpty)
              .toList();
          controller.saveCategory(
            ExpenseCategoryModel(
              id: cat?.id,
              name: nameCtrl.text.trim(),
              subcategories: subs,
            ),
          );
          Get.back();
        },
        child: const Text('Save', style: TextStyle(color: Colors.black)),
      ),
    );
  }

  void _expenseDialog({ExpenseModel? expToEdit}) {
    final descCtrl = TextEditingController(text: expToEdit?.description);
    final amtCtrl = TextEditingController(text: expToEdit?.amount.toString());
    String? bankId = expToEdit?.bankId;
    DateTime d = expToEdit?.date ?? DateTime.now();
    Get.defaultDialog(
      backgroundColor: const Color(0xFF2C2C2C),
      title: expToEdit == null ? 'Add Entry' : 'Edit Entry',
      titleStyle: const TextStyle(color: Colors.white),
      content: StatefulBuilder(
        builder: (ctx, setDState) => Column(
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
              decoration: const InputDecoration(
                hintText: 'Amount',
                hintStyle: TextStyle(color: Colors.white54),
              ),
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                filled: true,
                fillColor: Color(0xFF2C2C2C),
              ),
              dropdownColor: const Color(0xFF2C2C2C),
              value: bankId,
              hint: const Text(
                'Select Bank/Cash',
                style: TextStyle(color: Colors.white54),
              ),
              items: controller.banks
                  .map(
                    (b) => DropdownMenuItem(
                      value: b.id,
                      child: Text(
                        b.name,
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  )
                  .toList(),
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
          if (expToEdit == null)
            await controller.createExpense(e);
          else
            await controller.editExpense(expToEdit, e);
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
