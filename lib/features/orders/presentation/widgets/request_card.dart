import 'package:flutter/material.dart';
import '../../data/models/vendor_request_model.dart';

class RequestCard extends StatelessWidget {
  final VendorRequestModel request;
  final VoidCallback onView;
  final VoidCallback onAccept;
  final VoidCallback onReject;
  final bool isHistory; // Agar history men use karen to buttons chupane k liye

  const RequestCard({
    Key? key,
    required this.request,
    required this.onView,
    required this.onAccept,
    required this.onReject,
    this.isHistory = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Responsive text check
    bool isDesktop = MediaQuery.of(context).size.width > 600;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // --- 1. Product Image ---
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Container(
                width: isDesktop ? 80 : 60,
                height: isDesktop ? 80 : 60,
                color: Colors.grey[200],
                child: request.productImage.isNotEmpty
                    ? Image.network(request.productImage, fit: BoxFit.cover)
                    : const Icon(Icons.image_not_supported, color: Colors.grey),
              ),
            ),
            const SizedBox(width: 15),

            // --- 2. Details Section ---
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Request Type Badge (Add Product / Edit Product)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: request.requestType == 'add_product'
                          ? Colors.blue.withOpacity(0.1)
                          : Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: request.requestType == 'add_product'
                            ? Colors.blue
                            : Colors.orange,
                        width: 0.5,
                      ),
                    ),
                    child: Text(
                      request.requestType.replaceAll('_', ' ').toUpperCase(),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: request.requestType == 'add_product'
                            ? Colors.blue[800]
                            : Colors.orange[800],
                      ),
                    ),
                  ),
                  const SizedBox(height: 5),

                  // Product Name
                  Text(
                    request.productName,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: isDesktop ? 18 : 16,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),

                  // Vendor Name
                  Text(
                    "Vendor: ${request.vendorName}",
                    style: TextStyle(
                      fontSize: isDesktop ? 14 : 12,
                      color: Colors.grey[600],
                    ),
                  ),

                  // Price
                  Text(
                    "PKR ${request.productPrice}",
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),

            // --- 3. Action Buttons ---
            if (!isHistory) ...[
              // View Button
              IconButton(
                icon: const Icon(
                  Icons.visibility_outlined,
                  color: Colors.blueGrey,
                ),
                tooltip: "View Details",
                onPressed: onView,
              ),
              // Accept Button
              IconButton(
                icon: const Icon(
                  Icons.check_circle_outline,
                  color: Colors.green,
                ),
                tooltip: "Approve Request",
                onPressed: onAccept,
              ),
              // Reject Button
              IconButton(
                icon: const Icon(Icons.cancel_outlined, color: Colors.red),
                tooltip: "Reject Request",
                onPressed: onReject,
              ),
            ] else ...[
              // Status Badge for History
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: request.status == 'approved'
                      ? Colors.green[50]
                      : Colors.red[50],
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: request.status == 'approved'
                        ? Colors.green
                        : Colors.red,
                  ),
                ),
                child: Text(
                  request.status.toUpperCase(),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: request.status == 'approved'
                        ? Colors.green
                        : Colors.red,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
