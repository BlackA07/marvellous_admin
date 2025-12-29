import 'package:flutter/material.dart';
import '../../data/models/order_model.dart';

class OrderDetailScreen extends StatelessWidget {
  final OrderModel order;
  const OrderDetailScreen({Key? key, required this.order}) : super(key: key);

  @override
  Widget build(BuildContext context) {
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
                          backgroundImage: order.customerImage.isNotEmpty
                              ? NetworkImage(order.customerImage)
                              : null,
                          child: order.customerImage.isEmpty
                              ? const Icon(Icons.person)
                              : null,
                        ),
                        const SizedBox(width: 15),
                        Column(
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
                    Center(
                      child: Container(
                        height: 200,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          image: order.productImage.isNotEmpty
                              ? DecorationImage(
                                  image: NetworkImage(order.productImage),
                                  fit: BoxFit.cover,
                                )
                              : null,
                          color: Colors.grey[200],
                        ),
                        child: order.productImage.isEmpty
                            ? const Icon(Icons.shopping_bag, size: 50)
                            : null,
                      ),
                    ),
                    const SizedBox(height: 15),
                    _buildDetailRow(
                      "Product Name",
                      order.productName,
                      bodySize,
                    ),
                    _buildDetailRow("Price", "PKR ${order.price}", bodySize),
                    _buildDetailRow("Order ID", order.id, bodySize),
                    _buildDetailRow(
                      "Date",
                      order.date.toString().split(' ')[0],
                      bodySize,
                    ),
                    const SizedBox(height: 20),

                    // Action Buttons (If pending)
                    if (order.status == 'pending')
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () {}, // Controller call here
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                              ),
                              child: const Text("Accept Order"),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () {},
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                              ),
                              child: const Text("Reject Order"),
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
          Text(
            value,
            style: TextStyle(fontWeight: FontWeight.w500, fontSize: fontSize),
          ),
        ],
      ),
    );
  }
}
