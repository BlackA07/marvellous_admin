import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../../../vendors/controllers/vendor_controller.dart';
import '../../../products/models/product_model.dart';
import '../../../../features/categories/controllers/category_controller.dart';
import '../../../categories/models/category_model.dart';

class AddProductLogistics extends StatefulWidget {
  final CategoryController categoryController;
  final String? selectedCategory;
  final String? selectedSubCategory;
  final String selectedLocation;
  final Color cardColor, textColor;

  final Map<String, double>? initialDeliveryFees;
  final Map<String, String>? initialDeliveryTimes;
  final double? initialCodFee;

  final Function(String?) onCategoryChanged;
  final Function(String?) onSubCategoryChanged;
  final Function(String) onLocationChanged;
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
    this.initialDeliveryFees,
    this.initialDeliveryTimes,
    this.initialCodFee,
    required this.onCategoryChanged,
    required this.onSubCategoryChanged,
    required this.onLocationChanged,
    required this.onDetailsChanged,
  }) : super(key: key);

  @override
  State<AddProductLogistics> createState() => _AddProductLogisticsState();
}

class _AddProductLogisticsState extends State<AddProductLogistics> {
  Map<String, double> deliveryFees = {};
  Map<String, String> deliveryTimes = {};
  double codFee = 0.0;

