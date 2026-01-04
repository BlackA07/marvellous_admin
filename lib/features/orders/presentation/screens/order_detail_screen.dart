import 'dart:convert'; // Zaroori hai Base64 decode ke liye
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/orders_controller.dart';
import '../../data/models/order_model.dart';

class OrderDetailScreen extends StatelessWidget {
  final OrderModel order;
  const OrderDetailScreen({Key? key, required this.order}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Controller Find Karen
    final OrdersController controller = Get.find<OrdersController>();

    // Responsive Helper
    double titleSize = MediaQuery.of(context).size.width > 600 ? 24 : 18;
    double bodySize = MediaQuery.of(context).size.width > 600 ? 16 : 14;

    return Scaffold(
      appBar: AppBar(title: const Text("Order Details")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- Section 1: Customer Details ---
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Customer Information",
                      style: TextStyle(
                        fontSize: titleSize,
                        fontWeight: FontWeight.bold,
                        color: Colors.blueAccent,
                      ),
                    ),
                    const Divider(),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 30,
                          backgroundColor: Colors.grey[200],
                          child: ClipOval(
                            // Customer Image Logic
                            child: _buildImageWidget(
                              order.customerImage,
                              isAvatar: true,
                            ),
                          ),
                        ),
                        const SizedBox(width: 15),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                order.customerName,
                                style: TextStyle(
                                  fontSize: titleSize - 2,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                order.customerPhone,
                                style: TextStyle(fontSize: bodySize),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      "Address:",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: bodySize,
                      ),
                    ),
                    Text(
                      order.customerAddress,
                      style: TextStyle(fontSize: bodySize),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // --- Section 2: Product / Order Details ---
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Product Details",
                      style: TextStyle(
                        fontSize: titleSize,
                        fontWeight: FontWeight.bold,
                        color: Colors.orangeAccent,
                      ),
                    ),
                    const Divider(),
                    const SizedBox(height: 10),

                    // Product Image (Fixed Logic)
                    Center(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          height: 200,
                          width: double.infinity,
                          color: Colors.grey[200],
                          child: _buildImageWidget(order.productImage),
                        ),
                      ),
                    ),

                    const SizedBox(height: 15),
                    _buildDetailRow(
                      "Product Name",
                      order.productName,
                      bodySize,
                    ),
                    _buildDetailRow(
                      "Price",
                      "PKR ${order.price.toStringAsFixed(0)}",
                      bodySize,
                    ),
                    _buildDetailRow("Order ID", order.id, bodySize),
                    _buildDetailRow(
                      "Date",
                      order.date.toString().split(' ')[0],
                      bodySize,
                    ),
                    const SizedBox(height: 20),

                    // --- Action Buttons ---
                    if (order.status == 'pending')
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () => controller.acceptOrder(order.id),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                              ),
                              child: const Text(
                                "Accept Order",
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () => controller.rejectOrder(order.id),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                              ),
                              child: const Text(
                                "Reject Order",
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- HELPER WIDGETS ---

  Widget _buildDetailRow(String label, String value, double fontSize) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: fontSize,
              color: Colors.grey[700],
            ),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: TextStyle(fontWeight: FontWeight.w500, fontSize: fontSize),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  // Smart Image Builder (Handles Base64 & URL)
  Widget _buildImageWidget(String data, {bool isAvatar = false}) {
    if (data.isEmpty) {
      return Icon(
        isAvatar ? Icons.person : Icons.shopping_bag,
        color: Colors.grey,
        size: isAvatar ? 30 : 50,
      );
    }

    try {
      // 1. Check if it's a URL
      if (data.startsWith('http')) {
        return Image.network(
          data,
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
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

      // 2. Assume Base64 String
      return Image.memory(
        base64Decode(data),
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
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
}
