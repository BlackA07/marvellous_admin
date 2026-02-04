import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../data/models/order_model.dart';
import '../../data/models/vendor_request_model.dart';
import '../../data/repositories/orders_repository.dart';

class OrdersController extends GetxController {
  final OrdersRepository _repo = OrdersRepository();

  // Observables for Active Data
  var pendingOrders = <OrderModel>[].obs;
  var pendingRequests = <VendorRequestModel>[].obs;
  var feeRequests = <Map<String, dynamic>>[].obs;

  // Observables for History
  var historyOrders = <OrderModel>[].obs;
  var historyRequests = <VendorRequestModel>[].obs;

  var isLoading = false.obs;

  // Computed properties for counts
  int get pendingOrdersCount =>
      pendingOrders.where((o) => o.status == 'pending').length;
  int get pendingRequestsCount => pendingRequests.length;
  int get feeRequestsCount => feeRequests.length;

  @override
  void onInit() {
    super.onInit();
    print("🚀 OrdersController initialized");

    // Debug Firebase data first
    _debugFirebaseData();

    // Then bind streams
    bindStreams();
  }

  Future<void> _debugFirebaseData() async {
    print("\n🔍 Running Firebase debug check...");
    await _repo.debugCollections();
  }

  void bindStreams() {
    print("📡 Binding streams to observables...");

    // Bind orders stream
    pendingOrders.bindStream(
      _repo.getOrdersByStatus(['pending', 'confirmed', 'shipped']),
    );

    // Bind vendor requests stream
    pendingRequests.bindStream(_repo.getPendingRequests());

    // Bind fee requests stream
    feeRequests.bindStream(_repo.getFeeRequests());

    // Listen to changes for debugging
    ever(pendingOrders, (orders) {
      print("📦 Orders updated: ${orders.length} items");
      if (orders.isNotEmpty) {
        print(
          "   First order: ${orders.first.productName} - ${orders.first.status}",
        );
      }
    });

    ever(feeRequests, (requests) {
      print("💰 Fee requests updated: ${requests.length} items");
      if (requests.isNotEmpty) {
        print(
          "   First request: ${requests.first['userEmail']} - ${requests.first['amount']}",
        );
      }
    });

    ever(pendingRequests, (requests) {
      print("🏪 Vendor requests updated: ${requests.length} items");
      if (requests.isNotEmpty) {
        print("   First request: ${requests.first.productName}");
      }
    });
  }

  // --- FETCH HISTORY ---
  void fetchHistory() {
    print("📜 Fetching history data...");

    // History screens ke liye streams bind karna
    historyOrders.bindStream(
      _repo.getOrdersByStatus(['accepted', 'rejected', 'delivered']),
    );
    historyRequests.bindStream(_repo.getRequestHistory());
  }

  // --- ORDER ACTIONS (UI Alias) ---
  Future<void> acceptOrder(String id) async {
    print("✅ Accepting order: $id");
    await updateOrderStage(id, 'confirmed');
  }

  Future<void> rejectOrder(String id) async {
    print("❌ Rejecting order: $id");
    await updateOrderStage(id, 'rejected');
  }

  Future<void> updateOrderStage(String id, String nextStage) async {
    print("📝 Updating order $id to stage: $nextStage");

    try {
      isLoading.value = true;
      await _repo.updateOrderStatus(id, nextStage);

      Get.snackbar(
        "Status Updated",
        "Order is now ${nextStage.capitalize}",
        backgroundColor: Colors.blue,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 2),
      );

      print("✅ Order stage updated successfully");
    } catch (e) {
      print("❌ Error updating order stage: $e");
      Get.snackbar(
        "Error",
        "Failed to update order: ${e.toString()}",
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  // --- FEE REQUEST ACTIONS ---
  Future<void> approveFee(String reqId, String userId) async {
    print("✅ Approving fee request: $reqId for user: $userId");

    try {
      isLoading.value = true;
      await _repo.handleFeeRequest(reqId, userId, 'approved');

      Get.snackbar(
        "Success",
        "Membership Approved!",
        backgroundColor: Colors.green,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );

      print("✅ Fee request approved successfully");
    } catch (e) {
      print("❌ Error approving fee: $e");
      Get.snackbar(
        "Error",
        "Failed to approve: ${e.toString()}",
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> rejectFee(String reqId, String userId) async {
    print("❌ Rejecting fee request: $reqId");

    TextEditingController reasonCtrl = TextEditingController();

    Get.defaultDialog(
      title: "Reason for Rejection",
      content: Padding(
        padding: const EdgeInsets.all(8.0),
        child: TextField(
          controller: reasonCtrl,
          decoration: const InputDecoration(
            hintText: "Enter reason",
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
        ),
      ),
      textConfirm: "Reject",
      textCancel: "Cancel",
      confirmTextColor: Colors.white,
      buttonColor: Colors.red,
      onConfirm: () async {
        if (reasonCtrl.text.trim().isEmpty) {
          Get.snackbar(
            "Validation Error",
            "Please provide a reason",
            backgroundColor: Colors.orange,
            colorText: Colors.white,
          );
          return;
        }

        try {
          isLoading.value = true;
          await _repo.handleFeeRequest(
            reqId,
            userId,
            'rejected',
            reason: reasonCtrl.text.trim(),
          );

          Get.back(); // Close dialog

          Get.snackbar(
            "Rejected",
            "Request declined.",
            backgroundColor: Colors.red,
            colorText: Colors.white,
            snackPosition: SnackPosition.BOTTOM,
          );

          print("✅ Fee request rejected successfully");
        } catch (e) {
          print("❌ Error rejecting fee: $e");
          Get.snackbar(
            "Error",
            "Failed to reject: ${e.toString()}",
            backgroundColor: Colors.red,
            colorText: Colors.white,
          );
        } finally {
          isLoading.value = false;
        }
      },
    );
  }

  // --- VENDOR REQUEST ACTIONS ---
  Future<void> acceptRequest(String id) async {
    print("✅ Accepting vendor request: $id");

    try {
      isLoading.value = true;
      await _repo.updateRequestStatus(id, 'approved');

      Get.snackbar(
        "Success",
        "Vendor request approved!",
        backgroundColor: Colors.green,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );

      print("✅ Vendor request accepted successfully");
    } catch (e) {
      print("❌ Error accepting request: $e");
      Get.snackbar(
        "Error",
        "Failed to accept: ${e.toString()}",
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> rejectRequest(String id) async {
    print("❌ Rejecting vendor request: $id");

    try {
      isLoading.value = true;
      await _repo.updateRequestStatus(id, 'rejected');

      Get.snackbar(
        "Rejected",
        "Vendor request rejected.",
        backgroundColor: Colors.orange,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );

      print("✅ Vendor request rejected successfully");
    } catch (e) {
      print("❌ Error rejecting request: $e");
      Get.snackbar(
        "Error",
        "Failed to reject: ${e.toString()}",
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  @override
  void onClose() {
    print("🛑 OrdersController disposed");
    super.onClose();
  }
}
