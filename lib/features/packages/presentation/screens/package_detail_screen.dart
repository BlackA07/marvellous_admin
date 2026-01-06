import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:marvellous_admin/features/products/controller/products_controller.dart';
import '../../../products/models/product_model.dart';

class PackageDetailScreen extends StatelessWidget {
  final ProductModel package;
  const PackageDetailScreen({Key? key, required this.package})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    final ProductsController controller = Get.find<ProductsController>();

    // Find actual product objects from IDs
    List<ProductModel> includedItems = controller.productsOnly
        .where((p) => package.includedItemIds.contains(p.id))
        .toList();

    return Scaffold(
      backgroundColor: const Color(0xFF1E1E2C),
      appBar: AppBar(
        title: Text(
          package.name,
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
            // Header Image
            Container(
              height: 200,
              width: double.infinity,
              decoration: BoxDecoration(
                color: const Color(0xFF2A2D3E),
                borderRadius: BorderRadius.circular(15),
                image: package.images.isNotEmpty
                    ? DecorationImage(
                        image: MemoryImage(base64Decode(package.images.first)),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: package.images.isEmpty
                  ? const Icon(
                      Icons.inventory_2,
                      size: 50,
                      color: Colors.white24,
                    )
                  : null,
            ),
            const SizedBox(height: 20),

            // Info Card
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: const Color(0xFF2A2D3E),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Bundle Price",
                        style: TextStyle(color: Colors.white54),
                      ),
                      Text(
                        "PKR ${package.salePrice}",
                        style: GoogleFonts.orbitron(
                          color: Colors.greenAccent,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Stock",
                        style: TextStyle(color: Colors.white54),
                      ),
                      Text(
                        "${package.stockQuantity} Units",
                        style: GoogleFonts.orbitron(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),
            Text(
              "Included Items (${includedItems.length})",
              style: GoogleFonts.orbitron(
                color: Colors.cyanAccent,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 10),

            // List of items inside
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
            Text(
              "Description",
              style: GoogleFonts.orbitron(
                color: Colors.purpleAccent,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              package.description,
              style: GoogleFonts.comicNeue(color: Colors.white70, fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}
