import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../controller/vendor_payment_controller.dart';
import '../widgets/searchable_selection_field.dart';

class VendorManageBillsScreen extends StatefulWidget {
  const VendorManageBillsScreen({super.key});

  @override
  State<VendorManageBillsScreen> createState() =>
      _VendorManageBillsScreenState();
}

class _VendorManageBillsScreenState extends State<VendorManageBillsScreen> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final VendorPaymentController _controller = Get.put(
    VendorPaymentController(),
  );

  List<String> cachedVendorList = [];
  List<DocumentSnapshot> cachedVendorDocs = [];

  String? selectedVendorId;
  String? selectedVendorName;

  // ── Search & Filter ──
  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery = '';
  String _statusFilter = 'All'; // All, Paid, Partial, Unpaid
  String _sortMode = 'Latest First'; // Latest First, Oldest First

  @override
  void initState() {
    super.initState();
    _fetchVendors();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _fetchVendors() async {
    var snap = await _db
        .collection('vendors')
        .where('status', isEqualTo: 'approved')
        .get();
    setState(() {
      cachedVendorDocs = snap.docs;
      cachedVendorList = cachedVendorDocs.map((e) {
        var d = e.data() as Map<String, dynamic>;
        return "${d['storeName'] ?? 'Unknown'} (${d['ownerName'] ?? 'Unknown'})";
      }).toList()..sort();
    });
  }

  DateTime _parseDate(dynamic dateData) {
    if (dateData == null) return DateTime.now();
    if (dateData is Timestamp) return dateData.toDate();
    if (dateData is String)
      return DateTime.tryParse(dateData) ?? DateTime.now();
    return DateTime.now();
  }

  double _getCalculatedRemaining(Map<String, dynamic> data) {
    double rem =
        double.tryParse(data['remainingBalance']?.toString() ?? '0') ?? 0.0;
    if (rem <= 0.0) {
      double total =
          double.tryParse(
            data['totalBillAmount']?.toString() ??
                data['totalPrice']?.toString() ??
                '0',
          ) ??
          0.0;
      double paid = double.tryParse(data['cashPaid']?.toString() ?? '0') ?? 0.0;
      rem = total - paid;
    }
    return rem > 0 ? rem : 0.0;
  }

  // ── Bill Status Helper ──
  String _getBillStatus(double total, double paid, double remaining) {
    if (remaining <= 0) return 'Paid';
    if (paid <= 0) return 'Unpaid';
    return 'Partial';
  }

  // ── Color scheme per status ──
  Color _cardBg(String status) {
    switch (status) {
      case 'Paid':
        return const Color(0xFFE8F5E9); // light green
      case 'Partial':
        return const Color(0xFFE3F2FD); // light blue
      default:
        return const Color(0xFFFFEBEE); // light red
    }
  }

  Color _cardBorder(String status) {
    switch (status) {
      case 'Paid':
        return Colors.green.shade800;
      case 'Partial':
        return Colors.blue.shade800;
      default:
        return Colors.red.shade800;
    }
  }

  Color _statusBadgeBg(String status) {
    switch (status) {
      case 'Paid':
        return Colors.green.shade800;
      case 'Partial':
        return Colors.blue.shade800;
      default:
        return Colors.red.shade800;
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'Paid':
        return '✓ FULLY PAID';
      case 'Partial':
        return '◑ PARTIALLY PAID';
      default:
        return '✗ UNPAID';
    }
  }

  // ── Filter bills list ──
  List<DocumentSnapshot> _applyFilters(List<DocumentSnapshot> allBills) {
    // 1. Sort
    allBills.sort((a, b) {
      DateTime dA = _parseDate((a.data() as Map)['date']);
      DateTime dB = _parseDate((b.data() as Map)['date']);
      return _sortMode == 'Latest First' ? dB.compareTo(dA) : dA.compareTo(dB);
    });

    // 2. Status filter
    if (_statusFilter != 'All') {
      allBills = allBills.where((doc) {
        var d = doc.data() as Map<String, dynamic>;
        double total =
            double.tryParse(
              d['totalBillAmount']?.toString() ??
                  d['totalPrice']?.toString() ??
                  '0',
            ) ??
            0.0;
        double paid = double.tryParse(d['cashPaid']?.toString() ?? '0') ?? 0.0;
        double remaining = _getCalculatedRemaining(d);
        String status = _getBillStatus(total, paid, remaining);
        return status == _statusFilter;
      }).toList();
    }

    // 3. Search filter
    if (_searchQuery.trim().isNotEmpty) {
      String q = _searchQuery.toLowerCase();
      allBills = allBills.where((doc) {
        var d = doc.data() as Map<String, dynamic>;
        String billNum = (d['billNumber'] ?? '').toString().toLowerCase();
        double total =
            double.tryParse(
              d['totalBillAmount']?.toString() ??
                  d['totalPrice']?.toString() ??
                  '0',
            ) ??
            0.0;
        List items = d['items'] ?? [];
        String products = items
            .map((e) => (e['productName'] ?? ''))
            .join(' ')
            .toLowerCase();

        return billNum.contains(q) ||
            products.contains(q) ||
            total.toStringAsFixed(0).contains(q);
      }).toList();
    }

    return allBills;
  }

  // ── Double-confirm delete ──
  void _confirmDeleteStep1(String purchaseId, String billNumber) {
    Get.defaultDialog(
      title: "Delete Bill?",
      titlePadding: const EdgeInsets.only(top: 20, bottom: 10),
      titleStyle: GoogleFonts.comicNeue(
        fontWeight: FontWeight.w900,
        color: Colors.white,
        fontSize: 26,
      ),
      content: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: Text(
          "Are you sure you want to delete Bill #$billNumber?",
          textAlign: TextAlign.center,
          style: GoogleFonts.comicNeue(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      cancel: OutlinedButton(
        onPressed: () => Get.back(),
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: Colors.black, width: 2),
        ),
        child: Text(
          "Cancel",
          style: GoogleFonts.comicNeue(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
      confirm: ElevatedButton(
        style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade900),
        onPressed: () {
          Get.back();
          _confirmDeleteStep2(purchaseId, billNumber);
        },
        child: Text(
          "Yes, Proceed",
          style: GoogleFonts.comicNeue(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
    );
  }

  void _confirmDeleteStep2(String purchaseId, String billNumber) {
    final TextEditingController deleteCtrl = TextEditingController();

    Get.defaultDialog(
      title: "FINAL WARNING!",
      titlePadding: const EdgeInsets.only(top: 20, bottom: 10),
      titleStyle: GoogleFonts.comicNeue(
        fontWeight: FontWeight.w900,
        color: Colors.red.shade900,
        fontSize: 26,
      ),
      content: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          children: [
            Text(
              "This action is NON-RECOVERABLE.\nAll installments and payments for Bill #$billNumber will be wiped out.\n\nType 'DELETE' to confirm:",
              textAlign: TextAlign.center,
              style: GoogleFonts.comicNeue(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: deleteCtrl,
              textAlign: TextAlign.center,
              style: GoogleFonts.comicNeue(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
              decoration: InputDecoration(
                hintText: "Type DELETE",
                filled: true,
                fillColor: const Color.fromARGB(255, 96, 93, 93),
                border: OutlineInputBorder(
                  borderSide: const BorderSide(color: Colors.black, width: 2),
                  borderRadius: BorderRadius.circular(8),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: const BorderSide(color: Colors.red, width: 3),
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                OutlinedButton(
                  onPressed: () => Get.back(),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.black, width: 2),
                  ),
                  child: Text(
                    "Cancel",
                    style: GoogleFonts.comicNeue(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade900,
                  ),
                  onPressed: () async {
                    if (deleteCtrl.text.trim() == 'DELETE') {
                      Get.back();
                      await _controller.deleteBillTransaction(
                        purchaseId: purchaseId,
                        vendorId: selectedVendorId!,
                        billNumber: billNumber,
                      );
                    } else {
                      Get.snackbar(
                        "Cancelled",
                        "Typing mismatch. Deletion cancelled.",
                        backgroundColor: Colors.black,
                        colorText: Colors.white,
                      );
                    }
                  },
                  child: Text(
                    "DELETE NOW",
                    style: GoogleFonts.comicNeue(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          "Manage & Delete Bills",
          style: GoogleFonts.comicNeue(
            fontSize: 26,
            fontWeight: FontWeight.w900,
            color: Colors.black,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 2,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // ── TOP PANEL: Vendor + Search + Filter + Sort ──
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(
                  bottom: BorderSide(color: Colors.black, width: 2.5),
                ),
              ),
              child: Column(
                children: [
                  // Vendor selector
                  cachedVendorList.isEmpty
                      ? const LinearProgressIndicator(color: Colors.black)
                      : SearchableSelectionField(
                          label: "Select Vendor to Load Bills",
                          hint: "Search Store or Owner...",
                          selectedValue: selectedVendorName,
                          items: cachedVendorList,
                          onSelected: (val) {
                            var v = cachedVendorDocs.firstWhere((e) {
                              var d = e.data() as Map<String, dynamic>;
                              return "${d['storeName'] ?? ''} (${d['ownerName'] ?? ''})" ==
                                  val;
                            });
                            setState(() {
                              selectedVendorName = val;
                              selectedVendorId = v.id;
                              _searchQuery = '';
                              _searchCtrl.clear();
                              _statusFilter = 'All';
                              _sortMode = 'Latest First';
                            });
                          },
                        ),

                  if (selectedVendorId != null) ...[
                    const SizedBox(height: 16),

                    // ── SEARCH BAR ──
                    TextField(
                      controller: _searchCtrl,
                      onChanged: (val) => setState(() => _searchQuery = val),
                      style: GoogleFonts.comicNeue(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                      decoration: InputDecoration(
                        hintText: "Search by Bill No, Product, or Amount...",
                        hintStyle: GoogleFonts.comicNeue(
                          color: Colors.black45,
                          fontSize: 15,
                        ),
                        prefixIcon: const Icon(
                          Icons.search,
                          color: Colors.black,
                          size: 26,
                        ),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(
                                  Icons.close,
                                  color: Colors.black,
                                ),
                                onPressed: () => setState(() {
                                  _searchQuery = '';
                                  _searchCtrl.clear();
                                }),
                              )
                            : null,
                        filled: true,
                        fillColor: const Color(0xFFF1F3F5),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(
                            color: Colors.black,
                            width: 2,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(
                            color: Colors.black,
                            width: 2,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(
                            color: Colors.black,
                            width: 2.5,
                          ),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 14,
                          horizontal: 14,
                        ),
                      ),
                    ),

                    const SizedBox(height: 14),

                    // ── STATUS FILTER CHIPS ──
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          for (final label in [
                            'All',
                            'Paid',
                            'Partial',
                            'Unpaid',
                          ])
                            Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: _filterChip(label),
                            ),
                          const SizedBox(width: 6),
                          Container(
                            height: 36,
                            width: 1.5,
                            color: Colors.black26,
                          ),
                          const SizedBox(width: 14),
                          // ── SORT DROPDOWN ──
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: _sortMode,
                                dropdownColor: Colors.black87,
                                iconEnabledColor: Colors.white,
                                style: GoogleFonts.comicNeue(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                                items: const [
                                  DropdownMenuItem(
                                    value: 'Latest First',
                                    child: Text('Latest First'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'Oldest First',
                                    child: Text('Oldest First'),
                                  ),
                                ],
                                onChanged: (val) {
                                  if (val != null)
                                    setState(() => _sortMode = val);
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // ── BILLS LIST ──
            if (selectedVendorId == null)
              Padding(
                padding: const EdgeInsets.only(top: 100),
                child: Center(
                  child: Text(
                    "Please select a vendor first.",
                    style: GoogleFonts.comicNeue(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: Colors.black54,
                    ),
                  ),
                ),
              )
            else
              StreamBuilder<QuerySnapshot>(
                stream: _db
                    .collection('vendor_purchases')
                    .where('vendorId', isEqualTo: selectedVendorId)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError)
                    return Padding(
                      padding: const EdgeInsets.all(20),
                      child: Text(
                        "Error: ${snapshot.error}",
                        style: GoogleFonts.comicNeue(
                          color: Colors.red,
                          fontWeight: FontWeight.w900,
                          fontSize: 20,
                        ),
                      ),
                    );
                  if (snapshot.connectionState == ConnectionState.waiting)
                    return const Padding(
                      padding: EdgeInsets.all(40),
                      child: CircularProgressIndicator(color: Colors.black),
                    );

                  var allBills = List<DocumentSnapshot>.from(
                    snapshot.data!.docs,
                  );
                  allBills = _applyFilters(allBills);

                  if (allBills.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 60, bottom: 50),
                      child: Column(
                        children: [
                          Icon(
                            Icons.inbox_rounded,
                            size: 60,
                            color: Colors.black26,
                          ),
                          const SizedBox(height: 14),
                          Text(
                            "No Bills Found.",
                            style: GoogleFonts.comicNeue(
                              fontSize: 24,
                              fontWeight: FontWeight.w900,
                              color: Colors.black45,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.all(15),
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: allBills.length,
                    itemBuilder: (context, index) {
                      var billDoc = allBills[index];
                      var billData = billDoc.data() as Map<String, dynamic>;

                      String billNum =
                          billData['billNumber']?.toString() ?? 'N/A';
                      if (billNum == 'null') billNum = 'N/A';

                      double totalAmount =
                          double.tryParse(
                            billData['totalBillAmount']?.toString() ??
                                billData['totalPrice']?.toString() ??
                                '0',
                          ) ??
                          0.0;
                      double remaining = _getCalculatedRemaining(billData);
                      double paidAmount = totalAmount - remaining;

                      DateTime billDate = _parseDate(billData['date']);

                      List items = billData['items'] ?? [];
                      String productsStr = items.isNotEmpty
                          ? items
                                .map((e) {
                                  String name = e['productName'] ?? '';
                                  String brand = e['brand'] ?? '';
                                  String ram = e['ram'] ?? '';
                                  String storage = e['storage'] ?? '';
                                  List<String> parts = [
                                    if (brand.isNotEmpty) brand,
                                  ];
                                  if (ram.isNotEmpty || storage.isNotEmpty) {
                                    parts.add(
                                      [
                                        if (ram.isNotEmpty) 'RAM:$ram',
                                        if (storage.isNotEmpty) 'ROM:$storage',
                                      ].join('/'),
                                    );
                                  }
                                  return parts.isEmpty
                                      ? name
                                      : '$name (${parts.join(' • ')})';
                                })
                                .join(", ")
                          : "N/A";

                      String status = _getBillStatus(
                        totalAmount,
                        paidAmount,
                        remaining,
                      );

                      return Obx(() {
                        return Card(
                          color: _cardBg(status),
                          elevation: 3,
                          margin: const EdgeInsets.only(bottom: 18),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(
                              color: _cardBorder(status),
                              width: 2.5,
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(15),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // ── Header Row ──
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            "Bill #: $billNum",
                                            style: GoogleFonts.comicNeue(
                                              fontSize: 22,
                                              fontWeight: FontWeight.w900,
                                              color: Colors.black,
                                            ),
                                          ),
                                          Text(
                                            "Date: ${DateFormat('dd MMM, yyyy').format(billDate)}",
                                            style: GoogleFonts.comicNeue(
                                              fontSize: 15,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.black54,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    // Status Badge
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 5,
                                      ),
                                      decoration: BoxDecoration(
                                        color: _statusBadgeBg(status),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        _statusLabel(status),
                                        style: GoogleFonts.comicNeue(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w900,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    // Delete icon
                                    IconButton(
                                      icon: _controller.isDeleting.value
                                          ? const SizedBox(
                                              width: 24,
                                              height: 24,
                                              child: CircularProgressIndicator(
                                                color: Colors.red,
                                                strokeWidth: 2,
                                              ),
                                            )
                                          : const Icon(
                                              Icons.delete_forever,
                                              color: Colors.red,
                                              size: 32,
                                            ),
                                      onPressed: _controller.isDeleting.value
                                          ? null
                                          : () => _confirmDeleteStep1(
                                              billDoc.id,
                                              billNum,
                                            ),
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 8),

                                Text(
                                  "Products: $productsStr",
                                  style: GoogleFonts.comicNeue(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.black87,
                                  ),
                                ),

                                Divider(
                                  color: _cardBorder(status),
                                  thickness: 1.5,
                                  height: 20,
                                ),

                                // ── Amount Row ──
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    _amountCell(
                                      "Total Amount",
                                      "PKR ${totalAmount.toStringAsFixed(0)}",
                                      Colors.black,
                                    ),
                                    _amountCell(
                                      "Total Paid",
                                      "PKR ${paidAmount.toStringAsFixed(0)}",
                                      Colors.green.shade800,
                                      align: CrossAxisAlignment.center,
                                    ),
                                    _amountCell(
                                      "Remaining",
                                      "PKR ${remaining.toStringAsFixed(0)}",
                                      remaining > 0
                                          ? Colors.red.shade800
                                          : Colors.green.shade800,
                                      align: CrossAxisAlignment.end,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      });
                    },
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  // ── Filter Chip Widget ──
  Widget _filterChip(String label) {
    final bool selected = _statusFilter == label;
    Color chipColor;
    switch (label) {
      case 'Paid':
        chipColor = Colors.green.shade800;
        break;
      case 'Partial':
        chipColor = Colors.blue.shade800;
        break;
      case 'Unpaid':
        chipColor = Colors.red.shade800;
        break;
      default:
        chipColor = Colors.black;
    }

    return GestureDetector(
      onTap: () => setState(() => _statusFilter = label),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? chipColor : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: chipColor, width: 2),
        ),
        child: Text(
          label,
          style: GoogleFonts.comicNeue(
            color: selected ? Colors.white : chipColor,
            fontWeight: FontWeight.w900,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  // ── Amount Cell Widget ──
  Widget _amountCell(
    String label,
    String value,
    Color valueColor, {
    CrossAxisAlignment align = CrossAxisAlignment.start,
  }) {
    return Column(
      crossAxisAlignment: align,
      children: [
        Text(
          label,
          style: GoogleFonts.comicNeue(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: Colors.black54,
          ),
        ),
        Text(
          value,
          style: GoogleFonts.comicNeue(
            fontSize: 17,
            fontWeight: FontWeight.w900,
            color: valueColor,
          ),
        ),
      ],
    );
  }
}
