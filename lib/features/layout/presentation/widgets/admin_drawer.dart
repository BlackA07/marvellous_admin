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
import 'package:marvellous_admin/features/settings/presentation/screens/variables_screen.dart';
import 'package:marvellous_admin/features/vendors/screens/vendors_list_screen.dart';

import '../../../../core/theme/pallete.dart';
import '../../../customers/presentation/screens/customers_screen.dart';
import '../../../vendor_purchase_product/presentation/screens/vendor_manage_bills_screen.dart';
import '../../../vendor_purchase_product/presentation/screens/vendor_purchase_screen.dart';

// ✅ IMPORT FOR YOUR NEW PAYMENT SCREEN (Make sure the file name is correct)
import '../../../vendor_purchase_product/presentation/screens/vendor_dues_history_screen.dart';
import '../../../vendor_purchase_product/presentation/screens/vendor_payment_dashboard.dart';
import '../../controller/layout_controller.dart';
import '../../../customers/presentation/screens/login_list_screen.dart';
// --- PRODUCTS IMPORTS ---
import '../../../products/presentation/screens/products_home_screen.dart';
import '../../../products/presentation/screens/add_product_screen.dart';
import '../../../products/presentation/screens/pending_requests_screen.dart';

// --- PACKAGES IMPORTS ---
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
    AdminMenuItem(title: "Point Variable", icon: Icons.settings_outlined),

    AdminMenuItem(
      title: "Products",
      icon: Icons.inventory_2_outlined,
      hasSubmenu: true,
      subItems: [
        "All Products",
        "Add Product",
        "Pending Requests",
        "Categories",
        "Vendors",
      ],
    ),

    AdminMenuItem(
      title: "Packages",
      icon: Icons.all_inbox_outlined,
      hasSubmenu: true,
      subItems: ["Packages Home Screen", "Add Package"],
    ),

    // ✅ FIXED: Customers with two subitems
    AdminMenuItem(
      title: "Customers",
      icon: Icons.people_outline,
      hasSubmenu: true,
      subItems: ["Customers Details", "Login List"],
    ),
    AdminMenuItem(title: "Orders", icon: Icons.shopping_bag_outlined),

    AdminMenuItem(
      title: "MLM Network",
      icon: Icons.hub_outlined,
      hasSubmenu: true,
      subItems: ["Tree View", "Commissions"],
    ),

    AdminMenuItem(title: "Staff", icon: Icons.badge_outlined),

    AdminMenuItem(
      title: "Payments",
      icon: Icons.payments_outlined,
      hasSubmenu: true,
      subItems: ["Vendor Payment", "Manage Vendor Bills"],
    ),

    AdminMenuItem(
      title: "Finance",
      icon: Icons.monetization_on_outlined,
      hasSubmenu: true,
      subItems: ["Earnings", "Payouts", "Purchase Products", "Vendor Dues"],
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
                          // DIRECT NAVIGATION (no submenu)
                          Widget screen = Center(
                            child: Text(
                              "${item.title} Screen",
                              style: const TextStyle(color: Colors.white),
                            ),
                          );

                          if (item.title == "Dashboard") {
                            screen = const DashboardScreen();
                          } else if (item.title == "Orders") {
                            screen = const OrdersDashboardScreen();
                          } else if (item.title == "Profile") {
                            screen = const AdminProfileScreen();
                          } else if (item.title == "Point Variable") {
                            screen = const VariablesScreen();
                          }
                          // ✅ "Customers" is now hasSubmenu = true, so this block is never reached.
                          // But if we later change it, we handle it safely.
                          else if (item.title == "Customers") {
                            // Default to Customer Details if clicked directly
                            screen = const CustomersScreen();
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
                            // Close drawer first
                            if (Scaffold.of(context).hasDrawer &&
                                Scaffold.of(context).isDrawerOpen) {
                              Navigator.pop(context);
                            }

                            // Determine target screen based on parent and subItem
                            Widget targetScreen = Center(
                              child: Text(
                                "$subItem Screen",
                                style: const TextStyle(color: Colors.white),
                              ),
                            );

                            // ─── PRODUCTS ───────────────────────────────
                            if (item.title == "Products") {
                              if (subItem == "All Products") {
                                targetScreen = const ProductsHomeScreen();
                              } else if (subItem == "Add Product") {
                                targetScreen = const AddProductScreen();
                              } else if (subItem == "Pending Requests") {
                                targetScreen = const PendingRequestsScreen();
                              } else if (subItem == "Categories") {
                                targetScreen = CategoriesScreen();
                              } else if (subItem == "Vendors") {
                                targetScreen = VendorsListScreen();
                              }
                            }
                            // ─── PACKAGES ──────────────────────────────
                            else if (item.title == "Packages") {
                              if (subItem == "Packages Home Screen") {
                                targetScreen = const PackagesHomeScreen();
                              } else if (subItem == "Add Package") {
                                targetScreen = const AddPackageScreen();
                              }
                            }
                            // ─── CUSTOMERS (FIXED) ─────────────────────
                            else if (item.title == "Customers") {
                              if (subItem == "Customers Details") {
                                targetScreen = const CustomersScreen();
                              } else if (subItem == "Login List") {
                                // ✅ Dummy placeholder for Login List
                                targetScreen = const LoginListScreen();
                              }
                            }
                            // ─── MLM NETWORK ───────────────────────────
                            else if (item.title == "MLM Network") {
                              if (subItem == "Tree View") {
                                targetScreen = const MLMTreeViewScreen();
                              } else if (subItem == "Commissions") {
                                targetScreen = const CommissionSetupScreen();
                              }
                            }
                            // ─── PAYMENTS ──────────────────────────────
                            else if (item.title == "Payments") {
                              if (subItem == "Vendor Payment") {
                                targetScreen = const VendorPaymentDashboard();
                              } else if (subItem == "Manage Vendor Bills") {
                                targetScreen = const VendorManageBillsScreen();
                              }
                            }
                            // ─── FINANCE ───────────────────────────────
                            else if (item.title == "Finance") {
                              if (subItem == "Earnings") {
                                targetScreen = const EarningsDashboardScreen();
                              } else if (subItem == "Payouts") {
                                targetScreen = const PayoutsScreen();
                              } else if (subItem == "Purchase Products") {
                                targetScreen = const VendorPurchaseScreen();
                              } else if (subItem == "Vendor Dues") {
                                targetScreen = const VendorPaymentsScreen();
                              }
                            }
                            // ─── ORDERS (if it had subitems later) ─────
                            else if (item.title == "Orders") {
                              targetScreen = const OrdersDashboardScreen();
                            }

                            // Navigate using provider
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
