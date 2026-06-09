import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../controller/customer_detail_controller.dart';
import 'helper_widgets.dart';

Widget buildDirectReferralRow(
  BuildContext context,
  CustomerDetailController controller,
) {
  return Obx(() {
    double directEarnings = 0.0;
    for (var member in controller.directMembersList) {
      directEarnings += (member['amount'] as num? ?? 0).toDouble();
    }
    return buildStatRowTappable(
      "Direct Referrals",
      "${controller.directActiveCount.value} members  •  Rs. ${directEarnings.toStringAsFixed(0)}",
      Icons.people_alt,
      Colors.blue,
      onTap: () => showDirectMembersSheet(context, controller),
    );
  });
}

Widget buildOtherNetworkRow(
  BuildContext context,
  CustomerDetailController controller,
) {
  return Obx(() {
    int otherMembers = controller.otherMembersList.length;
    double otherEarnings = 0.0;
    for (var member in controller.otherMembersList) {
      otherEarnings += (member['amount'] as num? ?? 0).toDouble();
    }
    return buildStatRowTappable(
      "Other Network",
      "$otherMembers members  •  Rs. ${otherEarnings.toStringAsFixed(0)}",
      Icons.account_tree_outlined,
      Colors.teal,
      onTap: () => showOtherNetworkSheet(context, controller),
    );
  });
}

