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

  final ScrollController _verticalController = ScrollController();

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

  @override
  void dispose() {
    _verticalController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const Color cardColor = Color.fromARGB(255, 231, 225, 225);
    const Color textColor = Colors.black;

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
        height: 650,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(15.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Inventory List",
                    style: GoogleFonts.orbitron(
                      color: textColor,
                      fontSize: widget.isMobile ? 16 : 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (widget.controller.searchHistoryList.isNotEmpty)
                    TextButton(
                      onPressed: () async {
                        bool? confirmed = await Get.defaultDialog<bool>(
                          title: "Clear History",
                          middleText: "Delete all search history?",
                          onConfirm: () {
                            Get.back(result: true);
                          },
                          onCancel: () => Get.back(result: false),
                          textConfirm: "Yes",
                          textCancel: "No",
                          buttonColor: Colors.redAccent,
                          backgroundColor: const Color.fromARGB(255, 0, 0, 0),
                        );

                        if (confirmed == true) {
                          await widget.controller.clearAllHistory();
                        }
                      },
                      child: const Text(
                        "Clear History",
                        style: TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                    ),
                ],
              ),
            ),
            const Divider(color: Colors.grey),

            if (widget.filteredList.isEmpty)
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.search_off,
                        size: widget.isMobile ? 40 : 50,
                        color: Colors.grey.shade300,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        "No products found",
                        style: GoogleFonts.comicNeue(
                          color: Colors.grey,
                          fontSize: widget.isMobile ? 16 : 18,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              Expanded(
                child: Scrollbar(
                  controller: _verticalController,
                  thumbVisibility: true,
                  interactive: true,
                  thickness: 8,
                  radius: const Radius.circular(8),
                  child: SingleChildScrollView(
                    controller: _verticalController,
                    scrollDirection: Axis.vertical,
                    child: SingleChildScrollView(
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
                          dataRowHeight: widget.isMobile ? 60 : 70,
                          columnSpacing: widget.isMobile ? 20 : 40,
                          columns: [
                            DataColumn(
                              label: _tableHeader("Product", textColor),
                              onSort: (index, _) {
                                _sort((p) => p.name, index);
                              },
                            ),
                            DataColumn(
                              label: _tableHeader("Brand", textColor),
                              onSort: (index, _) {
                                _sort((p) => p.brand, index);
                              },
                            ),
                            DataColumn(
                              label: _tableHeader("Category", textColor),
                              onSort: (index, _) {
                                _sort((p) => p.category, index);
                              },
                            ),
                            DataColumn(
                              label: _tableHeader("Sub Category", textColor),
                              onSort: (index, _) {
                                _sort((p) => p.subCategory, index);
                              },
                            ),
                            DataColumn(
                              label: _tableHeader("Location", textColor),
                              onSort: (index, _) {
                                _sort((p) => p.deliveryLocation, index);
                              },
                            ),
                            DataColumn(
                              label: _tableHeader("In / Out", textColor),
                              onSort: (index, _) {
                                _sort((p) => p.stockQuantity, index);
                              },
                            ),
                            DataColumn(
                              label: _tableHeader(
                                "Price",
                                Colors.green.shade700,
                              ),
                              numeric: true,
                              onSort: (index, _) {
                                _sort((p) => p.salePrice, index);
                              },
                            ),
                            DataColumn(
                              label: _tableHeader("Actions", textColor),
                            ),
                          ],
                          rows: widget.filteredList.map((product) {
                            int stockIn = product.stockQuantity;
                            int stockOut = product.stockOut;

                            return DataRow(
                              cells: [
                                DataCell(
                                  Row(
                                    children: [
                                      Container(
                                        width: widget.isMobile ? 35 : 45,
                                        height: widget.isMobile ? 35 : 45,
                                        decoration: BoxDecoration(
                                          color: Colors.grey.shade200,
                                          borderRadius: BorderRadius.circular(
                                            8,
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
                                        ),
                                        child: product.images.isEmpty
                                            ? Icon(
                                                product.isPackage
                                                    ? Icons.inventory_2
                                                    : Icons.image,
                                                color: Colors.grey,
                                                size: widget.isMobile ? 16 : 20,
                                              )
                                            : null,
                                      ),
                                      const SizedBox(width: 12),
                                      SizedBox(
                                        width: 120,
                                        child: Text(
                                          product.name,
                                          overflow: TextOverflow.ellipsis,
                                          style: GoogleFonts.comicNeue(
                                            color: textColor,
                                            fontWeight: FontWeight.bold,
                                            fontSize: widget.isMobile ? 13 : 15,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                DataCell(
                                  Text(
                                    product.brand,
                                    style: GoogleFonts.comicNeue(
                                      color: textColor,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                DataCell(
                                  Text(
                                    product.category,
                                    style: GoogleFonts.comicNeue(
                                      color: textColor,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                DataCell(
                                  Text(
                                    product.subCategory,
                                    style: GoogleFonts.comicNeue(
                                      color: textColor,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                DataCell(
                                  Text(
                                    product.deliveryLocation,
                                    style: GoogleFonts.comicNeue(
                                      color: textColor,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                DataCell(
                                  Text(
                                    "$stockIn / $stockOut",
                                    style: GoogleFonts.comicNeue(
                                      color: textColor,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                DataCell(
                                  Text(
                                    "PKR ${product.salePrice}",
                                    style: GoogleFonts.comicNeue(
                                      color: Colors.green.shade700,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                DataCell(
                                  Row(
                                    children: [
                                      IconButton(
                                        icon: const Icon(
                                          Icons.visibility,
                                          color: Colors.blueAccent,
                                        ),
                                        onPressed: () {
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
                                      IconButton(
                                        icon: const Icon(
                                          Icons.edit,
                                          color: Colors.orangeAccent,
                                        ),
                                        onPressed: () {
                                          ref
                                              .read(navigationProvider)
                                              .navigateTo(
                                                mainItem: "Products",
                                                subItem: "Add Product",
                                                screen: AddProductScreen(
                                                  productToEdit: product,
                                                ),
                                                title: "Edit Product",
                                              );
                                        },
                                      ),
                                      IconButton(
                                        icon: const Icon(
                                          Icons.delete,
                                          color: Colors.redAccent,
                                        ),
                                        onPressed: () =>
                                            widget.onDelete(product),
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
          ],
        ),
      ),
    );
  }

  Widget _tableHeader(String text, Color color) {
    return Text(
      text,
      style: GoogleFonts.comicNeue(
        color: color,
        fontWeight: FontWeight.bold,
        fontSize: 14,
      ),
    );
  }
}
