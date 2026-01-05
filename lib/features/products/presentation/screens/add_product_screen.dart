import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:marvellous_admin/features/categories/models/category_model.dart';

// Controllers
import '../../../categories/controllers/category_controller.dart';
import '../../../vendors/controllers/vendor_controller.dart';
import '../../controller/products_controller.dart';

// Models
import '../../models/product_model.dart';

class AddProductScreen extends StatefulWidget {
  final ProductModel? productToEdit;
  final String? preSelectedVendorId;

  const AddProductScreen({
    Key? key,
    this.productToEdit,
    this.preSelectedVendorId,
  }) : super(key: key);

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
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

  // Pricing
  final TextEditingController purchasePriceCtrl = TextEditingController();
  final TextEditingController salePriceCtrl = TextEditingController();
  final TextEditingController originalPriceCtrl =
      TextEditingController(); // FAKE PRICE

  final TextEditingController stockCtrl = TextEditingController();
  final TextEditingController warrantyCtrl = TextEditingController();

  // State Variables
  DateTime selectedDate = DateTime.now();
  String? selectedCategory;
  String? selectedSubCategory;
  String? selectedVendorId;
  String? selectedLocation; // New Location Field
  List<String> selectedImagesBase64 = [];

  double calculatedPoints = 0.0;

  // Options
  final List<String> locationOptions = [
    "Karachi Only",
    "Pakistan",
    "Worldwide",
    "Store Pickup Only",
  ];

  final List<String> warrantyOptions = [
    "No Warranty",
    "6 Months",
    "1 Year",
    "2 Years",
    "3 Years",
    "5 Years",
  ];

  @override
  void initState() {
    super.initState();
    if (widget.productToEdit != null) {
      _loadProductData(widget.productToEdit!);
    } else {
      if (widget.preSelectedVendorId != null) {
        selectedVendorId = widget.preSelectedVendorId;
      }
      selectedLocation = locationOptions[1]; // Default Pakistan
    }

    // Listener for Points Calculation
    purchasePriceCtrl.addListener(_calculatePoints);
    salePriceCtrl.addListener(_calculatePoints);
  }

  void _calculatePoints() {
    double buy = double.tryParse(purchasePriceCtrl.text) ?? 0;
    double sell = double.tryParse(salePriceCtrl.text) ?? 0;
    setState(() {
      calculatedPoints = productController.calculatePoints(buy, sell);
    });
  }

