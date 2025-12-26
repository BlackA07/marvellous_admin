import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/product_model.dart';

class ProductDetailScreen extends StatelessWidget {
  final ProductModel product;

  const ProductDetailScreen({Key? key, required this.product})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E1E2C),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E1E2C),
        elevation: 0,
        title: Text(
          product.name,
          style: GoogleFonts.orbitron(color: Colors.white),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.cyanAccent),
          onPressed: () => Get.back(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit, color: Colors.white),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.redAccent),
            onPressed: () {},
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
    return Container(
      height: 400,
      decoration: BoxDecoration(
        color: const Color(0xFF2A2D3E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Center(
        child: product.images.isNotEmpty
            ? Image.asset(product.images.first, fit: BoxFit.cover)
            : Column(
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
            product.category,
            style: const TextStyle(
              color: Colors.cyanAccent,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 15),

        // Title & Model
        Text(
          product.name,
          style: GoogleFonts.orbitron(
            color: Colors.white,
            fontSize: 32,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          "Model: ${product.modelNumber}",
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
                    "\$${product.salePrice}",
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
                    "${product.stockQuantity} Units",
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
          product.description.isEmpty
              ? "No description provided."
              : product.description,
          style: GoogleFonts.comicNeue(
            color: Colors.white70,
            fontSize: 16,
            height: 1.5,
          ),
        ),

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
          title: const Text(
            "Global Tech Suppliers",
            style: TextStyle(color: Colors.white),
          ),
          subtitle: const Text(
            "ID: #VEN-001",
            style: TextStyle(color: Colors.white54),
          ),
        ),
      ],
    );
  }
}
