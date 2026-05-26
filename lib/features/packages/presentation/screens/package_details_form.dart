import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:get/get.dart';
import '../../../vendors/controllers/vendor_controller.dart';
import '../../../products/models/product_model.dart';

class PackageDetailsForm extends StatefulWidget {
  final TextEditingController nameCtrl;
  final TextEditingController descCtrl;
  final List<String> selectedImagesBase64;
  final String? selectedVendorId;
  final String? selectedLocation;
  final List<ProductModel> selectedProducts;
  final VendorController vendorController;
  final Function(List<String>) onImagesChanged;
  final Function(String?) onVendorChanged;
  final Function(String) onLocationChanged;
  final Function(Map<String, double>, Map<String, String>, double)
  onLogisticsChanged;

  // Edit mode ke liye initial values
  final Map<String, double>? initialDeliveryFees;
  final Map<String, String>? initialDeliveryTimes;
  final double? initialCodFee;

  const PackageDetailsForm({
    Key? key,
    required this.nameCtrl,
    required this.descCtrl,
    required this.selectedImagesBase64,
    required this.selectedVendorId,
    required this.selectedLocation,
    required this.selectedProducts,
    required this.vendorController,
    required this.onImagesChanged,
    required this.onVendorChanged,
    required this.onLocationChanged,
    required this.onLogisticsChanged,
    this.initialDeliveryFees,
    this.initialDeliveryTimes,
    this.initialCodFee,
  }) : super(key: key);

  @override
  State<PackageDetailsForm> createState() => _PackageDetailsFormState();
}

class _PackageDetailsFormState extends State<PackageDetailsForm> {
  late Map<String, double> deliveryFees;
  late Map<String, String> deliveryTimes;
  late double codFee;

  // Controllers for text fields taake edit mode mein values show hon
  final Map<String, TextEditingController> _feeControllers = {};
  final Map<String, TextEditingController> _timeControllers = {};
  late TextEditingController _codController;

  @override
  void initState() {
    super.initState();

    // Edit mode mein parent ki values use karo, warna defaults
    deliveryFees = widget.initialDeliveryFees != null
        ? Map<String, double>.from(widget.initialDeliveryFees!)
        : {"Karachi": 0, "Pakistan": 0, "Worldwide": 0};

    deliveryTimes = widget.initialDeliveryTimes != null
        ? Map<String, String>.from(widget.initialDeliveryTimes!)
        : {
            "Karachi": "1-2 Days",
            "Pakistan": "3-5 Days",
            "Worldwide": "7-15 Days",
          };

    codFee = widget.initialCodFee ?? 0.0;

    // Controllers initialize karo existing values ke saath
    for (final key in ["Karachi", "Pakistan", "Worldwide"]) {
      _feeControllers[key] = TextEditingController(
        text: (deliveryFees[key] ?? 0) == 0
            ? ""
            : (deliveryFees[key]!).toStringAsFixed(0),
      );
      _timeControllers[key] = TextEditingController(
        text: deliveryTimes[key] ?? "",
      );
    }

    _codController = TextEditingController(
      text: codFee == 0 ? "" : codFee.toStringAsFixed(0),
    );
  }

  @override
  void dispose() {
    for (final c in _feeControllers.values) {
      c.dispose();
    }
    for (final c in _timeControllers.values) {
      c.dispose();
    }
    _codController.dispose();
    super.dispose();
  }

  void _notifyParent() {
    widget.onLogisticsChanged(deliveryFees, deliveryTimes, codFee);
  }

  Future<void> _pickImages() async {
    final images = await ImagePicker().pickMultiImage();
    if (images.isNotEmpty) {
      List<String> newList = List.from(widget.selectedImagesBase64);
      for (var img in images) {
        final bytes = await img.readAsBytes();
        newList.add(base64Encode(bytes));
      }
      widget.onImagesChanged(newList);
    }
  }