  void _loadProductData(ProductModel product) {
    nameCtrl.text = product.name;
    modelCtrl.text = product.modelNumber;
    descCtrl.text = product.description;
    brandCtrl.text = product.brand;
    purchasePriceCtrl.text = product.purchasePrice.toString();
    salePriceCtrl.text = product.salePrice.toString();
    originalPriceCtrl.text = product.originalPrice.toString();
    stockCtrl.text = product.stockQuantity.toString();
    warrantyCtrl.text = product.warranty;

    selectedCategory = product.category;
    selectedSubCategory = product.subCategory;
    selectedVendorId = product.vendorId;
    selectedLocation = product.deliveryLocation;
    selectedImagesBase64 = List.from(product.images);
    selectedDate = product.dateAdded;
    calculatedPoints = product.productPoints;
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
    originalPriceCtrl.clear();
    stockCtrl.clear();
    warrantyCtrl.clear();
    setState(() {
      selectedImagesBase64.clear();
      selectedCategory = null;
      selectedSubCategory = null;
      calculatedPoints = 0.0;
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

              // BRAND AUTOCOMPLETE
              Text(
                "Brand",
                style: GoogleFonts.comicNeue(
                  color: Colors.white70,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Autocomplete<String>(
                initialValue: TextEditingValue(text: brandCtrl.text),
                optionsBuilder: (TextEditingValue textEditingValue) {
                  if (textEditingValue.text == '') {
                    return const Iterable<String>.empty();
                  }
                  return productController.existingBrands.where((
                    String option,
                  ) {
                    return option.toLowerCase().contains(
                      textEditingValue.text.toLowerCase(),
                    );
                  });
                },
                onSelected: (String selection) {
                  brandCtrl.text = selection;
                },
                fieldViewBuilder:
                    (context, controller, focusNode, onEditingComplete) {
                      // Bind the local controller to the passed controller from Autocomplete
                      controller.addListener(() {
                        brandCtrl.text = controller.text;
                      });
                      return TextFormField(
                        controller: controller,
                        focusNode: focusNode,
                        onEditingComplete: onEditingComplete,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: "Select or type brand",
                          hintStyle: const TextStyle(color: Colors.white24),
                          filled: true,
                          fillColor: const Color(0xFF2A2D3E),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(
                              color: Colors.cyanAccent,
                            ),
                          ),
                        ),
                      );
                    },
                optionsViewBuilder: (context, onSelected, options) {
                  return Align(
                    alignment: Alignment.topLeft,
                    child: Material(
                      elevation: 4.0,
                      color: const Color(0xFF2A2D3E),
                      child: SizedBox(
                        width: 300,
                        child: ListView.builder(
                          padding: EdgeInsets.zero,
                          shrinkWrap: true,
                          itemCount: options.length,
                          itemBuilder: (BuildContext context, int index) {
                            final String option = options.elementAt(index);
                            return InkWell(
                              onTap: () => onSelected(option),
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Text(
                                  option,
                                  style: const TextStyle(color: Colors.white),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  );
                },
              ),

              const SizedBox(height: 15),

              // DESCRIPTION
              _buildTextField(
                "Description",
                "Enter full product details...",
                descCtrl,
                maxLines: 5,
                isMultiline: true,
              ),

              const SizedBox(height: 30),

              // ================= SECTION 3: CATEGORIZATION & LOCATION =================
              _buildSectionTitle("Logistics"),

              // CATEGORY (Auto-Selects First, but not Sub-Category)
              Obx(() {
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

                // Auto Select First Category if none selected
                if (selectedCategory == null && widget.productToEdit == null) {
                  Future.microtask(() {
                    if (mounted && selectedCategory == null) {
                      setState(() {
                        selectedCategory = cats.first.name;
                        selectedSubCategory = null; // Ensure Sub is empty
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
                      selectedSubCategory =
                          null; // Always reset sub-cat on category change
                    });
                  },
                );
              }),

              const SizedBox(height: 15),

              // SUB-CATEGORY (Remains empty initially)
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

                // Validate selectedSubCategory against list
                String? validSelectedSubCategory =
                    subCats.contains(selectedSubCategory)
                    ? selectedSubCategory
                    : null;

                return _buildDynamicDropdown<String>(
                  label: "Sub Category",
                  hint: selectedCategory == null
                      ? "Select Category First"
                      : "Select Sub-Category", // Will show this hint
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

              // LOCATION TO DELIVER
              _buildDynamicDropdown<String>(
                label: "Location to Deliver",
                hint: "Select Region",
                value: selectedLocation,
                items: locationOptions
                    .map(
                      (l) => DropdownMenuItem(
                        value: l,
                        child: Text(
                          l,
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (val) => setState(() => selectedLocation = val),
              ),

              const SizedBox(height: 30),

              // ================= SECTION 4: WARRANTY =================
              _buildSectionTitle("Warranty"),

              // Warranty Chips
              Wrap(
                spacing: 8,
                children: warrantyOptions.map((option) {
                  return ActionChip(
                    label: Text(option),
                    backgroundColor: warrantyCtrl.text == option
                        ? Colors.purpleAccent
                        : const Color(0xFF2A2D3E),
                    labelStyle: TextStyle(
                      color: warrantyCtrl.text == option
                          ? Colors.white
                          : Colors.white70,
                      fontWeight: FontWeight.bold,
                    ),
                    onPressed: () {
                      setState(() {
                        warrantyCtrl.text = option;
                      });
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 10),
              _buildTextField(
                "Custom Warranty",
                "Or type custom warranty (e.g. 10 Years)",
                warrantyCtrl,
              ),

              const SizedBox(height: 30),

              // ================= SECTION 5: PRICING & INVENTORY =================
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
                      "Quantity",
                      "0",
                      stockCtrl,
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
                      "Original Price (Fake)",
                      "High Price",
                      originalPriceCtrl,
                      isNumber: true,
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: _buildTextField(
                      "Sale Price (Discounted)",
                      "Actual Price",
                      salePriceCtrl,
                      isNumber: true,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // POINTS DISPLAY
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: Colors.purpleAccent.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.purpleAccent),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "Customer Points Reward:",
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                    Text(
                      "${calculatedPoints.toStringAsFixed(1)} Pts",
                      style: const TextStyle(
                        color: Colors.purpleAccent,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 15),

              // DYNAMIC VENDOR DROPDOWN
              Obx(() {
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
                if (selectedVendorId == null) {
                  Future.microtask(() {
                    if (mounted && selectedVendorId == null) {
                      setState(() {
                        selectedVendorId =
                            widget.preSelectedVendorId ?? vendorsList.first.id;
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
                          value: v.id,
                          child: Text(
                            v.storeName,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (val) => setState(() => selectedVendorId = val),
                );
              }),

              const SizedBox(height: 40),

              // ================= SECTION 6: ACTION BUTTON =================
              SizedBox(
                width: double.infinity,
                height: 55,
                child: Obx(
                  () => ElevatedButton(
                    onPressed: productController.isLoading.value
                        ? null
                        : () async {
                            if (_formKey.currentState!.validate()) {
                              if (selectedCategory == null ||
                                  selectedVendorId == null) {
                                Get.snackbar(
                                  "Error",
                                  "Please select Category and Vendor",
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
                                originalPrice:
                                    double.tryParse(originalPriceCtrl.text) ??
                                    0,
                                stockQuantity:
                                    int.tryParse(stockCtrl.text) ?? 0,
                                vendorId: selectedVendorId!,
                                images: selectedImagesBase64,
                                dateAdded: selectedDate,
                                deliveryLocation:
                                    selectedLocation ?? 'Worldwide',
                                warranty: warrantyCtrl.text.isEmpty
                                    ? "No Warranty"
                                    : warrantyCtrl.text,
                                productPoints: calculatedPoints,
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
    bool isMultiline = false,
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
          keyboardType: isNumber
              ? TextInputType.number
              : (isMultiline ? TextInputType.multiline : TextInputType.text),
          textInputAction: isMultiline
              ? TextInputAction.newline
              : TextInputAction.next,
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
