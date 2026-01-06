import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:marvellous_admin/features/categories/models/category_model.dart';
import 'package:marvellous_admin/features/dashboard/presentation/screens/dashboard_screen.dart';

// Controllers
import '../../../categories/controllers/category_controller.dart';
import '../../../vendors/controllers/vendor_controller.dart';
import '../../controller/products_controller.dart';

// Models
import '../../models/product_model.dart';

// SCREEN IMPORT
import 'products_home_screen.dart';

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
  String _currentName = "";
  final TextEditingController _nameTextController = TextEditingController();

  final TextEditingController modelCtrl = TextEditingController();
  final TextEditingController descCtrl = TextEditingController();
  final TextEditingController brandCtrl = TextEditingController();

  // Mobile Specific Controllers
  final TextEditingController ramCtrl = TextEditingController();
  final TextEditingController storageCtrl = TextEditingController();

  // Pricing
  final TextEditingController purchasePriceCtrl = TextEditingController();
  final TextEditingController salePriceCtrl = TextEditingController();
  final TextEditingController originalPriceCtrl = TextEditingController();

  final TextEditingController stockCtrl = TextEditingController();
  final TextEditingController warrantyCtrl = TextEditingController();

  // State Variables
  DateTime selectedDate = DateTime.now();
  String? selectedCategory;
  String? selectedSubCategory;
  String? selectedVendorId;
  String? selectedLocation;
  List<String> selectedImagesBase64 = [];

  double calculatedPoints = 0.0;

  bool _showDecimalPoints = true;
  bool _isSuccess = false;
  bool _isMobile = false;

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
      selectedLocation = locationOptions[1];
    }

    purchasePriceCtrl.addListener(_calculatePoints);
    salePriceCtrl.addListener(_calculatePoints);

    _nameTextController.addListener(() {
      _checkIfMobile(_nameTextController.text);
      _currentName = _nameTextController.text;
    });
  }

  void _checkIfMobile(String val) {
    if (val.toLowerCase().contains("mobile")) {
      if (!_isMobile) setState(() => _isMobile = true);
    } else {
      if (_isMobile) setState(() => _isMobile = false);
    }
  }

  void _calculatePoints() {
    double buy = double.tryParse(purchasePriceCtrl.text) ?? 0;
    double sell = double.tryParse(salePriceCtrl.text) ?? 0;
    setState(() {
      calculatedPoints = productController.calculatePoints(buy, sell);
    });
  }

  void _loadProductData(ProductModel product) {
    _nameTextController.text = product.name;
    _currentName = product.name;
    _checkIfMobile(product.name);

    modelCtrl.text = product.modelNumber;
    descCtrl.text = product.description;
    brandCtrl.text = product.brand;
    purchasePriceCtrl.text = product.purchasePrice.toString();
    salePriceCtrl.text = product.salePrice.toString();
    originalPriceCtrl.text = product.originalPrice == 0.0
        ? ""
        : product.originalPrice.toString();
    stockCtrl.text = product.stockQuantity.toString();
    warrantyCtrl.text = product.warranty;

    ramCtrl.text = product.ram ?? "";
    storageCtrl.text = product.storage ?? "";

    selectedCategory = product.category;
    selectedSubCategory = product.subCategory;
    selectedVendorId = product.vendorId;
    selectedLocation = product.deliveryLocation;
    selectedImagesBase64 = List.from(product.images);
    selectedDate = product.dateAdded;
    calculatedPoints = product.productPoints;
    _showDecimalPoints = product.showDecimalPoints;
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
    _nameTextController.clear();
    _currentName = "";
    modelCtrl.clear();
    descCtrl.clear();
    brandCtrl.clear();
    purchasePriceCtrl.clear();
    salePriceCtrl.clear();
    originalPriceCtrl.clear();
    stockCtrl.clear();
    warrantyCtrl.clear();
    ramCtrl.clear();
    storageCtrl.clear();

    setState(() {
      selectedImagesBase64.clear();
      selectedCategory = null;
      selectedSubCategory = null;
      calculatedPoints = 0.0;
      _showDecimalPoints = true;
      _isMobile = false;
      if (widget.preSelectedVendorId == null) selectedVendorId = null;
    });
  }

  // --- NEW FUNCTION: Show History Dialog ---
  void _showHistoryDialog() {
    Get.dialog(
      Dialog(
        backgroundColor: const Color(0xFF2A2D3E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          padding: const EdgeInsets.all(20),
          height: 400,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Input History",
                    style: GoogleFonts.orbitron(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () {
                      productController.clearAllHistory();
                      Get.back();
                      Get.snackbar(
                        "Success",
                        "History Cleared",
                        backgroundColor: Colors.green,
                        colorText: Colors.white,
                      );
                    },
                    icon: const Icon(
                      Icons.delete_sweep,
                      color: Colors.redAccent,
                      size: 20,
                    ),
                    label: const Text(
                      "Clear All",
                      style: TextStyle(color: Colors.redAccent),
                    ),
                  ),
                ],
              ),
              const Divider(color: Colors.white10),
              const SizedBox(height: 10),

              // HISTORY LIST
              Expanded(
                child: Obx(() {
                  if (productController.searchHistoryList.isEmpty) {
                    return Center(
                      child: Text(
                        "No history found.",
                        style: GoogleFonts.comicNeue(
                          color: Colors.white54,
                          fontSize: 16,
                        ),
                      ),
                    );
                  }
                  return ListView.builder(
                    itemCount: productController.searchHistoryList.length,
                    itemBuilder: (context, index) {
                      final item = productController.searchHistoryList[index];
                      return ListTile(
                        leading: const Icon(
                          Icons.history,
                          color: Colors.cyanAccent,
                          size: 18,
                        ),
                        title: Text(
                          item,
                          style: const TextStyle(color: Colors.white),
                        ),
                        trailing: IconButton(
                          icon: const Icon(
                            Icons.close,
                            color: Colors.white24,
                            size: 18,
                          ),
                          onPressed: () =>
                              productController.removeHistoryItem(item),
                        ),
                        onTap: () {
                          Get.back();
                        },
                      );
                    },
                  );
                }),
              ),

              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => Get.back(),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.white24),
                  ),
                  child: const Text(
                    "Close",
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
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
        automaticallyImplyLeading: false,

        actions: [
          IconButton(
            onPressed: _showHistoryDialog,
            icon: const Icon(Icons.history, color: Colors.cyanAccent),
            tooltip: "View History",
          ),
          const SizedBox(width: 10),
        ],
      ),
      body: Stack(
        children: [
          Opacity(
            opacity: _isSuccess ? 0.1 : 1.0,
            child: AbsorbPointer(
              absorbing: _isSuccess,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ================= MEDIA =================
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
                                      border: Border.all(
                                        color: Colors.cyanAccent,
                                      ),
                                      image: DecorationImage(
                                        image: MemoryImage(
                                          base64Decode(
                                            selectedImagesBase64[index],
                                          ),
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

                      // ================= BASIC INFO =================
                      _buildSectionTitle("Basic Information"),
                      _buildDateField(),
                      const SizedBox(height: 15),

                      // -- PRODUCT NAME WITH HISTORY --
                      _buildAutocompleteField(
                        label: "Product Name",
                        hint: "e.g. Smart Fridge or Mobile",
                        controller: _nameTextController,
                        onChanged: (val) {
                          _currentName = val;
                          _checkIfMobile(val);
                        },
                      ),

                      const SizedBox(height: 15),

                      // -- CONDITIONAL MOBILE FIELDS --
                      if (_isMobile) ...[
                        Row(
                          children: [
                            Expanded(
                              child: _buildTextField(
                                "RAM",
                                "e.g. 8GB",
                                ramCtrl,
                              ),
                            ),
                            const SizedBox(width: 15),
                            Expanded(
                              child: _buildTextField(
                                "Storage",
                                "e.g. 128GB",
                                storageCtrl,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 15),
                      ],

                      _buildTextField(
                        "Model Number",
                        "e.g. SF-2024",
                        modelCtrl,
                      ),
                      const SizedBox(height: 15),

                      // -- BRAND WITH HISTORY --
                      _buildAutocompleteField(
                        label: "Brand",
                        hint: "Select or type brand",
                        controller: brandCtrl,
                        onChanged: (val) => brandCtrl.text = val,
                      ),

                      const SizedBox(height: 15),
                      _buildTextField(
                        "Description",
                        "Enter details...",
                        descCtrl,
                        maxLines: 5,
                        isMultiline: true,
                      ),

                      const SizedBox(height: 30),

                      // ================= LOGISTICS =================
                      _buildSectionTitle("Logistics"),
                      Obx(() {
                        List<CategoryModel> cats =
                            categoryController.categories;
                        if (cats.isEmpty) {
                          return _buildDynamicDropdown<String>(
                            label: "Category",
                            hint: "No Categories Found",
                            value: null,
                            items: [],
                            onChanged: (val) {},
                          );
                        }
                        if (selectedCategory == null &&
                            widget.productToEdit == null) {
                          Future.microtask(() {
                            if (mounted && selectedCategory == null) {
                              setState(() {
                                selectedCategory = cats.first.name;
                                selectedSubCategory = null;
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
                      Obx(() {
                        List<CategoryModel> allCats =
                            categoryController.categories;
                        List<String> subCats = [];
                        if (selectedCategory != null) {
                          var catObj = allCats.firstWhere(
                            (c) => c.name == selectedCategory,
                            orElse: () =>
                                CategoryModel(name: '', subCategories: []),
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
                          onChanged: (val) =>
                              setState(() => selectedSubCategory = val),
                        );
                      }),
                      const SizedBox(height: 15),
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
                        onChanged: (val) =>
                            setState(() => selectedLocation = val),
                      ),

                      const SizedBox(height: 30),

                      // ================= WARRANTY =================
                      _buildSectionTitle("Warranty"),
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
                        "Or type custom warranty",
                        warrantyCtrl,
                      ),

                      const SizedBox(height: 30),

                      // ================= PRICING =================
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
                              "Original Price (Optional)",
                              "Fake High Price",
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
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  "Customer Points Reward:",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 5),
                                Row(
                                  children: [
                                    Transform.scale(
                                      scale: 0.8,
                                      child: Checkbox(
                                        value: _showDecimalPoints,
                                        activeColor: Colors.purpleAccent,
                                        onChanged: (val) {
                                          setState(() {
                                            _showDecimalPoints = val!;
                                          });
                                        },
                                      ),
                                    ),
                                    const Text(
                                      "Show Decimals",
                                      style: TextStyle(
                                        color: Colors.white54,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            Text(
                              _showDecimalPoints
                                  ? "${calculatedPoints.toStringAsFixed(1)} Pts"
                                  : "${calculatedPoints.toInt()} Pts",
                              style: const TextStyle(
                                color: Colors.purpleAccent,
                                fontWeight: FontWeight.bold,
                                fontSize: 20,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 15),

                      // ================= VENDOR =================
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
                                  value: v.id,
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

                      const SizedBox(height: 40),

                      // ================= ACTION BUTTON =================
                      SizedBox(
                        width: double.infinity,
                        height: 55,
                        child: Obx(
                          () => ElevatedButton(
                            onPressed: productController.isLoading.value
                                ? null
                                : () async {
                                    if (_formKey.currentState!.validate()) {
                                      if (_currentName.isEmpty) {
                                        Get.snackbar(
                                          "Error",
                                          "Product Name is required",
                                          backgroundColor: Colors.red,
                                          colorText: Colors.white,
                                        );
                                        return;
                                      }

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
                                        name: _currentName,
                                        modelNumber: modelCtrl.text,
                                        description: descCtrl.text,
                                        category: selectedCategory!,
                                        subCategory:
                                            selectedSubCategory ?? "General",
                                        brand: brandCtrl.text.isEmpty
                                            ? "Generic"
                                            : brandCtrl.text,
                                        purchasePrice:
                                            double.tryParse(
                                              purchasePriceCtrl.text,
                                            ) ??
                                            0,
                                        salePrice:
                                            double.tryParse(
                                              salePriceCtrl.text,
                                            ) ??
                                            0,
                                        originalPrice:
                                            double.tryParse(
                                              originalPriceCtrl.text,
                                            ) ??
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
                                        showDecimalPoints: _showDecimalPoints,
                                        ram: _isMobile ? ramCtrl.text : null,
                                        storage: _isMobile
                                            ? storageCtrl.text
                                            : null,
                                      );

                                      bool success;
                                      if (widget.productToEdit == null) {
                                        success = await productController
                                            .addNewProduct(newProduct);
                                        if (success) _clearForm();
                                      } else {
                                        success = await productController
                                            .updateProduct(newProduct);
                                      }

                                      if (success) {
                                        setState(() {
                                          _isSuccess = true;
                                        });
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
                                ? const CircularProgressIndicator(
                                    color: Colors.black,
                                  )
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
            ),
          ),

          // 2. SUCCESS OVERLAY
          if (_isSuccess)
            Container(
              color: Colors.black54,
              child: Center(
                child: Container(
                  width: 300,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2A2D3E),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.cyanAccent, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.cyanAccent.withOpacity(0.2),
                        blurRadius: 20,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.check_circle,
                        color: Colors.greenAccent,
                        size: 60,
                      ),
                      const SizedBox(height: 20),
                      Text(
                        widget.productToEdit == null
                            ? "Product Saved!"
                            : "Product Updated!",
                        style: GoogleFonts.orbitron(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 30),
                      if (widget.productToEdit == null)
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () {
                              setState(() {
                                _isSuccess = false;
                              });
                            },
                            icon: const Icon(Icons.add, color: Colors.black),
                            label: const Text(
                              "Add Another Product",
                              style: TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.cyanAccent,
                            ),
                          ),
                        ),
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () {
                            // CHANGE HERE: Instead of navigating away, just close the overlay
                            setState(() {
                              _isSuccess = false;
                            });
                          },
                          icon: const Icon(
                            Icons
                                .close, // Icon change kar diya arrow se close mein
                            color: Colors.white,
                          ),
                          label: const Text(
                            "Close", // Text change kar diya "Go Back" se "Close" mein
                            style: TextStyle(color: Colors.white),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Colors.white54),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // --- AUTOCOMPLETE WIDGET (Fixed) ---
  Widget _buildAutocompleteField({
    required String label,
    required String hint,
    required TextEditingController controller,
    required Function(String) onChanged,
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
        Autocomplete<String>(
          initialValue: TextEditingValue(text: controller.text),
          optionsBuilder: (TextEditingValue textEditingValue) {
            // Check full history list first
            final history = productController.searchHistoryList;

            if (textEditingValue.text.isEmpty) {
              return history.take(5);
            }

            // Filter and return matches
            final matches = productController.getSuggestions(
              textEditingValue.text,
            );

            // If no matches found in history/brands, return empty list (which hides dropdown)
            // Or you can choose to show "No history found" logic here if custom UI allows.
            return matches;
          },
          onSelected: (String selection) {
            controller.text = selection;
            onChanged(selection);
          },
          fieldViewBuilder:
              (context, fieldTextController, focusNode, onEditingComplete) {
                // Keep sync
                if (controller.text.isNotEmpty &&
                    fieldTextController.text.isEmpty) {
                  fieldTextController.text = controller.text;
                }
                return TextFormField(
                  controller: fieldTextController,
                  focusNode: focusNode,
                  onEditingComplete: onEditingComplete,
                  onChanged: (val) {
                    controller.text = val;
                    onChanged(val);
                  },
                  style: const TextStyle(color: Colors.white),
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
                  validator: (val) => val!.isEmpty ? "Required" : null,
                );
              },
          // Dropdown Builder
          optionsViewBuilder: (context, onSelected, options) {
            return Align(
              alignment: Alignment.topLeft,
              child: Material(
                elevation: 4.0,
                color: const Color(0xFF2A2D3E),
                child: SizedBox(
                  width: 300,
                  // Using Obx here to update list immediately when item removed
                  child: Obx(() {
                    // We need to re-fetch/filter based on current state of history list in controller
                    // Since Autocomplete passes static options list initially,
                    // we ignore 'options' param here and use controller list filtered by current text manually for real-time updates
                    // OR just use ListView logic on passed options but force rebuild.

                    // Simple approach: Use passed options but force UI update via Obx context
                    // However, 'options' is Iterable<String>, not observable.

                    // Better approach:
                    final currentText = _currentName.toLowerCase();
                    final List<String> currentList = productController
                        .searchHistoryList
                        .where((s) => s.toLowerCase().contains(currentText))
                        .toList();

                    if (currentList.isEmpty && currentText.isEmpty) {
                      return Container(
                        padding: const EdgeInsets.all(15),
                        child: Text(
                          "No history found",
                          style: TextStyle(color: Colors.white54),
                        ),
                      );
                    }

                    // Use filtered list from controller directly to ensure sync
                    final displayList = currentText.isEmpty
                        ? productController.searchHistoryList.take(5).toList()
                        : productController.getSuggestions(_currentName);

                    if (displayList.isEmpty) return SizedBox.shrink();

                    return ListView.builder(
                      padding: EdgeInsets.zero,
                      shrinkWrap: true,
                      itemCount: displayList.length,
                      itemBuilder: (BuildContext context, int index) {
                        final String option = displayList.elementAt(index);
                        return ListTile(
                          onTap: () => onSelected(option),
                          title: Text(
                            option,
                            style: const TextStyle(color: Colors.white),
                          ),
                          trailing: IconButton(
                            icon: const Icon(
                              Icons.close,
                              size: 16,
                              color: Colors.white24,
                            ),
                            onPressed: () {
                              productController.removeHistoryItem(option);
                            },
                          ),
                        );
                      },
                    );
                  }),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  // --- EXISTING HELPERS ---
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
          validator: (val) {
            if (label.contains("Optional")) return null;
            return val!.isEmpty ? "Required" : null;
          },
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
