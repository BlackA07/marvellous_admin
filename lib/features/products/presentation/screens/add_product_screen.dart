import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:intl/intl.dart';
import 'package:marvellous_admin/features/layout/presentation/screens/main_layout_screen.dart';

// Controllers & Models
import '../../../../features/categories/controllers/category_controller.dart';
import '../../controller/products_controller.dart';
import '../../models/product_model.dart';
import '../../../categories/models/category_model.dart';

// Child Widgets
import '../widgets/add_product_media.dart';
import '../widgets/add_product_info.dart';
import '../widgets/add_product_logistics.dart';
import '../widgets/add_product_pricing.dart';

// SCREEN IMPORT
import 'products_home_screen.dart';

class AddProductScreen extends StatefulWidget {
  final ProductModel? productToEdit;

  const AddProductScreen({Key? key, this.productToEdit}) : super(key: key);

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final ProductsController productController = Get.put(ProductsController());
  final CategoryController categoryController = Get.put(CategoryController());

  final ScrollController _scrollController = ScrollController();
  final _formKey = GlobalKey<FormState>();
  final ImagePicker _picker = ImagePicker();

  String _currentName = "";

  // ✅ Vendor Info & List
  String _vendorId = "Admin";
  String _vendorName = "Admin";
  String _productStatus = "approved";

  List<Map<String, dynamic>> vendorsList = [
    {'id': 'Admin', 'name': 'Admin'},
  ];

  // Controllers
  final TextEditingController nameCtrl = TextEditingController();
  final TextEditingController modelCtrl = TextEditingController();
  final TextEditingController descCtrl = TextEditingController();
  final TextEditingController brandCtrl = TextEditingController();
  final TextEditingController ramCtrl = TextEditingController();
  final TextEditingController storageCtrl = TextEditingController();
  final TextEditingController purchaseCtrl = TextEditingController();
  final TextEditingController saleCtrl = TextEditingController();
  final TextEditingController originalCtrl = TextEditingController();
  final TextEditingController warrantyCtrl = TextEditingController();

  // State
  DateTime selectedDate = DateTime.now();
  String? selectedCategory;
  String? selectedSubCategory;
  String selectedLocation = "Pakistan";
  List<String> selectedImagesBase64 = [];
  double calculatedPoints = 0.0;
  bool _isSuccess = false;
  bool _isMobile = false;

  // ✅ Key to reset Logistics controllers when form is cleared
  Key logisticsKey = UniqueKey();

  // Warranty Checkboxes State
  bool hasCompanyWarranty = false;
  bool hasShopWarranty = false;

  // Logistics State
  Map<String, double> deliveryFeesMap = {
    "Karachi": 0,
    "Pakistan": 0,
    "Worldwide": 0,
  };
  Map<String, String> deliveryTimeMap = {
    "Karachi": "1-2 Days",
    "Pakistan": "3-5 Days",
    "Worldwide": "7-15 Days",
  };
  double codFee = 0.0;

  // Colors
  final Color bgColor = const Color(0xFFF5F7FA);
  final Color cardColor = Colors.white;
  final Color textColor = Colors.black;
  final Color accentColor = Colors.deepPurple;

  @override
  void initState() {
    super.initState();
    _fetchVendors(); // ✅ Fetch Vendors on init
    if (widget.productToEdit != null) {
      _loadProductData(widget.productToEdit!);
    }

    purchaseCtrl.addListener(_calculatePoints);
    saleCtrl.addListener(_calculatePoints);
    nameCtrl.addListener(() {
      _currentName = nameCtrl.text;
      _checkIfMobile(nameCtrl.text);
    });
  }

