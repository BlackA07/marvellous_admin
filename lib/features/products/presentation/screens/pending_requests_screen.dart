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
                title: Text(
                  product.name,
                  style: GoogleFonts.orbitron(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
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
                  ],
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Review / Approve Button
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
                      onPressed: () {
                        // ✅ IS SE WAHI ADD PRODUCT SCREEN KHULEGI, LAIKIN DATA BARA HUA HOGA
                        Get.to(() => AddProductScreen(productToEdit: product));
                      },
                    ),
                    const SizedBox(width: 10),
                    // Reject Button
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      tooltip: "Reject Request",
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
