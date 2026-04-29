import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../controller/finance_controller.dart';
import '../models/finance_models.dart';

class TaxesScreen extends StatelessWidget {
  final FinanceController controller = Get.find();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('Taxes', style: GoogleFonts.orbitron(color: Colors.white)),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.cyanAccent,
        child: const Icon(Icons.add, color: Colors.black),
        onPressed: () => _taxDialog(context),
      ),
      body: Obx(
        () => ListView.builder(
          padding: const EdgeInsets.all(20),
          itemCount: controller.taxes.length,
          itemBuilder: (ctx, i) {
            final tax = controller.taxes[i];
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(
                color: const Color(0xFF2C2C2C),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.white24),
              ),
              child: ListTile(
                title: Text(
                  '${tax.category} - ${tax.subcategory}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: Text(
                  'Appear in Checkbox: ${tax.appearInCheckout}',
                  style: const TextStyle(color: Colors.white70),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${tax.percentage}%',
                      style: GoogleFonts.orbitron(
                        color: Colors.cyanAccent,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit, color: Colors.white),
                      onPressed: () => _taxDialog(context, tax: tax),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.redAccent),
                      onPressed: () => controller.removeTax(tax.id!),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  void _taxDialog(BuildContext context, {TaxModel? tax}) {
    final catCtrl = TextEditingController(text: tax?.category);
    final subCtrl = TextEditingController(text: tax?.subcategory);
    final percCtrl = TextEditingController(text: tax?.percentage.toString());
    bool appear = tax?.appearInCheckout ?? false;
    Get.defaultDialog(
      backgroundColor: const Color(0xFF2C2C2C),
      title: tax == null ? 'Add Tax' : 'Edit Tax',
      titleStyle: const TextStyle(color: Colors.white),
      content: StatefulBuilder(
        builder: (ctx, setState) => Column(
          children: [
            _input(catCtrl, 'Category'),
            _input(subCtrl, 'Subcategory'),
            _input(percCtrl, 'Percentage', isNum: true),
            CheckboxListTile(
              title: const Text(
                'Appear in dummy checkbox',
                style: TextStyle(color: Colors.white),
              ),
              value: appear,
              activeColor: Colors.cyanAccent,
              onChanged: (val) => setState(() => appear = val!),
            ),
          ],
        ),
      ),
      confirm: ElevatedButton(
        style: ElevatedButton.styleFrom(backgroundColor: Colors.cyanAccent),
        onPressed: () {
          final t = TaxModel(
            id: tax?.id,
            category: catCtrl.text,
            subcategory: subCtrl.text,
            percentage: double.tryParse(percCtrl.text) ?? 0,
            appearInCheckout: appear,
          );
          controller.saveTax(t);
          Get.back();
        },
        child: const Text('Save', style: TextStyle(color: Colors.black)),
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
          ),
        ),
      );
}
