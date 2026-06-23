import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../controllers/vendor_controller.dart';
import 'vendor_detail_screen.dart';

class VendorsListScreen extends StatefulWidget {
  VendorsListScreen({Key? key}) : super(key: key);

  @override
  State<VendorsListScreen> createState() => _VendorsListScreenState();
}

class _VendorsListScreenState extends State<VendorsListScreen> {
  final VendorController controller = Get.put(VendorController());
  String _selectedFilter = 'All';

  final List<String> _filters = [
    'All',
    'Approved',
    'Pending',
    'Hold',
    'Rejected',
  ];

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return Colors.greenAccent;
      case 'rejected':
        return Colors.redAccent;
      case 'pending':
        return Colors.orangeAccent;
      case 'hold':
        return Colors.amberAccent;
      default:
        return Colors.white38;
    }
  }

  // Vendors ko sort karo: approved upar, baqi neeche
  List get _sortedVendors {
    final all = controller.vendors.toList();
    if (_selectedFilter != 'All') {
      return all
          .where((v) => v.status.toLowerCase() == _selectedFilter.toLowerCase())
          .toList();
    }
    final approved = all
        .where((v) => v.status.toLowerCase() == 'approved')
        .toList();
    final others = all
        .where((v) => v.status.toLowerCase() != 'approved')
        .toList();
    return [...approved, ...others];
  }

  void _showHoldDialog(String docId) {
    final reasonCtrl = TextEditingController();
    Get.defaultDialog(
      title: 'Hold Vendor',
      titleStyle: GoogleFonts.orbitron(color: Colors.white),
      backgroundColor: const Color(0xFF2A2D3E),
      content: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: TextField(
          controller: reasonCtrl,
          maxLines: 3,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'Reason for holding...',
            hintStyle: const TextStyle(color: Colors.white38),
            filled: true,
            fillColor: const Color(0xFF1A1D2E),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
      ),
      textCancel: 'Cancel',
      cancelTextColor: Colors.cyanAccent,
      textConfirm: 'Hold',
      confirmTextColor: Colors.white,
      buttonColor: Colors.amber,
      onConfirm: () {
        if (reasonCtrl.text.trim().isEmpty) {
          Get.snackbar(
            'Required',
            'Please enter a reason',
            backgroundColor: Colors.red,
            colorText: Colors.white,
          );
          return;
        }
        Get.back();
        controller.holdVendor(docId, reasonCtrl.text.trim());
      },
    );
  }

  void _showRejectDialog(String docId) {
    final reasonCtrl = TextEditingController();
    Get.defaultDialog(
      title: 'Reject Vendor',
      titleStyle: GoogleFonts.orbitron(color: Colors.white),
      backgroundColor: const Color(0xFF2A2D3E),
      content: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: TextField(
          controller: reasonCtrl,
          maxLines: 3,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'Reason for rejection...',
            hintStyle: const TextStyle(color: Colors.white38),
            filled: true,
            fillColor: const Color(0xFF1A1D2E),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
      ),
      textCancel: 'Cancel',
      cancelTextColor: Colors.cyanAccent,
      textConfirm: 'Reject',
      confirmTextColor: Colors.white,
      buttonColor: Colors.redAccent,
      onConfirm: () {
        if (reasonCtrl.text.trim().isEmpty) {
          Get.snackbar(
            'Required',
            'Please enter a reason',
            backgroundColor: Colors.red,
            colorText: Colors.white,
          );
          return;
        }
        Get.back();
        controller.rejectVendor(docId, reasonCtrl.text.trim());
      },
    );
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
            const SizedBox(height: 14),

            // ── Filter Chips ──
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _filters.map((f) {
                  final bool selected = _selectedFilter == f;
                  Color chipColor;
                  switch (f) {
                    case 'Approved':
                      chipColor = Colors.greenAccent;
                      break;
                    case 'Pending':
                      chipColor = Colors.orangeAccent;
                      break;
                    case 'Hold':
                      chipColor = Colors.amberAccent;
                      break;
                    case 'Rejected':
                      chipColor = Colors.redAccent;
                      break;
                    default:
                      chipColor = Colors.cyanAccent;
                  }
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedFilter = f),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          color: selected
                              ? chipColor.withOpacity(0.18)
                              : Colors.white10,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: selected ? chipColor : Colors.white24,
                            width: selected ? 1.5 : 1,
                          ),
                        ),
                        child: Text(
                          f,
                          style: TextStyle(
                            color: selected ? chipColor : Colors.white54,
                            fontWeight: selected
                                ? FontWeight.bold
                                : FontWeight.normal,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),

            const SizedBox(height: 14),

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
                  final list = _sortedVendors;
                  if (list.isEmpty) {
                    return Center(
                      child: Text(
                        'No vendors found.',
                        style: const TextStyle(color: Colors.white54),
                      ),
                    );
                  }
                  return ListView.separated(
                    itemCount: list.length,
                    separatorBuilder: (_, __) =>
                        const Divider(color: Colors.white10, height: 1),
                    itemBuilder: (context, index) {
                      final vendor = list[index];
                      final String? imgBase64 =
                          (vendor.profileImage != null &&
                              vendor.profileImage!.trim().isNotEmpty)
                          ? vendor.profileImage
                          : vendor.storePictures.isNotEmpty
                          ? vendor.storePictures.first
                          : null;

                      Widget avatarWidget = imgBase64 != null
                          ? CircleAvatar(
                              radius: 24,
                              backgroundImage: MemoryImage(
                                base64Decode(imgBase64),
                              ),
                            )
                          : CircleAvatar(
                              radius: 24,
                              backgroundColor: Colors.cyanAccent.withOpacity(
                                0.2,
                              ),
                              child: Text(
                                vendor.avatarLetter,
                                style: const TextStyle(
                                  color: Colors.cyanAccent,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            );

                      final String subtitle = [
                        if (vendor.ownerName.trim().isNotEmpty)
                          vendor.ownerName.trim(),
                        if (vendor.displayPhone.trim().isNotEmpty)
                          vendor.displayPhone.trim(),
                      ].join('  •  ');

                      final bool isApproved =
                          vendor.status.toLowerCase() == 'approved';
                      final bool isPending =
                          vendor.status.toLowerCase() == 'pending';
                      final bool isHold = vendor.status.toLowerCase() == 'hold';

                      return Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                avatarWidget,
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
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
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 7,
                                                    vertical: 2,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: _statusColor(
                                                  vendor.status,
                                                ).withOpacity(0.12),
                                                borderRadius:
                                                    BorderRadius.circular(20),
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
                                          if (vendor.categories.isNotEmpty) ...[
                                            const SizedBox(width: 6),
                                            Flexible(
                                              child: Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
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
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),

                                      // Hold reason
                                      if (isHold &&
                                          vendor.rejectionReason.isEmpty)
                                        Padding(
                                          padding: const EdgeInsets.only(
                                            top: 4,
                                          ),
                                          child: Text(
                                            'Hold Reason: (see detail)',
                                            style: const TextStyle(
                                              color: Colors.amberAccent,
                                              fontSize: 11,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),

                                // ── Action Buttons ──
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    // View
                                    IconButton(
                                      icon: const Icon(
                                        Icons.visibility,
                                        color: Colors.blueAccent,
                                        size: 20,
                                      ),
                                      onPressed: () => Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => VendorDetailScreen(
                                            vendor: vendor,
                                          ),
                                        ),
                                      ),
                                    ),

                                    // Approve (only if not already approved)
                                    if (!isApproved)
                                      IconButton(
                                        icon: const Icon(
                                          Icons.check_circle,
                                          color: Colors.greenAccent,
                                          size: 20,
                                        ),
                                        tooltip: 'Approve',
                                        onPressed: () => controller
                                            .approveVendor(vendor.id!),
                                      ),

                                    // Hold (only pending)
                                    if (isPending || isApproved)
                                      IconButton(
                                        icon: const Icon(
                                          Icons.pause_circle,
                                          color: Colors.amberAccent,
                                          size: 20,
                                        ),
                                        tooltip: 'Hold',
                                        onPressed: () =>
                                            _showHoldDialog(vendor.id!),
                                      ),

                                    // Reject (not already rejected)
                                    if (!vendor.status.toLowerCase().contains(
                                      'rejected',
                                    ))
                                      IconButton(
                                        icon: const Icon(
                                          Icons.cancel,
                                          color: Colors.redAccent,
                                          size: 20,
                                        ),
                                        tooltip: 'Reject',
                                        onPressed: () =>
                                            _showRejectDialog(vendor.id!),
                                      ),

                                    // Delete
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
                                          backgroundColor: const Color(
                                            0xFF2A2D3E,
                                          ),
                                          middleText:
                                              'Are you sure you want to delete ${vendor.storeName.isNotEmpty ? vendor.storeName : vendor.ownerName}?',
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
