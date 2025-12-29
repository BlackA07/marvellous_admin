// File: lib/features/finance/presentation/controllers/finance_controller.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import '../../data/models/payout_request_model.dart';
import '../../data/repositories/finance_repository.dart';
import '../../../orders/data/models/order_model.dart'; // Order Model Import zaroori hai

class FinanceController extends GetxController {
  final FinanceRepository _repo = FinanceRepository();

  // Earnings Stats
  var totalEarnings = 0.0.obs;
  var monthlyEarnings = 0.0.obs;
  var dailyEarnings = 0.0.obs;

  // Real Data Lists
  var recentOrders = <OrderModel>[].obs; // Dashboard k liye recent list
  var customerPayouts = <PayoutRequestModel>[].obs;
  var vendorPayouts = <PayoutRequestModel>[].obs;

  var isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    _bindStreams();
    _fetchStatsAndRecent();
  }

  void _bindStreams() {
    // Real-time Total Earnings
    totalEarnings.bindStream(_repo.getTotalEarnings());

    // Payouts
    customerPayouts.bindStream(_repo.getPayoutRequests('customer'));
    vendorPayouts.bindStream(_repo.getPayoutRequests('vendor'));
  }

  void _fetchStatsAndRecent() async {
    // 1. Fetch One-time Stats
    monthlyEarnings.value = await _repo.getMonthlyEarnings();
    dailyEarnings.value = await _repo.getDailyEarnings();

    // 2. Fetch Recent Transactions (Real Data)
    // Hum sidha Firestore use kar rahe hen taake OrderModel men data mile
    // Kyunke EarningStatModel se OrderDetailScreen men jana mushkil hoga
    var snapshot = await FirebaseFirestore.instance
        .collection('orders')
        .where('status', isEqualTo: 'completed') // Sirf completed orders
        .orderBy('createdAt', descending: true)
        .limit(5) // Sirf top 5 recent
        .get();

    recentOrders.value = snapshot.docs
        .map((doc) => OrderModel.fromMap(doc.data(), doc.id))
        .toList();
  }

  // --- Logic for History Screen (Filtering) ---
  Future<List<OrderModel>> getOrdersByFilter(String filter) async {
    // filter types: 'all', 'month', 'today'
    Query query = FirebaseFirestore.instance
        .collection('orders')
        .where('status', isEqualTo: 'completed')
        .orderBy('createdAt', descending: true);

    DateTime now = DateTime.now();

    if (filter == 'month') {
      DateTime startOfMonth = DateTime(now.year, now.month, 1);
      query = query.where('createdAt', isGreaterThanOrEqualTo: startOfMonth);
    } else if (filter == 'today') {
      DateTime startOfDay = DateTime(now.year, now.month, now.day);
      query = query.where('createdAt', isGreaterThanOrEqualTo: startOfDay);
    }

    // Fetch Data
    var snapshot = await query.get();
    return snapshot.docs
        .map(
          (doc) =>
              OrderModel.fromMap(doc.data() as Map<String, dynamic>, doc.id),
        )
        .toList();
  }

  // Payout Actions
  Future<void> approvePayout(String id) async {
    try {
      await _repo.updatePayoutStatus(id, 'approved');
      Get.snackbar("Success", "Payout Approved Successfully");
    } catch (e) {
      Get.snackbar("Error", "Failed to approve: $e");
    }
  }

  Future<void> rejectPayout(String id) async {
    try {
      await _repo.updatePayoutStatus(id, 'rejected');
      Get.snackbar("Rejected", "Payout Request Rejected");
    } catch (e) {
      Get.snackbar("Error", "Failed to reject: $e");
    }
  }
}
