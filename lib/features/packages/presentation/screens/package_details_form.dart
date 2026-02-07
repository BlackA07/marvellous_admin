import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:get/get.dart';
import '../../../vendors/controllers/vendor_controller.dart';
import '../../../products/models/product_model.dart';

class PackageDetailsForm extends StatelessWidget {
  final TextEditingController nameCtrl;
  final TextEditingController descCtrl;
  final List<String> selectedImagesBase64;
  final String? selectedVendorId;
  final String? selectedLocation;
  final List<ProductModel> selectedProducts;
  final VendorController vendorController;
  final Function(List<String>) onImagesChanged;
  final Function(String?) onVendorChanged;
  final Function(String?) onLocationChanged;

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
  }) : super(key: key);

  Future<void> _pickImages() async {
    final images = await ImagePicker().pickMultiImage();
    if (images.isNotEmpty) {
      List<String> newList = List.from(selectedImagesBase64);
      for (var img in images) {
        final bytes = await img.readAsBytes();
        newList.add(base64Encode(bytes));
      }
      onImagesChanged(newList);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Common text style for all inputs
    const TextStyle inputTextStyle = TextStyle(
      color: Colors.black,
      fontWeight: FontWeight.w500,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Step 2: Details",
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
                controller: nameCtrl,
                style: inputTextStyle, // Text color black
                decoration: _deco("Package Name"),
                validator: (v) => v!.isEmpty ? "Required" : null,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.auto_fix_high, color: Colors.deepPurple),
              onPressed: () {
                if (selectedProducts.isNotEmpty) {
                  nameCtrl.text =
                      "Combo: ${selectedProducts.map((p) => p.name).join(" + ")}";
                }
              },
            ),
          ],
        ),
        const SizedBox(height: 15),
        TextFormField(
          controller: descCtrl,
          style: inputTextStyle, // Text color black
          maxLines: 3,
          decoration: _deco("Description"),
        ),
        const SizedBox(height: 15),
        Row(
          children: [
            Expanded(
              child: Obx(
                () => DropdownButtonFormField<String>(
                  value: selectedVendorId,
                  style: inputTextStyle, // Selected item text color black
                  dropdownColor: Colors.white,
                  items: vendorController.vendors
                      .map(
                        (v) => DropdownMenuItem(
                          value: v.id,
                          child: Text(v.storeName, style: inputTextStyle),
                        ),
                      )
                      .toList(),
                  onChanged: onVendorChanged,
                  decoration: _deco("Vendor"),
                ),
              ),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: DropdownButtonFormField<String>(
                value: selectedLocation,
                style: inputTextStyle, // Selected item text color black
                dropdownColor: Colors.white,
                items:
                    [
                          "Karachi Only",
                          "Pakistan",
                          "Worldwide",
                          "Store Pickup Only",
                        ]
                        .map(
                          (l) => DropdownMenuItem(
                            value: l,
                            child: Text(l, style: inputTextStyle),
                          ),
                        )
                        .toList(),
                onChanged: onLocationChanged,
                decoration: _deco("Location"),
              ),
            ),
          ],
        ),
      ],
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
          ...selectedImagesBase64.asMap().entries.map(
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
                      List<String> list = List.from(selectedImagesBase64);
                      list.removeAt(e.key);
                      onImagesChanged(list);
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
    labelStyle: const TextStyle(color: Colors.black54), // Label color
    filled: true,
    fillColor: Colors.white,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: Colors.grey),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide(color: Colors.grey.shade300),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: Colors.deepPurple, width: 2),
    ),
  );
}
