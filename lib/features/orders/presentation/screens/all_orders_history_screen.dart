// Path: lib/features/orders/presentation/screens/all_orders_history_screen.dart
import 'dart:convert';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class AllOrdersHistoryScreen extends StatefulWidget {
  const AllOrdersHistoryScreen({Key? key}) : super(key: key);

  @override
  State<AllOrdersHistoryScreen> createState() => _AllOrdersHistoryScreenState();
}

class _AllOrdersHistoryScreenState extends State<AllOrdersHistoryScreen> {
  String selectedFilter = 'All';
  final List<String> filters = [
    'All',
    'Pending',
    'Confirmed',
    'Shipped',
    'Delivered',
    'Rejected',
  ];

  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F),
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        title: Text(
          "All Orders History",
          style: GoogleFonts.orbitron(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Get.back(),
        ),
      ),
      body: Column(
        children: [
          // ── SEARCH BAR ────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
            child: TextField(
              controller: _searchController,
              style: const TextStyle(color: Colors.white),
              onChanged: (val) =>
                  setState(() => _searchQuery = val.trim().toLowerCase()),
              decoration: InputDecoration(
                hintText: 'Search by Order ID, Name or Product...',
                hintStyle: const TextStyle(color: Colors.white38, fontSize: 13),
                prefixIcon: const Icon(Icons.search, color: Colors.white38),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.close, color: Colors.white38),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                filled: true,
                fillColor: const Color(0xFF1A1A1A),
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.white.withOpacity(0.08)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.white.withOpacity(0.08)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.redAccent),
                ),
              ),
            ),
          ),

          // ── FILTERS ──────────────────────────────────────────
          Container(
            height: 80,
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('orders')
                  .snapshots(),
              builder: (context, snap) {
                Map<String, double> filterTotals = {};
                if (snap.hasData) {
                  for (var doc in snap.data!.docs) {
                    final d = doc.data() as Map<String, dynamic>;
                    final status = (d['status'] ?? 'pending')
                        .toString()
                        .toLowerCase();
                    final amount =
                        ((d['grandTotal'] ?? d['totalAmount'] ?? 0.0) as num)
                            .toDouble();
                    filterTotals['all'] = (filterTotals['all'] ?? 0.0) + amount;
                    filterTotals[status] =
                        (filterTotals[status] ?? 0.0) + amount;
                  }
                }

                return ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemCount: filters.length,
                  itemBuilder: (context, index) {
                    final filter = filters[index];
                    final isSelected = selectedFilter == filter;
                    final key = filter.toLowerCase();
                    final total = filterTotals[key] ?? 0.0;

                    return GestureDetector(
                      onTap: () => setState(() => selectedFilter = filter),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.only(right: 10),
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: isSelected ? Colors.redAccent : Colors.white12,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isSelected
                                ? Colors.redAccent
                                : Colors.transparent,
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              filter,
                              style: GoogleFonts.comicNeue(
                                color: isSelected
                                    ? Colors.white
                                    : Colors.white70,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                            if (snap.hasData && total > 0)
                              Text(
                                'Rs.${total.toStringAsFixed(0)}',
                                style: TextStyle(
                                  color: isSelected
                                      ? Colors.white70
                                      : Colors.white38,
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),

          // ── ORDERS LIST ──────────────────────────────────────
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('orders')
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: Colors.redAccent),
                  );
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      "Error: ${snapshot.error}",
                      style: const TextStyle(color: Colors.redAccent),
                    ),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return _buildEmptyState("No orders found.");
                }

                var docs = snapshot.data!.docs;

                // Status filter
                if (selectedFilter != 'All') {
                  docs = docs.where((doc) {
                    final status =
                        (doc.data() as Map<String, dynamic>)['status']
                            ?.toString()
                            .toLowerCase() ??
                        'pending';
                    return status == selectedFilter.toLowerCase();
                  }).toList();
                }

                // Search filter — order id, customer name, product name
                if (_searchQuery.isNotEmpty) {
                  docs = docs.where((doc) {
                    final d = doc.data() as Map<String, dynamic>;
                    final orderId = doc.id.toLowerCase();
                    final customerName = (d['customerName'] ?? '')
                        .toString()
                        .toLowerCase();
                    final items = d['items'] as List? ?? [];
                    final productNames = items
                        .map((i) => (i['name'] ?? '').toString().toLowerCase())
                        .join(' ');

                    return orderId.contains(_searchQuery) ||
                        customerName.contains(_searchQuery) ||
                        productNames.contains(_searchQuery);
                  }).toList();
                }

                if (docs.isEmpty) {
                  return _buildEmptyState(
                    _searchQuery.isNotEmpty
                        ? 'No results for "$_searchQuery"'
                        : "No $selectedFilter orders found.",
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    var data = docs[index].data() as Map<String, dynamic>;
                    String orderId = docs[index].id;
                    return _buildOrderCard(orderId, data);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // baaki sara code same rehta hai — _buildOrderCard se neeche tak kuch nahi badla

  Widget _buildOrderCard(String orderId, Map<String, dynamic> data) {
    String customerName = data['customerName'] ?? 'Unknown Customer';
    String customerPhone = data['customerPhone'] ?? 'No Phone';
    String status = data['status'] ?? 'pending';
    double grandTotal = (data['grandTotal'] ?? data['totalAmount'] ?? 0.0)
        .toDouble();

    List items = data['items'] ?? [];
    String firstItemName = "Multiple Items";
    String firstItemImage = "";
    if (items.isNotEmpty) {
      firstItemName = items[0]['name'] ?? "Unknown Item";
      firstItemImage = items[0]['image'] ?? items[0]['firstImage'] ?? "";
      if (items.length > 1) {
        firstItemName += " (+${items.length - 1} more)";
      }
    }

    String dateStr = "N/A";
    if (data['createdAt'] != null) {
      DateTime dt = (data['createdAt'] as Timestamp).toDate();
      dateStr = DateFormat('dd MMM yyyy, hh:mm a').format(dt);
    }

    return GestureDetector(
      // ✅ Tap karte hi detailed bottom sheet open hogi
      onTap: () => _showOrderDetails(data, orderId, dateStr),
      child: Card(
        color: const Color(0xFF1A1A1A),
        margin: const EdgeInsets.only(bottom: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
          side: BorderSide(color: Colors.white.withOpacity(0.05)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Order #$orderId",
                    style: GoogleFonts.orbitron(
                      color: Colors.white54,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  _buildStatusBadge(status),
                ],
              ),
              const Divider(color: Colors.white12, height: 20),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      height: 70,
                      width: 70,
                      color: Colors.white12,
                      child: _buildImage(firstItemImage),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          firstItemName,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.comicNeue(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(
                              Icons.person,
                              color: Colors.white54,
                              size: 14,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                customerName,
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 13,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            const Icon(
                              Icons.phone,
                              color: Colors.white54,
                              size: 14,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              customerPhone,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.black26,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      dateStr,
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 11,
                      ),
                    ),
                    Text(
                      "Rs. ${grandTotal.toStringAsFixed(0)}",
                      style: GoogleFonts.comicNeue(
                        color: Colors.greenAccent,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════
  //  ORDER DETAILS BOTTOM SHEET
  // ══════════════════════════════════════════════════════════════════
  void _showOrderDetails(
    Map<String, dynamic> data,
    String orderId,
    String dateStr,
  ) {
    String status = data['status'] ?? 'pending';
    String rejectionReason =
        data['rejectionReason'] ?? 'No reason provided by admin.';
    String paymentMethod = data['paymentMethod'] ?? 'N/A';
    String trxId = data['trxId'] ?? 'N/A';
    String paymentSource = data['paymentSource'] ?? '';

    List items = data['items'] ?? [];
    double subTotal = (data['subTotal'] ?? 0.0).toDouble();
    double shippingFee = (data['shippingFee'] ?? 0.0).toDouble();
    double codCharges = (data['codCharges'] ?? 0.0).toDouble();
    double grandTotal = (data['grandTotal'] ?? data['totalAmount'] ?? 0.0)
        .toDouble();

    Get.bottomSheet(
      Container(
        height: Get.height * 0.9,
        decoration: const BoxDecoration(
          color: Color(0xFF151515),
          borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 10),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 10),

            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Order Details",
                    style: GoogleFonts.orbitron(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white54),
                    onPressed: () => Get.back(),
                  ),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Status & ID
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Order ID: $orderId",
                          style: const TextStyle(
                            color: Colors.white54,
                            fontSize: 11,
                          ),
                        ),
                        _buildStatusBadge(status),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Text(
                      dateStr,
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Rejection Reason Alert
                    if (status.toLowerCase() == 'rejected') ...[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.redAccent.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: Colors.redAccent.withOpacity(0.3),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(
                                  Icons.cancel,
                                  color: Colors.redAccent,
                                  size: 16,
                                ),
                                SizedBox(width: 6),
                                Text(
                                  "Rejection Reason",
                                  style: TextStyle(
                                    color: Colors.redAccent,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              rejectionReason,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],

                    // Customer Info
                    _buildSectionHeader("Customer Info", Icons.person_outline),
                    _buildDetailBox([
                      _detailRow("Name", data['customerName'] ?? 'N/A'),
                      _detailRow("Phone", data['customerPhone'] ?? 'N/A'),
                      _detailRow("Email", data['userEmail'] ?? 'N/A'),
                      const Divider(color: Colors.white12),
                      _detailRow("Address", data['customerAddress'] ?? 'N/A'),
                    ]),
                    const SizedBox(height: 20),

                    // Payment Info
                    _buildSectionHeader("Payment Info", Icons.payment),
                    _buildDetailBox([
                      _detailRow("Method", paymentMethod),
                      if (paymentSource.isNotEmpty)
                        _detailRow("Source", paymentSource.toUpperCase()),
                      if (trxId.isNotEmpty && trxId != 'N/A')
                        _detailRow("TRX ID", trxId),
                    ]),

                    // Screenshot Fetcher
                    if (paymentMethod != 'Cash on Delivery') ...[
                      const SizedBox(height: 10),
                      FutureBuilder<QuerySnapshot>(
                        // Dynamically fetches the screenshot from finances collection if available
                        future: FirebaseFirestore.instance
                            .collection('finances')
                            .where('orderId', isEqualTo: orderId)
                            .limit(1)
                            .get(),
                        builder: (context, snap) {
                          if (snap.connectionState == ConnectionState.waiting) {
                            return const Center(
                              child: CircularProgressIndicator(strokeWidth: 2),
                            );
                          }
                          if (snap.hasData && snap.data!.docs.isNotEmpty) {
                            var finData =
                                snap.data!.docs.first.data()
                                    as Map<String, dynamic>;
                            String imgBase64 =
                                finData['screenshotBase64'] ?? '';
                            String ext = finData['imageExtension'] ?? 'jpg';

                            if (imgBase64.isNotEmpty) {
                              return GestureDetector(
                                onTap: () =>
                                    _showBase64ImageDialog(imgBase64, ext),
                                child: Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.blue.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: Colors.blue.withOpacity(0.3),
                                    ),
                                  ),
                                  child: const Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.image,
                                        color: Colors.blueAccent,
                                        size: 18,
                                      ),
                                      SizedBox(width: 8),
                                      Text(
                                        "View Payment Screenshot",
                                        style: TextStyle(
                                          color: Colors.blueAccent,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }
                          }
                          return const SizedBox.shrink();
                        },
                      ),
                    ],
                    const SizedBox(height: 20),

                    // Order Items
                    _buildSectionHeader(
                      "Order Items (${items.length})",
                      Icons.shopping_bag_outlined,
                    ),
                    _buildDetailBox(
                      items.map((item) {
                        double price = (item['salePrice'] ?? 0.0).toDouble();
                        int qty = item['quantity'] ?? 1;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Container(
                                  height: 40,
                                  width: 40,
                                  color: Colors.white12,
                                  child: _buildImage(
                                    item['image'] ?? item['firstImage'] ?? '',
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item['name'] ?? 'Unknown',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    if ((item['modelNumber'] ?? '')
                                        .toString()
                                        .isNotEmpty)
                                      Text(
                                        item['modelNumber'],
                                        style: const TextStyle(
                                          color: Colors.white54,
                                          fontSize: 11,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              Text(
                                "x$qty",
                                style: const TextStyle(
                                  color: Colors.white54,
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                "Rs.${(price * qty).toStringAsFixed(0)}",
                                style: const TextStyle(
                                  color: Colors.greenAccent,
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 20),

                    // Bill Summary
                    _buildSectionHeader("Bill Summary", Icons.receipt_long),
                    _buildDetailBox([
                      _detailRow(
                        "Subtotal",
                        "Rs. ${subTotal.toStringAsFixed(0)}",
                      ),
                      _detailRow(
                        "Shipping Fee",
                        "Rs. ${shippingFee.toStringAsFixed(0)}",
                      ),
                      if (codCharges > 0)
                        _detailRow(
                          "COD Charges",
                          "Rs. ${codCharges.toStringAsFixed(0)}",
                        ),
                      const Divider(color: Colors.white12),
                      _detailRow(
                        "Grand Total",
                        "Rs. ${grandTotal.toStringAsFixed(0)}",
                        isTotal: true,
                      ),
                    ]),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      isScrollControlled: true,
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(icon, color: Colors.white54, size: 18),
          const SizedBox(width: 8),
          Text(
            title,
            style: GoogleFonts.comicNeue(
              color: Colors.white70,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailBox(List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  Widget _detailRow(String label, String value, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: isTotal ? Colors.white : Colors.white54,
              fontSize: isTotal ? 14 : 13,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                color: isTotal ? Colors.greenAccent : Colors.white,
                fontSize: isTotal ? 16 : 13,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showBase64ImageDialog(String base64Data, String extension) {
    try {
      if (base64Data.isEmpty) return;
      Uint8List bytes = base64Decode(base64Data);
      Get.dialog(
        Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(20),
          child: Container(
            width: double.infinity,
            height: MediaQuery.of(Get.context!).size.height * 0.7,
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: const BoxDecoration(
                    color: Colors.black87,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(16),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Payment Screenshot",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
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
                    minScale: 0.5,
                    maxScale: 4.0,
                    child: Center(
                      child: Image.memory(
                        bytes,
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => const Icon(
                          Icons.broken_image,
                          color: Colors.red,
                          size: 60,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    } catch (e) {
      Get.snackbar(
        "Error",
        "Failed to display image",
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  Widget _buildStatusBadge(String status) {
    Color bg;
    Color textCol;
    switch (status.toLowerCase()) {
      case 'pending':
        bg = Colors.orange.withOpacity(0.2);
        textCol = Colors.orangeAccent;
        break;
      case 'confirmed':
        bg = Colors.blue.withOpacity(0.2);
        textCol = Colors.blueAccent;
        break;
      case 'shipped':
        bg = Colors.purple.withOpacity(0.2);
        textCol = Colors.purpleAccent;
        break;
      case 'delivered':
        bg = Colors.green.withOpacity(0.2);
        textCol = Colors.greenAccent;
        break;
      case 'rejected':
      case 'cancelled':
        bg = Colors.red.withOpacity(0.2);
        textCol = Colors.redAccent;
        break;
      default:
        bg = Colors.grey.withOpacity(0.2);
        textCol = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: textCol.withOpacity(0.5)),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          color: textCol,
          fontSize: 10,
          fontWeight: FontWeight.bold,
          letterSpacing: 1,
        ),
      ),
    );
  }

  Widget _buildImage(String data) {
    if (data.isEmpty) {
      return const Icon(Icons.shopping_bag, color: Colors.white38, size: 30);
    }
    try {
      if (data.startsWith('http')) {
        return Image.network(
          data,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) =>
              const Icon(Icons.broken_image, color: Colors.white38),
        );
      }
      return Image.memory(
        base64Decode(data),
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) =>
            const Icon(Icons.broken_image, color: Colors.white38),
      );
    } catch (_) {
      return const Icon(Icons.error, color: Colors.redAccent);
    }
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.history_toggle_off,
            size: 80,
            color: Colors.white.withOpacity(0.1),
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: GoogleFonts.comicNeue(
              color: Colors.white54,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
