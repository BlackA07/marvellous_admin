// lib/features/reports/shared/repository/dashboard_repository.dart

import 'package:flutter/material.dart';
import '../models/dashboard_model.dart';
import '../models/dashboard_stats_model.dart';
import '../models/recent_activity_model.dart';

class DashboardRepository {
  Future<DashboardModel> fetchDashboardData() async {
    await Future.delayed(const Duration(seconds: 1));

    return DashboardModel(
      stats: [
        DashboardStatsModel(
          title: "Total Revenue",
          value: "\$45,231.89",
          icon: Icons.monetization_on_outlined,
          color: Colors.cyanAccent,
        ),
        DashboardStatsModel(
          title: "Active Users",
          value: "2,350",
          icon: Icons.people_outline,
          color: Colors.purpleAccent,
        ),
        DashboardStatsModel(
          title: "Bounce Rate",
          value: "12.5%",
          icon: Icons.show_chart,
          color: Colors.orangeAccent,
        ),
        DashboardStatsModel(
          title: "New Orders",
          value: "456",
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
