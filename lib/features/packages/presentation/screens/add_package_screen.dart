import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:marvellous_admin/features/layout/presentation/screens/main_layout_screen.dart';

// Controllers & Models
import '../../../../features/products/controller/products_controller.dart';
import '../../../products/models/product_model.dart';
import '../../../vendors/controllers/vendor_controller.dart';
import '../../../dashboard/presentation/screens/dashboard_screen.dart';

class AddPackageScreen extends StatefulWidget {
  final ProductModel? packageToEdit;
  const AddPackageScreen({Key? key, this.packageToEdit}) : super(key: key);

  @override
  State<AddPackageScreen> createState() => _AddPackageScreenState();
}

class _AddPackageScreenState extends State<AddPackageScreen> {
  final ProductsController productController = Get.find<ProductsController>();
  final VendorController vendorController = Get.put(VendorController());

  final _formKey = GlobalKey<FormState>();
  final ImagePicker _picker = ImagePicker();

  // Controllers
  final TextEditingController nameCtrl = TextEditingController();
  final TextEditingController descCtrl = TextEditingController();
  final TextEditingController salePriceCtrl = TextEditingController();
  final TextEditingController originalPriceCtrl = TextEditingController();
  final TextEditingController stockCtrl = TextEditingController();

  // State
  List<String> selectedImagesBase64 = [];
  String? selectedVendorId;
  String? selectedLocation;

  // Package Specific State
  List<ProductModel> _selectedProducts = [];
  double _totalCalculatedPurchasePrice = 0.0;
  String _productSearchQuery = "";

  bool _isSuccess = false; // Popup State

  final List<String> locationOptions = [
    "Karachi Only",
    "Pakistan",
    "Worldwide",
    "Store Pickup Only",
  ];

  // Colors for Light Theme
  final Color bgColor = const Color(0xFFF5F7FA);
  final Color cardColor = Colors.white;
  final Color textColor = Colors.black87;
  final Color accentColor = Colors.deepPurple;
  final Color hintColor = Colors.grey;

  @override
  void initState() {
    super.initState();
    if (widget.packageToEdit != null) {
      _loadPackageData();
    } else {
      selectedLocation = locationOptions[1]; // Default Pakistan
    }
  }

  void _loadPackageData() {
    final pkg = widget.packageToEdit!;
    nameCtrl.text = pkg.name;
    descCtrl.text = pkg.description;
    salePriceCtrl.text = pkg.salePrice.toString();
    originalPriceCtrl.text = pkg.originalPrice == 0
        ? ""
        : pkg.originalPrice.toString();
    stockCtrl.text = pkg.stockQuantity.toString();

    selectedVendorId = pkg.vendorId;
    selectedLocation = pkg.deliveryLocation;
    selectedImagesBase64 = List.from(pkg.images);

    _selectedProducts = productController.productsOnly
        .where((p) => pkg.includedItemIds.contains(p.id))
        .toList();
    _recalculateTotals(updateImages: false);
  }

  void _recalculateTotals({bool updateImages = true}) {
    double total = 0;
    List<String> autoImages = [];

    // Calculate total and gather images from selected products
    for (var p in _selectedProducts) {
      total += p.purchasePrice;
      if (updateImages && p.images.isNotEmpty) {
        // Avoid duplicates
        if (!autoImages.contains(p.images.first)) {
          autoImages.add(p.images.first);
        }
      }
    }

    setState(() {
      _totalCalculatedPurchasePrice = total;
      if (updateImages) {
        // Keep existing manual images if you implemented separate logic,
        // but for now, we reset to selected products + we allow manual add below.
        // This makes sure if user removes a product, its image goes away.
        // Any manually added images (via picker) should be appended.
        // For simplicity: We stick to Auto Images from Selection + Manual Picker Append

        // Logic: Keep old images that are NOT from products?
        // Simple Fix: Just reset to auto images to keep it clean, user can add manual after.
        selectedImagesBase64 = autoImages;
      }
    });
  }

