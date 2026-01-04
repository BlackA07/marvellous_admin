import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../data/models/vendor_request_model.dart';

class RequestCard extends StatelessWidget {
  final VendorRequestModel request;
  final VoidCallback onView;
  final VoidCallback onAccept;
  final VoidCallback onReject;

  const RequestCard({
    Key? key,
    required this.request,
    required this.onView,
    required this.onAccept,
    required this.onReject,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // --- SMART IMAGE (Base64 & URL Support) ---
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Container(
                height: 70,
                width: 70,
                color: Colors.grey[100],
                child: _buildListImage(request.productImage),
              ),
            ),
            const SizedBox(width: 15),

            // --- INFO ---
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    request.productName,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 5),
                  Text(
                    "Vendor: ${request.vendorName}",
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    "PKR ${request.productPrice.toStringAsFixed(0)}",
                    style: const TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),

            // --- ARROW ICON (View Details) ---
            IconButton(
              onPressed: onView,
              icon: const Icon(
                Icons.arrow_forward_ios,
                size: 18,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- Helper Image Widget for List ---
  Widget _buildListImage(String data) {
    if (data.isEmpty) {
      return const Icon(Icons.image_not_supported, color: Colors.grey);
    }
    try {
      // 1. URL Check
      if (data.startsWith('http')) {
        return Image.network(
          data,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) =>
              const Icon(Icons.broken_image, color: Colors.grey),
        );
      }
      // 2. Base64 Check
      return Image.memory(
        base64Decode(data),
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) =>
            const Icon(Icons.broken_image, color: Colors.grey),
      );
    } catch (e) {
      return const Icon(Icons.error, color: Colors.grey);
    }
  }
}
