import 'dart:convert'; // Image decode k liye
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:badges/badges.dart' as badges;
import 'package:marvellous_admin/features/profile/presentation/controllers/profile_controller.dart';

// Theme Import
import '../../../../core/theme/pallete.dart';

// Controllers Imports
import '../../../orders/presentation/controllers/orders_controller.dart'; // Orders Controller

// Screens Imports
import '../../../finance/presentation/screens/earnings_dashboard_screen.dart';
import '../../../orders/presentation/screens/orders_dashboard_screen.dart';
import '../../../profile/presentation/screens/admin_profile_screen.dart';

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
    // --- Controllers Injection ---
    // Get.put ki jagah Get.find use kar rahe hen agar pehle se loaded ho to fast hoga
    // Agar nahi to create karega.
    final profileController = Get.isRegistered<ProfileController>()
        ? Get.find<ProfileController>()
        : Get.put(ProfileController());

    final ordersController = Get.isRegistered<OrdersController>()
        ? Get.find<OrdersController>()
        : Get.put(OrdersController());

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
            // 1. Menu Icon (Mobile Only)
            if (isMobile) ...[
              IconButton(
                onPressed: onMenuPressed,
                icon: const Icon(Icons.menu, color: Colors.cyanAccent),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              const SizedBox(width: 10),
            ],

            // 2. Dynamic Page Title (User Name)
            Expanded(
              child: Center(
                // FIX: Obx ab 'isLoading' ko sun raha hai.
                // Is se Red Screen nahi ayegi aur data aate hi update hoga.
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
                      fontSize: isMobile ? 24 : 32, // Responsive Font
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                    overflow: TextOverflow.ellipsis,
                  );
                }),
              ),
            ),

            // 3. Right Side Icons

            // --- Wallet Icon (Earnings) ---
            _AppBarIcon(
              icon: Icons.account_balance_wallet_outlined,
              tooltip: "Earnings",
              onTap: () {
                Get.to(() => const EarningsDashboardScreen());
              },
            ),

            const SizedBox(width: 15),

            // --- Requests Icon (Orders) with Badge ---
            Obx(() {
              int pendingCount =
                  ordersController.pendingOrders.length +
                  ordersController.pendingRequests.length;

              return badges.Badge(
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
                  tooltip: "Pending Orders & Requests",
                  onTap: () {
                    Get.to(() => const OrdersDashboardScreen());
                  },
                ),
              );
            }),

            const SizedBox(width: 20),

            // --- Profile Image ---
            // FIX: GestureDetector ko sabse bahar rakha hai taake click miss na ho
            GestureDetector(
              behavior: HitTestBehavior.opaque, // Ensures click detection
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
            ),

            const SizedBox(width: 15),

            // --- Divider ---
            Container(height: 30, width: 1, color: Colors.white24),

            const SizedBox(width: 10),

            // --- Logout Icon ---
            _AppBarIcon(
              icon: Icons.logout_outlined,
              tooltip: "Logout",
              isLogout: true,
              onTap: () {
                Get.snackbar("Logout", "Logged out successfully (Demo)");
                // Get.offAll(() => LoginScreen()); // Real logout
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
