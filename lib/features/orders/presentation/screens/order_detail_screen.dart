// Path: lib/features/orders/presentation/screens/order_detail_screen.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/orders_controller.dart';
import '../../data/models/order_model.dart';

class OrderDetailScreen extends StatelessWidget {
  final OrderModel order;
  const OrderDetailScreen({Key? key, required this.order}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final OrdersController controller = Get.find<OrdersController>();

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
                      order.items.isNotEmpty
                          ? "Order Items (${order.items.length})"
                          : "Product Details",
                      style: TextStyle(
                        fontSize: titleSize,
                        fontWeight: FontWeight.bold,
                        color: Colors.orangeAccent,
                      ),
                    ),
                    const Divider(),
                    const SizedBox(height: 10),

                    // ✅ FIX: Multiple Items List View
                    if (order.items.isNotEmpty) ...[
                      ...order.items.map((item) {
                        String img =
                            item['image'] ?? item['productImage'] ?? '';
                        String name =
                            item['name'] ?? item['productName'] ?? 'Unknown';
                        int qty =
                            int.tryParse(item['quantity']?.toString() ?? '1') ??
                            1;
                        double sp =
                            double.tryParse(
                              item['salePrice']?.toString() ?? '0',
                            ) ??
                            0.0;

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 15),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Container(
                                  height: 60,
                                  width: 60,
                                  color: Colors.grey[200],
                                  child: _buildImageWidget(img),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      name,
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: bodySize - 1,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      "Qty: $qty  •  Rs. ${sp.toStringAsFixed(0)}",
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: bodySize - 2,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                "Rs. ${(sp * qty).toStringAsFixed(0)}",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: bodySize - 1,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ] else ...[
                      // Fallback for older orders without items array
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
                    ],

                    const Divider(),
                    _buildDetailRow(
                      "Grand Total",
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

  Widget _buildImageWidget(String data, {bool isAvatar = false}) {
    if (data.isEmpty) {
      return Icon(
        isAvatar ? Icons.person : Icons.shopping_bag,
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
        base64Decode(data.contains(',') ? data.split(',').last : data),
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
