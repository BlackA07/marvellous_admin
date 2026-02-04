import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../data/models/order_model.dart';
import '../controllers/orders_controller.dart';
import '../widgets/order_card.dart';
import 'order_detail_screen.dart';

class OrdersDashboardScreen extends StatelessWidget {
  const OrdersDashboardScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(OrdersController());

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: const Color(0xFF0F0F0F),
        appBar: AppBar(
          backgroundColor: Colors.black,
          elevation: 0,
          title: Text(
            "Operations",
            style: GoogleFonts.orbitron(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          actions: [
            // Debug button
            IconButton(
              icon: const Icon(Icons.bug_report, color: Colors.orange),
              onPressed: () {
                _showDebugInfo(controller);
              },
            ),
          ],
          bottom: TabBar(
            isScrollable: true,
            indicatorColor: Colors.redAccent,
            labelPadding: const EdgeInsets.symmetric(horizontal: 20),
            tabs: [
              _buildTabWithBadge(
                "Orders",
                controller.pendingOrders,
                Icons.shopping_bag,
              ),
              _buildTabWithBadge(
                "Vendor Req",
                controller.pendingRequests,
                Icons.store,
              ),
              _buildTabWithBadge(
                "Fee Approvals",
                controller.feeRequests,
                Icons.verified_user,
              ),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildOrdersTab(controller),
            _buildVendorTab(controller),
            _buildFeeTab(controller),
          ],
        ),
      ),
    );
  }

