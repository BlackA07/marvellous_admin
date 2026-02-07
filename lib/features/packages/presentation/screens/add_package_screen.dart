import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

// Import local components
import 'package_product_table.dart';
import 'package_details_form.dart';
import 'package_pricing_section.dart';

// Controllers & Models
import '../../../../features/products/controller/products_controller.dart';
import '../../../layout/presentation/screens/main_layout_screen.dart';
import '../../../products/models/product_model.dart';
import '../../../vendors/controllers/vendor_controller.dart';

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
  List<ProductModel> _selectedProducts = [];

  // New Logistics State for Packages (To satisfy the required model arguments)
  Map<String, double> deliveryFeesMap = {
    "Karachi": 0.0,
    "Pakistan": 0.0,
    "Worldwide": 0.0,
  };
  Map<String, String> deliveryTimeMap = {
    "Karachi": "1-2 Days",
    "Pakistan": "3-5 Days",
    "Worldwide": "7-15 Days",
  };
  double codFee = 0.0;

  // Calculation State
  double totalBuy = 0.0;
  double totalIndividualSell = 0.0;
  double totalGP = 0.0;
  double totalPts = 0.0;

  bool _isSuccess = false;

  @override
  void initState() {
    super.initState();
    if (widget.packageToEdit != null) {
      _loadPackageData();
    } else {
      selectedLocation = "Pakistan";
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

    // Load Logistics Maps from existing package
    deliveryFeesMap = Map<String, double>.from(pkg.deliveryFeesMap);
    deliveryTimeMap = Map<String, String>.from(pkg.deliveryTimeMap);
    codFee = pkg.codFee;

    _selectedProducts = productController.productsOnly
        .where((p) => pkg.includedItemIds.contains(p.id))
        .toList();
    _calculateTotals(updateImages: false);
  }

  void _calculateTotals({bool updateImages = true}) {
    double buy = 0;
    double sell = 0;
    double gp = 0;
    double pts = 0;
    List<String> autoImages = [];
    for (var p in _selectedProducts) {
      buy += p.purchasePrice;
      sell += p.salePrice;
      gp += (p.salePrice - p.purchasePrice);
      pts += productController.calculatePoints(p.purchasePrice, p.salePrice);
      if (updateImages && p.images.isNotEmpty) {
        if (!autoImages.contains(p.images.first))
          autoImages.add(p.images.first);
      }
    }
    setState(() {
      totalBuy = buy;
      totalIndividualSell = sell;
      totalGP = gp;
      totalPts = pts;
      if (updateImages) selectedImagesBase64 = autoImages;
    });
  }

  void _onProductToggle(ProductModel product) {
    setState(() {
      if (_selectedProducts.contains(product)) {
        _selectedProducts.remove(product);
      } else {
        _selectedProducts.add(product);
      }
      _calculateTotals();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: Text(
          widget.packageToEdit == null ? "Create Package" : "Edit Package",
          style: GoogleFonts.orbitron(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: const Color(0xFFF5F7FA),
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
                      PackageProductTable(
                        productController: productController,
                        selectedProducts: _selectedProducts,
                        onProductToggle: _onProductToggle,
                        totalBuy: totalBuy,
                        totalGP: totalGP,
                        totalPts: totalPts,
                      ),
                      const SizedBox(height: 30),
                      PackageDetailsForm(
                        nameCtrl: nameCtrl,
                        descCtrl: descCtrl,
                        selectedImagesBase64: selectedImagesBase64,
                        selectedVendorId: selectedVendorId,
                        selectedLocation: selectedLocation,
                        selectedProducts: _selectedProducts,
                        vendorController: vendorController,
                        onImagesChanged: (list) =>
                            setState(() => selectedImagesBase64 = list),
                        onVendorChanged: (val) =>
                            setState(() => selectedVendorId = val),
                        onLocationChanged: (val) =>
                            setState(() => selectedLocation = val),
                        onLogisticsChanged: (fees, times, cod) {
                          setState(() {
                            deliveryFeesMap = fees;
                            deliveryTimeMap = times;
                            codFee = cod;
                          });
                        },
                      ),
                      const SizedBox(height: 30),
                      PackagePricingSection(
                        productController: productController,
                        salePriceCtrl: salePriceCtrl,
                        originalPriceCtrl: originalPriceCtrl,
                        stockCtrl: stockCtrl,
                        totalBuy: totalBuy,
                        totalIndividualSell: totalIndividualSell,
                        onSave: () => _handleSave(),
                      ),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ),
          ),
          if (_isSuccess) _buildSuccessPopup(),
        ],
      ),
    );
  }

  Future<void> _handleSave() async {
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
      if (selectedVendorId == null) {
        Get.snackbar(
          "Required",
          "Please select a Vendor",
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        return;
      }

      double sell = double.tryParse(salePriceCtrl.text) ?? 0;
      double points = productController.calculatePoints(totalBuy, sell);

      ProductModel newPackage = ProductModel(
        id: widget.packageToEdit?.id,
        name: nameCtrl.text,
        modelNumber: "PKG-${DateTime.now().millisecondsSinceEpoch}",
        description: descCtrl.text,
        category: "Bundle",
        subCategory: "Bundle",
        brand: "Package",
        purchasePrice: totalBuy,
        salePrice: sell,
        originalPrice: double.tryParse(originalPriceCtrl.text) ?? 0,
        stockQuantity: int.tryParse(stockCtrl.text) ?? 0,
        vendorId: selectedVendorId!,
        images: selectedImagesBase64,
        dateAdded: DateTime.now(),
        deliveryLocation: selectedLocation ?? 'Worldwide',
        warranty: "See Items",
        productPoints: points,
        isPackage: true,
        includedItemIds: _selectedProducts.map((p) => p.id!).toList(),
        showDecimalPoints: productController.showDecimals.value,
        deliveryFeesMap: deliveryFeesMap,
        deliveryTimeMap: deliveryTimeMap,
        codFee: codFee,
        averageRating: widget.packageToEdit?.averageRating ?? 0.0,
        totalReviews: widget.packageToEdit?.totalReviews ?? 0,
      );

      bool success = widget.packageToEdit == null
          ? await productController.addNewProduct(newPackage)
          : await productController.updateProduct(newPackage);

      if (success) setState(() => _isSuccess = true);
    }
  }

  Widget _buildSuccessPopup() {
    return Container(
      color: Colors.black54,
      child: Center(
        child: Container(
          width: 300,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.check_circle, color: Colors.green, size: 60),
              const SizedBox(height: 20),
              Text(
                widget.packageToEdit == null
                    ? "Package Created!"
                    : "Package Updated!",
                style: GoogleFonts.orbitron(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Get.offAll(() => MainLayoutScreen()),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                  ),
                  child: const Text(
                    "Go to Dashboard",
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
}
