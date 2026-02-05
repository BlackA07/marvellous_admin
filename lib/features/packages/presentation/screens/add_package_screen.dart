import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

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
  double _totalCalculatedIndividualSellPrice = 0.0;
  double _totalCalculatedGP = 0.0;
  double _totalCalculatedPoints = 0.0;

  String _productSearchQuery = "";

  // Sorting State
  int? sortColumnIndex;
  bool ascending = true;
  List<ProductModel> _sortedProducts = [];

  bool _isSuccess = false;

  final List<String> locationOptions = [
    "Karachi Only",
    "Pakistan",
    "Worldwide",
    "Store Pickup Only",
  ];

  // Colors
  final Color bgColor = const Color(0xFFF5F7FA);
  final Color cardColor = Colors.white;
  final Color textColor = Colors.black87;
  final Color accentColor = Colors.deepPurple;
  final Color hintColor = const Color.fromARGB(255, 0, 0, 0);

  @override
  void initState() {
    super.initState();

    salePriceCtrl.addListener(() {
      setState(() {});
    });

    if (widget.packageToEdit != null) {
      _loadPackageData();
    } else {
      selectedLocation = locationOptions[1];
    }
  }

  @override
  void dispose() {
    nameCtrl.dispose();
    descCtrl.dispose();
    salePriceCtrl.dispose();
    originalPriceCtrl.dispose();
    stockCtrl.dispose();
    super.dispose();
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
    double totalBuy = 0;
    double totalIndividualSell = 0;
    double totalGP = 0;
    double totalPts = 0;
    List<String> autoImages = [];

    for (var p in _selectedProducts) {
      totalBuy += p.purchasePrice;
      totalIndividualSell += p.salePrice;

      double gp = p.salePrice - p.purchasePrice;
      double pts = productController.calculatePoints(
        p.purchasePrice,
        p.salePrice,
      );

      totalGP += gp;
      totalPts += pts;

      if (updateImages && p.images.isNotEmpty) {
        if (!autoImages.contains(p.images.first)) {
          autoImages.add(p.images.first);
        }
      }
    }

    setState(() {
      _totalCalculatedPurchasePrice = totalBuy;
      _totalCalculatedIndividualSellPrice = totalIndividualSell;
      _totalCalculatedGP = totalGP;
      _totalCalculatedPoints = totalPts;
      if (updateImages) {
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
      _totalCalculatedIndividualSellPrice = 0.0;
      _totalCalculatedGP = 0.0;
      _totalCalculatedPoints = 0.0;
      _sortedProducts.clear();
      sortColumnIndex = null;
      ascending = true;
    });
  }

  // --- IMPROVED SORTING LOGIC ---
  void _sortProducts(int columnIndex, bool ascending) {
    setState(() {
      sortColumnIndex = columnIndex;
      this.ascending = ascending;
    });
  }

  // Helper method to get sorted products
  List<ProductModel> _getSortedProducts(List<ProductModel> products) {
    if (sortColumnIndex == null) return products;

    List<ProductModel> sortedList = List.from(products);

    sortedList.sort((a, b) {
      int comparison = 0;

      switch (sortColumnIndex) {
        case 1: // Product Name column
          comparison = a.name.compareTo(b.name);
          break;
        case 2: // Brand column
          comparison = a.brand.compareTo(b.brand);
          break;
        case 3: // Buy Price column
          comparison = a.purchasePrice.compareTo(b.purchasePrice);
          break;
        case 4: // Sell Price column
          comparison = a.salePrice.compareTo(b.salePrice);
          break;
        case 5: // GP column
          double gpA = a.salePrice - a.purchasePrice;
          double gpB = b.salePrice - b.purchasePrice;
          comparison = gpA.compareTo(gpB);
          break;
        case 6: // Points column
          double ptsA = productController.calculatePoints(
            a.purchasePrice,
            a.salePrice,
          );
          double ptsB = productController.calculatePoints(
            b.purchasePrice,
            b.salePrice,
          );
          comparison = ptsA.compareTo(ptsB);
          break;
        default:
          return 0;
      }

      return ascending ? comparison : -comparison;
    });

    return sortedList;
  }

  @override
  Widget build(BuildContext context) {
    // Get showDecimals from controller
    bool showDecimals = productController.showDecimals.value;

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
                      // 1. SELECT PRODUCTS WITH TABLE
                      Text(
                        "Step 1: Select Products",
                        style: GoogleFonts.orbitron(
                          color: accentColor,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Search Bar
                      TextField(
                        onChanged: (val) =>
                            setState(() => _productSearchQuery = val),
                        style: TextStyle(color: textColor),
                        decoration: InputDecoration(
                          hintText: "Search products...",
                          hintStyle: TextStyle(color: hintColor),
                          prefixIcon: Icon(Icons.search, color: hintColor),
                          filled: true,
                          fillColor: cardColor,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 0,
                          ),
                        ),
                      ),

                      const SizedBox(height: 10),

                      // Product Table
                      Obx(() {
                        var allProducts = productController.productsOnly.where((
                          p,
                        ) {
                          return p.name.toLowerCase().contains(
                            _productSearchQuery.toLowerCase(),
                          );
                        }).toList();

                        // Apply sorting if needed
                        allProducts = _getSortedProducts(allProducts);

                        return Container(
                          height: 400,
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
                          child: SingleChildScrollView(
                            scrollDirection: Axis.vertical,
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: DataTable(
                                columnSpacing: 30,
                                horizontalMargin: 15,
                                headingRowHeight: 50,
                                dataRowHeight: 60,
                                sortColumnIndex: sortColumnIndex,
                                sortAscending: ascending,
                                headingRowColor: MaterialStateProperty.all(
                                  Colors.grey.shade200,
                                ),
                                showCheckboxColumn: false,
                                columns: [
                                  DataColumn(
                                    label: Container(
                                      width: 70,
                                      child: _tableHeader("Select"),
                                    ),
                                  ),
                                  DataColumn(
                                    label: Container(
                                      width: 220,
                                      child: _tableHeader("Product"),
                                    ),
                                    onSort: (columnIndex, ascending) {
                                      _sortProducts(columnIndex, ascending);
                                    },
                                  ),
                                  DataColumn(
                                    label: Container(
                                      width: 120,
                                      child: _tableHeader("Brand"),
                                    ),
                                    onSort: (columnIndex, ascending) {
                                      _sortProducts(columnIndex, ascending);
                                    },
                                  ),
                                  DataColumn(
                                    label: Container(
                                      width: 110,
                                      child: _tableHeader("Buy Price"),
                                    ),
                                    numeric: true,
                                    onSort: (columnIndex, ascending) {
                                      _sortProducts(columnIndex, ascending);
                                    },
                                  ),
                                  DataColumn(
                                    label: Container(
                                      width: 110,
                                      child: _tableHeader("Sell Price"),
                                    ),
                                    numeric: true,
                                    onSort: (columnIndex, ascending) {
                                      _sortProducts(columnIndex, ascending);
                                    },
                                  ),
                                  DataColumn(
                                    label: Container(
                                      width: 100,
                                      child: _tableHeader("GP"),
                                    ),
                                    numeric: true,
                                    onSort: (columnIndex, ascending) {
                                      _sortProducts(columnIndex, ascending);
                                    },
                                  ),
                                  DataColumn(
                                    label: Container(
                                      width: 100,
                                      child: _tableHeader(
                                        "Points",
                                        color: Colors.amber.shade900,
                                      ),
                                    ),
                                    numeric: true,
                                    onSort: (columnIndex, ascending) {
                                      _sortProducts(columnIndex, ascending);
                                    },
                                  ),
                                ],
                                rows: allProducts.map((product) {
                                  final isSelected = _selectedProducts.contains(
                                    product,
                                  );

                                  final double gp =
                                      product.salePrice - product.purchasePrice;
                                  final double pts = productController
                                      .calculatePoints(
                                        product.purchasePrice,
                                        product.salePrice,
                                      );

                                  return DataRow(
                                    selected: isSelected,
                                    onSelectChanged: (_) =>
                                        _toggleProductSelection(product),
                                    cells: [
                                      // Checkbox
                                      DataCell(
                                        SizedBox(
                                          width: 70,
                                          child: Checkbox(
                                            value: isSelected,
                                            onChanged: (_) =>
                                                _toggleProductSelection(
                                                  product,
                                                ),
                                            activeColor: accentColor,
                                          ),
                                        ),
                                      ),
                                      // Product Name + Image
                                      DataCell(
                                        Container(
                                          width: 220,
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              if (product.images.isNotEmpty)
                                                Container(
                                                  width: 35,
                                                  height: 35,
                                                  margin: const EdgeInsets.only(
                                                    right: 8,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          4,
                                                        ),
                                                    image: DecorationImage(
                                                      image: MemoryImage(
                                                        base64Decode(
                                                          product.images.first,
                                                        ),
                                                      ),
                                                      fit: BoxFit.cover,
                                                    ),
                                                  ),
                                                ),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.center,
                                                  children: [
                                                    Text(
                                                      product.name,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                      maxLines: 2,
                                                      style:
                                                          GoogleFonts.comicNeue(
                                                            fontWeight:
                                                                FontWeight.bold,
                                                            fontSize: 13,
                                                            color: Colors.black,
                                                          ),
                                                    ),
                                                    if (product
                                                        .modelNumber
                                                        .isNotEmpty)
                                                      Text(
                                                        product.modelNumber,
                                                        overflow: TextOverflow
                                                            .ellipsis,
                                                        style:
                                                            GoogleFonts.comicNeue(
                                                              color:
                                                                  Colors.black,
                                                              fontSize: 11,
                                                            ),
                                                      ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                      // Brand
                                      DataCell(
                                        Container(
                                          width: 120,
                                          child: Text(
                                            product.brand,
                                            style: GoogleFonts.comicNeue(
                                              fontSize: 13,
                                              color: Colors.black,
                                            ),
                                          ),
                                        ),
                                      ),
                                      // Buy Price
                                      DataCell(
                                        Container(
                                          width: 110,
                                          child: Text(
                                            "PKR ${product.purchasePrice.toInt()}",
                                            textAlign: TextAlign.right,
                                            style: GoogleFonts.comicNeue(
                                              color: Colors.red.shade700,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 13,
                                            ),
                                          ),
                                        ),
                                      ),
                                      // Sell Price
                                      DataCell(
                                        Container(
                                          width: 110,
                                          child: Text(
                                            "PKR ${product.salePrice.toInt()}",
                                            textAlign: TextAlign.right,
                                            style: GoogleFonts.comicNeue(
                                              color: Colors.green.shade700,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 13,
                                            ),
                                          ),
                                        ),
                                      ),
                                      // GP
                                      DataCell(
                                        Container(
                                          width: 100,
                                          child: Text(
                                            "PKR ${gp.toInt()}",
                                            textAlign: TextAlign.right,
                                            style: GoogleFonts.comicNeue(
                                              color: Colors.blue.shade700,
                                              fontWeight: FontWeight.w900,
                                              fontSize: 13,
                                            ),
                                          ),
                                        ),
                                      ),
                                      // Points
                                      DataCell(
                                        Container(
                                          width: 100,
                                          child: Text(
                                            showDecimals
                                                ? pts.toStringAsFixed(2)
                                                : pts.floor().toString(),
                                            textAlign: TextAlign.right,
                                            style: GoogleFonts.comicNeue(
                                              color: Colors.amber.shade900,
                                              fontWeight: FontWeight.w900,
                                              fontSize: 13,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  );
                                }).toList(),
                              ),
                            ),
                          ),
                        );
                      }),

                      const SizedBox(height: 10),

                      // --- SUMMARY SECTION ---
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: cardColor,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: accentColor.withOpacity(0.2),
                          ),
                        ),
                        child: Wrap(
                          spacing: 20,
                          runSpacing: 10,
                          alignment: WrapAlignment.spaceBetween,
                          children: [
                            _summaryItem(
                              "Selected",
                              "${_selectedProducts.length}",
                            ),
                            _summaryItem(
                              "Cost",
                              "PKR ${_totalCalculatedPurchasePrice.toInt()}",
                            ),
                            _summaryItem(
                              "Total GP",
                              "PKR ${_totalCalculatedGP.toInt()}",
                              valueColor: Colors.blue,
                            ),
                            _summaryItem(
                              "Total Pts",
                              showDecimals
                                  ? _totalCalculatedPoints.toStringAsFixed(2)
                                  : _totalCalculatedPoints.floor().toString(),
                              valueColor: Colors.amber[800],
                            ),
                          ],
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

                      // Images Area
                      SizedBox(
                        height: 100,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          children: [
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
                                iconEnabledColor: Colors.black54,
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
                              iconEnabledColor: Colors.black54,
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

                      // --- COST & POINTS INFO ---
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.only(bottom: 15),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Column(
                          children: [
                            _buildReadOnlyRow(
                              "Total Purchase Cost:",
                              "PKR ${_totalCalculatedPurchasePrice.toStringAsFixed(0)}",
                              Colors.red.shade700,
                            ),
                            const Divider(height: 10),
                            _buildReadOnlyRow(
                              "Total Individual Sell Price:",
                              "PKR ${_totalCalculatedIndividualSellPrice.toStringAsFixed(0)}",
                              Colors.blue.shade800,
                            ),
                            const Divider(height: 10),
                            Builder(
                              builder: (context) {
                                double currentSell =
                                    double.tryParse(salePriceCtrl.text) ?? 0;
                                double points = productController
                                    .calculatePoints(
                                      _totalCalculatedPurchasePrice,
                                      currentSell,
                                    );
                                return _buildReadOnlyRow(
                                  "Gross Profit Points:",
                                  showDecimals
                                      ? points.toStringAsFixed(2)
                                      : points.floor().toString(),
                                  Colors.green.shade800,
                                  isBold: true,
                                );
                              },
                            ),
                          ],
                        ),
                      ),

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
                              decoration: _inputDeco("Bundle Sale Price"),
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

                      // SAVE BUTTON
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
                                        showDecimalPoints: showDecimals,
                                      );

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

  Widget _tableHeader(String text, {Color? color}) {
    return Text(
      text,
      style: GoogleFonts.comicNeue(
        color: color ?? Colors.black,
        fontWeight: FontWeight.bold,
        fontSize: 13,
      ),
    );
  }

  Widget _summaryItem(String label, String value, {Color? valueColor}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.grey.shade600,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: valueColor ?? Colors.black87,
            fontWeight: FontWeight.w900,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget _buildReadOnlyRow(
    String label,
    String value,
    Color valueColor, {
    bool isBold = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.grey.shade700,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: valueColor,
            fontSize: 14,
            fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
          ),
        ),
      ],
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
