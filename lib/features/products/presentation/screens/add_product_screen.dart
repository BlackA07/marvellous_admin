import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

// Controllers & Models
import '../../../../features/categories/controllers/category_controller.dart';
import '../../../../features/vendors/controllers/vendor_controller.dart';
import '../../controller/products_controller.dart';
import '../../models/product_model.dart';
import '../../../categories/models/category_model.dart';

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

  final TextEditingController warrantyCtrl = TextEditingController();

  // State Variables
  DateTime selectedDate = DateTime.now();
  String? selectedCategory;
  String? selectedSubCategory;
  String? selectedVendorId;
  String? selectedLocation;
  List<String> selectedImagesBase64 = [];

  double calculatedPoints = 0.0;
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

  // Updated Theme Colors (Lighter but readable)
  final Color bgColor = const Color(0xFFF5F7FA); // Light Greyish White
  final Color cardColor = Colors.white;
  final Color textColor = Colors.black87;
  final Color inputFillColor = const Color(0xFFE0E0E0); // Light grey for inputs
  final Color accentColor = Colors.deepPurple;

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
    // Stock logic removed from load as field is removed
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
    warrantyCtrl.clear();
    ramCtrl.clear();
    storageCtrl.clear();

    setState(() {
      selectedImagesBase64.clear();
      selectedCategory = null;
      selectedSubCategory = null;
      calculatedPoints = 0.0;
      _isMobile = false;
      if (widget.preSelectedVendorId == null) selectedVendorId = null;
    });
  }

  void _showHistoryDialog() {
    Get.dialog(
      Dialog(
        backgroundColor: Colors.white, // Light dialog
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
                      color: Colors.black87,
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
              const Divider(color: Colors.grey),
              const SizedBox(height: 10),
              Expanded(
                child: Obx(() {
                  if (productController.searchHistoryList.isEmpty) {
                    return Center(
                      child: Text(
                        "No history found.",
                        style: GoogleFonts.comicNeue(
                          color: Colors.grey,
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
                          color: Colors.blueAccent,
                          size: 18,
                        ),
                        title: Text(
                          item,
                          style: const TextStyle(color: Colors.black87),
                        ),
                        trailing: IconButton(
                          icon: const Icon(
                            Icons.close,
                            color: Colors.grey,
                            size: 18,
                          ),
                          onPressed: () =>
                              productController.removeHistoryItem(item),
                        ),
                        onTap: () => Get.back(),
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
                    side: const BorderSide(color: Colors.grey),
                  ),
                  child: const Text(
                    "Close",
                    style: TextStyle(color: Colors.black87),
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
    return GestureDetector(
      // --- CLOSE KEYBOARD ON TAP OUTSIDE ---
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: bgColor,
        appBar: AppBar(
          title: Text(
            widget.productToEdit == null ? "Add New Product" : "Edit Product",
            style: GoogleFonts.orbitron(
              color: textColor,
              fontWeight: FontWeight.bold,
            ),
          ),
          backgroundColor: Colors.transparent,
          elevation: 0,

          actions: [
            IconButton(
              onPressed: _showHistoryDialog,
              icon: Icon(Icons.history, color: accentColor),
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
                                color: cardColor,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Colors.grey.shade300,
                                  style: BorderStyle.solid,
                                ),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.add_a_photo_outlined,
                                    size: 40,
                                    color: accentColor,
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    "Click to upload images",
                                    style: GoogleFonts.comicNeue(
                                      color: textColor,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  const SizedBox(height: 5),
                                  Text(
                                    "Max 3 images (JPEG, PNG only)",
                                    style: GoogleFonts.comicNeue(
                                      color: Colors.grey,
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
                                        border: Border.all(color: accentColor),
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
                                      style: TextStyle(color: textColor),
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
                                      style: TextStyle(color: textColor),
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
                                    style: TextStyle(color: textColor),
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
                                  ? accentColor
                                  : cardColor,
                              labelStyle: TextStyle(
                                color: warrantyCtrl.text == option
                                    ? Colors.white
                                    : Colors.black87,
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
                        _buildSectionTitle("Pricing"),
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
                            // STOCK REMOVED HERE
                            Expanded(
                              child: _buildTextField(
                                "Original Price (Optional)",
                                "Fake High Price",
                                originalPriceCtrl,
                                isNumber: true,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 15),
                        _buildTextField(
                          "Sale Price (Discounted)",
                          "Actual Price",
                          salePriceCtrl,
                          isNumber: true,
                        ),

                        const SizedBox(height: 20),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(15),
                          decoration: BoxDecoration(
                            color: accentColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: accentColor),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "Customer Points Reward:",
                                style: TextStyle(
                                  color: Colors.black87,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 5),
                              // DECIMALS CHECKBOX REMOVED - using globalShowDecimals in controller logic
                              Obx(() {
                                // Real-time calculation based on global setting
                                bool showDecimal =
                                    productController.globalShowDecimals.value;
                                return Text(
                                  showDecimal
                                      ? "${calculatedPoints.toStringAsFixed(1)} Pts"
                                      : "${calculatedPoints.toInt()} Pts",
                                  style: TextStyle(
                                    color: accentColor,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 20,
                                  ),
                                );
                              }),
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
                                      style: TextStyle(color: textColor),
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
                                              0, // DEFAULT 0 since field removed
                                          vendorId: selectedVendorId!,
                                          images: selectedImagesBase64,
                                          dateAdded: selectedDate,
                                          deliveryLocation:
                                              selectedLocation ?? 'Worldwide',
                                          warranty: warrantyCtrl.text.isEmpty
                                              ? "No Warranty"
                                              : warrantyCtrl.text,
                                          productPoints: calculatedPoints,
                                          // showDecimalPoints handled in controller based on global setting
                                          showDecimalPoints: true,
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
                                backgroundColor: accentColor,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 5,
                              ),
                              child: productController.isLoading.value
                                  ? const CircularProgressIndicator(
                                      color: Colors.white,
                                    )
                                  : Text(
                                      widget.productToEdit == null
                                          ? "SAVE PRODUCT"
                                          : "UPDATE PRODUCT",
                                      style: GoogleFonts.orbitron(
                                        color: Colors.white,
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
                      color: cardColor,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: accentColor, width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: accentColor.withOpacity(0.2),
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
                          color: Colors.green,
                          size: 60,
                        ),
                        const SizedBox(height: 20),
                        Text(
                          widget.productToEdit == null
                              ? "Product Saved!"
                              : "Product Updated!",
                          style: GoogleFonts.orbitron(
                            color: textColor,
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
                              icon: const Icon(Icons.add, color: Colors.white),
                              label: const Text(
                                "Add Another Product",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: accentColor,
                              ),
                            ),
                          ),
                        const SizedBox(height: 10),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: () {
                              setState(() {
                                _isSuccess = false;
                              });
                              Get.back(); // Go back to previous screen
                            },
                            icon: Icon(Icons.close, color: textColor),
                            label: Text(
                              "Close",
                              style: TextStyle(color: textColor),
                            ),
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(color: Colors.grey.shade400),
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
      ),
    );
  }

  // --- AUTOCOMPLETE WIDGET (Fixed for Light Theme) ---
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
            color: textColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Autocomplete<String>(
          initialValue: TextEditingValue(text: controller.text),
          optionsBuilder: (TextEditingValue textEditingValue) {
            final history = productController.searchHistoryList;
            if (textEditingValue.text.isEmpty) {
              return history.take(5);
            }
            final matches = productController.getSuggestions(
              textEditingValue.text,
            );
            return matches;
          },
          onSelected: (String selection) {
            controller.text = selection;
            onChanged(selection);
          },
          fieldViewBuilder:
              (context, fieldTextController, focusNode, onEditingComplete) {
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
                  style: TextStyle(color: textColor),
                  decoration: InputDecoration(
                    hintText: hint,
                    hintStyle: TextStyle(color: Colors.grey.shade400),
                    filled: true,
                    fillColor: cardColor,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: accentColor),
                    ),
                  ),
                  validator: (val) => val!.isEmpty ? "Required" : null,
                );
              },
          optionsViewBuilder: (context, onSelected, options) {
            return Align(
              alignment: Alignment.topLeft,
              child: Material(
                elevation: 4.0,
                color: Colors.white,
                child: SizedBox(
                  width: 300,
                  child: Obx(() {
                    final currentText = _currentName.toLowerCase();
                    final List<String> currentList = productController
                        .searchHistoryList
                        .where((s) => s.toLowerCase().contains(currentText))
                        .toList();
                    final displayList = currentText.isEmpty
                        ? productController.searchHistoryList.take(5).toList()
                        : productController.getSuggestions(_currentName);

                    if (displayList.isEmpty) return const SizedBox.shrink();

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
                            style: TextStyle(color: textColor),
                          ),
                          trailing: IconButton(
                            icon: const Icon(
                              Icons.close,
                              size: 16,
                              color: Colors.grey,
                            ),
                            onPressed: () =>
                                productController.removeHistoryItem(option),
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

  // --- EXISTING HELPERS (Updated for Light Theme) ---
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
            color: textColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<T>(
          value: value,
          dropdownColor: cardColor,
          style: TextStyle(color: textColor),
          decoration: InputDecoration(
            filled: true,
            fillColor: cardColor,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
          ),
          hint: Text(hint, style: TextStyle(color: Colors.grey.shade400)),
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
        const SizedBox(height: 5),
        Divider(color: Colors.grey.shade300),
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
            color: textColor,
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
          style: TextStyle(color: textColor),
          validator: (val) {
            if (label.contains("Optional")) return null;
            return val!.isEmpty ? "Required" : null;
          },
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey.shade400),
            filled: true,
            fillColor: cardColor,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: accentColor),
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
            if (picked != null) setState(() => selectedDate = picked);
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
                Icon(Icons.calendar_today, color: accentColor, size: 18),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
