import 'dashboard_stats_model.dart';
import 'recent_activity_model.dart';

class DashboardModel {
  final List<DashboardStatsModel> stats;
  final List<RecentActivityModel> recentActivities;

  DashboardModel({required this.stats, required this.recentActivities});
}
