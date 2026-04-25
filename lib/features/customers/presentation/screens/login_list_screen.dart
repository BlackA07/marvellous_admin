import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'login_detail_screen.dart';

class LoginListScreen extends StatefulWidget {
  const LoginListScreen({super.key});

  @override
  State<LoginListScreen> createState() => _LoginListScreenState();
}

class _LoginListScreenState extends State<LoginListScreen> {
  // 'all' | 'today' | 'week' | 'month'
  String _dateFilter = 'all';

  // 'all' | 'active' | 'inactive'
  String _statusFilter = 'all';

  // Cache to store user status so we don't fetch from DB repeatedly
  final Map<String, bool> _userStatusCache = {};

  DateTime get _filterStart {
    final now = DateTime.now();
    switch (_dateFilter) {
      case 'today':
        return DateTime(now.year, now.month, now.day);
      case 'week':
        return now.subtract(const Duration(days: 7));
      case 'month':
        return now.subtract(const Duration(days: 30));
      default:
        return DateTime(2020);
    }
  }

  // Future function to check if a user is active (isMLMActive == true)
  Future<bool> _isUserActive(String uid) async {
    if (_userStatusCache.containsKey(uid)) {
      return _userStatusCache[uid]!;
    }
    try {
      DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();
      if (doc.exists) {
        bool isActive =
            (doc.data() as Map<String, dynamic>)['isMLMActive'] ?? false;
        _userStatusCache[uid] = isActive;
        return isActive;
      }
    } catch (_) {}
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      appBar: AppBar(
        title: Text(
          "User Login History",
          style: GoogleFonts.comicNeue(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Column(
        children: [
          // ── Date Filter Chips ────────────────────────────────────────
          Container(
            width: double.infinity,
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 5),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _dateChip('all', 'All Time', Icons.history),
                  const SizedBox(width: 8),
                  _dateChip('today', 'Today', Icons.today),
                  const SizedBox(width: 8),
                  _dateChip('week', 'This Week', Icons.date_range),
                  const SizedBox(width: 8),
                  _dateChip('month', 'This Month', Icons.calendar_month),
                ],
              ),
            ),
          ),

          // ── Status Filter Chips (NEW) ────────────────────────────────
          Container(
            width: double.infinity,
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _statusChip(
                    'all',
                    'All Users',
                    Icons.people,
                    Colors.blueGrey,
                  ),
                  const SizedBox(width: 8),
                  _statusChip(
                    'active',
                    'Active Users',
                    Icons.check_circle,
                    Colors.green.shade700,
                  ),
                  const SizedBox(width: 8),
                  _statusChip(
                    'inactive',
                    'Inactive Users',
                    Icons.cancel,
                    Colors.red.shade700,
                  ),
                ],
              ),
            ),
          ),
          const Divider(height: 1, color: Colors.black12, thickness: 1.5),

          // ── Login list ───────────────────────────────────────────────
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('login_logs')
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      "Error: ${snapshot.error}",
                      style: const TextStyle(color: Colors.red),
                    ),
                  );
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: Colors.black),
                  );
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Text(
                      "No login records found.",
                      style: GoogleFonts.comicNeue(
                        fontSize: 18,
                        color: Colors.black87,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  );
                }

                // Initial Date Filter
                final filterStart = _filterStart;
                var allLogs = snapshot.data!.docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final Timestamp? ts = data['timestamp'] as Timestamp?;
                  if (ts == null) return false;
                  return ts.toDate().isAfter(filterStart);
                }).toList();

                if (allLogs.isEmpty) {
                  return Center(
                    child: Text(
                      "No logins in selected period.",
                      style: GoogleFonts.comicNeue(
                        fontSize: 17,
                        color: Colors.black54,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(15),
                  itemCount: allLogs.length,
                  itemBuilder: (context, index) {
                    final data = allLogs[index].data() as Map<String, dynamic>;
                    final docId = allLogs[index].id;
                    final String userId = data['userId'] ?? '';
                    final String userName = data['userName'] ?? 'Unknown';
                    final String userEmail = data['userEmail'] ?? '';
                    final String userPhone = data['userPhone'] ?? '';
                    final Timestamp? ts = data['timestamp'] as Timestamp?;
                    final DateTime loginTime = ts != null
                        ? ts.toDate()
                        : DateTime.now();
                    final String ip = data['ipAddress'] ?? 'N/A';
                    final String device =
                        data['deviceInfo'] ?? 'Unknown device';

                    // Use FutureBuilder to check Active/Inactive status per user
                    return FutureBuilder<bool>(
                      future: _isUserActive(userId),
                      builder: (context, statusSnapshot) {
                        if (statusSnapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const SizedBox(); // Hide while loading to avoid flicker
                        }

                        bool isActive = statusSnapshot.data ?? false;

                        // Apply Status Filter
                        if (_statusFilter == 'active' && !isActive)
                          return const SizedBox();
                        if (_statusFilter == 'inactive' && isActive)
                          return const SizedBox();

                        return _buildLoginCard(
                          docId: docId,
                          userId: userId,
                          userName: userName,
                          userEmail: userEmail,
                          userPhone: userPhone,
                          loginTime: loginTime,
                          ip: ip,
                          device: device,
                          isActive: isActive, // ✅ Pass Active status to UI
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _dateChip(String value, String label, IconData icon) {
    final bool selected = _dateFilter == value;
    return GestureDetector(
      onTap: () => setState(() => _dateFilter = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: selected ? Colors.indigo : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? Colors.indigo : Colors.grey.shade400,
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: selected ? Colors.white : Colors.black54,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.comicNeue(
                fontSize: 14,
                fontWeight: FontWeight.w900,
                color: selected ? Colors.white : Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statusChip(String value, String label, IconData icon, Color color) {
    final bool selected = _statusFilter == value;
    return GestureDetector(
      onTap: () => setState(() => _statusFilter = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? color : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color, width: 1.5),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: color.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ]
              : [],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: selected ? Colors.white : color),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.comicNeue(
                fontSize: 13,
                fontWeight: FontWeight.w900,
                color: selected ? Colors.white : color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoginCard({
    required String docId,
    required String userId,
    required String userName,
    required String userEmail,
    required String userPhone,
    required DateTime loginTime,
    required String ip,
    required String device,
    required bool isActive, // ✅ NEW: Colors change based on this
  }) {
    // UI Colors based on Active/Inactive (Similar to Customers List)
    final Color cardBorder = isActive
        ? Colors.green.shade400
        : Colors.red.shade300;
    final Color cardBg = isActive ? Colors.white : const Color(0xFFFFF8F8);
    final Color avatarBg = isActive
        ? Colors.green.shade100
        : Colors.grey.shade200;
    final Color iconColor = isActive
        ? Colors.green.shade700
        : Colors.grey.shade600;

    final String timeAgo = _timeAgo(loginTime);

    return GestureDetector(
      onTap: () => Get.to(
        () => LoginDetailScreen(
          logId: docId,
          userId: userId,
          userName: userName,
          userEmail: userEmail,
          userPhone: userPhone,
          loginTime: loginTime,
          ipAddress: ip,
          deviceInfo: device,
        ),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: cardBorder, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            // Avatar
            CircleAvatar(
              radius: 26,
              backgroundColor: avatarBg,
              child: Icon(Icons.person, color: iconColor, size: 28),
            ),
            const SizedBox(width: 14),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          userName,
                          style: GoogleFonts.comicNeue(
                            fontWeight: FontWeight.w900,
                            fontSize: 17,
                            color: Colors.black,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      // Active/Inactive Pill
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: isActive
                              ? Colors.green.shade50
                              : Colors.red.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isActive
                                ? Colors.green.shade400
                                : Colors.red.shade400,
                            width: 1,
                          ),
                        ),
                        child: Text(
                          isActive ? "Active" : "Inactive",
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                            color: isActive
                                ? Colors.green.shade700
                                : Colors.red.shade700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    userEmail,
                    style: GoogleFonts.comicNeue(
                      fontSize: 14,
                      color: Colors.black87,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      const Icon(
                        Icons.access_time,
                        size: 13,
                        color: Colors.black54,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        DateFormat('dd MMM yyyy, hh:mm a').format(loginTime),
                        style: GoogleFonts.comicNeue(
                          fontSize: 13,
                          color: Colors.black54,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      const Icon(
                        Icons.timer_outlined,
                        size: 12,
                        color: Colors.black38,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        timeAgo,
                        style: GoogleFonts.comicNeue(
                          fontSize: 12,
                          color: Colors.black38,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right, color: Colors.black38, size: 22),
          ],
        ),
      ),
    );
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return "Just now";
    if (diff.inMinutes < 60) return "${diff.inMinutes}m ago";
    if (diff.inHours < 24) return "${diff.inHours}h ago";
    if (diff.inDays < 7) return "${diff.inDays}d ago";
    if (diff.inDays < 30) return "${(diff.inDays / 7).floor()}w ago";
    return "${(diff.inDays / 30).floor()}mo ago";
  }
}
