import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../presentation/widgets/product_filter_dialog.dart';
import '../controller/products_controller.dart';

class ProductSearchBar extends StatefulWidget {
  final ProductsController controller;
  final bool isMobile;

  const ProductSearchBar({
    Key? key,
    required this.controller,
    required this.isMobile,
  }) : super(key: key);

  @override
  State<ProductSearchBar> createState() => _ProductSearchBarState();
}

class _ProductSearchBarState extends State<ProductSearchBar> {
  late TextEditingController _searchCtrl;

  @override
  void initState() {
    super.initState();
    _searchCtrl = TextEditingController(
      text: widget.controller.searchQuery.value,
    );
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const cardColor = Color.fromARGB(255, 231, 225, 225);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Container(
                height: 50,
                padding: const EdgeInsets.symmetric(horizontal: 15),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.search, color: Colors.black),
                    const SizedBox(width: 10),
                    Expanded(
                      // ✅ FAST INSTANT SEARCH: Autocomplete hata diya gaya hai
                      child: TextField(
                        controller: _searchCtrl,
                        style: GoogleFonts.comicNeue(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                        decoration: InputDecoration(
                          hintText: "Search products by name, model, brand...",
                          hintStyle: GoogleFonts.comicNeue(
                            color: Colors.black54,
                          ),
                          border: InputBorder.none,
                        ),
                        onChanged: (val) {
                          widget.controller.updateSearch(val);
                        },
                      ),
                    ),
                    Obx(() {
                      return widget.controller.searchQuery.value.isNotEmpty
                          ? IconButton(
                              icon: const Icon(
                                Icons.close,
                                color: Colors.black,
                              ),
                              onPressed: () {
                                _searchCtrl.clear();
                                widget.controller.updateSearch('');
                                FocusScope.of(context).unfocus();
                              },
                            )
                          : const SizedBox();
                    }),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 15),
            // --- FILTER BUTTON ---
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
                ),
                child: const Icon(Icons.filter_list, color: Colors.black),
              ),
            ),
            const SizedBox(width: 15),
            // --- REFRESH BUTTON ---
            InkWell(
              onTap: () async {
                _searchCtrl.clear();
                widget.controller.updateSearch('');
                widget.controller.clearAllFilters();
                widget.controller.fetchProducts();
                Get.snackbar(
                  "Refreshed",
                  "Product list & Stock updated",
                  backgroundColor: Colors.green,
                  colorText: Colors.white,
                  duration: const Duration(seconds: 2),
                  snackPosition: SnackPosition.TOP,
                );
              },
              child: Container(
                height: 50,
                width: 50,
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.refresh, color: Colors.black),
              ),
            ),
          ],
        ),

        // --- ACTIVE FILTER CHIPS ---
        Obx(() {
          bool hasFilters =
              widget.controller.selectedCategory.value != 'All' ||
              widget.controller.selectedSubCategory.value != 'All';

          if (!hasFilters) return const SizedBox();

          return Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (widget.controller.selectedCategory.value != 'All')
                  Chip(
                    label: Text(widget.controller.selectedCategory.value),
                    deleteIcon: const Icon(Icons.close, size: 16),
                    onDeleted: () =>
                        widget.controller.updateCategoryFilter('All'),
                    backgroundColor: Colors.orange.shade100,
                  ),
                if (widget.controller.selectedSubCategory.value != 'All')
                  Chip(
                    label: Text(widget.controller.selectedSubCategory.value),
                    deleteIcon: const Icon(Icons.close, size: 16),
                    onDeleted: () =>
                        widget.controller.updateSubCategoryFilter('All'),
                    backgroundColor: Colors.red.shade100,
                  ),
              ],
            ),
          );
        }),
      ],
    );
  }
}
