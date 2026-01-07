import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/product_model.dart';
import '../../controller/products_controller.dart';
import 'add_product_screen.dart';

class ProductDetailScreen extends StatefulWidget {
  final ProductModel product;

  const ProductDetailScreen({Key? key, required this.product})
    : super(key: key);

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  final ProductsController controller = Get.find<ProductsController>();

  // Image Index State
  int _currentImageIndex = 0;

  // OPTIMIZATION: Use ValueNotifier for magnifier position to prevent full rebuilds
  final ValueNotifier<Offset?> _magnifierPositionNotifier = ValueNotifier(null);

  @override
  void dispose() {
    _magnifierPositionNotifier.dispose();
    super.dispose();
  }

  void _showFullScreenImage(BuildContext context, int initialIndex) {
    showDialog(
      context: context,
      builder: (context) {
        int dialogIndex = initialIndex;
        final TransformationController dialogTransformCtrl =
            TransformationController();

        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              backgroundColor: Colors.transparent,
              insetPadding: EdgeInsets.zero,
              child: Stack(
                children: [
                  InteractiveViewer(
                    transformationController: dialogTransformCtrl,
                    panEnabled: true,
                    minScale: 0.5,
                    maxScale: 4.0,
                    child: Container(
                      width: double.infinity,
                      height: double.infinity,
                      color: Colors.black,
                      child: Image.memory(
                        base64Decode(widget.product.images[dialogIndex]),
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
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
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E1E2C),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E1E2C),
        elevation: 0,
        toolbarHeight: 80,
        title: Text(
          widget.product.name,
          style: GoogleFonts.orbitron(color: Colors.white),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.cyanAccent),
          onPressed: () => Get.back(),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(top: 10, right: 10),
            child: IconButton(
              iconSize: 28,
              icon: const Icon(Icons.edit, color: Colors.white),
              onPressed: () {
                Get.to(() => AddProductScreen(productToEdit: widget.product));
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 10, right: 20),
            child: IconButton(
              iconSize: 28,
              icon: const Icon(Icons.delete, color: Colors.redAccent),
              onPressed: () {
                Get.defaultDialog(
                  title: "Delete Product?",
                  titleStyle: GoogleFonts.orbitron(color: Colors.white),
                  backgroundColor: const Color(0xFF2A2D3E),
                  middleText:
                      "Are you sure you want to permanently delete ${widget.product.name}?",
                  middleTextStyle: const TextStyle(color: Colors.white70),
                  textConfirm: "Delete",
                  textCancel: "Cancel",
                  confirmTextColor: Colors.white,
                  buttonColor: Colors.redAccent,
                  onConfirm: () {
                    if (widget.product.id != null) {
                      controller.deleteProduct(widget.product.id!);
                      Get.back();
                      Get.back();
                    }
                  },
                );
              },
            ),
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          bool isDesktop = constraints.maxWidth > 900;
          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: isDesktop
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 4, child: _buildImageGallery()),
                      const SizedBox(width: 30),
                      Expanded(flex: 6, child: _buildProductDetails()),
                    ],
                  )
                : Column(
                    children: [
                      _buildImageGallery(),
                      const SizedBox(height: 20),
                      _buildProductDetails(),
                    ],
                  ),
          );
        },
      ),
    );
  }

  Widget _buildImageGallery() {
    bool hasImages = widget.product.images.isNotEmpty;
    return Column(
      children: [
        Stack(
          children: [
            Container(
              height: 400,
              width: double.infinity,
              decoration: BoxDecoration(
                color: const Color(0xFF2A2D3E),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white10),
              ),
              child: !hasImages
                  ? const Center(
                      child: Icon(
                        Icons.image_not_supported,
                        size: 60,
                        color: Colors.white24,
                      ),
                    )
                  : ScrollConfiguration(
                      // Enable drag on PC/Web
                      behavior: ScrollConfiguration.of(context).copyWith(
                        dragDevices: {
                          PointerDeviceKind.touch,
                          PointerDeviceKind.mouse,
                        },
                      ),
                      child: PageView.builder(
                        itemCount: widget.product.images.length,
                        onPageChanged: (index) =>
                            setState(() => _currentImageIndex = index),
                        itemBuilder: (context, index) {
                          final imageBytes = base64Decode(
                            widget.product.images[index],
                          );

                          // OPTIMIZED MAGNIFIER:
                          // Using Listener to update ValueNotifier (No SetState Rebuilds)
                          return Listener(
                            onPointerHover: (event) {
                              // Optional: If you want hover to show lens
                              // _magnifierPositionNotifier.value = event.localPosition;
                            },
                            onPointerMove: (event) {
                              // Only update the notifier, doesn't rebuild the image
                              _magnifierPositionNotifier.value =
                                  event.localPosition;
                            },
                            onPointerUp: (_) {
                              _magnifierPositionNotifier.value = null;
                            },
                            child: GestureDetector(
                              onTap: () => _showFullScreenImage(context, index),

                              // Jab ungli rakh kar drag shuru ho (Touch Start)
                              onPanStart: (details) {
                                _magnifierPositionNotifier.value =
                                    details.localPosition;
                              },

                              // Jab ungli ghumayen (Dragging) - Ye scroll ko rok dega
                              onPanUpdate: (details) {
                                _magnifierPositionNotifier.value =
                                    details.localPosition;
                              },

                              // Jab ungli utha lein (Touch End)
                              onPanEnd: (_) {
                                _magnifierPositionNotifier.value = null;
                              },

                              // Behavior opaque rakhen taake har jagah touch pakde
                              behavior: HitTestBehavior.opaque,

                              child: Stack(
                                fit: StackFit.expand,
                                children: [
                                  // Base Image
                                  Image.memory(imageBytes, fit: BoxFit.contain),

                                  // The Lens (Listens to position updates)
                                  ValueListenableBuilder<Offset?>(
                                    valueListenable: _magnifierPositionNotifier,
                                    builder: (context, position, child) {
                                      if (position == null)
                                        return const SizedBox.shrink();
                                      return Positioned(
                                        left: position.dx - 50,
                                        top: position.dy - 50,
                                        child: const RawMagnifier(
                                          decoration: MagnifierDecoration(
                                            shape: CircleBorder(
                                              side: BorderSide(
                                                color: Colors.cyanAccent,
                                                width: 2,
                                              ),
                                            ),
                                          ),
                                          size: Size(100, 100),
                                          magnificationScale: 3.0,
                                        ),
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
            ),

            // Image Counter Badge
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
                    color: Colors.black.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white24),
                  ),
                  child: Text(
                    "${_currentImageIndex + 1} / ${widget.product.images.length}",
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

        // Navigation Indicators (Line/Dots)
        if (hasImages && widget.product.images.length > 1)
          Padding(
            padding: const EdgeInsets.only(top: 10.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(widget.product.images.length, (index) {
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  height: 6,
                  width: _currentImageIndex == index ? 24 : 8,
                  decoration: BoxDecoration(
                    color: _currentImageIndex == index
                        ? Colors.cyanAccent
                        : Colors.white24,
                    borderRadius: BorderRadius.circular(3),
                  ),
                );
              }),
            ),
          ),

        if (hasImages)
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Text(
              "Tap to expand • Drag to magnify",
              style: GoogleFonts.comicNeue(color: Colors.white24, fontSize: 12),
            ),
          ),
      ],
    );
  }

  Widget _buildProductDetails() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Category Badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: Colors.cyanAccent.withOpacity(0.2),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.cyanAccent),
          ),
          child: Text(
            widget.product.category,
            style: const TextStyle(
              color: Colors.cyanAccent,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 15),

        Text(
          widget.product.name,
          style: GoogleFonts.orbitron(
            color: Colors.white,
            fontSize: 32,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          "Model: ${widget.product.modelNumber}",
          style: GoogleFonts.comicNeue(color: Colors.white54, fontSize: 16),
        ),

        const SizedBox(height: 30),

        // PRICE & POINTS SECTION
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFF2A2D3E),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // --- PRICE COLUMN (Wrapped in Expanded) ---
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Price",
                          style: TextStyle(color: Colors.white54),
                        ),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              // UPDATED TO PKR
                              Text(
                                "PKR ${widget.product.salePrice}",
                                style: GoogleFonts.comicNeue(
                                  // Matched Font
                                  color: Colors.greenAccent,
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(width: 10),
                              if (widget.product.originalPrice >
                                  widget.product.salePrice)
                                Text(
                                  "PKR ${widget.product.originalPrice}",
                                  style: GoogleFonts.comicNeue(
                                    // Matched Font
                                    color: Colors.redAccent,
                                    fontSize: 18,
                                    decoration: TextDecoration.lineThrough,
                                    decorationColor: Colors.redAccent,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Divider
                  Container(
                    height: 40,
                    width: 1,
                    color: Colors.white10,
                    margin: const EdgeInsets.symmetric(horizontal: 10),
                  ),

                  // --- STOCK COLUMN ---
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Stock",
                          style: TextStyle(color: Colors.white54),
                        ),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            "${widget.product.stockQuantity} Units",
                            style: GoogleFonts.orbitron(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 15),
              const Divider(color: Colors.white10),
              const SizedBox(height: 10),

              // POINTS ROW
              Row(
                children: [
                  const Icon(Icons.star, color: Colors.amber, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      "Earned Points: ${widget.product.showDecimalPoints ? widget.product.productPoints.toStringAsFixed(1) : widget.product.productPoints.toInt()}",
                      style: const TextStyle(
                        color: Colors.amber,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 30),

        // Description
        Text(
          "Description",
          style: GoogleFonts.orbitron(
            color: Colors.purpleAccent,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          widget.product.description.isEmpty
              ? "No description provided."
              : widget.product.description,
          style: GoogleFonts.comicNeue(
            color: Colors.white70,
            fontSize: 16,
            height: 1.5,
          ),
        ),

        const SizedBox(height: 30),

        // Details Grid (Updated with RAM/Storage)
        if (widget.product.ram != null && widget.product.ram!.isNotEmpty)
          _buildInfoRow("RAM", widget.product.ram!),
        if (widget.product.storage != null &&
            widget.product.storage!.isNotEmpty)
          _buildInfoRow("Storage", widget.product.storage!),

        _buildInfoRow("Brand", widget.product.brand),
        _buildInfoRow("Sub-Category", widget.product.subCategory),
        _buildInfoRow("Location", widget.product.deliveryLocation),
        _buildInfoRow("Warranty", widget.product.warranty),

        const SizedBox(height: 30),

        // Vendor
        Text(
          "Vendor Information",
          style: GoogleFonts.orbitron(
            color: Colors.purpleAccent,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 10),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const CircleAvatar(
            backgroundColor: Colors.white10,
            child: Icon(Icons.store, color: Colors.white),
          ),
          title: Text(
            widget.product.vendorId,
            style: const TextStyle(color: Colors.white),
          ),
          subtitle: const Text(
            "Verified Vendor",
            style: TextStyle(color: Colors.white54),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Text(
            "$label: ",
            style: const TextStyle(
              color: Colors.white54,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(value, style: const TextStyle(color: Colors.white)),
        ],
      ),
    );
  }
}
