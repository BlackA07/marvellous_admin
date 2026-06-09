import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../components/customer_bottom_sheets.dart';
import '../../components/customer_dialogs.dart';
import '../../components/helper_widgets.dart';
import '../../components/mlm_tree_components.dart';
import '../../controller/customer_detail_controller.dart';

class CustomerDetailScreen extends StatelessWidget {
  final String uid;
  const CustomerDetailScreen({super.key, required this.uid});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(CustomerDetailController(uid: uid), tag: uid);

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      appBar: AppBar(
        title: Text(
          "User Profile",
          style: GoogleFonts.comicNeue(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 26,
          ),
        ),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.black),
        elevation: 1,
        actions: [
          IconButton(
            icon: const Icon(Icons.message, color: Colors.indigo),
            onPressed: () => showSendMessageDialog(context, controller),
          ),
          IconButton(
            icon: const Icon(Icons.account_balance_wallet, color: Colors.green),
            onPressed: () => showAdjustWalletDialog(context, controller),
          ),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value)
          return const Center(
            child: CircularProgressIndicator(color: Colors.black),
          );
        if (controller.customer.value == null)
          return const Center(child: Text("User not found"));

        final customer = controller.customer.value!;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(15),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── PROFILE HEADER ──────────────────────────────────────
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GestureDetector(
                      onTap: () =>
                          showFullImageDialog(context, customer.faceImage),
                      child: Container(
                        height: 140,
                        width: 140,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.indigo.shade200,
                            width: 4,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.indigo.withOpacity(0.15),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ClipOval(
                          child: _buildSmartImage(customer.faceImage),
                        ),
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            customer.name,
                            style: GoogleFonts.comicNeue(
                              fontSize: 26,
                              fontWeight: FontWeight.w900,
                              color: Colors.black,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            customer.email,
                            style: GoogleFonts.comicNeue(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 4),
                          GestureDetector(
                            onTap: () {
                              Clipboard.setData(
                                ClipboardData(text: customer.phone),
                              );
                              Get.snackbar(
                                "Copied",
                                "Phone number copied",
                                snackPosition: SnackPosition.BOTTOM,
                                backgroundColor: Colors.black,
                                colorText: Colors.white,
                              );
                            },
                            child: Row(
                              children: [
                                Text(
                                  customer.phone,
                                  style: GoogleFonts.comicNeue(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.blue.shade700,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Icon(
                                  Icons.copy,
                                  size: 16,
                                  color: Colors.blue.shade700,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),
                          buildInfoRowCopyable(
                            "My Referral Code",
                            customer.myReferralCode,
                            Icons.code,
                          ),
                          const SizedBox(height: 6),
                          buildInfoRowCopyable(
                            "Upline Code",
                            controller.uplineCode.value,
                            Icons.arrow_upward,
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Expanded(
                                child: buildInfoRowIcon(
                                  "Direct",
                                  "${controller.directActiveCount.value} active",
                                  Icons.people,
                                  Colors.blue.shade700,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Expanded(
                                child: buildInfoRowIcon(
                                  "Total Network",
                                  "${controller.totalActiveCount.value} active",
                                  Icons.account_tree,
                                  Colors.teal,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              buildInfoRowCompact(
                                "Membership",
                                controller.membershipStatus.value.toUpperCase(),
                                Icons.verified,
                                controller.membershipStatus.value == 'approved'
                                    ? Colors.green
                                    : Colors.orange,
                              ),
                              buildInfoRowCompact(
                                "Paid Fee",
                                controller.paidStatus.value,
                                Icons.payment,
                                controller.paidStatus.value == "Paid"
                                    ? Colors.green
                                    : Colors.red,
                              ),
                            ],
                          ),
                          if (controller.remainingFee.value > 0)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                "Remaining Fee: Rs. ${controller.remainingFee.value.toStringAsFixed(0)}",
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.red,
                                ),
                              ),
                            ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              buildBadge(
                                "Rank: ${customer.rank}",
                                Colors.amber.shade900,
                                Colors.amber.shade100,
                              ),
                              buildBadge(
                                "${customer.totalPoints.toStringAsFixed(0)} Pts",
                                Colors.green.shade900,
                                Colors.green.shade100,
                              ),
                              buildBadge(
                                customer.isMLMActive ? "MLM Active" : "MLM Off",
                                customer.isMLMActive
                                    ? Colors.green.shade900
                                    : Colors.red.shade900,
                                customer.isMLMActive
                                    ? Colors.green.shade50
                                    : Colors.red.shade50,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // ── DATE RANGE FILTER ───────────────────────────────────
              Obx(
                () => Row(
                  children: [
                    Expanded(
                      child: buildDatePickerBtn(
                        "Start Date",
                        controller.startDate.value,
                        context,
                        (d) {
                          controller.startDate.value = d;
                          controller.isAllTime.value = false;
                          controller.fetchStatsForDateRange();
                          controller.fetchLevelEarnings();
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: buildDatePickerBtn(
                        "End Date",
                        controller.endDate.value,
                        context,
                        (d) {
                          controller.endDate.value = d;
                          controller.isAllTime.value = false;
                          controller.fetchStatsForDateRange();
                          controller.fetchLevelEarnings();
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () => controller.setAllTime(),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: controller.isAllTime.value
                              ? Colors.indigo
                              : Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: Colors.indigo.shade300,
                            width: 1.5,
                          ),
                        ),
                        child: Text(
                          "ALL",
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 14,
                            color: controller.isAllTime.value
                                ? Colors.white
                                : Colors.indigo,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // ── STATS ROWS ──────────────────────────────────────────
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    buildStatRow(
                      "Own Sale",
                      "Rs. ${controller.ownSaleAmount.value.toStringAsFixed(0)}",
                      Icons.shopping_bag,
                      Colors.indigo,
                      isFirst: true,
                    ),
                    buildDivider(),
                    buildStatRowTappable(
                      "Receipts (${controller.receiptCount.value})",
                      "View All →",
                      Icons.receipt_long,
                      Colors.teal,
                      onTap: () => showOrderHistory(context, controller),
                    ),
                    buildDivider(),
                    buildStatRowTappable(
                      "Total Network",
                      "${controller.totalActiveCount.value} members  •  Rs. ${controller.allLevelEarnings.value.toStringAsFixed(0)}",
                      Icons.account_tree,
                      Colors.purple,
                      onTap: () => showLevelBreakdown(context, controller),
                    ),
                    buildDivider(),
                    buildDirectReferralRow(context, controller),
                    buildDivider(),
                    buildOtherNetworkRow(context, controller),
                    buildDivider(),
                    buildStatRow(
                      "Total Earnings",
                      "Rs. ${(controller.allLevelEarnings.value + customer.totalCashbackEarned).toStringAsFixed(0)}",
                      Icons.monetization_on,
                      Colors.orange.shade800,
                    ),
                    buildDivider(),
                    buildStatRow(
                      "Cashback Earned",
                      "Rs. ${customer.totalCashbackEarned.toStringAsFixed(0)}",
                      Icons.cached,
                      Colors.blue.shade800,
                    ),
                    buildDivider(),
                    buildStatRow(
                      "Withdrawn",
                      "Rs. ${controller.totalWithdrawn.value.toStringAsFixed(0)}",
                      Icons.arrow_downward,
                      Colors.red.shade800,
                      isLast: true,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // ── WALLET & ADDRESS CARD ────────────────────────────────
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    buildInfoRowIcon(
                      "Available Wallet",
                      "Rs. ${customer.walletBalance.toStringAsFixed(0)}",
                      Icons.account_balance_wallet,
                      Colors.green.shade800,
                    ),
                    const Divider(height: 28),
                    buildInfoRowIcon(
                      "Shopping Wallet",
                      "Rs. ${customer.shoppingWalletBalance.toStringAsFixed(0)}",
                      Icons.shopping_cart,
                      Colors.blue.shade800,
                    ),
                    const Divider(height: 28),
                    buildInfoRowMultiLine(
                      "Address",
                      customer.address.isEmpty || customer.address == "N/A"
                          ? "Not provided"
                          : customer.address,
                      Icons.location_on,
                      Colors.black87,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),

              // ── MLM TREE ────────────────────────────────────────────
              if (controller.mlmTree.value != null) ...[
                Text(
                  "Network Downline Tree",
                  style: GoogleFonts.comicNeue(
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 16,
                  runSpacing: 8,
                  children: [
                    buildLegendItem(Colors.indigo.shade400, "You (Root)"),
                    buildLegendItem(Colors.green.shade600, "Direct [D]"),
                    buildLegendItem(Colors.purple.shade500, "Overflow [OF]"),
                    buildLegendItem(Colors.blueGrey, "Network"),
                  ],
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.blue.shade100),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 16,
                        color: Colors.blue.shade700,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          "[D] = Direct referral via your code   [OF] = Overflow (placed from upline)",
                          style: GoogleFonts.comicNeue(
                            fontSize: 12,
                            color: Colors.blue.shade800,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.touch_app_outlined,
                        size: 14,
                        color: Colors.black54,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        "Pinch to zoom  •  Drag to pan  •  Tap node to view profile",
                        style: GoogleFonts.comicNeue(
                          fontSize: 12,
                          color: Colors.black54,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                Stack(
                  children: [
                    AdminTreeViewport(node: controller.mlmTree.value!),
                    Positioned(
                      top: 10,
                      right: 10,
                      child: GestureDetector(
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => FullscreenTreePage(
                              node: controller.mlmTree.value!,
                            ),
                          ),
                        ),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.15),
                                blurRadius: 6,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.fullscreen,
                            size: 22,
                            color: Colors.indigo,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        );
      }),
    );
  }

  // ✅ SMART IMAGE BUILDER FOR DETAIL SCREEN
  Widget _buildSmartImage(String imageData) {
    if (imageData.trim().isEmpty) {
      return const Icon(Icons.person, color: Colors.black26, size: 60);
    }
    try {
      String cleanData = imageData.trim();
      if (cleanData.startsWith('http')) {
        return Image.network(
          cleanData,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) =>
              const Icon(Icons.person, color: Colors.black26, size: 60),
        );
      } else {
        if (cleanData.contains(',')) cleanData = cleanData.split(',').last;
        cleanData = cleanData.replaceAll(RegExp(r'\s+'), '');
        return Image.memory(
          base64Decode(cleanData),
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) =>
              const Icon(Icons.person, color: Colors.black26, size: 60),
        );
      }
    } catch (_) {
      return const Icon(Icons.person, color: Colors.black26, size: 60);
    }
  }
}
