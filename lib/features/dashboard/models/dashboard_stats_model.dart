import 'package:flutter/material.dart';

class DashboardStatsModel {
  final String title;
  final String value;
  final String change;
  final bool isIncrease;
  final IconData icon;
  final Color color;

  DashboardStatsModel({
    required this.title,
    required this.value,
    required this.change,
    required this.isIncrease,
    required this.icon,
    required this.color,
  });
}
