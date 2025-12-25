import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

// 1. Page Index State (Kon sa page khula he)
final pageIndexProvider = StateProvider<int>((ref) => 0);
// 0 = Dashboard, 1 = Products, etc.

// 2. AppBar Title State (Top bar pe kya likha aaye)
final appBarTitleProvider = StateProvider<String>((ref) => "Dashboard");

class LayoutController {
  // Logic agar complex hui to yahan ayegi, filhal StateProvider kaafi he.
}
