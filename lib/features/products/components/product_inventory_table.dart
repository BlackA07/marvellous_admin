import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../controller/products_controller.dart';
import '../models/product_model.dart';
import '../presentation/screens/add_product_screen.dart';
import '../presentation/screens/product_detail_screen.dart';
import '../../layout/controller/layout_controller.dart';

class ProductInventoryTable extends ConsumerStatefulWidget {
  final List<ProductModel> filteredList;
  final ProductsController controller;
  final bool isMobile;
  final BoxConstraints constraints;
  final Function(ProductModel) onDelete;

  const ProductInventoryTable({
    Key? key,
    required this.filteredList,
    required this.controller,
    required this.isMobile,
    required this.constraints,
    required this.onDelete,
  }) : super(key: key);

  @override
  ConsumerState<ProductInventoryTable> createState() =>
      _ProductInventoryTableState();
}

class _ProductInventoryTableState extends ConsumerState<ProductInventoryTable> {
  bool ascending = true;
  int? sortColumnIndex;

  // --- PAGINATION STATE ---
  int _currentPage = 1;
  final int _itemsPerPage = 11;

  // --- SELECTION STATE ---
  Set<String> selectedProductIds = {};

  // Controllers for Scrolling
  final ScrollController _verticalController = ScrollController();
  final ScrollController _topHorizontalController = ScrollController();
  final ScrollController _bottomHorizontalController = ScrollController();

  @override
  void initState() {
    super.initState();
    _topHorizontalController.addListener(() {
      if (_topHorizontalController.offset !=
          _bottomHorizontalController.offset) {
        _bottomHorizontalController.jumpTo(_topHorizontalController.offset);
      }
    });
    _bottomHorizontalController.addListener(() {
      if (_bottomHorizontalController.offset !=
          _topHorizontalController.offset) {
        _topHorizontalController.jumpTo(_bottomHorizontalController.offset);
      }
    });
  }

  @override
  void dispose() {
    _verticalController.dispose();
    _topHorizontalController.dispose();
    _bottomHorizontalController.dispose();
    super.dispose();
  }

  void _sort<T>(
    Comparable<T> Function(ProductModel p) getField,
    int columnIndex,
  ) {
    setState(() {
      if (sortColumnIndex == columnIndex) {
        ascending = !ascending;
      } else {
        sortColumnIndex = columnIndex;
        ascending = true;
      }
      widget.filteredList.sort((a, b) {
        final aValue = getField(a);
        final bValue = getField(b);
        return ascending
            ? Comparable.compare(aValue, bValue)
            : Comparable.compare(bValue, aValue);
      });
    });
  }

  double _calculatePoints(ProductModel product) {
    double sale = product.salePrice;
    double purchase = product.purchasePrice;
    double profitPerPointVal = 0.0;

    try {
      profitPerPointVal = widget.controller.profitPerPoint.toDouble();
    } catch (e) {
      profitPerPointVal = 1.0;
    }

    if (profitPerPointVal == 0) {
      return 0.0;
    }

    double grossProfit = sale - purchase;
    double points = grossProfit / profitPerPointVal;

    if (points.isNaN || points.isInfinite) {
      return 0.0;
    }
    return points;
  }

  // --- CALCULATE TOTAL POINTS OF FILTERED LIST ---
  double _calculateTotalPoints() {
    double total = 0.0;
    for (var product in widget.filteredList) {
      total += _calculatePoints(product);
    }
    return total;
  }

  // --- CALCULATE TOTAL AMOUNT (PRICE) OF FILTERED LIST ---
  double _calculateTotalAmount() {
    double total = 0.0;
    for (var product in widget.filteredList) {
      total += product.salePrice;
    }
    return total;
  }

  // --- CALCULATE TOTAL POINTS OF SELECTED PRODUCTS ---
  double _calculateSelectedPoints() {
    double total = 0.0;
    for (var product in widget.filteredList) {
      if (selectedProductIds.contains(product.id)) {
        total += _calculatePoints(product);
      }
    }
    return total;
  }

