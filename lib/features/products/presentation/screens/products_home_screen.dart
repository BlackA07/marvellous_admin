import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../controller/products_controller.dart';
import 'add_product_screen.dart';
import 'product_detail_screen.dart';
import '../../../layout/controller/layout_controller.dart';

// Widget Imports
import '../widgets/product_stats_card.dart';
import '../widgets/product_filter_bar.dart';
import '../widgets/product_table.dart';

class ProductsHomeScreen extends ConsumerWidget {
  ProductsHomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // FORCE INJECT CONTROLLER: Solves "Controller not found"
    final ProductsController controller = Get.put(ProductsController());

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // Switch to Add Product Screen using Riverpod
          ref
              .read(navigationProvider)
              .navigateTo(
                mainItem: "Products",
                subItem: "Add Product",
                screen: const AddProductScreen(),
                title: "Add Product",
              );
        },
        backgroundColor: Colors.cyanAccent,
        label: Text(
          "Add Product",
          style: GoogleFonts.comicNeue(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        icon: const Icon(Icons.add, color: Colors.black),
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(
            child: CircularProgressIndicator(color: Colors.cyanAccent),
          );
        }

        return LayoutBuilder(
          builder: (context, constraints) {
            bool isDesktop = constraints.maxWidth > 1100;

            return SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // STATS
                  if (isDesktop)
                    Row(
                      children: [
                        Expanded(
                          child: ProductStatsCard(
                            title: "Total Products",
                            value: "${controller.totalProducts}",
                            icon: Icons.inventory,
                            color: Colors.purpleAccent,
                          ),
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          child: ProductStatsCard(
                            title: "Low Stock",
                            value: "${controller.lowStockCount}",
                            icon: Icons.warning,
                            color: Colors.redAccent,
                          ),
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          child: ProductStatsCard(
                            title: "Total Value",
                            value: "\$${controller.totalInventoryValue}",
                            icon: Icons.attach_money,
                            color: Colors.greenAccent,
                          ),
                        ),
                      ],
                    )
                  else
                    GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisSpacing: 15,
                      mainAxisSpacing: 15,
                      childAspectRatio: 1.5,
                      children: [
                        ProductStatsCard(
                          title: "Total Products",
                          value: "${controller.totalProducts}",
                          icon: Icons.inventory,
                          color: Colors.purpleAccent,
                        ),
                        ProductStatsCard(
                          title: "Low Stock",
                          value: "${controller.lowStockCount}",
                          icon: Icons.warning,
                          color: Colors.redAccent,
                        ),
                        ProductStatsCard(
                          title: "Total Value",
                          value: "\$${controller.totalInventoryValue}",
                          icon: Icons.attach_money,
                          color: Colors.greenAccent,
                        ),
                      ],
                    ),

                  const SizedBox(height: 30),
                  ProductFilterBar(onSearch: (val) {}, onFilterTap: () {}),
                  const SizedBox(height: 20),

                  // TABLE
                  ProductTable(
                    products: controller.productList,
                    onEdit: (p) {},
                    onDelete: (id) => controller.deleteProduct(id),
                    onView: (p) {
                      // Detail view can be a full page push
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ProductDetailScreen(product: p),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 80),
                ],
              ),
            );
          },
        );
      }),
    );
  }
}
