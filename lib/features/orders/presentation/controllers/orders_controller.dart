import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../data/models/order_model.dart';
import '../../data/models/vendor_request_model.dart';
import '../../data/repositories/orders_repository.dart';

class OrdersController extends GetxController {
  final OrdersRepository _repo = OrdersRepository();

  var pendingOrders = <OrderModel>[].obs;
  var pendingRequests = <VendorRequestModel>[].obs;
  var historyOrders = <OrderModel>[].obs;
  var historyRequests = <VendorRequestModel>[].obs;

  @override
  void onInit() {
    super.onInit();
    bindStreams();
  }

  void bindStreams() {
    pendingOrders.bindStream(_repo.getPendingOrders());
    pendingRequests.bindStream(_repo.getPendingRequests());
  }

  void fetchHistory() {
    historyOrders.bindStream(_repo.getOrderHistory());
    historyRequests.bindStream(_repo.getRequestHistory());
  }

  // --- ACTIONS WITH UNDO ---

  // 1. Accept Request
  Future<void> acceptRequest(String id) async {
    try {
      await _repo.updateRequestStatus(id, 'approved');

      // Undo Option with SnackBar
      Get.snackbar(
        "Success",
        "Request Approved & Product Published",
        mainButton: TextButton(
          onPressed: () async {
            await _repo.updateRequestStatus(id, 'pending'); // Revert to pending
            Get.back(); // Close snackbar
            Get.snackbar("Undone", "Status reverted to Pending");
          },
          child: const Text("UNDO", style: TextStyle(color: Colors.yellow)),
        ),
        duration: const Duration(seconds: 4),
      );
    } catch (e) {
      Get.snackbar("Error", e.toString());
    }
  }

  // 2. Reject Request
  Future<void> rejectRequest(String id) async {
    try {
      await _repo.updateRequestStatus(id, 'rejected');

      // Undo Option
      Get.snackbar(
        "Rejected",
        "Request has been rejected",
        mainButton: TextButton(
          onPressed: () async {
            await _repo.updateRequestStatus(id, 'pending'); // Revert
            Get.back();
            Get.snackbar("Undone", "Status reverted to Pending");
          },
          child: const Text("UNDO", style: TextStyle(color: Colors.yellow)),
        ),
        duration: const Duration(seconds: 4),
      );
    } catch (e) {
      Get.snackbar("Error", e.toString());
    }
  }

  // Order Actions (Same Logic applied if needed)
  Future<void> acceptOrder(String id) async {
    await _repo.updateOrderStatus(id, 'accepted');
    Get.snackbar("Success", "Order Accepted");
  }

  Future<void> rejectOrder(String id) async {
    await _repo.updateOrderStatus(id, 'rejected');
    Get.snackbar("Rejected", "Order Rejected");
  }
}
