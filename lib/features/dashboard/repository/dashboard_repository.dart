import 'package:flutter/material.dart';
import '../models/dashboard_model.dart';
import '../models/dashboard_stats_model.dart';
import '../models/recent_activity_model.dart';

class DashboardRepository {
  Future<DashboardModel> fetchDashboardData() async {
    // Simulate API delay
    await Future.delayed(const Duration(seconds: 1));

    return DashboardModel(
      stats: [
        DashboardStatsModel(
          title: "Total Revenue",
          value: "\$45,231.89",
          change: "+20.1%",
          isIncrease: true,
          icon: Icons.monetization_on_outlined,
          color: Colors.cyanAccent,
        ),
        DashboardStatsModel(
          title: "Active Users",
          value: "2,350",
          change: "+15.2%",
          isIncrease: true,
          icon: Icons.people_outline,
          color: Colors.purpleAccent,
        ),
        DashboardStatsModel(
          title: "Bounce Rate",
          value: "12.5%",
          change: "-4.5%",
          isIncrease: false, // Good for bounce rate
          icon: Icons.show_chart,
          color: Colors.orangeAccent,
        ),
        DashboardStatsModel(
          title: "New Orders",
          value: "456",
          change: "+8.3%",
          isIncrease: true,
          icon: Icons.shopping_cart_outlined,
          color: Colors.greenAccent,
        ),
      ],
      recentActivities: [
        RecentActivityModel(
          id: "1",
          user: "Ali Khan",
          action: "Purchased iPhone 15",
          timestamp: "2 min ago",
          status: "Completed",
        ),
        RecentActivityModel(
          id: "2",
          user: "Sara Ahmed",
          action: "Updated Profile",
          timestamp: "15 min ago",
          status: "Pending",
        ),
        RecentActivityModel(
          id: "3",
          user: "John Doe",
          action: "Login Attempt",
          timestamp: "1 hr ago",
          status: "Failed",
        ),
        RecentActivityModel(
          id: "4",
          user: "Bilal",
          action: "New Ticket",
          timestamp: "2 hrs ago",
          status: "Completed",
        ),
      ],
    );
  }
}
