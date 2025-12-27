import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:marvellous_admin/features/categories/models/category_model.dart';
import 'package:marvellous_admin/features/layout/presentation/screens/main_layout_screen.dart';
import 'package:marvellous_admin/features/products/presentation/screens/products_home_screen.dart';

// Controllers
import '../../../categories/controllers/category_controller.dart';
import '../../../vendors/controllers/vendor_controller.dart';
import '../../controller/products_controller.dart';

// Models
import '../../models/product_model.dart';

class AddProductScreen extends StatefulWidget {
  final ProductModel? productToEdit; // Data for Edit Mode
  final String?
  preSelectedVendorId; // For auto-selecting vendor from detail screen

  const AddProductScreen({
    Key? key,
    this.productToEdit,
    this.preSelectedVendorId,
  }) : super(key: key);

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  // FORCE INJECT CONTROLLERS
  final ProductsController productController = Get.put(ProductsController());
  final CategoryController categoryController = Get.put(CategoryController());
  final VendorController vendorController = Get.put(VendorController());

  final _formKey = GlobalKey<FormState>();
  final ImagePicker _picker = ImagePicker();

  // Text Controllers
  final TextEditingController nameCtrl = TextEditingController();
  final TextEditingController modelCtrl = TextEditingController();
  final TextEditingController descCtrl = TextEditingController();
  final TextEditingController brandCtrl = TextEditingController();
  final TextEditingController purchasePriceCtrl = TextEditingController();
  final TextEditingController salePriceCtrl = TextEditingController();
  final TextEditingController stockCtrl = TextEditingController();

  // State Variables
  DateTime selectedDate = DateTime.now();
  String? selectedCategory;
  String? selectedSubCategory;
  String? selectedVendorId;
  List<String> selectedImagesBase64 = [];

  @override
  void initState() {
    super.initState();
    if (widget.productToEdit != null) {
      _loadProductData(widget.productToEdit!);
    } else {
      // Logic for pre-selected vendor
      if (widget.preSelectedVendorId != null) {
        selectedVendorId = widget.preSelectedVendorId;
      }
    }
  }

