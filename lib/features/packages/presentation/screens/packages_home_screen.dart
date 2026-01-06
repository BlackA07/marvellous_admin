import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:marvellous_admin/features/products/controller/products_controller.dart';
import 'package:marvellous_admin/features/products/presentation/widgets/product_stats_card.dart';

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
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Get.to(() => const AddPackageScreen()),
        backgroundColor: Colors.purpleAccent,
        icon: const Icon(Icons.inventory_2, color: Colors.white),
        label: Text(
          "Create Package",
          style: GoogleFonts.comicNeue(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(
            child: CircularProgressIndicator(color: Colors.purpleAccent),
          );
        }

        final packages = controller.packagesOnly;
        double totalValue = packages.fold(
          0,
          (sum, p) => sum + (p.salePrice * p.stockQuantity),
        );

        return Scrollbar(
          controller: _scrollController,
          thumbVisibility: true,
          child: SingleChildScrollView(
            controller: _scrollController,
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Stats Row
                Row(
                  children: [
                    Expanded(
                      child: ProductStatsCard(
                        title: "Total Packages",
                        value: "${packages.length}",
                        icon: Icons.inventory_2,
                        color: Colors.cyanAccent,
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: ProductStatsCard(
                        title: "Inventory Value",
                        value: "PKR $totalValue",
                        icon: Icons.attach_money,
                        color: Colors.greenAccent,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 30),

                Text(
                  "Active Packages",
                  style: GoogleFonts.orbitron(
                    color: Colors.white,
                    fontSize: 20,
                  ),
                ),
                const Divider(color: Colors.white10),

                if (packages.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(40),
                    child: Center(
                      child: Text(
                        "No Packages Found",
                        style: TextStyle(color: Colors.white54),
                      ),
                    ),
                  )
                else
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      headingRowColor: MaterialStateProperty.all(
                        Colors.white10,
                      ),
                      columns: const [
                        DataColumn(
                          label: Text(
                            "Name",
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                        DataColumn(
                          label: Text(
                            "Items",
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                        DataColumn(
                          label: Text(
                            "Price",
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                        DataColumn(
                          label: Text(
                            "Stock",
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                        DataColumn(
                          label: Text(
                            "Actions",
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ],
                      rows: packages.map((pkg) {
                        return DataRow(
                          cells: [
                            DataCell(
                              Text(
                                pkg.name,
                                style: const TextStyle(color: Colors.white),
                              ),
                            ),
                            DataCell(
                              Text(
                                "${pkg.includedItemIds.length} Items",
                                style: const TextStyle(
                                  color: Colors.purpleAccent,
                                ),
                              ),
                            ),
                            DataCell(
                              Text(
                                "PKR ${pkg.salePrice}",
                                style: const TextStyle(
                                  color: Colors.greenAccent,
                                ),
                              ),
                            ),
                            DataCell(
                              Text(
                                "${pkg.stockQuantity}",
                                style: const TextStyle(color: Colors.white),
                              ),
                            ),
                            DataCell(
                              Row(
                                children: [
                                  IconButton(
                                    icon: const Icon(
                                      Icons.visibility,
                                      color: Colors.blue,
                                    ),
                                    onPressed: () => Get.to(
                                      () => PackageDetailScreen(package: pkg),
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.edit,
                                      color: Colors.orange,
                                    ),
                                    onPressed: () => Get.to(
                                      () =>
                                          AddPackageScreen(packageToEdit: pkg),
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.delete,
                                      color: Colors.red,
                                    ),
                                    onPressed: () => controller.deleteProduct(
                                      pkg.id!,
                                      isPackage: true,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
              ],
            ),
          ),
        );
      }),
    );
  }
}
