import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../../controller/customers_controller.dart';
import '../../models/customer_model.dart';
import 'customer_detail_screen.dart';

class CustomersScreen extends StatelessWidget {
  const CustomersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(CustomersController());

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        title: Obx(
          () => Text(
            controller.isSelectionMode.value
                ? "${controller.selectedUids.length} Selected"
                : "Manage Customers",
            style: GoogleFonts.comicNeue(
              color: Colors.black,
              fontWeight: FontWeight.bold,
              fontSize: 24,
            ),
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.black),
        actions: [
          Obx(() {
            if (controller.isSelectionMode.value) {
              return Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.select_all, color: Colors.black),
                    onPressed: controller.selectAll,
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.black),
                    onPressed: controller.toggleSelectionMode,
                  ),
                ],
              );
            } else {
              return IconButton(
                icon: const Icon(Icons.checklist, color: Colors.black),
                onPressed: controller.toggleSelectionMode,
              );
            }
          }),
        ],
      ),
      body: Column(
        children: [
          // ── Search Bar ───────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(15, 15, 15, 8),
            child: TextField(
              onChanged: controller.searchCustomer,
              style: const TextStyle(color: Colors.black),
              decoration: InputDecoration(
                hintText: "Search by Name, Phone, or Code...",
                hintStyle: GoogleFonts.comicNeue(color: Colors.black54),
                prefixIcon: const Icon(Icons.search, color: Colors.blue),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: const BorderSide(color: Colors.black, width: 1.5),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: const BorderSide(color: Colors.black, width: 1.5),
                ),
              ),
            ),
          ),

          // ── Sort Filters ─────────────────────────────────────────────
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 15),
            child: Obx(
              () => Row(
                children: ['All', 'Newest', 'High Rank/Points', 'Most Refers']
                    .map((filter) {
                      bool isSel = controller.currentFilter.value == filter;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(
                            filter,
                            style: TextStyle(
                              color: isSel ? Colors.white : Colors.black,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          selected: isSel,
                          selectedColor: Colors.black,
                          backgroundColor: Colors.grey.shade300,
                          onSelected: (_) => controller.applyFilter(filter),
                        ),
                      );
                    })
                    .toList(),
              ),
            ),
          ),
          const SizedBox(height: 8),

          // ── Active / Inactive / All Status Filters ───────────────────
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 15),
            child: Obx(
              () => Row(
                children: [
                  _statusChip(
                    label: "All Users",
                    icon: Icons.people,
                    color: Colors.blueGrey,
                    selected: controller.statusFilter.value == 'all',
                    onTap: () => controller.applyStatusFilter('all'),
                  ),
                  const SizedBox(width: 8),
                  _statusChip(
                    label: "Active (MLM ON)",
                    icon: Icons.check_circle,
                    color: Colors.green.shade700,
                    selected: controller.statusFilter.value == 'active',
                    onTap: () => controller.applyStatusFilter('active'),
                  ),
                  const SizedBox(width: 8),
                  _statusChip(
                    label: "Inactive (No Sale)",
                    icon: Icons.cancel,
                    color: Colors.red.shade700,
                    selected: controller.statusFilter.value == 'inactive',
                    onTap: () => controller.applyStatusFilter('inactive'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),

          // ── Count indicator ──────────────────────────────────────────
          Obx(() {
            final total = controller.filteredList.length;
            final active = controller.filteredList
                .where((c) => c.isMLMActive)
                .length;
            final inactive = total - active;
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15),
              child: Row(
                children: [
                  _countBadge("Total: $total", Colors.blueGrey),
                  const SizedBox(width: 8),
                  _countBadge("Active: $active", Colors.green.shade700),
                  const SizedBox(width: 8),
                  _countBadge("Inactive: $inactive", Colors.red.shade700),
                ],
              ),
            );
          }),
          const SizedBox(height: 8),

          // ── List ─────────────────────────────────────────────────────
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value)
                return const Center(
                  child: CircularProgressIndicator(color: Colors.black),
                );
              if (controller.filteredList.isEmpty)
                return Center(
                  child: Text(
                    "No users found.",
                    style: GoogleFonts.comicNeue(
                      fontSize: 18,
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                );

              return ListView.builder(
                padding: const EdgeInsets.symmetric(
                  horizontal: 15,
                  vertical: 5,
                ),
                itemCount: controller.filteredList.length,
                itemBuilder: (context, index) {
                  final customer = controller.filteredList[index];
                  return _buildCustomerCard(customer, controller, context);
                },
              );
            }),
          ),
        ],
      ),

      // ── Bulk Message FAB ─────────────────────────────────────────────
      floatingActionButton: Obx(() {
        if (!controller.isSelectionMode.value ||
            controller.selectedUids.isEmpty)
          return const SizedBox.shrink();
        return FloatingActionButton.extended(
          backgroundColor: Colors.indigo,
          icon: const Icon(Icons.send, color: Colors.white),
          label: Text(
            "Send Message",
            style: GoogleFonts.comicNeue(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          onPressed: () => _showMessageDialog(context, controller),
        );
      }),
    );
  }

  Widget _statusChip({
    required String label,
    required IconData icon,
    required Color color,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? color : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color, width: 1.5),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: color.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ]
              : [],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: selected ? Colors.white : color),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.comicNeue(
                fontSize: 13,
                fontWeight: FontWeight.w900,
                color: selected ? Colors.white : color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _countBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Text(
        text,
        style: GoogleFonts.comicNeue(
          fontSize: 13,
          fontWeight: FontWeight.w900,
          color: color,
        ),
      ),
    );
  }

  Widget _buildCustomerCard(
    CustomerModel customer,
    CustomersController controller,
    BuildContext context,
  ) {
    String referredBy =
        customer.referralCode.isEmpty || customer.referralCode == "null"
        ? "Top / Direct"
        : customer.referralCode;

    final bool isActive = customer.isMLMActive;

    return Obx(() {
      bool isSelected = controller.selectedUids.contains(customer.uid);

      return GestureDetector(
        onTap: () {
          if (controller.isSelectionMode.value) {
            controller.toggleUserSelection(customer.uid);
          } else {
            Get.to(() => CustomerDetailScreen(uid: customer.uid));
          }
        },
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isSelected
                ? Colors.indigo.shade50
                : isActive
                ? Colors.white
                : const Color(0xFFFFF8F8), // light red tint for inactive
            borderRadius: BorderRadius.circular(15),
            border: Border.all(
              color: isSelected
                  ? Colors.indigo
                  : isActive
                  ? Colors.green.shade400
                  : Colors.red.shade300,
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                children: [
                  if (controller.isSelectionMode.value)
                    Checkbox(
                      value: isSelected,
                      activeColor: Colors.indigo,
                      onChanged: (_) =>
                          controller.toggleUserSelection(customer.uid),
                    ),

                  // Profile Image with active indicator ring
                  Stack(
                    children: [
                      Container(
                        height: 65,
                        width: 65,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                          border: Border.all(
                            color: isActive
                                ? Colors.green.shade500
                                : Colors.red.shade400,
                            width: 2.5,
                          ),
                        ),
                        child: ClipOval(
                          child: _buildBase64Image(customer.faceImage),
                        ),
                      ),
                      Positioned(
                        bottom: 2,
                        right: 2,
                        child: Container(
                          width: 14,
                          height: 14,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isActive
                                ? Colors.green.shade500
                                : Colors.red.shade400,
                            border: Border.all(color: Colors.white, width: 1.5),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 12),

                  // Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                customer.name.isEmpty
                                    ? "Unknown User"
                                    : customer.name,
                                style: GoogleFonts.comicNeue(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                  color: Colors.black,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            // Active/Inactive pill
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: isActive
                                    ? Colors.green.shade50
                                    : Colors.red.shade50,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: isActive
                                      ? Colors.green.shade400
                                      : Colors.red.shade400,
                                ),
                              ),
                              child: Text(
                                isActive ? "Active" : "Inactive",
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w900,
                                  color: isActive
                                      ? Colors.green.shade700
                                      : Colors.red.shade700,
                                ),
                              ),
                            ),
                          ],
                        ),
                        Text(
                          customer.email,
                          style: GoogleFonts.comicNeue(
                            fontSize: 15,
                            color: Colors.black87,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        GestureDetector(
                          onTap: () => controller.copyPhone(customer.phone),
                          child: Row(
                            children: [
                              Text(
                                customer.phone,
                                style: GoogleFonts.comicNeue(
                                  fontSize: 15,
                                  color: Colors.blue.shade700,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Icon(
                                Icons.copy,
                                size: 14,
                                color: Colors.blue.shade700,
                              ),
                            ],
                          ),
                        ),
                        if (customer.address.isNotEmpty &&
                            customer.address != "N/A")
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              customer.address,
                              style: GoogleFonts.comicNeue(
                                fontSize: 14,
                                fontWeight: FontWeight.w900,
                                color: Colors.black54,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                      ],
                    ),
                  ),

                  IconButton(
                    icon: const Icon(
                      Icons.remove_red_eye,
                      color: Colors.black,
                      size: 28,
                    ),
                    onPressed: () =>
                        Get.to(() => CustomerDetailScreen(uid: customer.uid)),
                  ),
                ],
              ),
              Divider(
                color: isActive ? Colors.green.shade200 : Colors.red.shade200,
                thickness: 1,
                height: 20,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _refBadge(
                    "My Code: ${customer.myReferralCode}",
                    Colors.green.shade900,
                  ),
                  _refBadge("Referred By: $referredBy", Colors.orange.shade900),
                ],
              ),
            ],
          ),
        ),
      );
    });
  }

  Widget _refBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: color, width: 1.5),
      ),
      child: Text(
        text,
        style: GoogleFonts.comicNeue(
          fontSize: 15,
          fontWeight: FontWeight.w900,
          color: color,
        ),
      ),
    );
  }

  // NAYA — yeh lagao
  Widget _buildBase64Image(String imageData) {
    // ── URL hai to seedha Network ─────────────────────────────
    if (imageData.startsWith('http')) {
      return Image.network(
        imageData,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) =>
            const Icon(Icons.person, color: Colors.black, size: 30),
      );
    }
    // ── Base64 hai ────────────────────────────────────────────
    if (imageData.isNotEmpty) {
      try {
        final clean = imageData.contains(',')
            ? imageData.split(',').last
            : imageData;
        return Image.memory(
          base64Decode(clean),
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) =>
              const Icon(Icons.person, color: Colors.black, size: 30),
        );
      } catch (_) {}
    }
    return const Icon(Icons.person, color: Colors.black, size: 30);
  }

  // ── Broadcast Dialog — fixed text colors ─────────────────────────────
  void _showMessageDialog(
    BuildContext context,
    CustomersController controller,
  ) {
    final titleCtrl = TextEditingController();
    final bodyCtrl = TextEditingController();
    String? selectedImageBase64;

    Get.dialog(
      StatefulBuilder(
        builder: (context, setState) {
          return Dialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: const BorderSide(color: Colors.black, width: 2),
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "Broadcast Message",
                    style: GoogleFonts.comicNeue(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 15),

                  // ✅ FIX: style with black text explicitly
                  TextField(
                    controller: titleCtrl,
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                    decoration: InputDecoration(
                      labelText: "Notification Title",
                      labelStyle: const TextStyle(color: Colors.black54),
                      hintText: "Enter title...",
                      hintStyle: const TextStyle(color: Colors.black38),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: Colors.indigo,
                          width: 2,
                        ),
                      ),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                    ),
                  ),
                  const SizedBox(height: 10),

                  TextField(
                    controller: bodyCtrl,
                    maxLines: 4,
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                    decoration: InputDecoration(
                      labelText: "Message Body",
                      labelStyle: const TextStyle(color: Colors.black54),
                      hintText: "Type your message...",
                      hintStyle: const TextStyle(color: Colors.black38),
                      alignLabelWithHint: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: Colors.indigo,
                          width: 2,
                        ),
                      ),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                    ),
                  ),
                  const SizedBox(height: 15),

                  // Image section
                  selectedImageBase64 != null
                      ? Stack(
                          alignment: Alignment.topRight,
                          children: [
                            Container(
                              height: 130,
                              width: 130,
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: Colors.indigo.shade200,
                                  width: 2,
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: Image.memory(
                                  base64Decode(selectedImageBase64!),
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => const Icon(
                                    Icons.broken_image,
                                    color: Colors.red,
                                  ),
                                ),
                              ),
                            ),
                            Positioned(
                              top: -4,
                              right: -4,
                              child: GestureDetector(
                                onTap: () =>
                                    setState(() => selectedImageBase64 = null),
                                child: Container(
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.red,
                                  ),
                                  padding: const EdgeInsets.all(4),
                                  child: const Icon(
                                    Icons.close,
                                    color: Colors.white,
                                    size: 14,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        )
                      : OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Colors.black),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          icon: const Icon(Icons.image, color: Colors.black),
                          label: const Text(
                            "Attach Image",
                            style: TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          onPressed: () async {
                            try {
                              final picker = ImagePicker();
                              final XFile? xfile = await picker.pickImage(
                                source: ImageSource.gallery,
                                imageQuality: 50,
                              );
                              if (xfile != null) {
                                final bytes = await xfile.readAsBytes();
                                final String b64 = base64Encode(bytes);
                                setState(() => selectedImageBase64 = b64);
                              }
                            } catch (e) {
                              Get.snackbar(
                                "Error",
                                "Could not pick image: $e",
                                backgroundColor: Colors.red,
                                colorText: Colors.white,
                              );
                            }
                          },
                        ),
                  const SizedBox(height: 20),

                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.indigo,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: () async {
                        if (titleCtrl.text.isEmpty || bodyCtrl.text.isEmpty) {
                          Get.snackbar(
                            "Error",
                            "Title and Body are required",
                            backgroundColor: Colors.red,
                            colorText: Colors.white,
                          );
                          return;
                        }
                        Get.back();
                        await controller.sendMultiNotification(
                          title: titleCtrl.text,
                          body: bodyCtrl.text,
                          base64Image: selectedImageBase64,
                        );
                      },
                      child: Text(
                        "Send to ${controller.selectedUids.length} Users",
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
