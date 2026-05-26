import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../../../mlm/data/models/mlm_models.dart';
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
            onPressed: () => _sendMessageDialog(context, controller),
          ),
          IconButton(
            icon: const Icon(Icons.account_balance_wallet, color: Colors.green),
            onPressed: () => _adjustWalletDialog(context, controller),
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
                    Container(
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
                        child: _buildBase64Image(customer.faceImage),
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
                          _infoRowCopyable(
                            "My Referral Code",
                            customer.myReferralCode,
                            Icons.code,
                          ),
                          const SizedBox(height: 6),
                          _infoRowCopyable(
                            "Upline Code",
                            controller.uplineCode.value,
                            Icons.arrow_upward,
                          ),
                          const SizedBox(height: 6),

                          // ── Direct Active + Total Active ──────────────
                          Row(
                            children: [
                              Expanded(
                                child: _infoRowIcon(
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
                                child: _infoRowIcon(
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
                              _infoRowCompact(
                                "Membership",
                                controller.membershipStatus.value.toUpperCase(),
                                Icons.verified,
                                controller.membershipStatus.value == 'approved'
                                    ? Colors.green
                                    : Colors.orange,
                              ),
                              _infoRowCompact(
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
                              _badge(
                                "Rank: ${customer.rank}",
                                Colors.amber.shade900,
                                Colors.amber.shade100,
                              ),
                              _badge(
                                "${customer.totalPoints.toStringAsFixed(0)} Pts",
                                Colors.green.shade900,
                                Colors.green.shade100,
                              ),
                              _badge(
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
              Row(
                children: [
                  Expanded(
                    child: _datePickerBtn(
                      "Start Date",
                      controller.startDate.value,
                      context,
                      (d) {
                        controller.startDate.value = d;
                        controller.fetchStatsForDateRange();
                        controller.fetchLevelEarnings();
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _datePickerBtn(
                      "End Date",
                      controller.endDate.value,
                      context,
                      (d) {
                        controller.endDate.value = d;
                        controller.fetchStatsForDateRange();
                        controller.fetchLevelEarnings();
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // ── STATS ROWS (updated) ──────────────────────────────────────────
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
                    _statRow(
                      "Own Sale",
                      "Rs. ${controller.ownSaleAmount.value.toStringAsFixed(0)}",
                      Icons.shopping_bag,
                      Colors.indigo,
                      isFirst: true,
                    ),
                    _divider(),
                    _statRowTappable(
                      "Receipts (${controller.receiptCount.value})",
                      "View All →",
                      Icons.receipt_long,
                      Colors.teal,
                      onTap: () => _showOrderHistory(context, controller),
                    ),
                    _divider(),

                    // --- NEW: Total Network (members + total earnings) ---
                    _statRowTappable(
                      "Total Network",
                      "${controller.totalActiveCount.value} members  •  Rs. ${controller.allLevelEarnings.value.toStringAsFixed(0)}",
                      Icons.account_tree,
                      Colors.purple,
                      onTap: () => _showLevelBreakdown(context, controller),
                    ),
                    _divider(),

                    // --- Direct Referrals (members + level‑1 commission) ---
                    _buildDirectReferralRow(controller),
                    _divider(),

                    // --- Other Network (remaining members + commission from levels ≥2) ---
                    _buildOtherNetworkRow(controller),
                    _divider(),

                    _statRow(
                      "Total Earnings",
                      "Rs. ${(controller.allLevelEarnings.value + customer.totalCashbackEarned).toStringAsFixed(0)}",
                      Icons.monetization_on,
                      Colors.orange.shade800,
                    ),
                    _divider(),
                    _statRow(
                      "Cashback Earned",
                      "Rs. ${customer.totalCashbackEarned.toStringAsFixed(0)}",
                      Icons.cached,
                      Colors.blue.shade800,
                    ),
                    _divider(),
                    _statRow(
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
                    _infoRowIcon(
                      "Available Wallet",
                      "Rs. ${customer.walletBalance.toStringAsFixed(0)}",
                      Icons.account_balance_wallet,
                      Colors.green.shade800,
                    ),
                    const Divider(height: 28),
                    _infoRowIcon(
                      "Shopping Wallet",
                      "Rs. ${customer.shoppingWalletBalance.toStringAsFixed(0)}",
                      Icons.shopping_cart,
                      Colors.blue.shade800,
                    ),
                    const Divider(height: 28),
                    _infoRowMultiLine(
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

                // Legend
                Wrap(
                  spacing: 16,
                  runSpacing: 8,
                  children: [
                    _legendItem(Colors.indigo.shade400, "You (Root)"),
                    _legendItem(Colors.green.shade600, "Direct [D]"),
                    _legendItem(Colors.purple.shade500, "Overflow [OF]"),
                    _legendItem(Colors.blueGrey, "Network"),
                  ],
                ),
                const SizedBox(height: 8),

                // Badge legend
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
                          "[D] = Direct referral via your code   "
                          "[OF] = Overflow (placed from upline)",
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

                // Tree viewport
                _AdminTreeViewport(node: controller.mlmTree.value!),
              ],
            ],
          ),
        );
      }),
    );
  }

  Widget _buildDirectReferralRow(CustomerDetailController controller) {
    return Obx(() {
      // Find level‑1 commission from levelEarnings list
      double directEarnings = 0.0;
      for (var item in controller.levelEarnings) {
        if (item['level'] == 1) {
          directEarnings = (item['totalCommission'] as num).toDouble();
          break;
        }
      }
      return _statRow(
        "Direct Referrals",
        "${controller.directActiveCount.value} members  •  Rs. ${directEarnings.toStringAsFixed(0)}",
        Icons.people_alt,
        Colors.blue,
      );
    });
  }

  Widget _buildOtherNetworkRow(CustomerDetailController controller) {
    return Obx(() {
      int otherMembers =
          controller.totalActiveCount.value -
          controller.directActiveCount.value;
      double directEarnings = 0.0;
      for (var item in controller.levelEarnings) {
        if (item['level'] == 1) {
          directEarnings = (item['totalCommission'] as num).toDouble();
          break;
        }
      }
      double otherEarnings = controller.allLevelEarnings.value - directEarnings;
      return _statRow(
        "Other Network",
        "$otherMembers members  •  Rs. ${otherEarnings.toStringAsFixed(0)}",
        Icons.account_tree_outlined,
        Colors.teal,
      );
    });
  }

  Widget _legendItem(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(shape: BoxShape.circle, color: color),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }

  // ── LEVEL BREAKDOWN ───────────────────────────────────────────────────
  void _showLevelBreakdown(
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
        maxChildSize: 0.9,
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
                ),
              ),
              const Divider(thickness: 1.5),
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
                  return ListView.separated(
                    controller: scrollCtrl,
                    padding: const EdgeInsets.all(16),
                    itemCount: controller.levelEarnings.length,
                    separatorBuilder: (_, __) => const Divider(),
                    itemBuilder: (_, idx) {
                      final item = controller.levelEarnings[idx];
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          children: [
                            Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                color: Colors.purple.shade100,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Center(
                                child: Text(
                                  "Lv${item['level']}",
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.purple.shade800,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "People: ${item['peopleCount']}",
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  Text(
                                    "Total Commission: Rs. ${(item['totalCommission'] as double).toStringAsFixed(0)}",
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.green,
                                    ),
                                  ),
                                ],
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

  // ── ORDER HISTORY ────────────────────────────────────────────────────
  void _showOrderHistory(
    BuildContext context,
    CustomerDetailController controller,
  ) {
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
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
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.teal.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.teal.shade300),
                      ),
                      child: Text(
                        "${controller.receiptCount.value} Orders",
                        style: GoogleFonts.comicNeue(
                          fontSize: 15,
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
                            _orderCard(controller.ordersList[i]),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _orderCard(Map<String, dynamic> order) {
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
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
          if (order['items'] != null &&
              (order['items'] as List).isNotEmpty) ...[
            const SizedBox(height: 12),
            const Divider(thickness: 1),
            const SizedBox(height: 8),
            ...((order['items'] as List).map((item) {
              String? imageBase64 = item['image'];
              double price = (item['price'] ?? 0).toDouble();
              int qty = item['quantity'] ?? 1;
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
                              child: _buildBase64Image(imageBase64),
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
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }).toList()),
          ],
        ],
      ),
    );
  }

  // ── HELPERS ───────────────────────────────────────────────────────────
  Widget _divider() => const Divider(height: 1, indent: 16, endIndent: 16);

  Widget _infoRowCopyable(String label, String value, IconData icon) {
    return GestureDetector(
      onTap: () {
        Clipboard.setData(ClipboardData(text: value));
        Get.snackbar(
          "Copied",
          "$label copied",
          snackPosition: SnackPosition.BOTTOM,
        );
      },
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey.shade700),
          const SizedBox(width: 6),
          Text(
            "$label: ",
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w900,
                color: Colors.black,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const Icon(Icons.copy, size: 14, color: Colors.blue),
        ],
      ),
    );
  }

  Widget _infoRowIcon(
    String label,
    String value,
    IconData icon,
    Color valueColor,
  ) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey.shade700),
        const SizedBox(width: 8),
        Text(
          "$label: ",
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w900,
              color: valueColor,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _infoRowCompact(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Row(
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        Text(
          "$label: ",
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w900,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _infoRowMultiLine(
    String label,
    String value,
    IconData icon,
    Color valueColor,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: Colors.grey.shade700),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                color: Colors.black87,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w900,
            color: valueColor,
          ),
        ),
      ],
    );
  }

  Widget _statRow(
    String title,
    String value,
    IconData icon,
    Color color, {
    bool isFirst = false,
    bool isLast = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: isFirst ? const Radius.circular(20) : Radius.zero,
          topRight: isFirst ? const Radius.circular(20) : Radius.zero,
          bottomLeft: isLast ? const Radius.circular(20) : Radius.zero,
          bottomRight: isLast ? const Radius.circular(20) : Radius.zero,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              title,
              style: GoogleFonts.comicNeue(
                fontSize: 17,
                fontWeight: FontWeight.w900,
                color: Colors.black87,
              ),
            ),
          ),
          Text(
            value,
            style: GoogleFonts.comicNeue(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  Widget _statRowTappable(
    String title,
    String value,
    IconData icon,
    Color color, {
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.comicNeue(
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                  color: Colors.black87,
                ),
              ),
            ),
            Text(
              value,
              style: GoogleFonts.comicNeue(
                fontSize: 17,
                fontWeight: FontWeight.w900,
                color: color,
              ),
            ),
            const SizedBox(width: 4),
            Icon(Icons.chevron_right, color: Colors.grey.shade500, size: 24),
          ],
        ),
      ),
    );
  }

  Widget _badge(String text, Color textColor, Color bgColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: textColor.withOpacity(0.6), width: 1.5),
      ),
      child: Text(
        text,
        style: GoogleFonts.comicNeue(
          fontWeight: FontWeight.w900,
          color: textColor,
          fontSize: 13,
        ),
      ),
    );
  }

  // NAYA — yeh lagao
  Widget _buildBase64Image(String imageData) {
    if (imageData.startsWith('http')) {
      return Image.network(
        imageData,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) =>
            const Icon(Icons.person, color: Colors.grey, size: 80),
      );
    }
    if (imageData.isNotEmpty) {
      try {
        final clean = imageData.contains(',')
            ? imageData.split(',').last
            : imageData;
        return Image.memory(
          base64Decode(clean),
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) =>
              const Icon(Icons.person, color: Colors.grey, size: 80),
        );
      } catch (_) {}
    }
    return const Icon(Icons.person, color: Colors.grey, size: 80);
  }

  Widget _datePickerBtn(
    String label,
    DateTime date,
    BuildContext context,
    Function(DateTime) onPicked,
  ) {
    return InkWell(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: date,
          firstDate: DateTime(2020),
          lastDate: DateTime(2100),
        );
        if (picked != null) onPicked(picked);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.grey.shade300, width: 1.5),
        ),
        child: Row(
          children: [
            Icon(Icons.calendar_month, color: Colors.grey.shade700, size: 22),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Colors.black54,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  DateFormat('dd MMM, yy').format(date),
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 14,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _adjustWalletDialog(
    BuildContext context,
    CustomerDetailController controller,
  ) {
    final amtCtrl = TextEditingController();
    final reasonCtrl = TextEditingController();
    bool isDeduction = false;

    Get.dialog(
      StatefulBuilder(
        builder: (context, setState) => Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(width: 2),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "Adjust Wallet",
                  style: GoogleFonts.comicNeue(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 15),
                Row(
                  children: [
                    Expanded(
                      child: RadioListTile(
                        title: const Text("Add"),
                        value: false,
                        groupValue: isDeduction,
                        activeColor: Colors.black,
                        onChanged: (v) =>
                            setState(() => isDeduction = v as bool),
                      ),
                    ),
                    Expanded(
                      child: RadioListTile(
                        title: const Text("Deduct"),
                        value: true,
                        groupValue: isDeduction,
                        activeColor: Colors.black,
                        onChanged: (v) =>
                            setState(() => isDeduction = v as bool),
                      ),
                    ),
                  ],
                ),
                TextField(
                  controller: amtCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: "Amount",
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: reasonCtrl,
                  decoration: const InputDecoration(
                    labelText: "Reason",
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isDeduction ? Colors.red : Colors.green,
                    minimumSize: const Size(double.infinity, 50),
                  ),
                  onPressed: () {
                    double amt = double.tryParse(amtCtrl.text) ?? 0;
                    if (amt > 0 && reasonCtrl.text.isNotEmpty)
                      controller.adjustWallet(
                        amt,
                        reasonCtrl.text,
                        isDeduction,
                      );
                  },
                  child: const Text(
                    "SUBMIT",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _sendMessageDialog(
    BuildContext context,
    CustomerDetailController controller,
  ) {
    final titleCtrl = TextEditingController();
    final bodyCtrl = TextEditingController();
    String? selectedImageBase64;

    Get.dialog(
      StatefulBuilder(
        builder: (context, setState) => Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(width: 2),
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "Send Message",
                  style: GoogleFonts.comicNeue(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 15),
                TextField(
                  controller: titleCtrl,
                  decoration: const InputDecoration(
                    labelText: "Title",
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: bodyCtrl,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: "Message",
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 15),
                selectedImageBase64 != null
                    ? Stack(
                        alignment: Alignment.topRight,
                        children: [
                          Container(
                            height: 120,
                            width: 120,
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Image.memory(
                              base64Decode(selectedImageBase64!),
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) =>
                                  const Icon(Icons.broken_image),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, color: Colors.red),
                            onPressed: () =>
                                setState(() => selectedImageBase64 = null),
                          ),
                        ],
                      )
                    : OutlinedButton.icon(
                        icon: const Icon(Icons.image, color: Colors.black),
                        label: const Text(
                          "Add Image",
                          style: TextStyle(color: Colors.black),
                        ),
                        onPressed: () async {
                          final picker = ImagePicker();
                          final XFile? xfile = await picker.pickImage(
                            source: ImageSource.gallery,
                            imageQuality: 50,
                          );
                          if (xfile != null) {
                            final bytes = await xfile.readAsBytes();
                            final String base64String = base64Encode(bytes);
                            setState(() => selectedImageBase64 = base64String);
                          }
                        },
                      ),
                const SizedBox(height: 20),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.indigo,
                    minimumSize: const Size(double.infinity, 50),
                  ),
                  onPressed: () {
                    if (titleCtrl.text.isNotEmpty) {
                      controller.sendDirectMessage(
                        titleCtrl.text,
                        bodyCtrl.text,
                        selectedImageBase64 ?? '',
                      );
                    }
                  },
                  child: const Text(
                    "SEND",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
//  ADMIN TREE VIEWPORT
//  - Full InteractiveViewer with unlimited zoom/pan
//  - Prevents parent ListView scroll conflict via Listener
//  - No level limit — shows entire downline tree
// ════════════════════════════════════════════════════════════════════════════
// ════════════════════════════════════════════════════════════════════════════
//  ADMIN TREE VIEWPORT with zoom controls
// ════════════════════════════════════════════════════════════════════════════
class _AdminTreeViewport extends StatefulWidget {
  final MLMNode node;
  const _AdminTreeViewport({required this.node});

  @override
  State<_AdminTreeViewport> createState() => _AdminTreeViewportState();
}

class _AdminTreeViewportState extends State<_AdminTreeViewport> {
  final TransformationController _transformCtrl = TransformationController();
  bool _isInteracting = false;

  void _zoomIn() {
    final currentScale = _transformCtrl.value.getMaxScaleOnAxis();
    final newScale = (currentScale + 0.2).clamp(0.5, 4.0);
    _transformCtrl.value = Matrix4.identity()..scale(newScale);
  }

  void _zoomOut() {
    final currentScale = _transformCtrl.value.getMaxScaleOnAxis();
    final newScale = (currentScale - 0.2).clamp(0.5, 4.0);
    _transformCtrl.value = Matrix4.identity()..scale(newScale);
  }

  void _resetZoom() {
    _transformCtrl.value = Matrix4.identity();
  }

  @override
  void dispose() {
    _transformCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 460, // increased to fit buttons
      decoration: BoxDecoration(
        color: const Color(0xFFF0F4FF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.indigo.shade100, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.indigo.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(15),
            child: Listener(
              onPointerDown: (_) => setState(() => _isInteracting = true),
              onPointerUp: (_) => setState(() => _isInteracting = false),
              onPointerCancel: (_) => setState(() => _isInteracting = false),
              child: InteractiveViewer(
                transformationController: _transformCtrl,
                boundaryMargin: const EdgeInsets.all(200),
                minScale: 0.5,
                maxScale: 4.0,
                constrained: false,
                panAxis: PanAxis.free,
                scaleEnabled: true,
                onInteractionStart: (_) =>
                    setState(() => _isInteracting = true),
                onInteractionEnd: (_) => setState(() => _isInteracting = false),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: _AdminTreeNodeWidget(node: widget.node),
                ),
              ),
            ),
          ),
          // Zoom control buttons (bottom right)
          Positioned(
            bottom: 12,
            right: 12,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.zoom_out, size: 22),
                    onPressed: _zoomOut,
                    tooltip: 'Zoom out',
                    constraints: const BoxConstraints(
                      minWidth: 40,
                      minHeight: 40,
                    ),
                    padding: EdgeInsets.zero,
                  ),
                  const VerticalDivider(
                    width: 1,
                    thickness: 1,
                    color: Colors.grey,
                  ),
                  IconButton(
                    icon: const Icon(Icons.zoom_in, size: 22),
                    onPressed: _zoomIn,
                    tooltip: 'Zoom in',
                    constraints: const BoxConstraints(
                      minWidth: 40,
                      minHeight: 40,
                    ),
                    padding: EdgeInsets.zero,
                  ),
                  const VerticalDivider(
                    width: 1,
                    thickness: 1,
                    color: Colors.grey,
                  ),
                  IconButton(
                    icon: const Icon(Icons.fit_screen, size: 22),
                    onPressed: _resetZoom,
                    tooltip: 'Reset zoom',
                    constraints: const BoxConstraints(
                      minWidth: 40,
                      minHeight: 40,
                    ),
                    padding: EdgeInsets.zero,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
//  ADMIN TREE NODE WIDGET
//  - Unlimited levels (no maxLevel cap)
//  - [D] badge for direct referrals
//  - [OF] badge for overflow users
//  - Tap to navigate to that user's CustomerDetailScreen
// ════════════════════════════════════════════════════════════════════════════
class _AdminTreeNodeWidget extends StatelessWidget {
  final MLMNode node;

  const _AdminTreeNodeWidget({required this.node});

  // Border color based on level (cycles after level 6)
  static Color _borderColor(int level) {
    const colors = [
      Color(0xFF3B5BDB), // 0: root (indigo)
      Color(0xFF2E7D32), // 1: green
      Color(0xFFE65100), // 2: orange
      Color(0xFF6A1B9A), // 3: purple
      Color(0xFF00695C), // 4: teal
      Color(0xFFC62828), // 5: red
      Color(0xFF1565C0), // 6: blue
    ];
    return colors[level % colors.length];
  }

  static Color _rankColor(String rank) {
    switch (rank.toLowerCase()) {
      case 'silver':
        return Colors.blueGrey.shade600;
      case 'gold':
        return const Color(0xFFB8860B);
      case 'diamond':
        return const Color(0xFF1565C0);
      default:
        return const Color(0xFF6D4C41);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool hasChildren = node.children.isNotEmpty;
    final Color borderClr = _borderColor(node.level);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // ── Node card ─────────────────────────────────────────────────
        GestureDetector(
          onTap: () {
            if (node.level > 0) {
              Get.to(
                () => CustomerDetailScreen(uid: node.uid),
                preventDuplicates: false,
              );
            }
          },
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Avatar
              Container(
                width: 76,
                height: 76,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  border: Border.all(color: borderClr, width: 3),
                  boxShadow: [
                    BoxShadow(
                      color: borderClr.withOpacity(0.25),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: ClipOval(child: _buildImage(node.image)),
              ),
              const SizedBox(height: 6),

              // Name tag
              Container(
                constraints: const BoxConstraints(maxWidth: 96),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: borderClr,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  node.name.length > 13
                      ? '${node.name.substring(0, 13)}…'
                      : node.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                  ),
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(height: 3),

              // Rank badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: _rankColor(node.rank).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(7),
                  border: Border.all(color: _rankColor(node.rank), width: 1),
                ),
                child: Text(
                  node.rank.toUpperCase(),
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                    color: _rankColor(node.rank),
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              const SizedBox(height: 3),

              // Level label
              Text(
                node.level == 0 ? "YOU" : "Level ${node.level}",
                style: TextStyle(
                  fontSize: 11,
                  color: borderClr,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 3),

              // ── D / OF badges ──────────────────────────────────────
              if (node.level > 0)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (node.isDirectReferral)
                      _smallBadge(
                        "D",
                        Colors.green.shade700,
                        Colors.green.shade50,
                      ),
                    if (node.isDirectReferral && node.isOverflow)
                      const SizedBox(width: 4),
                    if (node.isOverflow)
                      _smallBadge(
                        "OF",
                        Colors.purple.shade700,
                        Colors.purple.shade50,
                      ),
                  ],
                ),

              // Commission (root node only)
              if (node.level == 0) ...[
                const SizedBox(height: 4),
                Text(
                  "Rs.${node.totalCommissionEarned.toStringAsFixed(0)}",
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    color: borderClr,
                  ),
                ),
              ],

              // Tap hint (non-root)
              if (node.level > 0)
                const Text(
                  "tap to view",
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.black38,
                    fontStyle: FontStyle.italic,
                  ),
                ),
            ],
          ),
        ),

        // ── Children connector lines ──────────────────────────────────
        if (hasChildren) ...[
          Container(width: 2, height: 24, color: Colors.grey.shade400),
          if (node.children.length > 1)
            CustomPaint(
              size: Size((node.children.length * 116.0) - 20, 2),
              painter: _LinePainter(color: Colors.grey.shade400),
            ),
          Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: node.children.map((child) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 2,
                      height: 24,
                      color: Colors.grey.shade400,
                    ),
                    _AdminTreeNodeWidget(node: child),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ],
    );
  }

  Widget _smallBadge(String text, Color textColor, Color bgColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: textColor, width: 1),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w900,
          color: textColor,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildImage(String data) {
    if (data.isEmpty) {
      return const Icon(Icons.person, color: Colors.grey, size: 36);
    }
    try {
      if (data.startsWith('http')) {
        return Image.network(
          data,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) =>
              const Icon(Icons.person, color: Colors.grey),
        );
      }
      final clean = data.contains(',') ? data.split(',').last : data;
      return Image.memory(
        base64Decode(clean),
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) =>
            const Icon(Icons.person, color: Colors.grey),
      );
    } catch (_) {
      return const Icon(Icons.person, color: Colors.grey, size: 36);
    }
  }
}

class _LinePainter extends CustomPainter {
  final Color color;
  const _LinePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawLine(
      Offset.zero,
      Offset(size.width, 0),
      Paint()
        ..color = color
        ..strokeWidth = 2,
    );
  }

  @override
  bool shouldRepaint(_LinePainter old) => false;
}
