import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../controllers/vendor_controller.dart';
import 'add_vendor_screen.dart';
import 'vendor_detail_screen.dart'; // Import the new detail screen

class VendorsListScreen extends StatelessWidget {
  VendorsListScreen({Key? key}) : super(key: key);

  final VendorController controller = Get.put(VendorController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.cyanAccent,
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddVendorScreen()),
          );
        },
        label: const Text(
          "Add Vendor",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        icon: const Icon(Icons.person_add, color: Colors.black),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "All Vendors",
              style: GoogleFonts.orbitron(color: Colors.white, fontSize: 22),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF2A2D3E),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white10),
                ),
                child: Obx(() {
                  if (controller.isLoading.value) {
                    return const Center(
                      child: CircularProgressIndicator(
                        color: Colors.cyanAccent,
                      ),
                    );
                  }
                  if (controller.vendors.isEmpty) {
                    return const Center(
                      child: Text(
                        "No Vendors Found",
                        style: TextStyle(color: Colors.white54),
                      ),
                    );
                  }

                  return ListView.separated(
                    itemCount: controller.vendors.length,
                    separatorBuilder: (ctx, i) =>
                        const Divider(color: Colors.white10),
                    itemBuilder: (context, index) {
                      final vendor = controller.vendors[index];
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.cyanAccent.withOpacity(0.2),
                          child: Text(
                            vendor.name.isNotEmpty
                                ? vendor.name[0].toUpperCase()
                                : "V",
                            style: const TextStyle(color: Colors.cyanAccent),
                          ),
                        ),
                        title: Text(
                          vendor.storeName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: Text(
                          "${vendor.name} • ${vendor.phone}",
                          style: const TextStyle(color: Colors.white54),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // VIEW DETAIL
                            IconButton(
                              icon: const Icon(
                                Icons.visibility,
                                color: Colors.blueAccent,
                              ),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        VendorDetailScreen(vendor: vendor),
                                  ),
                                );
                              },
                            ),
                            // EDIT
                            IconButton(
                              icon: const Icon(
                                Icons.edit,
                                color: Colors.orangeAccent,
                              ),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        AddVendorScreen(vendorToEdit: vendor),
                                  ),
                                );
                              },
                            ),
                            // DELETE WITH CONFIRMATION
                            IconButton(
                              icon: const Icon(
                                Icons.delete,
                                color: Colors.redAccent,
                              ),
                              onPressed: () {
                                Get.defaultDialog(
                                  title: "Delete Vendor?",
                                  titleStyle: GoogleFonts.orbitron(
                                    color: Colors.white,
                                  ),
                                  backgroundColor: const Color(0xFF2A2D3E),
                                  middleText:
                                      "Are you sure you want to delete ${vendor.storeName}?\nThis action can be undone briefly.",
                                  middleTextStyle: const TextStyle(
                                    color: Colors.white70,
                                  ),
                                  textConfirm: "Yes, Delete",
                                  textCancel: "Cancel",
                                  confirmTextColor: Colors.white,
                                  buttonColor: Colors.redAccent,
                                  cancelTextColor: Colors.cyanAccent,
                                  onConfirm: () {
                                    Get.back(); // Close Dialog
                                    controller.deleteVendor(vendor);
                                  },
                                );
                              },
                            ),
                          ],
                        ),
                      );
                    },
                  );
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
