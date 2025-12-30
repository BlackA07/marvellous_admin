import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Layout Components
import '../../controller/layout_controller.dart';
import '../widgets/admin_app_bar.dart';
import '../widgets/admin_drawer.dart';

class MainLayoutScreen extends ConsumerWidget {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  MainLayoutScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch the current content widget
    final currentScreen = ref.watch(currentContentProvider);
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width > 1100;

    return Scaffold(
      key: _scaffoldKey,

      drawer: !isDesktop
          ? const Drawer(
              width: 260,
              backgroundColor: Color.fromARGB(0, 128, 124, 124),
              child: AdminDrawer(),
            )
          : null,

      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
            colors: [
              Colors.white,
              Color.fromARGB(255, 90, 87, 87),
              Color(0xFF606060),
              Color(0xFF1A1A1A),
            ],
            stops: [0.0, 0.4, 0.75, 1.0],
          ),
        ),
        child: Row(
          children: [
            if (isDesktop) const SizedBox(width: 260, child: AdminDrawer()),

            Expanded(
              child: Column(
                children: [
                  AdminAppBar(
                    isMobile: !isDesktop,
                    onMenuPressed: () {
                      _scaffoldKey.currentState?.openDrawer();
                    },
                  ),

                  // Displays whatever widget is set in the controller
                  Expanded(child: currentScreen),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
