import 'package:get/get.dart';
import '../../data/models/order_model.dart';
import '../../data/models/vendor_request_model.dart';
import '../../data/repositories/orders_repository.dart';

class OrdersController extends GetxController {
  final OrdersRepository _repo = OrdersRepository();

  // Observables
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
    // Live Data Binding
    pendingOrders.bindStream(_repo.getPendingOrders());
    pendingRequests.bindStream(_repo.getPendingRequests());
  }

  // Called when entering History Screen
  void fetchHistory() {
    historyOrders.bindStream(_repo.getOrderHistory());
    historyRequests.bindStream(_repo.getRequestHistory());
  }

  // Actions
  Future<void> acceptOrder(String id) async {
    await _repo.updateOrderStatus(id, 'accepted');
    Get.snackbar("Success", "Order Accepted & Moved to History");
  }

  Future<void> rejectOrder(String id) async {
    await _repo.updateOrderStatus(id, 'rejected');
    Get.snackbar("Rejected", "Order Rejected");
  }

  Future<void> acceptRequest(String id) async {
    await _repo.updateRequestStatus(id, 'approved');
    Get.snackbar("Success", "Vendor Request Approved");
  }

  Future<void> rejectRequest(String id) async {
    await _repo.updateRequestStatus(id, 'rejected');
    Get.snackbar("Rejected", "Vendor Request Rejected");
  }
}
