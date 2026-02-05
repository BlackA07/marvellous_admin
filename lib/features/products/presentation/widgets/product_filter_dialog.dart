import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../controller/products_controller.dart';

class ProductFilterDialog extends StatelessWidget {
  final ProductsController controller = Get.find();

  ProductFilterDialog({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isSmall = MediaQuery.of(context).size.width < 600;

    // Local state for dialog
    final RxString localCategory = controller.selectedCategory.value.obs;
    final RxString localSubCategory = controller.selectedSubCategory.value.obs;

    return Dialog(
      backgroundColor: const Color(0xFF2A2D3E),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Obx(() {
          // Get subcategories based on selected category
          final subCategories = {
            'All',
            ...controller.productList
                .where(
                  (p) =>
                      localCategory.value == 'All' ||
                      p.category == localCategory.value,
                )
                .map((p) => p.subCategory)
                .where((e) => e.isNotEmpty),
          }.toList();

          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Filter Products",
                    style: GoogleFonts.orbitron(
                      color: Colors.white,
                      fontSize: 20,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Get.back(),
                    icon: const Icon(Icons.close, color: Colors.white54),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // --- CATEGORY SECTION ---
              Text(
                "Category",
                style: GoogleFonts.comicNeue(
                  color: Colors.cyanAccent,
                  fontSize: 18,
                ),
              ),

              const SizedBox(height: 10),

              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: controller.availableCategories.map((cat) {
                  final selected = localCategory.value == cat;
                  return ChoiceChip(
                    label: Text(
                      cat,
                      style: TextStyle(fontSize: isSmall ? 12 : 14),
                    ),
                    selected: selected,
                    selectedColor: Colors.orangeAccent,
                    onSelected: (_) {
                      localCategory.value = cat;
                      localSubCategory.value = 'All'; // Reset subcategory
                    },
                  );
                }).toList(),
              ),

              const SizedBox(height: 20),

              // --- SUBCATEGORY SECTION ---
              Text(
                "Sub Category",
                style: GoogleFonts.comicNeue(
                  color: Colors.cyanAccent,
                  fontSize: 18,
                ),
              ),

              const SizedBox(height: 10),

              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: subCategories.map((sub) {
                  final selected = localSubCategory.value == sub;
                  return ChoiceChip(
                    label: Text(
                      sub,
                      style: TextStyle(fontSize: isSmall ? 12 : 14),
                    ),
                    selected: selected,
                    selectedColor: Colors.redAccent,
                    onSelected: (_) {
                      localSubCategory.value = sub;
                    },
                  );
                }).toList(),
              ),

              const SizedBox(height: 25),

              // --- ACTION BUTTONS ---
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        controller.clearAllFilters();
                        localCategory.value = 'All';
                        localSubCategory.value = 'All';
                        Get.back();
                      },
                      child: const Text(
                        "Clear Filters",
                        style: TextStyle(color: Colors.redAccent),
                      ),
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        // ✅ FIXED: Properly set both filters
                        controller.updateCategoryFilter(localCategory.value);
                        controller.updateSubCategoryFilter(
                          localSubCategory.value,
                        );
                        Get.back();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.cyanAccent,
                      ),
                      child: const Text(
                        "Apply",
                        style: TextStyle(color: Colors.black),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          );
        }),
      ),
    );
  }
}
