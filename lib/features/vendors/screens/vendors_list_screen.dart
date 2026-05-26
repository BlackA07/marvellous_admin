import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../controllers/vendor_controller.dart';
import 'vendor_detail_screen.dart';

class VendorsListScreen extends StatelessWidget {
  VendorsListScreen({Key? key}) : super(key: key);

  final VendorController controller = Get.put(VendorController());

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return Colors.greenAccent;
      case 'rejected':
        return Colors.redAccent;
      case 'pending':
        return Colors.orangeAccent;
      default:
        return Colors.white38;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'All Vendors',
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
                        'No Vendors Found',
                        style: TextStyle(color: Colors.white54),
                      ),
                    );
                  }

                  return ListView.separated(
                    itemCount: controller.vendors.length,
                    separatorBuilder: (ctx, i) =>
                        const Divider(color: Colors.white10, height: 1),
                    itemBuilder: (context, index) {
                      final vendor = controller.vendors[index];

                      // Avatar: profileImage > storePictures[0] > letter
                      final String? imgBase64 =
                          (vendor.profileImage != null &&
                              vendor.profileImage!.trim().isNotEmpty)
                          ? vendor.profileImage
                          : vendor.storePictures.isNotEmpty
                          ? vendor.storePictures.first
                          : null;

                      Widget avatarWidget;
                      if (imgBase64 != null) {
                        avatarWidget = CircleAvatar(
                          radius: 24,
                          backgroundImage: MemoryImage(base64Decode(imgBase64)),
                        );
                      } else {
                        avatarWidget = CircleAvatar(
                          radius: 24,
                          backgroundColor: Colors.cyanAccent.withOpacity(0.2),
                          child: Text(
                            vendor.avatarLetter,
                            style: const TextStyle(
                              color: Colors.cyanAccent,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        );
                      }

                      // Subtitle: owner name + mobile
                      final List<String> subParts = [];
                      if (vendor.ownerName.trim().isNotEmpty)
                        subParts.add(vendor.ownerName.trim());
                      if (vendor.displayPhone.trim().isNotEmpty)
                        subParts.add(vendor.displayPhone.trim());
                      final String subtitle = subParts.join('  •  ');

                      return Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        child: Row(
                          children: [
                            avatarWidget,
                            const SizedBox(width: 12),

                            // Info block
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Store name
                                  Text(
                                    vendor.storeName.trim().isNotEmpty
                                        ? vendor.storeName.trim()
                                        : 'Unnamed Vendor',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),

                                  // Owner + phone
                                  if (subtitle.isNotEmpty) ...[
                                    const SizedBox(height: 3),
                                    Text(
                                      subtitle,
                                      style: const TextStyle(
                                        color: Colors.white54,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],

                                  // Email
                                  if (vendor.email.trim().isNotEmpty) ...[
                                    const SizedBox(height: 2),
                                    Text(
                                      vendor.email.trim(),
                                      style: const TextStyle(
                                        color: Colors.white38,
                                        fontSize: 11,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],

                                  const SizedBox(height: 5),
                                  Row(
                                    children: [
                                      // Status badge
                                      if (vendor.status.trim().isNotEmpty)
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 7,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: _statusColor(
                                              vendor.status,
                                            ).withOpacity(0.12),
                                            borderRadius: BorderRadius.circular(
                                              20,
                                            ),
                                            border: Border.all(
                                              color: _statusColor(
                                                vendor.status,
                                              ).withOpacity(0.6),
                                              width: 0.7,
                                            ),
                                          ),
                                          child: Text(
                                            vendor.status.toUpperCase(),
                                            style: TextStyle(
                                              color: _statusColor(
                                                vendor.status,
                                              ),
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                              letterSpacing: 0.8,
                                            ),
                                          ),
                                        ),

                                      // Categories chip
                                      if (vendor.categories.isNotEmpty) ...[
                                        const SizedBox(width: 6),
                                        Flexible(
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 7,
                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.cyanAccent
                                                  .withOpacity(0.10),
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                              border: Border.all(
                                                color: Colors.cyanAccent
                                                    .withOpacity(0.4),
                                                width: 0.7,
                                              ),
                                            ),
                                            child: Text(
                                              vendor.categories.join(', '),
                                              style: const TextStyle(
                                                color: Colors.cyanAccent,
                                                fontSize: 10,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ],
                              ),
                            ),

                            // Action buttons — View + Delete only (no Edit)
                            Row(
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
                                            VendorDetailScreen(vendor: vendor),
                                      ),
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
                                      title: 'Delete Vendor?',
                                      titleStyle: GoogleFonts.orbitron(
                                        color: Colors.white,
                                      ),
                                      backgroundColor: const Color(0xFF2A2D3E),
                                      middleText:
                                          'Are you sure you want to delete ${vendor.storeName.isNotEmpty ? vendor.storeName : vendor.ownerName}?\nThis action can be undone briefly.',
                                      middleTextStyle: const TextStyle(
                                        color: Colors.white70,
                                      ),
                                      textConfirm: 'Yes, Delete',
                                      textCancel: 'Cancel',
                                      confirmTextColor: Colors.white,
                                      buttonColor: Colors.redAccent,
                                      cancelTextColor: Colors.cyanAccent,
                                      onConfirm: () {
                                        Get.back();
                                        controller.deleteVendor(vendor);
                                      },
                                    );
                                  },
                                ),
                              ],
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
