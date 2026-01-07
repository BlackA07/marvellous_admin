import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

// --- EXISTING IMPORTS ---
import 'package:marvellous_admin/features/categories/screens/categories_screen.dart';
import 'package:marvellous_admin/features/dashboard/presentation/screens/dashboard_screen.dart';
import 'package:marvellous_admin/features/finance/presentation/screens/earnings_dashboard_screen.dart';
import 'package:marvellous_admin/features/finance/presentation/screens/payouts_screen.dart';
import 'package:marvellous_admin/features/mlm/presentation/screens/commission_setup_screen.dart';
import 'package:marvellous_admin/features/mlm/presentation/screens/mlm_tree_view.dart';
import 'package:marvellous_admin/features/orders/presentation/screens/orders_dashboard_screen.dart';
import 'package:marvellous_admin/features/profile/presentation/screens/admin_profile_screen.dart';
import 'package:marvellous_admin/features/vendors/screens/vendors_list_screen.dart';

import '../../../../core/theme/pallete.dart';
import '../../controller/layout_controller.dart';

// --- PRODUCTS IMPORTS ---
import '../../../products/presentation/screens/products_home_screen.dart';
import '../../../products/presentation/screens/add_product_screen.dart';

// --- PACKAGES IMPORTS (New) ---
// Make sure paths are correct based on your folder structure
import '../../../packages/presentation/screens/packages_home_screen.dart'
    hide ProductsHomeScreen;
import '../../../packages/presentation/screens/add_package_screen.dart';

class AdminMenuItem {
  final String title;
  final IconData icon;
  final bool hasSubmenu;
  bool isExpanded;
  final List<String> subItems;

  AdminMenuItem({
    required this.title,
    required this.icon,
    this.hasSubmenu = false,
    this.isExpanded = false,
    this.subItems = const [],
  });
}

class AdminDrawer extends ConsumerStatefulWidget {
  const AdminDrawer({super.key});

  @override
  ConsumerState<AdminDrawer> createState() => _AdminDrawerState();
}

class _AdminDrawerState extends ConsumerState<AdminDrawer> {
  final List<AdminMenuItem> menuItems = [
    AdminMenuItem(title: "Dashboard", icon: Icons.dashboard_outlined),

    // PRODUCTS
    AdminMenuItem(
      title: "Products",
      icon: Icons.inventory_2_outlined,
      hasSubmenu: true,
      subItems: ["All Products", "Add Product", "Categories", "Vendors"],
    ),

    // PACKAGES (New Item)
    AdminMenuItem(
      title: "Packages",
      icon: Icons.all_inbox_outlined, // Good icon for bundles/packages
      hasSubmenu: true,
      subItems: ["Packages Home Screen", "Add Package"],
    ),

    AdminMenuItem(title: "Customers", icon: Icons.people_outline),
    AdminMenuItem(title: "Orders", icon: Icons.shopping_bag_outlined),

    // MLM
    AdminMenuItem(
      title: "MLM Network",
      icon: Icons.hub_outlined,
      hasSubmenu: true,
      subItems: ["Tree View", "Commissions"],
    ),

    AdminMenuItem(title: "Staff", icon: Icons.badge_outlined),

    // Finance
    AdminMenuItem(
      title: "Finance",
      icon: Icons.monetization_on_outlined,
      hasSubmenu: true,
      subItems: ["Earnings", "Payouts"],
    ),

    AdminMenuItem(title: "Reports", icon: Icons.bar_chart_outlined),
    AdminMenuItem(title: "Profile", icon: Icons.person_outlined),
  ];

