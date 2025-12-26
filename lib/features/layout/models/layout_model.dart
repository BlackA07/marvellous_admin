import 'package:flutter/material.dart';

class AdminMenuItem {
  final String title;
  final IconData icon;
  final bool hasSubmenu;

  const AdminMenuItem({
    required this.title,
    required this.icon,
    this.hasSubmenu = false,
  });
}
