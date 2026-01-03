import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/orders_controller.dart';
import '../widgets/order_card.dart'; // Common List Card (Customer k liye)
import '../widgets/request_card.dart'; // Request Card (Vendor k liye)
import 'order_detail_screen.dart';
import 'request_detail_screen.dart';

class AllOrdersScreen extends StatelessWidget {
  final bool isVendorRequest; // True = Vendor Requests, False = Customer Orders

  const AllOrdersScreen({Key? key, required this.isVendorRequest})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Controller dhoond rahe hen (jo Dashboard men already put kiya hua tha)
    final controller = Get.find<OrdersController>();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          isVendorRequest ? "All Vendor Requests" : "All Customer Orders",
        ),
        elevation: 1,
      ),
      body: SafeArea(
        child: Obx(() {
          // --- LOGIC 1: Vendor Requests List ---
          if (isVendorRequest) {
            if (controller.pendingRequests.isEmpty) {
              return const Center(child: Text("No Pending Requests Found"));
            }

            return ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 10),
              itemCount: controller.pendingRequests.length,
              itemBuilder: (context, index) {
                final req = controller.pendingRequests[index];
                return RequestCard(
                  request: req,
                  onView: () => Get.to(() => RequestDetailScreen(request: req)),

                  // --- ACCEPT BUTTON LOGIC ---
                  onAccept: () {
                    Get.defaultDialog(
                      title: "Approve Request",
                      middleText:
                          "Are you sure you want to approve this product?",
                      textConfirm: "Yes, Approve",
                      textCancel: "Cancel",
                      confirmTextColor: Colors.white,
                      buttonColor: Colors.green,
                      onConfirm: () {
                        Get.back(); // Close Dialog
                        controller.acceptRequest(
                          req.id,
                        ); // Call Controller (Undo logic is inside controller)
                      },
                    );
                  },

                  // --- REJECT BUTTON LOGIC ---
                  onReject: () {
                    Get.defaultDialog(
                      title: "Reject Request",
                      middleText: "Are you sure you want to reject?",
                      textConfirm: "Yes, Reject",
                      textCancel: "Cancel",
                      confirmTextColor: Colors.white,
                      buttonColor: Colors.red,
                      onConfirm: () {
                        Get.back(); // Close Dialog
                        controller.rejectRequest(req.id); // Call Controller
                      },
                    );
                  },
                );
              },
            );
          }
          // --- LOGIC 2: Customer Orders List ---
          else {
            if (controller.pendingOrders.isEmpty) {
              return const Center(child: Text("No Pending Orders Found"));
            }

            return ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 10),
              itemCount: controller.pendingOrders.length,
              itemBuilder: (context, index) {
                final order = controller.pendingOrders[index];
                // Customer orders k liye hum CommonListCard use kar rahe hen
                // (Jo maine pichle response men widgets men diya tha)
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
          }
        }),
      ),
    );
  }
}
