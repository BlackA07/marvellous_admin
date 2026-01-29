import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart'; // Settings fetch karne k liye
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // For Keyboard Input
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

  // Magnifier Variables
  Offset? _dragPosition;
  bool _showMagnifier = false;
  final FocusNode _focusNode = FocusNode(); // Focus node for keyboard events

  @override
  void initState() {
    super.initState();
    // Request focus so keyboard events work immediately on the main screen
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) FocusScope.of(context).requestFocus(_focusNode);
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  // --- Keyboard Navigation Logic (Main Screen) ---
  void _handleKeyEvent(RawKeyEvent event) {
    if (event is RawKeyDownEvent) {
      if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
        _nextImage();
      } else if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
        _previousImage();
      }
    }
  }

  void _nextImage() {
    setState(() {
      _currentImageIndex++;
      if (_currentImageIndex >= widget.product.images.length) {
        _currentImageIndex = 0; // Infinite Scroll Loop
      }
    });
  }

  void _previousImage() {
    setState(() {
      _currentImageIndex--;
      if (_currentImageIndex < 0) {
        _currentImageIndex =
            widget.product.images.length - 1; // Infinite Scroll Loop
      }
    });
  }

  // --- Show Full Screen Image Dialog ---
  void _showFullScreenImage(BuildContext context, int initialIndex) {
    showDialog(
      context: context,
      builder: (context) {
        // Using a separate StatefulWidget ensures FocusNode and Controllers are disposed correctly
        return FullScreenImageViewer(
          images: widget.product.images,
          initialIndex: initialIndex,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return RawKeyboardListener(
      focusNode: _focusNode,
      autofocus: true, // Auto focus specifically for this screen
      onKey: _handleKeyEvent,
      child: Scaffold(
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
      ),
    );
  }

  Widget _buildImageGallery() {
    bool hasImages = widget.product.images.isNotEmpty;
    return Stack(
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
              : GestureDetector(
                  onTap: () =>
                      _showFullScreenImage(context, _currentImageIndex),
                  // --- MAGNIFIER LOGIC START ---
                  // Triggered on Long Press or Drag
                  onLongPressStart: (details) {
                    setState(() {
                      _showMagnifier = true;
                      _dragPosition = details.localPosition;
                    });
                  },
                  onLongPressMoveUpdate: (details) {
                    setState(() {
                      _dragPosition = details.localPosition;
                    });
                  },
                  onLongPressEnd: (details) {
                    setState(() {
                      _showMagnifier = false;
                      _dragPosition = null;
                    });
                  },
                  // --- MAGNIFIER LOGIC END ---
                  child: Stack(
                    children: [
                      // Base Image
                      Positioned.fill(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Image.memory(
                            base64Decode(
                              widget.product.images[_currentImageIndex],
                            ),
                            fit: BoxFit
                                .contain, // Show FULL image without cropping
                          ),
                        ),
                      ),

                      // The Magnifying Glass Lens
                      if (_showMagnifier && _dragPosition != null)
                        Positioned(
                          left: _dragPosition!.dx - 60, // Centering lens
                          top: _dragPosition!.dy - 60,
                          child: RawMagnifier(
                            decoration: const MagnifierDecoration(
                              shape: CircleBorder(
                                side: BorderSide(
                                  color: Colors.cyanAccent,
                                  width: 3,
                                ),
                              ),
                              opacity: 1.0,
                            ),
                            size: const Size(120, 120), // Bigger Lens
                            magnificationScale: 2.0, // 2x Zoom
                            focalPointOffset: Offset(
                              _dragPosition!.dx - 60,
                              _dragPosition!.dy - 60,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
        ),

        // Image Counter
        if (hasImages)
          Positioned(
            bottom: 15,
            right: 15,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.7),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                "${_currentImageIndex + 1} / ${widget.product.images.length}",
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),

        // Navigation Arrows
        if (hasImages && widget.product.images.length > 1) ...[
          Positioned(
            left: 10,
            top: 0,
            bottom: 0,
            child: Center(
              child: IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    color: Colors.black45,
                    borderRadius: BorderRadius.circular(50),
                  ),
                  child: const Icon(
                    Icons.arrow_back_ios,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                onPressed: _previousImage,
              ),
            ),
          ),
          Positioned(
            right: 10,
            top: 0,
            bottom: 0,
            child: Center(
              child: IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    color: Colors.black45,
                    borderRadius: BorderRadius.circular(50),
                  ),
                  child: const Icon(
                    Icons.arrow_forward_ios,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                onPressed: _nextImage,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildProductDetails() {
    // --- POINTS CALCULATION LOGIC ---
    // Fetching from Firestore to get 'profitPerPoint'
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('admin_settings')
          .doc('global_config')
          .snapshots(),
      builder: (context, snapshot) {
        double profitPerPoint = 100.0; // Default
        bool showDecimals = true;

        if (snapshot.hasData && snapshot.data!.exists) {
          final data = snapshot.data!.data() as Map<String, dynamic>;
          profitPerPoint = (data['profitPerPoint'] ?? 100.0).toDouble();
          showDecimals = data['showDecimals'] ?? true;
        }

        // Formula: (Sale Price - Purchase Price) / ProfitPerPoint
        double grossProfit =
            widget.product.salePrice - widget.product.purchasePrice;
        double calculatedPoints = 0;

        if (profitPerPoint > 0) {
          calculatedPoints = grossProfit / profitPerPoint;
        }
        if (calculatedPoints < 0) calculatedPoints = 0; // No negative points

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Brand
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.cyanAccent.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.cyanAccent),
              ),
              child: Text(
                widget.product.brand,
                style: const TextStyle(
                  color: Colors.cyanAccent,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 15),

            // Name & Model
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

            // PRICE & STOCK
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
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Price",
                              style: TextStyle(color: Colors.white54),
                            ),
                            Text(
                              "PKR ${widget.product.salePrice}",
                              style: GoogleFonts.comicNeue(
                                color: Colors.greenAccent,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        height: 40,
                        width: 1,
                        color: Colors.white10,
                        margin: const EdgeInsets.symmetric(horizontal: 10),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Stock",
                              style: TextStyle(color: Colors.white54),
                            ),
                            Text(
                              "${widget.product.stockQuantity}",
                              style: GoogleFonts.comicNeue(
                                color: Colors.white,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Calculated Points Display
                  Row(
                    children: [
                      const Icon(Icons.star, color: Colors.amber, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        // Displaying Calculated Points
                        "Earned Points: ${showDecimals ? calculatedPoints.toStringAsFixed(1) : calculatedPoints.toInt()}",
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

            const SizedBox(height: 20),

            // --- DESCRIPTION RESTORED ---
            Text(
              "Description",
              style: GoogleFonts.orbitron(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: const Color(0xFF2A2D3E),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                widget.product.description.isEmpty
                    ? "No description available."
                    : widget.product.description,
                style: GoogleFonts.comicNeue(
                  color: Colors.white70,
                  fontSize: 14,
                ),
              ),
            ),
            const SizedBox(height: 20),

            _buildInfoRow("Category", widget.product.category),
            _buildInfoRow("Sub-Category", widget.product.subCategory),
            _buildInfoRow("Location", widget.product.deliveryLocation),
            _buildInfoRow("Warranty", widget.product.warranty),

            const SizedBox(height: 20),
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
      },
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

// --- NEW WIDGET: FIX FOR ADDLISTENER ERROR ---
// Extracting Dialog to a StatefulWidget ensures dispose() is called correctly
class FullScreenImageViewer extends StatefulWidget {
  final List<String> images;
  final int initialIndex;

  const FullScreenImageViewer({
    Key? key,
    required this.images,
    required this.initialIndex,
  }) : super(key: key);

  @override
  State<FullScreenImageViewer> createState() => _FullScreenImageViewerState();
}

class _FullScreenImageViewerState extends State<FullScreenImageViewer> {
  late PageController _pageController;
  late int _currentIndex;
  final FocusNode _dialogFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
    // Safe focus request
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _dialogFocusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _dialogFocusNode.dispose(); // This fixes the 'addListener' error
    super.dispose();
  }

  void _goToNext() {
    setState(() {
      _currentIndex++;
      if (_currentIndex >= widget.images.length) _currentIndex = 0;
      _pageController.jumpToPage(_currentIndex);
    });
  }

  void _goToPrevious() {
    setState(() {
      _currentIndex--;
      if (_currentIndex < 0) _currentIndex = widget.images.length - 1;
      _pageController.jumpToPage(_currentIndex);
    });
  }

  @override
  Widget build(BuildContext context) {
    return RawKeyboardListener(
      focusNode: _dialogFocusNode,
      onKey: (event) {
        if (event is RawKeyDownEvent) {
          if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
            _goToNext();
          } else if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
            _goToPrevious();
          } else if (event.logicalKey == LogicalKeyboardKey.escape) {
            Navigator.pop(context);
          }
        }
      },
      child: Dialog(
        backgroundColor: Colors.black, // Full black background
        insetPadding: EdgeInsets.zero, // Full screen logic
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Image Viewer
            PageView.builder(
              controller: _pageController,
              itemCount: widget.images.length,
              onPageChanged: (index) {
                setState(() {
                  _currentIndex = index;
                });
              },
              itemBuilder: (context, index) {
                final imageBytes = base64Decode(widget.images[index]);
                // InteractiveViewer for Zooming with fingers in Dialog
                return InteractiveViewer(
                  minScale: 0.1,
                  maxScale: 5.0,
                  child: Center(
                    child: Image.memory(
                      imageBytes,
                      fit: BoxFit.contain, // Show FULL image
                    ),
                  ),
                );
              },
            ),

            // Close Button
            Positioned(
              top: 40,
              right: 20,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 30),
                onPressed: () => Navigator.pop(context),
              ),
            ),

            // Counter
            Positioned(
              bottom: 40,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  "${_currentIndex + 1} / ${widget.images.length}",
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

            // Dialog Navigation Arrows (Visual)
            if (widget.images.length > 1) ...[
              Positioned(
                left: 10,
                child: IconButton(
                  icon: const Icon(
                    Icons.arrow_back_ios,
                    color: Colors.white,
                    size: 40,
                  ),
                  onPressed: _goToPrevious,
                ),
              ),
              Positioned(
                right: 10,
                child: IconButton(
                  icon: const Icon(
                    Icons.arrow_forward_ios,
                    color: Colors.white,
                    size: 40,
                  ),
                  onPressed: _goToNext,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
