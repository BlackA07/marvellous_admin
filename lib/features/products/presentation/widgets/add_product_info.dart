import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:get/get.dart';
import '../../controller/products_controller.dart';

class AddProductInfo extends StatelessWidget {
  final TextEditingController nameCtrl,
      brandCtrl,
      modelCtrl,
      descCtrl,
      ramCtrl,
      storageCtrl;
  final bool isMobile;
  final DateTime selectedDate;
  final Function(DateTime) onDateChanged;
  final Color cardColor, textColor, accentColor;
  final List<String> productHistory;
  final List<String> brandHistory;
  final Function(String) onNameChanged;

  const AddProductInfo({
    Key? key,
    required this.nameCtrl,
    required this.brandCtrl,
    required this.modelCtrl,
    required this.descCtrl,
    required this.ramCtrl,
    required this.storageCtrl,
    required this.isMobile,
    required this.selectedDate,
    required this.onDateChanged,
    required this.cardColor,
    required this.textColor,
    required this.accentColor,
    required this.productHistory,
    required this.brandHistory,
    required this.onNameChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader("Basic Info"),

        Text(
          "Date Added",
          style: GoogleFonts.comicNeue(
            color: textColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),

        InkWell(
          onTap: () async {
            DateTime? picked = await showDatePicker(
              context: context,
              initialDate: selectedDate,
              firstDate: DateTime(2000),
              lastDate: DateTime(2100),
              builder: (context, child) => Theme(
                data: ThemeData.light().copyWith(
                  colorScheme: ColorScheme.light(primary: accentColor),
                ),
                child: child!,
              ),
            );
            if (picked != null) onDateChanged(picked);
          },
          child: Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  DateFormat('dd MMM yyyy').format(selectedDate),
                  style: TextStyle(color: textColor),
                ),
                Icon(Icons.calendar_today, color: accentColor),
              ],
            ),
          ),
        ),
        const SizedBox(height: 15),

        _buildAutocomplete(
          "Product Name",
          "e.g. Mobile",
          nameCtrl,
          productHistory,
          onNameChanged,
          "product",
        ),

        const SizedBox(height: 15),

        if (isMobile) ...[
          Row(
            children: [
              Expanded(child: _buildTextField("RAM", "8GB", ramCtrl)),
              const SizedBox(width: 10),
              Expanded(child: _buildTextField("Storage", "128GB", storageCtrl)),
            ],
          ),
          const SizedBox(height: 15),
        ],

        _buildTextField("Model", "SF-2024", modelCtrl),
        const SizedBox(height: 15),

        _buildAutocomplete(
          "Brand",
          "Samsung",
          brandCtrl,
          brandHistory,
          (v) => brandCtrl.text = v,
          "brand",
        ),

        const SizedBox(height: 15),
        _buildTextField("Description", "Details...", descCtrl, maxLines: 4),
      ],
    );
  }

  // 🔥 FIXED AUTOCOMPLETE (caret + reverse + startsWith)
  Widget _buildAutocomplete(
    String label,
    String hint,
    TextEditingController ctrl,
    List<String> history,
    Function(String) onChanged,
    String type,
  ) {
    final ProductsController pController = Get.find<ProductsController>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.comicNeue(
            color: textColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 5),

        RawAutocomplete<String>(
          initialValue: TextEditingValue(text: ctrl.text),

          optionsBuilder: (TextEditingValue value) {
            if (value.text.isEmpty) return const Iterable<String>.empty();
            return history.where(
              (e) => e.toLowerCase().startsWith(value.text.toLowerCase()),
            );
          },

          onSelected: (selection) {
            ctrl.text = selection;
            onChanged(selection);
          },

          fieldViewBuilder: (context, textController, focusNode, _) {
            return TextFormField(
              controller: textController,
              focusNode: focusNode,
              style: const TextStyle(color: Colors.black),
              cursorColor: Colors.black,
              onChanged: (val) {
                ctrl.text = val;
                onChanged(val);
              },
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: const TextStyle(color: Colors.grey),
                filled: true,
                fillColor: cardColor,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              validator: (val) => val!.isEmpty ? "Required" : null,
            );
          },

          optionsViewBuilder: (context, onSelected, options) {
            return Material(
              elevation: 4,
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              child: ListView(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                children: options.map((opt) {
                  return ListTile(
                    title: Text(
                      opt,
                      style: const TextStyle(color: Colors.black),
                    ),
                    trailing: IconButton(
                      icon: const Icon(
                        Icons.close,
                        size: 16,
                        color: Colors.red,
                      ),
                      onPressed: () {
                        pController.removeSpecificHistoryItem(opt, type);
                        (context as Element).markNeedsBuild();
                      },
                    ),
                    onTap: () => onSelected(opt),
                  );
                }).toList(),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildTextField(
    String label,
    String hint,
    TextEditingController ctrl, {
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.comicNeue(
            color: textColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 5),
        TextFormField(
          controller: ctrl,
          maxLines: maxLines,
          style: const TextStyle(color: Colors.black),
          cursorColor: Colors.black,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Colors.grey),
            filled: true,
            fillColor: cardColor,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          ),
          validator: (val) => val!.isEmpty ? "Required" : null,
        ),
      ],
    );
  }

  Widget _buildHeader(String title) {
    return Column(
      children: [
        Row(
          children: [
            Container(
              width: 4,
              height: 20,
              color: accentColor,
              margin: const EdgeInsets.only(right: 10),
            ),
            Text(
              title,
              style: GoogleFonts.orbitron(
                color: textColor,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const Divider(),
        const SizedBox(height: 10),
      ],
    );
  }
}
