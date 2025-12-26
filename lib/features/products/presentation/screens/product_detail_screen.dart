import 'dart:convert'; // Required for Base64
import 'dart:ui'; // Required for PointerDeviceKind (Mouse Scroll)
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Required for Keyboard Keys
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

// Imports for Logic
import '../../models/product_model.dart';
import '../../controller/products_controller.dart';
import 'add_product_screen.dart'; // Required for Edit Navigation

class ProductDetailScreen extends StatefulWidget {
  final ProductModel product;

  const ProductDetailScreen({Key? key, required this.product})
    : super(key: key);

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  // Access the controller to handle Delete logic
  final ProductsController controller = Get.find<ProductsController>();

  int _currentImageIndex = 0; // Track active image
  final TransformationController _transformationController =
      TransformationController();

  // Helper to decode image safely
  ImageProvider _getImageProvider(String base64String) {
    return MemoryImage(base64Decode(base64String));
  }

  // Show Full Screen Zoom Dialog with Keyboard Support
  void _showFullScreenImage(BuildContext context, int initialIndex) {
    showDialog(
      context: context,
      builder: (context) {
        int dialogIndex = initialIndex;
        final TransformationController dialogTransformCtrl =
            TransformationController();

        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Focus(
              autofocus: true,
              onKeyEvent: (node, event) {
                if (event is KeyDownEvent) {
                  if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
                    if (dialogIndex > 0) {
                      setDialogState(() {
                        dialogIndex--;
                        dialogTransformCtrl.value = Matrix4.identity();
                      });
                      return KeyEventResult.handled;
                    }
                  } else if (event.logicalKey ==
                      LogicalKeyboardKey.arrowRight) {
                    if (dialogIndex < widget.product.images.length - 1) {
                      setDialogState(() {
                        dialogIndex++;
                        dialogTransformCtrl.value = Matrix4.identity();
                      });
                      return KeyEventResult.handled;
                    }
                  }
                }
                return KeyEventResult.ignored;
              },
              child: Dialog(
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
                    if (dialogIndex > 0)
                      Positioned(
                        left: 20,
                        top: 0,
                        bottom: 0,
                        child: Center(
                          child: IconButton(
                            icon: const Icon(
                              Icons.arrow_back_ios,
                              color: Colors.white70,
                              size: 40,
                            ),
                            onPressed: () {
                              setDialogState(() {
                                dialogIndex--;
                                dialogTransformCtrl.value = Matrix4.identity();
                              });
                            },
                          ),
                        ),
                      ),
                    if (dialogIndex < widget.product.images.length - 1)
                      Positioned(
                        right: 20,
                        top: 0,
                        bottom: 0,
                        child: Center(
                          child: IconButton(
                            icon: const Icon(
                              Icons.arrow_forward_ios,
                              color: Colors.white70,
                              size: 40,
                            ),
                            onPressed: () {
                              setDialogState(() {
                                dialogIndex++;
                                dialogTransformCtrl.value = Matrix4.identity();
                              });
                            },
                          ),
                        ),
                      ),
                    Positioned(
                      bottom: 20,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black54,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            "${dialogIndex + 1} / ${widget.product.images.length}",
                            style: GoogleFonts.orbitron(
                              color: Colors.white,
                              fontSize: 16,
                            ),
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
    return Scaffold(
      backgroundColor: const Color(0xFF1E1E2C),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E1E2C),
        elevation: 0,
        toolbarHeight:
            80, // Increased height to accommodate bigger buttons/padding
        title: Text(
          widget.product.name,
          style: GoogleFonts.orbitron(color: Colors.white),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.cyanAccent),
          onPressed: () => Get.back(),
        ),
        actions: [
          // --- EDIT BUTTON ---
          Padding(
            padding: const EdgeInsets.only(
              top: 10,
              right: 10,
            ), // Moved Down & Left
            child: IconButton(
              iconSize: 28, // Bigger Size
              icon: const Icon(Icons.edit, color: Colors.white),
              tooltip: "Edit Product",
              onPressed: () {
                // Navigate to Add Screen in Edit Mode
                Get.to(() => AddProductScreen(productToEdit: widget.product));
              },
            ),
          ),
          // --- DELETE BUTTON ---
          Padding(
            padding: const EdgeInsets.only(
              top: 10,
              right: 20,
            ), // Moved Down & Left
            child: IconButton(
              iconSize: 28, // Bigger Size
              icon: const Icon(Icons.delete, color: Colors.redAccent),
              tooltip: "Delete Product",
              onPressed: () {
                // Delete Logic with Dialog
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
                      Get.back(); // Close Dialog
                      Get.back(); // Close Detail Screen (Go back to list)
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
                      // Left: Images
                      Expanded(flex: 4, child: _buildImageGallery()),
                      const SizedBox(width: 30),
                      // Right: Details
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
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.image_not_supported,
                    size: 60,
                    color: Colors.white24,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    "No Image Available",
                    style: GoogleFonts.comicNeue(color: Colors.white54),
                  ),
                ],
              ),
            )
          : Stack(
              children: [
                // 1. SLIDABLE IMAGE VIEW (With Mouse Scroll Support)
                ScrollConfiguration(
                  behavior: ScrollConfiguration.of(context).copyWith(
                    dragDevices: {
                      PointerDeviceKind.touch,
                      PointerDeviceKind.mouse, // Enables Mouse Drag
                    },
                  ),
                  child: PageView.builder(
                    itemCount: widget.product.images.length,
                    onPageChanged: (index) {
                      setState(() {
                        _currentImageIndex = index;
                        _transformationController.value = Matrix4.identity();
                      });
                    },
                    itemBuilder: (context, index) {
                      return GestureDetector(
                        onTap: () => _showFullScreenImage(context, index),
                        child: InteractiveViewer(
                          transformationController: _transformationController,
                          maxScale: 3.0,
                          child: Image.memory(
                            base64Decode(widget.product.images[index]),
                            fit: BoxFit.contain,
                            width: double.infinity,
                          ),
                        ),
                      );
                    },
                  ),
                ),

                // 2. ZOOM HINT ICON
                Positioned(
                  top: 10,
                  right: 10,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: IconButton(
                      icon: const Icon(
                        Icons.zoom_in_map,
                        color: Colors.cyanAccent,
                      ),
                      tooltip: "Full Screen Zoom",
                      onPressed: () =>
                          _showFullScreenImage(context, _currentImageIndex),
                    ),
                  ),
                ),

                // 3. IMAGE COUNTER
                if (widget.product.images.length > 1)
                  Positioned(
                    bottom: 15,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          "${_currentImageIndex + 1} / ${widget.product.images.length}",
                          style: GoogleFonts.comicNeue(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
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

        // Title & Model
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

        // Price Section
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFF2A2D3E),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Sale Price",
                    style: TextStyle(color: Colors.white54),
                  ),
                  Text(
                    "\$${widget.product.salePrice}",
                    style: GoogleFonts.orbitron(
                      color: Colors.greenAccent,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Container(height: 40, width: 1, color: Colors.white10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Stock", style: TextStyle(color: Colors.white54)),
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

        // Extra Details
        _buildInfoRow("Brand", widget.product.brand),
        _buildInfoRow("Sub-Category", widget.product.subCategory),

        const SizedBox(height: 30),

        // Vendor Info
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
