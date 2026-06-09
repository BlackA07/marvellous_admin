import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../features/products/controller/products_controller.dart';
import '../../../products/models/product_model.dart';

class PackageProductTable extends StatefulWidget {
  final ProductsController productController;
  final List<ProductModel> selectedProducts;
  final Function(ProductModel) onProductToggle;
  final double totalBuy;
  final double totalGP;
  final double totalPts;

  const PackageProductTable({
    Key? key,
    required this.productController,
    required this.selectedProducts,
    required this.onProductToggle,
    required this.totalBuy,
    required this.totalGP,
    required this.totalPts,
  }) : super(key: key);

  @override
  State<PackageProductTable> createState() => _PackageProductTableState();
}

class _PackageProductTableState extends State<PackageProductTable> {
  // ✅ NEW: Search controller for clearing text instantly
  final TextEditingController _searchCtrl = TextEditingController();
  String _productSearchQuery = "";

  int? sortColumnIndex;
  bool ascending = true;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _sortProducts(int columnIndex, bool asc) {
    setState(() {
      sortColumnIndex = columnIndex;
      ascending = asc;
    });
  }

  List<ProductModel> _getSortedProducts(List<ProductModel> products) {
    if (sortColumnIndex == null) return products;
    final sorted = List<ProductModel>.from(products);
    sorted.sort((a, b) {
      int cmp = 0;
      switch (sortColumnIndex) {
        case 1:
          cmp = a.name.compareTo(b.name);
          break;
        case 2:
          cmp = a.brand.compareTo(b.brand);
          break;
        case 3:
          cmp = a.category.compareTo(b.category);
          break;
        case 4:
          cmp = a.subCategory.compareTo(b.subCategory);
          break;
        case 5:
          cmp = a.deliveryLocation.compareTo(b.deliveryLocation);
          break;
        case 6:
          cmp = a.purchasePrice.compareTo(b.purchasePrice);
          break;
        case 7:
          cmp = a.salePrice.compareTo(b.salePrice);
          break;
        case 8:
          cmp = (a.salePrice - a.purchasePrice).compareTo(
            b.salePrice - b.purchasePrice,
          );
          break;
        case 9:
          cmp = _custPts(a).compareTo(_custPts(b));
          break;
        case 10:
          cmp = _origPts(a).compareTo(_origPts(b));
          break;
      }
      return ascending ? cmp : -cmp;
    });
    return sorted;
  }

  double _origPts(ProductModel p) =>
      widget.productController.calculatePoints(p.purchasePrice, p.salePrice);

  double _custPts(ProductModel p) {
    final pts = _origPts(p);
    final showDec = widget.productController.showDecimals.value;
    return showDec ? double.parse(pts.toStringAsFixed(2)) : pts.floorToDouble();
  }

  double get totalSellingPrice =>
      widget.selectedProducts.fold(0, (s, p) => s + p.salePrice);

  double get totalOriginalPoints =>
      widget.selectedProducts.fold(0, (s, p) => s + _origPts(p));

  double get totalCustomerPoints =>
      widget.selectedProducts.fold(0, (s, p) => s + _custPts(p));

