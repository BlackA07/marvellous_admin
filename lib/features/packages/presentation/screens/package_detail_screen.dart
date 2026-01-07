import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:marvellous_admin/features/products/controller/products_controller.dart';
import '../../../products/models/product_model.dart';

class PackageDetailScreen extends StatefulWidget {
  final ProductModel package;
  const PackageDetailScreen({Key? key, required this.package})
    : super(key: key);

  @override
  State<PackageDetailScreen> createState() => _PackageDetailScreenState();
}

class _PackageDetailScreenState extends State<PackageDetailScreen> {
  int _currentImageIndex = 0;
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
                        base64Decode(widget.package.images[dialogIndex]),
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
    final ProductsController controller = Get.find<ProductsController>();

    // Find actual product objects from IDs
    List<ProductModel> includedItems = controller.productsOnly
        .where((p) => widget.package.includedItemIds.contains(p.id))
        .toList();

    return Scaffold(
      backgroundColor: const Color(0xFF1E1E2C),
      appBar: AppBar(
        title: Text(
          widget.package.name,
          style: GoogleFonts.orbitron(color: Colors.white),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Get.back(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. IMAGE GALLERY
            _buildImageGallery(),

            const SizedBox(height: 20),

            // 2. INFO CARD (Price + Points)
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: const Color(0xFF2A2D3E),
                borderRadius: BorderRadius.circular(15),
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
                            "Bundle Price",
                            style: TextStyle(color: Colors.white54),
                          ),
                          // CHANGED: Simple Font
                          Text(
                            "PKR ${widget.package.salePrice}",
                            style: GoogleFonts.comicNeue(
                              color: Colors.greenAccent,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      // Points Display
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const Text(
                            "Points",
                            style: TextStyle(color: Colors.white54),
                          ),
                          Row(
                            children: [
                              const Icon(
                                Icons.star,
                                color: Colors.amber,
                                size: 18,
                              ),
                              const SizedBox(width: 5),
                              Text(
                                widget.package.showDecimalPoints
                                    ? "${widget.package.productPoints.toStringAsFixed(1)}"
                                    : "${widget.package.productPoints.toInt()}",
                                style: GoogleFonts.comicNeue(
                                  color: Colors.amber,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // 3. INCLUDED ITEMS
            Text(
              "Included Items (${includedItems.length})",
              style: GoogleFonts.orbitron(
                color: Colors.cyanAccent,
                fontSize: 18,
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
                    color: const Color(0xFF2A2D3E),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: ListTile(
                    leading: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.grey[800],
                        borderRadius: BorderRadius.circular(5),
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
                      style: const TextStyle(color: Colors.white),
                    ),
                    subtitle: Text(
                      item.modelNumber,
                      style: const TextStyle(color: Colors.white54),
                    ),
                    trailing: Text(
                      "PKR ${item.purchasePrice}",
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 20),

            // 4. DESCRIPTION
            Text(
              "Description",
              style: GoogleFonts.orbitron(
                color: Colors.purpleAccent,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              widget.package.description,
              style: GoogleFonts.comicNeue(color: Colors.white70, fontSize: 16),
            ),

            // 5. BOTTOM PADDING
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  Widget _buildImageGallery() {
    bool hasImages = widget.package.images.isNotEmpty;
    return Column(
      children: [
        Stack(
          children: [
            Container(
              height: 300, // Slightly smaller than product detail for package
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
                      behavior: ScrollConfiguration.of(context).copyWith(
                        dragDevices: {
                          PointerDeviceKind.touch,
                          PointerDeviceKind.mouse,
                        },
                      ),
                      child: PageView.builder(
                        itemCount: widget.package.images.length,
                        onPageChanged: (index) =>
                            setState(() => _currentImageIndex = index),
                        itemBuilder: (context, index) {
                          final imageBytes = base64Decode(
                            widget.package.images[index],
                          );

                          // MAGNIFIER LOGIC (Same as Product Detail)
                          return GestureDetector(
                            onTap: () => _showFullScreenImage(context, index),
                            onPanStart: (details) =>
                                _magnifierPositionNotifier.value =
                                    details.localPosition,
                            onPanUpdate: (details) =>
                                _magnifierPositionNotifier.value =
                                    details.localPosition,
                            onPanEnd: (_) =>
                                _magnifierPositionNotifier.value = null,
                            behavior: HitTestBehavior.opaque,
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                Image.memory(imageBytes, fit: BoxFit.contain),
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
                                        magnificationScale: 2.0,
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
            ),

            // Image Counter
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
                        ? Colors.cyanAccent
                        : Colors.white24,
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
