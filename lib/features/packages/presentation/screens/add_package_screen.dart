import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:marvellous_admin/features/products/controller/products_controller.dart';

// Controllers & Models
import '../../../products/models/product_model.dart';
import '../../../categories/controllers/category_controller.dart';
import '../../../vendors/controllers/vendor_controller.dart';
import 'packages_home_screen.dart';

class AddPackageScreen extends StatefulWidget {
  final ProductModel? packageToEdit;
  const AddPackageScreen({Key? key, this.packageToEdit}) : super(key: key);

  @override
  State<AddPackageScreen> createState() => _AddPackageScreenState();
}

class _AddPackageScreenState extends State<AddPackageScreen> {
  final ProductsController productController = Get.find<ProductsController>();
  final CategoryController categoryController = Get.put(CategoryController());
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
  String? selectedCategory;
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

  @override
  void initState() {
    super.initState();
    if (widget.packageToEdit != null) {
      _loadPackageData();
    } else {
      selectedLocation = locationOptions[1];
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

    selectedCategory = pkg.category;
    selectedVendorId = pkg.vendorId;
    selectedLocation = pkg.deliveryLocation;
    selectedImagesBase64 = List.from(pkg.images);

    _selectedProducts = productController.productsOnly
        .where((p) => pkg.includedItemIds.contains(p.id))
        .toList();
    _recalculateTotals();
  }

  void _recalculateTotals() {
    double total = 0;
    for (var p in _selectedProducts) {
      total += p.purchasePrice;
    }
    setState(() {
      _totalCalculatedPurchasePrice = total;
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

  Future<void> _pickImages() async {
    final List<XFile> images = await _picker.pickMultiImage();
    if (images.isNotEmpty) {
      for (var img in images) {
        final bytes = await img.readAsBytes();
        setState(() => selectedImagesBase64.add(base64Encode(bytes)));
      }
    }
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
      backgroundColor: const Color(0xFF1E1E2C),
      appBar: AppBar(
        title: Text(
          widget.packageToEdit == null ? "Create Package" : "Edit Package",
          style: GoogleFonts.orbitron(color: Colors.white),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
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
                          color: Colors.cyanAccent,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),

                      // FIXED CONTAINER FOR LIST (No Expanded here inside ScrollView)
                      Container(
                        height: 300,
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2A2D3E),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white24),
                        ),
                        child: Column(
                          children: [
                            TextField(
                              onChanged: (val) =>
                                  setState(() => _productSearchQuery = val),
                              style: const TextStyle(color: Colors.white),
                              decoration: InputDecoration(
                                hintText: "Search items...",
                                hintStyle: const TextStyle(
                                  color: Colors.white24,
                                ),
                                prefixIcon: const Icon(
                                  Icons.search,
                                  color: Colors.white54,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 0,
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                            Expanded(
                              // This Expanded is OK because it's inside Container with fixed height
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
                                        style: const TextStyle(
                                          color: Colors.white,
                                        ),
                                      ),
                                      subtitle: Text(
                                        "Buy: PKR ${product.purchasePrice}",
                                        style: const TextStyle(
                                          color: Colors.white54,
                                          fontSize: 12,
                                        ),
                                      ),
                                      value: isSelected,
                                      activeColor: Colors.purpleAccent,
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
                                          color: Colors.grey[800],
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
                        "Selected: ${_selectedProducts.length} | Cost: PKR ${_totalCalculatedPurchasePrice.toInt()}",
                        style: const TextStyle(color: Colors.greenAccent),
                      ),

                      const SizedBox(height: 30),

                      // 2. PACKAGE DETAILS
                      Text(
                        "Step 2: Details",
                        style: GoogleFonts.orbitron(
                          color: Colors.cyanAccent,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 15),

                      GestureDetector(
                        onTap: _pickImages,
                        child: Container(
                          height: 100,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: const Color(0xFF2A2D3E),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.white24),
                          ),
                          child: selectedImagesBase64.isEmpty
                              ? Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: const [
                                    Icon(
                                      Icons.add_photo_alternate,
                                      color: Colors.white54,
                                      size: 30,
                                    ),
                                    Text(
                                      "Add Images",
                                      style: TextStyle(color: Colors.white54),
                                    ),
                                  ],
                                )
                              : ListView.builder(
                                  scrollDirection: Axis.horizontal,
                                  itemCount: selectedImagesBase64.length,
                                  itemBuilder: (context, index) => Padding(
                                    padding: const EdgeInsets.all(5.0),
                                    child: Image.memory(
                                      base64Decode(selectedImagesBase64[index]),
                                    ),
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: 15),

                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: nameCtrl,
                              style: const TextStyle(color: Colors.white),
                              decoration: _inputDeco("Package Name"),
                              validator: (v) => v!.isEmpty ? "Required" : null,
                            ),
                          ),
                          IconButton(
                            onPressed: _autoGenerateName,
                            icon: const Icon(
                              Icons.auto_fix_high,
                              color: Colors.purpleAccent,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 15),

                      TextFormField(
                        controller: descCtrl,
                        style: const TextStyle(color: Colors.white),
                        maxLines: 3,
                        decoration: _inputDeco("Description"),
                      ),
                      const SizedBox(height: 15),

                      Row(
                        children: [
                          Expanded(
                            child: Obx(() {
                              var cats = categoryController.categories;
                              return DropdownButtonFormField<String>(
                                value: selectedCategory,
                                dropdownColor: const Color(0xFF2A2D3E),
                                style: const TextStyle(color: Colors.white),
                                decoration: _inputDeco("Category"),
                                items: cats
                                    .map(
                                      (c) => DropdownMenuItem(
                                        value: c.name,
                                        child: Text(c.name),
                                      ),
                                    )
                                    .toList(),
                                onChanged: (v) =>
                                    setState(() => selectedCategory = v),
                              );
                            }),
                          ),
                          const SizedBox(width: 15),
                          Expanded(
                            child: Obx(() {
                              var vends = vendorController.vendors;
                              return DropdownButtonFormField<String>(
                                value:
                                    selectedVendorId ??
                                    (vends.isNotEmpty ? vends.first.id : null),
                                dropdownColor: const Color(0xFF2A2D3E),
                                style: const TextStyle(color: Colors.white),
                                decoration: _inputDeco("Vendor"),
                                items: vends
                                    .map(
                                      (v) => DropdownMenuItem(
                                        value: v.id,
                                        child: Text(
                                          v.storeName,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    )
                                    .toList(),
                                onChanged: (v) =>
                                    setState(() => selectedVendorId = v),
                              );
                            }),
                          ),
                        ],
                      ),

                      const SizedBox(height: 30),

                      // 3. PRICING
                      Text(
                        "Step 3: Pricing",
                        style: GoogleFonts.orbitron(
                          color: Colors.cyanAccent,
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
                              style: const TextStyle(color: Colors.white),
                              decoration: _inputDeco("Fake Price"),
                            ),
                          ),
                          const SizedBox(width: 15),
                          Expanded(
                            child: TextFormField(
                              controller: salePriceCtrl,
                              keyboardType: TextInputType.number,
                              style: const TextStyle(color: Colors.white),
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
                        style: const TextStyle(color: Colors.white),
                        decoration: _inputDeco("Stock Qty"),
                        validator: (v) => v!.isEmpty ? "Required" : null,
                      ),

                      const SizedBox(height: 40),

                      // SAVE BUTTON
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.purpleAccent,
                          ),
                          onPressed: () async {
                            if (_formKey.currentState!.validate()) {
                              if (_selectedProducts.isEmpty) {
                                Get.snackbar(
                                  "Error",
                                  "Select products first",
                                  backgroundColor: Colors.red,
                                  colorText: Colors.white,
                                );
                                return;
                              }

                              double buy = _totalCalculatedPurchasePrice;
                              double sell = double.parse(salePriceCtrl.text);
                              double points = productController.calculatePoints(
                                buy,
                                sell,
                              );

                              ProductModel newPackage = ProductModel(
                                id: widget.packageToEdit?.id,
                                name: nameCtrl.text,
                                modelNumber:
                                    "PKG-${DateTime.now().millisecondsSinceEpoch}",
                                description: descCtrl.text,
                                category: selectedCategory ?? "General",
                                subCategory: "Bundle",
                                brand: "Package",
                                purchasePrice: _totalCalculatedPurchasePrice,
                                salePrice: sell,
                                originalPrice:
                                    double.tryParse(originalPriceCtrl.text) ??
                                    0,
                                stockQuantity: int.parse(stockCtrl.text),
                                vendorId: selectedVendorId!,
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

                              bool success;
                              if (widget.packageToEdit == null) {
                                success = await productController.addNewProduct(
                                  newPackage,
                                );
                                if (success) _clearForm();
                              } else {
                                success = await productController.updateProduct(
                                  newPackage,
                                );
                              }

                              if (success) {
                                setState(() {
                                  _isSuccess = true;
                                });
                              }
                            }
                          },
                          child: productController.isLoading.value
                              ? const CircularProgressIndicator(
                                  color: Colors.white,
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
                    color: const Color(0xFF2A2D3E),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.purpleAccent, width: 2),
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
                        "Package Saved!",
                        style: GoogleFonts.orbitron(
                          color: Colors.white,
                          fontSize: 20,
                        ),
                      ),
                      const SizedBox(height: 30),

                      // Add New Button
                      if (widget.packageToEdit == null)
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () => setState(() => _isSuccess = false),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.purpleAccent,
                            ),
                            child: const Text(
                              "Create New Package",
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                        ),
                      const SizedBox(height: 10),

                      // Close/Go Back
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: () =>
                              Get.off(() => const PackagesHomeScreen()),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Colors.white54),
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
            ),
        ],
      ),
    );
  }

  InputDecoration _inputDeco(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.white54),
      filled: true,
      fillColor: const Color(0xFF2A2D3E),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide.none,
      ),
    );
  }
}
