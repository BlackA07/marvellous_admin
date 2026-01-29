import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // For Keyboard events
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

// Controllers & Models
import 'package:marvellous_admin/features/products/controller/products_controller.dart';
import '../../../products/models/product_model.dart';
import 'add_package_screen.dart'; // Import your AddPackageScreen

class PackageDetailScreen extends StatefulWidget {
  final ProductModel package;
  const PackageDetailScreen({Key? key, required this.package})
    : super(key: key);

  @override
  State<PackageDetailScreen> createState() => _PackageDetailScreenState();
}

class _PackageDetailScreenState extends State<PackageDetailScreen> {
  final ProductsController productController = Get.find<ProductsController>();

  // Controllers
  final PageController _pageCtrl = PageController();
  int _currentImageIndex = 0;

  @override
  void dispose() {
    _pageCtrl.dispose();
    super.dispose();
  }

  // --- DELETE LOGIC ---
  void _deletePackage() {
    Get.defaultDialog(
      title: "Delete Package?",
      titleStyle: GoogleFonts.orbitron(
        fontWeight: FontWeight.bold,
        color: Colors.red,
      ),
      middleText: "Are you sure you want to delete '${widget.package.name}'?",
      textConfirm: "Delete",
      textCancel: "Cancel",
      confirmTextColor: Colors.white,
      buttonColor: Colors.red,
      onConfirm: () {
        // 1. Close Dialog
        Get.back();

        // 2. Go back to list screen
        Get.back();

        // 3. Perform Delete
        productController.deleteProduct(widget.package.id!, isPackage: true);

        // 4. Show Undo Snackbar
        Get.snackbar(
          "Deleted",
          "${widget.package.name} removed.",
          backgroundColor: Colors.black87,
          colorText: Colors.white,
          duration: const Duration(seconds: 4),
          mainButton: TextButton(
            onPressed: () {
              productController.addNewProduct(widget.package);
              Get.back(); // Close snackbar
            },
            child: const Text("UNDO", style: TextStyle(color: Colors.yellow)),
          ),
        );
      },
    );
  }