  void _loadProductData(ProductModel product) {
    nameCtrl.text = product.name;
    modelCtrl.text = product.modelNumber;
    descCtrl.text = product.description;
    brandCtrl.text = product.brand;
    purchasePriceCtrl.text = product.purchasePrice.toString();
    salePriceCtrl.text = product.salePrice.toString();
    stockCtrl.text = product.stockQuantity.toString();

    selectedCategory = product.category;
    selectedSubCategory = product.subCategory;
    selectedVendorId = product.vendorId;
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
    brandCtrl.clear();
    purchasePriceCtrl.clear();
    salePriceCtrl.clear();
    stockCtrl.clear();
    setState(() {
      selectedImagesBase64.clear();
      selectedCategory = null;
      selectedSubCategory = null;
      // Keep vendor selected if it was pre-selected
      if (widget.preSelectedVendorId == null) selectedVendorId = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E1E2C),
      appBar: AppBar(
        title: Text(
          widget.productToEdit == null ? "Add New Product" : "Edit Product",
          style: GoogleFonts.orbitron(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        // leading: IconButton(
        //   icon: const Icon(Icons.arrow_back, color: Colors.white),
        //   onPressed: () => Get.off(() => MainLayoutScreen()),
        // ),
      ),
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

              // 1. DYNAMIC CATEGORY DROPDOWN
              Obx(() {
                final _ = categoryController.categories.length;

                if (categoryController.isLoading.value) {
                  return const Center(child: CircularProgressIndicator());
                }

                List<CategoryModel> cats = categoryController.categories;

                if (cats.isEmpty) {
                  return _buildDynamicDropdown<String>(
                    label: "Category",
                    hint: "No Categories Found",
                    value: null,
                    items: [],
                    onChanged: (val) {},
                  );
                }

                if (selectedCategory == null && widget.productToEdit == null) {
                  Future.microtask(() {
                    if (mounted && selectedCategory == null) {
                      setState(() {
                        selectedCategory = cats.first.name;
                      });
                    }
                  });
                }

                String? validSelectedCategory =
                    cats.any((c) => c.name == selectedCategory)
                    ? selectedCategory
                    : null;

                return _buildDynamicDropdown<String>(
                  label: "Category",
                  hint: "Select Category",
                  value: validSelectedCategory,
                  items: cats
                      .map(
                        (c) => DropdownMenuItem(
                          value: c.name,
                          child: Text(
                            c.name,
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (val) {
                    setState(() {
                      selectedCategory = val;
                      selectedSubCategory = null;
                    });
                  },
                );
              }),

              const SizedBox(height: 15),

              // 2. DYNAMIC SUB-CATEGORY DROPDOWN
              Obx(() {
                List<CategoryModel> allCats = categoryController.categories;

                List<String> subCats = [];
                if (selectedCategory != null) {
                  var catObj = allCats.firstWhere(
                    (c) => c.name == selectedCategory,
                    orElse: () => CategoryModel(name: '', subCategories: []),
                  );
                  subCats = catObj.subCategories;
                }

                String? validSelectedSubCategory =
                    subCats.contains(selectedSubCategory)
                    ? selectedSubCategory
                    : null;

                return _buildDynamicDropdown<String>(
                  label: "Sub Category",
                  hint: selectedCategory == null
                      ? "Select Category First"
                      : "Select Sub-Category",
                  value: validSelectedSubCategory,
                  items: subCats
                      .map(
                        (s) => DropdownMenuItem(
                          value: s,
                          child: Text(
                            s,
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (val) => setState(() => selectedSubCategory = val),
                );
              }),

              const SizedBox(height: 15),

              // 3. BRAND TEXT FIELD
              _buildTextField("Brand", "e.g. Samsung", brandCtrl),

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

                  // DYNAMIC VENDOR DROPDOWN
                  Expanded(
                    child: Obx(() {
                      final _ = vendorController.vendors.length;

                      if (vendorController.isLoading.value) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      var vendorsList = vendorController.vendors;

                      if (vendorsList.isEmpty) {
                        return _buildDynamicDropdown<String>(
                          label: "Vendor",
                          hint: "No Vendors Found",
                          value: null,
                          items: [],
                          onChanged: (val) {},
                        );
                      }

                      // AUTO SELECT LOGIC (Prioritize preSelectedVendorId)
                      if (selectedVendorId == null) {
                        Future.microtask(() {
                          if (mounted && selectedVendorId == null) {
                            setState(() {
                              // Use preSelectedVendorId if passed, else first from list
                              selectedVendorId =
                                  widget.preSelectedVendorId ??
                                  vendorsList.first.id;
                            });
                          }
                        });
                      }

                      String? validSelectedVendorId =
                          vendorsList.any((v) => v.id == selectedVendorId)
                          ? selectedVendorId
                          : null;

                      return _buildDynamicDropdown<String>(
                        label: "Vendor",
                        hint: "Select Vendor",
                        value: validSelectedVendorId,
                        items: vendorsList
                            .map(
                              (v) => DropdownMenuItem(
                                value: v.id, // Storing ID
                                child: Text(
                                  v.storeName,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(color: Colors.white),
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: (val) =>
                            setState(() => selectedVendorId = val),
                      );
                    }),
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
                    onPressed: productController.isLoading.value
                        ? null
                        : () async {
                            if (_formKey.currentState!.validate()) {
                              // Validations
                              if (selectedCategory == null) {
                                Get.snackbar(
                                  "Error",
                                  "Please select a Category",
                                  backgroundColor: Colors.red,
                                  colorText: Colors.white,
                                );
                                return;
                              }
                              if (selectedVendorId == null) {
                                Get.snackbar(
                                  "Error",
                                  "Please select a Vendor",
                                  backgroundColor: Colors.red,
                                  colorText: Colors.white,
                                );
                                return;
                              }

                              ProductModel newProduct = ProductModel(
                                id: widget.productToEdit?.id,
                                name: nameCtrl.text,
                                modelNumber: modelCtrl.text,
                                description: descCtrl.text,
                                category: selectedCategory!,
                                subCategory: selectedSubCategory ?? "General",
                                brand: brandCtrl.text.isEmpty
                                    ? "Generic"
                                    : brandCtrl.text,
                                purchasePrice:
                                    double.tryParse(purchasePriceCtrl.text) ??
                                    0,
                                salePrice:
                                    double.tryParse(salePriceCtrl.text) ?? 0,
                                stockQuantity:
                                    int.tryParse(stockCtrl.text) ?? 0,
                                vendorId: selectedVendorId!,
                                images: selectedImagesBase64,
                                dateAdded: selectedDate,
                              );

                              bool success;
                              if (widget.productToEdit == null) {
                                success = await productController.addNewProduct(
                                  newProduct,
                                );
                                if (success) _clearForm();
                              } else {
                                success = await productController.updateProduct(
                                  newProduct,
                                );
                              }

                              if (success && widget.productToEdit != null) {
                                Get.back();
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
                    child: productController.isLoading.value
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
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  // --- HELPER WIDGETS ---

  Widget _buildDynamicDropdown<T>({
    required String label,
    required String hint,
    required T? value,
    required List<DropdownMenuItem<T>> items,
    required Function(T?) onChanged,
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
        DropdownButtonFormField<T>(
          value: value,
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
          hint: Text(hint, style: const TextStyle(color: Colors.white24)),
          items: items,
          onChanged: onChanged,
          validator: (val) => val == null ? "Required" : null,
        ),
      ],
    );
  }

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
