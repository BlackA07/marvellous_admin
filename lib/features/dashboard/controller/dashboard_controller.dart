import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart'; // For NumberFormat
import '../models/dashboard_model.dart';
import '../models/dashboard_stats_model.dart';
import '../models/recent_activity_model.dart';

class DashboardController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  var isLoading = true.obs;
  var isDrawerOpen = true.obs;
  var dashboardData = Rxn<DashboardModel>();
  var selectedFilter = "Day".obs;

  @override
  void onInit() {
    super.onInit();
    fetchData();
  }

  void toggleDrawer() {
    isDrawerOpen.value = !isDrawerOpen.value;
  }

  void updateFilter(String filter) {
    selectedFilter.value = filter;
  }

  void fetchData() async {
    try {
      isLoading(true);

      // --- 1. Fetch Real Counts (Current Month) ---
      // Note: Real apps use 'created_at' to filter by month.
      // Here we assume total count for simplicity MVP.
      var usersSnapshot = await _firestore.collection('users').count().get();
      var vendorsSnapshot = await _firestore
          .collection('vendors')
          .count()
          .get();

      int currentUsers = usersSnapshot.count ?? 0;
      int currentVendors = vendorsSnapshot.count ?? 0;

      // --- 2. Fetch Orders for Revenue & Pending ---
      var ordersSnapshot = await _firestore.collection('orders').get();
      int pendingOrders = 0;
      double totalRevenue = 0.0;

      for (var doc in ordersSnapshot.docs) {
        var data = doc.data();
        if (data['status'] == 'Pending') {
          pendingOrders++;
        }
        if (data['status'] == 'Delivered' || data['status'] == 'Completed') {
          totalRevenue += (data['totalAmount'] ?? 0).toDouble();
        }
      }

      // --- 3. Mock Previous Month Data (Since we don't have history yet) ---
      // In real app, you would fetch count where createdAt < startOfThisMonth
      int prevUsers = 0; // Example: Last month 0
      int prevVendors = 0;
      double prevRevenue = 0.0;
      int prevPending = 0;

      // --- Calculate Percentages ---
      String userChange = _calculatePercentageChange(currentUsers, prevUsers);
      String vendorChange = _calculatePercentageChange(
        currentVendors,
        prevVendors,
      );
      String revenueChange = _calculatePercentageChange(
        totalRevenue,
        prevRevenue,
      );
      String pendingChange = _calculatePercentageChange(
        pendingOrders,
        prevPending,
      );

      // Format Revenue
      final currencyFormatter = NumberFormat.currency(
        locale: 'en_PK',
        symbol: 'PKR ',
        decimalDigits: 0,
      );
      String formattedRevenue = currencyFormatter.format(totalRevenue);

      // --- 4. Fetch Recent Activity ---
      var productsSnapshot = await _firestore
          .collection('products')
          .orderBy('dateAdded', descending: true)
          .limit(5)
          .get();

      List<RecentActivityModel> activities = productsSnapshot.docs.map((doc) {
        var data = doc.data();
        Timestamp? ts = data['dateAdded'];
        String timeAgo = ts != null
            ? _formatTimestamp(ts.toDate())
            : "Just now";

        return RecentActivityModel(
          id: doc.id,
          user: "Admin",
          action: "Added ${data['name']}",
          timestamp: timeAgo,
          status: "Completed",
        );
      }).toList();

      // --- 5. Build Stats List ---
      List<DashboardStatsModel> stats = [
        DashboardStatsModel(
          title: "Total Revenue",
          value: formattedRevenue,
          icon: Icons.attach_money,
          color: Colors.greenAccent,
          change: revenueChange,
          isIncrease: !revenueChange.startsWith('-'),
        ),
        DashboardStatsModel(
          title: "Total Users",
          value: "$currentUsers",
          icon: Icons.group,
          color: Colors.purpleAccent,
          change: userChange,
          isIncrease: !userChange.startsWith('-'),
        ),
        DashboardStatsModel(
          title: "Total Vendors",
          value: "$currentVendors",
          icon: Icons.store,
          color: Colors.orangeAccent,
          change: vendorChange,
          isIncrease: !vendorChange.startsWith('-'),
        ),
        DashboardStatsModel(
          title: "Pending Orders",
          value: "$pendingOrders",
          icon: Icons.shopping_cart,
          color: Colors.blueAccent,
          change: pendingChange,
          isIncrease: !pendingChange.startsWith('-'),
        ),
      ];

      dashboardData.value = DashboardModel(
        stats: stats,
        recentActivities: activities,
      );
    } catch (e) {
      print("Error fetching dashboard data: $e");
      Get.snackbar("Error", "Failed to load data");
    } finally {
      isLoading(false);
    }
  }

  // Percentage Calculation Logic
  String _calculatePercentageChange(num current, num previous) {
    if (previous == 0) {
      return current == 0 ? "0%" : "+100%"; // 0 to something is 100% increase
    }
    double change = ((current - previous) / previous) * 100;
    return "${change >= 0 ? '+' : ''}${change.toStringAsFixed(1)}%";
  }

  String _formatTimestamp(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inDays > 0) return "${diff.inDays}d ago";
    if (diff.inHours > 0) return "${diff.inHours}h ago";
    if (diff.inMinutes > 0) return "${diff.inMinutes}m ago";
    return "Just now";
  }
}
