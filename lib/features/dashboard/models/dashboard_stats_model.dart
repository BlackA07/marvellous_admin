// lib/features/reports/shared/models/dashboard_stats_model.dart

import 'package:flutter/material.dart';

class DashboardStatsModel {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;

  DashboardStatsModel({
    required this.title,
    required this.value,
    this.subtitle = '',
    required this.icon,
    required this.color,
  });
}
