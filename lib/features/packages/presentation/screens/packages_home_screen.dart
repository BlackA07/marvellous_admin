import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

// Controllers & Models
import '../../../../features/products/controller/products_controller.dart';
import '../../../products/models/product_model.dart';

// Screens
import 'add_package_screen.dart';
import 'package_detail_screen.dart';

class PackagesHomeScreen extends StatefulWidget {
  const PackagesHomeScreen({Key? key}) : super(key: key);

  @override
  State<PackagesHomeScreen> createState() => _PackagesHomeScreenState();
}

class _PackagesHomeScreenState extends State<PackagesHomeScreen> {
  final ProductsController controller = Get.put(ProductsController());

  // Scrolling Controllers
  final ScrollController _verticalTableController = ScrollController();
  final ScrollController _horizontalTableController = ScrollController();

  // Sorting State
  int _sortColumnIndex = 0;
  bool _isAscending = true;

  @override
  void dispose() {
    _verticalTableController.dispose();
    _horizontalTableController.dispose();
    super.dispose();
  }

  // --- SORTING LOGIC ---
  void _onSort<T>(
    Comparable<T> Function(ProductModel p) getField,
    int columnIndex,
  ) {
    setState(() {
      if (_sortColumnIndex == columnIndex) {
        _isAscending = !_isAscending;
      } else {
        _sortColumnIndex = columnIndex;
        _isAscending = true;
      }
    });
  }

