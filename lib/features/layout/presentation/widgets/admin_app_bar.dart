import 'dart:convert'; // Image decode k liye
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:badges/badges.dart' as badges;
import 'package:marvellous_admin/features/auth/presentation/login_screen.dart';
import 'package:marvellous_admin/features/profile/presentation/controllers/profile_controller.dart';

// Theme Import
import '../../../../core/theme/pallete.dart';

// Controllers Imports
import '../../../orders/presentation/controllers/orders_controller.dart';
import '../../../products/controller/products_controller.dart';

// Screens Imports
import '../../../orders/presentation/screens/orders_dashboard_screen.dart';
import '../../../profile/presentation/screens/admin_profile_screen.dart';
import '../../../products/presentation/screens/pending_requests_screen.dart';

// ✅ NAYA CONTROLLER: Jo login hone wale user ki permissions check karega
class CurrentUserController extends GetxController {
  var isAdmin = false.obs;
  var permissions = <String, List<String>>{}.obs;
  var isLoading = true.obs;

  @override
  void onInit() {
    super.onInit();
    _loadPermissions();
  }

  Future<void> _loadPermissions() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      if (userDoc.exists && userDoc.data()?['role'] == 'admin') {
        isAdmin.value = true;
        isLoading.value = false;
        return;
      }

      final staffQuery = await FirebaseFirestore.instance
          .collection('staff')
          .where('email', isEqualTo: user.email)
          .limit(1)
          .get();
      if (staffQuery.docs.isEmpty) {
        isLoading.value = false;
        return;
      }

      final staffId = staffQuery.docs.first.id;
      final permDoc = await FirebaseFirestore.instance
          .collection('user_permissions')
          .doc(staffId)
          .get();

      if (permDoc.exists && permDoc.data() != null) {
        final data = permDoc.data()!;
        if (data['permissions'] != null) {
          Map<String, List<String>> temp = {};
          (data['permissions'] as Map<String, dynamic>).forEach((k, v) {
            temp[k] = List<String>.from(v);
          });
          permissions.value = temp;
        }
      }
    } catch (e) {
      debugPrint(e.toString());
    } finally {
      isLoading.value = false;
    }
  }

  bool hasPermission(String module, [String? subItem]) {
    if (isAdmin.value) return true;
    if (subItem != null) {
      return permissions.containsKey('$module|$subItem') &&
          permissions['$module|$subItem']!.isNotEmpty;
    }
    return permissions.containsKey(module) && permissions[module]!.isNotEmpty;
  }
}

class AdminAppBar extends StatelessWidget {
  final VoidCallback onMenuPressed;
  final bool isMobile;

