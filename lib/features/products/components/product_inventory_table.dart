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
  final int _itemsPerPage = 11; // User requirement: Odd number (9 or 11)

  // Controllers for Scrolling
  final ScrollController _verticalController = ScrollController();
  final ScrollController _topHorizontalController = ScrollController();
  final ScrollController _bottomHorizontalController = ScrollController();

  @override
  void initState() {
    super.initState();
    // Scroll Sync Logic
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

  // --- SORTING LOGIC ---
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

  // --- DYNAMIC POINTS CALCULATION (FIXED) ---
  double _calculatePoints(ProductModel product) {
    // 1. Get Sale and Purchase Price safely
    double sale = product.salePrice;

    // Make sure model has purchasePrice, else treat as 0 to avoid null errors if distinct
    double purchase = product.purchasePrice;

    // 2. Get Profit Per Point from Controller
    // Using simple .toDouble() in case it's an int or RxDouble
    double profitPerPointVal = 0.0;
    try {
      profitPerPointVal = widget.controller.profitPerPoint.toDouble();
    } catch (e) {
      // Fallback incase variable access fails
      profitPerPointVal = 1.0;
    }

    // 3. CRITICAL: Prevent Division by Zero
    if (profitPerPointVal == 0) {
      return 0.0;
    }

    // 4. Calculate Gross Profit
    double grossProfit = sale - purchase;

    // 5. Calculate Points
    double points = grossProfit / profitPerPointVal;

    // 6. Safety Check: If result is NaN or Infinity, return 0.0
    if (points.isNaN || points.isInfinite) {
      return 0.0;
    }

    return points;
  }

  @override
  Widget build(BuildContext context) {
    const Color cardColor = Color.fromARGB(255, 231, 225, 225);
    const Color textColor = Colors.black;

    // --- COMPACT SIZES ---
    final double _fontSize = widget.isMobile ? 11 : 13;
    final double _iconSize = widget.isMobile ? 16 : 18;
    final double _rowHeight = widget.isMobile ? 45 : 50;
    final double _colSpacing = widget.isMobile ? 10 : 20;

    // --- PAGINATION LOGIC ---
    int totalItems = widget.filteredList.length;
    int totalPages = (totalItems / _itemsPerPage).ceil();
    if (totalPages == 0) totalPages = 1;

    // Ensure current page is valid
    if (_currentPage > totalPages) _currentPage = totalPages;

    // Slice the list for current page
    int startIndex = (_currentPage - 1) * _itemsPerPage;
    int endIndex = startIndex + _itemsPerPage;
    if (endIndex > totalItems) endIndex = totalItems;

    // Ye list ab table men show hogi
    final List<ProductModel> currentDisplayList = widget.filteredList.sublist(
      startIndex,
      endIndex,
    );

    final double estimatedTableWidth = widget.isMobile ? 800 : 1200;

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
        // Height allows for pagination controls
        height: 760,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- HEADER ---
            Padding(
              padding: const EdgeInsets.all(15.0),
              child: Row(
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
            ),
            const Divider(color: Colors.grey, height: 1),

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
                                  columns: [
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
                                    // --- POINTS COLUMN (Modified) ---
                                    DataColumn(
                                      label: _tableHeader(
                                        "Pts (GP)",
                                        Colors.amber.shade900,
                                        _fontSize,
                                      ),
                                      numeric: true,
                                      // Sort based on calculated points
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
                                  // Use currentDisplayList (Paginated)
                                  rows: currentDisplayList.map((product) {
                                    int stockIn = product.stockQuantity;
                                    int stockOut = product.stockOut;
                                    // Use safe calculation
                                    double dynamicPoints = _calculatePoints(
                                      product,
                                    );

                                    return DataRow(
                                      cells: [
                                        // Product Name & Image
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
                                                width: 100,
                                                child: Text(
                                                  product.name,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: GoogleFonts.comicNeue(
                                                    color: textColor,
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: _fontSize,
                                                  ),
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

                                        // --- UPDATED POINTS CELL (SAFE) ---
                                        DataCell(
                                          Text(
                                            // Check again for safety before printing to string
                                            product.showDecimalPoints
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

                                        // Price Cell
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

                                        // Actions Cell
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

                    // --- PAGINATION CONTROLS FOOTER ---
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
                            "Showing $startIndex - $endIndex of $totalItems",
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

  // --- HELPER WIDGETS ---
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
