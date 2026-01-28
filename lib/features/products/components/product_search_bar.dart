import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../presentation/widgets/product_filter_dialog.dart';
import '../controller/products_controller.dart';

class ProductSearchBar extends StatelessWidget {
  final ProductsController controller;
  final bool isMobile;

  const ProductSearchBar({
    Key? key,
    required this.controller,
    required this.isMobile,
  }) : super(key: key);

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
                      child: Autocomplete<String>(
                        optionsBuilder: (value) {
                          if (value.text.isEmpty) {
                            return controller.searchHistoryList.reversed;
                          }
                          return controller.searchHistoryList.where(
                            (e) => e.toLowerCase().contains(
                              value.text.toLowerCase(),
                            ),
                          );
                        },
                        onSelected: (val) {
                          controller.updateSearch(val);
                          controller.addToHistory(val);
                        },
                        fieldViewBuilder: (context, textCtrl, focus, _) {
                          textCtrl.text = controller.searchQuery.value;
                          textCtrl.selection = TextSelection.fromPosition(
                            TextPosition(offset: textCtrl.text.length),
                          );

                          return TextField(
                            controller: textCtrl,
                            focusNode: focus,
                            style: const TextStyle(color: Colors.black),
                            decoration: const InputDecoration(
                              hintText: "Search products...",
                              hintStyle: TextStyle(color: Colors.black54),
                              border: InputBorder.none,
                            ),
                            onChanged: controller.updateSearch,
                            onSubmitted: (val) {
                              if (val.trim().isNotEmpty) {
                                controller.addToHistory(val);
                              }
                            },
                          );
                        },
                        optionsViewBuilder: (context, onSelect, options) {
                          return Material(
                            elevation: 4,
                            borderRadius: BorderRadius.circular(8),
                            child: ListView(
                              shrinkWrap: true,
                              children: options.map((e) {
                                return ListTile(
                                  dense: true,
                                  title: Text(
                                    e,
                                    style: const TextStyle(
                                      color: Color.fromARGB(255, 255, 255, 255),
                                    ),
                                  ),
                                  trailing: IconButton(
                                    icon: const Icon(Icons.close, size: 16),
                                    onPressed: () {
                                      controller.removeHistoryItem(e);
                                    },
                                  ),
                                  onTap: () => onSelect(e),
                                );
                              }).toList(),
                            ),
                          );
                        },
                      ),
                    ),
                    Obx(() {
                      return controller.searchQuery.value.isNotEmpty
                          ? IconButton(
                              icon: const Icon(
                                Icons.close,
                                color: Colors.black,
                              ),
                              onPressed: () {
                                controller.updateSearch('');
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
          ],
        ),

        Obx(() {
          if (controller.selectedCategory.value == 'All') {
            return const SizedBox();
          }

          return Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Chip(
              label: Text(controller.selectedCategory.value),
              onDeleted: () => controller.updateCategoryFilter('All'),
            ),
          );
        }),
      ],
    );
  }
}