  const AdminAppBar({
    Key? key,
    required this.onMenuPressed,
    this.isMobile = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Inject controllers
    final profileController = Get.isRegistered<ProfileController>()
        ? Get.find<ProfileController>()
        : Get.put(ProfileController());
    final ordersController = Get.isRegistered<OrdersController>()
        ? Get.find<OrdersController>()
        : Get.put(OrdersController());
    final productsController = Get.isRegistered<ProductsController>()
        ? Get.find<ProductsController>()
        : Get.put(ProductsController());

    // ✅ Inject our new CurrentUserController
    final currentUserCtrl = Get.put(CurrentUserController());

    return SafeArea(
      bottom: false,
      child: Container(
        height: 70,
        padding: const EdgeInsets.symmetric(horizontal: 15),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E2C),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.5),
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
          border: const Border(
            bottom: BorderSide(color: Colors.white12, width: 1),
          ),
        ),
        child: Row(
          children: [
            if (isMobile) ...[
              IconButton(
                onPressed: onMenuPressed,
                icon: const Icon(Icons.menu, color: Colors.cyanAccent),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              const SizedBox(width: 10),
            ],

            Expanded(
              child: Center(
                child: Obx(() {
                  if (profileController.isLoading.value) {
                    return const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.cyanAccent,
                      ),
                    );
                  }
                  return Text(
                    profileController.nameController.text.isEmpty
                        ? "Admin Panel"
                        : profileController.nameController.text,
                    style: GoogleFonts.comicNeue(
                      color: Colors.white,
                      fontSize: isMobile ? 24 : 32,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                    overflow: TextOverflow.ellipsis,
                  );
                }),
              ),
            ),

            // --- PENDING PRODUCT REQUESTS BADGE ---
            Obx(() {
              // Hide if user does NOT have permission to Pending Requests
              if (!currentUserCtrl.hasPermission(
                'Products',
                'Pending Requests',
              )) {
                return const SizedBox.shrink();
              }

              int productReqs = productsController.pendingRequestsList.length;
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  badges.Badge(
                    showBadge: productReqs > 0,
                    badgeContent: Text(
                      '$productReqs',
                      style: const TextStyle(color: Colors.white, fontSize: 10),
                    ),
                    badgeStyle: const badges.BadgeStyle(
                      badgeColor: Colors.orange,
                      elevation: 0,
                    ),
                    position: badges.BadgePosition.topEnd(top: -5, end: -2),
                    child: _AppBarIcon(
                      icon: Icons.inventory_outlined,
                      tooltip: "Pending Product Requests",
                      onTap: () {
                        Get.to(() => const PendingRequestsScreen());
                      },
                    ),
                  ),
                  const SizedBox(width: 15),
                ],
              );
            }),

            // --- Wallet Icon (Earnings) ---
            Obx(() {
              // Hide if user does NOT have permission to Earnings
              if (!currentUserCtrl.hasPermission('Finance', 'Earnings')) {
                return const SizedBox.shrink();
              }

              return Row(mainAxisSize: MainAxisSize.min, children: [
                  
                  
                ],
              );
            }),

            // --- Orders Icon with Badge ---
            Obx(() {
              // Hide if user does NOT have permission to Orders
              if (!currentUserCtrl.hasPermission('Orders')) {
                return const SizedBox.shrink();
              }

              // ✅ FIX: Ab yahan har qisam ki pending requests ka total aayega
              int pendingCount =
                  ordersController.pendingOrders.length + // COD Orders
                  ordersController
                      .orderPaymentRequests
                      .length + // Online Payments
                  ordersController
                      .pendingVendorAccounts
                      .length + // New Vendor Signups
                  ordersController
                      .pendingRequests
                      .length + // Vendor Product Requests
                  ordersController.withdrawalRequests.length + // Withdrawals
                  ordersController.depositRequests.length + // Deposits
                  ordersController.feeRequests.length; // Old Fees

              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  badges.Badge(
                    showBadge: pendingCount > 0,
                    badgeContent: Text(
                      '$pendingCount',
                      style: const TextStyle(color: Colors.white, fontSize: 10),
                    ),
                    badgeStyle: const badges.BadgeStyle(
                      badgeColor: Colors.redAccent,
                      elevation: 0,
                    ),
                    position: badges.BadgePosition.topEnd(top: -5, end: -2),
                    child: _AppBarIcon(
                      icon: Icons.assignment_late_outlined,
                      tooltip: "Pending Operations & Requests",
                      onTap: () {
                        Get.to(() => OrdersDashboardScreen());
                      },
                    ),
                  ),
                  const SizedBox(width: 20),
                ],
              );
            }),

            // --- Profile Image ---
            Obx(() {
              // Hide if user does NOT have permission to Profile
              if (!currentUserCtrl.hasPermission('Profile')) {
                return const SizedBox.shrink();
              }

              return GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  Get.to(() => const AdminProfileScreen());
                },
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.cyanAccent),
                  ),
                  child: Obx(() {
                    bool hasImage =
                        profileController.profileImageBase64.value.isNotEmpty;

                    return CircleAvatar(
                      radius: 18,
                      backgroundColor: Colors.grey[800],
                      backgroundImage: hasImage
                          ? MemoryImage(
                              base64Decode(
                                profileController.profileImageBase64.value,
                              ),
                            )
                          : null,
                      child: !hasImage
                          ? Text(
                              profileController.nameController.text.isNotEmpty
                                  ? profileController.nameController.text[0]
                                        .toUpperCase()
                                  : "A",
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            )
                          : null,
                    );
                  }),
                ),
              );
            }),

            Obx(() {
              if (!currentUserCtrl.hasPermission('Profile'))
                return const SizedBox.shrink();
              return Row(
                children: [
                  const SizedBox(width: 15),
                  Container(height: 30, width: 1, color: Colors.white24),
                  const SizedBox(width: 10),
                ],
              );
            }),

            // --- Logout Icon (Hamesha visible rahega taake staff logout kar sake) ---
            _AppBarIcon(
              icon: Icons.logout_outlined,
              tooltip: "Logout",
              isLogout: true,
              onTap: () async {
                await FirebaseAuth.instance.signOut();
                // 1. Pehle screen change karo
                Get.offAll(() => const LoginScreen());

                // 2. Thora sa wait karwa ke Snackbar show karo
                Future.delayed(const Duration(milliseconds: 400), () {
                  Get.snackbar(
                    "Logged Out",
                    "See you soon!",
                    backgroundColor: Colors.green,
                    colorText: Colors.white,
                  );
                });
              },
            ),
          ],
        ),
      ),
    );
  }
}

// Helper Widget for Hover Icons
class _AppBarIcon extends StatefulWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool isLogout;
  final String tooltip;

  const _AppBarIcon({
    required this.icon,
    required this.onTap,
    this.isLogout = false,
    this.tooltip = "",
  });

  @override
  State<_AppBarIcon> createState() => _AppBarIconState();
}

class _AppBarIconState extends State<_AppBarIcon> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: Tooltip(
        message: widget.tooltip,
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _isHovered
                  ? (widget.isLogout
                        ? Colors.red.withOpacity(0.2)
                        : Colors.cyanAccent.withOpacity(0.2))
                  : Colors.transparent,
              shape: BoxShape.circle,
            ),
            child: Icon(
              widget.icon,
              color: _isHovered
                  ? (widget.isLogout ? Colors.redAccent : Colors.cyanAccent)
                  : Colors.grey.shade400,
              size: 22,
            ),
          ),
        ),
      ),
    );
  }
}
