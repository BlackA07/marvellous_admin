import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../../data/models/order_model.dart';
import '../controllers/orders_controller.dart';
import '../widgets/order_card.dart';
import 'order_detail_screen.dart';

class OrdersDashboardScreen extends StatelessWidget {
  const OrdersDashboardScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(OrdersController(), permanent: true);

    return DefaultTabController(
      length: 6,
      child: Scaffold(
        backgroundColor: const Color(0xFF0F0F0F),
        appBar: AppBar(
          backgroundColor: Colors.black,
          elevation: 0,
          title: Text(
            "Operations",
            style: GoogleFonts.orbitron(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.bug_report, color: Colors.orange),
              onPressed: () => _showDebugInfo(controller),
            ),
          ],
          bottom: TabBar(
            isScrollable: true,
            indicatorColor: Colors.redAccent,
            labelPadding: const EdgeInsets.symmetric(horizontal: 12),
            tabs: [
              _buildTabWithBadge(
                "COD Orders",
                controller.pendingOrders,
                Icons.shopping_bag,
              ),
              _buildTabWithBadge(
                "Online Pay",
                controller.orderPaymentRequests,
                Icons.payment,
              ),
              _buildTabWithBadge(
                "Vendor",
                controller.pendingRequests,
                Icons.store,
              ),
              _buildTabWithBadge(
                "Withdrawals",
                controller.withdrawalRequests,
                Icons.arrow_downward,
              ),
              _buildTabWithBadge(
                "Deposits",
                controller.depositRequests,
                Icons.arrow_upward,
              ),
              _buildTabWithBadge(
                "Old Fees",
                controller.feeRequests,
                Icons.verified_user,
              ),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildOrdersTab(controller),
            _buildOrderPaymentsTab(controller),
            _buildVendorTab(controller),
            _buildWithdrawalsTab(controller),
            _buildDepositsTab(controller),
            _buildFeeTab(controller),
          ],
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  CONFIRMATION DIALOG
  // ══════════════════════════════════════════════════════════════════════════
  void _showConfirmationDialog({
    required String title,
    required String content,
    required VoidCallback onConfirm,
  }) {
    Get.dialog(
      AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: Colors.redAccent.withOpacity(0.5), width: 1),
        ),
        title: Text(
          title,
          style: GoogleFonts.orbitron(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(content, style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text(
              "CANCEL",
              style: TextStyle(color: Colors.white38),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () {
              Get.back();
              onConfirm();
            },
            child: const Text(
              "YES, REJECT",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  DEBUG INFO
  // ══════════════════════════════════════════════════════════════════════════
  void _showDebugInfo(OrdersController controller) {
    Get.dialog(
      AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: Text(
          "Debug Information",
          style: GoogleFonts.orbitron(color: Colors.white),
        ),
        content: Obx(
          () => SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _debugRow("COD Orders", controller.pendingOrders.length),
                _debugRow(
                  "Online Payments",
                  controller.orderPaymentRequests.length,
                ),
                _debugRow("Vendor Requests", controller.pendingRequests.length),
                _debugRow(
                  "Withdrawal Requests",
                  controller.withdrawalRequests.length,
                ),
                _debugRow(
                  "Deposit Requests",
                  controller.depositRequests.length,
                ),
                _debugRow("Old Fee Requests", controller.feeRequests.length),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text("Close")),
        ],
      ),
    );
  }

  Widget _debugRow(String label, int count) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.white70)),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: count > 0 ? Colors.green : Colors.red,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              count.toString(),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabWithBadge(String title, RxList list, IconData icon) {
    return Tab(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16),
          const SizedBox(width: 6),
          Text(
            title,
            style: GoogleFonts.comicNeue(
              fontWeight: FontWeight.bold,
              fontSize: 11,
            ),
          ),
          const SizedBox(width: 5),
          Obx(
            () => list.isEmpty
                ? const SizedBox()
                : Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.redAccent,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      list.length.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  TAB 1: COD ORDERS
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildOrdersTab(OrdersController controller) {
    return Obx(() {
      if (controller.isLoading.value) {
        return const Center(
          child: CircularProgressIndicator(color: Colors.redAccent),
        );
      }
      if (controller.pendingOrders.isEmpty) {
        return _buildEmptyState("No COD Orders", Icons.shopping_bag_outlined);
      }
      return ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: controller.pendingOrders.length,
        itemBuilder: (context, index) {
          final order = controller.pendingOrders[index];
          return CommonListCard(
            title: order.productName,
            subtitle:
                "User: ${order.customerName}\nStatus: ${order.status.toUpperCase()}\nPayment: ${order.paymentMethod}",
            imageUrl: order.productImage,
            price: "PKR ${order.price.toStringAsFixed(0)}",
            onView: () => Get.to(() => OrderDetailScreen(order: order)),
            onAccept: () => _showCenteredStatusDialog(context, order),
            onReject: () => _showConfirmationDialog(
              title: "Reject Order?",
              content: "Are you sure you want to completely reject this order?",
              onConfirm: () =>
                  controller.updateOrderStage(order.id, 'rejected'),
            ),
          );
        },
      );
    });
  }

  void _showCenteredStatusDialog(BuildContext context, OrderModel order) {
    Get.dialog(
      Center(
        child: Material(
          color: Colors.transparent,
          child: Container(
            width: Get.width * 0.85,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A1A),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.redAccent, width: 2),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "Order Status",
                  style: GoogleFonts.orbitron(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  "Update stage for #${order.id}",
                  style: const TextStyle(color: Colors.white54, fontSize: 10),
                ),
                const SizedBox(height: 25),
                _dialogBtn(
                  "CONFIRM ORDER",
                  Colors.blue,
                  () => _handleUpdate(order.id, 'confirmed'),
                ),
                _dialogBtn(
                  "MARK AS SHIPPED",
                  Colors.orange,
                  () => _handleUpdate(order.id, 'shipped'),
                ),
                _dialogBtn(
                  "MARK AS DELIVERED",
                  Colors.green,
                  () => _handleUpdate(order.id, 'delivered'),
                ),
                const SizedBox(height: 15),
                TextButton(
                  onPressed: () => Get.back(),
                  child: const Text(
                    "CANCEL",
                    style: TextStyle(color: Colors.white38),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _handleUpdate(String id, String status) {
    Get.find<OrdersController>().updateOrderStage(id, status);
    Get.back();
  }

  Widget _dialogBtn(String text, Color color, VoidCallback onTap) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      height: 50,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          side: BorderSide(color: color.withOpacity(0.5)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        onPressed: onTap,
        child: Text(
          text,
          style: GoogleFonts.orbitron(
            color: color,
            fontSize: 13,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  TAB 2: ONLINE PAYMENTS
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildOrderPaymentsTab(OrdersController controller) {
    return Obx(() {
      if (controller.isLoading.value) {
        return const Center(
          child: CircularProgressIndicator(color: Colors.redAccent),
        );
      }
      if (controller.orderPaymentRequests.isEmpty) {
        return _buildEmptyState(
          "No Online Payment Requests",
          Icons.payment_outlined,
        );
      }
      return ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: controller.orderPaymentRequests.length,
        itemBuilder: (context, index) {
          final req = controller.orderPaymentRequests[index];
          return _buildOrderPaymentCard(req, controller);
        },
      );
    });
  }

  Widget _buildOrderPaymentCard(
    Map<String, dynamic> req,
    OrdersController controller,
  ) {
    String userId = req['userId'] ?? '';
    String userName = req['userName'] ?? 'Unknown';
    String userEmail = req['userEmail'] ?? 'No Email';
    String customerName = req['customerName'] ?? 'N/A';
    String customerPhone = req['customerPhone'] ?? 'N/A';
    String customerAddress = req['customerAddress'] ?? 'N/A';
    String method = req['method'] ?? 'N/A';
    String trxId = req['trxId'] ?? 'N/A';
    double totalAmount = (req['totalAmount'] ?? 0.0).toDouble();
    var items = req['items'] as List? ?? [];
    var timestamp = req['timestamp'];
    String formattedDate = 'N/A';
    if (timestamp != null) {
      try {
        formattedDate = DateFormat(
          'dd MMM, hh:mm a',
        ).format(timestamp.toDate());
      } catch (e) {}
    }

    return Card(
      color: const Color(0xFF1A1A1A),
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
        side: BorderSide(color: Colors.blue.withOpacity(0.3)),
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: Colors.blue.withOpacity(0.2),
          child: const Icon(Icons.payment, color: Colors.blue),
        ),
        title: Text(
          "$userName (Customer: $customerName)",
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              userEmail,
              style: const TextStyle(color: Colors.white60, fontSize: 11),
            ),
            Text(
              "Rs. ${totalAmount.toStringAsFixed(0)} • ${items.length} items",
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ],
        ),
        trailing: Text(
          formattedDate,
          style: const TextStyle(color: Colors.white38, fontSize: 10),
        ),
        children: [
          Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.3),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(15),
                bottomRight: Radius.circular(15),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _detailRow("Customer Name", customerName),
                _detailRow("Customer Phone", customerPhone),
                _detailRow("Address", customerAddress),
                const Divider(color: Colors.white24, height: 20),
                _detailRow("Payment Method", method),
                _detailRow("TRX ID", trxId),
                _detailRow(
                  "Total Amount",
                  "Rs. ${totalAmount.toStringAsFixed(0)}",
                ),
                const Divider(color: Colors.white24, height: 20),
                Text(
                  "Order Items (${items.length}):",
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 8),
                ...items.map((item) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 5),
                    child: Text(
                      "• ${item['name'] ?? 'Unknown'} x${item['quantity'] ?? 1} - Rs.${(item['salePrice'] ?? 0) * (item['quantity'] ?? 1)}",
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                  );
                }).toList(),
                const Divider(color: Colors.white24, height: 20),
                if (req['screenshotBase64'] != null &&
                    req['screenshotBase64'].toString().isNotEmpty)
                  GestureDetector(
                    onTap: () => _showBase64ImageDialog(
                      req['screenshotBase64'],
                      req['imageExtension'] ?? 'jpg',
                    ),
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 10),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(Icons.image, color: Colors.blue, size: 18),
                          SizedBox(width: 8),
                          Text(
                            "View Payment Screenshot",
                            style: TextStyle(color: Colors.blue, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ),
                const SizedBox(height: 15),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.check, size: 18),
                        label: const Text("Approve & Create Order"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        onPressed: () {
                          if (userId.isEmpty) {
                            Get.snackbar(
                              "Error",
                              "User ID missing",
                              backgroundColor: Colors.red,
                            );
                            return;
                          }
                          controller.approveOrderPayment(req['id']);
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.close, size: 18),
                        label: const Text("Reject"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        onPressed: () => _showRejectDialog(
                          req['id'],
                          userId,
                          'order_payment',
                          controller,
                        ),
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
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  TAB 3: WITHDRAWALS
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildWithdrawalsTab(OrdersController controller) {
    return Obx(() {
      if (controller.isLoading.value) {
        return const Center(
          child: CircularProgressIndicator(color: Colors.redAccent),
        );
      }
      if (controller.withdrawalRequests.isEmpty) {
        return _buildEmptyState(
          "No Withdrawal Requests",
          Icons.account_balance_wallet_outlined,
        );
      }
      return ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: controller.withdrawalRequests.length,
        itemBuilder: (context, index) {
          final req = controller.withdrawalRequests[index];
          return _buildFinanceCard(context, req, 'withdrawal', controller);
        },
      );
    });
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  TAB 4: DEPOSITS
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildDepositsTab(OrdersController controller) {
    return Obx(() {
      if (controller.isLoading.value) {
        return const Center(
          child: CircularProgressIndicator(color: Colors.redAccent),
        );
      }
      if (controller.depositRequests.isEmpty) {
        return _buildEmptyState("No Deposit Requests", Icons.payments_outlined);
      }
      return ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: controller.depositRequests.length,
        itemBuilder: (context, index) {
          final req = controller.depositRequests[index];
          return _buildFinanceCard(context, req, 'deposit', controller);
        },
      );
    });
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  FINANCE CARD (Withdrawal + Deposit)
  //  CHANGE: Withdrawal approve button ab screenshot dialog kholega
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildFinanceCard(
    BuildContext context,
    Map<String, dynamic> req,
    String type,
    OrdersController controller,
  ) {
    double amount = (req['amount'] ?? 0.0).toDouble();
    String userId = req['userId'] ?? '';
    String userName = req['userName'] ?? 'Unknown';
    String userEmail = req['userEmail'] ?? 'No Email';
    String method = req['method'] ?? 'N/A';
    var timestamp = req['timestamp'];
    String formattedDate = 'N/A';
    if (timestamp != null) {
      try {
        formattedDate = DateFormat(
          'dd MMM, hh:mm a',
        ).format(timestamp.toDate());
      } catch (e) {}
    }

    return Card(
      color: const Color(0xFF1A1A1A),
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
        side: BorderSide(
          color: type == 'withdrawal'
              ? Colors.red.withOpacity(0.3)
              : Colors.green.withOpacity(0.3),
        ),
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: type == 'withdrawal'
              ? Colors.red.withOpacity(0.2)
              : Colors.green.withOpacity(0.2),
          child: Icon(
            type == 'withdrawal' ? Icons.arrow_downward : Icons.arrow_upward,
            color: type == 'withdrawal' ? Colors.red : Colors.green,
          ),
        ),
        title: Text(
          userName,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              userEmail,
              style: const TextStyle(color: Colors.white60, fontSize: 11),
            ),
            Text(
              "Rs. ${amount.toStringAsFixed(0)} • $method",
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ],
        ),
        trailing: Text(
          formattedDate,
          style: const TextStyle(color: Colors.white38, fontSize: 10),
        ),
        children: [
          Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.3),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(15),
                bottomRight: Radius.circular(15),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (type == 'withdrawal') ...[
                  // ─── Withdrawal Details ───────────────────────────────────
                  if ((req['accountName'] ?? '').toString().isNotEmpty)
                    _detailRow("Account Name", req['accountName']),
                  if ((req['mobileNumber'] ?? '').toString().isNotEmpty)
                    _detailRow("Mobile", req['mobileNumber']),
                  if ((req['iban'] ?? '').toString().isNotEmpty)
                    _detailRow("IBAN", req['iban']),
                  if ((req['bankName'] ?? '').toString().isNotEmpty)
                    _detailRow("Bank", req['bankName']),
                  if ((req['walletAddress'] ?? '').toString().isNotEmpty)
                    _detailRow("Wallet Address", req['walletAddress']),
                  if ((req['userEmail_detail'] ?? '').toString().isNotEmpty)
                    _detailRow("USDT Email", req['userEmail_detail']),
                  _detailRow(
                    "Requested Amount",
                    "Rs. ${(req['requestedAmount'] ?? amount).toStringAsFixed(0)}",
                  ),
                  _detailRow(
                    "Fee Deducted (50%)",
                    "Rs. ${(req['feeDeducted'] ?? 0.0).toStringAsFixed(0)}",
                  ),
                  _detailRow(
                    "Client Receives",
                    "Rs. ${(req['amountToReceive'] ?? amount).toStringAsFixed(0)}",
                  ),
                  _detailRow(
                    "Membership",
                    req['isUnpaidMember'] == true
                        ? '❌ Unpaid'
                        : '✅ Paid Member',
                  ),
                  // User screenshot (if provided)
                  if ((req['screenshotBase64'] ?? '').toString().isNotEmpty)
                    GestureDetector(
                      onTap: () => _showBase64ImageDialog(
                        req['screenshotBase64'],
                        req['imageExtension'] ?? 'jpg',
                      ),
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Icon(Icons.image, color: Colors.blue, size: 18),
                            SizedBox(width: 8),
                            Text(
                              "View User Screenshot",
                              style: TextStyle(
                                color: Colors.blue,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ] else ...[
                  // ─── Deposit Details ──────────────────────────────────────
                  if (req['trxId'] != null) _detailRow("TRX ID", req['trxId']),
                  if ((req['screenshotBase64'] ?? '').toString().isNotEmpty)
                    GestureDetector(
                      onTap: () => _showBase64ImageDialog(
                        req['screenshotBase64'],
                        req['imageExtension'] ?? 'jpg',
                      ),
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 10),
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Icon(Icons.image, color: Colors.blue, size: 18),
                            SizedBox(width: 8),
                            Text(
                              "View Screenshot",
                              style: TextStyle(
                                color: Colors.blue,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
                const Divider(color: Colors.white24, height: 25),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.check, size: 18),
                        label: const Text("Approve"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),

                        // In _buildFinanceCard function, onPressed for Approve button:
                        onPressed: () {
                          if (userId.isEmpty) {
                            Get.snackbar(
                              "Error",
                              "User ID missing",
                              backgroundColor: Colors.red,
                            );
                            return;
                          }

                          if (type == 'withdrawal') {
                            // ✅ Direct approve karo - screenshot wala dialog mat dikhao
                            // Agar screenshot wala dialog chahiye to comment out karo
                            controller.approveWithdrawal(
                              req['id'],
                              userId,
                              amount,
                            );

                            // Agar screenshot dialog chahiye to ye use karo:
                            // _showWithdrawalApproveDialog(context, req, userId, amount, controller);
                          } else {
                            controller.approveDeposit(req['id'], userId);
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.close, size: 18),
                        label: const Text("Reject"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        onPressed: () => _showRejectDialog(
                          req['id'],
                          userId,
                          type,
                          controller,
                        ),
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
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  ✅ NEW: Withdrawal Approve Dialog with Screenshot Upload
  // ══════════════════════════════════════════════════════════════════════════
  void _showWithdrawalApproveDialog(
    BuildContext context,
    Map<String, dynamic> req,
    String userId,
    double amount,
    OrdersController controller,
  ) {
    File? pickedFile;
    String? base64Img;
    String? imgExt;
    bool isLoading = false;
    String? error;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setState) {
            return Dialog(
              backgroundColor: const Color(0xFF1A1A1A),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Row(
                      children: [
                        const Icon(
                          Icons.check_circle,
                          color: Colors.green,
                          size: 22,
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Approve Withdrawal',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Rs. ${amount.toStringAsFixed(0)} — ${req['userName'] ?? ''}',
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Screenshot Upload Area
                    GestureDetector(
                      onTap: isLoading
                          ? null
                          : () async {
                              final picker = ImagePicker();
                              final picked = await picker.pickImage(
                                source: ImageSource.gallery,
                                imageQuality: 70,
                                maxWidth: 1000,
                              );
                              if (picked == null) return;
                              final file = File(picked.path);
                              final bytes = await file.readAsBytes();
                              if (bytes.lengthInBytes > 1024 * 1024) {
                                setState(
                                  () => error =
                                      'Image too large (max 1MB). Please compress.',
                                );
                                return;
                              }
                              setState(() {
                                pickedFile = file;
                                base64Img = base64Encode(bytes);
                                imgExt = picked.path
                                    .split('.')
                                    .last
                                    .toLowerCase();
                                error = null;
                              });
                            },
                      child: Container(
                        width: double.infinity,
                        height: 130,
                        decoration: BoxDecoration(
                          color: Colors.black26,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: pickedFile != null
                                ? Colors.green.withOpacity(0.5)
                                : Colors.white24,
                          ),
                        ),
                        child: pickedFile != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(11),
                                child: Image.file(
                                  pickedFile!,
                                  fit: BoxFit.cover,
                                ),
                              )
                            : const Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.cloud_upload_outlined,
                                    color: Colors.white38,
                                    size: 32,
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    'Tap to upload payment proof',
                                    style: TextStyle(
                                      color: Colors.white38,
                                      fontSize: 12,
                                    ),
                                  ),
                                  Text(
                                    '(optional — user ko dikhega)',
                                    style: TextStyle(
                                      color: Colors.white24,
                                      fontSize: 10,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),

                    if (error != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        error!,
                        style: const TextStyle(
                          color: Colors.redAccent,
                          fontSize: 11,
                        ),
                      ),
                    ],

                    const SizedBox(height: 16),

                    if (isLoading)
                      const Center(
                        child: CircularProgressIndicator(color: Colors.green),
                      )
                    else
                      Row(
                        children: [
                          // ─── Approve WITHOUT screenshot ───────────────────
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () {
                                Navigator.of(ctx).pop();
                                controller.approveWithdrawal(
                                  req['id'],
                                  userId,
                                  amount,
                                );
                              },
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.white54,
                                side: const BorderSide(color: Colors.white24),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 10,
                                ),
                              ),
                              child: const Text(
                                'Approve\n(No SS)',
                                textAlign: TextAlign.center,
                                style: TextStyle(fontSize: 11),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          // ─── Approve WITH screenshot ──────────────────────
                          Expanded(
                            flex: 2,
                            child: ElevatedButton.icon(
                              // "Approve + Screenshot" button ke onPressed mein:
                              onPressed: pickedFile == null
                                  ? null
                                  : () async {
                                      setState(() => isLoading = true);
                                      try {
                                        double requestedAmount =
                                            (req['requestedAmount'] ?? amount)
                                                .toDouble();
                                        bool isUnpaid =
                                            req['isUnpaidMember'] ?? false;
                                        double feeDeducted = isUnpaid
                                            ? requestedAmount * 0.50
                                            : 0.0;
                                        double amountToReceive =
                                            requestedAmount - feeDeducted;

                                        // 1. Update finances doc
                                        await FirebaseFirestore.instance
                                            .collection('finances')
                                            .doc(req['id'])
                                            .update({
                                              'status': 'approved',
                                              'adminScreenshotBase64':
                                                  base64Img,
                                              'adminImageExtension': imgExt,
                                              'feeDeducted': feeDeducted,
                                              'amountToReceive':
                                                  amountToReceive,
                                              'processedAt':
                                                  FieldValue.serverTimestamp(),
                                            });

                                        // 2. Apply fee if unpaid
                                        if (isUnpaid && feeDeducted > 0) {
                                          var userDoc = await FirebaseFirestore
                                              .instance
                                              .collection('users')
                                              .doc(userId)
                                              .get();
                                          var userData = userDoc.data() ?? {};
                                          double currentPaid =
                                              (userData['paidFees'] ?? 0.0)
                                                  .toDouble();

                                          await FirebaseFirestore.instance
                                              .collection('users')
                                              .doc(userId)
                                              .update({
                                                'paidFees':
                                                    currentPaid + feeDeducted,
                                              });
                                        }

                                        // 3. Add history - NO WALLET DEDUCTION
                                        await FirebaseFirestore.instance
                                            .collection('users')
                                            .doc(userId)
                                            .collection('wallet_history')
                                            .add({
                                              'amount': amountToReceive,
                                              'type': 'withdrawal_approved',
                                              'description':
                                                  '✅ Withdrawal Approved',
                                              'requestedAmount':
                                                  requestedAmount,
                                              'feeDeducted': feeDeducted,
                                              'amountToReceive':
                                                  amountToReceive,
                                              'timestamp':
                                                  FieldValue.serverTimestamp(),
                                            });

                                        if (ctx.mounted)
                                          Navigator.of(ctx).pop();
                                        Get.snackbar(
                                          'Approved ✅',
                                          'Withdrawal approved with screenshot',
                                          backgroundColor: Colors.green,
                                          colorText: Colors.white,
                                        );
                                      } catch (e) {
                                        setState(() {
                                          isLoading = false;
                                          error = 'Error: $e';
                                        });
                                      }
                                    },
                              icon: const Icon(Icons.check, size: 16),
                              label: const Text('Approve + Screenshot'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white,
                                disabledBackgroundColor: Colors.green
                                    .withOpacity(0.3),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 10,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),

                    const SizedBox(height: 4),
                    Center(
                      child: TextButton(
                        onPressed: isLoading
                            ? null
                            : () => Navigator.of(ctx).pop(),
                        child: const Text(
                          'Cancel',
                          style: TextStyle(color: Colors.white38),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  IMAGE VIEWER DIALOG
  // ══════════════════════════════════════════════════════════════════════════
  void _showBase64ImageDialog(String base64Data, String extension) {
    try {
      Get.dialog(
        Dialog(
          backgroundColor: Colors.black,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                color: Colors.black87,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Screenshot (.$extension)",
                      style: const TextStyle(color: Colors.white),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Get.back(),
                    ),
                  ],
                ),
              ),
              Flexible(
                child: InteractiveViewer(
                  child: Image.memory(
                    base64Decode(base64Data),
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stack) => const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.error, color: Colors.red, size: 50),
                          SizedBox(height: 10),
                          Text(
                            "Failed to load image",
                            style: TextStyle(color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    } catch (e) {
      Get.snackbar(
        "Error",
        "Failed to display image: $e",
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  REJECT DIALOG
  // ══════════════════════════════════════════════════════════════════════════
  void _showRejectDialog(
    String reqId,
    String userId,
    String type,
    OrdersController controller,
  ) {
    final reasonCtrl = TextEditingController();
    Get.dialog(
      AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: Text(
          "Reject ${type == 'withdrawal'
              ? 'Withdrawal'
              : type == 'order_payment'
              ? 'Payment'
              : 'Deposit'}",
          style: const TextStyle(color: Colors.white),
        ),
        content: TextField(
          controller: reasonCtrl,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: "Enter rejection reason",
            hintStyle: TextStyle(color: Colors.white38),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.white24),
            ),
            focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.redAccent),
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text("Cancel")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              String reason = reasonCtrl.text.trim();
              if (reason.isEmpty) {
                Get.snackbar(
                  "Error",
                  "Please enter a reason",
                  backgroundColor: Colors.orange,
                );
                return;
              }
              Get.back();
              if (type == 'withdrawal') {
                controller.rejectWithdrawal(reqId, userId, reason);
              } else if (type == 'order_payment') {
                controller.rejectOrderPayment(reqId, userId, reason);
              } else {
                controller.rejectDeposit(reqId, userId, reason);
              }
            },
            child: const Text("Reject"),
          ),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.white54, fontSize: 12),
          ),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  TAB 5: OLD FEE REQUESTS
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildFeeTab(OrdersController controller) {
    return Obx(() {
      if (controller.isLoading.value) {
        return const Center(
          child: CircularProgressIndicator(color: Colors.redAccent),
        );
      }
      if (controller.feeRequests.isEmpty) {
        return _buildEmptyState(
          "No Old Fee Requests",
          Icons.verified_user_outlined,
        );
      }
      return ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: controller.feeRequests.length,
        itemBuilder: (context, index) {
          final req = controller.feeRequests[index];
          return Card(
            color: const Color(0xFF1A1A1A),
            margin: const EdgeInsets.symmetric(vertical: 8),
            child: ListTile(
              leading: const CircleAvatar(
                backgroundColor: Colors.redAccent,
                child: Icon(Icons.attach_money, color: Colors.white),
              ),
              title: Text(
                req['userEmail'] ?? 'No Email',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              subtitle: Text(
                "Rs. ${req['amount'] ?? 0} | ${req['method'] ?? 'N/A'}",
                style: const TextStyle(color: Colors.white60),
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.check_circle, color: Colors.green),
                    onPressed: () {
                      final uid = req['userId'];
                      if (uid == null || uid.isEmpty) {
                        Get.snackbar(
                          "Error",
                          "User ID not found",
                          backgroundColor: Colors.red,
                        );
                        return;
                      }
                      controller.approveFee(req['id'], uid);
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.cancel, color: Colors.red),
                    onPressed: () {
                      final uid = req['userId'];
                      if (uid == null || uid.isEmpty) {
                        Get.snackbar(
                          "Error",
                          "User ID not found",
                          backgroundColor: Colors.red,
                        );
                        return;
                      }
                      _showConfirmationDialog(
                        title: "Reject Old Fee?",
                        content:
                            "Are you sure you want to reject this old fee request?",
                        onConfirm: () => controller.rejectFee(req['id'], uid),
                      );
                    },
                  ),
                ],
              ),
            ),
          );
        },
      );
    });
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  TAB 6: VENDOR REQUESTS
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildVendorTab(OrdersController controller) {
    return Obx(() {
      if (controller.isLoading.value) {
        return const Center(
          child: CircularProgressIndicator(color: Colors.redAccent),
        );
      }
      if (controller.pendingRequests.isEmpty) {
        return _buildEmptyState("No Vendor Requests", Icons.store_outlined);
      }
      return ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: controller.pendingRequests.length,
        itemBuilder: (context, index) {
          final req = controller.pendingRequests[index];
          return CommonListCard(
            title: req.productName,
            subtitle: "By ${req.vendorName}",
            imageUrl: req.productImage,
            price: "PKR ${req.productPrice}",
            onView: () {},
            onAccept: () => controller.acceptRequest(req.id),
            onReject: () => _showConfirmationDialog(
              title: "Reject Vendor?",
              content: "Are you sure you want to reject this vendor request?",
              onConfirm: () => controller.rejectRequest(req.id),
            ),
          );
        },
      );
    });
  }

  Widget _buildEmptyState(String message, IconData icon) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 80, color: Colors.white24),
          const SizedBox(height: 20),
          Text(
            message,
            style: GoogleFonts.orbitron(color: Colors.white54, fontSize: 16),
          ),
        ],
      ),
    );
  }
}
