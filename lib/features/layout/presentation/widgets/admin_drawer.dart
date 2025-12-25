import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/pallete.dart';
import '../../controller/layout_controller.dart';
import '../../models/layout_model.dart';

class AdminDrawer extends ConsumerWidget {
  const AdminDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedIndex = ref.watch(pageIndexProvider);

    // Items definition
    final List<AdminMenuItem> menuItems = [
      const AdminMenuItem(title: "Dashboard", icon: Icons.dashboard_outlined),
      const AdminMenuItem(
        title: "Products",
        icon: Icons.inventory_2_outlined,
        hasSubmenu: true,
      ),
      const AdminMenuItem(title: "Customers", icon: Icons.people_outline),
      const AdminMenuItem(title: "Orders", icon: Icons.shopping_bag_outlined),
      const AdminMenuItem(
        title: "MLM Network",
        icon: Icons.hub_outlined,
        hasSubmenu: true,
      ),
      const AdminMenuItem(title: "Staff", icon: Icons.badge_outlined),
      const AdminMenuItem(
        title: "Finance",
        icon: Icons.monetization_on_outlined,
        hasSubmenu: true,
      ),
      const AdminMenuItem(title: "Reports", icon: Icons.bar_chart_outlined),
    ];

    return Container(
      width: 260,
      height: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF2C2C2C), Color(0xFF1A1A1A), Color(0xFF000000)],
        ),
        border: Border(right: BorderSide(color: Colors.white10)),
      ),
      child: Column(
        children: [
          // HEADER AREA (Logo & Name)
          Container(
            height: 120, // Height kam ki
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
            child: Row(
              children: [
                Image.asset('assets/images/logo.png', height: 65, width: 65),
                // const Icon(
                //   Icons.admin_panel_settings,
                //   color: Colors.cyanAccent,
                //   size: 40,
                // ),
                const SizedBox(width: 15),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Marvellous",
                      style: GoogleFonts.orbitron(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      "Admin Panel",
                      style: GoogleFonts.comicNeue(
                        color: Pallete.neonBlue,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const Divider(color: Colors.white10, height: 1),

          // MENU LIST
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 10),
              itemCount: menuItems.length,
              itemBuilder: (context, index) {
                final item = menuItems[index];
                final isSelected = selectedIndex == index;

                return Container(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color: isSelected
                        ? Colors.white.withOpacity(0.1)
                        : Colors.transparent,
                    border: isSelected
                        ? Border.all(color: Colors.white12)
                        : null,
                  ),
                  child: ListTile(
                    onTap: () {
                      ref.read(pageIndexProvider.notifier).state = index;
                      ref.read(appBarTitleProvider.notifier).state = item.title;

                      // Agar mobile drawer khula hai to band kardo
                      if (Scaffold.of(context).hasDrawer &&
                          Scaffold.of(context).isDrawerOpen) {
                        Navigator.pop(context);
                      }
                    },
                    leading: Icon(
                      item.icon,
                      color: isSelected ? Pallete.neonBlue : Colors.grey,
                      size: 22,
                    ),
                    title: Text(
                      item.title,
                      style: GoogleFonts.comicNeue(
                        color: isSelected ? Colors.white : Colors.grey.shade400,
                        fontWeight: isSelected
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                    trailing: item.hasSubmenu
                        ? Icon(
                            Icons.chevron_right,
                            size: 18,
                            color: Colors.grey.shade600,
                          )
                        : null,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
