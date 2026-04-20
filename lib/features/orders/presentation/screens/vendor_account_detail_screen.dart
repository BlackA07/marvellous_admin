import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../controllers/orders_controller.dart';

class VendorAccountDetailScreen extends StatelessWidget {
  final Map<String, dynamic> vendorData;

  const VendorAccountDetailScreen({Key? key, required this.vendorData})
    : super(key: key);

  Widget _buildImage({
    required String imageStr,
    double? width,
    double? height,
    BoxFit fit = BoxFit.cover,
    Widget? errorWidget,
  }) {
    final fallback =
        errorWidget ??
        Container(
          width: width,
          height: height,
          color: Colors.white10,
          child: const Icon(Icons.broken_image, color: Colors.white30),
        );

    if (imageStr.isEmpty) return fallback;

    if (imageStr.startsWith('http://') || imageStr.startsWith('https://')) {
      return Image.network(
        imageStr,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (c, e, s) => fallback,
        loadingBuilder: (c, child, progress) {
          if (progress == null) return child;
          return Container(
            width: width,
            height: height,
            color: Colors.white10,
            child: const Center(
              child: CircularProgressIndicator(
                color: Colors.blueAccent,
                strokeWidth: 2,
              ),
            ),
          );
        },
      );
    }

    try {
      return Image.memory(
        base64Decode(imageStr),
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (c, e, s) => fallback,
      );
    } catch (_) {
      return fallback;
    }
  }

