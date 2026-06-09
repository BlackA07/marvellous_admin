import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'vendor_purchase_screen.dart';

class AdminOrderRequestsScreen extends StatelessWidget {
  const AdminOrderRequestsScreen({super.key});

  // ✅ FAST & CRASH-PROOF UNIVERSAL IMAGE BUILDER (Handles both Cloudinary URLs & Base64)
  Widget _buildBase64Image(String? base64String, double size) {
    if (base64String == null || base64String.isEmpty) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(
          Icons.image_not_supported,
          size: size * 0.5,
          color: Colors.grey,
        ),
      );
    }

    try {
      // ✅ 1. Agar Cloudinary URL hai (Migration ke baad)
      if (base64String.startsWith('http')) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: Image.network(
            base64String,
            width: size,
            height: size,
            fit: BoxFit.cover,
            cacheWidth: (size * 2).toInt(), // 🔥 SPEED FIX: RAM Optimization
            errorBuilder: (context, error, stackTrace) => Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(
                Icons.broken_image,
                size: size * 0.5,
                color: Colors.grey,
              ),
            ),
          ),
        );
      }

      // ✅ 2. Agar purana Base64 Data hai (Migration se pehle ka)
      String cleanBase64 = base64String.contains(',')
          ? base64String.split(',').last
          : base64String;
      return ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: Image.memory(
          base64Decode(cleanBase64),
          width: size,
          height: size,
          fit: BoxFit.cover,
          cacheWidth: (size * 2).toInt(), // 🔥 SPEED FIX: RAM Optimization
          errorBuilder: (context, error, stackTrace) => Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(
              Icons.broken_image,
              size: size * 0.5,
              color: Colors.grey,
            ),
          ),
        ),
      );
    } catch (e) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(Icons.broken_image, size: size * 0.5, color: Colors.grey),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      appBar: AppBar(
        title: Text(
          "Sent Order Requests",
          style: GoogleFonts.comicNeue(
            fontSize: 26,
            fontWeight: FontWeight.w900,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.black,
        elevation: 2,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('order_requests')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.black),
            );
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Text(
                "No order requests found.",
                style: GoogleFonts.comicNeue(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black54,
                ),
              ),
            );
          }

          var requests = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(15),
            physics: const BouncingScrollPhysics(),
            itemCount: requests.length,
            itemBuilder: (context, index) {
              var req = requests[index].data() as Map<String, dynamic>;
              String reqId = requests[index].id;

              DateTime date = (req['createdAt'] as Timestamp).toDate();
              List items = req['items'] ?? [];
              String status = req['status'] ?? 'pending';

              // Status Colors
              Color statusColor = Colors.orange.shade800;
              if (status == 'confirmed') statusColor = Colors.blue.shade800;
              if (status == 'shipped') statusColor = Colors.purple.shade800;
              if (status == 'received') statusColor = Colors.teal.shade700;
              if (status == 'completed') statusColor = Colors.green.shade900;
              if (status == 'rejected') statusColor = Colors.red.shade900;

              return Card(
                color: Colors.white,
                elevation: 4,
                margin: const EdgeInsets.only(bottom: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: statusColor, width: 1.5),
                ),
                child: ExpansionTile(
                  shape: const Border(),
                  tilePadding: const EdgeInsets.all(18),
                  title: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          req['vendorName'] ?? 'Unknown Vendor',
                          style: GoogleFonts.comicNeue(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            color: Colors.black,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: statusColor, width: 1.5),
                        ),
                        child: Text(
                          status.toUpperCase(),
                          style: GoogleFonts.comicNeue(
                            color: statusColor,
                            fontWeight: FontWeight.w900,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 10.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Total Items: ${items.length}",
                          style: GoogleFonts.comicNeue(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            color: Colors.black87,
                          ),
                        ),
                        Text(
                          DateFormat('dd MMM yyyy, hh:mm a').format(date),
                          style: GoogleFonts.comicNeue(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.black54,
                          ),
                        ),
                      ],
                    ),
                  ),
                  children: [
                    const Divider(
                      color: Colors.black12,
                      thickness: 1.5,
                      height: 0,
                    ),

                    // ✅ Rejection Reason
                    if (status == 'rejected' && req['rejectReason'] != null)
                      Container(
                        width: double.infinity,
                        margin: const EdgeInsets.all(15),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          border: Border.all(
                            color: Colors.red.shade900,
                            width: 2,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "REJECTION REASON:",
                              style: GoogleFonts.comicNeue(
                                fontWeight: FontWeight.w900,
                                color: Colors.red.shade900,
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              req['rejectReason'],
                              style: GoogleFonts.comicNeue(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: Colors.black87,
                              ),
                            ),
                          ],
                        ),
                      ),

                    // ✅ Items list WITH product image
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: items.length,
                      itemBuilder: (context, i) {
                        var item = items[i];
                        bool isAvail = item['isAvailable'] ?? true;

                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          decoration: const BoxDecoration(
                            border: Border(
                              bottom: BorderSide(color: Colors.black12),
                            ),
                          ),
                          child: Row(
                            children: [
                              // ✅ Product Image
                              _buildBase64Image(item['image'], 55),
                              const SizedBox(width: 14),

                              // Product Details
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "${item['productName']}",
                                      style: GoogleFonts.comicNeue(
                                        fontWeight: FontWeight.w900,
                                        fontSize: 18,
                                        color: Colors.black,
                                      ),
                                    ),
                                    Text(
                                      "Qty: ${item['requestQty']}  |  Model: ${item['model']}",
                                      style: GoogleFonts.comicNeue(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                        color: Colors.black54,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              // Available / Not Available badge
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: isAvail
                                      ? Colors.green.shade50
                                      : Colors.red.shade50,
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: isAvail
                                        ? Colors.green.shade800
                                        : Colors.red.shade900,
                                    width: 1.5,
                                  ),
                                ),
                                child: Text(
                                  isAvail ? "Available" : "Not Available",
                                  style: GoogleFonts.comicNeue(
                                    fontWeight: FontWeight.w900,
                                    color: isAvail
                                        ? Colors.green.shade800
                                        : Colors.red.shade900,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),

                    // ── ADMIN ACTION BUTTONS ──
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          if (status == 'shipped')
                            Expanded(
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.teal.shade700,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                  ),
                                ),
                                icon: const Icon(
                                  Icons.inventory_rounded,
                                  color: Colors.white,
                                  size: 20,
                                ),
                                label: Text(
                                  "MARK AS RECEIVED",
                                  style: GoogleFonts.comicNeue(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 16,
                                  ),
                                ),
                                onPressed: () => _confirmActionDialog(
                                  "Receive Order",
                                  "Are you sure you have received these items from the vendor?",
                                  () async {
                                    await FirebaseFirestore.instance
                                        .collection('order_requests')
                                        .doc(reqId)
                                        .update({'status': 'received'});
                                    Get.snackbar(
                                      "Success",
                                      "Order marked as received.",
                                      backgroundColor: Colors.green,
                                      colorText: Colors.white,
                                    );
                                  },
                                ),
                              ),
                            ),

                          if (status == 'received')
                            Expanded(
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue.shade900,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                  ),
                                ),
                                icon: const Icon(
                                  Icons.receipt_long,
                                  color: Colors.white,
                                  size: 20,
                                ),
                                label: Text(
                                  "GENERATE FINAL BILL",
                                  style: GoogleFonts.comicNeue(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 16,
                                  ),
                                ),
                                onPressed: () {
                                  req['requestId'] = reqId;
                                  Get.to(
                                    () => const VendorPurchaseScreen(),
                                    arguments: {'orderRequest': req},
                                  );
                                },
                              ),
                            ),

                          if (status == 'pending')
                            Text(
                              "Waiting for vendor confirmation...",
                              style: GoogleFonts.comicNeue(
                                fontWeight: FontWeight.bold,
                                color: Colors.orange.shade800,
                              ),
                            ),

                          if (status == 'confirmed')
                            Text(
                              "Vendor confirmed. Waiting for shipment...",
                              style: GoogleFonts.comicNeue(
                                fontWeight: FontWeight.bold,
                                color: Colors.blue.shade800,
                              ),
                            ),

                          if (status == 'completed')
                            Text(
                              "Bill Generated & Completed.",
                              style: GoogleFonts.comicNeue(
                                fontWeight: FontWeight.bold,
                                color: Colors.green.shade900,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _confirmActionDialog(
    String title,
    String message,
    VoidCallback onConfirm,
  ) {
    Get.defaultDialog(
      title: title,
      titleStyle: GoogleFonts.comicNeue(
        fontWeight: FontWeight.w900,
        fontSize: 24,
        color: const Color.fromARGB(255, 255, 255, 255),
      ),
      content: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10.0),
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: GoogleFonts.comicNeue(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      cancel: OutlinedButton(
        onPressed: () => Get.back(),
        child: const Text(
          "Cancel",
          style: TextStyle(
            color: Color.fromARGB(255, 255, 255, 255),
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      confirm: ElevatedButton(
        style: ElevatedButton.styleFrom(backgroundColor: Colors.black),
        onPressed: () {
          Get.back();
          onConfirm();
        },
        child: const Text(
          "Yes, Proceed",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
