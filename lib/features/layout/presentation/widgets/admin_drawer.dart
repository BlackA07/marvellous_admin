import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

// --- EXISTING IMPORTS ---
import 'package:marvellous_admin/features/categories/screens/categories_screen.dart';
import 'package:marvellous_admin/features/dashboard/presentation/screens/dashboard_screen.dart';
import 'package:marvellous_admin/features/mlm/presentation/screens/commission_setup_screen.dart';
import 'package:marvellous_admin/features/mlm/presentation/screens/mlm_tree_view.dart';
import 'package:marvellous_admin/features/orders/presentation/screens/orders_dashboard_screen.dart';
import 'package:marvellous_admin/features/profile/presentation/screens/admin_profile_screen.dart';
import 'package:marvellous_admin/features/settings/presentation/screens/variables_screen.dart';
import 'package:marvellous_admin/features/vendors/screens/vendors_list_screen.dart';

import '../../../../core/theme/pallete.dart';
import '../../../customers/presentation/screens/customers_screen.dart';
import '../../../finance/screens/banks_screen.dart';
import '../../../finance/screens/expenses_screen.dart';
import '../../../finance/screens/taxes_screen.dart';
import '../../../staff/presentation/add_staff_screen.dart';
import '../../../staff/presentation/staff_list/staff_list_screen.dart';
import '../../../user_settings/views/user_settings_screen.dart';

