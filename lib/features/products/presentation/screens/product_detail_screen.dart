import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  int _currentImageIndex = 0;
  final TransformationController _transformationController =
      TransformationController();

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
                  // Left/Right arrows omitted for brevity, logic remains the same as your previous code
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
    return Container(
      height: 400,
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
          : PageView.builder(
              itemCount: widget.product.images.length,
              onPageChanged: (index) =>
                  setState(() => _currentImageIndex = index),
              itemBuilder: (context, index) {
                return GestureDetector(
                  onTap: () => _showFullScreenImage(context, index),
                  child: Image.memory(
                    base64Decode(widget.product.images[index]),
                    fit: BoxFit.contain,
                  ),
                );
              },
            ),
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
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Price",
                        style: TextStyle(color: Colors.white54),
                      ),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            "\$${widget.product.salePrice}",
                            style: GoogleFonts.orbitron(
                              color: Colors.greenAccent,
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 10),
                          // FAKE PRICE STRIKETHROUGH
                          if (widget.product.originalPrice >
                              widget.product.salePrice)
                            Text(
                              "\$${widget.product.originalPrice}",
                              style: GoogleFonts.orbitron(
                                color: Colors.redAccent,
                                fontSize: 18,
                                decoration: TextDecoration.lineThrough,
                                decorationColor: Colors.redAccent,
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                  Container(height: 40, width: 1, color: Colors.white10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Stock",
                        style: TextStyle(color: Colors.white54),
                      ),
                      Text(
                        "${widget.product.stockQuantity} Units",
                        style: GoogleFonts.orbitron(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
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
                  Text(
                    "Earned Points: ${widget.product.productPoints.toStringAsFixed(1)}",
                    style: const TextStyle(
                      color: Colors.amber,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
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

        // Details Grid
        _buildInfoRow("Brand", widget.product.brand),
        _buildInfoRow("Sub-Category", widget.product.subCategory),
        _buildInfoRow("Location", widget.product.deliveryLocation), // New
        _buildInfoRow("Warranty", widget.product.warranty), // New

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