  @override
  Widget build(BuildContext context) {
    const TextStyle inputTextStyle = TextStyle(
      color: Colors.black,
      fontWeight: FontWeight.w500,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Step 2: Details & Logistics",
          style: GoogleFonts.orbitron(
            color: Colors.deepPurple,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 15),
        _buildImagePicker(),
        const SizedBox(height: 15),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: widget.nameCtrl,
                style: inputTextStyle,
                decoration: _deco("Package Name"),
                validator: (v) => v!.isEmpty ? "Required" : null,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.auto_fix_high, color: Colors.deepPurple),
              onPressed: () {
                if (widget.selectedProducts.isNotEmpty) {
                  widget.nameCtrl.text =
                      "Combo: ${widget.selectedProducts.map((p) => p.name).join(" + ")}";
                }
              },
            ),
          ],
        ),
        const SizedBox(height: 15),
        TextFormField(
          controller: widget.descCtrl,
          style: inputTextStyle,
          maxLines: 3,
          decoration: _deco("Description"),
        ),
        const SizedBox(height: 15),
        Row(
          children: [
            Expanded(
              child: Obx(
                () => DropdownButtonFormField<String>(
                  value: widget.selectedVendorId,
                  style: inputTextStyle,
                  dropdownColor: Colors.white,
                  items: widget.vendorController.vendors
                      .map(
                        (v) => DropdownMenuItem(
                          value: v.id,
                          child: Text(v.storeName, style: inputTextStyle),
                        ),
                      )
                      .toList(),
                  onChanged: widget.onVendorChanged,
                  decoration: _deco("Vendor"),
                ),
              ),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: DropdownButtonFormField<String>(
                value: widget.selectedLocation,
                style: inputTextStyle,
                dropdownColor: Colors.white,
                items: ["Karachi Only", "Pakistan", "Worldwide"]
                    .map(
                      (l) => DropdownMenuItem(
                        value: l,
                        child: Text(l, style: inputTextStyle),
                      ),
                    )
                    .toList(),
                onChanged: (val) => widget.onLocationChanged(val!),
                decoration: _deco("Shipping Scope"),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        const Divider(),
        Text(
          "Region-wise Shipping Fees & Time",
          style: GoogleFonts.comicNeue(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 10),

        // KARACHI SECTION — hamesha show
        _buildRegionInput("Karachi", "Karachi Fee", "Karachi Time"),

        // PAKISTAN SECTION
        if (widget.selectedLocation != "Karachi Only")
          _buildRegionInput(
            "Pakistan",
            "Outside Karachi Fee",
            "Outside Karachi Time",
          ),

        // WORLDWIDE SECTION
        if (widget.selectedLocation == "Worldwide")
          _buildRegionInput(
            "Worldwide",
            "International Fee",
            "International Time",
          ),

        const SizedBox(height: 15),
        // COD field with controller
        TextFormField(
          controller: _codController,
          keyboardType: TextInputType.number,
          style: const TextStyle(color: Colors.black, fontSize: 13),
          decoration: _deco("Cash on Delivery (COD) Fee"),
          onChanged: (val) {
            codFee = double.tryParse(val) ?? 0.0;
            _notifyParent();
          },
        ),
      ],
    );
  }

  Widget _buildRegionInput(String key, String feeLabel, String timeLabel) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Expanded(
            child: TextFormField(
              controller: _feeControllers[key],
              keyboardType: TextInputType.number,
              style: const TextStyle(color: Colors.black, fontSize: 13),
              decoration: _deco(feeLabel),
              onChanged: (v) {
                deliveryFees[key] = double.tryParse(v) ?? 0;
                _notifyParent();
              },
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: TextFormField(
              controller: _timeControllers[key],
              style: const TextStyle(color: Colors.black, fontSize: 13),
              decoration: _deco(timeLabel),
              onChanged: (v) {
                deliveryTimes[key] = v;
                _notifyParent();
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImagePicker() {
    return SizedBox(
      height: 100,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          GestureDetector(
            onTap: _pickImages,
            child: Container(
              width: 100,
              margin: const EdgeInsets.only(right: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.deepPurple.withOpacity(0.5)),
              ),
              child: const Icon(Icons.add_a_photo, color: Colors.deepPurple),
            ),
          ),
          ...widget.selectedImagesBase64.asMap().entries.map(
            (e) => Stack(
              children: [
                Container(
                  width: 100,
                  margin: const EdgeInsets.only(right: 10),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    image: DecorationImage(
                      image: MemoryImage(base64Decode(e.value)),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                Positioned(
                  top: 5,
                  right: 15,
                  child: InkWell(
                    onTap: () {
                      List<String> list = List.from(
                        widget.selectedImagesBase64,
                      );
                      list.removeAt(e.key);
                      widget.onImagesChanged(list);
                    },
                    child: const CircleAvatar(
                      radius: 10,
                      backgroundColor: Colors.red,
                      child: Icon(Icons.close, size: 12, color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _deco(String l) => InputDecoration(
    labelText: l,
    labelStyle: const TextStyle(color: Colors.black54, fontSize: 12),
    filled: true,
    fillColor: Colors.white,
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide(color: Colors.grey.shade300),
    ),
  );
}