  @override
  Widget build(BuildContext context) {
    // ✅ FIX 1: Controller safely fetch karo
    OrdersController? controller;
    try {
      controller = Get.find<OrdersController>();
    } catch (_) {
      controller = Get.put(OrdersController());
    }

    // ✅ FIX 2: uid — dono fields check karo (uid ya id)
    String uid = (vendorData['uid'] ?? vendorData['id'] ?? '').toString();
    String profileImage = (vendorData['profileImage'] ?? '').toString();
    String storeName = (vendorData['storeName'] ?? 'N/A').toString();
    String storePhone = (vendorData['storePhone'] ?? 'N/A').toString();
    String ownerName = (vendorData['ownerName'] ?? 'N/A').toString();
    String ownerMobile = (vendorData['ownerMobile'] ?? 'N/A').toString();
    String contactPersonName = (vendorData['contactPersonName'] ?? 'N/A')
        .toString();
    String contactPersonPhone = (vendorData['contactPersonPhone'] ?? 'N/A')
        .toString();
    String email = (vendorData['email'] ?? 'N/A').toString();
    String address = (vendorData['address'] ?? 'N/A').toString();
    double beginningBalance =
        double.tryParse(vendorData['beginningBalance']?.toString() ?? '0') ??
        0.0;

    List<String> categories = ((vendorData['categories'] ?? []) as List)
        .map((e) => e.toString())
        .toList();
    List<String> subCategories = ((vendorData['subCategories'] ?? []) as List)
        .map((e) => e.toString())
        .toList();
    List<String> storePictures = ((vendorData['storePictures'] ?? []) as List)
        .map((e) => e.toString())
        .toList();

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F),
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () => Get.back(),
        ),
        title: Text(
          "Vendor Details",
          style: GoogleFonts.orbitron(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // ═══════════════════════════════════════
            // TOP HERO
            // ═══════════════════════════════════════
            Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
              ),
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 30),
              child: Column(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        colors: [Colors.blueAccent, Colors.purpleAccent],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.blueAccent.withOpacity(0.4),
                          blurRadius: 20,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(3),
                    child: ClipOval(
                      child: _buildImage(
                        imageStr: profileImage,
                        width: 110,
                        height: 110,
                        errorWidget: Container(
                          width: 110,
                          height: 110,
                          color: Colors.white10,
                          child: const Icon(
                            Icons.store,
                            size: 50,
                            color: Colors.white54,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    storeName,
                    style: GoogleFonts.orbitron(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    email,
                    style: TextStyle(
                      color: Colors.blueAccent.withOpacity(0.8),
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.green.withOpacity(0.2),
                          Colors.teal.withOpacity(0.2),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.green.withOpacity(0.5),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.account_balance_wallet,
                          color: Colors.greenAccent,
                          size: 16,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          "Balance: ${beginningBalance.toStringAsFixed(0)} Rs",
                          style: const TextStyle(
                            color: Colors.greenAccent,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  // ═══════════════════════════════════════
                  // STORE INFO — paired layout
                  // Owner Name | Owner Mobile
                  // Contact Person | Contact Phone
                  // Store Name | Store Phone
                  // ═══════════════════════════════════════
                  _sectionCard(
                    icon: Icons.store,
                    iconColor: Colors.blueAccent,
                    title: "Store Information",
                    child: Column(
                      children: [
                        // Row 1: Owner Name + Owner Mobile
                        _pairedRow(
                          leftIcon: Icons.person,
                          leftLabel: "Owner Name",
                          leftValue: ownerName,
                          leftColor: Colors.purpleAccent,
                          rightIcon: Icons.phone_android,
                          rightLabel: "Owner Mobile",
                          rightValue: ownerMobile,
                          rightColor: Colors.orangeAccent,
                        ),
                        const SizedBox(height: 10),
                        // Row 2: Contact Person + Contact Phone
                        _pairedRow(
                          leftIcon: Icons.support_agent,
                          leftLabel: "Contact Person",
                          leftValue: contactPersonName,
                          leftColor: Colors.tealAccent,
                          rightIcon: Icons.call,
                          rightLabel: "Contact Phone",
                          rightValue: contactPersonPhone,
                          rightColor: Colors.amberAccent,
                        ),
                        const SizedBox(height: 10),
                        // Row 3: Store Name + Store Phone
                        _pairedRow(
                          leftIcon: Icons.storefront,
                          leftLabel: "Store Name",
                          leftValue: storeName,
                          leftColor: Colors.blueAccent,
                          rightIcon: Icons.phone,
                          rightLabel: "Store Phone",
                          rightValue: storePhone,
                          rightColor: Colors.cyanAccent,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  // ADDRESS
                  _sectionCard(
                    icon: Icons.location_on,
                    iconColor: Colors.redAccent,
                    title: "Store Address",
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.place,
                          color: Colors.white38,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            address,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                              height: 1.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  // CATEGORIES
                  if (categories.isNotEmpty || subCategories.isNotEmpty)
                    _sectionCard(
                      icon: Icons.category,
                      iconColor: Colors.orangeAccent,
                      title: "Categories",
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (categories.isNotEmpty) ...[
                            const Text(
                              "Main Categories",
                              style: TextStyle(
                                color: Colors.white38,
                                fontSize: 12,
                                letterSpacing: 1,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: categories
                                  .map((c) => _chip(c, Colors.blueAccent))
                                  .toList(),
                            ),
                          ],
                          if (categories.isNotEmpty && subCategories.isNotEmpty)
                            const SizedBox(height: 14),
                          if (subCategories.isNotEmpty) ...[
                            const Text(
                              "Sub Categories",
                              style: TextStyle(
                                color: Colors.white38,
                                fontSize: 12,
                                letterSpacing: 1,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: subCategories
                                  .map((s) => _chip(s, Colors.greenAccent))
                                  .toList(),
                            ),
                          ],
                        ],
                      ),
                    ),

                  if (categories.isNotEmpty || subCategories.isNotEmpty)
                    const SizedBox(height: 12),

                  // STORE PICTURES
                  if (storePictures.isNotEmpty)
                    _sectionCard(
                      icon: Icons.photo_library,
                      iconColor: Colors.purpleAccent,
                      title: "Store Pictures",
                      child: SizedBox(
                        height: 130,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: storePictures.length,
                          itemBuilder: (context, index) {
                            return Padding(
                              padding: const EdgeInsets.only(right: 10),
                              child: GestureDetector(
                                onTap: () => _showFullImage(
                                  context,
                                  storePictures[index],
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: _buildImage(
                                    imageStr: storePictures[index],
                                    width: 130,
                                    height: 130,
                                    errorWidget: Container(
                                      width: 130,
                                      height: 130,
                                      decoration: BoxDecoration(
                                        color: Colors.white10,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: const Icon(
                                        Icons.broken_image,
                                        color: Colors.white30,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),

                  const SizedBox(height: 30),

                  // ACTION BUTTONS
                  Row(
                    children: [
                      Expanded(
                        child: _actionButton(
                          label: "APPROVE",
                          icon: Icons.check_circle_outline,
                          color: Colors.green,
                          onTap: () {
                            controller!.approveVendorAccount(uid);
                            Get.back();
                          },
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: _actionButton(
                          label: "REJECT",
                          icon: Icons.cancel_outlined,
                          color: Colors.redAccent,
                          onTap: () =>
                              _showRejectDialog(context, controller!, uid),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════
  // Paired Row — name aur phone aamne samne ek hi row mein
  // ══════════════════════════════════════════════════════
  Widget _pairedRow({
    required IconData leftIcon,
    required String leftLabel,
    required String leftValue,
    required Color leftColor,
    required IconData rightIcon,
    required String rightLabel,
    required String rightValue,
    required Color rightColor,
  }) {
    return Row(
      children: [
        Expanded(
          child: _miniTile(
            icon: leftIcon,
            color: leftColor,
            label: leftLabel,
            value: leftValue,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _miniTile(
            icon: rightIcon,
            color: rightColor,
            label: rightLabel,
            value: rightValue,
          ),
        ),
      ],
    );
  }

  Widget _miniTile({
    required IconData icon,
    required Color color,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.07),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.25), width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 15),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white38,
                    fontSize: 10,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: iconColor, size: 16),
              const SizedBox(width: 7),
              Text(
                title,
                style: TextStyle(
                  color: iconColor,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Divider(color: Colors.white10, height: 1),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _chip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.4), width: 1),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _actionButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color, color.withOpacity(0.7)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showFullImage(BuildContext context, String imageStr) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.black87,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: _buildImage(imageStr: imageStr, fit: BoxFit.contain),
        ),
      ),
    );
  }

  void _showRejectDialog(
    BuildContext context,
    OrdersController controller,
    String uid,
  ) {
    final reasonCtrl = TextEditingController();
    Get.dialog(
      AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          "Reject Vendor",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: TextField(
          controller: reasonCtrl,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: "Enter rejection reason",
            hintStyle: TextStyle(color: Colors.white38),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.white24),
            ),
            focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.redAccent),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text(
              "Cancel",
              style: TextStyle(color: Colors.white54),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () {
              if (reasonCtrl.text.isEmpty) {
                Get.snackbar(
                  "Error",
                  "Please enter a reason",
                  backgroundColor: Colors.orange,
                );
                return;
              }
              controller.rejectVendorAccount(uid, reasonCtrl.text);
              Get.back();
              Get.back();
            },
            child: const Text(
              "Confirm Reject",
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
