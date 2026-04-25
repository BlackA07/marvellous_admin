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

  @override
  void initState() {
    super.initState();
    _fetchVendors();
  }

  void _fetchVendors() async {
    var snap = await _db.collection('vendors').get();
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

  // ✅ DOUBLE CONFIRMATION LOGIC
  void _confirmDeleteStep1(String purchaseId, String billNumber) {
    Get.defaultDialog(
      title: "Delete Bill?",
      titlePadding: const EdgeInsets.only(top: 20, bottom: 10),
      titleStyle: GoogleFonts.comicNeue(
        fontWeight: FontWeight.w900,
        color: const Color.fromARGB(255, 255, 255, 255),
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
            color: const Color.fromARGB(255, 255, 255, 255),
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
      confirm: ElevatedButton(
        style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade900),
        onPressed: () {
          Get.back(); // Close first popup
          _confirmDeleteStep2(purchaseId, billNumber); // Open second popup
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
                      color: const Color.fromARGB(255, 255, 255, 255),
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
                      Get.back(); // Close dialog
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
            // Vendor Selection Area
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(
                  bottom: BorderSide(color: Colors.black, width: 2.5),
                ),
              ),
              child: cachedVendorList.isEmpty
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
                        });
                      },
                    ),
            ),

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

                  var allBills = snapshot.data!.docs;

                  if (allBills.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 50, bottom: 50),
                      child: Text(
                        "No Bills Found for this Vendor.",
                        style: GoogleFonts.comicNeue(
                          fontSize: 26,
                          fontWeight: FontWeight.w900,
                          color: Colors.black,
                        ),
                      ),
                    );
                  }

                  allBills.sort((a, b) {
                    DateTime dA = _parseDate((a.data() as Map)['date']);
                    DateTime dB = _parseDate((b.data() as Map)['date']);
                    return dB.compareTo(dA); // Show newest bills first
                  });

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
                          ? items.map((e) => e['productName']).join(", ")
                          : "N/A";

                      return Obx(() {
                        return Card(
                          color: Colors.white,
                          elevation: 4,
                          margin: const EdgeInsets.only(bottom: 20),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: const BorderSide(
                              color: Colors.black,
                              width: 2.5,
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(15),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
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
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.black54,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
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
                                              size: 35,
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
                                const SizedBox(height: 10),
                                Text(
                                  "Products: $productsStr",
                                  style: GoogleFonts.comicNeue(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.black87,
                                  ),
                                ),
                                const Divider(
                                  color: Colors.black,
                                  thickness: 1.5,
                                  height: 20,
                                ),

                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          "Total Amount",
                                          style: GoogleFonts.comicNeue(
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.black54,
                                          ),
                                        ),
                                        Text(
                                          "PKR ${totalAmount.toStringAsFixed(0)}",
                                          style: GoogleFonts.comicNeue(
                                            fontSize: 18,
                                            fontWeight: FontWeight.w900,
                                            color: Colors.black,
                                          ),
                                        ),
                                      ],
                                    ),
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                      children: [
                                        Text(
                                          "Total Paid",
                                          style: GoogleFonts.comicNeue(
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.black54,
                                          ),
                                        ),
                                        Text(
                                          "PKR ${paidAmount.toStringAsFixed(0)}",
                                          style: GoogleFonts.comicNeue(
                                            fontSize: 18,
                                            fontWeight: FontWeight.w900,
                                            color: Colors.green.shade900,
                                          ),
                                        ),
                                      ],
                                    ),
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.end,
                                      children: [
                                        Text(
                                          "Remaining",
                                          style: GoogleFonts.comicNeue(
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.black54,
                                          ),
                                        ),
                                        Text(
                                          "PKR ${remaining.toStringAsFixed(0)}",
                                          style: GoogleFonts.comicNeue(
                                            fontSize: 18,
                                            fontWeight: FontWeight.w900,
                                            color: Colors.red.shade900,
                                          ),
                                        ),
                                      ],
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
}