  // Debug info dialog
  void _showDebugInfo(OrdersController controller) {
    Get.dialog(
      AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: Text(
          "Debug Information",
          style: GoogleFonts.orbitron(color: Colors.white),
        ),
        content: Obx(
          () => SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _debugRow("Pending Orders", controller.pendingOrders.length),
                _debugRow("Vendor Requests", controller.pendingRequests.length),
                _debugRow("Fee Requests", controller.feeRequests.length),
                const SizedBox(height: 20),
                const Text(
                  "Check console for detailed logs",
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text("Close")),
        ],
      ),
    );
  }

  Widget _debugRow(String label, int count) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.white70)),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: count > 0 ? Colors.green : Colors.red,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              count.toString(),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Reactive Tab Badge Logic
  Widget _buildTabWithBadge(String title, RxList list, IconData icon) {
    return Tab(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18),
          const SizedBox(width: 8),
          Text(
            title,
            style: GoogleFonts.comicNeue(fontWeight: FontWeight.bold),
          ),
          const SizedBox(width: 6),
          Obx(
            () => list.isEmpty
                ? const SizedBox()
                : Container(
                    padding: const EdgeInsets.all(5),
                    decoration: const BoxDecoration(
                      color: Colors.redAccent,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      list.length.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrdersTab(OrdersController controller) {
    return Obx(() {
      // Show loading indicator
      if (controller.isLoading.value) {
        return const Center(
          child: CircularProgressIndicator(color: Colors.redAccent),
        );
      }

      // Check if empty
      if (controller.pendingOrders.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.shopping_bag_outlined,
                size: 80,
                color: Colors.white24,
              ),
              const SizedBox(height: 20),
              Text(
                "No Active Orders",
                style: GoogleFonts.orbitron(
                  color: Colors.white54,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                "Orders will appear here when placed",
                style: TextStyle(color: Colors.white38, fontSize: 12),
              ),
              const SizedBox(height: 30),
              ElevatedButton.icon(
                onPressed: () {
                  controller.bindStreams(); // Retry binding
                  Get.snackbar(
                    "Refreshing",
                    "Checking for new orders...",
                    backgroundColor: Colors.blue,
                    colorText: Colors.white,
                  );
                },
                icon: const Icon(Icons.refresh),
                label: const Text("Refresh"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                ),
              ),
            ],
          ),
        );
      }

      // Show orders list
      return ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: controller.pendingOrders.length,
        itemBuilder: (context, index) {
          final order = controller.pendingOrders[index];
          return CommonListCard(
            title: order.productName,
            subtitle:
                "User: ${order.customerName}\nStatus: ${order.status.toUpperCase()}",
            imageUrl: order.productImage,
            price: "PKR ${order.price.toStringAsFixed(0)}",
            onView: () => Get.to(() => OrderDetailScreen(order: order)),
            onAccept: () => _showCenteredStatusDialog(context, order),
            onReject: () => controller.updateOrderStage(order.id, 'rejected'),
          );
        },
      );
    });
  }

  // --- CENTERED MARVELLOUS DIALOG (BLACK & RED) ---
  void _showCenteredStatusDialog(BuildContext context, OrderModel order) {
    Get.dialog(
      Center(
        child: Material(
          color: Colors.transparent,
          child: Container(
            width: Get.width * 0.85,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A1A), // Dark Black
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.redAccent, width: 2),
              boxShadow: [
                BoxShadow(
                  color: Colors.redAccent.withOpacity(0.2),
                  blurRadius: 15,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "Order Status",
                  style: GoogleFonts.orbitron(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  "Update stage for #${order.id}",
                  style: const TextStyle(color: Colors.white54, fontSize: 10),
                ),
                const SizedBox(height: 25),
                _dialogBtn(
                  "CONFIRM ORDER",
                  Colors.blue,
                  () => _handleUpdate(order.id, 'confirmed'),
                ),
                _dialogBtn(
                  "MARK AS SHIPPED",
                  Colors.orange,
                  () => _handleUpdate(order.id, 'shipped'),
                ),
                _dialogBtn(
                  "MARK AS DELIVERED",
                  Colors.green,
                  () => _handleUpdate(order.id, 'delivered'),
                ),
                const SizedBox(height: 15),
                TextButton(
                  onPressed: () => Get.back(),
                  child: const Text(
                    "CANCEL",
                    style: TextStyle(color: Colors.white38),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _handleUpdate(String id, String status) {
    Get.find<OrdersController>().updateOrderStage(id, status);
    Get.back();
  }

  Widget _dialogBtn(String text, Color color, VoidCallback onTap) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      height: 50,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          side: BorderSide(color: color.withOpacity(0.5)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        onPressed: onTap,
        child: Text(
          text,
          style: GoogleFonts.orbitron(
            color: color,
            fontSize: 13,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  // --- FEE TAB ---
  Widget _buildFeeTab(OrdersController controller) {
    return Obx(() {
      // Show loading
      if (controller.isLoading.value) {
        return const Center(
          child: CircularProgressIndicator(color: Colors.redAccent),
        );
      }

      // Check if empty
      if (controller.feeRequests.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.verified_user_outlined,
                size: 80,
                color: Colors.white24,
              ),
              const SizedBox(height: 20),
              Text(
                "No Pending Fee Requests",
                style: GoogleFonts.orbitron(
                  color: Colors.white54,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                "Fee requests will appear here",
                style: TextStyle(color: Colors.white38, fontSize: 12),
              ),
            ],
          ),
        );
      }

      // Show fee requests list
      return ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: controller.feeRequests.length,
        itemBuilder: (context, index) {
          final req = controller.feeRequests[index];
          return Card(
            color: const Color(0xFF1A1A1A),
            margin: const EdgeInsets.symmetric(horizontal: 5, vertical: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
              side: const BorderSide(color: Colors.white10),
            ),
            child: ListTile(
              leading: const CircleAvatar(
                backgroundColor: Colors.redAccent,
                child: Icon(Icons.attach_money, color: Colors.white),
              ),
              title: Text(
                req['userEmail'] ?? 'No Email',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              subtitle: Text(
                "Rs. ${req['amount'] ?? 0} | ${req['method'] ?? 'N/A'}",
                style: const TextStyle(color: Colors.white60, fontSize: 12),
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.check_circle, color: Colors.green),
                    onPressed: () {
                      final userId = req['userId'];
                      if (userId == null || userId.isEmpty) {
                        Get.snackbar(
                          "Error",
                          "User ID not found",
                          backgroundColor: Colors.red,
                          colorText: Colors.white,
                        );
                        return;
                      }
                      controller.approveFee(req['id'], userId);
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.cancel, color: Colors.red),
                    onPressed: () {
                      final userId = req['userId'];
                      if (userId == null || userId.isEmpty) {
                        Get.snackbar(
                          "Error",
                          "User ID not found",
                          backgroundColor: Colors.red,
                          colorText: Colors.white,
                        );
                        return;
                      }
                      controller.rejectFee(req['id'], userId);
                    },
                  ),
                ],
              ),
            ),
          );
        },
      );
    });
  }

  // --- VENDOR TAB ---
  Widget _buildVendorTab(OrdersController controller) {
    return Obx(() {
      // Show loading
      if (controller.isLoading.value) {
        return const Center(
          child: CircularProgressIndicator(color: Colors.redAccent),
        );
      }

      // Check if empty
      if (controller.pendingRequests.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.store_outlined, size: 80, color: Colors.white24),
              const SizedBox(height: 20),
              Text(
                "No Vendor Requests",
                style: GoogleFonts.orbitron(
                  color: Colors.white54,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                "Vendor requests will appear here",
                style: TextStyle(color: Colors.white38, fontSize: 12),
              ),
            ],
          ),
        );
      }

      // Show vendor requests list
      return ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: controller.pendingRequests.length,
        itemBuilder: (context, index) {
          final req = controller.pendingRequests[index];
          return CommonListCard(
            title: req.productName,
            subtitle: "By ${req.vendorName}",
            imageUrl: req.productImage,
            price: "PKR ${req.productPrice}",
            onView: () {
              Get.snackbar(
                "Vendor Request",
                "Product: ${req.productName}\nVendor: ${req.vendorName}",
                backgroundColor: Colors.blue,
                colorText: Colors.white,
                duration: const Duration(seconds: 3),
              );
            },
            onAccept: () => controller.acceptRequest(req.id),
            onReject: () => controller.rejectRequest(req.id),
          );
        },
      );
    });
  }
}
