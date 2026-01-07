import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../controllers/category_controller.dart';
import '../models/category_model.dart';

class CategoriesScreen extends StatelessWidget {
  CategoriesScreen({Key? key}) : super(key: key);

  final CategoryController controller = Get.put(CategoryController());
  final TextEditingController _nameController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent, // Assuming nested inside main layout
      body: Padding(
        padding: const EdgeInsets.all(10.0), // Reduced padding for mobile
        child: LayoutBuilder(
          builder: (context, constraints) {
            // Check screen width to decide layout
            bool isMobile = constraints.maxWidth < 800;

            if (isMobile) {
              // Mobile Layout: Column (Top: Main, Bottom: Sub)
              return Column(
                children: [
                  Expanded(
                    flex: 1,
                    child: _buildMainCategoriesSection(context),
                  ),
                  const SizedBox(height: 10),
                  Expanded(flex: 1, child: _buildSubCategoriesSection(context)),
                ],
              );
            } else {
              // Desktop/Tablet Layout: Row (Left: Main, Right: Sub)
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 1,
                    child: _buildMainCategoriesSection(context),
                  ),
                  const SizedBox(width: 20),
                  Expanded(flex: 1, child: _buildSubCategoriesSection(context)),
                ],
              );
            }
          },
        ),
      ),
    );
  }

  Widget _buildMainCategoriesSection(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2D3E),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  "All Categories",
                  style: GoogleFonts.orbitron(
                    color: Colors.white,
                    fontSize: 16, // Slightly smaller for better fit
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              IconButton(
                onPressed: () => _showAddDialog(context, isMain: true),
                icon: const Icon(Icons.add_circle, color: Colors.cyanAccent),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const Divider(color: Colors.white10),
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value) {
                return const Center(
                  child: CircularProgressIndicator(color: Colors.cyanAccent),
                );
              }
              if (controller.categories.isEmpty) {
                return const Center(
                  child: Text(
                    "No Categories",
                    style: TextStyle(color: Colors.white54),
                  ),
                );
              }

              return ListView.builder(
                itemCount: controller.categories.length,
                itemBuilder: (context, index) {
                  final cat = controller.categories[index];
                  return Obx(() {
                    bool isSelected =
                        controller.selectedCategory.value?.id == cat.id;
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 5),
                      color: isSelected
                          ? Colors.cyanAccent.withOpacity(0.2)
                          : Colors.white.withOpacity(0.05),
                      child: InkWell(
                        onTap: () => controller.selectCategory(cat),
                        borderRadius: BorderRadius.circular(4),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          child: Row(
                            children: [
                              // Category Name (Flexible to wrap)
                              Expanded(
                                child: Text(
                                  cat.name,
                                  style: TextStyle(
                                    color: isSelected
                                        ? Colors.cyanAccent
                                        : Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  softWrap: true, // Allow wrapping
                                ),
                              ),
                              // Edit Button
                              IconButton(
                                icon: const Icon(
                                  Icons.edit,
                                  color: Colors.orangeAccent,
                                  size: 18,
                                ),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                onPressed: () {
                                  _showEditDialog(context, category: cat);
                                },
                              ),
                              const SizedBox(width: 8),
                              // Delete Button
                              IconButton(
                                icon: const Icon(
                                  Icons.delete,
                                  color: Colors.redAccent,
                                  size: 18,
                                ),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                onPressed: () {
                                  // CONFIRMATION DIALOG
                                  Get.defaultDialog(
                                    title: "Delete Category?",
                                    titleStyle: GoogleFonts.orbitron(
                                      color: Colors.white,
                                      fontSize: 16,
                                    ),
                                    backgroundColor: const Color(0xFF2A2D3E),
                                    contentPadding: const EdgeInsets.all(20),
                                    middleText:
                                        "Are you sure you want to delete '${cat.name}'?",
                                    middleTextStyle: const TextStyle(
                                      color: Colors.white70,
                                    ),
                                    textConfirm: "Delete",
                                    textCancel: "Cancel",
                                    confirmTextColor: Colors.white,
                                    buttonColor: Colors.redAccent,
                                    cancelTextColor: Colors.cyanAccent,
                                    onConfirm: () {
                                      Get.back(); // Close dialog
                                      controller.deleteCategory(cat);
                                    },
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  });
                },
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildSubCategoriesSection(BuildContext context) {
    return Obx(() {
      final selectedCat = controller.selectedCategory.value;

      if (selectedCat == null) {
        return Container(
          decoration: BoxDecoration(
            color: const Color(0xFF2A2D3E),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.white10),
          ),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Text(
                "Select a Category to view Sub-Categories",
                textAlign: TextAlign.center,
                style: GoogleFonts.comicNeue(
                  color: Colors.white54,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        );
      }

      // We need to find the latest version of the selected category from the list to see real-time subcat updates
      final liveCat = controller.categories.firstWhere(
        (c) => c.id == selectedCat.id,
        orElse: () => selectedCat,
      );

      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF2A2D3E),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.white10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        liveCat.name,
                        style: GoogleFonts.orbitron(
                          color: Colors.cyanAccent,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        "Sub-Categories",
                        style: TextStyle(color: Colors.white54, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => _showAddDialog(context, isMain: false),
                  icon: const Icon(Icons.add_circle, color: Colors.greenAccent),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const Divider(color: Colors.white10),
            Expanded(
              child: liveCat.subCategories.isEmpty
                  ? const Center(
                      child: Text(
                        "No Sub-Categories added yet",
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white54, fontSize: 13),
                      ),
                    )
                  : ListView.builder(
                      itemCount: liveCat.subCategories.length,
                      itemBuilder: (context, index) {
                        final subName = liveCat.subCategories[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 5),
                          color: Colors.white.withOpacity(0.05),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.subdirectory_arrow_right,
                                  color: Colors.white54,
                                  size: 16,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    subName,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                    ),
                                    softWrap: true,
                                  ),
                                ),
                                // Edit Button
                                IconButton(
                                  icon: const Icon(
                                    Icons.edit,
                                    color: Colors.orangeAccent,
                                    size: 18,
                                  ),
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                  onPressed: () {
                                    _showEditDialog(
                                      context,
                                      subCategoryName: subName,
                                      parentCategory: liveCat,
                                    );
                                  },
                                ),
                                const SizedBox(width: 8),
                                // Delete Button
                                IconButton(
                                  icon: const Icon(
                                    Icons.delete,
                                    color: Colors.redAccent,
                                    size: 18,
                                  ),
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                  onPressed: () {
                                    // SUB CATEGORY CONFIRMATION
                                    Get.defaultDialog(
                                      title: "Delete Sub-Category?",
                                      titleStyle: GoogleFonts.orbitron(
                                        color: Colors.white,
                                        fontSize: 16,
                                      ),
                                      backgroundColor: const Color(0xFF2A2D3E),
                                      contentPadding: const EdgeInsets.all(20),
                                      middleText:
                                          "Are you sure you want to delete '$subName'?",
                                      middleTextStyle: const TextStyle(
                                        color: Colors.white70,
                                      ),
                                      textConfirm: "Delete",
                                      textCancel: "Cancel",
                                      confirmTextColor: Colors.white,
                                      buttonColor: Colors.redAccent,
                                      cancelTextColor: Colors.cyanAccent,
                                      onConfirm: () {
                                        Get.back();
                                        controller.deleteSubCategory(
                                          liveCat,
                                          subName,
                                        );
                                      },
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      );
    });
  }

  // --- ADD DIALOG ---
  void _showAddDialog(BuildContext context, {required bool isMain}) {
    _nameController.clear();
    Get.defaultDialog(
      title: isMain ? "Add Category" : "Add Sub-Category",
      titleStyle: GoogleFonts.orbitron(color: Colors.white, fontSize: 18),
      backgroundColor: const Color(0xFF2A2D3E),
      contentPadding: const EdgeInsets.all(20),
      content: Column(
        children: [
          TextField(
            controller: _nameController,
            autofocus: true,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: isMain
                  ? "Enter Category Name"
                  : "Enter Sub-Category Name",
              hintStyle: const TextStyle(color: Colors.white54),
              filled: true,
              fillColor: Colors.black26,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 15,
                vertical: 15,
              ),
            ),
            onSubmitted: (value) {
              if (value.isNotEmpty) {
                if (isMain) {
                  controller.addCategory(value);
                  Get.back();
                } else {
                  controller.addSubCategory(value);
                }
              }
            },
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.cyanAccent,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () {
                if (_nameController.text.isNotEmpty) {
                  if (isMain) {
                    controller.addCategory(_nameController.text);
                    Get.back();
                  } else {
                    controller.addSubCategory(_nameController.text);
                  }
                }
              },
              child: const Text(
                "Save",
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- EDIT DIALOG (NEW FEATURE) ---
  void _showEditDialog(
    BuildContext context, {
    CategoryModel? category,
    String? subCategoryName,
    CategoryModel? parentCategory,
  }) {
    bool isMain = category != null;
    _nameController.text = isMain ? category.name : subCategoryName ?? "";

    Get.defaultDialog(
      title: isMain ? "Edit Category" : "Edit Sub-Category",
      titleStyle: GoogleFonts.orbitron(color: Colors.white, fontSize: 18),
      backgroundColor: const Color(0xFF2A2D3E),
      contentPadding: const EdgeInsets.all(20),
      content: Column(
        children: [
          TextField(
            controller: _nameController,
            autofocus: true,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: "Enter New Name",
              hintStyle: const TextStyle(color: Colors.white54),
              filled: true,
              fillColor: Colors.black26,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 15,
                vertical: 15,
              ),
            ),
            onSubmitted: (value) {
              if (value.isNotEmpty) {
                if (isMain) {
                  controller.updateCategory(category, value);
                } else if (parentCategory != null && subCategoryName != null) {
                  controller.updateSubCategory(
                    parentCategory,
                    subCategoryName,
                    value,
                  );
                }
                Get.back();
              }
            },
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orangeAccent,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () {
                if (_nameController.text.isNotEmpty) {
                  if (isMain) {
                    controller.updateCategory(category, _nameController.text);
                  } else if (parentCategory != null &&
                      subCategoryName != null) {
                    controller.updateSubCategory(
                      parentCategory,
                      subCategoryName,
                      _nameController.text,
                    );
                  }
                  Get.back();
                }
              },
              child: const Text(
                "Update",
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
