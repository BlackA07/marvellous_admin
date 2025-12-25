import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:badges/badges.dart' as badges;

// Theme import (Apne project k hisaab se path adjust karlena)
import '../../../../core/theme/pallete.dart';

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
    // SafeArea lagaya taake phone ke notch se bache
    return SafeArea(
      bottom: false, // Neeche se safe area nahi chahiye
      child: Container(
        height: 70,
        padding: const EdgeInsets.symmetric(
          horizontal: 15,
        ), // Padding thori kam ki
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
            // 1. Menu Icon (Left Side) - Sirf Mobile pe dikhega
            if (isMobile) ...[
              IconButton(
                onPressed: onMenuPressed,
                icon: const Icon(Icons.menu, color: Colors.cyanAccent),
                padding: EdgeInsets.zero, // Padding remove ki taake space bache
                constraints: const BoxConstraints(),
              ),
              const SizedBox(width: 10),
            ],

            // 2. Page Title (CENTERED & BIGGER)
            Expanded(
              child: Center(
                child: Text(
                  "Arslan",
                  style: GoogleFonts.comicNeue(
                    color: Colors.white,
                    fontSize: isMobile ? 24 : 32, // Mobile pe thora chota
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                  overflow: TextOverflow.ellipsis, // Agar naam bohot bada ho
                ),
              ),
            ),

            // 3. Right Side Icons
            _AppBarIcon(
              icon: Icons.account_balance_wallet_outlined,
              onTap: () {},
            ),

            const SizedBox(width: 10), // Gap thora kam kiya

            badges.Badge(
              badgeContent: const Text(
                '3',
                style: TextStyle(color: Colors.white, fontSize: 10),
              ),
              badgeStyle: const badges.BadgeStyle(
                badgeColor: Colors.purpleAccent,
              ),
              position: badges.BadgePosition.topEnd(top: -5, end: -2),
              child: _AppBarIcon(
                icon: Icons.assignment_late_outlined,
                onTap: () {},
              ),
            ),

            const SizedBox(width: 10),

            badges.Badge(
              showBadge: true,
              position: badges.BadgePosition.topEnd(top: 0, end: 0),
              badgeStyle: const badges.BadgeStyle(badgeColor: Colors.redAccent),
              child: _AppBarIcon(
                icon: Icons.notifications_none_outlined,
                onTap: () {},
              ),
            ),

            const SizedBox(width: 15),

            // Profile Circle
            Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.cyanAccent),
              ),
              child: const CircleAvatar(
                radius: 16, // Size fix kiya
                backgroundColor: Colors.purpleAccent,
                child: Text("A", style: TextStyle(fontSize: 14)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Helper Widget for Hover Effect on Icons
class _AppBarIcon extends StatefulWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _AppBarIcon({required this.icon, required this.onTap});

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
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: _isHovered
                ? Colors.cyanAccent.withOpacity(0.2)
                : Colors.transparent,
            shape: BoxShape.circle,
          ),
          child: Icon(
            widget.icon,
            color: _isHovered ? Colors.cyanAccent : Colors.grey.shade400,
            size: 22, // Icon size adjust kiya
          ),
        ),
      ),
    );
  }
}
