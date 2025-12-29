// File: lib/features/finance/presentation/screens/earnings_history_screen.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/finance_controller.dart';
import '../../../orders/data/models/order_model.dart';
import '../../../orders/presentation/screens/order_detail_screen.dart'; // Order Detail Screen link

class EarningsHistoryScreen extends StatelessWidget {
  final String title;
  final String filterType; // 'all', 'month', 'today'

  const EarningsHistoryScreen({
    Key? key,
    required this.title,
    required this.filterType,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<FinanceController>();

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: FutureBuilder<List<OrderModel>>(
        future: controller.getOrdersByFilter(filterType),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text("No Earnings Found for this period"),
            );
          }

          final orders = snapshot.data!;

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: orders.length,
            separatorBuilder: (c, i) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final order = orders[index];
              return Card(
                elevation: 2,
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  leading: CircleAvatar(
                    backgroundColor: Colors.green.withOpacity(0.1),
                    child: const Icon(Icons.attach_money, color: Colors.green),
                  ),
                  title: Text(
                    order.productName,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    "Order ID: ${order.id}\nDate: ${order.date.toString().split(' ')[0]}",
                  ),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        "PKR ${order.price}",
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.green,
                        ),
                      ),
                      const Icon(
                        Icons.arrow_forward_ios,
                        size: 12,
                        color: Colors.grey,
                      ),
                    ],
                  ),
                  // CLICK PE ORDER DETAIL SCREEN
                  onTap: () {
                    Get.to(() => OrderDetailScreen(order: order));
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
