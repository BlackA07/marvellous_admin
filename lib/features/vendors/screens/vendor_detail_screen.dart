import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:marvellous_admin/features/products/presentation/screens/add_product_screen.dart';
import 'package:marvellous_admin/features/products/presentation/screens/product_detail_screen.dart';
import '../models/vendor_model.dart';
import 'add_vendor_screen.dart';
import '../controllers/vendor_controller.dart';
import '../../products/models/product_model.dart';

class VendorDetailScreen extends StatefulWidget {
  final VendorModel vendor;

  const VendorDetailScreen({Key? key, required this.vendor}) : super(key: key);

  @override
  State<VendorDetailScreen> createState() => _VendorDetailScreenState();
}

class _VendorDetailScreenState extends State<VendorDetailScreen> {
  final VendorController controller = Get.find();

  @override
  void initState() {
    super.initState();
    controller.fetchVendorProducts(widget.vendor.id ?? widget.vendor.uid);
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return Colors.greenAccent;
      case 'rejected':
        return Colors.redAccent;
      case 'pending':
        return Colors.orangeAccent;
      default:
        return Colors.white54;
    }
  }

  String _formatDate(DateTime? dt) {
    if (dt == null) return 'N/A';
    return '${dt.day}/${dt.month}/${dt.year}  '
        '${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final vendor = widget.vendor;

    // Collect all images: profileImage first, then storePictures
    final List<String> allImages = [];
    if (vendor.profileImage != null && vendor.profileImage!.trim().isNotEmpty) {
      allImages.add(vendor.profileImage!);
    }
    for (final pic in vendor.storePictures) {
      if (pic.trim().isNotEmpty && !allImages.contains(pic)) {
        allImages.add(pic);
      }
    }

    return Scaffold(
      backgroundColor: const Color(0xFF1E1E2C),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          vendor.storeName.isNotEmpty ? vendor.storeName : 'Vendor Detail',
          style: GoogleFonts.orbitron(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        // actions: [
        //   IconButton(
        //     icon: const Icon(Icons.edit, color: Colors.cyanAccent),
        //     onPressed: () {
        //       Navigator.push(
        //         context,
        //         MaterialPageRoute(
        //             builder: (_) => AddVendorScreen(vendorToEdit: vendor)),
        //       );
        //     },
        //   ),
        // ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── IMAGES SECTION ────────────────────────────────────────────
            if (allImages.isNotEmpty) ...[
              Text(
                allImages.length == 1 ? 'Store Image' : 'Store Images',
                style: const TextStyle(
                  color: Colors.white70,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 130,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: allImages.length,
                  itemBuilder: (ctx, i) {
                    return GestureDetector(
                      onTap: () => _showFullImage(context, allImages[i]),
                      child: Container(
                        width: 130,
                        margin: const EdgeInsets.only(right: 10),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.white10),
                          image: DecorationImage(
                            image: MemoryImage(base64Decode(allImages[i])),
                            fit: BoxFit.cover,
                          ),
                        ),
                        child: i == 0 && vendor.profileImage != null
                            ? Align(
                                alignment: Alignment.topLeft,
                                child: Container(
                                  margin: const EdgeInsets.all(5),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.black54,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Text(
                                    'Profile',
                                    style: TextStyle(
                                      color: Colors.cyanAccent,
                                      fontSize: 10,
                                    ),
                                  ),
                                ),
                              )
                            : null,
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 20),
            ],

            // ── VENDOR DETAILS CARD ───────────────────────────────────────
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
                  // Header row: avatar + store name + status
                  Row(
                    children: [
                      _buildAvatar(vendor, allImages),
                      const SizedBox(width: 15),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              vendor.storeName.isNotEmpty
                                  ? vendor.storeName
                                  : 'Unnamed Vendor',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (vendor.status.trim().isNotEmpty) ...[
                              const SizedBox(height: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: _statusColor(
                                    vendor.status,
                                  ).withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: _statusColor(vendor.status),
                                    width: 0.8,
                                  ),
                                ),
                                child: Text(
                                  vendor.status.toUpperCase(),
                                  style: TextStyle(
                                    color: _statusColor(vendor.status),
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),

                  const Divider(color: Colors.white24, height: 30),

                  // ── All detail rows ──
                  _detailRow(Icons.person, 'Owner Name', vendor.ownerName),
                  _gap(),
                  _detailRow(Icons.store, 'Store Name', vendor.storeName),
                  _gap(),
                  _detailRow(Icons.phone, 'Store Phone', vendor.storePhone),
                  _gap(),
                  _detailRow(
                    Icons.phone_android,
                    'Owner Mobile',
                    vendor.ownerMobile,
                  ),

                  if (vendor.contactPersonName.trim().isNotEmpty) ...[
                    _gap(),
                    _detailRow(
                      Icons.person_outline,
                      'Contact Person',
                      vendor.contactPersonName,
                    ),
                  ],
                  if (vendor.contactPersonPhone.trim().isNotEmpty) ...[
                    _gap(),
                    _detailRow(
                      Icons.call,
                      'Contact Phone',
                      vendor.contactPersonPhone,
                    ),
                  ],
                  if (vendor.email.trim().isNotEmpty) ...[
                    _gap(),
                    _detailRow(Icons.email_outlined, 'Email', vendor.email),
                  ],

                  _gap(),
                  _detailRow(Icons.location_on, 'Address', vendor.address),

                  if (vendor.beginningBalance > 0) ...[
                    _gap(),
                    _detailRow(
                      Icons.account_balance_wallet_outlined,
                      'Beginning Balance',
                      'Rs. ${vendor.beginningBalance.toStringAsFixed(0)}',
                    ),
                  ],

                  // Categories
                  if (vendor.categories.isNotEmpty) ...[
                    _gap(),
                    _chipRow(
                      Icons.category_outlined,
                      'Categories',
                      vendor.categories,
                      Colors.cyanAccent,
                    ),
                  ],

                  // Sub-categories
                  if (vendor.subCategories.isNotEmpty) ...[
                    _gap(),
                    _chipRow(
                      Icons.subdirectory_arrow_right,
                      'Sub-Categories',
                      vendor.subCategories,
                      Colors.purpleAccent,
                    ),
                  ],

                  // Timestamps
                  if (vendor.approvedAt != null) ...[
                    _gap(),
                    _detailRow(
                      Icons.check_circle_outline,
                      'Approved At',
                      _formatDate(vendor.approvedAt),
                    ),
                  ],
                  if (vendor.rejectedAt != null) ...[
                    _gap(),
                    _detailRow(
                      Icons.cancel_outlined,
                      'Rejected At',
                      _formatDate(vendor.rejectedAt),
                      valueColor: Colors.redAccent,
                    ),
                  ],
                  if (vendor.rejectionReason.trim().isNotEmpty) ...[
                    _gap(),
                    _detailRow(
                      Icons.info_outline,
                      'Rejection Reason',
                      vendor.rejectionReason,
                      valueColor: Colors.orangeAccent,
                    ),
                  ],

                  // Pending new categories
                  if (vendor.pendingNewCategories.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    const Text(
                      'Pending New Categories',
                      style: TextStyle(
                        color: Colors.white70,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...vendor.pendingNewCategories.map((cat) {
                      final name = cat['name']?.toString() ?? cat.toString();
                      return _pendingChip(
                        name,
                        Colors.orangeAccent,
                        Icons.category_outlined,
                      );
                    }),
                  ],

                  // Pending new sub-categories
                  if (vendor.pendingNewSubCategories.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    const Text(
                      'Pending New Sub-Categories',
                      style: TextStyle(
                        color: Colors.white70,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...vendor.pendingNewSubCategories.map((sub) {
                      final catName = sub['categoryName']?.toString() ?? '';
                      final subName =
                          sub['subName']?.toString() ?? sub.toString();
                      final label = catName.isNotEmpty
                          ? '$catName  →  $subName'
                          : subName;
                      return _pendingChip(
                        label,
                        Colors.purpleAccent,
                        Icons.subdirectory_arrow_right,
                      );
                    }),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 30),

            // ── PRODUCTS HEADER ──────────────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Vendor Products',
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
                    // Get.to(() => AddProductScreen(preSelectedVendorId: vendor.id));
                  },
                  icon: const Icon(Icons.add, color: Colors.black, size: 18),
                  label: const Text(
                    'Add Product',
                    style: TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 15),

            // ── PRODUCTS LIST ─────────────────────────────────────────────
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
                  child: const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.inventory_2_outlined,
                          color: Colors.white24,
                          size: 40,
                        ),
                        SizedBox(height: 10),
                        Text(
                          'No products linked to this vendor yet.',
                          style: TextStyle(color: Colors.white54),
                        ),
                      ],
                    ),
                  ),
                );
              }
              return ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
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
                        ),
                        child: product.images.isEmpty
                            ? const Icon(Icons.image, color: Colors.white24)
                            : ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: product.images.first.startsWith('http')
                                    ? Image.network(
                                        product.images.first,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) =>
                                            const Icon(
                                              Icons.broken_image,
                                              color: Colors.white24,
                                            ),
                                      )
                                    : Image.memory(
                                        base64Decode(product.images.first),
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) =>
                                            const Icon(
                                              Icons.broken_image,
                                              color: Colors.white24,
                                            ),
                                      ),
                              ),
                      ),
                      title: Text(
                        product.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: Text(
                        '${product.modelNumber} • Stock: ${product.stockQuantity}',
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
                            onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    ProductDetailScreen(product: product),
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.edit,
                              color: Colors.orangeAccent,
                              size: 20,
                            ),
                            onPressed: () => Get.to(
                              () => AddProductScreen(productToEdit: product),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.delete,
                              color: Colors.redAccent,
                              size: 20,
                            ),
                            onPressed: () {
                              Get.defaultDialog(
                                title: 'Delete Product?',
                                titleStyle: GoogleFonts.orbitron(
                                  color: Colors.white,
                                ),
                                backgroundColor: const Color(0xFF2A2D3E),
                                middleText:
                                    'Are you sure you want to delete ${product.name}?',
                                middleTextStyle: const TextStyle(
                                  color: Colors.white70,
                                ),
                                textConfirm: 'Delete',
                                textCancel: 'Cancel',
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

  // ── Helper Widgets ────────────────────────────────────────────────────────

  Widget _buildAvatar(VendorModel vendor, List<String> allImages) {
    if (allImages.isNotEmpty) {
      return CircleAvatar(
        radius: 30,
        backgroundImage: MemoryImage(base64Decode(allImages.first)),
      );
    }
    return CircleAvatar(
      radius: 30,
      backgroundColor: Colors.cyanAccent.withOpacity(0.2),
      child: Text(
        vendor.avatarLetter,
        style: GoogleFonts.orbitron(
          color: Colors.cyanAccent,
          fontSize: 22,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _detailRow(
    IconData icon,
    String label,
    String value, {
    Color? valueColor,
  }) {
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
                value.trim().isEmpty ? 'N/A' : value,
                style: TextStyle(
                  color: valueColor ?? Colors.white,
                  fontSize: 15,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _chipRow(
    IconData icon,
    String label,
    List<String> items,
    Color color,
  ) {
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
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: items
                    .map(
                      (item) => Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: color.withOpacity(0.5),
                            width: 0.7,
                          ),
                        ),
                        child: Text(
                          item,
                          style: TextStyle(color: color, fontSize: 12),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _pendingChip(String label, Color color, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(color: Colors.white, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  SizedBox _gap() => const SizedBox(height: 14);

  void _showFullImage(BuildContext context, String base64Img) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.black87,
        insetPadding: const EdgeInsets.all(16),
        child: Stack(
          children: [
            InteractiveViewer(child: Image.memory(base64Decode(base64Img))),
            Positioned(
              top: 8,
              right: 8,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