  @override
  void dispose() {
    nameCtrl.dispose();
    modelCtrl.dispose();
    descCtrl.dispose();
    brandCtrl.dispose();
    ramCtrl.dispose();
    storageCtrl.dispose();
    purchaseCtrl.dispose();
    saleCtrl.dispose();
    originalCtrl.dispose();
    warrantyCtrl.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // ✅ Fetch all vendors for the dropdown
  Future<void> _fetchVendors() async {
    try {
      var snap = await FirebaseFirestore.instance.collection('vendors').get();
      List<Map<String, dynamic>> fetchedVendors = [];
      for (var doc in snap.docs) {
        fetchedVendors.add({
          'id': doc.id,
          'name':
              doc.data()['storeName'] ??
              doc.data()['ownerName'] ??
              'Unknown Vendor',
        });
      }
      if (mounted) {
        setState(() {
          vendorsList.addAll(fetchedVendors);
        });
      }
    } catch (e) {
      debugPrint("Error fetching vendors: $e");
    }
  }

  void _checkIfMobile(String val) {
    bool isMob = val.toLowerCase().contains("mobile");
    if (isMob != _isMobile) setState(() => _isMobile = isMob);
  }

  void _calculatePoints() {
    double buy = double.tryParse(purchaseCtrl.text) ?? 0;
    double sell = double.tryParse(saleCtrl.text) ?? 0;
    setState(() {
      calculatedPoints = productController.calculatePoints(buy, sell);
    });
  }

  void _loadProductData(ProductModel product) {
    nameCtrl.text = product.name;
    _currentName = product.name;
    _checkIfMobile(product.name);
    modelCtrl.text = product.modelNumber;
    descCtrl.text = product.description;
    brandCtrl.text = product.brand;
    purchaseCtrl.text = product.purchasePrice.toString();
    saleCtrl.text = product.salePrice.toString();
    originalCtrl.text = product.originalPrice == 0.0
        ? ""
        : product.originalPrice.toString();

    // Handle Vendor Info & Status
    _vendorId = product.vendorId;
    _vendorName = product.vendorName;
    _productStatus = product.status;

    // Warranty Logic
    String w = product.warranty;
    hasCompanyWarranty = w.contains("Company");
    hasShopWarranty = w.contains("Shop");
    warrantyCtrl.text = w
        .replaceAll(RegExp(r'\s*\(.*?Warranty\)\s*'), '')
        .trim();
    if (warrantyCtrl.text == "") warrantyCtrl.text = "No Warranty";

    ramCtrl.text = product.ram ?? "";
    storageCtrl.text = product.storage ?? "";
    selectedCategory = product.category;

    if (product.subCategory == "General" || product.subCategory == "") {
      selectedSubCategory = null;
    } else {
      selectedSubCategory = product.subCategory;
    }

    List<String> validLocations = ["Karachi Only", "Pakistan", "Worldwide"];
    if (validLocations.contains(product.deliveryLocation)) {
      selectedLocation = product.deliveryLocation;
    } else {
      selectedLocation = "Pakistan";
    }

    selectedImagesBase64 = List.from(product.images);
    selectedDate = product.dateAdded;
    calculatedPoints = product.productPoints;

    deliveryFeesMap = {
      "Karachi": product.deliveryFeesMap["Karachi"] ?? 0.0,
      "Pakistan": product.deliveryFeesMap["Pakistan"] ?? 0.0,
      "Worldwide": product.deliveryFeesMap["Worldwide"] ?? 0.0,
    };
    deliveryTimeMap = {
      "Karachi": product.deliveryTimeMap["Karachi"] ?? "1-2 Days",
      "Pakistan": product.deliveryTimeMap["Pakistan"] ?? "3-5 Days",
      "Worldwide": product.deliveryTimeMap["Worldwide"] ?? "7-15 Days",
    };
    codFee = product.codFee;
  }

  Future<void> _handleImagePicker() async {
    if (selectedImagesBase64.length >= 3) {
      Get.snackbar("Limit Reached", "Max 3 images allowed.");
      return;
    }

    if (kIsWeb) {
      _pickImages(ImageSource.gallery);
      return;
    }

    if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
      _pickImages(ImageSource.gallery);
    } else {
      showModalBottomSheet(
        context: context,
        backgroundColor: Colors.white,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (ctx) => SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt, color: Colors.deepPurple),
                title: const Text(
                  "Camera",
                  style: TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickImages(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.image, color: Colors.deepPurple),
                title: const Text(
                  "Gallery",
                  style: TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickImages(ImageSource.gallery);
                },
              ),
            ],
          ),
        ),
      );
    }
  }

  Future<void> _pickImages(ImageSource source) async {
    try {
      if (selectedImagesBase64.length >= 3) return;

      final XFile? file = await _picker.pickImage(source: source);
      if (file == null) return;

      if (kIsWeb) {
        final bytes = await file.readAsBytes();
        setState(() => selectedImagesBase64.add(base64Encode(bytes)));
        return;
      }

      CroppedFile? croppedFile = await ImageCropper().cropImage(
        sourcePath: file.path,
        aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1), // Square crop
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Crop Image',
            toolbarColor: accentColor,
            toolbarWidgetColor: Colors.white,
            initAspectRatio: CropAspectRatioPreset.square,
            lockAspectRatio: false,
          ),
          IOSUiSettings(title: 'Crop Image'),
        ],
      );

      if (croppedFile != null) {
        final bytes = await File(croppedFile.path).readAsBytes();
        setState(() {
          selectedImagesBase64.add(base64Encode(bytes));
        });
      }
    } catch (e) {
      Get.snackbar(
        "Error",
        "Image pick failed: $e",
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  void _clearForm() {
    nameCtrl.clear();
    modelCtrl.clear();
    descCtrl.clear();
    brandCtrl.clear();
    purchaseCtrl.clear();
    saleCtrl.clear();
    originalCtrl.clear();
    warrantyCtrl.clear();
    ramCtrl.clear();
    storageCtrl.clear();
    setState(() {
      selectedImagesBase64.clear();
      selectedSubCategory = null;
      calculatedPoints = 0.0;
      _isMobile = false;
      hasCompanyWarranty = false;
      hasShopWarranty = false;
      _vendorId = "Admin";
      _vendorName = "Admin";
      _productStatus = "approved";

      deliveryFeesMap = {"Karachi": 0, "Pakistan": 0, "Worldwide": 0};
      deliveryTimeMap = {
        "Karachi": "1-2 Days",
        "Pakistan": "3-5 Days",
        "Worldwide": "7-15 Days",
      };
      codFee = 0.0;
      logisticsKey =
          UniqueKey(); // ✅ Completely resets logistics controllers on clear
    });
  }

  String _getCombinedWarranty() {
    String duration = warrantyCtrl.text.trim();
    if (duration == "") duration = "No Warranty";

    List<String> types = [];
    if (hasCompanyWarranty) types.add("Company");
    if (hasShopWarranty) types.add("Shop");

    if (types.isEmpty) return duration;
    return "$duration (${types.join(' & ')} Warranty)";
  }

  void _saveProduct() async {
    if (_formKey.currentState!.validate()) {
      if (selectedCategory == null) {
        Get.snackbar(
          "Required",
          "Please select a Category",
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        return;
      }

      productController.isLoading.value = true;

      ProductModel newProduct = ProductModel(
        id: widget.productToEdit?.id,
        name: nameCtrl.text,
        modelNumber: modelCtrl.text,
        description: descCtrl.text,
        category: selectedCategory!,
        subCategory: selectedSubCategory ?? "General",
        brand: brandCtrl.text == "" ? "Generic" : brandCtrl.text,
        purchasePrice: double.tryParse(purchaseCtrl.text) ?? 0,
        salePrice: double.tryParse(saleCtrl.text) ?? 0,
        originalPrice: double.tryParse(originalCtrl.text) ?? 0,
        stockQuantity: widget.productToEdit?.stockQuantity ?? 0,
        vendorId: _vendorId,
        vendorName: _vendorName,
        status: _productStatus,
        images: selectedImagesBase64,
        dateAdded: selectedDate,
        deliveryLocation: selectedLocation,
        warranty: _getCombinedWarranty(),
        productPoints: calculatedPoints,
        showDecimalPoints: true,
        ram: _isMobile ? ramCtrl.text : null,
        storage: _isMobile ? storageCtrl.text : null,
        deliveryFeesMap: deliveryFeesMap,
        deliveryTimeMap: deliveryTimeMap,
        codFee: codFee,
        averageRating: widget.productToEdit?.averageRating ?? 0.0,
        totalReviews: widget.productToEdit?.totalReviews ?? 0,
      );

      bool success;
      if (widget.productToEdit == null) {
        success = await productController.addNewProduct(newProduct);
      } else {
        success = await productController.updateProduct(newProduct);
      }

      productController.isLoading.value = false;

      if (success) {
        setState(() => _isSuccess = true);
      }
    } else {
      Get.snackbar(
        "Required Fields",
        "Please fill all red fields.",
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: bgColor,
        appBar: AppBar(
          title: Text(
            widget.productToEdit == null ? "Add Product" : "Edit Product",
            style: GoogleFonts.orbitron(
              color: textColor,
              fontWeight: FontWeight.bold,
            ),
          ),
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: textColor),
            onPressed: () => Get.back(),
          ),
        ),
        body: Stack(
          children: [
            Opacity(
              opacity: _isSuccess ? 0.1 : 1.0,
              child: AbsorbPointer(
                absorbing: _isSuccess,
                child: SingleChildScrollView(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(20),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ✅ NEW: Vendor Selection Dropdown
                        Container(
                          margin: const EdgeInsets.only(bottom: 20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Select Vendor",
                                style: GoogleFonts.orbitron(
                                  color: textColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 10),
                              DropdownButtonFormField<String>(
                                value:
                                    vendorsList.any((v) => v['id'] == _vendorId)
                                    ? _vendorId
                                    : null,
                                style: const TextStyle(
                                  color: Colors.black,
                                  fontSize: 14,
                                ),
                                dropdownColor: Colors.white,
                                decoration: InputDecoration(
                                  filled: true,
                                  fillColor: cardColor,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                items: vendorsList.map((vendor) {
                                  return DropdownMenuItem<String>(
                                    value: vendor['id'],
                                    child: Text(
                                      vendor['name'],
                                      style: const TextStyle(
                                        color: Colors.black,
                                      ),
                                    ),
                                  );
                                }).toList(),
                                onChanged: (val) {
                                  setState(() {
                                    _vendorId = val!;
                                    _vendorName = vendorsList.firstWhere(
                                      (v) => v['id'] == val,
                                    )['name'];
                                  });
                                },
                              ),
                            ],
                          ),
                        ),

                        AddProductMedia(
                          images: selectedImagesBase64,
                          onPickImages: _handleImagePicker,
                          onRemoveImage: (index) => setState(
                            () => selectedImagesBase64.removeAt(index),
                          ),
                          cardColor: cardColor,
                          accentColor: accentColor,
                          textColor: textColor,
                        ),
                        const SizedBox(height: 30),

                        AddProductInfo(
                          nameCtrl: nameCtrl,
                          brandCtrl: brandCtrl,
                          modelCtrl: modelCtrl,
                          descCtrl: descCtrl,
                          ramCtrl: ramCtrl,
                          storageCtrl: storageCtrl,
                          isMobile: _isMobile,
                          selectedDate: selectedDate,
                          onDateChanged: (d) =>
                              setState(() => selectedDate = d),
                          cardColor: cardColor,
                          textColor: textColor,
                          accentColor: accentColor,
                          productHistory:
                              productController.productNameHistoryList,
                          brandHistory: productController.brandHistoryList,
                          onNameChanged: (val) {
                            setState(() {
                              _currentName = val;
                              _checkIfMobile(val);
                            });
                          },
                        ),
                        const SizedBox(height: 30),

                        AddProductLogistics(
                          key:
                              logisticsKey, // ✅ Key added to handle cursor resets gracefully
                          categoryController: categoryController,
                          selectedCategory: selectedCategory,
                          selectedSubCategory: selectedSubCategory,
                          selectedLocation: selectedLocation,
                          cardColor: cardColor,
                          textColor: textColor,
                          initialDeliveryFees: deliveryFeesMap,
                          initialDeliveryTimes: deliveryTimeMap,
                          initialCodFee: codFee,
                          onCategoryChanged: (val) {
                            setState(() {
                              selectedCategory = val;
                              selectedSubCategory = null;
                            });
                          },
                          onSubCategoryChanged: (val) =>
                              setState(() => selectedSubCategory = val),
                          onLocationChanged: (val) =>
                              setState(() => selectedLocation = val),
                          onDetailsChanged: (fees, times, cod) {
                            setState(() {
                              deliveryFeesMap = fees;
                              deliveryTimeMap = times;
                              codFee = cod;
                            });
                          },
                        ),
                        const SizedBox(height: 30),

                        AddProductPricing(
                          purchaseCtrl: purchaseCtrl,
                          saleCtrl: saleCtrl,
                          originalCtrl: originalCtrl,
                          warrantyCtrl: warrantyCtrl,
                          cardColor: cardColor,
                          textColor: textColor,
                          accentColor: accentColor,
                        ),

                        Container(
                          margin: const EdgeInsets.only(top: 10),
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: cardColor,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Warranty Type (Optional)",
                                style: GoogleFonts.comicNeue(
                                  color: textColor,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              CheckboxListTile(
                                title: const Text("Company Warranty"),
                                value: hasCompanyWarranty == true,
                                activeColor: accentColor,
                                controlAffinity:
                                    ListTileControlAffinity.leading,
                                contentPadding: EdgeInsets.zero,
                                onChanged: (val) => setState(
                                  () => hasCompanyWarranty = val ?? false,
                                ),
                              ),
                              CheckboxListTile(
                                title: const Text("Shop Warranty"),
                                value: hasShopWarranty == true,
                                activeColor: accentColor,
                                controlAffinity:
                                    ListTileControlAffinity.leading,
                                contentPadding: EdgeInsets.zero,
                                onChanged: (val) => setState(
                                  () => hasShopWarranty = val ?? false,
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 40),

                        // SAVE BUTTON
                        SizedBox(
                          width: double.infinity,
                          height: 55,
                          child: Obx(
                            () => ElevatedButton(
                              onPressed: productController.isLoading.value
                                  ? null
                                  : _saveProduct,
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
                                      "SAVE PRODUCT",
                                      style: GoogleFonts.orbitron(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
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
            if (_isSuccess) _buildSuccessOverlay(),
          ],
        ),
      ),
    );
  }

  Widget _buildSuccessOverlay() {
    return Container(
      color: Colors.black54,
      child: Center(
        child: Container(
          width: 320,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: accentColor, width: 2),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.check_circle, color: Colors.green, size: 60),
              const SizedBox(height: 20),
              Text(
                "Success!",
                style: GoogleFonts.orbitron(
                  color: Colors.black,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 30),
              if (widget.productToEdit == null)
                ElevatedButton.icon(
                  onPressed: () {
                    _clearForm();
                    setState(() => _isSuccess = false);
                    _scrollController.animateTo(
                      0,
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOut,
                    );
                  },
                  icon: const Icon(Icons.add, color: Colors.white),
                  label: const Text(
                    "Add Another",
                    style: TextStyle(color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accentColor,
                    minimumSize: const Size.fromHeight(45),
                  ),
                ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: () => Get.offAll(() => MainLayoutScreen()),
                icon: const Icon(Icons.dashboard, color: Colors.blue),
                label: const Text(
                  "Go to Dashboard",
                  style: TextStyle(color: Colors.blue),
                ),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(45),
                ),
              ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: () => Get.off(() => const ProductsHomeScreen()),
                icon: const Icon(Icons.list, color: Colors.black),
                label: const Text(
                  "All Products",
                  style: TextStyle(color: Colors.black),
                ),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(45),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
