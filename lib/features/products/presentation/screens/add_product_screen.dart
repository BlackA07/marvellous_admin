import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:intl/intl.dart';

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

  String _currentName = ""; // Fixed: Variable defined

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

  // Colors
  final Color bgColor = const Color(0xFFF5F7FA);
  final Color cardColor = Colors.white;
  final Color textColor = Colors.black; // FIXED: Black text
  final Color accentColor = Colors.deepPurple;

  @override
  void initState() {
    super.initState();
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
    warrantyCtrl.text = product.warranty;
    ramCtrl.text = product.ram ?? "";
    storageCtrl.text = product.storage ?? "";
    selectedCategory = product.category;
    selectedSubCategory = product.subCategory;
    selectedLocation = product.deliveryLocation;
    selectedImagesBase64 = List.from(product.images);
    selectedDate = product.dateAdded;
    calculatedPoints = product.productPoints;
  }

  // --- FIXED IMAGE PICKER (Resolves _namespace error) ---
  Future<void> _handleImagePicker() async {
    if (selectedImagesBase64.length >= 3) {
      Get.snackbar("Limit Reached", "Max 3 images allowed.");
      return;
    }

    // Check if Web strictly first to avoid dart:io errors
    if (kIsWeb) {
      _pickImages(ImageSource.gallery);
      return;
    }

    // Now safe to check Platform for Desktop
    if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
      _pickImages(ImageSource.gallery);
    } else {
      // Mobile
      showModalBottomSheet(
        context: context,
        backgroundColor: Colors.white,
        builder: (ctx) => Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt, color: Colors.deepPurple),
              title: const Text(
                "Camera",
                style: TextStyle(color: Colors.black),
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
                style: TextStyle(color: Colors.black),
              ),
              onTap: () {
                Navigator.pop(ctx);
                _pickImages(ImageSource.gallery);
              },
            ),
          ],
        ),
      );
    }
  }

  Future<void> _pickImages(ImageSource source) async {
    try {
      final List<XFile> pickedFiles;
      // Multi pick only for gallery
      if (source == ImageSource.gallery) {
        pickedFiles = await _picker.pickMultiImage();
      } else {
        final XFile? img = await _picker.pickImage(source: source);
        pickedFiles = img != null ? [img] : [];
      }

      if (pickedFiles.isEmpty) return;

      for (var file in pickedFiles) {
        if (selectedImagesBase64.length >= 3) break;

        // Skip Crop on Web to avoid CORS/Path issues, or if user prefers speed
        if (kIsWeb) {
          final bytes = await file.readAsBytes();
          setState(() => selectedImagesBase64.add(base64Encode(bytes)));
          continue;
        }

        // Mobile/Desktop Crop
        CroppedFile? croppedFile = await ImageCropper().cropImage(
          sourcePath: file.path,
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
          final bytes = await croppedFile.readAsBytes();
          setState(() {
            selectedImagesBase64.add(base64Encode(bytes));
          });
        }
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
    });
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

      ProductModel newProduct = ProductModel(
        id: widget.productToEdit?.id,
        name: nameCtrl.text,
        modelNumber: modelCtrl.text,
        description: descCtrl.text,
        category: selectedCategory!,
        subCategory: selectedSubCategory ?? "General",
        brand: brandCtrl.text.isEmpty ? "Generic" : brandCtrl.text,
        purchasePrice: double.tryParse(purchaseCtrl.text) ?? 0,
        salePrice: double.tryParse(saleCtrl.text) ?? 0,
        originalPrice: double.tryParse(originalCtrl.text) ?? 0,
        stockQuantity: 0,
        vendorId: "Admin",
        images: selectedImagesBase64,
        dateAdded: selectedDate,
        deliveryLocation: selectedLocation,
        warranty: warrantyCtrl.text.isEmpty ? "No Warranty" : warrantyCtrl.text,
        productPoints: calculatedPoints,
        showDecimalPoints: true,
        ram: _isMobile ? ramCtrl.text : null,
        storage: _isMobile ? storageCtrl.text : null,
      );

      bool success;
      if (widget.productToEdit == null) {
        success = await productController.addNewProduct(newProduct);
      } else {
        success = await productController.updateProduct(newProduct);
      }

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
                      children: [
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
                          categoryController: categoryController,
                          selectedCategory: selectedCategory,
                          selectedSubCategory: selectedSubCategory,
                          selectedLocation: selectedLocation,
                          cardColor: cardColor,
                          textColor: textColor,
                          onCategoryChanged: (val) {
                            setState(() {
                              selectedCategory = val;
                              selectedSubCategory = null;
                            });
                          },
                          onSubCategoryChanged: (val) =>
                              setState(() => selectedSubCategory = val),
                          onLocationChanged: (val) =>
                              setState(() => selectedLocation = val!),
                        ),
                        const SizedBox(height: 30),

                        AddProductPricing(
                          purchaseCtrl: purchaseCtrl,
                          saleCtrl: saleCtrl,
                          originalCtrl: originalCtrl,
                          warrantyCtrl: warrantyCtrl,
                          calculatedPoints: calculatedPoints,
                          showDecimals:
                              productController.globalShowDecimals.value,
                          cardColor: cardColor,
                          textColor: textColor,
                          accentColor: accentColor,
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
                onPressed: () {
                  // FIX: Go to Dashboard (Root)
                  Get.until((route) => route.isFirst);
                },
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
                onPressed: () {
                  // FIX: Close Overlay AND Screen -> Back to All Products
                  Get.close(2);
                },
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
