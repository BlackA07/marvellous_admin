import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../../controller/products_controller.dart';
import '../../models/product_model.dart';

class AddProductScreen extends StatefulWidget {
  final ProductModel? productToEdit; // Data for Edit Mode

  const AddProductScreen({Key? key, this.productToEdit}) : super(key: key);

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  // FORCE INJECT CONTROLLER
  final ProductsController controller = Get.put(ProductsController());
  final _formKey = GlobalKey<FormState>();
  final ImagePicker _picker = ImagePicker();

  // Text Controllers
  final TextEditingController nameCtrl = TextEditingController();
  final TextEditingController modelCtrl = TextEditingController();
  final TextEditingController descCtrl = TextEditingController();
  final TextEditingController purchasePriceCtrl = TextEditingController();
  final TextEditingController salePriceCtrl = TextEditingController();
  final TextEditingController stockCtrl = TextEditingController();

  // State Variables
  DateTime selectedDate = DateTime.now();
  String? selectedCategory;
  String? selectedSubCategory;
  String? selectedBrand;
  String? selectedVendor;
  List<String> selectedImagesBase64 = [];

  // Data Lists
  List<String> vendors = ["Ali Suppliers", "Global Tech", "+ Add New"];
  List<String> brands = ["Samsung", "Apple", "Haier", "+ Add New"];
  List<String> categories = [
    "Electronics",
    "Furniture",
    "Clothing",
    "+ Add New",
  ];

  Map<String, List<String>> categorySubCategoryMap = {
    "Electronics": ["Mobile", "Laptop", "Refrigerator"],
    "Furniture": ["Chair", "Table"],
    "Clothing": ["Men", "Women"],
  };

  @override
  void initState() {
    super.initState();
    if (widget.productToEdit != null) {
      _loadProductData(widget.productToEdit!);
    }
  }

  void _loadProductData(ProductModel product) {
    nameCtrl.text = product.name;
    modelCtrl.text = product.modelNumber;
    descCtrl.text = product.description;
    purchasePriceCtrl.text = product.purchasePrice.toString();
    salePriceCtrl.text = product.salePrice.toString();
    stockCtrl.text = product.stockQuantity.toString();

    // Ensure lists contain the loaded values (in case they are new)
    if (!categories.contains(product.category))
      categories.insert(0, product.category);
    // Initialize sub-category map for this category if needed
    if (!categorySubCategoryMap.containsKey(product.category)) {
      categorySubCategoryMap[product.category] = [product.subCategory];
    } else if (!categorySubCategoryMap[product.category]!.contains(
      product.subCategory,
    )) {
      categorySubCategoryMap[product.category]!.add(product.subCategory);
    }

    selectedCategory = product.category;
    selectedSubCategory = product.subCategory;
    selectedBrand = product.brand;
    selectedVendor = product.vendorId;
    selectedImagesBase64 = List.from(product.images);
    selectedDate = product.dateAdded;
  }

  Future<void> _pickImages() async {
    if (selectedImagesBase64.length >= 3) {
      Get.snackbar("Limit Reached", "Max 3 images allowed.");
      return;
    }
    final List<XFile> images = await _picker.pickMultiImage();
    if (images.isNotEmpty) {
      int remainingSlots = 3 - selectedImagesBase64.length;
      List<XFile> toProcess = images.take(remainingSlots).toList();
      for (var img in toProcess) {
        final bytes = await img.readAsBytes();
        if (bytes.lengthInBytes > 1000000) {
          Get.snackbar("Warning", "${img.name} is too large (>1MB). Skipping.");
          continue;
        }
        setState(() => selectedImagesBase64.add(base64Encode(bytes)));
      }
    }
  }

  void _removeImage(int index) =>
      setState(() => selectedImagesBase64.removeAt(index));

  void _clearForm() {
    nameCtrl.clear();
    modelCtrl.clear();
    descCtrl.clear();
    purchasePriceCtrl.clear();
    salePriceCtrl.clear();
    stockCtrl.clear();
    setState(() {
      selectedImagesBase64.clear();
      selectedCategory = null;
      selectedSubCategory = null;
      selectedBrand = null;
      selectedVendor = null;
    });
  }

