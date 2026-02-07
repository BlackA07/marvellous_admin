import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../features/categories/controllers/category_controller.dart';
import '../../../categories/models/category_model.dart';

class AddProductLogistics extends StatefulWidget {
  final CategoryController categoryController;
  final String? selectedCategory;
  final String? selectedSubCategory;
  final String selectedLocation;
  final Color cardColor, textColor;
  final Function(String?) onCategoryChanged;
  final Function(String?) onSubCategoryChanged;
  final Function(String) onLocationChanged;
  // Callback for multi-region data
  final Function(Map<String, double>, Map<String, String>, double)
  onDetailsChanged;

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
    required this.onDetailsChanged,
  }) : super(key: key);

  @override
  State<AddProductLogistics> createState() => _AddProductLogisticsState();
}

class _AddProductLogisticsState extends State<AddProductLogistics> {
  // Local state for flexible logistics
  Map<String, double> deliveryFees = {
    "Karachi": 0,
    "Pakistan": 0,
    "Worldwide": 0,
  };
  Map<String, String> deliveryTimes = {
    "Karachi": "1-2 Days",
    "Pakistan": "3-5 Days",
    "Worldwide": "7-15 Days",
  };
  double codFee = 0.0;

  void _updateParent() {
    widget.onDetailsChanged(deliveryFees, deliveryTimes, codFee);
  }

  void _showAddDialog(BuildContext context, bool isSub) {
    TextEditingController ctrl = TextEditingController();
    if (isSub && widget.selectedCategory != null) {
      var catModel = widget.categoryController.categories.firstWhere(
        (c) => c.name == widget.selectedCategory,
        orElse: () => CategoryModel(name: '', subCategories: []),
      );
      if (catModel.id != null)
        widget.categoryController.selectCategory(catModel);
    }

    Get.defaultDialog(
      title: isSub ? "Add Sub-Category" : "Add Category",
      titleStyle: const TextStyle(
        color: Colors.black,
        fontWeight: FontWeight.bold,
      ),
      backgroundColor: Colors.white,
      content: TextField(
        controller: ctrl,
        style: const TextStyle(color: Colors.black),
        decoration: const InputDecoration(
          hintText: "Enter Name",
          border: OutlineInputBorder(),
        ),
      ),
      textConfirm: "Add",
      textCancel: "Cancel",
      onConfirm: () async {
        if (ctrl.text.isNotEmpty) {
          if (isSub) {
            await widget.categoryController.addSubCategory(ctrl.text);
            widget.onSubCategoryChanged(ctrl.text);
          } else {
            await widget.categoryController.addCategory(ctrl.text);
            widget.onCategoryChanged(ctrl.text);
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
        _buildHeader("Category & Taxonomy"),
        Row(
          children: [
            Expanded(
              child: Obx(() {
                var cats = widget.categoryController.categories;
                return _buildDropdown(
                  "Category",
                  widget.selectedCategory,
                  cats.map((c) => c.name).toList(),
                  widget.onCategoryChanged,
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
          children: [
            Expanded(
              child: Obx(() {
                var cat = widget.categoryController.categories.firstWhere(
                  (c) => c.name == widget.selectedCategory,
                  orElse: () => CategoryModel(name: '', subCategories: []),
                );
                return _buildDropdown(
                  "Sub Category",
                  widget.selectedSubCategory,
                  cat.subCategories,
                  widget.onSubCategoryChanged,
                  isOptional: true,
                );
              }),
            ),
            IconButton(
              icon: Icon(
                Icons.add_circle,
                color: widget.selectedCategory == null
                    ? Colors.grey
                    : Colors.green,
                size: 30,
              ),
              onPressed: widget.selectedCategory == null
                  ? null
                  : () => _showAddDialog(context, true),
            ),
          ],
        ),
        const SizedBox(height: 30),
        _buildHeader("Shipping Logistics"),
        _buildDropdown(
          "Main Shipping Scope",
          widget.selectedLocation,
          ["Karachi Only", "Pakistan", "Worldwide"],
          (val) => widget.onLocationChanged(val!),
        ),
        const SizedBox(height: 15),

        // KARACHI SECTION (Always visible)
        _buildRegionInputs(
          "Karachi",
          "Karachi Shipping Fee",
          "Karachi Delivery Time",
        ),

        // PAKISTAN SECTION (Visible for Pakistan and Worldwide)
        if (widget.selectedLocation != "Karachi Only")
          _buildRegionInputs(
            "Pakistan",
            "Outside Karachi (Pakistan) Fee",
            "Pakistan Delivery Time",
          ),

        // WORLDWIDE SECTION (Only for Worldwide)
        if (widget.selectedLocation == "Worldwide")
          _buildRegionInputs(
            "Worldwide",
            "International Shipping Fee",
            "International Delivery Time",
          ),

        const SizedBox(height: 15),
        _buildSimpleInput("Cash on Delivery (COD) Fee", (val) {
          codFee = double.tryParse(val) ?? 0.0;
          _updateParent();
        }),
      ],
    );
  }

  Widget _buildRegionInputs(String key, String feeLabel, String timeLabel) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: Row(
        children: [
          Expanded(
            child: _buildSimpleInput(feeLabel, (val) {
              deliveryFees[key] = double.tryParse(val) ?? 0.0;
              _updateParent();
            }, isNumber: true),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _buildSimpleInput(timeLabel, (val) {
              deliveryTimes[key] = val;
              _updateParent();
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildSimpleInput(
    String label,
    Function(String) onChange, {
    bool isNumber = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.comicNeue(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 5),
        TextField(
          onChanged: onChange,
          keyboardType: isNumber ? TextInputType.number : TextInputType.text,
          style: const TextStyle(color: Colors.black, fontSize: 13),
          decoration: InputDecoration(
            filled: true,
            fillColor: widget.cardColor,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
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
            color: widget.textColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 5),
        DropdownButtonFormField<String>(
          value: value,
          style: const TextStyle(color: Colors.black, fontSize: 14),
          dropdownColor: Colors.white,
          items: items
              .map(
                (e) => DropdownMenuItem(
                  value: e,
                  child: Text(e, style: const TextStyle(color: Colors.black)),
                ),
              )
              .toList(),
          onChanged: onChanged,
          decoration: InputDecoration(
            filled: true,
            fillColor: widget.cardColor,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
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
                color: widget.textColor,
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
