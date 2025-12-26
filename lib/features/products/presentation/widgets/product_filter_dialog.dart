import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../controller/products_controller.dart';

class ProductFilterDialog extends StatelessWidget {
  final ProductsController controller = Get.find();

  // Local variable for Stock (since we are mimicking it for now)
  final RxString _localStockFilter = "All Stock".obs;

  ProductFilterDialog({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF2A2D3E),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: Colors.white10),
      ),
      child: Container(
        padding: const EdgeInsets.all(20),
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Filter Products",
                  style: GoogleFonts.orbitron(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  onPressed: () => Get.back(),
                  icon: const Icon(Icons.close, color: Colors.white54),
                ),
              ],
            ),
            const Divider(color: Colors.white24, height: 30),

            // Section 1: By Category
            Text(
              "By Category",
              style: GoogleFonts.comicNeue(
                color: Colors.cyanAccent,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 15),

            // Categories Chips
            Obx(() {
              return Wrap(
                spacing: 10,
                runSpacing: 10,
                children: controller.availableCategories.map((cat) {
                  // Real-time check
                  bool isSelected = controller.selectedCategory.value == cat;
                  return ChoiceChip(
                    label: Text(cat),
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.black : Colors.white70,
                      fontWeight: FontWeight.bold,
                    ),
                    selected: isSelected,
                    selectedColor: Colors.cyanAccent,
                    backgroundColor: Colors.white.withOpacity(0.05),
                    onSelected: (bool selected) {
                      // INSTANT UPDATE LOGIC:
                      // Yahan select karte hi controller update hoga aur background men list change ho jayegi
                      controller.updateCategoryFilter(selected ? cat : 'All');
                    },
                  );
                }).toList(),
              );
            }),

            const SizedBox(height: 25),

            // Section 2: Stock Status
            Text(
              "Stock Status",
              style: GoogleFonts.comicNeue(
                color: Colors.cyanAccent,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 15),

            // Stock Status Chips
            Obx(() {
              return Wrap(
                spacing: 10,
                children: [
                  _buildStockChip("All Stock"),
                  _buildStockChip("Low Stock (<10)"),
                  _buildStockChip("Out of Stock"),
                ],
              );
            }),

            const SizedBox(height: 30),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      // Clear logic
                      controller.clearAllFilters();
                      _localStockFilter.value = "All Stock";
                      Get.back();
                    },
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.redAccent),
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      "Clear Filters",
                      style: TextStyle(
                        color: Colors.redAccent,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Get.back(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.cyanAccent,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      "Apply / Close",
                      style: TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStockChip(String label) {
    bool isSelected = _localStockFilter.value == label;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (val) {
        _localStockFilter.value = label;
        // Agar controller men stock logic he to yahan call karein:
        // controller.updateStockFilter(label);
      },
      selectedColor: Colors.purpleAccent,
      backgroundColor: Colors.white.withOpacity(0.05),
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : Colors.white70,
        fontWeight: FontWeight.bold,
      ),
    );
  }
}
