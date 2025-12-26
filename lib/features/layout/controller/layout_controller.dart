import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../../dashboard/presentation/screens/dashboard_screen.dart';

final activeMainItemProvider = StateProvider<String>((ref) => "Dashboard");
final activeSubItemProvider = StateProvider<String?>((ref) => null);
final currentContentProvider = StateProvider<Widget>(
  (ref) => DashboardScreen(),
);
final appBarTitleProvider = StateProvider<String>((ref) => "Dashboard");

class NavigationController {
  final Ref ref;

  NavigationController(this.ref);

  void navigateTo({
    required String mainItem,
    String? subItem,
    required Widget screen,
    required String title,
  }) {
    ref.read(activeMainItemProvider.notifier).state = mainItem;
    ref.read(activeSubItemProvider.notifier).state = subItem;
    ref.read(currentContentProvider.notifier).state = screen;
    ref.read(appBarTitleProvider.notifier).state = title;
  }
}

final navigationProvider = Provider((ref) => NavigationController(ref));