  void _toggleProductSelection(ProductModel product) {
    setState(() {
      if (_selectedProducts.contains(product)) {
        _selectedProducts.remove(product);
      } else {
        _selectedProducts.add(product);
      }
      _recalculateTotals();
    });
  }

  void _autoGenerateName() {
    if (_selectedProducts.isEmpty) return;
    String generatedName = _selectedProducts.map((p) => p.name).join(" + ");
    nameCtrl.text = "Combo: $generatedName";
  }

  // Manual Image Picker
  Future<void> _pickImages() async {
    final List<XFile> images = await _picker.pickMultiImage();
    if (images.isNotEmpty) {
      for (var img in images) {
        final bytes = await img.readAsBytes();
        setState(() => selectedImagesBase64.add(base64Encode(bytes)));
      }
    }
  }

  void _removeImage(int index) {
    setState(() {
      selectedImagesBase64.removeAt(index);
    });
  }

  void _clearForm() {
    nameCtrl.clear();
    descCtrl.clear();
    salePriceCtrl.clear();
    originalPriceCtrl.clear();
    stockCtrl.clear();
    setState(() {
      selectedImagesBase64.clear();
      _selectedProducts.clear();
      _totalCalculatedPurchasePrice = 0.0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: Text(
          widget.packageToEdit == null ? "Create Package" : "Edit Package",
          style: GoogleFonts.orbitron(
            color: textColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: bgColor,
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
                      // 1. SELECT PRODUCTS
                      Text(
                        "Step 1: Select Products",
                        style: GoogleFonts.orbitron(
                          color: accentColor,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),

                      Container(
                        height: 300,
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: cardColor,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 5,
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            TextField(
                              onChanged: (val) =>
                                  setState(() => _productSearchQuery = val),
                              style: TextStyle(color: textColor),
                              decoration: InputDecoration(
                                hintText: "Search items...",
                                hintStyle: TextStyle(color: hintColor),
                                prefixIcon: Icon(
                                  Icons.search,
                                  color: hintColor,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(
                                    color: Colors.grey.shade300,
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(
                                    color: Colors.grey.shade300,
                                  ),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 0,
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                            Expanded(
                              child: Obx(() {
                                var items = productController.productsOnly
                                    .where((p) {
                                      return p.name.toLowerCase().contains(
                                        _productSearchQuery.toLowerCase(),
                                      );
                                    })
                                    .toList();

                                return ListView.builder(
                                  itemCount: items.length,
                                  itemBuilder: (context, index) {
                                    final product = items[index];
                                    final isSelected = _selectedProducts
                                        .contains(product);
                                    return CheckboxListTile(
                                      title: Text(
                                        product.name,
                                        style: TextStyle(
                                          color: textColor,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      subtitle: Text(
                                        "Buy: PKR ${product.purchasePrice}",
                                        style: TextStyle(
                                          color: Colors.grey.shade600,
                                          fontSize: 12,
                                        ),
                                      ),
                                      value: isSelected,
                                      activeColor: accentColor,
                                      checkColor: Colors.white,
                                      onChanged: (val) =>
                                          _toggleProductSelection(product),
                                      secondary: Container(
                                        width: 40,
                                        height: 40,
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(
                                            5,
                                          ),
                                          image: product.images.isNotEmpty
                                              ? DecorationImage(
                                                  image: MemoryImage(
                                                    base64Decode(
                                                      product.images.first,
                                                    ),
                                                  ),
                                                  fit: BoxFit.cover,
                                                )
                                              : null,
                                          color: Colors.grey.shade200,
                                        ),
                                      ),
                                    );
                                  },
                                );
                              }),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        "Selected: ${_selectedProducts.length} items | Total Purchase Cost: PKR ${_totalCalculatedPurchasePrice.toInt()}",
                        style: TextStyle(
                          color: Colors.green.shade700,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 30),

                      // 2. PACKAGE DETAILS
                      Text(
                        "Step 2: Details",
                        style: GoogleFonts.orbitron(
                          color: accentColor,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 15),

                      // Images Area (Auto + Manual Add)
                      SizedBox(
                        height: 100,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          children: [
                            // 1. Add Image Button
                            GestureDetector(
                              onTap: _pickImages,
                              child: Container(
                                width: 100,
                                margin: const EdgeInsets.only(right: 10),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: accentColor.withOpacity(0.5),
                                    style: BorderStyle.solid,
                                  ),
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.add_a_photo, color: accentColor),
                                    const SizedBox(height: 5),
                                    Text(
                                      "Add",
                                      style: TextStyle(
                                        color: accentColor,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            // 2. Image List
                            ...selectedImagesBase64.asMap().entries.map((
                              entry,
                            ) {
                              int idx = entry.key;
                              String b64 = entry.value;
                              return Stack(
                                children: [
                                  Container(
                                    margin: const EdgeInsets.only(right: 10),
                                    width: 100,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                        color: Colors.grey.shade300,
                                      ),
                                      image: DecorationImage(
                                        image: MemoryImage(base64Decode(b64)),
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    top: 5,
                                    right: 15,
                                    child: InkWell(
                                      onTap: () => _removeImage(idx),
                                      child: Container(
                                        padding: const EdgeInsets.all(2),
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
                            }).toList(),
                          ],
                        ),
                      ),

                      const SizedBox(height: 15),

                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: nameCtrl,
                              style: TextStyle(color: textColor),
                              decoration: _inputDeco("Package Name"),
                              validator: (v) => v!.isEmpty ? "Required" : null,
                            ),
                          ),
                          IconButton(
                            onPressed: _autoGenerateName,
                            icon: Icon(Icons.auto_fix_high, color: accentColor),
                            tooltip: "Auto-Name",
                          ),
                        ],
                      ),
                      const SizedBox(height: 15),

                      TextFormField(
                        controller: descCtrl,
                        style: TextStyle(color: textColor),
                        maxLines: 3,
                        decoration: _inputDeco("Description"),
                      ),
                      const SizedBox(height: 15),

                      // Vendor & Location
                      Row(
                        children: [
                          Expanded(
                            child: Obx(() {
                              var vends = vendorController.vendors;
                              return DropdownButtonFormField<String>(
                                value:
                                    selectedVendorId ??
                                    (vends.isNotEmpty ? vends.first.id : null),
                                dropdownColor: cardColor,
                                style: TextStyle(color: textColor),
                                iconEnabledColor:
                                    Colors.black54, // Icon Visible
                                decoration: _inputDeco("Vendor"),
                                items: vends
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
                                onChanged: (v) =>
                                    setState(() => selectedVendorId = v),
                                validator: (v) => v == null ? "Required" : null,
                                isExpanded: true,
                              );
                            }),
                          ),
                          const SizedBox(width: 15),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: selectedLocation,
                              dropdownColor: cardColor,
                              style: TextStyle(color: textColor),
                              iconEnabledColor: Colors.black54, // Icon Visible
                              decoration: _inputDeco("Location"),
                              items: locationOptions
                                  .map(
                                    (l) => DropdownMenuItem(
                                      value: l,
                                      child: Text(
                                        l,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(color: textColor),
                                      ),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (v) =>
                                  setState(() => selectedLocation = v),
                              isExpanded: true,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 30),

                      // 3. PRICING
                      Text(
                        "Step 3: Pricing",
                        style: GoogleFonts.orbitron(
                          color: accentColor,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 15),

                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: originalPriceCtrl,
                              keyboardType: TextInputType.number,
                              style: TextStyle(color: textColor),
                              decoration: _inputDeco("Fake Price (Optional)"),
                            ),
                          ),
                          const SizedBox(width: 15),
                          Expanded(
                            child: TextFormField(
                              controller: salePriceCtrl,
                              keyboardType: TextInputType.number,
                              style: TextStyle(color: textColor),
                              decoration: _inputDeco("Sale Price"),
                              validator: (v) => v!.isEmpty ? "Required" : null,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 15),
                      TextFormField(
                        controller: stockCtrl,
                        keyboardType: TextInputType.number,
                        style: TextStyle(color: textColor),
                        decoration: _inputDeco("Stock Qty (Optional)"),
                      ),

                      const SizedBox(height: 40),

                      // SAVE BUTTON with Loading
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: Obx(
                          () => ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: accentColor,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            onPressed: productController.isLoading.value
                                ? null
                                : () async {
                                    if (_formKey.currentState!.validate()) {
                                      // Validation Logic
                                      if (_selectedProducts.isEmpty) {
                                        Get.snackbar(
                                          "Error",
                                          "Select products first",
                                          backgroundColor: Colors.red,
                                          colorText: Colors.white,
                                        );
                                        return;
                                      }
                                      if (selectedVendorId == null) {
                                        Get.snackbar(
                                          "Required",
                                          "Please select a Vendor",
                                          backgroundColor: Colors.red,
                                          colorText: Colors.white,
                                        );
                                        return;
                                      }

                                      // Data Preparation
                                      double buy =
                                          _totalCalculatedPurchasePrice;
                                      double sell =
                                          double.tryParse(salePriceCtrl.text) ??
                                          0;
                                      double points = productController
                                          .calculatePoints(buy, sell);

                                      int stock = 0;
                                      if (stockCtrl.text.isNotEmpty) {
                                        stock =
                                            int.tryParse(stockCtrl.text) ?? 0;
                                      }

                                      ProductModel newPackage = ProductModel(
                                        id: widget.packageToEdit?.id,
                                        name: nameCtrl.text,
                                        modelNumber:
                                            "PKG-${DateTime.now().millisecondsSinceEpoch}",
                                        description: descCtrl.text,
                                        category: "Bundle",
                                        subCategory: "Bundle",
                                        brand: "Package",
                                        purchasePrice:
                                            _totalCalculatedPurchasePrice,
                                        salePrice: sell,
                                        originalPrice:
                                            double.tryParse(
                                              originalPriceCtrl.text,
                                            ) ??
                                            0,
                                        stockQuantity: stock,
                                        vendorId:
                                            selectedVendorId!, // Force unwrap only after check
                                        images: selectedImagesBase64,
                                        dateAdded: DateTime.now(),
                                        deliveryLocation:
                                            selectedLocation ?? 'Worldwide',
                                        warranty: "See Items",
                                        productPoints: points,
                                        isPackage: true,
                                        includedItemIds: _selectedProducts
                                            .map((p) => p.id!)
                                            .toList(),
                                        showDecimalPoints: true,
                                      );

                                      // Save Operation
                                      bool success;
                                      if (widget.packageToEdit == null) {
                                        success = await productController
                                            .addNewProduct(newPackage);
                                        if (success) _clearForm();
                                      } else {
                                        success = await productController
                                            .updateProduct(newPackage);
                                      }

                                      if (success) {
                                        setState(() {
                                          _isSuccess = true;
                                        });
                                      }
                                    }
                                  },
                            child: productController.isLoading.value
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : Text(
                                    "SAVE PACKAGE",
                                    style: GoogleFonts.orbitron(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
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

          // POPUP OVERLAY
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
                    boxShadow: [
                      BoxShadow(color: Colors.black12, blurRadius: 20),
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
                        widget.packageToEdit == null
                            ? "Package Created!"
                            : "Package Updated!",
                        style: GoogleFonts.orbitron(
                          color: textColor,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 30),

                      if (widget.packageToEdit == null)
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () => setState(() => _isSuccess = false),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: accentColor,
                            ),
                            child: const Text(
                              "Create New Package",
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                        ),
                      const SizedBox(height: 10),

                      // Close -> Go to Dashboard
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: () {
                            Get.offAll(() => MainLayoutScreen());
                          },
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: Colors.grey.shade300),
                          ),
                          child: Text(
                            "Close",
                            style: TextStyle(color: textColor),
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

  InputDecoration _inputDeco(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: Colors.grey.shade600),
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Colors.deepPurple),
      ),
    );
  }
}
