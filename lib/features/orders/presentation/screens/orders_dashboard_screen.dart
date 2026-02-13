import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../data/models/order_model.dart';
import '../controllers/orders_controller.dart';
import '../widgets/order_card.dart';
import 'order_detail_screen.dart';

class OrdersDashboardScreen extends StatelessWidget {
  const OrdersDashboardScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(OrdersController());

    return DefaultTabController(
      length: 5,
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
            labelPadding: const EdgeInsets.symmetric(horizontal: 15),
            tabs: [
              _buildTabWithBadge(
                "Orders",
                controller.pendingOrders,
                Icons.shopping_bag,
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
            _buildVendorTab(controller),
            _buildWithdrawalsTab(controller),
            _buildDepositsTab(controller),
            _buildFeeTab(controller),
          ],
        ),
      ),
    );
  }

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
                _debugRow("Pending Orders", controller.pendingOrders.length),
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
              fontSize: 12,
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

  // --- ORDERS TAB ---
  Widget _buildOrdersTab(OrdersController controller) {
    return Obx(() {
      if (controller.isLoading.value) {
        return const Center(
          child: CircularProgressIndicator(color: Colors.redAccent),
        );
      }

      if (controller.pendingOrders.isEmpty) {
        return _buildEmptyState(
          "No Active Orders",
          Icons.shopping_bag_outlined,
        );
      }

      return ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: controller.pendingOrders.length,
        itemBuilder: (context, index) {
          final order = controller.pendingOrders[index];
          return CommonListCard(
            title: order.productName,
            subtitle:
                "User: ${order.customerName}\nStatus: ${order.status.toUpperCase()}",
            imageUrl: order.productImage,
            price: "PKR ${order.price.toStringAsFixed(0)}",
            onView: () => Get.to(() => OrderDetailScreen(order: order)),
            onAccept: () => _showCenteredStatusDialog(context, order),
            onReject: () => controller.updateOrderStage(order.id, 'rejected'),
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

  // --- WITHDRAWALS TAB ---
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
          return _buildFinanceCard(req, 'withdrawal', controller);
        },
      );
    });
  }

  // --- DEPOSITS TAB (WITH BASE64 IMAGE SUPPORT) ---
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
          return _buildFinanceCard(req, 'deposit', controller);
        },
      );
    });
  }

  Widget _buildFinanceCard(
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
                  if (req['accountName'] != null)
                    _detailRow("Account Name", req['accountName']),
                  if (req['mobileNumber'] != null)
                    _detailRow("Mobile", req['mobileNumber']),
                  if (req['iban'] != null) _detailRow("IBAN", req['iban']),
                  if (req['bankName'] != null)
                    _detailRow("Bank", req['bankName']),
                  if (req['walletAddress'] != null)
                    _detailRow("Wallet", req['walletAddress']),
                  _detailRow(
                    "Available Balance",
                    "Rs. ${(req['availableBalance'] ?? 0.0).toStringAsFixed(0)}",
                  ),
                ] else ...[
                  if (req['trxId'] != null) _detailRow("TRX ID", req['trxId']),

                  // ✅ BASE64 IMAGE SUPPORT
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
                              "View Screenshot (Base64)",
                              style: TextStyle(
                                color: Colors.blue,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  // ❌ OLD URL SUPPORT (Fallback for old data)
                  else if (req['screenshotUrl'] != null &&
                      req['screenshotUrl'].toString().isNotEmpty)
                    GestureDetector(
                      onTap: () => _showImageUrlDialog(req['screenshotUrl']),
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
                              "View Screenshot (URL)",
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
                            controller.approveWithdrawal(
                              req['id'],
                              userId,
                              amount,
                            );
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

  // ✅ NEW: Show Base64 Image Dialog
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
                      "Payment Screenshot (.${extension})",
                      style: const TextStyle(color: Colors.white),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Get.back(),
                    ),
                  ],
                ),
              ),
              Expanded(
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

  // ❌ OLD: Show URL Image Dialog (for backward compatibility)
  void _showImageUrlDialog(String url) {
    Get.dialog(
      Dialog(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              color: Colors.black,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Payment Screenshot",
                    style: TextStyle(color: Colors.white),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Get.back(),
                  ),
                ],
              ),
            ),
            Image.network(url, fit: BoxFit.contain),
          ],
        ),
      ),
    );
  }

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
          "Reject ${type == 'withdrawal' ? 'Withdrawal' : 'Deposit'}",
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

  // --- OLD FEE TAB ---
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
                      final userId = req['userId'];
                      if (userId == null || userId.isEmpty) {
                        Get.snackbar(
                          "Error",
                          "User ID not found",
                          backgroundColor: Colors.red,
                        );
                        return;
                      }
                      controller.approveFee(req['id'], userId);
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.cancel, color: Colors.red),
                    onPressed: () {
                      final userId = req['userId'];
                      if (userId == null || userId.isEmpty) {
                        Get.snackbar(
                          "Error",
                          "User ID not found",
                          backgroundColor: Colors.red,
                        );
                        return;
                      }
                      controller.rejectFee(req['id'], userId);
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

  // --- VENDOR TAB ---
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
            onReject: () => controller.rejectRequest(req.id),
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
