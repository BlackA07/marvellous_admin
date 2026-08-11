import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../controllers/category_controller.dart';
import '../models/category_model.dart';
import 'dart:io';

class CategoriesScreen extends StatelessWidget {
  CategoriesScreen({Key? key}) : super(key: key);

  final CategoryController controller = Get.put(CategoryController());
  final TextEditingController _nameController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Padding(
        padding: const EdgeInsets.all(10.0),
        child: LayoutBuilder(
          builder: (context, constraints) {
            bool isMobile = constraints.maxWidth < 800;
            if (isMobile) {
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
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              IconButton(
                onPressed: () => _showFormDialog(context, isMain: true),
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
                              // ✅ Circular Image Display
                              CircleAvatar(
                                radius: 18,
                                backgroundColor: Colors.white12,
                                backgroundImage:
                                    (cat.imageUrl != null &&
                                        cat.imageUrl!.isNotEmpty)
                                    ? NetworkImage(cat.imageUrl!)
                                    : null,
                                child:
                                    (cat.imageUrl == null ||
                                        cat.imageUrl!.isEmpty)
                                    ? const Icon(
                                        Icons.image,
                                        size: 18,
                                        color: Colors.white54,
                                      )
                                    : null,
                              ),
                              const SizedBox(width: 10),
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
                                  softWrap: true,
                                ),
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.edit,
                                  color: Colors.orangeAccent,
                                  size: 18,
                                ),
                                onPressed: () => _showFormDialog(
                                  context,
                                  isMain: true,
                                  category: cat,
                                ),
                              ),
                              const SizedBox(width: 8),
                              IconButton(
                                icon: const Icon(
                                  Icons.delete,
                                  color: Colors.redAccent,
                                  size: 18,
                                ),
                                onPressed: () {
                                  Get.defaultDialog(
                                    title: "Delete Category?",
                                    backgroundColor: const Color(0xFF2A2D3E),
                                    middleText:
                                        "Are you sure you want to delete '${cat.name}'?",
                                    middleTextStyle: const TextStyle(
                                      color: Colors.white70,
                                    ),
                                    textConfirm: "Delete",
                                    textCancel: "Cancel",
                                    confirmTextColor: Colors.white,
                                    buttonColor: Colors.redAccent,
                                    onConfirm: () {
                                      Get.back();
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
            child: Text(
              "Select a Category to view Sub-Categories",
              style: GoogleFonts.comicNeue(color: Colors.white54, fontSize: 14),
            ),
          ),
        );
      }

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
                      const Text(
                        "Sub-Categories",
                        style: TextStyle(color: Colors.white54, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => _showFormDialog(context, isMain: false),
                  icon: const Icon(Icons.add_circle, color: Colors.greenAccent),
                ),
              ],
            ),
            const Divider(color: Colors.white10),
            Expanded(
              child: liveCat.subCategories.isEmpty
                  ? const Center(
                      child: Text(
                        "No Sub-Categories added yet",
                        style: TextStyle(color: Colors.white54, fontSize: 13),
                      ),
                    )
                  : ListView.builder(
                      itemCount: liveCat.subCategories.length,
                      itemBuilder: (context, index) {
                        final subCatMap = liveCat.subCategories[index];
                        final subName = subCatMap['name'];
                        final subImageUrl = subCatMap['imageUrl'];

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
                                // ✅ Circular Image for Sub-category
                                CircleAvatar(
                                  radius: 16,
                                  backgroundColor: Colors.white12,
                                  backgroundImage:
                                      (subImageUrl != null &&
                                          subImageUrl.isNotEmpty)
                                      ? NetworkImage(subImageUrl)
                                      : null,
                                  child:
                                      (subImageUrl == null ||
                                          subImageUrl.isEmpty)
                                      ? const Icon(
                                          Icons.subdirectory_arrow_right,
                                          size: 16,
                                          color: Colors.white54,
                                        )
                                      : null,
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
                                IconButton(
                                  icon: const Icon(
                                    Icons.edit,
                                    color: Colors.orangeAccent,
                                    size: 18,
                                  ),
                                  onPressed: () => _showFormDialog(
                                    context,
                                    isMain: false,
                                    subCategoryData: subCatMap,
                                    parentCategory: liveCat,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                IconButton(
                                  icon: const Icon(
                                    Icons.delete,
                                    color: Colors.redAccent,
                                    size: 18,
                                  ),
                                  onPressed: () {
                                    Get.defaultDialog(
                                      title: "Delete Sub-Category?",
                                      backgroundColor: const Color(0xFF2A2D3E),
                                      middleText:
                                          "Are you sure you want to delete '$subName'?",
                                      middleTextStyle: const TextStyle(
                                        color: Colors.white70,
                                      ),
                                      textConfirm: "Delete",
                                      textCancel: "Cancel",
                                      confirmTextColor: Colors.white,
                                      buttonColor: Colors.redAccent,
                                      onConfirm: () {
                                        Get.back();
                                        controller.deleteSubCategory(
                                          liveCat,
                                          subCatMap,
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

  // --- MERGED ADD/EDIT DIALOG ---
  void _showFormDialog(
    BuildContext context, {
    required bool isMain,
    CategoryModel? category,
    Map<String, dynamic>? subCategoryData,
    CategoryModel? parentCategory,
  }) {
    bool isEditing = category != null || subCategoryData != null;
    _nameController.text = isEditing
        ? (isMain ? category!.name : subCategoryData!['name'])
        : "";

    // Clear temporary image state before opening dialog
    controller.tempSelectedImageBytes.value = null;

    String existingImageUrl = isEditing
        ? (isMain
              ? category?.imageUrl ?? ''
              : subCategoryData?['imageUrl'] ?? '')
        : "";

    Get.defaultDialog(
      title: isMain
          ? (isEditing ? "Edit Category" : "Add Category")
          : (isEditing ? "Edit Sub-Category" : "Add Sub-Category"),
      titleStyle: GoogleFonts.orbitron(color: Colors.white, fontSize: 18),
      backgroundColor: const Color(0xFF2A2D3E),
      contentPadding: const EdgeInsets.all(20),
      barrierDismissible: false, // Prevent dismissing while uploading
      content: Obx(() {
        return Stack(
          clipBehavior: Clip.none,
          children: [
            Column(
              children: [
                // ✅ Image Picker Circle
                // ✅ Image Picker Circle (Updated for MemoryImage safely)
                GestureDetector(
                  onTap: () => controller.pickAndCropImage(),
                  child: CircleAvatar(
                    radius: 45,
                    backgroundColor: Colors.white12,
                    backgroundImage:
                        controller.tempSelectedImageBytes.value != null
                        ? MemoryImage(controller.tempSelectedImageBytes.value!)
                              as ImageProvider
                        : (existingImageUrl.isNotEmpty
                              ? NetworkImage(existingImageUrl)
                              : null),
                    child:
                        (controller.tempSelectedImageBytes.value == null &&
                            existingImageUrl.isEmpty)
                        ? const Icon(
                            Icons.add_a_photo,
                            size: 30,
                            color: Colors.white54,
                          )
                        : null,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  "Tap to select image",
                  style: TextStyle(color: Colors.white54, fontSize: 12),
                ),
                const SizedBox(height: 20),

                // Name Input
                TextField(
                  controller: _nameController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: isMain ? "Category Name" : "Sub-Category Name",
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
                ),
                const SizedBox(height: 20),

                // ✅ NEW: Cancel + Save/Update Buttons side by side
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.white24),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onPressed: controller.isUploading.value
                            ? null
                            : () {
                                controller.tempSelectedImageBytes.value = null;
                                Get.back();
                              },
                        child: const Text(
                          "Cancel",
                          style: TextStyle(
                            color: Colors.white70,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isEditing
                              ? Colors.orangeAccent
                              : Colors.cyanAccent,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onPressed: controller.isUploading.value
                            ? null
                            : () async {
                                if (_nameController.text.isNotEmpty) {
                                  if (isMain) {
                                    if (isEditing) {
                                      await controller.updateCategory(
                                        category!,
                                        _nameController.text,
                                      );
                                    } else {
                                      await controller.addCategory(
                                        _nameController.text,
                                      );
                                    }
                                  } else {
                                    if (isEditing) {
                                      await controller.updateSubCategory(
                                        parentCategory!,
                                        subCategoryData!,
                                        _nameController.text,
                                      );
                                    } else {
                                      if (controller.selectedCategory.value !=
                                          null) {
                                        await controller.addSubCategory(
                                          controller
                                              .selectedCategory
                                              .value!
                                              .name,
                                          _nameController.text,
                                        );
                                      }
                                    }
                                  }
                                }
                              },
                        child: controller.isUploading.value
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.black,
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(
                                isEditing ? "Update" : "Save",
                                style: const TextStyle(
                                  color: Colors.black,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
                if (controller.isUploading.value) ...[
                  const SizedBox(height: 10),
                  const Text(
                    "Uploading Image...",
                    style: TextStyle(color: Colors.cyanAccent, fontSize: 12),
                  ),
                ],
              ],
            ),

            // ✅ NEW: Top-right X close icon — closes dialog directly,
            // disabled while an image is uploading so it can't be
            // interrupted mid-upload.
            Positioned(
              top: -12,
              right: -12,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white70, size: 22),
                onPressed: controller.isUploading.value
                    ? null
                    : () {
                        controller.tempSelectedImageBytes.value = null;
                        Get.back();
                      },
              ),
            ),
          ],
        );
      }),
    );
  }
}