  @override
  Widget build(BuildContext context) {
    final activeMain = ref.watch(activeMainItemProvider);
    final activeSub = ref.watch(activeSubItemProvider);
    final nav = ref.read(navigationProvider);

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
          // HEADER (Logo etc)
          Container(
            height: 120,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
            child: Row(
              children: [
                Image.asset('assets/images/logo.png', height: 65, width: 65),
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
                final bool isMainActive = activeMain == item.title;

                return Column(
                  children: [
                    // PARENT ITEM
                    ListTile(
                      onTap: () {
                        if (item.hasSubmenu) {
                          setState(() {
                            item.isExpanded = !item.isExpanded;
                          });
                        } else {
                          // DIRECT NAVIGATION
                          Widget screen = Center(
                            child: Text(
                              "${item.title} Screen",
                              style: const TextStyle(color: Colors.white),
                            ),
                          );

                          if (item.title == "Dashboard") {
                            screen = DashboardScreen();
                          } else if (item.title == "Orders") {
                            screen = const OrdersDashboardScreen();
                          } else if (item.title == "Profile") {
                            screen = const AdminProfileScreen();
                          }

                          nav.navigateTo(
                            mainItem: item.title,
                            subItem: null,
                            screen: screen,
                            title: item.title,
                          );

                          if (Scaffold.of(context).hasDrawer &&
                              Scaffold.of(context).isDrawerOpen) {
                            Navigator.pop(context);
                          }
                        }
                      },
                      leading: Icon(
                        item.icon,
                        color: isMainActive ? Pallete.neonBlue : Colors.grey,
                        size: 22,
                      ),
                      title: Text(
                        item.title,
                        style: GoogleFonts.comicNeue(
                          color: isMainActive
                              ? Colors.white
                              : Colors.grey.shade400,
                          fontWeight: isMainActive
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                      trailing: item.hasSubmenu
                          ? Icon(
                              item.isExpanded
                                  ? Icons.keyboard_arrow_up
                                  : Icons.keyboard_arrow_down,
                              size: 18,
                              color: Colors.grey.shade600,
                            )
                          : null,
                    ),

                    // SUBMENU ITEMS
                    if (item.hasSubmenu && item.isExpanded)
                      ...item.subItems.map((subItem) {
                        final bool isSubActive = activeSub == subItem;
                        return InkWell(
                          onTap: () {
                            if (Scaffold.of(context).hasDrawer &&
                                Scaffold.of(context).isDrawerOpen) {
                              Navigator.pop(context);
                            }

                            // --- SWITCHING LOGIC ---
                            Widget targetScreen = Center(
                              child: Text(
                                "$subItem Screen",
                                style: const TextStyle(color: Colors.white),
                              ),
                            );

                            // 1. PRODUCTS
                            if (item.title == "Products") {
                              if (subItem == "All Products") {
                                targetScreen = ProductsHomeScreen();
                              } else if (subItem == "Add Product") {
                                targetScreen = const AddProductScreen();
                              } else if (subItem == "Categories") {
                                targetScreen = CategoriesScreen();
                              } else if (subItem == "Vendors") {
                                targetScreen = VendorsListScreen();
                              }
                            }
                            // 2. PACKAGES (New Logic)
                            else if (item.title == "Packages") {
                              if (subItem == "Packages Home Screen") {
                                targetScreen = const PackagesHomeScreen();
                              } else if (subItem == "Add Package") {
                                targetScreen = const AddPackageScreen();
                              }
                            }
                            // 3. OTHERS
                            else if (item.title == "Orders") {
                              targetScreen = const OrdersDashboardScreen();
                            } else if (item.title == "MLM Network") {
                              if (subItem == "Tree View") {
                                targetScreen = const MLMTreeViewScreen();
                              } else if (subItem == "Commissions") {
                                targetScreen = const CommissionSetupScreen();
                              }
                            } else if (item.title == "Finance") {
                              if (subItem == "Earnings") {
                                targetScreen = const EarningsDashboardScreen();
                              } else if (subItem == "Payouts") {
                                targetScreen = const PayoutsScreen();
                              }
                            }

                            nav.navigateTo(
                              mainItem: item.title,
                              subItem: subItem,
                              screen: targetScreen,
                              title: subItem,
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              vertical: 10,
                              horizontal: 10,
                            ),
                            margin: const EdgeInsets.only(
                              left: 10,
                              right: 10,
                              bottom: 2,
                            ),
                            decoration: BoxDecoration(
                              color: isSubActive
                                  ? Colors.cyanAccent.withOpacity(0.1)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                const SizedBox(width: 40),
                                if (isSubActive)
                                  Container(
                                    width: 6,
                                    height: 6,
                                    margin: const EdgeInsets.only(right: 8),
                                    decoration: const BoxDecoration(
                                      color: Colors.cyanAccent,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                Text(
                                  subItem,
                                  style: GoogleFonts.comicNeue(
                                    color: isSubActive
                                        ? Colors.cyanAccent
                                        : Colors.white70,
                                    fontWeight: isSubActive
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