  // --- CAROUSEL NAVIGATION (Infinite) ---
  void _moveCarousel(int direction) {
    if (widget.package.images.isEmpty) return;

    int newIndex = _currentImageIndex + direction;
    int total = widget.package.images.length;

    // Infinite Loop Logic
    if (newIndex < 0) {
      newIndex = total - 1; // Go to last
    } else if (newIndex >= total) {
      newIndex = 0; // Go to first
    }

    _pageCtrl.animateToPage(
      newIndex,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  // --- FULL SCREEN IMAGE VIEWER ---
  void _showFullScreenImage(BuildContext context, int initialIndex) {
    showDialog(
      context: context,
      builder: (context) {
        // Local state for the dialog
        int dialogIndex = initialIndex;
        int totalImages = widget.package.images.length;

        return StatefulBuilder(
          builder: (context, setDialogState) {
            // Helper to change image in dialog (Infinite Loop)
            void moveDialogImage(int direction) {
              int newIdx = dialogIndex + direction;
              if (newIdx < 0) newIdx = totalImages - 1;
              if (newIdx >= totalImages) newIdx = 0;
              setDialogState(() => dialogIndex = newIdx);
            }

            // Keyboard Listener
            return Focus(
              autofocus: true,
              onKey: (node, event) {
                if (event is RawKeyDownEvent) {
                  if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
                    moveDialogImage(-1);
                    return KeyEventResult.handled;
                  } else if (event.logicalKey ==
                      LogicalKeyboardKey.arrowRight) {
                    moveDialogImage(1);
                    return KeyEventResult.handled;
                  } else if (event.logicalKey == LogicalKeyboardKey.escape) {
                    Navigator.pop(context);
                    return KeyEventResult.handled;
                  }
                }
                return KeyEventResult.ignored;
              },
              child: Dialog(
                backgroundColor: Colors.black,
                insetPadding: EdgeInsets.zero,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Image with Zoom
                    InteractiveViewer(
                      minScale: 0.5,
                      maxScale: 4.0,
                      child: Container(
                        width: double.infinity,
                        height: double.infinity,
                        child: Image.memory(
                          base64Decode(widget.package.images[dialogIndex]),
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),

                    // Close Button
                    Positioned(
                      top: 40,
                      right: 20,
                      child: IconButton(
                        icon: const Icon(
                          Icons.close,
                          color: Colors.white,
                          size: 30,
                        ),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),

                    // Left Arrow
                    if (totalImages > 1)
                      Positioned(
                        left: 10,
                        child: IconButton(
                          icon: const Icon(
                            Icons.arrow_back_ios,
                            color: Colors.white,
                            size: 40,
                          ),
                          onPressed: () => moveDialogImage(-1),
                        ),
                      ),

                    // Right Arrow
                    if (totalImages > 1)
                      Positioned(
                        right: 10,
                        child: IconButton(
                          icon: const Icon(
                            Icons.arrow_forward_ios,
                            color: Colors.white,
                            size: 40,
                          ),
                          onPressed: () => moveDialogImage(1),
                        ),
                      ),

                    // Counter
                    Positioned(
                      bottom: 30,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white24,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          "${dialogIndex + 1} / $totalImages",
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Theme Colors (Light Theme)
    const Color bgColor = Color(0xFFF5F7FA);
    const Color cardColor = Colors.white;
    const Color textColor = Colors.black87;
    const Color accentColor = Colors.deepPurple;

    // Find actual product objects from IDs
    List<ProductModel> includedItems = productController.productsOnly
        .where((p) => widget.package.includedItemIds.contains(p.id))
        .toList();

    // Calculate Financials
    double totalPurchaseCost = includedItems.fold(
      0,
      (sum, item) => sum + item.purchasePrice,
    );
    double grossProfit = widget.package.salePrice - totalPurchaseCost;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: Text(
          "Package Details",
          style: GoogleFonts.orbitron(
            color: textColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: textColor),
        centerTitle: true,
        actions: [
          // Edit Button
          IconButton(
            icon: const Icon(Icons.edit, color: Colors.orange),
            tooltip: "Edit Package",
            onPressed: () {
              // Navigate to Edit Screen
              Get.to(() => AddPackageScreen(packageToEdit: widget.package));
            },
          ),
          // Delete Button
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.red),
            tooltip: "Delete Package",
            onPressed: _deletePackage,
          ),
          const SizedBox(width: 10),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. IMAGE GALLERY (With Arrows)
            _buildImageGallery(accentColor),

            const SizedBox(height: 20),

            // 2. NAME & MODEL
            Text(
              widget.package.name,
              style: GoogleFonts.orbitron(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            Text(
              "Model: ${widget.package.modelNumber}",
              style: TextStyle(color: Colors.grey[600], fontSize: 14),
            ),

            const SizedBox(height: 20),

            // 3. FINANCIAL INFO CARD
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Row 1: Sale Price & Points
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Bundle Price",
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                          ),
                          Text(
                            "PKR ${widget.package.salePrice.toInt()}",
                            style: GoogleFonts.comicNeue(
                              color: Colors.green[700],
                              fontSize: 24,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            "Points",
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                          ),
                          Row(
                            children: [
                              const Icon(
                                Icons.star,
                                color: Colors.amber,
                                size: 20,
                              ),
                              const SizedBox(width: 5),
                              Text(
                                widget.package.showDecimalPoints
                                    ? widget.package.productPoints
                                          .toStringAsFixed(1)
                                    : widget.package.productPoints
                                          .toInt()
                                          .toString(),
                                style: GoogleFonts.comicNeue(
                                  color: Colors.amber[800],
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                  const Divider(height: 25),
                  // Row 2: Purchase & Profit
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildMiniInfo(
                        "Purchase Cost",
                        "PKR ${totalPurchaseCost.toInt()}",
                        Colors.redAccent,
                      ),
                      _buildMiniInfo(
                        "Gross Profit",
                        "PKR ${grossProfit.toInt()}",
                        grossProfit >= 0 ? Colors.blueAccent : Colors.red,
                      ),
                    ],
                  ),
                  const SizedBox(height: 15),
                  // Row 3: Location & Stock
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildMiniInfo(
                        "Location",
                        widget.package.deliveryLocation,
                        textColor,
                      ),
                      _buildMiniInfo(
                        "Stock",
                        "${widget.package.stockQuantity} Units",
                        textColor,
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 25),

            // 4. DESCRIPTION
            Text(
              "Description",
              style: GoogleFonts.orbitron(
                color: accentColor,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 5),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Text(
                widget.package.description.isEmpty
                    ? "No description provided."
                    : widget.package.description,
                style: const TextStyle(
                  color: Colors.black87,
                  fontSize: 15,
                  height: 1.5,
                ),
              ),
            ),

            const SizedBox(height: 25),

            // 5. INCLUDED ITEMS LIST
            Text(
              "Included Items (${includedItems.length})",
              style: GoogleFonts.orbitron(
                color: accentColor,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),

            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: includedItems.length,
              itemBuilder: (context, index) {
                final item = includedItems[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.03),
                        blurRadius: 5,
                      ),
                    ],
                  ),
                  child: ListTile(
                    leading: Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(8),
                        image: item.images.isNotEmpty
                            ? DecorationImage(
                                image: MemoryImage(
                                  base64Decode(item.images.first),
                                ),
                                fit: BoxFit.cover,
                              )
                            : null,
                      ),
                    ),
                    title: Text(
                      item.name,
                      style: const TextStyle(
                        color: textColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: Text(
                      "Model: ${item.modelNumber}",
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                    trailing: Text(
                      "Cost: ${item.purchasePrice.toInt()}",
                      style: const TextStyle(
                        color: Colors.redAccent,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 50),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniInfo(String label, String value, Color valueColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            color: valueColor,
            fontWeight: FontWeight.bold,
            fontSize: 15,
          ),
        ),
      ],
    );
  }

  Widget _buildImageGallery(Color accentColor) {
    bool hasImages = widget.package.images.isNotEmpty;

    return Column(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            // Image Area
            Container(
              height: 300,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade300),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: !hasImages
                  ? const Center(
                      child: Icon(
                        Icons.image_not_supported,
                        size: 60,
                        color: Colors.grey,
                      ),
                    )
                  : GestureDetector(
                      onTap: () =>
                          _showFullScreenImage(context, _currentImageIndex),
                      child: PageView.builder(
                        controller: _pageCtrl,
                        itemCount: widget.package.images.length,
                        onPageChanged: (index) =>
                            setState(() => _currentImageIndex = index),
                        itemBuilder: (context, index) {
                          return ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Image.memory(
                              base64Decode(widget.package.images[index]),
                              fit: BoxFit.contain,
                            ),
                          );
                        },
                      ),
                    ),
            ),

            // Left Arrow
            if (hasImages && widget.package.images.length > 1)
              Positioned(
                left: 10,
                child: CircleAvatar(
                  backgroundColor: Colors.black.withOpacity(0.5),
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => _moveCarousel(-1),
                  ),
                ),
              ),

            // Right Arrow
            if (hasImages && widget.package.images.length > 1)
              Positioned(
                right: 10,
                child: CircleAvatar(
                  backgroundColor: Colors.black.withOpacity(0.5),
                  child: IconButton(
                    icon: const Icon(Icons.arrow_forward, color: Colors.white),
                    onPressed: () => _moveCarousel(1),
                  ),
                ),
              ),

            // Counter Badge
            if (hasImages)
              Positioned(
                bottom: 15,
                right: 15,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    "${_currentImageIndex + 1} / ${widget.package.images.length}",
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
          ],
        ),

        // Dots Indicator
        if (hasImages && widget.package.images.length > 1)
          Padding(
            padding: const EdgeInsets.only(top: 10.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(widget.package.images.length, (index) {
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  height: 6,
                  width: _currentImageIndex == index ? 24 : 8,
                  decoration: BoxDecoration(
                    color: _currentImageIndex == index
                        ? accentColor
                        : Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(3),
                  ),
                );
              }),
            ),
          ),
      ],
    );
  }
}