// --- VENDOR IMPORTS ---
import '../../../vendor_purchase_product/presentation/screens/admin_order_requests_screen.dart';
import '../../../vendor_purchase_product/presentation/screens/vendor_manage_bills_screen.dart';
import '../../../vendor_purchase_product/presentation/screens/vendor_purchase_screen.dart';
import '../../../vendor_purchase_product/presentation/screens/vendor_dues_history_screen.dart';
import '../../../vendor_purchase_product/presentation/screens/vendor_payment_dashboard.dart';
// ✅ NEW SCREEN IMPORT (Path adjust kar lena agar file kisi aur folder me ho)
import '../../../vendor_purchase_product/presentation/screens/create_order_request_screen.dart';

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
  bool _isLoadingPermissions = true;
  List<AdminMenuItem> _displayedMenuItems = [];

  // Yeh aapka original master menu hai
  final List<AdminMenuItem> _masterMenuItems = [
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
      ], // ✅ "Vendors" removed from here
    ),
    // ✅ NEW DEDICATED VENDORS MENU ADDED
    AdminMenuItem(
      title: "Vendors",
      icon: Icons.storefront_outlined,
      hasSubmenu: true,
      subItems: [
        "All Vendors",
        "Create Order Request",
        "All Order Requests", // ✅ Naya submenu for viewing all order requests
        "Purchase Products",
        "Vendor Dues",
        "Vendor Payment",
        "Manage Vendor Bills",
      ],
    ),
    AdminMenuItem(
      title: "Packages",
      icon: Icons.all_inbox_outlined,
      hasSubmenu: true,
      subItems: ["Packages Home Screen", "Add Package"],
    ),
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
    AdminMenuItem(
      title: "Staff",
      icon: Icons.badge_outlined,
      hasSubmenu: true,
      subItems: [
        "Add New Staff",
        "All Staff List",
        "User Settings & Permissions",
      ],
    ),
    // ✅ "Payments" Main Menu was fully moved into Vendors, so it's removed
    AdminMenuItem(
      title: "Finance",
      icon: Icons.monetization_on_outlined,
      hasSubmenu: true,
      subItems: [
        "Banks",
        "Expenses",
        "Taxes",
      ], // ✅ Vendor stuff removed from Finance
    ),
    AdminMenuItem(title: "Reports", icon: Icons.bar_chart_outlined),
    AdminMenuItem(title: "Profile", icon: Icons.person_outlined),
  ];

  @override
  void initState() {
    super.initState();
    _loadUserPermissions();
  }

  Future<void> _loadUserPermissions() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        setState(() => _isLoadingPermissions = false);
        return;
      }

      // 1. Pehle check karein ke kya yeh Super Admin hai?
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (userDoc.exists && userDoc.data()?['role'] == 'admin') {
        // Super Admin ko sab kuch dikhana hai
        setState(() {
          _displayedMenuItems = List.from(_masterMenuItems);
          _isLoadingPermissions = false;
        });
        return;
      }

      // 2. Agar Super Admin nahi hai, to pehle Staff ka data uske email se dhoondein
      final staffQuery = await FirebaseFirestore.instance
          .collection('staff')
          .where('email', isEqualTo: user.email)
          .limit(1)
          .get();

      if (staffQuery.docs.isEmpty) {
        // Agar staff record nahi mila to fallback
        _filterMenuBasedOnPermissions({});
        return;
      }

      final staffId = staffQuery.docs.first.id;

      // 3. Ab us sahi staffId se permissions nikalein
      final permDoc = await FirebaseFirestore.instance
          .collection('user_permissions')
          .doc(staffId)
          .get();

      if (permDoc.exists && permDoc.data() != null) {
        final data = permDoc.data()!;
        Map<String, List<String>> userPerms = {};
        if (data['permissions'] != null) {
          (data['permissions'] as Map<String, dynamic>).forEach((key, value) {
            userPerms[key] = List<String>.from(value);
          });
        }
        _filterMenuBasedOnPermissions(userPerms);
      } else {
        // Agar koi permission nahi mili to sirf Dashboard aur Profile dikhao
        _filterMenuBasedOnPermissions({});
      }
    } catch (e) {
      debugPrint('Error loading permissions: $e');
      // Fallback: Show only basic items on error
      _filterMenuBasedOnPermissions({});
    }
  }

  void _filterMenuBasedOnPermissions(Map<String, List<String>> perms) {
    List<AdminMenuItem> filtered = [];

    for (var item in _masterMenuItems) {
      // Dashboard aur Profile hamesha show hote hain

      if (item.hasSubmenu) {
        List<String> allowedSubItems = [];

        // Check permissions for each subitem
        for (var sub in item.subItems) {
          String key =
              '${item.title}|$sub'; // Format matching the controller's save logic

          if (perms.containsKey(key) && perms[key]!.isNotEmpty) {
            allowedSubItems.add(sub);
          }
        }

        // Agar kisi ek subitem ki permission hai, to parent menu show kardo
        if (allowedSubItems.isNotEmpty) {
          filtered.add(
            AdminMenuItem(
              title: item.title,
              icon: item.icon,
              hasSubmenu: true,
              isExpanded: false,
              subItems: allowedSubItems,
            ),
          );
        }
      } else {
        // Un items ke liye jinka koi submenu nahi hai (like Orders, Point Variable)
        if (perms.containsKey(item.title) && perms[item.title]!.isNotEmpty) {
          filtered.add(
            AdminMenuItem(
              title: item.title,
              icon: item.icon,
              hasSubmenu: false,
              isExpanded: false,
            ),
          );
        }
      }
    }

    setState(() {
      _displayedMenuItems = filtered;
      _isLoadingPermissions = false;
    });
  }

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

          // LOADING INDICATOR YA MENU LIST
          Expanded(
            child: _isLoadingPermissions
                ? const Center(
                    child: CircularProgressIndicator(color: Pallete.neonBlue),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    itemCount: _displayedMenuItems.length,
                    itemBuilder: (context, index) {
                      final item = _displayedMenuItems[index];
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
                                } else if (item.title == "Customers") {
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
                              color: isMainActive
                                  ? Pallete.neonBlue
                                  : Colors.grey,
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
                                      style: const TextStyle(
                                        color: Colors.white,
                                      ),
                                    ),
                                  );

                                  // ─── PRODUCTS ───────────────────────────────
                                  if (item.title == "Products") {
                                    if (subItem == "All Products") {
                                      targetScreen = const ProductsHomeScreen();
                                    } else if (subItem == "Add Product") {
                                      targetScreen = const AddProductScreen();
                                    } else if (subItem == "Pending Requests") {
                                      targetScreen =
                                          const PendingRequestsScreen();
                                    } else if (subItem == "Categories") {
                                      targetScreen = CategoriesScreen();
                                    }
                                  }
                                  // ─── VENDORS (✅ NAYA SECTION) ───────────────
                                  else if (item.title == "Vendors") {
                                    if (subItem == "All Vendors") {
                                      targetScreen = VendorsListScreen();
                                    } else if (subItem ==
                                        "Create Order Request") {
                                      targetScreen =
                                          const CreateOrderRequestScreen();
                                    } else if (subItem ==
                                        "All Order Requests") {
                                      targetScreen =
                                          const AdminOrderRequestsScreen();
                                    } else if (subItem == "Purchase Products") {
                                      targetScreen =
                                          const VendorPurchaseScreen();
                                    } else if (subItem == "Vendor Dues") {
                                      targetScreen =
                                          const VendorPaymentsScreen();
                                    } else if (subItem == "Vendor Payment") {
                                      targetScreen =
                                          const VendorPaymentDashboard();
                                    } else if (subItem ==
                                        "Manage Vendor Bills") {
                                      targetScreen =
                                          const VendorManageBillsScreen();
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
                                      targetScreen = const LoginListScreen();
                                    }
                                  }
                                  // ─── MLM NETWORK ───────────────────────────
                                  else if (item.title == "MLM Network") {
                                    if (subItem == "Tree View") {
                                      targetScreen = const MLMTreeViewScreen();
                                    } else if (subItem == "Commissions") {
                                      targetScreen =
                                          const CommissionSetupScreen();
                                    }
                                  } else if (item.title == "Staff") {
                                    if (subItem == "Add New Staff") {
                                      targetScreen = AddStaffScreen();
                                    } else if (subItem == "All Staff List") {
                                      targetScreen = StaffListScreen();
                                    } else if (subItem ==
                                        "User Settings & Permissions") {
                                      targetScreen = UserSettingsScreen();
                                    }
                                  }
                                  // ─── FINANCE ───────────────────────────────
                                  else if (item.title == "Finance") {
                                    if (subItem == "Banks") {
                                      targetScreen = BanksScreen();
                                    } else if (subItem == "Expenses") {
                                      targetScreen = ExpensesScreen();
                                    } else if (subItem == "Taxes") {
                                      targetScreen = TaxesScreen();
                                    }
                                  }
                                  // ─── ORDERS ───────────────────────────────
                                  else if (item.title == "Orders") {
                                    targetScreen =
                                        const OrdersDashboardScreen();
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
                                          margin: const EdgeInsets.only(
                                            right: 8,
                                          ),
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