  void _showAddDialog(String title, Function(String) onAdd) {
    TextEditingController addCtrl = TextEditingController();
    Get.defaultDialog(
      title: "Add New $title",
      titleStyle: GoogleFonts.orbitron(color: Colors.white),
      backgroundColor: const Color(0xFF2A2D3E),
      content: TextField(
        controller: addCtrl,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(filled: true, fillColor: Colors.black12),
      ),
      textConfirm: "Add",
      textCancel: "Cancel",
      confirmTextColor: Colors.black,
      buttonColor: Colors.cyanAccent,
      onConfirm: () {
        if (addCtrl.text.isNotEmpty) {
          onAdd(addCtrl.text);
          Get.back();
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E1E2C),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ================= SECTION 1: MEDIA =================
              _buildSectionTitle("Media"),
              if (selectedImagesBase64.length < 3)
                GestureDetector(
                  onTap: _pickImages,
                  child: Container(
                    height: 140,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: const Color(0xFF2A2D3E),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.white10,
                        style: BorderStyle.solid,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.add_a_photo_outlined,
                          size: 40,
                          color: Colors.cyanAccent,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          "Click to upload images",
                          style: GoogleFonts.comicNeue(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          "Max 3 images (JPEG, PNG only)",
                          style: GoogleFonts.comicNeue(
                            color: Colors.white54,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              const SizedBox(height: 15),

              // Image Previews
              if (selectedImagesBase64.isNotEmpty)
                SizedBox(
                  height: 100,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: selectedImagesBase64.length,
                    itemBuilder: (context, index) {
                      return Stack(
                        children: [
                          Container(
                            width: 100,
                            height: 100,
                            margin: const EdgeInsets.only(right: 10),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Colors.cyanAccent),
                              image: DecorationImage(
                                image: MemoryImage(
                                  base64Decode(selectedImagesBase64[index]),
                                ),
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          Positioned(
                            top: 5,
                            right: 15,
                            child: InkWell(
                              onTap: () => _removeImage(index),
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(
                                  color: Colors.red,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.close,
                                  size: 14,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),

              const SizedBox(height: 30),

              // ================= SECTION 2: BASIC INFO =================
              _buildSectionTitle("Basic Information"),
              _buildDateField(),
              const SizedBox(height: 15),
              _buildTextField("Product Name", "e.g. Smart Fridge", nameCtrl),
              const SizedBox(height: 15),
              _buildTextField("Model Number", "e.g. SF-2024", modelCtrl),
              const SizedBox(height: 15),
              _buildTextField(
                "Description",
                "Enter full product details...",
                descCtrl,
                maxLines: 4,
              ),

              const SizedBox(height: 30),

              // ================= SECTION 3: CATEGORIZATION =================
              _buildSectionTitle("Categorization"),

              // 1. Category Dropdown with FIX
              _buildDropdown("Category", categories, (val) {
                if (val == "+ Add New") {
                  _showAddDialog(
                    "Category",
                    (v) => setState(() {
                      categories.insert(0, v);
                      // Initialize new category list
                      if (!categorySubCategoryMap.containsKey(v)) {
                        categorySubCategoryMap[v] = [];
                      }
                      selectedCategory = v;
                      selectedSubCategory = null; // IMPORTANT: Reset Sub
                    }),
                  );
                } else {
                  setState(() {
                    selectedCategory = val;
                    selectedSubCategory =
                        null; // IMPORTANT: Reset Sub to avoid conflict
                  });
                }
              }, selectedValue: selectedCategory),

              const SizedBox(height: 15),

              // 2. Sub-Category
              if (selectedCategory != null)
                _buildDropdown(
                  "Sub Category",
                  (categorySubCategoryMap[selectedCategory] ?? []) +
                      ["+ Add New"],
                  (val) {
                    if (val == "+ Add New") {
                      _showAddDialog(
                        "Sub Category",
                        (v) => setState(() {
                          categorySubCategoryMap[selectedCategory]!.add(v);
                          selectedSubCategory = v;
                        }),
                      );
                    } else {
                      setState(() => selectedSubCategory = val);
                    }
                  },
                  selectedValue: selectedSubCategory,
                ),

              const SizedBox(height: 15),

              // 3. Brand
              _buildDropdown("Brand", brands, (val) {
                if (val == "+ Add New")
                  _showAddDialog(
                    "Brand",
                    (v) => setState(() {
                      brands.insert(0, v);
                      selectedBrand = v;
                    }),
                  );
                else
                  setState(() => selectedBrand = val);
              }, selectedValue: selectedBrand),

              const SizedBox(height: 30),

              // ================= SECTION 4: PRICING & INVENTORY =================
              _buildSectionTitle("Pricing & Inventory"),
              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      "Purchase Price",
                      "0.00",
                      purchasePriceCtrl,
                      isNumber: true,
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: _buildTextField(
                      "Sale Price",
                      "0.00",
                      salePriceCtrl,
                      isNumber: true,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 15),
              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      "Quantity",
                      "0",
                      stockCtrl,
                      isNumber: true,
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: _buildDropdown("Vendor", vendors, (val) {
                      if (val == "+ Add New")
                        _showAddDialog(
                          "Vendor",
                          (newVen) => setState(() {
                            vendors.insert(vendors.length - 1, newVen);
                            selectedVendor = newVen;
                          }),
                        );
                      else
                        setState(() => selectedVendor = val);
                    }, selectedValue: selectedVendor),
                  ),
                ],
              ),

              const SizedBox(height: 40),

              // ================= SECTION 5: ACTION BUTTON =================
              SizedBox(
                width: double.infinity,
                height: 55,
                child: Obx(
                  () => ElevatedButton(
                    onPressed: controller.isLoading.value
                        ? null
                        : () async {
                            if (_formKey.currentState!.validate()) {
                              ProductModel newProduct = ProductModel(
                                id: widget.productToEdit?.id,
                                name: nameCtrl.text,
                                modelNumber: modelCtrl.text,
                                description: descCtrl.text,
                                category: selectedCategory ?? "Uncategorized",
                                subCategory: selectedSubCategory ?? "General",
                                brand: selectedBrand ?? "Generic",
                                purchasePrice:
                                    double.tryParse(purchasePriceCtrl.text) ??
                                    0,
                                salePrice:
                                    double.tryParse(salePriceCtrl.text) ?? 0,
                                stockQuantity:
                                    int.tryParse(stockCtrl.text) ?? 0,
                                vendorId: selectedVendor ?? "Unknown",
                                images: selectedImagesBase64,
                                dateAdded: selectedDate,
                              );

                              bool success;
                              if (widget.productToEdit == null) {
                                success = await controller.addNewProduct(
                                  newProduct,
                                );
                                if (success) _clearForm(); // Only clear on Add
                              } else {
                                success = await controller.updateProduct(
                                  newProduct,
                                );
                              }
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.cyanAccent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 5,
                    ),
                    child: controller.isLoading.value
                        ? const CircularProgressIndicator(color: Colors.black)
                        : Text(
                            widget.productToEdit == null
                                ? "SAVE PRODUCT"
                                : "UPDATE PRODUCT",
                            style: GoogleFonts.orbitron(
                              color: Colors.black,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              letterSpacing: 1.2,
                            ),
                          ),
                  ),
                ),
              ),
              const SizedBox(height: 40), // Bottom padding
            ],
          ),
        ),
      ),
    );
  }

  // --- HELPER WIDGETS ---

  // Section Title with Divider Look
  Widget _buildSectionTitle(String title) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 4,
              height: 20,
              color: Colors.purpleAccent,
              margin: const EdgeInsets.only(right: 10),
            ),
            Text(
              title,
              style: GoogleFonts.orbitron(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 5),
        const Divider(color: Colors.white10),
        const SizedBox(height: 10),
      ],
    );
  }

  Widget _buildTextField(
    String label,
    String hint,
    TextEditingController ctrl, {
    int maxLines = 1,
    bool isNumber = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.comicNeue(
            color: Colors.white70,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: ctrl,
          maxLines: maxLines,
          keyboardType: isNumber ? TextInputType.number : TextInputType.text,
          style: const TextStyle(color: Colors.white),
          validator: (val) => val!.isEmpty ? "Required" : null,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Colors.white24),
            filled: true,
            fillColor: const Color(0xFF2A2D3E),
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
      ],
    );
  }

  Widget _buildDropdown(
    String label,
    List<String> items,
    Function(String?) onChanged, {
    String? selectedValue,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.comicNeue(
            color: Colors.white70,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: selectedValue,
          dropdownColor: const Color(0xFF2A2D3E),
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            filled: true,
            fillColor: const Color(0xFF2A2D3E),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,
            ),
          ),
          items: items
              .map(
                (e) => DropdownMenuItem(
                  value: e,
                  child: Text(
                    e,
                    style: TextStyle(
                      color: e.startsWith("+")
                          ? Colors.cyanAccent
                          : Colors.white,
                    ),
                  ),
                ),
              )
              .toList(),
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _buildDateField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Date Added",
          style: GoogleFonts.comicNeue(
            color: Colors.white70,
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
              builder: (context, child) =>
                  Theme(data: ThemeData.dark(), child: child!),
            );
            if (picked != null) setState(() => selectedDate = picked);
          },
          child: Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: const Color(0xFF2A2D3E),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  DateFormat('dd MMM yyyy').format(selectedDate),
                  style: const TextStyle(color: Colors.white),
                ),
                const Icon(
                  Icons.calendar_today,
                  color: Colors.cyanAccent,
                  size: 18,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
