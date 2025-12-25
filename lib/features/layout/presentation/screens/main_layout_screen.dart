import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Screens
import '../../../dashboard/presentation/screens/dashboard_screen.dart';

// Layout Components
import '../../controller/layout_controller.dart';
import '../widgets/admin_app_bar.dart';
import '../widgets/admin_drawer.dart';

class MainLayoutScreen extends ConsumerWidget {
  // Is Key se hum Drawer open karenge
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  MainLayoutScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedIndex = ref.watch(pageIndexProvider);
    final size = MediaQuery.of(context).size;

    // Check if device is Desktop/Web
    final isDesktop = size.width > 1100;

    // Pages List
    final List<Widget> pages = [
      DashboardScreen(), // Dashboard yahan load hoga
      const Center(
        child: Text("Products Screen", style: TextStyle(color: Colors.white)),
      ),
      const Center(
        child: Text("Customers Screen", style: TextStyle(color: Colors.white)),
      ),
      const Center(
        child: Text("Orders Screen", style: TextStyle(color: Colors.white)),
      ),
      const Center(
        child: Text(
          "MLM Network Screen",
          style: TextStyle(color: Colors.white),
        ),
      ),
      const Center(
        child: Text("Staff Screen", style: TextStyle(color: Colors.white)),
      ),
      const Center(
        child: Text("Finance Screen", style: TextStyle(color: Colors.white)),
      ),
      const Center(
        child: Text("Reports Screen", style: TextStyle(color: Colors.white)),
      ),
    ];

    return Scaffold(
      key: _scaffoldKey, // Key assign ki taake drawer khul sake
      // CHANGE 1: Solid color hata diya, kyunki ab body container men gradient hoga
      // backgroundColor: const Color(0xFF1E1E2C),

      // MOBILE DRAWER
      drawer: !isDesktop
          ? const Drawer(
              width: 260,
              backgroundColor: Colors.transparent,
              child: AdminDrawer(),
            )
          : null,

      // CHANGE 2: Body ko Container men wrap kiya gradient k liye
      body: Container(
        decoration: const BoxDecoration(
          // Dark Grey Gradient Theme
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF353A50), // Light dark-grey (Top Left)
              Color(0xFF252836), // Mid dark-grey
              Color(0xFF1B1B26), // Darkest grey/black (Bottom Right)
            ],
            stops: [0.0, 0.5, 1.0],
          ),
        ),
        child: Row(
          children: [
            // 1. DESKTOP DRAWER (Fixed Left Side)
            if (isDesktop) const SizedBox(width: 260, child: AdminDrawer()),

            // 2. RIGHT SIDE CONTENT
            Expanded(
              child: Column(
                children: [
                  // Top AppBar
                  AdminAppBar(
                    isMobile: !isDesktop,
                    onMenuPressed: () {
                      // Ye button click hone par drawer khulega
                      _scaffoldKey.currentState?.openDrawer();
                    },
                  ),

                  // Main Page Content
                  Expanded(
                    // CHANGE 3: Yahan se solid color hataya taake gradient nazar aaye
                    child: Container(
                      // color: const Color(0xFF1E1E2C), // <--- REMOVED THIS
                      child: pages[selectedIndex],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
