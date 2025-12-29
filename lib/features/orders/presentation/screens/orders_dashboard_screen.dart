import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/orders_controller.dart';
import '../widgets/order_card.dart';
import 'order_detail_screen.dart';
import 'request_detail_screen.dart';
import 'order_history_screen.dart';
import 'all_orders_screen.dart'; // Make sure ye import ho

class OrdersDashboardScreen extends StatelessWidget {
  const OrdersDashboardScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Controller inject kar rahe hen
    final controller = Get.put(OrdersController());

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Orders & Requests"),
          bottom: const TabBar(
            tabs: [
              Tab(text: "Customer Orders", icon: Icon(Icons.shopping_cart)),
              Tab(text: "Vendor Requests", icon: Icon(Icons.store)),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.history),
              onPressed: () => Get.to(() => const OrderHistoryScreen()),
              tooltip: "View History",
            ),
          ],
        ),
        body: TabBarView(
          children: [
            // Tab 1: Customer Pending
            _buildCustomerTab(controller, context),
            // Tab 2: Vendor Requests
            _buildVendorTab(controller, context),
          ],
        ),
      ),
    );
  }

  // --- TAB 1: CUSTOMER ORDERS ---
  Widget _buildCustomerTab(OrdersController controller, BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: Obx(() {
            if (controller.pendingOrders.isEmpty) {
              return const Center(child: Text("No Pending Orders"));
            }
            return ListView.builder(
              // Sirf top 10 dikhane k liye (Visual limit, actual query repo men hoti he)
              itemCount: controller.pendingOrders.length,
              itemBuilder: (context, index) {
                final order = controller.pendingOrders[index];
                return CommonListCard(
                  title: order.productName,
                  subtitle: "Customer: ${order.customerName}",
                  imageUrl: order.productImage,
                  price: "PKR ${order.price}",
                  onView: () => Get.to(() => OrderDetailScreen(order: order)),
                  onAccept: () => controller.acceptOrder(order.id),
                  onReject: () => controller.rejectOrder(order.id),
                );
              },
            );
          }),
        ),
        // Yahan 'false' pass kiya kyunke ye Vendor nahi hai
        _buildSeeAllButton("View All Orders", false),
      ],
    );
  }

  // --- TAB 2: VENDOR REQUESTS ---
  Widget _buildVendorTab(OrdersController controller, BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: Obx(() {
            if (controller.pendingRequests.isEmpty) {
              return const Center(child: Text("No Vendor Requests"));
            }
            return ListView.builder(
              itemCount: controller.pendingRequests.length,
              itemBuilder: (context, index) {
                final req = controller.pendingRequests[index];
                return CommonListCard(
                  title: req.productName,
                  subtitle:
                      "${req.requestType.replaceAll('_', ' ').capitalize} by ${req.vendorName}",
                  imageUrl: req.productImage,
                  price: "PKR ${req.productPrice}",
                  onView: () => Get.to(() => RequestDetailScreen(request: req)),
                  onAccept: () => controller.acceptRequest(req.id),
                  onReject: () => controller.rejectRequest(req.id),
                );
              },
            );
          }),
        ),
        // Yahan 'true' pass kiya kyunke ye Vendor Request hai
        _buildSeeAllButton("View All Requests", true),
      ],
    );
  }

  // --- SEE ALL BUTTON ---
  Widget _buildSeeAllButton(String text, bool isVendorRequest) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 5,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          backgroundColor: Colors.blue[800],
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        onPressed: () {
          // Ab ye variable sahi se pass hoga
          Get.to(() => AllOrdersScreen(isVendorRequest: isVendorRequest));
        },
        child: Text(
          text,
          style: const TextStyle(color: Colors.white, fontSize: 16),
        ),
      ),
    );
  }
}