  Map<String, TextEditingController> feeControllers = {};
  Map<String, TextEditingController> timeControllers = {};
  TextEditingController codController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initValuesAndControllers();
  }

  @override
  void didUpdateWidget(covariant AddProductLogistics oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Jab bhi props change honge (e.g., Edit mode load hoga), sync ho jayega
    if (widget.initialDeliveryFees != oldWidget.initialDeliveryFees ||
        widget.initialCodFee != oldWidget.initialCodFee ||
        widget.selectedLocation != oldWidget.selectedLocation) {
      _syncControllersWithProps();
    }
  }

  void _initValuesAndControllers() {
    List<String> keys = ["Karachi", "Pakistan", "Worldwide"];
    for (var k in keys) {
      double fee = widget.initialDeliveryFees?[k] ?? 0.0;
      String time =
          widget.initialDeliveryTimes?[k] ??
          (k == "Karachi"
              ? "1-2 Days"
              : k == "Pakistan"
              ? "3-5 Days"
              : "7-15 Days");

      deliveryFees[k] = fee;
      deliveryTimes[k] = time;

      feeControllers[k] = TextEditingController(
        text: fee == 0 ? "" : fee.toInt().toString(),
      );
      timeControllers[k] = TextEditingController(text: time);
    }
    codFee = widget.initialCodFee ?? 0.0;
    codController.text = codFee == 0 ? "" : codFee.toInt().toString();
  }

  void _syncControllersWithProps() {
    List<String> keys = ["Karachi", "Pakistan", "Worldwide"];
    for (var k in keys) {
      double fee = widget.initialDeliveryFees?[k] ?? 0.0;
      String time = widget.initialDeliveryTimes?[k] ?? deliveryTimes[k] ?? "";

      deliveryFees[k] = fee;
      deliveryTimes[k] = time;

      if (feeControllers.containsKey(k)) {
        String feeText = fee == 0 ? "" : fee.toInt().toString();
        if (feeControllers[k]!.text != feeText) {
          feeControllers[k]!.text = feeText;
        }
        if (timeControllers[k]!.text != time) {
          timeControllers[k]!.text = time;
        }
      }
    }
    codFee = widget.initialCodFee ?? 0.0;
    String codText = codFee == 0 ? "" : codFee.toInt().toString();
    if (codController.text != codText) {
      codController.text = codText;
    }
    setState(() {});
  }

  @override
  void dispose() {
    for (var ctrl in feeControllers.values) {
      ctrl.dispose();
    }
    for (var ctrl in timeControllers.values) {
      ctrl.dispose();
    }
    codController.dispose();
    super.dispose();
  }

  void _updateParent() {
    Map<String, double> finalFees = Map.from(deliveryFees);
    Map<String, String> finalTimes = Map.from(deliveryTimes);

    if (widget.selectedLocation == "Karachi Only") {
      finalFees["Pakistan"] = 0;
      finalFees["Worldwide"] = 0;
    } else if (widget.selectedLocation == "Pakistan") {
      finalFees["Worldwide"] = 0;
    }

    widget.onDetailsChanged(finalFees, finalTimes, codFee);
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
          (val) {
            widget.onLocationChanged(val!);
            _updateParent();
          },
        ),
        const SizedBox(height: 15),
        _buildRegionInputs(
          "Karachi",
          "Karachi Shipping Fee",
          "Karachi Delivery Time",
        ),
        if (widget.selectedLocation != "Karachi Only")
          _buildRegionInputs(
            "Pakistan",
            "Outside Karachi (Pakistan) Fee",
            "Pakistan Delivery Time",
          ),
        if (widget.selectedLocation == "Worldwide")
          _buildRegionInputs(
            "Worldwide",
            "International Shipping Fee",
            "International Delivery Time",
          ),
        const SizedBox(height: 15),
        _buildSimpleInput("Cash on Delivery (COD) Fee", codController, (val) {
          codFee = double.tryParse(val) ?? 0.0;
          _updateParent();
        }, isNumber: true),
      ],
    );
  }

  Widget _buildRegionInputs(String key, String feeLabel, String timeLabel) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: Row(
        children: [
          Expanded(
            child: _buildSimpleInput(feeLabel, feeControllers[key]!, (val) {
              deliveryFees[key] = double.tryParse(val) ?? 0.0;
              _updateParent();
            }, isNumber: true),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _buildSimpleInput(timeLabel, timeControllers[key]!, (val) {
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
    TextEditingController ctrl,
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
          controller: ctrl,
          onChanged: onChange,
          keyboardType: isNumber ? TextInputType.number : TextInputType.text,
          style: const TextStyle(color: Colors.black, fontSize: 13),
          decoration: InputDecoration(
            filled: true,
            fillColor: widget.cardColor,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 8,
            ),
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
    List<String> safeItems = List.from(items);
    if (value != null && value.isNotEmpty && !safeItems.contains(value)) {
      safeItems.add(value);
    }
    String? safeValue = safeItems.contains(value)
        ? value
        : (safeItems.isNotEmpty ? safeItems.first : null);
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
          value: safeValue,
          style: const TextStyle(color: Colors.black, fontSize: 14),
          dropdownColor: Colors.white,
          items: safeItems
              .toSet()
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

  void _showAddDialog(BuildContext context, bool isSub) {
    showDialog(
      context: context,
      builder: (context) {
        return AddCategoryDialog(
          title: isSub ? "Sub-Category" : "Category",
          onSave: (val) async {
            if (isSub) {
              await widget.categoryController.addSubCategory(
                widget.selectedCategory!,
                val,
              );
              widget.onSubCategoryChanged(val);
            } else {
              await widget.categoryController.addCategory(val);
              widget.onCategoryChanged(val);
            }
          },
        );
      },
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

class AddCategoryDialog extends StatelessWidget {
  final String title;
  final Function(String) onSave;

  AddCategoryDialog({Key? key, required this.title, required this.onSave})
    : super(key: key);

  final TextEditingController _controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF2A2D3E),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Add New $title",
              style: GoogleFonts.orbitron(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _controller,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: "Enter Name",
                hintStyle: const TextStyle(color: Colors.white24),
                filled: true,
                fillColor: Colors.black12,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Colors.cyanAccent),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Get.back(),
                  child: const Text(
                    "Cancel",
                    style: TextStyle(color: Colors.white54),
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: () {
                    if (_controller.text.isNotEmpty) {
                      onSave(_controller.text);
                      Get.back();
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.cyanAccent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    "Add",
                    style: TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