// ── DIRECT MEMBERS SHEET ──
void showDirectMembersSheet(
  BuildContext context,
  CustomerDetailController controller,
) {
  if (controller.directMembersList.isEmpty) {
    Get.snackbar(
      "No Direct Members",
      "No direct referral commission earned yet.",
      backgroundColor: Colors.orange,
      colorText: Colors.white,
    );
    return;
  }
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => DraggableScrollableSheet(
      initialChildSize: 0.65,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      builder: (_, scrollCtrl) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 14, bottom: 8),
              width: 50,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.grey.shade400,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Direct Members",
                    style: GoogleFonts.comicNeue(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: Colors.indigo,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.indigo.shade50,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.indigo.shade200),
                    ),
                    child: Text(
                      "${controller.directMembersList.length} members",
                      style: GoogleFonts.comicNeue(
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        color: Colors.indigo,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(thickness: 1.5),
            Expanded(
              child: ListView.separated(
                controller: scrollCtrl,
                padding: const EdgeInsets.all(16),
                itemCount: controller.directMembersList.length,
                separatorBuilder: (_, __) => const Divider(),
                itemBuilder: (_, idx) {
                  final member = controller.directMembersList[idx];
                  return _buildNetworkMemberTile(context, controller, member);
                },
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

// ── OTHER NETWORK SHEET (FLAT LIST) ──
void showOtherNetworkSheet(
  BuildContext context,
  CustomerDetailController controller,
) {
  if (controller.otherMembersList.isEmpty) {
    Get.snackbar(
      "No Other Network",
      "No other network members found.",
      backgroundColor: Colors.orange,
      colorText: Colors.white,
    );
    return;
  }
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => DraggableScrollableSheet(
      initialChildSize: 0.65,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      builder: (_, scrollCtrl) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 14, bottom: 8),
              width: 50,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.grey.shade400,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Other Network",
                    style: GoogleFonts.comicNeue(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: Colors.teal,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.teal.shade50,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.teal.shade200),
                    ),
                    child: Text(
                      "${controller.otherMembersList.length} members",
                      style: GoogleFonts.comicNeue(
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        color: Colors.teal.shade800,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(thickness: 1.5),
            Expanded(
              child: ListView.separated(
                controller: scrollCtrl,
                padding: const EdgeInsets.all(16),
                itemCount: controller.otherMembersList.length,
                separatorBuilder: (_, __) => const Divider(),
                itemBuilder: (_, idx) {
                  final member = controller.otherMembersList[idx];
                  return _buildNetworkMemberTile(context, controller, member);
                },
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

// Reuseable tile for both Direct and Other network lists
Widget _buildNetworkMemberTile(
  BuildContext context,
  CustomerDetailController controller,
  Map<String, dynamic> member,
) {
  return InkWell(
    borderRadius: BorderRadius.circular(12),
    onTap: () => showMemberCommissionHistory(context, controller, member),
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.indigo.shade200, width: 2),
            ),
            child: ClipOval(
              child: buildBase64Image(member['image'] as String? ?? ''),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  member['name'] as String? ?? 'User',
                  style: GoogleFonts.comicNeue(
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                    color: Colors.black87,
                  ),
                ),
                if (member['uid'] != null)
                  Text(
                    "UID: ${(member['uid'] as String).length > 8 ? (member['uid'] as String).substring(0, 8) : member['uid']}...",
                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    const Icon(Icons.touch_app, size: 12, color: Colors.indigo),
                    const SizedBox(width: 3),
                    Text(
                      "Tap to view history",
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.indigo.shade300,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                "+ Rs. ${(member['amount'] as double).toStringAsFixed(0)}",
                style: GoogleFonts.comicNeue(
                  fontWeight: FontWeight.w900,
                  color: Colors.green.shade700,
                  fontSize: 16,
                ),
              ),
              Text(
                "Level ${member['level'] ?? 1}",
                style: const TextStyle(fontSize: 11, color: Colors.black38),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}

// ── TOTAL NETWORK SUMMARY (Exactly as customer app screenshot) ──
void showLevelBreakdown(
  BuildContext context,
  CustomerDetailController controller,
) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      builder: (_, scrollCtrl) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 14, bottom: 8),
              width: 50,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.grey.shade400,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Text(
                "Network Earnings Breakdown",
                style: GoogleFonts.comicNeue(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: Colors.black,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const Divider(thickness: 1.5, height: 0),
            Expanded(
              child: Obx(() {
                if (controller.levelEarnings.isEmpty) {
                  return Center(
                    child: Text(
                      "No commission data for selected period",
                      style: GoogleFonts.comicNeue(
                        fontSize: 16,
                        color: Colors.black54,
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  controller: scrollCtrl,
                  padding: const EdgeInsets.all(16),
                  itemCount: controller.levelEarnings.length,
                  itemBuilder: (_, idx) {
                    final item = controller.levelEarnings[idx];
                    int level = item['level'];
                    int filledUsers = item['peopleCount'];
                    double totalCommission = (item['totalCommission'] as num)
                        .toDouble();

                    int requiredUsers = 1;
                    for (int i = 0; i < level; i++) {
                      requiredUsers *= 7;
                    }

                    double fillPercentage = (filledUsers / requiredUsers) * 100;
                    bool isComplete = fillPercentage >= 100;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 14),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color.fromARGB(255, 189, 232, 228),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isComplete
                              ? const Color.fromARGB(
                                  255,
                                  0,
                                  135,
                                  5,
                                ).withOpacity(0.4)
                              : Colors.grey.withOpacity(0.25),
                          width: 2.5,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color.fromARGB(
                                        255,
                                        168,
                                        0,
                                        0,
                                      ).withOpacity(0.12),
                                      borderRadius: BorderRadius.circular(9),
                                    ),
                                    child: Text(
                                      "LEVEL $level",
                                      style: GoogleFonts.comicNeue(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w900,
                                        color: const Color.fromARGB(
                                          255,
                                          0,
                                          107,
                                          7,
                                        ),
                                      ),
                                    ),
                                  ),
                                  if (isComplete) ...[
                                    const SizedBox(width: 8),
                                    const Icon(
                                      Icons.check_circle,
                                      color: Colors.green,
                                      size: 18,
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          Row(
                            children: [
                              Expanded(
                                child: _miniStatBox(
                                  "Sales",
                                  "$filledUsers/$requiredUsers",
                                  const Color.fromARGB(255, 0, 101, 5),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _miniStatBox(
                                  "Commission",
                                  "Rs.${totalCommission.toStringAsFixed(0)}",
                                  const Color.fromARGB(255, 0, 60, 121),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: LinearProgressIndicator(
                              value: (fillPercentage / 100).clamp(0.0, 1.0),
                              minHeight: 7,
                              backgroundColor: Colors.grey.shade200,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                isComplete
                                    ? const Color.fromARGB(255, 0, 100, 5)
                                    : const Color(0xFF6C63FF),
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            "${fillPercentage.toStringAsFixed(1)}% Complete",
                            style: GoogleFonts.comicNeue(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: Colors.black,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              }),
            ),
          ],
        ),
      ),
    ),
  );
}

Widget _miniStatBox(String label, String value, Color color) {
  return Container(
    padding: const EdgeInsets.all(10),
    decoration: BoxDecoration(
      color: const Color.fromARGB(255, 218, 235, 233),
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: Colors.black, width: 1.2),
      boxShadow: [
        BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 4),
      ],
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: GoogleFonts.comicNeue(
            fontSize: 18,
            fontWeight: FontWeight.w900,
            color: color,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 3),
        Text(
          label,
          style: GoogleFonts.comicNeue(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: Colors.black,
          ),
        ),
      ],
    ),
  );
}

void showMemberCommissionHistory(
  BuildContext context,
  CustomerDetailController controller,
  Map<String, dynamic> member,
) {
  final String memberUid = member['uid'] as String;
  final String memberName = member['name'] as String? ?? 'User';
  final String memberImage = member['image'] as String? ?? '';

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      builder: (_, scrollCtrl) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 14, bottom: 8),
              width: 50,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.grey.shade400,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.indigo.shade200,
                        width: 2.5,
                      ),
                    ),
                    child: ClipOval(child: buildBase64Image(memberImage)),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          memberName,
                          style: GoogleFonts.comicNeue(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            color: Colors.black,
                          ),
                        ),
                        Text(
                          "Commission History",
                          style: GoogleFonts.comicNeue(
                            fontSize: 14,
                            color: Colors.black54,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Divider(thickness: 1.5),
            Expanded(
              child: FutureBuilder<List<Map<String, dynamic>>>(
                future: controller.fetchMemberCommissionHistory(memberUid),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(color: Colors.indigo),
                    );
                  }
                  final history = snapshot.data ?? [];
                  if (history.isEmpty) {
                    return Center(
                      child: Text(
                        "No commission history from this member",
                        style: GoogleFonts.comicNeue(
                          fontSize: 16,
                          color: Colors.black54,
                        ),
                      ),
                    );
                  }
                  double totalFromMember = 0.0;
                  for (var h in history) {
                    totalFromMember += (h['amount'] as num? ?? 0).toDouble();
                  }
                  return Column(
                    children: [
                      Container(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: Colors.green.shade200),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "Total Earned from $memberName",
                              style: GoogleFonts.comicNeue(
                                fontSize: 14,
                                fontWeight: FontWeight.w900,
                                color: Colors.black87,
                              ),
                            ),
                            Text(
                              "Rs. ${totalFromMember.toStringAsFixed(0)}",
                              style: GoogleFonts.comicNeue(
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                                color: Colors.green.shade700,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: ListView.separated(
                          controller: scrollCtrl,
                          padding: const EdgeInsets.all(16),
                          itemCount: history.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 10),
                          itemBuilder: (_, i) {
                            final h = history[i];
                            final String type = h['type'] ?? '';
                            final double amt = (h['amount'] as num? ?? 0)
                                .toDouble();
                            final int level = h['level'] as int? ?? 0;
                            final DateTime? date = h['timestamp'] is DateTime
                                ? h['timestamp'] as DateTime
                                : null;
                            final String orderId =
                                h['orderId'] as String? ?? '';
                            final Color typeColor = type == 'direct_sale_bonus'
                                ? Colors.blue.shade700
                                : Colors.purple.shade700;
                            final String typeLabel = type == 'direct_sale_bonus'
                                ? 'Direct Sale Bonus'
                                : 'Level $level Commission';
                            return Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: typeColor.withOpacity(0.2),
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.04),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: typeColor.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Icon(
                                      type == 'direct_sale_bonus'
                                          ? Icons.star
                                          : Icons.account_tree,
                                      color: typeColor,
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          typeLabel,
                                          style: GoogleFonts.comicNeue(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w900,
                                            color: typeColor,
                                          ),
                                        ),
                                        if (orderId.isNotEmpty)
                                          Text(
                                            "Order: $orderId",
                                            style: const TextStyle(
                                              fontSize: 11,
                                              color: Colors.black45,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        if (date != null)
                                          Text(
                                            DateFormat(
                                              'dd MMM yyyy, hh:mm a',
                                            ).format(date),
                                            style: const TextStyle(
                                              fontSize: 11,
                                              color: Colors.black38,
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                  Text(
                                    "+ Rs. ${amt.toStringAsFixed(0)}",
                                    style: GoogleFonts.comicNeue(
                                      fontSize: 17,
                                      fontWeight: FontWeight.w900,
                                      color: Colors.green.shade700,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

void showOrderHistory(
  BuildContext context,
  CustomerDetailController controller,
) {
  // ── GRAND TOTAL POINTS CALCULATION (USING EXACT ORDER CONTROLLER LOGIC) ──
  double globalGrandTotalPoints = 0.0;
  for (var order in controller.ordersList) {
    globalGrandTotalPoints += controller.getOrderPointsData(
      order,
    )['grandTotalPoints'];
  }

  final String grandTotalPtsStr = controller.formatPoints(
    globalGrandTotalPoints,
  );

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (_, scrollCtrl) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 14, bottom: 8),
              width: 50,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.grey.shade400,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Order History",
                    style: GoogleFonts.comicNeue(
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      color: Colors.black,
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.teal.shade50,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.teal.shade300),
                        ),
                        child: Text(
                          "${controller.receiptCount.value} Orders",
                          style: GoogleFonts.comicNeue(
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                            color: Colors.teal.shade800,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.green.shade300),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.star,
                              color: Colors.green.shade700,
                              size: 14,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              "$grandTotalPtsStr Pts",
                              style: GoogleFonts.comicNeue(
                                fontSize: 14,
                                fontWeight: FontWeight.w900,
                                color: Colors.green.shade800,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Divider(thickness: 1.5),
            Expanded(
              child: controller.ordersList.isEmpty
                  ? Center(
                      child: Text(
                        "No orders in this date range",
                        style: GoogleFonts.comicNeue(
                          fontSize: 18,
                          color: Colors.black54,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    )
                  : ListView.separated(
                      controller: scrollCtrl,
                      padding: const EdgeInsets.all(16),
                      itemCount: controller.ordersList.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 14),
                      itemBuilder: (_, i) =>
                          buildOrderCard(controller.ordersList[i], controller),
                    ),
            ),
          ],
        ),
      ),
    ),
  );
}

Widget buildOrderCard(
  Map<String, dynamic> order,
  CustomerDetailController controller,
) {
  final status = order['status'] ?? 'unknown';
  final Color statusColor = status == 'delivered'
      ? Colors.green.shade700
      : status == 'rejected' || status == 'cancelled'
      ? Colors.red.shade700
      : status == 'pending'
      ? Colors.orange.shade700
      : Colors.blue.shade700;
  final double total = (order['grandTotal'] ?? order['totalAmount'] ?? 0.0)
      .toDouble();
  final DateTime? date = order['createdAt'];
  final String paymentMethod = order['paymentMethod'] ?? 'Unknown';

  final items = order['items'] as List? ?? [];

  // ── FIX: CALL POINTS LOGIC ──
  final ptsData = controller.getOrderPointsData(order);
  final String totalPtsDisplay = controller.formatPoints(
    ptsData['grandTotalPoints'],
  );
  final List<double> itemPointsList = ptsData['itemPoints'];

  return Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: Colors.grey.shade300, width: 1.5),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.04),
          blurRadius: 8,
          offset: const Offset(0, 4),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                order['orderId'] ?? order['id'] ?? 'Order',
                style: GoogleFonts.comicNeue(
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                  color: Colors.black87,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: statusColor.withOpacity(0.5)),
              ),
              child: Text(
                status.toUpperCase(),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  color: statusColor,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              date != null
                  ? DateFormat('dd MMM yyyy, hh:mm a').format(date)
                  : '',
              style: const TextStyle(fontSize: 13, color: Colors.black54),
            ),
            Text(
              "Rs. ${total.toStringAsFixed(0)}",
              style: GoogleFonts.comicNeue(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: Colors.black,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(Icons.payment, size: 16, color: Colors.grey.shade600),
                const SizedBox(width: 4),
                Text(
                  "Payment: $paymentMethod",
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.black54,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.amber.shade300),
              ),
              child: Text(
                "⭐ $totalPtsDisplay Pts",
                style: GoogleFonts.comicNeue(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Colors.amber.shade800,
                ),
              ),
            ),
          ],
        ),
        if (items.isNotEmpty) ...[
          const SizedBox(height: 12),
          const Divider(thickness: 1),
          const SizedBox(height: 8),
          ...items.asMap().entries.map((entry) {
            int idx = entry.key;
            var item = entry.value;
            String? imageBase64 = item['image'];
            double price =
                double.tryParse(
                  item['salePrice']?.toString() ??
                      item['price']?.toString() ??
                      '0',
                ) ??
                0.0;
            int qty = item['quantity'] ?? 1;

            String ptsDisplay = controller.formatPoints(itemPointsList[idx]);

            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: imageBase64 != null && imageBase64.isNotEmpty
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: buildBase64Image(imageBase64),
                          )
                        : const Icon(Icons.image, color: Colors.grey),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item['name'] ?? item['productName'] ?? 'Item',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "Qty: $qty  |  Price: Rs.${price.toStringAsFixed(0)}",
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.black54,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Icon(
                              Icons.star,
                              size: 13,
                              color: Colors.amber.shade700,
                            ),
                            const SizedBox(width: 3),
                            Text(
                              "$ptsDisplay pts",
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w900,
                                color: Colors.amber.shade800,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ],
    ),
  );
}
