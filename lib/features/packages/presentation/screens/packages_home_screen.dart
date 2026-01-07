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
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  // Delete Logic with Undo
  void _deletePackage(ProductModel pkg) {
    Get.defaultDialog(
      title: "Delete Package?",
      titleStyle: GoogleFonts.comicNeue(
        fontWeight: FontWeight.bold,
        color: const Color.fromARGB(221, 255, 0, 0),
      ), // Dialog text dark for white bg
      middleText: "Are you sure you want to delete ${pkg.name}?",
      textConfirm: "Delete",
      textCancel: "Cancel",
      confirmTextColor: Colors.white,
      buttonColor: Colors.redAccent,
      backgroundColor: const Color.fromARGB(255, 0, 0, 0),
      onConfirm: () {
        // 1. Close Dialog immediately
        Get.back();

        // 2. Perform Delete (Pass isPackage: true)
        controller.deleteProduct(pkg.id!, isPackage: true);

        // 3. Show Undo Snackbar
        Get.snackbar(
          "Processing Delete",
          "${pkg.name} is being removed...",
          mainButton: TextButton(
            onPressed: () {
              // UNDO LOGIC
              controller.addNewProduct(pkg);
              Get.back(); // Close Snackbar
            },
            child: const Text("UNDO", style: TextStyle(color: Colors.yellow)),
          ),
          backgroundColor: Colors.black87,
          colorText: Colors.white,
          duration: const Duration(seconds: 3),
          snackPosition: SnackPosition.TOP, // Show at Top
          margin: const EdgeInsets.all(20),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // RESTORED DARK THEME COLORS
    // This was likely transparent before to show gradient behind, or a specific dark color.
    // Assuming transparent to match Dashboard gradient or fallback to dark.
    const Color bgColor = Color.fromARGB(0, 228, 224, 224);
    const Color cardColor = Color.fromARGB(
      255,
      199,
      193,
      191,
    ); // Dark Card Color
    const Color textColor = Color.fromARGB(255, 0, 0, 0);
    const Color accentColor = Color.fromARGB(
      255,
      83,
      157,
      207,
    ); // Original Accent

    return Scaffold(
      backgroundColor: bgColor,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Get.to(() => const AddPackageScreen()),
        backgroundColor: accentColor,
        icon: const Icon(Icons.inventory_2, color: Colors.white),
        label: Text(
          "Create Package",
          style: GoogleFonts.comicNeue(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      // REFRESH INDICATOR
      body: RefreshIndicator(
        color: accentColor,
        backgroundColor: cardColor,
        onRefresh: () async {
          controller.fetchProducts();
          await Future.delayed(const Duration(seconds: 1));
        },
        child: Obx(() {
          if (controller.isLoading.value) {
            return const Center(
              child: CircularProgressIndicator(color: accentColor),
            );
          }

          final packages = controller.packagesOnly;

          // Calculate Stats
          double totalValue = packages.fold(0, (sum, p) => sum + p.salePrice);
          int totalPackages = packages.length;

          return Scrollbar(
            controller: _scrollController,
            thumbVisibility: true,
            trackVisibility: true,
            thickness: 8,
            radius: const Radius.circular(10),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              controller: _scrollController,
              padding: const EdgeInsets.all(13),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // STATS AREA
                  LayoutBuilder(
                    builder: (context, constraints) {
                      bool isMobile = constraints.maxWidth < 800;
                      return isMobile
                          ? Column(
                              children: [
                                _buildStatCard(
                                  "Total Packages",
                                  "$totalPackages",
                                  Icons.inventory_2,
                                  Colors.cyanAccent,
                                  cardColor,
                                ), // Cyan for dark theme
                                const SizedBox(height: 10),
                                _buildStatCard(
                                  "Inventory Value",
                                  "PKR ${totalValue.toStringAsFixed(0)}",
                                  Icons.attach_money,
                                  Colors
                                      .greenAccent, // GreenAccent for dark theme
                                  cardColor,
                                ),
                              ],
                            )
                          : Row(
                              children: [
                                Expanded(
                                  child: _buildStatCard(
                                    "Total Packages",
                                    "$totalPackages",
                                    Icons.inventory_2,
                                    Colors.cyanAccent,
                                    cardColor,
                                  ),
                                ),
                                const SizedBox(width: 20),
                                Expanded(
                                  child: _buildStatCard(
                                    "Inventory Value",
                                    "PKR ${totalValue.toStringAsFixed(0)}",
                                    Icons.attach_money,
                                    Colors.greenAccent,
                                    cardColor,
                                  ),
                                ),
                              ],
                            );
                    },
                  ),

                  const SizedBox(height: 30),

                  Text(
                    "Active Packages",
                    style: GoogleFonts.comicNeue(
                      color: textColor,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Divider(color: Colors.white10),

                  if (packages.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(40),
                      child: Center(
                        child: Column(
                          children: [
                            Icon(Icons.inbox, size: 50, color: Colors.white24),
                            const SizedBox(height: 10),
                            Text(
                              "No Packages Found",
                              style: TextStyle(
                                color: Colors.white54,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    Container(
                      decoration: BoxDecoration(
                        color: cardColor, // Dark bg for table container
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(10),
                      child: SizedBox(
                        height: 650,
                        child: SingleChildScrollView(
                          scrollDirection: Axis.vertical,
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: DataTable(
                              headingRowColor: MaterialStateProperty.all(
                                Colors.white10,
                              ), // Dark header
                              dataRowHeight: 70,
                              columnSpacing: 30,
                              columns: const [
                                DataColumn(
                                  label: Text(
                                    "Name",
                                    style: TextStyle(
                                      color: Color.fromARGB(
                                        255,
                                        0,
                                        0,
                                        0,
                                      ), // White Header Text
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                DataColumn(
                                  label: Text(
                                    "Items",
                                    style: TextStyle(
                                      color: Color.fromARGB(255, 0, 0, 0),
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                DataColumn(
                                  label: Text(
                                    "Price",
                                    style: TextStyle(
                                      color: Color.fromARGB(255, 0, 0, 0),
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                DataColumn(
                                  label: Text(
                                    "Actions",
                                    style: TextStyle(
                                      color: Color.fromARGB(255, 0, 0, 0),
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                              rows: packages.map((pkg) {
                                return DataRow(
                                  cells: [
                                    // Name & Image
                                    DataCell(
                                      Row(
                                        children: [
                                          Container(
                                            width: 40,
                                            height: 40,
                                            decoration: BoxDecoration(
                                              color: Colors
                                                  .grey[800], // Dark placeholder
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                              image: pkg.images.isNotEmpty
                                                  ? DecorationImage(
                                                      image: MemoryImage(
                                                        base64Decode(
                                                          pkg.images.first,
                                                        ),
                                                      ),
                                                      fit: BoxFit.cover,
                                                    )
                                                  : null,
                                            ),
                                            child: pkg.images.isEmpty
                                                ? const Icon(
                                                    Icons.inventory_2,
                                                    color: Colors.white54,
                                                  )
                                                : null,
                                          ),
                                          const SizedBox(width: 10),
                                          SizedBox(
                                            width: 180,
                                            child: Text(
                                              pkg.name,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w600,
                                                color: Colors.white,
                                              ), // White Text
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    // Items Count
                                    DataCell(
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.purple.withOpacity(0.3),
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        child: Text(
                                          "${pkg.includedItemIds.length} Items",
                                          style: const TextStyle(
                                            color: Colors
                                                .purpleAccent, // Light Purple
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                    ),
                                    // Price
                                    DataCell(
                                      Text(
                                        "PKR ${pkg.salePrice}",
                                        style: GoogleFonts.comicNeue(
                                          color: Colors
                                              .greenAccent, // Green Accent
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ),
                                    // Actions
                                    DataCell(
                                      Row(
                                        children: [
                                          IconButton(
                                            icon: const Icon(
                                              Icons.visibility,
                                              color: Colors.blueAccent,
                                            ),
                                            onPressed: () => Get.to(
                                              () => PackageDetailScreen(
                                                package: pkg,
                                              ),
                                            ),
                                          ),
                                          IconButton(
                                            icon: const Icon(
                                              Icons.edit,
                                              color: Colors.orangeAccent,
                                            ),
                                            onPressed: () => Get.to(
                                              () => AddPackageScreen(
                                                packageToEdit: pkg,
                                              ),
                                            ),
                                          ),
                                          IconButton(
                                            icon: const Icon(
                                              Icons.delete,
                                              color: Colors.redAccent,
                                            ),
                                            onPressed: () =>
                                                _deletePackage(pkg),
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
                ],
              ),
            ),
          );
        }),
      ),
    );
  }

  // Helper Widget for Stats Card (Updated for Dark Theme)
  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
    Color bgColor,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1), // Subtle colored glow
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    value,
                    style: GoogleFonts.comicNeue(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: const Color.fromARGB(255, 0, 0, 0),
                    ),
                  ), // White Text
                ),
                Text(
                  title,
                  style: GoogleFonts.comicNeue(
                    color: const Color.fromARGB(137, 0, 0, 0),
                    fontSize: 14,
                  ),
                ), // Greyish Text
              ],
            ),
          ),
        ],
      ),
    );
  }
}
