import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../features/categories/controllers/category_controller.dart';
import '../../../categories/models/category_model.dart';

class AddProductLogistics extends StatelessWidget {
  final CategoryController categoryController;
  final String? selectedCategory;
  final String? selectedSubCategory;
  final String selectedLocation;
  final Color cardColor, textColor;
  final Function(String?) onCategoryChanged;
  final Function(String?) onSubCategoryChanged;
  final Function(String?) onLocationChanged;

  const AddProductLogistics({
    Key? key,
    required this.categoryController,
    required this.selectedCategory,
    required this.selectedSubCategory,
    required this.selectedLocation,
    required this.cardColor,
    required this.textColor,
    required this.onCategoryChanged,
    required this.onSubCategoryChanged,
    required this.onLocationChanged,
  }) : super(key: key);

  void _showAddDialog(BuildContext context, bool isSub) {
    TextEditingController ctrl = TextEditingController();

    if (isSub && selectedCategory != null) {
      var catModel = categoryController.categories.firstWhere(
        (c) => c.name == selectedCategory,
        orElse: () => CategoryModel(name: '', subCategories: []),
      );
      if (catModel.id != null) {
        categoryController.selectCategory(catModel);
      }
    }

    Get.defaultDialog(
      title: isSub ? "Add Sub-Category" : "Add Category",
      titleStyle: const TextStyle(
        color: Colors.black,
        fontWeight: FontWeight.bold,
      ),
      backgroundColor: Colors.white,

      // 🔥 THE ONLY REAL FIX (theme override safe)
      content: Theme(
        data: Theme.of(context).copyWith(
          textTheme: Theme.of(context).textTheme.copyWith(
            bodyMedium: const TextStyle(color: Colors.black),
          ),
          inputDecorationTheme: const InputDecorationTheme(
            hintStyle: TextStyle(color: Colors.grey),
          ),
        ),
        child: TextField(
          controller: ctrl,
          style: const TextStyle(color: Colors.black),
          decoration: const InputDecoration(
            hintText: "Enter Name",
            border: OutlineInputBorder(),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Colors.deepPurple),
            ),
          ),
        ),
      ),

      textConfirm: "Add",
      textCancel: "Cancel",
      confirmTextColor: Colors.white,
      buttonColor: Colors.deepPurple,
      cancelTextColor: Colors.black,
      onConfirm: () async {
        if (ctrl.text.isNotEmpty) {
          String newName = ctrl.text;

          if (isSub) {
            await categoryController.addSubCategory(newName);
            onSubCategoryChanged(newName);
          } else {
            await categoryController.addCategory(newName);
            onCategoryChanged(newName);
          }

          Get.back();
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader("Logistics"),

        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Obx(() {
                var cats = categoryController.categories;

                if (cats.isNotEmpty && selectedCategory == null) {
                  Future.microtask(() => onCategoryChanged(cats.first.name));
                }

                String? validCat = cats.any((c) => c.name == selectedCategory)
                    ? selectedCategory
                    : null;

                return _buildDropdown(
                  "Category",
                  validCat,
                  cats.map((c) => c.name).toList(),
                  onCategoryChanged,
                );
              }),
            ),
            IconButton(
              icon: const Icon(Icons.add_circle, color: Colors.green, size: 30),
              onPressed: () => _showAddDialog(context, false),
            ),
          ],
        ),
        const SizedBox(height: 15),

        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Obx(() {
                var cats = categoryController.categories;
                List<String> subCats = [];

                if (selectedCategory != null) {
                  var catObj = cats.firstWhere(
                    (c) => c.name == selectedCategory,
                    orElse: () => CategoryModel(name: '', subCategories: []),
                  );
                  subCats = catObj.subCategories;
                }

                String? validSub = subCats.contains(selectedSubCategory)
                    ? selectedSubCategory
                    : null;

                return _buildDropdown(
                  "Sub Category",
                  validSub,
                  subCats,
                  onSubCategoryChanged,
                  isOptional: true,
                );
              }),
            ),
            IconButton(
              icon: Icon(
                Icons.add_circle,
                color: selectedCategory == null ? Colors.grey : Colors.green,
                size: 30,
              ),
              onPressed: selectedCategory == null
                  ? null
                  : () => _showAddDialog(context, true),
            ),
          ],
        ),
        const SizedBox(height: 15),

        _buildDropdown("Location to Deliver", selectedLocation, [
          "Karachi Only",
          "Pakistan",
          "Worldwide",
        ], onLocationChanged),
      ],
    );
  }

  Widget _buildDropdown(
    String label,
    String? value,
    List<String> items,
    Function(String?) onChanged, {
    bool isOptional = false,
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
        DropdownButtonFormField<String>(
          value: value,
          style: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w500,
            fontSize: 15,
          ),
          dropdownColor: const Color.fromARGB(255, 155, 159, 184),
          icon: const Icon(Icons.arrow_drop_down, color: Colors.black),
          items: items
              .map(
                (e) => DropdownMenuItem(
                  value: e,
                  child: Text(
                    e,
                    style: const TextStyle(color: Color.fromARGB(255, 0, 0, 0)),
                  ),
                ),
              )
              .toList(),
          onChanged: onChanged,
          decoration: InputDecoration(
            filled: true,
            fillColor: cardColor,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Colors.deepPurple),
            ),
          ),
          validator: (val) =>
              isOptional ? null : (val == null ? "Required" : null),
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
              color: Colors.deepPurple,
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
