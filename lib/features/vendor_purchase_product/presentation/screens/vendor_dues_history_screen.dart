import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class VendorPaymentsScreen extends StatefulWidget {
  const VendorPaymentsScreen({super.key});

  @override
  State<VendorPaymentsScreen> createState() => _VendorPaymentsScreenState();
}

class _VendorPaymentsScreenState extends State<VendorPaymentsScreen> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ✅ FILTERS
  String selectedVendorFilter = 'All Vendors';
  String filterStatus = 'All'; // All, Overdue, Pay Today, Upcoming, Paid
  String timeFilter = 'All Time'; // Today, This Week, This Month, All Time
  String sortBy = 'Closest First (Today -> Future)'; // Naya Sorting Logic

  // Calculate total pending from the filtered list
  double calculateTotalPending(List<QueryDocumentSnapshot> docs) {
    double total = 0;
    for (var doc in docs) {
      var data = doc.data() as Map<String, dynamic>;
      bool isPaid = data['isPaid'] == true;
      if (!isPaid) {
        total += double.tryParse(data['amountDue']?.toString() ?? '0') ?? 0.0;
      }
    }
    return total;
  }

  // ✅ FULL DETAILS MODAL
  void _showFullDetails(
    Map<String, dynamic> data,
    String formattedDate,
    String status,
  ) {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(25),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: Colors.black, width: 3),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: FutureBuilder<DocumentSnapshot>(
          future: _db
              .collection('vendor_purchases')
              .doc(data['purchaseId'])
              .get(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(color: Colors.black),
              );
            }

            double totalBill = 0.0;
            double cashPaid = 0.0;
            double remaining = 0.0;

            if (snapshot.hasData && snapshot.data!.exists) {
              var purchaseData = snapshot.data!.data() as Map<String, dynamic>;
              totalBill =
                  (purchaseData['totalBillAmount'] ??
                          purchaseData['totalPrice'] ??
                          0.0)
                      .toDouble();
              cashPaid = (purchaseData['cashPaid'] ?? 0.0).toDouble();
              remaining = (purchaseData['remainingBalance'] ?? 0.0).toDouble();
            }

            return SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 60,
                      height: 6,
                      decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 25),
                  Text(
                    "TRANSACTION DETAILS",
                    style: GoogleFonts.comicNeue(
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      color: Colors.black,
                    ),
                  ),
                  const Divider(color: Colors.black, thickness: 2, height: 30),

                  // Main Info
                  _detailRow(
                    "Bill Number:",
                    data['billNumber']?.toString() ?? "N/A",
                  ),
                  _detailRow(
                    "Vendor Name:",
                    data['vendorName']?.toString() ?? "Unknown Vendor",
                  ),
                  _detailRow(
                    "Product(s):",
                    data['productName']?.toString() ?? "Unknown Product",
                  ),

                  const Divider(color: Colors.black, thickness: 2, height: 30),
                  Text(
                    "💰 PURCHASE SUMMARY",
                    style: GoogleFonts.comicNeue(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 10),
                  _detailRow(
                    "Total Bill:",
                    "PKR ${totalBill.toStringAsFixed(0)}",
                  ),
                  _detailRow(
                    "Advance / Paid:",
                    "PKR ${cashPaid.toStringAsFixed(0)}",
                  ),
                  _detailRow(
                    "Remaining Balance:",
                    "PKR ${remaining.toStringAsFixed(0)}",
                  ),

                  const Divider(color: Colors.black, thickness: 2, height: 30),
                  Text(
                    "📅 INSTALLMENT INFO",
                    style: GoogleFonts.comicNeue(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 10),
                  _detailRow(
                    "Installment Due:",
                    "PKR ${double.tryParse(data['amountDue']?.toString() ?? '0') ?? 0.0}",
                  ),
                  _detailRow("Due Date:", formattedDate),
                  _detailRow("Status:", status.toUpperCase()),

                  const SizedBox(height: 20),
                  Text(
                    "Admin Note:",
                    style: GoogleFonts.comicNeue(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      color: Colors.yellow.shade200,
                      border: Border.all(color: Colors.black, width: 2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      data['note']?.toString() ?? "No extra details available.",
                      style: GoogleFonts.comicNeue(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                  ),

                  const SizedBox(height: 35),
                  SizedBox(
                    width: double.infinity,
                    height: 60,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: () => Get.back(),
                      child: Text(
                        "CLOSE DETAILS",
                        style: GoogleFonts.comicNeue(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
      isScrollControlled: true,
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: GoogleFonts.comicNeue(
                fontSize: 20,
                color: Colors.black,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: GoogleFonts.comicNeue(
                fontSize: 22,
                color: Colors.black,
                fontWeight: FontWeight.w900,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          "Vendor Dues & Payments",
          style: GoogleFonts.comicNeue(
            fontSize: 26,
            fontWeight: FontWeight.w900,
            color: Colors.black,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 2,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black, size: 30),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _db.collection('vendor_dues').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error loading data.',
                style: GoogleFonts.comicNeue(
                  fontSize: 22,
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                ),
              ),
            );
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.black),
            );
          }

          var allDocs = snapshot.data!.docs;
          DateTime now = DateTime.now();
          DateTime startOfDay = DateTime(now.year, now.month, now.day);

          Set<String> vendorNamesSet = {};
          for (var doc in allDocs) {
            String vName =
                (doc.data() as Map<String, dynamic>)['vendorName']
                    ?.toString() ??
                'Unknown Vendor';
            vendorNamesSet.add(vName);
          }
          List<String> vendorDropdownItems = [
            'All Vendors',
            ...vendorNamesSet.toList()..sort(),
          ];

          double totalOverdue = 0;
          double totalToday = 0;
          double totalUpcoming = 0;
          double totalPaid = 0;

          // ✅ APPLY FILTERS
          var filteredList = allDocs.where((doc) {
            var data = doc.data() as Map<String, dynamic>;

            String vName = data['vendorName']?.toString() ?? 'Unknown Vendor';
            Timestamp? ts = data['dueDate'] as Timestamp?;
            DateTime dueDate = ts?.toDate() ?? DateTime.now();
            bool isPaid = data['isPaid'] == true;

            String docStatus = "Upcoming";
            if (isPaid) {
              docStatus = "Paid";
            } else if (dueDate.isBefore(startOfDay)) {
              docStatus = "Overdue";
            } else if (dueDate.year == now.year &&
                dueDate.month == now.month &&
                dueDate.day == now.day) {
              docStatus = "Pay Today";
            }

            if (selectedVendorFilter != 'All Vendors' &&
                vName != selectedVendorFilter)
              return false;
            if (filterStatus != 'All' && docStatus != filterStatus)
              return false;

            bool matchesTime = true;
            if (timeFilter == 'Today') {
              matchesTime =
                  dueDate.year == now.year &&
                  dueDate.month == now.month &&
                  dueDate.day == now.day;
            } else if (timeFilter == 'This Week') {
              matchesTime =
                  dueDate.isAfter(
                    startOfDay.subtract(const Duration(days: 7)),
                  ) &&
                  dueDate.isBefore(startOfDay.add(const Duration(days: 7)));
            } else if (timeFilter == 'This Month') {
              matchesTime =
                  dueDate.month == now.month && dueDate.year == now.year;
            }
            if (!matchesTime) return false;

            double amount =
                double.tryParse(data['amountDue']?.toString() ?? '0') ?? 0.0;
            if (docStatus == "Overdue") totalOverdue += amount;
            if (docStatus == "Pay Today") totalToday += amount;
            if (docStatus == "Upcoming") totalUpcoming += amount;
            if (docStatus == "Paid") totalPaid += amount;

            return true;
          }).toList();

          // ✅ EXACT SORTING LOGIC ADDED
          List<String> sortOptions = [
            'Closest First (Today -> Future)',
            'Farthest First (Future -> Today)',
            'Highest to Lowest Amount',
            'Lowest to Highest Amount',
          ];

          if (!sortOptions.contains(sortBy)) {
            sortBy = sortOptions.first;
          }

          filteredList.sort((a, b) {
            var dataA = a.data() as Map<String, dynamic>;
            var dataB = b.data() as Map<String, dynamic>;

            // Naye Amount filters ki sorting logic
            if (sortBy == 'Highest to Lowest Amount' ||
                sortBy == 'Lowest to Highest Amount') {
              double amtA =
                  double.tryParse(dataA['amountDue']?.toString() ?? '0') ?? 0.0;
              double amtB =
                  double.tryParse(dataB['amountDue']?.toString() ?? '0') ?? 0.0;
              if (sortBy == 'Highest to Lowest Amount') {
                return amtB.compareTo(amtA);
              } else {
                return amtA.compareTo(amtB);
              }
            }
            // Purani Date filters ki sorting logic
            else {
              Timestamp? tsA = dataA['dueDate'] as Timestamp?;
              Timestamp? tsB = dataB['dueDate'] as Timestamp?;
              DateTime dateA = tsA?.toDate() ?? DateTime.now();
              DateTime dateB = tsB?.toDate() ?? DateTime.now();

              if (sortBy == 'Closest First (Today -> Future)') {
                return dateA.compareTo(dateB);
              } else {
                return dateB.compareTo(dateA);
              }
            }
          });

          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Column(
                  children: [
                    // ✅ FILTER UI SECTION
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(15),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        border: Border(
                          bottom: BorderSide(color: Colors.black, width: 2.5),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildDropdown(
                            "Select Vendor",
                            selectedVendorFilter,
                            vendorDropdownItems,
                            (val) =>
                                setState(() => selectedVendorFilter = val!),
                          ),
                          const SizedBox(height: 15),
                          Row(
                            children: [
                              Expanded(
                                child: _buildDropdown(
                                  "Status",
                                  filterStatus,
                                  [
                                    "All",
                                    "Overdue",
                                    "Pay Today",
                                    "Upcoming",
                                    "Paid",
                                  ],
                                  (val) => setState(() => filterStatus = val!),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _buildDropdown(
                                  "Timeframe",
                                  timeFilter,
                                  [
                                    "All Time",
                                    "Today",
                                    "This Week",
                                    "This Month",
                                  ],
                                  (val) => setState(() => timeFilter = val!),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 15),
                          // ✅ ONLY 4 SORTING OPTIONS
                          _buildDropdown(
                            "Sort By",
                            sortBy,
                            sortOptions,
                            (val) => setState(() => sortBy = val!),
                          ),
                        ],
                      ),
                    ),

                    // ✅ SUMMARY CARD
                    Container(
                      margin: const EdgeInsets.all(15),
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade200,
                        border: Border.all(color: Colors.black, width: 3),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black26,
                            offset: Offset(2, 4),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "DASHBOARD SUMMARY",
                            style: GoogleFonts.comicNeue(
                              color: Colors.black,
                              fontSize: 24,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const Divider(
                            color: Colors.black,
                            thickness: 2,
                            height: 20,
                          ),
                          _summaryRow(
                            "OVERDUE (LATE):",
                            totalOverdue,
                            Colors.red.shade900,
                          ),
                          _summaryRow(
                            "PAY TODAY:",
                            totalToday,
                            Colors.orange.shade900,
                          ),
                          _summaryRow(
                            "UPCOMING DUES:",
                            totalUpcoming,
                            Colors.blue.shade900,
                          ),
                          const Divider(
                            color: Colors.black,
                            thickness: 1,
                            height: 20,
                          ),
                          _summaryRow(
                            "ALREADY PAID:",
                            totalPaid,
                            Colors.green.shade900,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              if (filteredList.isEmpty)
                SliverToBoxAdapter(
                  child: Container(
                    height: 200,
                    alignment: Alignment.center,
                    child: Text(
                      "No Data Found For Selected Filters.",
                      style: GoogleFonts.comicNeue(
                        fontSize: 24,
                        color: Colors.black,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 15,
                    vertical: 5,
                  ),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      var data =
                          filteredList[index].data() as Map<String, dynamic>;

                      String docId = filteredList[index].id;
                      String vName =
                          data['vendorName']?.toString() ?? 'Unknown Vendor';
                      String pName =
                          data['productName']?.toString() ?? 'Unknown Product';
                      String billNum = data['billNumber']?.toString() ?? 'N/A';
                      double amount =
                          double.tryParse(
                            data['amountDue']?.toString() ?? '0',
                          ) ??
                          0.0;
                      bool isPaid = data['isPaid'] == true;

                      Timestamp? ts = data['dueDate'] as Timestamp?;
                      DateTime dueDate = ts?.toDate() ?? DateTime.now();
                      String formattedDate = DateFormat(
                        'dd MMMM, yyyy',
                      ).format(dueDate);

                      bool isOverdue = !isPaid && dueDate.isBefore(startOfDay);
                      bool isToday =
                          !isPaid &&
                          dueDate.year == now.year &&
                          dueDate.month == now.month &&
                          dueDate.day == now.day;

                      String statusText = "UPCOMING";
                      Color statusColor = Colors.blue.shade900;
                      Color statusBg = Colors.blue.shade100;

                      if (isPaid) {
                        statusText = "PAID";
                        statusColor = Colors.green.shade900;
                        statusBg = Colors.green.shade100;
                      } else if (isOverdue) {
                        statusText = "OVERDUE";
                        statusColor = Colors.red.shade900;
                        statusBg = Colors.red.shade100;
                      } else if (isToday) {
                        statusText = "PAY TODAY";
                        statusColor = Colors.orange.shade900;
                        statusBg = Colors.orange.shade100;
                      }

                      return GestureDetector(
                        onTap: () =>
                            _showFullDetails(data, formattedDate, statusText),
                        child: Card(
                          color: Colors.white,
                          elevation: 5,
                          margin: const EdgeInsets.only(bottom: 20),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: const BorderSide(
                              color: Colors.black,
                              width: 2.5,
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(20.0),
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
                                            vName,
                                            style: GoogleFonts.comicNeue(
                                              fontSize: 24,
                                              fontWeight: FontWeight.w900,
                                              color: Colors.black,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          Text(
                                            "Bill #: $billNum",
                                            style: GoogleFonts.comicNeue(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.black54,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: statusBg,
                                        border: Border.all(
                                          color: statusColor,
                                          width: 2.5,
                                        ),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        statusText,
                                        style: GoogleFonts.comicNeue(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w900,
                                          color: statusColor,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const Divider(
                                  color: Colors.black,
                                  thickness: 2,
                                  height: 25,
                                ),
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      flex: 2,
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            "Product:",
                                            style: GoogleFonts.comicNeue(
                                              fontSize: 18,
                                              color: Colors.black,
                                              fontWeight: FontWeight.w900,
                                            ),
                                          ),
                                          Text(
                                            pName,
                                            style: GoogleFonts.comicNeue(
                                              fontSize: 20,
                                              color: Colors.black,
                                              fontWeight: FontWeight.w900,
                                            ),
                                          ),
                                          const SizedBox(height: 10),
                                          Text(
                                            "Due Date:",
                                            style: GoogleFonts.comicNeue(
                                              fontSize: 18,
                                              color: Colors.black,
                                              fontWeight: FontWeight.w900,
                                            ),
                                          ),
                                          Text(
                                            formattedDate,
                                            style: GoogleFonts.comicNeue(
                                              fontSize: 20,
                                              fontWeight: FontWeight.w900,
                                              color: isOverdue
                                                  ? Colors.red.shade900
                                                  : Colors.black,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Expanded(
                                      flex: 1,
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.end,
                                        children: [
                                          Text(
                                            "Amount",
                                            style: GoogleFonts.comicNeue(
                                              fontSize: 18,
                                              color: Colors.black,
                                              fontWeight: FontWeight.w900,
                                            ),
                                          ),
                                          Text(
                                            "PKR ${amount.toStringAsFixed(0)}",
                                            style: GoogleFonts.comicNeue(
                                              fontSize: 26,
                                              fontWeight: FontWeight.w900,
                                              color: Colors.black,
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
                        ),
                      );
                    }, childCount: filteredList.length),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _summaryRow(String label, double amount, Color amtColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.comicNeue(
              color: Colors.black,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          Text(
            "PKR ${amount.toStringAsFixed(0)}",
            style: GoogleFonts.comicNeue(
              color: amtColor,
              fontSize: 22,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdown(
    String label,
    String value,
    List<String> items,
    Function(String?) onChanged,
  ) {
    String safeValue = items.contains(value) ? value : items.first;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.comicNeue(
            fontSize: 18,
            fontWeight: FontWeight.w900,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 5),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: Colors.black, width: 2.5),
            borderRadius: BorderRadius.circular(8),
          ),
          child: DropdownButton<String>(
            value: safeValue,
            isExpanded: true,
            icon: const Icon(
              Icons.arrow_drop_down,
              color: Colors.black,
              size: 30,
            ),
            items: items
                .map(
                  (s) => DropdownMenuItem(
                    value: s,
                    child: Text(
                      s,
                      style: GoogleFonts.comicNeue(
                        color: Colors.black,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                )
                .toList(),
            onChanged: onChanged,
            dropdownColor: Colors.white,
            underline: const SizedBox(),
          ),
        ),
      ],
    );
  }
}