  // --- CALCULATE TOTAL AMOUNT OF SELECTED PRODUCTS ---
  double _calculateSelectedAmount() {
    double total = 0.0;
    for (var product in widget.filteredList) {
      if (selectedProductIds.contains(product.id)) {
        total += product.salePrice;
      }
    }
    return total;
  }

  // --- TOGGLE SELECT ALL ---
  void _toggleSelectAll(List<ProductModel> currentDisplayList) {
    setState(() {
      if (selectedProductIds.length == currentDisplayList.length &&
          currentDisplayList.isNotEmpty) {
        selectedProductIds.clear();
      } else {
        selectedProductIds = currentDisplayList.map((p) => p.id!).toSet();
      }
    });
  }

  // --- BULK DELETE SELECTED ---
  void _deleteSelected() {
    if (selectedProductIds.isEmpty) {
      Get.snackbar(
        "No Selection",
        "Please select products to delete",
        backgroundColor: Colors.orange,
        colorText: Colors.white,
      );
      return;
    }

    final int count = selectedProductIds.length;

    Get.defaultDialog(
      title: "Delete Selected Products?",
      titleStyle: GoogleFonts.comicNeue(fontWeight: FontWeight.bold),
      middleText: "Are you sure you want to delete $count product(s)?",
      textConfirm: "Delete",
      textCancel: "Cancel",
      confirmTextColor: Colors.white,
      buttonColor: Colors.redAccent,
      backgroundColor: Colors.black,
      onConfirm: () async {
        Get.back();
        for (var id in selectedProductIds) {
          await widget.controller.deleteProduct(id, isPackage: false);
        }
        setState(() {
          selectedProductIds.clear();
        });
        Get.snackbar(
          "Deleted",
          "$count product(s) removed",
          backgroundColor: Colors.black87,
          colorText: Colors.white,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    const Color cardColor = Color.fromARGB(255, 231, 225, 225);
    const Color textColor = Colors.black;

    final double _fontSize = widget.isMobile ? 11 : 13;
    final double _iconSize = widget.isMobile ? 16 : 18;
    final double _rowHeight = widget.isMobile ? 50 : 55;
    final double _colSpacing = widget.isMobile ? 10 : 20;

    int totalItems = widget.filteredList.length;
    int totalPages = (totalItems / _itemsPerPage).ceil();
    if (totalPages == 0) totalPages = 1;
    if (_currentPage > totalPages) _currentPage = totalPages;

    int startIndex = (_currentPage - 1) * _itemsPerPage;
    int endIndex = startIndex + _itemsPerPage;
    if (endIndex > totalItems) endIndex = totalItems;

    final List<ProductModel> currentDisplayList = widget.filteredList.sublist(
      startIndex,
      endIndex,
    );

    final double estimatedTableWidth = widget.isMobile ? 900 : 1300;

    // --- TOTALS ---
    double totalFilteredPoints = _calculateTotalPoints();
    double totalFilteredAmount = _calculateTotalAmount();
    double totalSelectedPoints = _calculateSelectedPoints();
    double totalSelectedAmount = _calculateSelectedAmount();

    // --- Check showDecimals from Firestore (global setting) ---
    bool showDecimals = widget.controller.showDecimals.value;

    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: SizedBox(
        height: 820,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- HEADER WITH TOTALS ---
            Padding(
              padding: const EdgeInsets.all(15.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Inventory List (${widget.filteredList.length})",
                        style: GoogleFonts.orbitron(
                          color: textColor,
                          fontSize: widget.isMobile ? 16 : 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (widget.controller.searchHistoryList.isNotEmpty)
                        TextButton(
                          onPressed: () async {
                            await widget.controller.clearAllHistory();
                          },
                          child: const Text(
                            "Clear History",
                            style: TextStyle(color: Colors.grey, fontSize: 12),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // --- TOTAL POINTS & AMOUNT ROW ---
                  Wrap(
                    spacing: 10,
                    runSpacing: 8,
                    children: [
                      // Total Points
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.amber.shade100,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.amber.shade700),
                        ),
                        child: Text(
                          showDecimals
                              ? "Total Points: ${totalFilteredPoints.toStringAsFixed(1)}"
                              : "Total Points: ${totalFilteredPoints.floor()}",
                          style: GoogleFonts.comicNeue(
                            color: Colors.amber.shade900,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      // Total Amount
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green.shade100,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.green.shade700),
                        ),
                        child: Text(
                          "Total Amount: PKR ${totalFilteredAmount.toInt()}",
                          style: GoogleFonts.comicNeue(
                            color: Colors.green.shade900,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      // Selected Totals
                      if (selectedProductIds.isNotEmpty) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade100,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.blue.shade700),
                          ),
                          child: Text(
                            showDecimals
                                ? "Selected: ${selectedProductIds.length} (${totalSelectedPoints.toStringAsFixed(1)} pts, PKR ${totalSelectedAmount.toInt()})"
                                : "Selected: ${selectedProductIds.length} (${totalSelectedPoints.floor()} pts, PKR ${totalSelectedAmount.toInt()})",
                            style: GoogleFonts.comicNeue(
                              color: Colors.blue.shade900,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            const Divider(color: Colors.grey, height: 1),

            // --- SELECTION TOOLBAR ---
            if (selectedProductIds.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 15,
                  vertical: 10,
                ),
                color: Colors.blue.shade50,
                child: Row(
                  children: [
                    Text(
                      "${selectedProductIds.length} selected",
                      style: GoogleFonts.comicNeue(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: Colors.black,
                      ),
                    ),
                    const Spacer(),
                    TextButton.icon(
                      onPressed: () =>
                          setState(() => selectedProductIds.clear()),
                      icon: const Icon(Icons.clear, size: 16),
                      label: const Text("Clear"),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton.icon(
                      onPressed: _deleteSelected,
                      icon: const Icon(Icons.delete, size: 16),
                      label: const Text("Delete Selected"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),

            // --- EMPTY STATE ---
            if (widget.filteredList.isEmpty)
              Expanded(
                child: Center(
                  child: Text(
                    "No products found",
                    style: GoogleFonts.comicNeue(color: Colors.grey),
                  ),
                ),
              )
            else
              Expanded(
                child: Column(
                  children: [
                    // --- TOP SCROLLBAR ---
                    Scrollbar(
                      controller: _topHorizontalController,
                      thumbVisibility: true,
                      trackVisibility: true,
                      thickness: 8,
                      child: SingleChildScrollView(
                        controller: _topHorizontalController,
                        scrollDirection: Axis.horizontal,
                        child: SizedBox(
                          width:
                              estimatedTableWidth > widget.constraints.maxWidth
                              ? estimatedTableWidth
                              : widget.constraints.maxWidth,
                          height: 15,
                        ),
                      ),
                    ),
                    // --- TABLE CONTENT ---
                    Expanded(
                      child: Scrollbar(
                        controller: _verticalController,
                        thumbVisibility: true,
                        thickness: 8,
                        child: SingleChildScrollView(
                          controller: _verticalController,
                          scrollDirection: Axis.vertical,
                          child: Scrollbar(
                            controller: _bottomHorizontalController,
                            thumbVisibility: true,
                            trackVisibility: true,
                            thickness: 8,
                            child: SingleChildScrollView(
                              controller: _bottomHorizontalController,
                              scrollDirection: Axis.horizontal,
                              child: ConstrainedBox(
                                constraints: BoxConstraints(
                                  minWidth: widget.constraints.maxWidth,
                                ),
                                child: DataTable(
                                  sortColumnIndex: sortColumnIndex,
                                  sortAscending: ascending,
                                  headingRowColor: MaterialStateProperty.all(
                                    const Color.fromARGB(255, 216, 213, 213),
                                  ),
                                  dataRowHeight: _rowHeight,
                                  headingRowHeight: _rowHeight,
                                  columnSpacing: _colSpacing,
                                  horizontalMargin: 10,
                                  showCheckboxColumn: false, // CRITICAL FIX
                                  columns: [
                                    // --- SELECT ALL CHECKBOX ---
                                    DataColumn(
                                      label: Checkbox(
                                        value:
                                            selectedProductIds.length ==
                                                currentDisplayList.length &&
                                            currentDisplayList.isNotEmpty,
                                        onChanged: (_) => _toggleSelectAll(
                                          currentDisplayList,
                                        ),
                                        activeColor: Colors.blue,
                                      ),
                                    ),
                                    DataColumn(
                                      label: _tableHeader(
                                        "Product",
                                        textColor,
                                        _fontSize,
                                      ),
                                      onSort: (index, _) =>
                                          _sort((p) => p.name, index),
                                    ),
                                    DataColumn(
                                      label: _tableHeader(
                                        "Brand",
                                        textColor,
                                        _fontSize,
                                      ),
                                      onSort: (index, _) =>
                                          _sort((p) => p.brand, index),
                                    ),
                                    DataColumn(
                                      label: _tableHeader(
                                        "Category",
                                        textColor,
                                        _fontSize,
                                      ),
                                      onSort: (index, _) =>
                                          _sort((p) => p.category, index),
                                    ),
                                    DataColumn(
                                      label: _tableHeader(
                                        "Sub Cat",
                                        textColor,
                                        _fontSize,
                                      ),
                                      onSort: (index, _) =>
                                          _sort((p) => p.subCategory, index),
                                    ),
                                    DataColumn(
                                      label: _tableHeader(
                                        "Loc",
                                        textColor,
                                        _fontSize,
                                      ),
                                      onSort: (index, _) => _sort(
                                        (p) => p.deliveryLocation,
                                        index,
                                      ),
                                    ),
                                    DataColumn(
                                      label: _tableHeader(
                                        "In/Out",
                                        textColor,
                                        _fontSize,
                                      ),
                                      onSort: (index, _) =>
                                          _sort((p) => p.stockQuantity, index),
                                    ),
                                    DataColumn(
                                      label: _tableHeader(
                                        "Pts (GP)",
                                        Colors.amber.shade900,
                                        _fontSize,
                                      ),
                                      numeric: true,
                                      onSort: (index, _) => _sort(
                                        (p) => _calculatePoints(p),
                                        index,
                                      ),
                                    ),
                                    DataColumn(
                                      label: _tableHeader(
                                        "Price",
                                        Colors.green.shade800,
                                        _fontSize,
                                      ),
                                      numeric: true,
                                      onSort: (index, _) =>
                                          _sort((p) => p.salePrice, index),
                                    ),
                                    DataColumn(
                                      label: _tableHeader(
                                        "Actions",
                                        textColor,
                                        _fontSize,
                                      ),
                                    ),
                                  ],
                                  rows: currentDisplayList.map((product) {
                                    int stockIn = product.stockQuantity;
                                    int stockOut = product.stockOut;
                                    double dynamicPoints = _calculatePoints(
                                      product,
                                    );
                                    bool isSelected = selectedProductIds
                                        .contains(product.id);

                                    return DataRow(
                                      selected: isSelected,
                                      onSelectChanged: (selected) {
                                        setState(() {
                                          if (selected == true) {
                                            selectedProductIds.add(product.id!);
                                          } else {
                                            selectedProductIds.remove(
                                              product.id,
                                            );
                                          }
                                        });
                                      },
                                      cells: [
                                        // --- CHECKBOX CELL ---
                                        DataCell(
                                          Checkbox(
                                            value: isSelected,
                                            onChanged: (val) {
                                              setState(() {
                                                if (val == true) {
                                                  selectedProductIds.add(
                                                    product.id!,
                                                  );
                                                } else {
                                                  selectedProductIds.remove(
                                                    product.id,
                                                  );
                                                }
                                              });
                                            },
                                            activeColor: Colors.blue,
                                          ),
                                        ),
                                        // --- PRODUCT NAME & MODEL NUMBER ---
                                        DataCell(
                                          Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              if (product.images.isNotEmpty)
                                                Container(
                                                  width: 30,
                                                  height: 30,
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
                                              SizedBox(
                                                width: 120,
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
                                                      style:
                                                          GoogleFonts.comicNeue(
                                                            color: textColor,
                                                            fontWeight:
                                                                FontWeight.bold,
                                                            fontSize: _fontSize,
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
                                                              color: Colors
                                                                  .grey
                                                                  .shade600,
                                                              fontSize:
                                                                  _fontSize - 2,
                                                            ),
                                                      ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        _buildCellText(
                                          product.brand,
                                          _fontSize,
                                        ),
                                        _buildCellText(
                                          product.category,
                                          _fontSize,
                                        ),
                                        _buildCellText(
                                          product.subCategory,
                                          _fontSize,
                                        ),
                                        _buildCellText(
                                          product.deliveryLocation,
                                          _fontSize,
                                        ),
                                        _buildCellText(
                                          "$stockIn / $stockOut",
                                          _fontSize,
                                        ),
                                        DataCell(
                                          Text(
                                            showDecimals
                                                ? dynamicPoints.toStringAsFixed(
                                                    1,
                                                  )
                                                : dynamicPoints
                                                      .floor()
                                                      .toString(),
                                            style: GoogleFonts.comicNeue(
                                              color: Colors.amber.shade900,
                                              fontWeight: FontWeight.w900,
                                              fontSize: _fontSize,
                                            ),
                                          ),
                                        ),
                                        DataCell(
                                          Text(
                                            "PKR ${product.salePrice.toInt()}",
                                            style: GoogleFonts.comicNeue(
                                              color: Colors.green.shade800,
                                              fontWeight: FontWeight.bold,
                                              fontSize: _fontSize,
                                            ),
                                          ),
                                        ),
                                        DataCell(
                                          Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              _actionIcon(
                                                Icons.visibility,
                                                Colors.blueAccent,
                                                _iconSize,
                                                () {
                                                  Navigator.push(
                                                    context,
                                                    MaterialPageRoute(
                                                      builder: (_) =>
                                                          ProductDetailScreen(
                                                            product: product,
                                                          ),
                                                    ),
                                                  );
                                                },
                                              ),
                                              _actionIcon(
                                                Icons.edit,
                                                Colors.orangeAccent,
                                                _iconSize,
                                                () {
                                                  ref
                                                      .read(navigationProvider)
                                                      .navigateTo(
                                                        mainItem: "Products",
                                                        subItem: "Add Product",
                                                        screen:
                                                            AddProductScreen(
                                                              productToEdit:
                                                                  product,
                                                            ),
                                                        title: "Edit Product",
                                                      );
                                                },
                                              ),
                                              _actionIcon(
                                                Icons.delete,
                                                Colors.redAccent,
                                                _iconSize,
                                                () {
                                                  widget.onDelete(product);
                                                },
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    );
                                  }).toList(),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    // --- PAGINATION CONTROLS ---
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                      decoration: const BoxDecoration(
                        border: Border(
                          top: BorderSide(color: Colors.grey, width: 0.5),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(
                            "Showing ${startIndex + 1} - $endIndex of $totalItems",
                            style: GoogleFonts.comicNeue(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 20),
                          IconButton(
                            icon: const Icon(Icons.arrow_back_ios, size: 16),
                            onPressed: _currentPage > 1
                                ? () => setState(() => _currentPage--)
                                : null,
                          ),
                          Text(
                            "Page $_currentPage of $totalPages",
                            style: GoogleFonts.orbitron(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.arrow_forward_ios, size: 16),
                            onPressed: _currentPage < totalPages
                                ? () => setState(() => _currentPage++)
                                : null,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _tableHeader(String text, Color color, double fontSize) {
    return Text(
      text,
      style: GoogleFonts.comicNeue(
        color: color,
        fontWeight: FontWeight.bold,
        fontSize: fontSize,
      ),
    );
  }

  DataCell _buildCellText(String text, double fontSize) {
    return DataCell(
      Text(
        text,
        style: GoogleFonts.comicNeue(
          color: Colors.black,
          fontSize: fontSize,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _actionIcon(
    IconData icon,
    Color color,
    double size,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Icon(icon, color: color, size: size),
      ),
    );
  }
}
