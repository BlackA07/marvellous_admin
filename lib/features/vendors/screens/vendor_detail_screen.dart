import 'dart:convert'; // For base64 decode
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:marvellous_admin/features/products/presentation/screens/add_product_screen.dart';
import 'package:marvellous_admin/features/products/presentation/screens/product_detail_screen.dart';
import '../models/vendor_model.dart';
import 'add_vendor_screen.dart';
import '../controllers/vendor_controller.dart';
import '../../products/models/product_model.dart'; // Import Product Model

class VendorDetailScreen extends StatelessWidget {
  final VendorModel vendor;

  // Controller inject karke vendor ke products fetch karenge
  final VendorController controller = Get.find();

  VendorDetailScreen({Key? key, required this.vendor}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Screen open hote hi products fetch karo is vendor ke liye
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.fetchVendorProducts(vendor.id!);
    });

    return Scaffold(
      backgroundColor: const Color(0xFF1E1E2C),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          vendor.storeName,
          style: GoogleFonts.orbitron(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit, color: Colors.cyanAccent),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AddVendorScreen(vendorToEdit: vendor),
                ),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. VENDOR DETAILS CARD
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF2A2D3E),
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: Colors.white10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 30,
                        backgroundColor: Colors.cyanAccent.withOpacity(0.2),
                        child: Text(
                          vendor.name.isNotEmpty
                              ? vendor.name[0].toUpperCase()
                              : "V",
                          style: GoogleFonts.orbitron(
                            color: Colors.cyanAccent,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 15),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            vendor.name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            "Speciality: ${vendor.speciality}",
                            style: const TextStyle(
                              color: Colors.cyanAccent,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const Divider(color: Colors.white24, height: 30),
                  _buildDetailRow(Icons.phone, "Phone", vendor.phone),
                  const SizedBox(height: 15),
                  _buildDetailRow(Icons.badge, "CNIC", vendor.cnic),
                  const SizedBox(height: 15),
                  _buildDetailRow(Icons.location_on, "Address", vendor.address),
                ],
              ),
            ),

            const SizedBox(height: 30),

            // 2. VENDOR PRODUCTS SECTION HEADER
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Vendor Products",
                  style: GoogleFonts.orbitron(
                    color: Colors.white,
                    fontSize: 20,
                  ),
                ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.cyanAccent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: () {
                    // Navigate to Add Product Screen
                    // Pass vendor.id as preSelectedVendorId
                    // Get.to(
                    //   () => AddProductScreen(preSelectedVendorId: vendor.id),
                    // );
                  },
                  icon: const Icon(Icons.add, color: Colors.black, size: 18),
                  label: const Text(
                    "Add Product",
                    style: TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 15),

            // 3. PRODUCTS LIST
            Obx(() {
              if (controller.isProductsLoading.value) {
                return const Center(
                  child: CircularProgressIndicator(color: Colors.cyanAccent),
                );
              }

              if (controller.vendorProducts.isEmpty) {
                return Container(
                  width: double.infinity,
                  height: 200,
                  decoration: BoxDecoration(
                    color: const Color(0xFF2A2D3E).withOpacity(0.5),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white10),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(
                          Icons.inventory_2_outlined,
                          color: Colors.white24,
                          size: 40,
                        ),
                        SizedBox(height: 10),
                        Text(
                          "No products linked to this vendor yet.",
                          style: TextStyle(color: Colors.white54),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return ListView.builder(
                shrinkWrap: true, // Needed inside SingleScrollView
                physics:
                    const NeverScrollableScrollPhysics(), // Scroll parent instead
                itemCount: controller.vendorProducts.length,
                itemBuilder: (context, index) {
                  final ProductModel product = controller.vendorProducts[index];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2A2D3E),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.white10),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(10),
                      leading: Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: Colors.black26,
                          borderRadius: BorderRadius.circular(8),
                          image: product.images.isNotEmpty
                              ? DecorationImage(
                                  image: MemoryImage(
                                    base64Decode(product.images.first),
                                  ),
                                  fit: BoxFit.cover,
                                )
                              : null,
                        ),
                        child: product.images.isEmpty
                            ? const Icon(Icons.image, color: Colors.white24)
                            : null,
                      ),
                      title: Text(
                        product.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: Text(
                        "${product.modelNumber} • Stock: ${product.stockQuantity}",
                        style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 12,
                        ),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(
                              Icons.visibility,
                              color: Colors.blueAccent,
                              size: 20,
                            ),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      ProductDetailScreen(product: product),
                                ),
                              );
                            },
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.edit,
                              color: Colors.orangeAccent,
                              size: 20,
                            ),
                            onPressed: () {
                              Get.to(
                                () => AddProductScreen(productToEdit: product),
                              );
                            },
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.delete,
                              color: Colors.redAccent,
                              size: 20,
                            ),
                            onPressed: () {
                              Get.defaultDialog(
                                title: "Delete Product?",
                                titleStyle: GoogleFonts.orbitron(
                                  color: Colors.white,
                                ),
                                backgroundColor: const Color(0xFF2A2D3E),
                                middleText:
                                    "Are you sure you want to delete ${product.name}?",
                                middleTextStyle: const TextStyle(
                                  color: Colors.white70,
                                ),
                                textConfirm: "Delete",
                                textCancel: "Cancel",
                                confirmTextColor: Colors.white,
                                buttonColor: Colors.redAccent,
                                onConfirm: () {
                                  Get.back();
                                  controller.deleteProductFromVendor(product);
                                },
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
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: Colors.white54, size: 20),
        const SizedBox(width: 15),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(color: Colors.white54, fontSize: 12),
              ),
              const SizedBox(height: 4),
              Text(
                value.isEmpty ? "N/A" : value,
                style: const TextStyle(color: Colors.white, fontSize: 16),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
