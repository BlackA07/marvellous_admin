// lib/features/products/presentation/screens/pending_requests_screen.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../controller/products_controller.dart';
import 'add_product_screen.dart'; // Aapki pehlay wali original admin screen

class PendingRequestsScreen extends StatefulWidget {
  const PendingRequestsScreen({Key? key}) : super(key: key);

  @override
  State<PendingRequestsScreen> createState() => _PendingRequestsScreenState();
}

class _PendingRequestsScreenState extends State<PendingRequestsScreen> {
  String _selectedFilter = 'all';

  @override
  Widget build(BuildContext context) {
    final ProductsController controller = Get.find<ProductsController>();

    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2A2A2A),
        elevation: 1,
        title: Text(
          "Pending Vendor Requests",
          style: GoogleFonts.orbitron(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Obx(() {
        // ── Latest first sort ──
        final allList = controller.pendingRequestsList.toList()
          ..sort((a, b) => b.dateAdded.compareTo(a.dateAdded));

        // ── Filter apply ──
        final filtered = _selectedFilter == 'all'
            ? allList
            : allList.where((p) => p.status == _selectedFilter).toList();

        return Column(
          children: [
            // ── Filter Chips ──
            Container(
              color: const Color(0xFF2A2A2A),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _filterChip(
                      'all',
                      'All',
                      Colors.blueAccent,
                      allList.length,
                    ),
                    const SizedBox(width: 8),
                    _filterChip(
                      'pending',
                      'Pending',
                      Colors.orange,
                      allList.where((p) => p.status == 'pending').length,
                    ),
                    const SizedBox(width: 8),
                    _filterChip(
                      'hold',
                      'Hold',
                      Colors.amber,
                      allList.where((p) => p.status == 'hold').length,
                    ),
                    const SizedBox(width: 8),
                    _filterChip(
                      'rejected',
                      'Rejected',
                      Colors.red,
                      allList.where((p) => p.status == 'rejected').length,
                    ),
                  ],
                ),
              ),
            ),

            // ── List ──
            Expanded(
              child: filtered.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.inbox_outlined,
                            size: 80,
                            color: Colors.grey,
                          ),
                          const SizedBox(height: 15),
                          Text(
                            "No ${_selectedFilter == 'all' ? '' : _selectedFilter} requests.",
                            style: GoogleFonts.comicNeue(
                              fontSize: 18,
                              color: Colors.grey,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        final product = filtered[index];
                        bool hasImage = product.images.isNotEmpty;

                        return Card(
                          color: const Color(0xFF2A2A2A),
                          margin: const EdgeInsets.only(bottom: 15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                          elevation: 3,
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Image
                                Container(
                                  width: 60,
                                  height: 60,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(10),
                                    color: Colors.grey.shade800,
                                    image: hasImage
                                        ? DecorationImage(
                                            image: _getImageProvider(
                                              product.images.first,
                                            ),
                                            fit: BoxFit.cover,
                                          )
                                        : null,
                                  ),
                                  child: !hasImage
                                      ? const Icon(
                                          Icons.image,
                                          color: Colors.grey,
                                        )
                                      : null,
                                ),
                                const SizedBox(width: 12),

                                // Content
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              product.name,
                                              style: GoogleFonts.orbitron(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 13,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ),
                                          _statusBadge(product.status),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        "By: ${product.vendorName}",
                                        style: const TextStyle(
                                          color: Colors.blueAccent,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                        ),
                                      ),
                                      Text(
                                        "Category: ${product.category} > ${product.subCategory}",
                                        style: const TextStyle(
                                          fontSize: 11,
                                          color: Colors.white54,
                                        ),
                                      ),
                                      Text(
                                        "Purchase: PKR ${product.purchasePrice.toStringAsFixed(0)}",
                                        style: TextStyle(
                                          color: Colors.green.shade400,
                                          fontWeight: FontWeight.w900,
                                          fontSize: 13,
                                        ),
                                      ),
                                      if (product.brand.isNotEmpty ||
                                          product.modelNumber.isNotEmpty)
                                        Text(
                                          [
                                            if (product.brand.isNotEmpty)
                                              "Brand: ${product.brand}",
                                            if (product.modelNumber.isNotEmpty)
                                              "Model: ${product.modelNumber}",
                                          ].join("  |  "),
                                          style: const TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white70,
                                          ),
                                        ),
                                      if (product.status == 'hold')
                                        Padding(
                                          padding: const EdgeInsets.only(
                                            top: 4,
                                          ),
                                          child: Text(
                                            "Hold: ${product.holdReason ?? 'No reason'}",
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.amber.shade400,
                                            ),
                                          ),
                                        ),
                                      const SizedBox(height: 10),

                                      // Buttons
                                      Row(
                                        children: [
                                          Expanded(
                                            child: ElevatedButton.icon(
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: Colors.green,
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      vertical: 8,
                                                    ),
                                              ),
                                              icon: const Icon(
                                                Icons.edit_document,
                                                color: Colors.white,
                                                size: 16,
                                              ),
                                              label: const Text(
                                                "Review",
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 12,
                                                ),
                                              ),
                                              onPressed: () => Get.to(
                                                () => AddProductScreen(
                                                  productToEdit: product,
                                                ),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 6),
                                          Expanded(
                                            child: ElevatedButton.icon(
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: Colors.orange,
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      vertical: 8,
                                                    ),
                                              ),
                                              icon: const Icon(
                                                Icons.pause_circle,
                                                color: Colors.white,
                                                size: 16,
                                              ),
                                              label: const Text(
                                                "Hold",
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 12,
                                                ),
                                              ),
                                              onPressed: () => _showHoldDialog(
                                                context,
                                                controller,
                                                product.id!,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 6),
                                          IconButton(
                                            icon: const Icon(
                                              Icons.delete,
                                              color: Colors.red,
                                            ),
                                            onPressed: () {
                                              Get.defaultDialog(
                                                title: "Reject Request?",
                                                middleText:
                                                    "Are you sure you want to reject this product?",
                                                textConfirm: "Yes, Reject",
                                                confirmTextColor: Colors.white,
                                                buttonColor: Colors.red,
                                                onConfirm: () {
                                                  controller.rejectRequest(
                                                    product.id!,
                                                  );
                                                  Get.back();
                                                },
                                                onCancel: () {},
                                              );
                                            },
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        );
      }),
    );
  }

  Widget _filterChip(String value, String label, Color color, int count) {
    final bool isSelected = _selectedFilter == value;
    return GestureDetector(
      onTap: () => setState(() => _selectedFilter = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? color : color.withOpacity(0.15),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? color : color.withOpacity(0.4),
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : color,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: isSelected ? Colors.white24 : color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                count.toString(),
                style: TextStyle(
                  color: isSelected ? Colors.white : color,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  ImageProvider _getImageProvider(String imageStr) {
    if (imageStr.startsWith('http')) {
      return NetworkImage(imageStr); // Cloudinary URL
    }
    try {
      return MemoryImage(base64Decode(imageStr)); // Base64
    } catch (e) {
      return const AssetImage('assets/images/placeholder.png'); // fallback
    }
  }

  Widget _statusBadge(String status) {
    Color bg;
    Color text;
    switch (status) {
      case 'hold':
        bg = Colors.amber.shade100;
        text = Colors.amber.shade900;
        break;
      case 'rejected':
        bg = Colors.red.shade100;
        text = Colors.red.shade900;
        break;
      default:
        bg = Colors.orange.shade100;
        text = Colors.orange.shade900;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          color: text,
          fontWeight: FontWeight.bold,
          fontSize: 10,
        ),
      ),
    );
  }
}

void _showHoldDialog(
  BuildContext context,
  ProductsController controller,
  String productId,
) {
  final reasonCtrl = TextEditingController();
  Get.defaultDialog(
    title: "Hold Request",
    content: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: TextField(
        controller: reasonCtrl,
        maxLines: 3,
        decoration: const InputDecoration(
          hintText: "Reason for holding (e.g. price zyada hai...)",
          border: OutlineInputBorder(),
        ),
      ),
    ),
    textConfirm: "Hold",
    confirmTextColor: Colors.white,
    buttonColor: Colors.orange,
    onConfirm: () {
      if (reasonCtrl.text.trim().isEmpty) {
        Get.snackbar(
          "Required",
          "Please enter a reason",
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        return;
      }
      controller.holdRequest(productId, reasonCtrl.text.trim());
      Get.back();
    },
    onCancel: () {},
  );
}
