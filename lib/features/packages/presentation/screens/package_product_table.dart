import 'dart:convert';
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
  final ScrollController _verticalScroll = ScrollController();

  @override
  void dispose() {
    _verticalScroll.dispose();
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
    List<ProductModel> sortedList = List.from(products);
    sortedList.sort((a, b) {
      int comparison = 0;
      switch (sortColumnIndex) {
        case 1:
          comparison = a.name.compareTo(b.name);
          break;
        case 2:
          comparison = a.brand.compareTo(b.brand);
          break;
        case 3:
          comparison = a.category.compareTo(b.category);
          break;
        case 4:
          comparison = a.subCategory.compareTo(b.subCategory);
          break;
        case 5:
          comparison = a.deliveryLocation.compareTo(b.deliveryLocation);
          break;
        case 6:
          comparison = a.purchasePrice.compareTo(b.purchasePrice);
          break;
        case 7:
          comparison = a.salePrice.compareTo(b.salePrice);
          break;
        case 8:
          comparison = (a.salePrice - a.purchasePrice).compareTo(
            b.salePrice - b.purchasePrice,
          );
          break;
        case 9:
          comparison = a.productPoints.compareTo(b.productPoints);
          break;
      }
      return ascending ? comparison : -comparison;
    });
    return sortedList;
  }

  double get totalSellingPrice =>
      widget.selectedProducts.fold(0, (sum, p) => sum + p.salePrice);

  double get totalOriginalPoints =>
      widget.selectedProducts.fold(0, (sum, p) => sum + p.productPoints);

  double get totalCustomerPoints {
    bool showDec = widget.productController.showDecimals.value;
    return widget.selectedProducts.fold(0, (sum, p) {
      double pts = p.productPoints;
      return sum +
          (showDec
              ? double.parse(pts.toStringAsFixed(2))
              : pts.floorToDouble());
    });
  }

  @override
  Widget build(BuildContext context) {
    bool showDecimals = widget.productController.showDecimals.value;

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
          var all = widget.productController.productsOnly.where((p) {
            String query = _productSearchQuery.toLowerCase();
            return p.name.toLowerCase().contains(query) ||
                p.brand.toLowerCase().contains(query) ||
                p.category.toLowerCase().contains(query) ||
                p.subCategory.toLowerCase().contains(query) ||
                p.deliveryLocation.toLowerCase().contains(query) ||
                p.modelNumber.toLowerCase().contains(query);
          }).toList();
          all = _getSortedProducts(all);

          return Container(
            height: 480,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 5)],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Scrollbar(
                controller: _verticalScroll,
                thumbVisibility: true,
                trackVisibility: true,
                thickness: 10,
                child: SingleChildScrollView(
                  controller: _verticalScroll,
                  scrollDirection: Axis.vertical,
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      return DataTable(
                        sortColumnIndex: sortColumnIndex,
                        sortAscending: ascending,
                        columnSpacing: 4,
                        horizontalMargin: 8,
                        headingRowColor: MaterialStateProperty.all(
                          Colors.grey.shade200,
                        ),
                        showCheckboxColumn: false,
                        dataRowHeight: 70,
                        columns: [
                          DataColumn(
                            label: SizedBox(
                              width: 35,
                              child: _headerText("Sel"),
                            ),
                          ),
                          DataColumn(
                            label: SizedBox(
                              width: 130,
                              child: _headerText("Product"),
                            ),
                            onSort: _sortProducts,
                          ),
                          DataColumn(
                            label: SizedBox(
                              width: 60,
                              child: _headerText("Brand"),
                            ),
                            onSort: _sortProducts,
                          ),
                          DataColumn(
                            label: SizedBox(
                              width: 65,
                              child: _headerText("Cat"),
                            ),
                            onSort: _sortProducts,
                          ),
                          DataColumn(
                            label: SizedBox(
                              width: 65,
                              child: _headerText("Sub"),
                            ),
                            onSort: _sortProducts,
                          ),
                          DataColumn(
                            label: SizedBox(
                              width: 60,
                              child: _headerText("Loc"),
                            ),
                            onSort: _sortProducts,
                          ),
                          DataColumn(
                            label: SizedBox(
                              width: 55,
                              child: _headerText("Buy"),
                            ),
                            numeric: true,
                            onSort: _sortProducts,
                          ),
                          DataColumn(
                            label: SizedBox(
                              width: 55,
                              child: _headerText("Sell"),
                            ),
                            numeric: true,
                            onSort: _sortProducts,
                          ),
                          DataColumn(
                            label: SizedBox(
                              width: 50,
                              child: _headerText("GP"),
                            ),
                            numeric: true,
                            onSort: _sortProducts,
                          ),
                          DataColumn(
                            label: SizedBox(
                              width: 50,
                              child: _headerText("Cust"),
                            ),
                            numeric: true,
                            onSort: _sortProducts,
                          ),
                          DataColumn(
                            label: SizedBox(
                              width: 50,
                              child: _headerText("Orig"),
                            ),
                            numeric: true,
                            onSort: _sortProducts,
                          ),
                        ],
                        rows: all.map((product) {
                          final isSelected = widget.selectedProducts.any(
                            (p) => p.id == product.id,
                          );
                          double origPts = product.productPoints;
                          String custPtsDisplay = showDecimals
                              ? origPts.toStringAsFixed(2)
                              : origPts.floor().toString();

                          return DataRow(
                            selected: isSelected,
                            onSelectChanged: (_) =>
                                widget.onProductToggle(product),
                            cells: [
                              DataCell(
                                SizedBox(
                                  width: 35,
                                  child: Checkbox(
                                    value: isSelected,
                                    onChanged: (_) =>
                                        widget.onProductToggle(product),
                                    activeColor: Colors.deepPurple,
                                  ),
                                ),
                              ),
                              DataCell(
                                SizedBox(
                                  width: 130,
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      if (product.images.isNotEmpty)
                                        Container(
                                          width: 40,
                                          height: 40,
                                          margin: const EdgeInsets.only(
                                            right: 6,
                                          ),
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(
                                              6,
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
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
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
                                                color: Colors.black,
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
                              ),
                              DataCell(
                                SizedBox(
                                  width: 60,
                                  child: _cellText(product.brand, maxLines: 2),
                                ),
                              ),
                              DataCell(
                                SizedBox(
                                  width: 65,
                                  child: _cellText(
                                    product.category,
                                    maxLines: 2,
                                  ),
                                ),
                              ),
                              DataCell(
                                SizedBox(
                                  width: 65,
                                  child: _cellText(
                                    product.subCategory,
                                    maxLines: 2,
                                  ),
                                ),
                              ),
                              DataCell(
                                SizedBox(
                                  width: 60,
                                  child: _cellText(
                                    product.deliveryLocation,
                                    maxLines: 2,
                                  ),
                                ),
                              ),
                              DataCell(
                                SizedBox(
                                  width: 55,
                                  child: _cellText(
                                    "${product.purchasePrice.toInt()}",
                                    color: Colors.red,
                                  ),
                                ),
                              ),
                              DataCell(
                                SizedBox(
                                  width: 55,
                                  child: _cellText(
                                    "${product.salePrice.toInt()}",
                                    color: Colors.purple,
                                  ),
                                ),
                              ),
                              DataCell(
                                SizedBox(
                                  width: 50,
                                  child: _cellText(
                                    "${(product.salePrice - product.purchasePrice).toInt()}",
                                    color: Colors.blue,
                                  ),
                                ),
                              ),
                              DataCell(
                                SizedBox(
                                  width: 50,
                                  child: _cellText(
                                    custPtsDisplay,
                                    color: Colors.orange.shade900,
                                  ),
                                ),
                              ),
                              DataCell(
                                SizedBox(
                                  width: 50,
                                  child: _cellText(
                                    origPts.toStringAsFixed(2),
                                    color: Colors.deepOrange,
                                  ),
                                ),
                              ),
                            ],
                          );
                        }).toList(),
                      );
                    },
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

  Widget _headerText(String text) => Text(
    text,
    style: GoogleFonts.comicNeue(
      color: Colors.black,
      fontWeight: FontWeight.bold,
      fontSize: 11,
    ),
    overflow: TextOverflow.ellipsis,
  );

  Widget _cellText(
    String text, {
    Color color = Colors.black,
    int maxLines = 1,
  }) => Text(
    text,
    style: GoogleFonts.comicNeue(
      color: color,
      fontWeight: FontWeight.bold,
      fontSize: 10,
    ),
    maxLines: maxLines,
    overflow: TextOverflow.ellipsis,
  );

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
          fontSize: 15,
          fontWeight: FontWeight.w900,
          color: color,
        ),
      ),
    ],
  );
}
