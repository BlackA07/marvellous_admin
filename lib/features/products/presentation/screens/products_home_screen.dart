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
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
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
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    value,
                    style: GoogleFonts.comicNeue(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  title,
                  style: GoogleFonts.comicNeue(
                    color: Colors.grey,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const Color bgColor = Color(0xFFF5F7FA);
    const Color cardColor = Color.fromARGB(255, 231, 225, 225);
    const Color textColor = Colors.black87;
    const Color accentColor = Colors.cyan;

    return GestureDetector(
      // --- LOGIC CHANGE: Refresh if empty on unfocus ---
      onTap: () {
        FocusScope.of(context).unfocus(); // Hide keyboard

        // If search controller is empty (user cleared it but didn't press enter/search)
        // Refresh the list to show all products
        if (controller.searchQuery.value.isEmpty) {
          controller.updateSearch(""); // Ensures state is clean
          // Optional: trigger a fetch if you want a hard refresh,
          // but usually clearing filter is enough.
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
                        if (isDesktop)
                          Row(
                            children: [
                              Expanded(
                                child: _buildStatCard(
                                  "Total Products",
                                  "${controller.totalProducts}",
                                  Icons.inventory,
                                  Colors.purple,
                                  cardColor,
                                ),
                              ),
                              const SizedBox(width: 20),
                              Expanded(
                                child: _buildStatCard(
                                  "Total Value",
                                  "PKR ${controller.totalInventoryValue.toStringAsFixed(0)}",
                                  Icons.attach_money,
                                  Colors.green,
                                  cardColor,
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
                            childAspectRatio: isMobile ? 1.6 : 2.0,
                            children: [
                              _buildStatCard(
                                "Total Products",
                                "${controller.totalProducts}",
                                Icons.inventory,
                                Colors.purple,
                                cardColor,
                              ),
                              _buildStatCard(
                                "Total Value",
                                "PKR ${controller.totalInventoryValue.toStringAsFixed(0)}",
                                Icons.attach_money,
                                Colors.green,
                                cardColor,
                              ),
                            ],
                          ),

                        const SizedBox(height: 30),

                        Row(
                          children: [
                            Expanded(
                              child: Container(
                                height: 50,
                                decoration: BoxDecoration(
                                  color: cardColor,
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.05),
                                      blurRadius: 5,
                                    ),
                                  ],
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 15,
                                ),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.search,
                                      color: Colors.grey,
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Autocomplete<String>(
                                        optionsBuilder:
                                            (
                                              TextEditingValue textEditingValue,
                                            ) {
                                              controller.updateSearch(
                                                textEditingValue.text,
                                              );

                                              if (textEditingValue.text == '') {
                                                return controller
                                                    .searchHistoryList
                                                    .take(5);
                                              }

                                              return controller
                                                  .searchHistoryList
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
                                          FocusScope.of(context).unfocus();
                                        },
                                        fieldViewBuilder:
                                            (
                                              context,
                                              textController,
                                              focusNode,
                                              onEditingComplete,
                                            ) {
                                              if (textController.text !=
                                                  controller
                                                      .searchQuery
                                                      .value) {
                                                textController.text = controller
                                                    .searchQuery
                                                    .value;
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
                                                autofocus: false,
                                                style: const TextStyle(
                                                  color: Colors.black87,
                                                ),
                                                decoration:
                                                    const InputDecoration(
                                                      hintText:
                                                          "Search products...",
                                                      hintStyle: TextStyle(
                                                        color: Colors.grey,
                                                      ),
                                                      border: InputBorder.none,
                                                    ),
                                              );
                                            },
                                        optionsViewBuilder: (context, onSelected, options) {
                                          return Align(
                                            alignment: Alignment.topLeft,
                                            child: Material(
                                              elevation: 4.0,
                                              color: Colors.white,
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                              child: SizedBox(
                                                width: 400,
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
                                                          dense: true,
                                                          leading: const Icon(
                                                            Icons.history,
                                                            size: 18,
                                                            color: Colors.cyan,
                                                          ),
                                                          title: Text(
                                                            option,
                                                            style:
                                                                const TextStyle(
                                                                  color: Colors
                                                                      .black87,
                                                                ),
                                                            overflow:
                                                                TextOverflow
                                                                    .ellipsis,
                                                            maxLines: 1,
                                                          ),
                                                          onTap: () =>
                                                              onSelected(
                                                                option,
                                                              ),
                                                          trailing: IconButton(
                                                            icon: const Icon(
                                                              Icons.close,
                                                              size: 16,
                                                              color:
                                                                  Colors.grey,
                                                            ),
                                                            onPressed: () {
                                                              controller
                                                                  .removeHistoryItem(
                                                                    option,
                                                                  );
                                                              setState(() {});
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
                                          color: Colors.grey,
                                        ),
                                        onPressed: () {
                                          controller.updateSearch("");
                                          FocusScope.of(context).unfocus();
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
                                  color: cardColor,
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.05),
                                      blurRadius: 5,
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.filter_list,
                                  color: Colors.black87,
                                ),
                              ),
                            ),
                          ],
                        ),

                        if (controller.selectedCategory.value != 'All')
                          Padding(
                            padding: const EdgeInsets.only(top: 10),
                            child: Chip(
                              backgroundColor: Colors.cyan.withOpacity(0.1),
                              label: Text(
                                "Filtered by: ${controller.selectedCategory.value}",
                                style: TextStyle(
                                  color: Colors.cyan.shade800,
                                  fontSize: isMobile ? 12 : 14,
                                ),
                              ),
                              onDeleted: () {
                                controller.updateCategoryFilter('All');
                              },
                              deleteIcon: Icon(
                                Icons.close,
                                color: Colors.cyan.shade800,
                                size: 18,
                              ),
                            ),
                          ),

                        const SizedBox(height: 20),

                        Container(
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
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        "Inventory List",
                                        style: GoogleFonts.orbitron(
                                          color: textColor,
                                          fontSize: isMobile ? 16 : 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      if (controller
                                          .searchHistoryList
                                          .isNotEmpty)
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
                                              backgroundColor: Colors.white,
                                              titleStyle: const TextStyle(
                                                color: Colors.black87,
                                              ),
                                              middleTextStyle: const TextStyle(
                                                color: Colors.grey,
                                              ),
                                            );
                                          },
                                          child: const Text(
                                            "Clear History",
                                            style: TextStyle(
                                              color: Colors.grey,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                                const Divider(color: Colors.grey),

                                if (filteredList.isEmpty)
                                  Expanded(
                                    child: Center(
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.search_off,
                                            size: isMobile ? 40 : 50,
                                            color: Colors.grey.shade300,
                                          ),
                                          const SizedBox(height: 10),
                                          Text(
                                            "No products found",
                                            style: GoogleFonts.comicNeue(
                                              color: Colors.grey,
                                              fontSize: isMobile ? 16 : 18,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  )
                                else
                                  Expanded(
                                    child: SingleChildScrollView(
                                      scrollDirection: Axis.vertical,
                                      child: SingleChildScrollView(
                                        scrollDirection: Axis.horizontal,
                                        child: ConstrainedBox(
                                          constraints: BoxConstraints(
                                            minWidth: constraints.maxWidth,
                                          ),
                                          child: DataTable(
                                            headingRowColor:
                                                MaterialStateProperty.all(
                                                  const Color.fromARGB(
                                                    255,
                                                    216,
                                                    213,
                                                    213,
                                                  ),
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
                                                  "Actions",
                                                  isMobile,
                                                ),
                                              ),
                                            ],
                                            rows: filteredList.map((product) {
                                              bool isPackage =
                                                  product.isPackage;
                                              return DataRow(
                                                cells: [
                                                  DataCell(
                                                    Row(
                                                      children: [
                                                        Container(
                                                          width: isMobile
                                                              ? 35
                                                              : 45,
                                                          height: isMobile
                                                              ? 35
                                                              : 45,
                                                          decoration: BoxDecoration(
                                                            color: Colors
                                                                .grey
                                                                .shade200,
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
                                                                    fit: BoxFit
                                                                        .cover,
                                                                  )
                                                                : null,
                                                          ),
                                                          child:
                                                              product
                                                                  .images
                                                                  .isEmpty
                                                              ? Icon(
                                                                  isPackage
                                                                      ? Icons
                                                                            .inventory_2
                                                                      : Icons
                                                                            .image,
                                                                  color: Colors
                                                                      .grey,
                                                                  size: isMobile
                                                                      ? 16
                                                                      : 20,
                                                                )
                                                              : null,
                                                        ),
                                                        const SizedBox(
                                                          width: 15,
                                                        ),
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
                                                                          right:
                                                                              5,
                                                                        ),
                                                                    padding: const EdgeInsets.symmetric(
                                                                      horizontal:
                                                                          4,
                                                                      vertical:
                                                                          2,
                                                                    ),
                                                                    decoration: BoxDecoration(
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
                                                                        fontSize:
                                                                            8,
                                                                        color: Colors
                                                                            .white,
                                                                        fontWeight:
                                                                            FontWeight.bold,
                                                                      ),
                                                                    ),
                                                                  ),
                                                                SizedBox(
                                                                  width: 120,
                                                                  child: Text(
                                                                    product
                                                                        .name,
                                                                    overflow:
                                                                        TextOverflow
                                                                            .ellipsis,
                                                                    style: GoogleFonts.comicNeue(
                                                                      color: Colors
                                                                          .black87,
                                                                      fontWeight:
                                                                          FontWeight
                                                                              .bold,
                                                                      fontSize:
                                                                          isMobile
                                                                          ? 13
                                                                          : 15,
                                                                    ),
                                                                  ),
                                                                ),
                                                              ],
                                                            ),
                                                            Text(
                                                              product
                                                                  .modelNumber,
                                                              style:
                                                                  GoogleFonts.comicNeue(
                                                                    color: Colors
                                                                        .grey,
                                                                    fontSize:
                                                                        isMobile
                                                                        ? 10
                                                                        : 12,
                                                                  ),
                                                            ),
                                                          ],
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                  DataCell(
                                                    Text(
                                                      product.category,
                                                      style: TextStyle(
                                                        color: Colors.black87,
                                                        fontSize: isMobile
                                                            ? 12
                                                            : 14,
                                                      ),
                                                    ),
                                                  ),
                                                  DataCell(
                                                    Text(
                                                      "PKR ${product.salePrice}",
                                                      style:
                                                          GoogleFonts.comicNeue(
                                                            color: Colors
                                                                .green
                                                                .shade700,
                                                            fontWeight:
                                                                FontWeight.bold,
                                                            fontSize: isMobile
                                                                ? 12
                                                                : 14,
                                                          ),
                                                    ),
                                                  ),
                                                  DataCell(
                                                    Row(
                                                      children: [
                                                        IconButton(
                                                          icon: Icon(
                                                            Icons.visibility,
                                                            color: Colors
                                                                .blueAccent,
                                                            size: isMobile
                                                                ? 18
                                                                : 20,
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
                                                            color: Colors
                                                                .orangeAccent,
                                                            size: isMobile
                                                                ? 18
                                                                : 20,
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
                                                                  screen: AddProductScreen(
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
                                                            color: Colors
                                                                .redAccent,
                                                            size: isMobile
                                                                ? 18
                                                                : 20,
                                                          ),
                                                          onPressed: () =>
                                                              _deleteProduct(
                                                                product,
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
                                      ),
                                    ),
                                  ),
                              ],
                            ),
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
      ),
    );
  }

  Widget _tableHeader(String text, bool isMobile) {
    return Text(
      text,
      style: GoogleFonts.comicNeue(
        color: Colors.grey.shade700,
        fontWeight: FontWeight.bold,
        fontSize: isMobile ? 12 : 14,
      ),
    );
  }
}