  // --- DELETE LOGIC ---
  void _deletePackage(ProductModel pkg) {
    Get.defaultDialog(
      title: "Delete Package?",
      titleStyle: GoogleFonts.comicNeue(
        fontWeight: FontWeight.bold,
        color: Colors.redAccent,
      ),
      middleText: "Are you sure you want to delete ${pkg.name}?",
      textConfirm: "Delete",
      textCancel: "Cancel",
      confirmTextColor: Colors.white,
      buttonColor: Colors.red,
      onConfirm: () {
        Get.back();
        controller.deleteProduct(pkg.id!, isPackage: true);
        Get.snackbar(
          "Deleted",
          "${pkg.name} removed.",
          backgroundColor: Colors.black87,
          colorText: Colors.white,
          snackPosition: SnackPosition.TOP,
          mainButton: TextButton(
            onPressed: () {
              controller.addNewProduct(pkg);
              Get.back();
            },
            child: const Text("UNDO", style: TextStyle(color: Colors.yellow)),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    const Color bgColor = Color(0xFFF5F7FA);
    const Color cardColor = Colors.white;
    const Color textColor = Colors.black87;
    const Color headerColor = Color(0xFFE0E0E0);
    const Color accentColor = Colors.deepPurple;

    return Scaffold(
      backgroundColor: bgColor,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Get.to(() => const AddPackageScreen()),
        backgroundColor: accentColor,
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text(
          "New Package",
          style: GoogleFonts.orbitron(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          controller.fetchProducts();
        },
        child: Obx(() {
          if (controller.isLoading.value) {
            return const Center(child: CircularProgressIndicator());
          }

          // 1. Prepare List
          List<ProductModel> packages = List.from(controller.packagesOnly);

          // 2. Apply Sorting
          packages.sort((a, b) {
            int result = 0;
            switch (_sortColumnIndex) {
              case 0:
                result = a.name.compareTo(b.name);
                break;
              case 1:
                result = a.includedItemIds.length.compareTo(
                  b.includedItemIds.length,
                );
                break;
              case 2:
                result = a.productPoints.compareTo(b.productPoints);
                break;
              case 3:
                result = a.salePrice.compareTo(b.salePrice);
                break;
              case 4:
                result = a.deliveryLocation.compareTo(b.deliveryLocation);
                break;
            }
            return _isAscending ? result : -result;
          });

          // Stats
          double totalValue = packages.fold(0, (sum, p) => sum + p.salePrice);
          int totalItems = packages.length;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(15),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // --- STATS HEADER ---
                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        "Total Packages",
                        "$totalItems",
                        Icons.inventory_2,
                        Colors.blue,
                        cardColor,
                      ),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: _buildStatCard(
                        "Total Value",
                        "PKR ${totalValue.toInt()}",
                        Icons.attach_money,
                        Colors.green,
                        cardColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // --- TABLE CONTAINER ---
                Container(
                  width: double.infinity, // Ensures full width
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(5),
                  child: Theme(
                    data: Theme.of(context).copyWith(
                      dividerColor: Colors.grey.shade200,
                      iconTheme: const IconThemeData(color: Colors.black54),
                    ),
                    child: SizedBox(
                      height: 750, // Fixed height for scrolling area
                      child: Scrollbar(
                        controller: _verticalTableController,
                        thumbVisibility: true,
                        thickness: 8,
                        radius: const Radius.circular(8),
                        child: SingleChildScrollView(
                          controller: _verticalTableController,
                          scrollDirection: Axis.vertical,
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              return Scrollbar(
                                controller: _horizontalTableController,
                                thumbVisibility: true,
                                trackVisibility: true,
                                child: SingleChildScrollView(
                                  controller: _horizontalTableController,
                                  scrollDirection: Axis.horizontal,
                                  child: ConstrainedBox(
                                    constraints: BoxConstraints(
                                      // Ensure table takes at least full width of container
                                      minWidth: constraints.maxWidth,
                                    ),
                                    child: DataTable(
                                      sortColumnIndex: _sortColumnIndex,
                                      sortAscending: _isAscending,
                                      headingRowColor:
                                          MaterialStateProperty.all(
                                            headerColor,
                                          ),
                                      dataRowHeight: 60,
                                      columnSpacing: 25,
                                      // Using Expanded/Flexible inside cells helps distribute space but DataTable is rigid.
                                      // minWidth constraint above forces it to stretch if content is small.
                                      columns: [
                                        DataColumn(
                                          label: _headerText("Name"),
                                          onSort: (idx, _) =>
                                              _onSort((p) => p.name, idx),
                                        ),
                                        DataColumn(
                                          label: _headerText("Items"),
                                          numeric: true,
                                          onSort: (idx, _) => _onSort(
                                            (p) => p.includedItemIds.length,
                                            idx,
                                          ),
                                        ),
                                        DataColumn(
                                          label: _headerText("Points"),
                                          numeric: true,
                                          onSort: (idx, _) => _onSort(
                                            (p) => p.productPoints,
                                            idx,
                                          ),
                                        ),
                                        DataColumn(
                                          label: _headerText("Price"),
                                          numeric: true,
                                          onSort: (idx, _) =>
                                              _onSort((p) => p.salePrice, idx),
                                        ),
                                        DataColumn(
                                          label: _headerText("Location"),
                                          onSort: (idx, _) => _onSort(
                                            (p) => p.deliveryLocation,
                                            idx,
                                          ),
                                        ),
                                        DataColumn(
                                          label: _headerText("Actions"),
                                        ),
                                      ],
                                      rows: packages.map((pkg) {
                                        return DataRow(
                                          cells: [
                                            DataCell(
                                              Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Container(
                                                    width: 35,
                                                    height: 35,
                                                    decoration: BoxDecoration(
                                                      color:
                                                          Colors.grey.shade200,
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            6,
                                                          ),
                                                      image:
                                                          pkg.images.isNotEmpty
                                                          ? DecorationImage(
                                                              image: MemoryImage(
                                                                base64Decode(
                                                                  pkg
                                                                      .images
                                                                      .first,
                                                                ),
                                                              ),
                                                              fit: BoxFit.cover,
                                                            )
                                                          : null,
                                                    ),
                                                  ),
                                                  const SizedBox(width: 10),
                                                  // Name takes remaining space if table stretches
                                                  Container(
                                                    constraints:
                                                        const BoxConstraints(
                                                          maxWidth: 200,
                                                        ), // Limit width to prevent overflow
                                                    child: Text(
                                                      pkg.name,
                                                      style: const TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        color: textColor,
                                                      ),
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            DataCell(
                                              Text(
                                                "${pkg.includedItemIds.length}",
                                                style: const TextStyle(
                                                  color: textColor,
                                                ),
                                              ),
                                            ),
                                            DataCell(
                                              Text(
                                                pkg.productPoints
                                                    .toStringAsFixed(1),
                                                style: const TextStyle(
                                                  color: textColor,
                                                ),
                                              ),
                                            ),
                                            DataCell(
                                              Text(
                                                "PKR ${pkg.salePrice.toInt()}",
                                                style: GoogleFonts.comicNeue(
                                                  color: Colors.green[700],
                                                  fontWeight: FontWeight.w900,
                                                  fontSize: 15,
                                                ),
                                              ),
                                            ),
                                            DataCell(
                                              Text(
                                                pkg.deliveryLocation,
                                                style: const TextStyle(
                                                  color: textColor,
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ),
                                            DataCell(
                                              Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  _actionIcon(
                                                    Icons.visibility,
                                                    Colors.blue,
                                                    () => Get.to(
                                                      () => PackageDetailScreen(
                                                        package: pkg,
                                                      ),
                                                    ),
                                                  ),
                                                  _actionIcon(
                                                    Icons.edit,
                                                    Colors.orange,
                                                    () => Get.to(
                                                      () => AddPackageScreen(
                                                        packageToEdit: pkg,
                                                      ),
                                                    ),
                                                  ),
                                                  _actionIcon(
                                                    Icons.delete,
                                                    Colors.red,
                                                    () => _deletePackage(pkg),
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
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 80),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _headerText(String text) {
    return Text(
      text,
      style: const TextStyle(
        color: Colors.black87,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _actionIcon(IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Icon(icon, color: color, size: 20),
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
    Color bgColor,
  ) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                Text(
                  title,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
