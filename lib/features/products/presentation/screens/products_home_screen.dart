import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

// Controller & Model
import '../../controller/products_controller.dart';
import '../../models/product_model.dart';

// SCREEN IMPORTS
import 'add_product_screen.dart';
import '../../components/product_stats_section.dart'; // New Component
import '../../components/product_search_bar.dart'; // New Component
import '../../components/product_inventory_table.dart'; // New Component

// Layout Controller for Navigation
import '../../../layout/controller/layout_controller.dart';

class ProductsHomeScreen extends ConsumerStatefulWidget {
  const ProductsHomeScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<ProductsHomeScreen> createState() => _ProductsHomeScreenState();
}

class _ProductsHomeScreenState extends ConsumerState<ProductsHomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  // Controller yahan initialize ho raha hai, jese apne kaha tha
  final ProductsController controller = Get.put(ProductsController());

  @override
  void initState() {
    super.initState();
    controller.fetchHistory();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // Delete Logic yahan rakhi hai taake centralized rahe
  void _deleteProduct(ProductModel product) {
    Get.defaultDialog(
      title: "Delete Product?",
      titleStyle: GoogleFonts.comicNeue(fontWeight: FontWeight.bold),
      middleText: "Are you sure you want to delete ${product.name}?",
      textConfirm: "Delete",
      textCancel: "Cancel",
      confirmTextColor: const Color.fromARGB(255, 255, 255, 255),
      buttonColor: Colors.redAccent,
      backgroundColor: const Color.fromARGB(255, 0, 0, 0),
      onConfirm: () async {
        Get.back();
        await controller.deleteProduct(product.id!, isPackage: false);
        Get.snackbar(
          "Deleted",
          "${product.name} has been removed.",
          mainButton: TextButton(
            onPressed: () {
              controller.addNewProduct(product);
              Get.back();
            },
            child: const Text("UNDO", style: TextStyle(color: Colors.yellow)),
          ),
          backgroundColor: Colors.black87,
          colorText: Colors.white,
          duration: const Duration(seconds: 4),
          snackPosition: SnackPosition.TOP,
          margin: const EdgeInsets.all(20),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    const Color bgColor = Color(0xFFF5F7FA);
    const Color accentColor = Colors.cyan;

    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
        if (controller.searchQuery.value.isEmpty) {
          controller.updateSearch("");
        }
      },
      child: Scaffold(
        backgroundColor: bgColor,
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () {
            ref
                .read(navigationProvider)
                .navigateTo(
                  mainItem: "Products",
                  subItem: "Add Product",
                  screen: const AddProductScreen(),
                  title: "Add Product",
                );
          },
          backgroundColor: accentColor,
          label: Text(
            "Add Product",
            style: GoogleFonts.comicNeue(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          icon: const Icon(Icons.add, color: Colors.white),
        ),
        body: RefreshIndicator(
          color: accentColor,
          backgroundColor: Colors.white,
          onRefresh: () async {
            _searchController.clear();
            controller.updateSearch("");
            controller.clearAllFilters();
            controller.fetchProducts();
            await Future.delayed(const Duration(seconds: 1));
          },
          child: Obx(() {
            if (controller.isLoading.value) {
              return const Center(
                child: CircularProgressIndicator(color: accentColor),
              );
            }

            return LayoutBuilder(
              builder: (context, constraints) {
                bool isDesktop = constraints.maxWidth > 1100;
                bool isMobile = constraints.maxWidth < 800;

                final products = controller.productsOnly;

                // Filtering Logic (Same as before)
                final filteredList = products.where((product) {
                  String search = controller.searchQuery.value.toLowerCase();
                  bool matchesSearch =
                      search.isEmpty ||
                      product.name.toLowerCase().contains(search) ||
                      product.modelNumber.toLowerCase().contains(search) ||
                      product.category.toLowerCase().contains(search);

                  bool matchesCategory =
                      controller.selectedCategory.value == 'All' ||
                      product.category == controller.selectedCategory.value;

                  return matchesSearch && matchesCategory;
                }).toList();

                return Scrollbar(
                  controller: _scrollController,
                  thumbVisibility: true,
                  trackVisibility: true,
                  thickness: 8,
                  radius: const Radius.circular(10),
                  child: SingleChildScrollView(
                    controller: _scrollController,
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.only(
                      top: 6,
                      left: 10,
                      right: 10,
                      bottom: 20,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 1. STATS SECTION
                        ProductStatsSection(
                          controller: controller,
                          isDesktop: isDesktop,
                          isMobile: isMobile,
                        ),

                        const SizedBox(height: 30),

                        // 2. SEARCH BAR & FILTER SECTION
                        ProductSearchBar(
                          controller: controller,
                          isMobile: isMobile,
                        ),

                        const SizedBox(height: 20),

                        // 3. INVENTORY TABLE SECTION
                        ProductInventoryTable(
                          filteredList: filteredList,
                          controller: controller,
                          isMobile: isMobile,
                          constraints: constraints,
                          onDelete: _deleteProduct, // Callback passed here
                        ),

                        const SizedBox(height: 80),
                      ],
                    ),
                  ),
                );
              },
            );
          }),
        ),
      ),
    );
  }
}
