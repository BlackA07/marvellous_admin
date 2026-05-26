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
  String _productSearchQuery = "";
  int? sortColumnIndex;
  bool ascending = true;

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
        TextField(
          onChanged: (val) => setState(() => _productSearchQuery = val),
          style: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 15,
          ),
          decoration: InputDecoration(
            hintText: "Search by Name, Brand, Category, Model, Location...",
            prefixIcon: const Icon(Icons.search, color: Colors.deepPurple),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            contentPadding: const EdgeInsets.symmetric(
              vertical: 0,
              horizontal: 10,
            ),
          ),
        ),
        const SizedBox(height: 10),
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

          // Column widths
          const double wSel = 35;
          const double wProd = 130;
          const double wBrand = 65;
          const double wCat = 65;
          const double wSub = 65;
          const double wLoc = 65;
          const double wNum = 65;
          const double totalWidth =
              wSel + wProd + wBrand + wCat + wSub + wLoc + (wNum * 5) + 80;

          return Container(
            height: 400,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: const [
                BoxShadow(color: Colors.black12, blurRadius: 5),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Scrollbar(
                thumbVisibility: true,
                trackVisibility: true,
                thickness: 10,
                child: SingleChildScrollView(
                  scrollDirection: Axis.vertical,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: SizedBox(
                      width: totalWidth,
                      child: Column(
                        children: [
                          // Header
                          _buildHeader(),
                          const Divider(height: 1),
                          // Rows via ListView.builder logic (Column with items)
                          ...all
                              .map(
                                (product) => _buildRow(product, showDecimals),
                              )
                              .toList(),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        }),
        const SizedBox(height: 10),
        _buildSummary(showDecimals),
      ],
    );
  }

  Widget _buildHeader() {
    final headers = [
      ("", 35.0, false, -1),
      ("Product", 130.0, true, 1),
      ("Brand", 65.0, true, 2),
      ("Cat", 65.0, true, 3),
      ("Sub", 65.0, true, 4),
      ("Loc", 65.0, true, 5),
      ("Buy", 65.0, true, 6),
      ("Sell", 65.0, true, 7),
      ("GP", 65.0, true, 8),
      ("Cust", 65.0, true, 9),
      ("Orig", 65.0, true, 10),
    ];

    return Container(
      height: 40,
      color: Colors.grey.shade200,
      child: Row(
        children: headers.map((h) {
          final (label, width, sortable, colIdx) = h;
          return GestureDetector(
            onTap: sortable
                ? () {
                    if (sortColumnIndex == colIdx) {
                      _sortProducts(colIdx, !ascending);
                    } else {
                      _sortProducts(colIdx, true);
                    }
                  }
                : null,
            child: SizedBox(
              width: width,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      label,
                      style: GoogleFonts.comicNeue(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (sortable && sortColumnIndex == colIdx)
                    Icon(
                      ascending ? Icons.arrow_upward : Icons.arrow_downward,
                      size: 12,
                      color: Colors.deepPurple,
                    ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

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
              width: 35,
              child: Checkbox(
                value: isSelected,
                onChanged: (_) => widget.onProductToggle(product),
                activeColor: Colors.deepPurple,
              ),
            ),
            // Product name + image
            SizedBox(
              width: 130,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (product.images.isNotEmpty)
                    Container(
                      width: 40,
                      height: 40,
                      margin: const EdgeInsets.only(right: 6),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(6),
                        image: DecorationImage(
                          image: NetworkImage(product.images.first),
                          fit: BoxFit.cover,
                        ),
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
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                          ),
                        ),
                        Text(
                          product.modelNumber,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.comicNeue(
                            color: Colors.black54,
                            fontWeight: FontWeight.bold,
                            fontSize: 9,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            _cell(product.brand, 65, Colors.black),
            _cell(product.category, 65, Colors.black),
            _cell(product.subCategory, 65, Colors.black),
            _cell(product.deliveryLocation, 65, Colors.black),
            _cell("${product.purchasePrice.toInt()}", 65, Colors.red),
            _cell("${product.salePrice.toInt()}", 65, Colors.purple),
            _cell(
              "${(product.salePrice - product.purchasePrice).toInt()}",
              65,
              Colors.blue,
            ),
            _cell(custPtsStr, 65, Colors.orange.shade900),
            _cell(origPtsStr, 65, Colors.deepOrange),
          ],
        ),
      ),
    );
  }

  Widget _cell(String text, double width, Color color) {
    return SizedBox(
      width: width,
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
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10),
        ],
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
