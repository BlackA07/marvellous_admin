// lib/features/products/presentation/screens/pending_requests_screen.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../controller/products_controller.dart';
import 'add_product_screen.dart'; // Aapki pehlay wali original admin screen

class PendingRequestsScreen extends StatelessWidget {
  const PendingRequestsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final ProductsController controller = Get.find<ProductsController>();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        title: Text(
          "Pending Vendor Requests",
          style: GoogleFonts.orbitron(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Obx(() {
        if (controller.pendingRequestsList.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.inbox_outlined, size: 80, color: Colors.grey),
                const SizedBox(height: 15),
                Text(
                  "No pending requests.",
                  style: GoogleFonts.comicNeue(
                    fontSize: 20,
                    color: Colors.grey,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(20),
          itemCount: controller.pendingRequestsList.length,
          itemBuilder: (context, index) {
            final product = controller.pendingRequestsList[index];
            bool hasImage = product.images.isNotEmpty;

            return Card(
              margin: const EdgeInsets.only(bottom: 15),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              elevation: 3,
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 15,
                  vertical: 10,
                ),
                leading: Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color: Colors.grey.shade200,
                    image: hasImage
                        ? DecorationImage(
                            image: MemoryImage(
                              base64Decode(product.images.first),
                            ),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: !hasImage
                      ? const Icon(Icons.image, color: Colors.grey)
                      : null,
                ),
                // ✅ FIX: Title mein Product Name ke sath Live Status Badge add kar diya hai
                title: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        product.name,
                        style: GoogleFonts.orbitron(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: product.status == 'hold'
                            ? Colors.amber.shade100
                            : (product.status == 'rejected'
                                  ? Colors.red.shade100
                                  : Colors.orange.shade100),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        product.status.toUpperCase(),
                        style: TextStyle(
                          color: product.status == 'hold'
                              ? Colors.amber.shade900
                              : (product.status == 'rejected'
                                    ? Colors.red.shade900
                                    : Colors.orange.shade900),
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 5),
                    Text(
                      "By: ${product.vendorName}",
                      style: const TextStyle(
                        color: Colors.blueAccent,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      "Category: ${product.category} > ${product.subCategory}",
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      "Purchase Price: PKR ${product.purchasePrice.toStringAsFixed(0)}",
                      style: TextStyle(
                        color: Colors.green.shade400,
                        fontWeight: FontWeight.w900,
                        fontSize: 14,
                      ),
                    ),
                    if (product.brand.isNotEmpty ||
                        product.modelNumber.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 2.0),
                        child: Text(
                          [
                            if (product.brand.isNotEmpty)
                              "Brand: ${product.brand}",
                            if (product.modelNumber.isNotEmpty)
                              "Model: ${product.modelNumber}",
                          ].join("  |  "),
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    // ✅ FIX: Admin ko ab actual hold reason nazar aayega!
                    if (product.status == 'hold')
                      Padding(
                        padding: const EdgeInsets.only(top: 6.0),
                        child: Text(
                          "Hold Reason: ${product.holdReason ?? 'Reason not provided'}",
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.amber.shade400,
                          ),
                        ),
                      ),
                  ],
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Review Button (same)
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                      ),
                      icon: const Icon(
                        Icons.edit_document,
                        color: Colors.white,
                        size: 18,
                      ),
                      label: const Text(
                        "Review",
                        style: TextStyle(color: Colors.white),
                      ),
                      onPressed: () => Get.to(
                        () => AddProductScreen(productToEdit: product),
                      ),
                    ),
                    const SizedBox(width: 6),
                    // Hold Button (same)
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                      ),
                      icon: const Icon(
                        Icons.pause_circle,
                        color: Colors.white,
                        size: 18,
                      ),
                      label: const Text(
                        "Hold",
                        style: TextStyle(color: Colors.white),
                      ),
                      onPressed: () =>
                          _showHoldDialog(context, controller, product.id!),
                    ),
                    const SizedBox(width: 6),
                    // Delete/Reject Button (same)
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () {
                        Get.defaultDialog(
                          title: "Reject Request?",
                          middleText:
                              "Are you sure you want to reject this product?",
                          textConfirm: "Yes, Reject",
                          confirmTextColor: Colors.white,
                          buttonColor: Colors.red,
                          onConfirm: () {
                            controller.rejectRequest(product.id!);
                            Get.back();
                          },
                          onCancel: () {},
                        );
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        );
      }),
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
