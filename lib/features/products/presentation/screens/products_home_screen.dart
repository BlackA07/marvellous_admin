import 'dart:convert'; // For Base64 Decoding
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

// Controller & Model
import '../../controller/products_controller.dart';
import '../../models/product_model.dart';

// SCREEN IMPORTS
import 'add_product_screen.dart';
import 'product_detail_screen.dart';
import '../widgets/product_filter_dialog.dart';

// Layout Controller
import '../../../layout/controller/layout_controller.dart';

// Widgets
import '../widgets/product_stats_card.dart';

class ProductsHomeScreen extends ConsumerStatefulWidget {
  const ProductsHomeScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<ProductsHomeScreen> createState() => _ProductsHomeScreenState();
}

class _ProductsHomeScreenState extends ConsumerState<ProductsHomeScreen> {
  // Controller for handling search text
  final TextEditingController _searchController = TextEditingController();

  // Scroll Controller
  final ScrollController _scrollController = ScrollController();

  // GetX Controller injection
  final ProductsController controller = Get.put(ProductsController());

  @override
  void initState() {
    super.initState();
    // Refresh history on load
    controller.fetchHistory();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
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

      // Refresh Indicator Implementation
      body: RefreshIndicator(
        color: Colors.cyanAccent,
        backgroundColor: const Color(0xFF2A2D3E),
        onRefresh: () async {
          _searchController.clear();
          controller.updateSearch("");
          controller.clearAllFilters();
          controller.onInit();
        },
        child: Obx(() {
          if (controller.isLoading.value) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.cyanAccent),
            );
          }

          return LayoutBuilder(
            builder: (context, constraints) {
              // Responsive Breakpoints
              bool isDesktop = constraints.maxWidth > 1100;
              bool isMobile = constraints.maxWidth < 800; // Mobile check

              return Scrollbar(
                controller: _scrollController,
                thumbVisibility: true,
                trackVisibility: true,
                child: SingleChildScrollView(
                  controller: _scrollController,
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 1. STATS SECTION
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
                                // Updated to PKR
                                value: "PKR ${controller.totalInventoryValue}",
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
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                          childAspectRatio: isMobile ? 1.1 : 1.5,
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
                              // Updated to PKR
                              value: "PKR ${controller.totalInventoryValue}",
                              icon: Icons.attach_money,
                              color: Colors.greenAccent,
                            ),
                          ],
                        ),

                      const SizedBox(height: 30),

                      // 2. CUSTOM SEARCH BAR WITH HISTORY
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              height: 50,
                              decoration: BoxDecoration(
                                color: const Color(0xFF2A2D3E),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.white10),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 15,
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.search,
                                    color: Colors.white54,
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Autocomplete<String>(
                                      optionsBuilder:
                                          (TextEditingValue textEditingValue) {
                                            controller.updateSearch(
                                              textEditingValue.text,
                                            );

                                            if (textEditingValue.text == '') {
                                              return controller
                                                  .searchHistoryList
                                                  .take(5);
                                            }

                                            return controller.searchHistoryList
                                                .where((String option) {
                                                  return option
                                                      .toLowerCase()
                                                      .contains(
                                                        textEditingValue.text
                                                            .toLowerCase(),
                                                      );
                                                });
                                          },
                                      onSelected: (String selection) {
                                        controller.updateSearch(selection);
                                        controller.addToHistory(selection);
                                      },
                                      fieldViewBuilder:
                                          (
                                            context,
                                            textController,
                                            focusNode,
                                            onEditingComplete,
                                          ) {
                                            if (textController.text !=
                                                controller.searchQuery.value) {
                                              textController.text =
                                                  controller.searchQuery.value;
                                              textController.selection =
                                                  TextSelection.fromPosition(
                                                    TextPosition(
                                                      offset: textController
                                                          .text
                                                          .length,
                                                    ),
                                                  );
                                            }

                                            return TextField(
                                              controller: textController,
                                              focusNode: focusNode,
                                              onEditingComplete:
                                                  onEditingComplete,
                                              onChanged: (val) {
                                                controller.updateSearch(val);
                                              },
                                              style: const TextStyle(
                                                color: Colors.white,
                                              ),
                                              decoration: const InputDecoration(
                                                hintText:
                                                    "Search products (History enabled)...",
                                                hintStyle: TextStyle(
                                                  color: Colors.white24,
                                                ),
                                                border: InputBorder.none,
                                              ),
                                            );
                                          },
                                      optionsViewBuilder:
                                          (context, onSelected, options) {
                                            return Align(
                                              alignment: Alignment.topLeft,
                                              child: Material(
                                                elevation: 4.0,
                                                color: const Color(0xFF1E1E2C),
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                                child: SizedBox(
                                                  width: 300,
                                                  child: ListView.builder(
                                                    padding: EdgeInsets.zero,
                                                    shrinkWrap: true,
                                                    itemCount: options.length,
                                                    itemBuilder:
                                                        (
                                                          BuildContext context,
                                                          int index,
                                                        ) {
                                                          final String option =
                                                              options.elementAt(
                                                                index,
                                                              );
                                                          return ListTile(
                                                            leading: const Icon(
                                                              Icons.history,
                                                              size: 18,
                                                              color: Colors
                                                                  .cyanAccent,
                                                            ),
                                                            title: Text(
                                                              option,
                                                              style:
                                                                  const TextStyle(
                                                                    color: Colors
                                                                        .white,
                                                                  ),
                                                            ),
                                                            onTap: () =>
                                                                onSelected(
                                                                  option,
                                                                ),
                                                            trailing: IconButton(
                                                              icon: const Icon(
                                                                Icons.close,
                                                                size: 16,
                                                                color: Colors
                                                                    .white24,
                                                              ),
                                                              onPressed: () {
                                                                controller
                                                                    .removeHistoryItem(
                                                                      option,
                                                                    );
                                                              },
                                                            ),
                                                          );
                                                        },
                                                  ),
                                                ),
                                              ),
                                            );
                                          },
                                    ),
                                  ),
                                  if (controller.searchQuery.isNotEmpty)
                                    IconButton(
                                      icon: const Icon(
                                        Icons.close,
                                        color: Colors.white54,
                                      ),
                                      onPressed: () {
                                        controller.updateSearch("");
                                      },
                                    ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 15),
                          InkWell(
                            onTap: () {
                              showDialog(
                                context: context,
                                builder: (_) => ProductFilterDialog(),
                              );
                            },
                            child: Container(
                              height: 50,
                              width: 50,
                              decoration: BoxDecoration(
                                color: const Color(0xFF2A2D3E),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.white10),
                              ),
                              child: const Icon(
                                Icons.filter_list,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),

                      if (controller.selectedCategory.value != 'All')
                        Padding(
                          padding: const EdgeInsets.only(top: 10),
                          child: Chip(
                            backgroundColor: Colors.cyanAccent.withOpacity(0.2),
                            label: Text(
                              "Filtered by: ${controller.selectedCategory.value}",
                              style: TextStyle(
                                color: Colors.cyanAccent,
                                fontSize: isMobile ? 12 : 14,
                              ),
                            ),
                            onDeleted: () {
                              controller.updateCategoryFilter('All');
                            },
                            deleteIcon: const Icon(
                              Icons.close,
                              color: Colors.cyanAccent,
                              size: 18,
                            ),
                          ),
                        ),

                      const SizedBox(height: 20),

                      // 3. PRODUCT TABLE
                      Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFF2A2D3E),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white10),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(15.0),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    "Inventory List",
                                    style: GoogleFonts.orbitron(
                                      color: Colors.white,
                                      fontSize: isMobile ? 16 : 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  if (controller.searchHistoryList.isNotEmpty)
                                    TextButton(
                                      onPressed: () {
                                        Get.defaultDialog(
                                          title: "Clear History",
                                          middleText:
                                              "Delete all search history?",
                                          onConfirm: () {
                                            controller.clearAllHistory();
                                            Get.back();
                                          },
                                          textConfirm: "Yes",
                                          textCancel: "No",
                                          buttonColor: Colors.redAccent,
                                          backgroundColor: const Color(
                                            0xFF1E1E2C,
                                          ),
                                          titleStyle: const TextStyle(
                                            color: Colors.white,
                                          ),
                                          middleTextStyle: const TextStyle(
                                            color: Colors.white70,
                                          ),
                                        );
                                      },
                                      child: const Text(
                                        "Clear History",
                                        style: TextStyle(
                                          color: Colors.white54,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            const Divider(color: Colors.white10),

                            if (controller.filteredProducts.isEmpty)
                              Padding(
                                padding: const EdgeInsets.all(40.0),
                                child: Center(
                                  child: Column(
                                    children: [
                                      Icon(
                                        Icons.search_off,
                                        size: isMobile ? 40 : 50,
                                        color: Colors.white24,
                                      ),
                                      const SizedBox(height: 10),
                                      Text(
                                        "No products found",
                                        style: GoogleFonts.comicNeue(
                                          color: Colors.white54,
                                          fontSize: isMobile ? 16 : 18,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              )
                            else
                              Scrollbar(
                                thumbVisibility: true,
                                trackVisibility: true,
                                child: SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  physics: const BouncingScrollPhysics(),
                                  child: ConstrainedBox(
                                    constraints: BoxConstraints(
                                      minWidth: constraints.maxWidth,
                                    ),
                                    child: DataTable(
                                      headingRowColor:
                                          MaterialStateProperty.all(
                                            Colors.white.withOpacity(0.05),
                                          ),
                                      dataRowHeight: isMobile ? 60 : 70,
                                      columnSpacing: isMobile ? 20 : 56,
                                      columns: [
                                        DataColumn(
                                          label: _tableHeader(
                                            "Product",
                                            isMobile,
                                          ),
                                        ),
                                        DataColumn(
                                          label: _tableHeader(
                                            "Category",
                                            isMobile,
                                          ),
                                        ),
                                        DataColumn(
                                          label: _tableHeader(
                                            "Price",
                                            isMobile,
                                          ),
                                        ),
                                        DataColumn(
                                          label: _tableHeader(
                                            "Stock",
                                            isMobile,
                                          ),
                                        ),
                                        DataColumn(
                                          label: _tableHeader(
                                            "Actions",
                                            isMobile,
                                          ),
                                        ),
                                      ],
                                      rows: controller.filteredProducts.map((
                                        product,
                                      ) {
                                        bool isPackage = product.isPackage;
                                        return DataRow(
                                          cells: [
                                            // Image & Name
                                            DataCell(
                                              Row(
                                                children: [
                                                  Container(
                                                    width: isMobile ? 35 : 45,
                                                    height: isMobile ? 35 : 45,
                                                    decoration: BoxDecoration(
                                                      color: Colors.grey[800],
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            8,
                                                          ),
                                                      image:
                                                          product
                                                              .images
                                                              .isNotEmpty
                                                          ? DecorationImage(
                                                              image: MemoryImage(
                                                                base64Decode(
                                                                  product
                                                                      .images
                                                                      .first,
                                                                ),
                                                              ),
                                                              fit: BoxFit.cover,
                                                            )
                                                          : null,
                                                    ),
                                                    child:
                                                        product.images.isEmpty
                                                        ? Icon(
                                                            isPackage
                                                                ? Icons
                                                                      .inventory_2
                                                                : Icons.image,
                                                            color:
                                                                Colors.white54,
                                                            size: isMobile
                                                                ? 16
                                                                : 20,
                                                          )
                                                        : null,
                                                  ),
                                                  const SizedBox(width: 15),
                                                  Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .center,
                                                    children: [
                                                      Row(
                                                        children: [
                                                          if (isPackage)
                                                            Container(
                                                              margin:
                                                                  const EdgeInsets.only(
                                                                    right: 5,
                                                                  ),
                                                              padding:
                                                                  const EdgeInsets.symmetric(
                                                                    horizontal:
                                                                        4,
                                                                    vertical: 2,
                                                                  ),
                                                              decoration:
                                                                  BoxDecoration(
                                                                    color: Colors
                                                                        .purple,
                                                                    borderRadius:
                                                                        BorderRadius.circular(
                                                                          4,
                                                                        ),
                                                                  ),
                                                              child: const Text(
                                                                "PKG",
                                                                style: TextStyle(
                                                                  fontSize: 8,
                                                                  color: Colors
                                                                      .white,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .bold,
                                                                ),
                                                              ),
                                                            ),
                                                          Text(
                                                            product.name,
                                                            style:
                                                                GoogleFonts.comicNeue(
                                                                  color: Colors
                                                                      .white,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .bold,
                                                                  fontSize:
                                                                      isMobile
                                                                      ? 13
                                                                      : 15,
                                                                ),
                                                          ),
                                                        ],
                                                      ),
                                                      Text(
                                                        product.modelNumber,
                                                        style:
                                                            GoogleFonts.comicNeue(
                                                              color: Colors
                                                                  .white54,
                                                              fontSize: isMobile
                                                                  ? 10
                                                                  : 12,
                                                            ),
                                                      ),
                                                    ],
                                                  ),
                                                ],
                                              ),
                                            ),
                                            // Category
                                            DataCell(
                                              Text(
                                                product.category,
                                                style: TextStyle(
                                                  color: Colors.white70,
                                                  fontSize: isMobile ? 12 : 14,
                                                ),
                                              ),
                                            ),
                                            // Price (UPDATED: PKR + Font + No Overflow)
                                            DataCell(
                                              FittedBox(
                                                fit: BoxFit.scaleDown,
                                                child: Text(
                                                  "PKR ${product.salePrice}",
                                                  style: GoogleFonts.comicNeue(
                                                    color: Colors.cyanAccent,
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: isMobile
                                                        ? 12
                                                        : 14,
                                                  ),
                                                ),
                                              ),
                                            ),
                                            // Stock
                                            DataCell(
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 10,
                                                      vertical: 5,
                                                    ),
                                                decoration: BoxDecoration(
                                                  color:
                                                      product.stockQuantity < 10
                                                      ? Colors.red.withOpacity(
                                                          0.2,
                                                        )
                                                      : Colors.green
                                                            .withOpacity(0.2),
                                                  borderRadius:
                                                      BorderRadius.circular(20),
                                                  border: Border.all(
                                                    color:
                                                        product.stockQuantity <
                                                            10
                                                        ? Colors.redAccent
                                                        : Colors.greenAccent,
                                                    width: 0.5,
                                                  ),
                                                ),
                                                child: Text(
                                                  "${product.stockQuantity}",
                                                  style: TextStyle(
                                                    color:
                                                        product.stockQuantity <
                                                            10
                                                        ? Colors.redAccent
                                                        : Colors.greenAccent,
                                                    fontSize: isMobile
                                                        ? 10
                                                        : 12,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                            ),
                                            // Actions
                                            DataCell(
                                              Row(
                                                children: [
                                                  IconButton(
                                                    icon: Icon(
                                                      Icons.visibility,
                                                      color: Colors.blueAccent,
                                                      size: isMobile ? 18 : 20,
                                                    ),
                                                    onPressed: () {
                                                      Navigator.push(
                                                        context,
                                                        MaterialPageRoute(
                                                          builder: (_) =>
                                                              ProductDetailScreen(
                                                                product:
                                                                    product,
                                                              ),
                                                        ),
                                                      );
                                                    },
                                                  ),
                                                  IconButton(
                                                    icon: Icon(
                                                      Icons.edit,
                                                      color:
                                                          Colors.orangeAccent,
                                                      size: isMobile ? 18 : 20,
                                                    ),
                                                    onPressed: () {
                                                      ref
                                                          .read(
                                                            navigationProvider,
                                                          )
                                                          .navigateTo(
                                                            mainItem:
                                                                "Products",
                                                            subItem:
                                                                "Add Product",
                                                            screen:
                                                                AddProductScreen(
                                                                  productToEdit:
                                                                      product,
                                                                ),
                                                            title:
                                                                "Edit Product",
                                                          );
                                                    },
                                                  ),
                                                  IconButton(
                                                    icon: Icon(
                                                      Icons.delete,
                                                      color: Colors.redAccent,
                                                      size: isMobile ? 18 : 20,
                                                    ),
                                                    onPressed: () {
                                                      Get.defaultDialog(
                                                        title:
                                                            "Delete Product?",
                                                        titleStyle:
                                                            GoogleFonts.orbitron(
                                                              color:
                                                                  Colors.white,
                                                              fontSize: 16,
                                                            ),
                                                        backgroundColor:
                                                            const Color(
                                                              0xFF2A2D3E,
                                                            ),
                                                        middleText:
                                                            "Are you sure you want to delete ${product.name}?",
                                                        middleTextStyle:
                                                            const TextStyle(
                                                              color: Colors
                                                                  .white70,
                                                            ),
                                                        textConfirm: "Delete",
                                                        textCancel: "Cancel",
                                                        confirmTextColor:
                                                            Colors.white,
                                                        buttonColor:
                                                            Colors.redAccent,
                                                        onConfirm: () {
                                                          if (product.id !=
                                                              null) {
                                                            controller
                                                                .deleteProduct(
                                                                  product.id!,
                                                                );
                                                          }
                                                          Get.back();
                                                        },
                                                      );
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
                          ],
                        ),
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
    );
  }

  Widget _tableHeader(String text, bool isMobile) {
    return Text(
      text,
      style: GoogleFonts.comicNeue(
        color: Colors.white54,
        fontWeight: FontWeight.bold,
        fontSize: isMobile ? 12 : 14,
      ),
    );
  }
}
