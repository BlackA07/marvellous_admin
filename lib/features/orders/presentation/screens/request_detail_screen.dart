import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../data/models/vendor_request_model.dart';
import '../controllers/orders_controller.dart';

class RequestDetailScreen extends StatelessWidget {
  final VendorRequestModel request;
  const RequestDetailScreen({Key? key, required this.request})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    final OrdersController controller = Get.find<OrdersController>();
    double titleSize = MediaQuery.of(context).size.width > 600 ? 24 : 18;

    return Scaffold(
      appBar: AppBar(title: const Text("Vendor Request Details")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // --- Vendor Info ---
            Card(
              elevation: 3,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.all(12),
                leading: CircleAvatar(
                  radius: 25,
                  backgroundColor: Colors.grey[200],
                  child: ClipOval(
                    child: _buildImageWidget(
                      request.vendorImage,
                      isAvatar: true,
                    ),
                  ),
                ),
                title: Text(
                  request.vendorName,
                  style: TextStyle(
                    fontSize: titleSize,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: const Text(
                  "Vendor ID: Verified",
                  style: TextStyle(color: Colors.green),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // --- Product Info ---
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(5),
                        border: Border.all(color: Colors.blue.withOpacity(0.3)),
                      ),
                      child: Text(
                        "Request Type: ${request.requestType.toUpperCase().replaceAll('_', ' ')}",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue[800],
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const SizedBox(height: 15),

                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        height: 200,
                        width: double.infinity,
                        color: Colors.grey[100],
                        child: _buildImageWidget(request.productImage),
                      ),
                    ),
                    const SizedBox(height: 15),

                    Text(
                      request.productName,
                      style: TextStyle(
                        fontSize: titleSize,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),

                    Text(
                      request.productDescription,
                      style: TextStyle(color: Colors.grey[700], height: 1.4),
                    ),
                    const SizedBox(height: 15),

                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.green[50],
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            "Proposed Price:",
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            "PKR ${request.productPrice.toStringAsFixed(0)}",
                            style: const TextStyle(
                              color: Colors.green,
                              fontWeight: FontWeight.bold,
                              fontSize: 20,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 30),

            // --- Action Buttons ---
            if (request.status == 'pending')
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _showConfirmationDialog(
                        context,
                        "Approve Request",
                        "Approve and publish this product?",
                        () => controller.acceptRequest(request.id),
                        isReject: false,
                      ),
                      icon: const Icon(Icons.check_circle, color: Colors.white),
                      label: const Text(
                        "Approve",
                        style: TextStyle(color: Colors.white),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green[700],
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _showConfirmationDialog(
                        context,
                        "Reject Request",
                        "Are you sure you want to reject?",
                        () => controller.rejectRequest(request.id),
                        isReject: true,
                      ),
                      icon: const Icon(Icons.cancel, color: Colors.white),
                      label: const Text(
                        "Reject",
                        style: TextStyle(color: Colors.white),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red[700],
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                ],
              ),

            if (request.status != 'pending')
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: request.status == 'approved'
                      ? Colors.green
                      : Colors.red,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Text(
                    request.status.toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  // FIXED IMAGE BUILDER
  Widget _buildImageWidget(String data, {bool isAvatar = false}) {
    if (data.isEmpty) {
      return Icon(
        isAvatar ? Icons.person : Icons.image_not_supported,
        color: Colors.grey,
        size: isAvatar ? 30 : 50,
      );
    }
    try {
      if (data.startsWith('http')) {
        return Image.network(
          data,
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
          // Fixed errorBuilder arguments
          errorBuilder: (context, error, stackTrace) => Icon(
            Icons.broken_image,
            color: Colors.grey,
            size: isAvatar ? 30 : 50,
          ),
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return const Center(
              child: CircularProgressIndicator(strokeWidth: 2),
            );
          },
        );
      }
      return Image.memory(
        base64Decode(data),
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        // Fixed errorBuilder arguments
        errorBuilder: (context, error, stackTrace) => Icon(
          Icons.broken_image,
          color: Colors.grey,
          size: isAvatar ? 30 : 50,
        ),
      );
    } catch (e) {
      return Icon(Icons.error, color: Colors.red, size: isAvatar ? 30 : 50);
    }
  }

  void _showConfirmationDialog(
    BuildContext context,
    String title,
    String content,
    VoidCallback onConfirm, {
    required bool isReject,
  }) {
    Get.defaultDialog(
      title: title,
      titleStyle: TextStyle(
        color: isReject ? Colors.red : Colors.green,
        fontWeight: FontWeight.bold,
      ),
      middleText: content,
      backgroundColor: Colors.white,
      radius: 15,
      textConfirm: isReject ? "Yes, Reject" : "Yes, Approve",
      textCancel: "Cancel",
      buttonColor: isReject ? Colors.red : Colors.green,
      confirmTextColor: Colors.white,
      onConfirm: () {
        Get.back();
        onConfirm();
      },
    );
  }
}