  // ✅ Crash-proof image loader for Cloudinary URLs & Base64
  Widget _buildSmartImage(String data) {
    if (data.isEmpty)
      return const Icon(Icons.image, color: Colors.grey, size: 20);
    try {
      if (data.startsWith('http')) {
        return Image.network(
          data,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) =>
              const Icon(Icons.broken_image, size: 20),
        );
      }
      String cleanData = data.contains(',') ? data.split(',').last : data;
      return Image.memory(
        base64Decode(cleanData),
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => const Icon(Icons.broken_image, size: 20),
      );
    } catch (e) {
      return const Icon(Icons.broken_image, color: Colors.grey, size: 20);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool showDecimals = widget.productController.showDecimals.value;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Step 1: Select Products",
          style: GoogleFonts.orbitron(
            color: Colors.deepPurple,
            fontSize: 17,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 10),

        // ✅ RESPONSIVE & INSTANT SEARCH BAR
        TextField(
          controller: _searchCtrl,
          onChanged: (val) => setState(() => _productSearchQuery = val),
          style: GoogleFonts.comicNeue(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 15,
          ),
          decoration: InputDecoration(
            hintText: "Search by Name, Brand, Category, Model, Location...",
            hintStyle: GoogleFonts.comicNeue(color: Colors.black54),
            prefixIcon: const Icon(Icons.search, color: Colors.deepPurple),
            // ✅ CROSS BUTTON ADDED
            suffixIcon: _productSearchQuery.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.close, color: Colors.black54),
                    onPressed: () {
                      _searchCtrl.clear();
                      setState(() => _productSearchQuery = "");
                      FocusScope.of(context).unfocus();
                    },
                  )
                : null,
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            contentPadding: const EdgeInsets.symmetric(
              vertical: 0,
              horizontal: 10,
            ),
          ),
        ),
        const SizedBox(height: 15),

        Obx(() {
          final query = _productSearchQuery.toLowerCase();
          var all = widget.productController.productsOnly.where((p) {
            return p.name.toLowerCase().contains(query) ||
                p.brand.toLowerCase().contains(query) ||
                p.category.toLowerCase().contains(query) ||
                p.subCategory.toLowerCase().contains(query) ||
                p.deliveryLocation.toLowerCase().contains(query) ||
                p.modelNumber.toLowerCase().contains(query);
          }).toList();
          all = _getSortedProducts(all);

          return LayoutBuilder(
            builder: (context, constraints) {
              // ✅ FLEXIBLE RESPONSIVE WIDTH CALCULATION
              double minTableWidth = 1000;
              double tableWidth = math.max(constraints.maxWidth, minTableWidth);

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ─── 1. MAIN INVENTORY TABLE ───
                  Container(
                    height: 400,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.black12),
                      boxShadow: const [
                        BoxShadow(color: Colors.black12, blurRadius: 5),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Scrollbar(
                        thumbVisibility: true,
                        trackVisibility: true,
                        thickness: 8,
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: SizedBox(
                            width: tableWidth,
                            child: Column(
                              children: [
                                _buildHeader(isSelectedTable: false),
                                const Divider(
                                  height: 1,
                                  thickness: 1,
                                  color: Colors.black12,
                                ),
                                Expanded(
                                  child: SingleChildScrollView(
                                    scrollDirection: Axis.vertical,
                                    child: Column(
                                      children: all
                                          .map(
                                            (product) => _buildRow(
                                              product,
                                              showDecimals,
                                            ),
                                          )
                                          .toList(),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  // ─── 2. SELECTED PRODUCTS TABLE (NEW) ───
                  if (widget.selectedProducts.isNotEmpty) ...[
                    const SizedBox(height: 25),
                    Row(
                      children: [
                        const Icon(
                          Icons.check_circle,
                          color: Colors.green,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          "Selected Items (${widget.selectedProducts.length})",
                          style: GoogleFonts.orbitron(
                            color: Colors.green.shade800,
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Container(
                      constraints: const BoxConstraints(
                        maxHeight: 280,
                      ), // Auto size up to 280
                      decoration: BoxDecoration(
                        color: Colors.green.shade50, // Slight green tint
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.green.shade300,
                          width: 2,
                        ),
                        boxShadow: const [
                          BoxShadow(color: Colors.black12, blurRadius: 5),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Scrollbar(
                          thumbVisibility: true,
                          thickness: 8,
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: SizedBox(
                              width: tableWidth,
                              child: Column(
                                mainAxisSize: MainAxisSize.min, // Hug content
                                children: [
                                  _buildHeader(
                                    isSelectedTable: true,
                                  ), // Disable sort on this header
                                  const Divider(
                                    height: 1,
                                    thickness: 1,
                                    color: Colors.black12,
                                  ),
                                  Flexible(
                                    child: SingleChildScrollView(
                                      scrollDirection: Axis.vertical,
                                      child: Column(
                                        children: widget.selectedProducts
                                            .map(
                                              (product) => _buildRow(
                                                product,
                                                showDecimals,
                                              ),
                                            )
                                            .toList(),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              );
            },
          );
        }),
        const SizedBox(height: 20),
        _buildSummary(showDecimals),
      ],
    );
  }

  // ✅ RESPONSIVE HEADER WITH FLEX
  Widget _buildHeader({bool isSelectedTable = false}) {
    Color headerColor = isSelectedTable
        ? Colors.green.shade100
        : Colors.grey.shade200;

    return Container(
      height: 40,
      color: headerColor,
      child: Row(
        children: [
          const SizedBox(width: 45), // Space for checkbox
          _headerCell("Product", 5, 1, isSelectedTable),
          _headerCell("Brand", 2, 2, isSelectedTable),
          _headerCell("Cat", 2, 3, isSelectedTable),
          _headerCell("Sub", 2, 4, isSelectedTable),
          _headerCell("Loc", 2, 5, isSelectedTable),
          _headerCell("Buy", 2, 6, isSelectedTable),
          _headerCell("Sell", 2, 7, isSelectedTable),
          _headerCell("GP", 2, 8, isSelectedTable),
          _headerCell("Cust Pts", 2, 9, isSelectedTable),
          _headerCell("Orig Pts", 2, 10, isSelectedTable),
        ],
      ),
    );
  }

  Widget _headerCell(String label, int flex, int colIdx, bool isSelectedTable) {
    return Expanded(
      flex: flex,
      child: GestureDetector(
        onTap: isSelectedTable
            ? null
            : () {
                if (sortColumnIndex == colIdx) {
                  _sortProducts(colIdx, !ascending);
                } else {
                  _sortProducts(colIdx, true);
                }
              },
        child: Container(
          color: Colors.transparent, // Ensures full area is clickable
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  label,
                  style: GoogleFonts.comicNeue(
                    color: isSelectedTable
                        ? Colors.green.shade900
                        : Colors.black,
                    fontWeight: FontWeight.w900,
                    fontSize: 13,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (!isSelectedTable && sortColumnIndex == colIdx)
                Icon(
                  ascending ? Icons.arrow_upward : Icons.arrow_downward,
                  size: 14,
                  color: Colors.deepPurple,
                ),
            ],
          ),
        ),
      ),
    );
  }

  // ✅ RESPONSIVE DATA ROW WITH FLEX
  Widget _buildRow(ProductModel product, bool showDecimals) {
    final isSelected = widget.selectedProducts.any((p) => p.id == product.id);
    final origPts = _origPts(product);
    final custPtsStr = showDecimals
        ? origPts.toStringAsFixed(2)
        : origPts.floor().toString();
    final origPtsStr = origPts.toStringAsFixed(2);

    return InkWell(
      onTap: () => widget.onProductToggle(product),
      child: Container(
        height: 68,
        decoration: BoxDecoration(
          color: isSelected
              ? Colors.deepPurple.withOpacity(0.06)
              : Colors.white,
          border: const Border(bottom: BorderSide(color: Color(0xFFEEEEEE))),
        ),
        child: Row(
          children: [
            // Checkbox
            SizedBox(
              width: 45,
              child: Checkbox(
                value: isSelected,
                onChanged: (_) => widget.onProductToggle(product),
                activeColor: Colors.deepPurple,
              ),
            ),
            // Product name + image (Flex 5)
            Expanded(
              flex: 5,
              child: Row(
                children: [
                  if (product.images.isNotEmpty)
                    Container(
                      width: 40,
                      height: 40,
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: Colors.black12),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: _buildSmartImage(product.images.first),
                      ),
                    ),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          product.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.comicNeue(
                            color: Colors.black,
                            fontWeight: FontWeight.w900,
                            fontSize: 13,
                          ),
                        ),
                        Text(
                          product.modelNumber,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.comicNeue(
                            color: Colors.black54,
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            _cell(product.brand, 2, Colors.black87),
            _cell(product.category, 2, Colors.black87),
            _cell(product.subCategory, 2, Colors.black87),
            _cell(product.deliveryLocation, 2, Colors.black87),
            _cell(
              "Rs. ${product.purchasePrice.toInt()}",
              2,
              Colors.red.shade700,
            ),
            _cell(
              "Rs. ${product.salePrice.toInt()}",
              2,
              Colors.purple.shade700,
            ),
            _cell(
              "Rs. ${(product.salePrice - product.purchasePrice).toInt()}",
              2,
              Colors.blue.shade700,
            ),
            _cell(custPtsStr, 2, Colors.orange.shade900),
            _cell(origPtsStr, 2, Colors.deepOrange),
          ],
        ),
      ),
    );
  }

  Widget _cell(String text, int flex, Color color) {
    return Expanded(
      flex: flex,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Text(
          text,
          style: GoogleFonts.comicNeue(
            color: color,
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }

  Widget _buildSummary(bool showDecimals) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.deepPurple.withOpacity(0.2)),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10)],
      ),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 15,
        runSpacing: 10,
        children: [
          _sumItem(
            "Selected",
            "${widget.selectedProducts.length}",
            Colors.black,
          ),
          _sumItem("Buy Cost", "Rs ${widget.totalBuy.toInt()}", Colors.red),
          _sumItem(
            "Sell Sum",
            "Rs ${totalSellingPrice.toInt()}",
            Colors.purple,
          ),
          _sumItem("GP Sum", "Rs ${widget.totalGP.toInt()}", Colors.blue),
          _sumItem(
            "Cust Pts",
            showDecimals
                ? totalCustomerPoints.toStringAsFixed(2)
                : totalCustomerPoints.floor().toString(),
            Colors.orange.shade900,
          ),
          _sumItem(
            "Orig Pts",
            totalOriginalPoints.toStringAsFixed(3),
            Colors.deepOrange,
          ),
        ],
      ),
    );
  }

  Widget _sumItem(String label, String value, Color color) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      Text(
        label,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.black,
        ),
      ),
      const SizedBox(height: 2),
      Text(
        value,
        style: TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w900,
          color: color,
        ),
      ),
    ],
  );
}
