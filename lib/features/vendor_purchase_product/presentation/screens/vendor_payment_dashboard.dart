import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../controller/vendor_payment_controller.dart';
import '../widgets/searchable_selection_field.dart';

class VendorPaymentDashboard extends StatefulWidget {
  const VendorPaymentDashboard({super.key});

  @override
  State<VendorPaymentDashboard> createState() => _VendorPaymentDashboardState();
}

class _VendorPaymentDashboardState extends State<VendorPaymentDashboard>
    with SingleTickerProviderStateMixin {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final VendorPaymentController _paymentController = Get.put(
    VendorPaymentController(),
  );

  late TabController _tabController;

  List<String> cachedVendorList = [];
  List<DocumentSnapshot> cachedVendorDocs = [];

  String? selectedVendorId;
  String? selectedVendorName;
  String? selectedStoreName;
  String? selectedOwnerName;
  double globalTotalRemaining = 0.0;

  String? selectedPurchaseIdForPayment;
  String? selectedBillNumberForPayment;
  double selectedBillRemainingForPayment = 0.0;

  final amountCtrl = TextEditingController();
  final noteCtrl = TextEditingController();
  DateTime paymentDate = DateTime.now();
  String paymentMode = 'Cash';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      setState(() {});
    });
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

  // ✅ FIX: Vendor ka koi bill nahi to proper popup dikhao
  void _openPaymentDialog(List<QueryDocumentSnapshot> activeBills) {
    if (activeBills.isEmpty) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: Colors.black, width: 2.5),
          ),
          title: Row(
            children: [
              const Icon(Icons.info_outline, color: Colors.black, size: 28),
              const SizedBox(width: 10),
              Text(
                "No Pending Bills",
                style: GoogleFonts.comicNeue(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: Colors.black,
                ),
              ),
            ],
          ),
          content: Text(
            "Is vendor ka koi bill pending nahi hai.\nSaare bills already paid hain.",
            style: GoogleFonts.comicNeue(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(
                "OK",
                style: GoogleFonts.comicNeue(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                ),
              ),
            ),
          ],
        ),
      );
      return;
    }

    selectedPurchaseIdForPayment = activeBills.first.id;
    var firstData = activeBills.first.data() as Map<String, dynamic>;

    String bNum = firstData['billNumber']?.toString() ?? 'N/A';
    selectedBillNumberForPayment = bNum == 'null' ? 'N/A' : bNum;
    selectedBillRemainingForPayment = _getCalculatedRemaining(firstData);
    paymentMode = 'Cash';

    Get.bottomSheet(
      Theme(
        data: ThemeData.light().copyWith(canvasColor: Colors.white),
        child: StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              padding: const EdgeInsets.all(25),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: Colors.black, width: 3),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: SingleChildScrollView(
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
                    const SizedBox(height: 20),
                    Text(
                      "MAKE A PAYMENT",
                      style: GoogleFonts.comicNeue(
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                        color: Colors.black,
                      ),
                    ),
                    const Divider(
                      color: Colors.black,
                      thickness: 2,
                      height: 20,
                    ),

                    Text(
                      "Select Bill to Pay:",
                      style: GoogleFonts.comicNeue(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 5),

                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: Colors.black, width: 2.5),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          dropdownColor: Colors.white,
                          isExpanded: true,
                          value: selectedPurchaseIdForPayment,
                          style: const TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.w900,
                            fontSize: 16,
                          ),
                          icon: const Icon(
                            Icons.arrow_drop_down,
                            color: Colors.black,
                            size: 30,
                          ),
                          items: activeBills.map((doc) {
                            var data = doc.data() as Map<String, dynamic>;
                            String dropBNum =
                                data['billNumber']?.toString() ?? 'N/A';
                            if (dropBNum == 'null') dropBNum = 'N/A';
                            double rem = _getCalculatedRemaining(data);
                            return DropdownMenuItem(
                              value: doc.id,
                              child: Text(
                                "Bill #$dropBNum (Rem: PKR $rem)",
                                style: const TextStyle(
                                  color: Colors.black,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            );
                          }).toList(),
                          onChanged: (val) {
                            var selectedDoc = activeBills.firstWhere(
                              (doc) => doc.id == val,
                            );
                            var data =
                                selectedDoc.data() as Map<String, dynamic>;
                            setModalState(() {
                              selectedPurchaseIdForPayment = val;
                              String n =
                                  data['billNumber']?.toString() ?? 'N/A';
                              selectedBillNumberForPayment = n == 'null'
                                  ? 'N/A'
                                  : n;
                              selectedBillRemainingForPayment =
                                  _getCalculatedRemaining(data);
                              amountCtrl.clear();
                            });
                          },
                        ),
                      ),
                    ),

                    const SizedBox(height: 15),
                    Text(
                      "Payment Amount (Max: PKR $selectedBillRemainingForPayment):",
                      style: GoogleFonts.comicNeue(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 5),
                    TextField(
                      controller: amountCtrl,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                      decoration: InputDecoration(
                        prefixText: "PKR ",
                        prefixStyle: const TextStyle(
                          color: Colors.black,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 15,
                          vertical: 12,
                        ),
                        border: OutlineInputBorder(
                          borderSide: const BorderSide(
                            color: Colors.black,
                            width: 2.5,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderSide: const BorderSide(
                            color: Colors.black,
                            width: 2.5,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: const BorderSide(
                            color: Colors.black,
                            width: 3.5,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),

                    const SizedBox(height: 15),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Date:",
                                style: GoogleFonts.comicNeue(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.black,
                                ),
                              ),
                              const SizedBox(height: 5),
                              InkWell(
                                onTap: () async {
                                  DateTime? picked = await showDatePicker(
                                    context: context,
                                    initialDate: paymentDate,
                                    firstDate: DateTime(2000),
                                    lastDate: DateTime(2100),
                                  );
                                  if (picked != null)
                                    setModalState(() => paymentDate = picked);
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 14,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    border: Border.all(
                                      color: Colors.black,
                                      width: 2.5,
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        DateFormat(
                                          'dd MMM, yyyy',
                                        ).format(paymentDate),
                                        style: const TextStyle(
                                          color: Colors.black,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                      const Icon(
                                        Icons.calendar_month,
                                        color: Colors.black,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 15),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Mode:",
                                style: GoogleFonts.comicNeue(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.black,
                                ),
                              ),
                              const SizedBox(height: 5),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  border: Border.all(
                                    color: Colors.black,
                                    width: 2.5,
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<String>(
                                    dropdownColor: Colors.white,
                                    isExpanded: true,
                                    value: paymentMode,
                                    style: const TextStyle(
                                      color: Colors.black,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                    icon: const Icon(
                                      Icons.arrow_drop_down,
                                      color: Colors.black,
                                    ),
                                    items: ["Cash", "Bank Transfer", "Cheque"]
                                        .map(
                                          (e) => DropdownMenuItem(
                                            value: e,
                                            child: Text(
                                              e,
                                              style: const TextStyle(
                                                color: Colors.black,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        )
                                        .toList(),
                                    onChanged: (v) =>
                                        setModalState(() => paymentMode = v!),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 15),
                    Text(
                      "Note (Optional):",
                      style: GoogleFonts.comicNeue(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 5),
                    TextField(
                      controller: noteCtrl,
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 15,
                          vertical: 12,
                        ),
                        border: OutlineInputBorder(
                          borderSide: const BorderSide(
                            color: Colors.black,
                            width: 2.5,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderSide: const BorderSide(
                            color: Colors.black,
                            width: 2.5,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: const BorderSide(
                            color: Colors.black,
                            width: 3.5,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),

                    const SizedBox(height: 25),
                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: Obx(
                        () => ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.black,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          onPressed: _paymentController.isLoading.value
                              ? null
                              : () async {
                                  double amount =
                                      double.tryParse(amountCtrl.text) ?? 0.0;
                                  bool
                                  success = await _paymentController.processPayment(
                                    purchaseId: selectedPurchaseIdForPayment!,
                                    vendorId: selectedVendorId!,
                                    vendorName: selectedVendorName!,
                                    billNumber: selectedBillNumberForPayment!,
                                    totalBillRemaining:
                                        selectedBillRemainingForPayment,
                                    payingAmount: amount,
                                    paymentDate: paymentDate,
                                    paymentMode: paymentMode,
                                    note: noteCtrl.text.isEmpty
                                        ? "Payment towards Bill #$selectedBillNumberForPayment"
                                        : noteCtrl.text,
                                  );
                                  if (success) {
                                    amountCtrl.clear();
                                    noteCtrl.clear();
                                    Navigator.of(context).pop();
                                  }
                                },
                          child: _paymentController.isLoading.value
                              ? const CircularProgressIndicator(
                                  color: Colors.white,
                                )
                              : Text(
                                  "SUBMIT PAYMENT",
                                  style: GoogleFonts.comicNeue(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    // ✅ FIX: Scaffold mein body ko Column + Expanded se wrap karo
    // Taake dono tabs ek hi screen pe fit ho, bahar scroll na ho
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          "Vendor Ledger & Payments",
          style: GoogleFonts.comicNeue(
            fontSize: 22,
            fontWeight: FontWeight.w900,
            color: Colors.black,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 2,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      bottomNavigationBar: selectedVendorId != null
          ? _buildMakePaymentFixedButton()
          : null,
      body: Column(
        children: [
          // ── Vendor Selection (fixed at top, never scrolls) ──
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(
                bottom: BorderSide(color: Colors.black12, width: 1),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (cachedVendorList.isEmpty)
                  const LinearProgressIndicator(color: Colors.black)
                else
                  SearchableSelectionField(
                    label: "Select Vendor to Load Account",
                    hint: "Search Store or Owner...",
                    selectedValue: selectedVendorName,
                    items: cachedVendorList,
                    onSelected: (val) {
                      var v = cachedVendorDocs.firstWhere((e) {
                        var d = e.data() as Map<String, dynamic>;
                        return "${d['storeName'] ?? ''} (${d['ownerName'] ?? ''})" ==
                            val;
                      });
                      var data = v.data() as Map<String, dynamic>;
                      setState(() {
                        selectedVendorName = val;
                        selectedVendorId = v.id;
                        selectedStoreName = data['storeName'] ?? 'Unknown';
                        selectedOwnerName = data['ownerName'] ?? 'Unknown';
                      });
                    },
                  ),
                if (selectedVendorId != null) ...[
                  const SizedBox(height: 10),
                  // Vendor Info Card (compact)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      border: Border.all(
                        color: Colors.blue.shade900,
                        width: 1.5,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "$selectedStoreName",
                                style: GoogleFonts.comicNeue(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.blue.shade900,
                                ),
                              ),
                              Text(
                                "$selectedOwnerName",
                                style: GoogleFonts.comicNeue(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.blue.shade700,
                                ),
                              ),
                            ],
                          ),
                        ),
                        StreamBuilder<DocumentSnapshot>(
                          stream: _db
                              .collection('vendors')
                              .doc(selectedVendorId)
                              .snapshots(),
                          builder: (context, snapshot) {
                            if (!snapshot.hasData) return const SizedBox();
                            var data =
                                snapshot.data!.data() as Map<String, dynamic>?;
                            globalTotalRemaining =
                                (data?['beginningBalance'] ?? 0.0).toDouble();
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: globalTotalRemaining > 0
                                    ? Colors.red.shade50
                                    : Colors.green.shade50,
                                border: Border.all(
                                  color: globalTotalRemaining > 0
                                      ? Colors.red.shade900
                                      : Colors.green.shade900,
                                  width: 1.5,
                                ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                "PAYABLE: PKR ${globalTotalRemaining.toStringAsFixed(0)}",
                                style: GoogleFonts.comicNeue(
                                  color: globalTotalRemaining > 0
                                      ? Colors.red.shade900
                                      : Colors.green.shade900,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),

          // ── Tab Bar (only when vendor selected) ──
          if (selectedVendorId != null)
            Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(
                  bottom: BorderSide(color: Colors.black, width: 2),
                ),
              ),
              child: TabBar(
                controller: _tabController,
                labelColor: Colors.black,
                unselectedLabelColor: Colors.grey,
                labelStyle: GoogleFonts.comicNeue(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
                indicatorColor: Colors.black,
                indicatorWeight: 3,
                tabs: const [
                  Tab(text: "PENDING BILLS"),
                  Tab(text: "LEDGER HISTORY"),
                ],
              ),
            ),

          // ── Tab Content fills remaining screen space ──
          Expanded(
            child: selectedVendorId == null
                ? Center(
                    child: Text(
                      "Please select a vendor first.",
                      style: GoogleFonts.comicNeue(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: Colors.black54,
                      ),
                    ),
                  )
                : _tabController.index == 0
                ? _buildPendingBillsTab()
                : _buildLedgerTab(),
          ),
        ],
      ),
    );
  }

  Widget _buildMakePaymentFixedButton() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.black, width: 2)),
      ),
      child: StreamBuilder<QuerySnapshot>(
        stream: _db
            .collection('vendor_purchases')
            .where('vendorId', isEqualTo: selectedVendorId)
            .snapshots(),
        builder: (context, snap) {
          List<QueryDocumentSnapshot> active = [];
          if (snap.hasData) {
            active = snap.data!.docs
                .where(
                  (d) =>
                      _getCalculatedRemaining(
                        d.data() as Map<String, dynamic>,
                      ) >
                      0.01,
                )
                .toList();
            active.sort((a, b) {
              DateTime dA = _parseDate((a.data() as Map)['date']);
              DateTime dB = _parseDate((b.data() as Map)['date']);
              return dA.compareTo(dB);
            });
          }
          // ✅ FIX: active.isEmpty ho to bhi button enabled rakho,
          // taake popup dikhe. Disabled mat karo silently.
          return ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green.shade900,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: const BorderSide(color: Colors.black, width: 2),
              ),
              elevation: 4,
            ),
            icon: const Icon(Icons.payment, color: Colors.white, size: 26),
            label: Text(
              "MAKE A PAYMENT",
              style: GoogleFonts.comicNeue(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.5,
              ),
            ),
            onPressed: () => _openPaymentDialog(active),
          );
        },
      ),
    );
  }

  // ══════════════════════════════════════════════════════
  // TAB 1: PENDING BILLS
  // ══════════════════════════════════════════════════════
  Widget _buildPendingBillsTab() {
    return StreamBuilder<QuerySnapshot>(
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
                fontSize: 18,
              ),
            ),
          );
        if (snapshot.connectionState == ConnectionState.waiting)
          return const Center(
            child: CircularProgressIndicator(color: Colors.black),
          );

        var allBills = snapshot.data!.docs.toList();

        if (allBills.isEmpty) {
          return Center(
            child: Text(
              "No Bills Found.",
              style: GoogleFonts.comicNeue(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: Colors.black,
              ),
            ),
          );
        }

        var pendingBills = allBills.where((doc) {
          return _getCalculatedRemaining(doc.data() as Map<String, dynamic>) >
              0.01;
        }).toList();

        var paidBills = allBills.where((doc) {
          return _getCalculatedRemaining(doc.data() as Map<String, dynamic>) <=
              0.01;
        }).toList();

        pendingBills.sort((a, b) {
          DateTime dA = _parseDate((a.data() as Map)['date']);
          DateTime dB = _parseDate((b.data() as Map)['date']);
          return dA.compareTo(dB);
        });

        return SingleChildScrollView(
          child: Column(
            children: [
              if (pendingBills.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
                  child: Text(
                    "PENDING BILLS (${pendingBills.length})",
                    style: GoogleFonts.comicNeue(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: Colors.red.shade900,
                    ),
                  ),
                ),
                ListView.builder(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: pendingBills.length,
                  itemBuilder: (context, index) {
                    return _buildBillCard(pendingBills[index], isPaid: false);
                  },
                ),
              ],
              if (paidBills.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
                  child: Text(
                    "PAID BILLS (${paidBills.length})",
                    style: GoogleFonts.comicNeue(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: Colors.green.shade900,
                    ),
                  ),
                ),
                ListView.builder(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: paidBills.length,
                  itemBuilder: (context, index) {
                    return _buildBillCard(paidBills[index], isPaid: true);
                  },
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildBillCard(QueryDocumentSnapshot billDoc, {required bool isPaid}) {
    var billData = billDoc.data() as Map<String, dynamic>;

    String billNum = billData['billNumber']?.toString() ?? 'N/A';
    if (billNum == 'null') billNum = 'N/A';

    double totalAmount =
        double.tryParse(
          billData['totalBillAmount']?.toString() ??
              billData['totalPrice']?.toString() ??
              '0',
        ) ??
        0.0;
    double remaining = _getCalculatedRemaining(billData);
    double totalPaid = totalAmount - remaining;
    DateTime billDate = _parseDate(billData['date']);

    List items = billData['items'] ?? [];
    String productsStr = items.isNotEmpty
        ? items.map((e) => e['productName']).join(", ")
        : "N/A";

    String storeName = billData['storeName'] ?? selectedStoreName ?? 'N/A';
    String ownerName = billData['ownerName'] ?? selectedOwnerName ?? 'N/A';

    return Card(
      color: isPaid ? Colors.green.shade50 : Colors.white,
      elevation: 3,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isPaid ? Colors.green.shade900 : Colors.black,
          width: 2,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Bill Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Bill #: $billNum",
                        style: GoogleFonts.comicNeue(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color: Colors.black,
                        ),
                      ),
                      Text(
                        "$storeName | $ownerName",
                        style: GoogleFonts.comicNeue(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: isPaid
                        ? Colors.green.shade900
                        : Colors.orange.shade900,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    isPaid ? "PAID" : "PENDING",
                    style: GoogleFonts.comicNeue(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              "Products: $productsStr",
              style: GoogleFonts.comicNeue(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            Text(
              "Date: ${DateFormat('dd MMM, yyyy').format(billDate)}",
              style: GoogleFonts.comicNeue(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const Divider(color: Colors.black26, thickness: 1, height: 16),

            // Amount Summary
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _amtChip("Total", totalAmount.toStringAsFixed(0), Colors.black),
                _amtChip(
                  "Paid",
                  totalPaid.toStringAsFixed(0),
                  Colors.green.shade900,
                ),
                if (!isPaid)
                  _amtChip(
                    "Remaining",
                    remaining.toStringAsFixed(0),
                    Colors.red.shade900,
                  ),
              ],
            ),
            const SizedBox(height: 12),

            Text(
              "Payment Schedule:",
              style: GoogleFonts.comicNeue(
                fontSize: 15,
                fontWeight: FontWeight.w900,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 6),

            // ✅ FIX: Dues table — properly show actual paid per row
            StreamBuilder<QuerySnapshot>(
              stream: _db
                  .collection('vendor_dues')
                  .where('purchaseId', isEqualTo: billDoc.id)
                  .snapshots(),
              builder: (context, duesSnap) {
                if (!duesSnap.hasData) return const SizedBox();

                var dues = duesSnap.data!.docs.toList();
                dues.sort((a, b) {
                  DateTime dA = _parseDate((a.data() as Map)['dueDate']);
                  DateTime dB = _parseDate((b.data() as Map)['dueDate']);
                  return dA.compareTo(dB);
                });

                if (dues.isEmpty) return const SizedBox();

                // ✅ FIX: originalAmountDue = 0 wali row ko advance row treat karo
                // Actual paidAmount jo Firestore mein stored hai wahi directly dikhao
                // (controller ne already correct distribute kiya hai)
                double totalRemainingFromDues = 0.0;
                List<Map<String, dynamic>> dueRows = [];

                for (var doc in dues) {
                  var d = doc.data() as Map<String, dynamic>;

                  // ✅ originalAmountDue prefer karo, fallback amountDue
                  double original =
                      (d['originalAmountDue'] ?? d['amountDue'] ?? 0.0)
                          .toDouble();

                  // ✅ paidAmount directly from Firestore — controller ne sahi store kiya hai
                  double paid = (d['paidAmount'] ?? 0.0).toDouble();

                  // ✅ Agar original = 0 (advance row), to remaining = 0
                  double remainingDue = original <= 0
                      ? 0.0
                      : (original - paid).clamp(0.0, double.infinity);

                  totalRemainingFromDues += remainingDue;

                  dueRows.add({
                    'date': _parseDate(d['dueDate']),
                    'original': original,
                    'paid': paid,
                    'remaining': remainingDue,
                    'isPaid': d['isPaid'] == true || remainingDue <= 0.01,
                    'isAdvance': original <= 0.01,
                  });
                }

                return Column(
                  children: [
                    // ✅ FIX: Table responsive — LayoutBuilder se width fix karo
                    LayoutBuilder(
                      builder: (ctx, constraints) {
                        // Table ko screen width mein fit karo
                        double tableWidth = constraints.maxWidth;

                        // Column widths proportionally distribute
                        double dateW = tableWidth * 0.23;
                        double dayW = tableWidth * 0.19;
                        double origW = tableWidth * 0.22;
                        double paidW = tableWidth * 0.20;
                        double statusW = tableWidth * 0.12;

                        return Container(
                          width: tableWidth,
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.black, width: 1.5),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Column(
                            children: [
                              // Header Row
                              _tableHeaderRow(
                                dateW,
                                dayW,
                                origW,
                                paidW,
                                statusW,
                              ),
                              // Data Rows
                              ...dueRows.map((row) {
                                return _tableDueRow(
                                  row: row,
                                  dateW: dateW,
                                  dayW: dayW,
                                  origW: origW,
                                  paidW: paidW,
                                  statusW: statusW,
                                );
                              }),
                            ],
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 8),
                    // Total Remaining
                    Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 8,
                        horizontal: 10,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        border: Border.all(color: Colors.black, width: 1.5),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Total Remaining:",
                            style: GoogleFonts.comicNeue(
                              fontSize: 15,
                              fontWeight: FontWeight.w900,
                              color: Colors.black,
                            ),
                          ),
                          Text(
                            "PKR ${totalRemainingFromDues.toStringAsFixed(0)}",
                            style: GoogleFonts.comicNeue(
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              color: totalRemainingFromDues > 0
                                  ? Colors.red.shade900
                                  : Colors.green.shade900,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // ── Table Header Row ──
  Widget _tableHeaderRow(
    double dateW,
    double dayW,
    double origW,
    double paidW,
    double statusW,
  ) {
    final hStyle = GoogleFonts.comicNeue(
      fontWeight: FontWeight.w900,
      color: Colors.white,
      fontSize: 12,
    );
    return Container(
      decoration: const BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(4),
          topRight: Radius.circular(4),
        ),
      ),
      child: Row(
        children: [
          _headerCell("Date", dateW, hStyle),
          _vDivider(),
          _headerCell("Day", dayW, hStyle),
          _vDivider(),
          _headerCell("Due", origW, hStyle),
          _vDivider(),
          _headerCell("Paid", paidW, hStyle),
          _vDivider(),
          _headerCell("Status", statusW, hStyle),
        ],
      ),
    );
  }

  Widget _headerCell(String text, double width, TextStyle style) {
    return SizedBox(
      width: width,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        child: Text(
          text,
          style: style,
          textAlign: TextAlign.center,
          maxLines: 1,
        ),
      ),
    );
  }

  Widget _vDivider() => Container(width: 1, height: 38, color: Colors.white30);

  // ── Table Data Row ──
  Widget _tableDueRow({
    required Map<String, dynamic> row,
    required double dateW,
    required double dayW,
    required double origW,
    required double paidW,
    required double statusW,
  }) {
    DateTime date = row['date'];
    String day = DateFormat('EEE').format(date); // Short day e.g. "Mon"
    double original = row['original'];
    double paid = row['paid'];
    double remainingDue = row['remaining'];
    bool isPaidRow = row['isPaid'];
    bool isAdvance = row['isAdvance'];

    String status;
    Color statusColor;
    Color rowBg;

    if (isAdvance) {
      // Advance row — original=0, show "Advance" label
      status = "Advance";
      statusColor = Colors.green.shade800;
      rowBg = Colors.green.shade50;
    } else if (isPaidRow) {
      status = "Cleared";
      statusColor = Colors.green.shade800;
      rowBg = Colors.green.withOpacity(0.08);
    } else {
      DateTime today = DateTime(
        DateTime.now().year,
        DateTime.now().month,
        DateTime.now().day,
      );
      DateTime dueDay = DateTime(date.year, date.month, date.day);

      if (dueDay.isBefore(today)) {
        status = "Overdue";
        statusColor = Colors.red.shade900;
        rowBg = Colors.red.withOpacity(0.07);
      } else if (dueDay == today) {
        status = "Today";
        statusColor = Colors.orange.shade900;
        rowBg = Colors.orange.withOpacity(0.07);
      } else {
        status = "Pending";
        statusColor = Colors.orange.shade800;
        rowBg = Colors.white;
      }
    }

    final bodyStyle = const TextStyle(
      fontWeight: FontWeight.bold,
      color: Colors.black,
      fontSize: 13,
    );

    return Container(
      decoration: BoxDecoration(
        color: rowBg,
        border: const Border(
          top: BorderSide(color: Colors.black26, width: 0.5),
        ),
      ),
      child: Row(
        children: [
          // Date
          SizedBox(
            width: dateW,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 4),
              child: Text(
                DateFormat('dd MMM yy').format(date),
                style: bodyStyle,
                textAlign: TextAlign.center,
                maxLines: 1,
              ),
            ),
          ),
          _vDataDivider(),
          // Day
          SizedBox(
            width: dayW,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 4),
              child: Text(
                day,
                style: bodyStyle,
                textAlign: TextAlign.center,
                maxLines: 1,
              ),
            ),
          ),
          _vDataDivider(),
          // Original Due
          SizedBox(
            width: origW,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 4),
              child: Text(
                isAdvance ? "Advance" : "PKR ${original.toStringAsFixed(0)}",
                style: bodyStyle.copyWith(
                  color: isAdvance ? Colors.green.shade800 : Colors.black,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
              ),
            ),
          ),
          _vDataDivider(),
          // ✅ Paid Amount — directly from Firestore (already correct)
          SizedBox(
            width: paidW,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 4),
              child: Text(
                paid > 0 ? "PKR ${paid.toStringAsFixed(0)}" : "-",
                style: bodyStyle.copyWith(
                  color: paid > 0 ? Colors.green.shade800 : Colors.black54,
                  fontWeight: paid > 0 ? FontWeight.w900 : FontWeight.normal,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
              ),
            ),
          ),
          _vDataDivider(),
          // Status
          SizedBox(
            width: statusW,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 2),
              child: Text(
                status,
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  color: statusColor,
                  fontSize: 12,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _vDataDivider() => Container(width: 1, color: Colors.black12);

  Widget _amtChip(String label, String amount, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: GoogleFonts.comicNeue(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Colors.black54,
          ),
        ),
        Text(
          "PKR $amount",
          style: GoogleFonts.comicNeue(
            fontSize: 15,
            fontWeight: FontWeight.w900,
            color: color,
          ),
        ),
      ],
    );
  }

  // ══════════════════════════════════════════════════════
  // TAB 2: LEDGER HISTORY
  // ══════════════════════════════════════════════════════
  Widget _buildLedgerTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: _db
          .collection('vendor_purchases')
          .where('vendorId', isEqualTo: selectedVendorId)
          .snapshots(),
      builder: (context, purchaseSnap) {
        return StreamBuilder<QuerySnapshot>(
          stream: _db
              .collection('vendor_payment_history')
              .where('vendorId', isEqualTo: selectedVendorId)
              .snapshots(),
          builder: (context, paymentSnap) {
            if (purchaseSnap.connectionState == ConnectionState.waiting ||
                paymentSnap.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(color: Colors.black),
              );
            }

            var purchases = purchaseSnap.data!.docs.toList();
            var payments = paymentSnap.data!.docs.toList();

            if (purchases.isEmpty) {
              return Center(
                child: Text(
                  "No Ledger History.",
                  style: GoogleFonts.comicNeue(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: Colors.black,
                  ),
                ),
              );
            }

            purchases.sort((a, b) {
              DateTime dA = _parseDate((a.data() as Map)['date']);
              DateTime dB = _parseDate((b.data() as Map)['date']);
              return dB.compareTo(dA);
            });

            return ListView.builder(
              padding: const EdgeInsets.all(12),
              shrinkWrap: true,
              itemCount: purchases.length,
              itemBuilder: (context, index) {
                var pData = purchases[index].data() as Map<String, dynamic>;
                String bNum = pData['billNumber']?.toString() ?? 'N/A';
                if (bNum == 'null') bNum = 'N/A';

                DateTime pDate = _parseDate(pData['date']);
                double billTotal =
                    double.tryParse(
                      pData['totalBillAmount']?.toString() ??
                          pData['totalPrice']?.toString() ??
                          '0',
                    ) ??
                    0.0;
                double totalCashPaidInDB =
                    double.tryParse(pData['cashPaid']?.toString() ?? '0') ??
                    0.0;

                List items = pData['items'] ?? [];
                String productsStr = items.isNotEmpty
                    ? items.map((e) => e['productName']).join(", ")
                    : "N/A";
                String storeName =
                    pData['storeName'] ?? selectedStoreName ?? 'N/A';
                String ownerName =
                    pData['ownerName'] ?? selectedOwnerName ?? 'N/A';

                var billPayments = payments
                    .where((payDoc) {
                      return (payDoc.data() as Map)['billNumber'] == bNum;
                    })
                    .map((e) => e.data() as Map<String, dynamic>)
                    .toList();

                billPayments.sort(
                  (a, b) => _parseDate(
                    a['paymentDate'],
                  ).compareTo(_parseDate(b['paymentDate'])),
                );

                double sumOfManualPayments = 0.0;
                for (var pay in billPayments) {
                  sumOfManualPayments +=
                      double.tryParse(pay['paidAmount']?.toString() ?? '0') ??
                      0.0;
                }

                // ✅ FIX: Advance = totalCashPaidInDB - manual payments
                // Agar negative ho to 0 rakho
                double initialAdvance =
                    (totalCashPaidInDB - sumOfManualPayments).clamp(
                      0.0,
                      double.infinity,
                    );

                List<Map<String, dynamic>> billLedgerRows = [];
                double runningBalance = 0.0;

                runningBalance += billTotal;
                billLedgerRows.add({
                  'date': pDate,
                  'details': "Bill Generated",
                  'debit': billTotal,
                  'credit': 0.0,
                  'balance': runningBalance,
                });

                // ✅ FIX: Advance row sirf tab dikhao jab actually advance tha
                if (initialAdvance > 0.01) {
                  runningBalance -= initialAdvance;
                  billLedgerRows.add({
                    'date': pDate.add(const Duration(seconds: 1)),
                    'details': "Advance Cash Paid",
                    'debit': 0.0,
                    'credit': initialAdvance,
                    'balance': runningBalance,
                  });
                }

                for (var pay in billPayments) {
                  double pAmt =
                      double.tryParse(pay['paidAmount']?.toString() ?? '0') ??
                      0.0;
                  String mode = pay['paymentMode'] ?? 'Cash';
                  DateTime payD = _parseDate(pay['paymentDate']);
                  runningBalance -= pAmt;
                  billLedgerRows.add({
                    'date': payD,
                    'details': "Payment ($mode)",
                    'debit': 0.0,
                    'credit': pAmt,
                    'balance': runningBalance,
                  });
                }

                bool isFullyPaid = runningBalance <= 0.01;

                return Card(
                  color: isFullyPaid ? Colors.green.shade50 : Colors.white,
                  elevation: 3,
                  margin: const EdgeInsets.only(bottom: 20),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color: isFullyPaid ? Colors.green.shade900 : Colors.black,
                      width: 2,
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Bill #$bNum",
                                    style: GoogleFonts.comicNeue(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w900,
                                      color: Colors.black,
                                    ),
                                  ),
                                  Text(
                                    "$storeName | $ownerName",
                                    style: GoogleFonts.comicNeue(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.black54,
                                    ),
                                  ),
                                  Text(
                                    "Products: $productsStr",
                                    style: GoogleFonts.comicNeue(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.black54,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: isFullyPaid
                                    ? Colors.green.shade900
                                    : Colors.orange.shade900,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                isFullyPaid ? "PAID" : "BALANCE",
                                style: GoogleFonts.comicNeue(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const Divider(
                          color: Colors.black26,
                          thickness: 1,
                          height: 14,
                        ),

                        // ✅ Ledger table responsive with LayoutBuilder
                        LayoutBuilder(
                          builder: (ctx, constraints) {
                            double w = constraints.maxWidth;
                            double dW = w * 0.20;
                            double detW = w * 0.27;
                            double drW = w * 0.16;
                            double crW = w * 0.16;
                            double balW = w * 0.16;

                            return Container(
                              width: w,
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: Colors.black,
                                  width: 1.5,
                                ),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Column(
                                children: [
                                  // Header
                                  Container(
                                    decoration: const BoxDecoration(
                                      color: Colors.black,
                                      borderRadius: BorderRadius.only(
                                        topLeft: Radius.circular(4),
                                        topRight: Radius.circular(4),
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        _headerCell(
                                          "Date",
                                          dW,
                                          GoogleFonts.comicNeue(
                                            fontWeight: FontWeight.w900,
                                            color: Colors.white,
                                            fontSize: 12,
                                          ),
                                        ),
                                        _vDivider(),
                                        _headerCell(
                                          "Details",
                                          detW,
                                          GoogleFonts.comicNeue(
                                            fontWeight: FontWeight.w900,
                                            color: Colors.white,
                                            fontSize: 12,
                                          ),
                                        ),
                                        _vDivider(),
                                        _headerCell(
                                          "Debit",
                                          drW,
                                          GoogleFonts.comicNeue(
                                            fontWeight: FontWeight.w900,
                                            color: Colors.white,
                                            fontSize: 12,
                                          ),
                                        ),
                                        _vDivider(),
                                        _headerCell(
                                          "Credit",
                                          crW,
                                          GoogleFonts.comicNeue(
                                            fontWeight: FontWeight.w900,
                                            color: Colors.white,
                                            fontSize: 12,
                                          ),
                                        ),
                                        _vDivider(),
                                        _headerCell(
                                          "Balance",
                                          balW,
                                          GoogleFonts.comicNeue(
                                            fontWeight: FontWeight.w900,
                                            color: Colors.white,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  // Data rows
                                  ...billLedgerRows.map((row) {
                                    bool isBillGen =
                                        row['details'] == "Bill Generated";
                                    return Container(
                                      decoration: BoxDecoration(
                                        color: isBillGen
                                            ? Colors.orange.withOpacity(0.07)
                                            : Colors.white,
                                        border: const Border(
                                          top: BorderSide(
                                            color: Colors.black26,
                                            width: 0.5,
                                          ),
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          SizedBox(
                                            width: dW,
                                            child: Padding(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    vertical: 7,
                                                    horizontal: 4,
                                                  ),
                                              child: Text(
                                                DateFormat(
                                                  'dd-MMM-yy',
                                                ).format(row['date']),
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.black,
                                                  fontSize: 11,
                                                ),
                                                textAlign: TextAlign.center,
                                                maxLines: 1,
                                              ),
                                            ),
                                          ),
                                          _vDataDivider(),
                                          SizedBox(
                                            width: detW,
                                            child: Padding(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    vertical: 7,
                                                    horizontal: 4,
                                                  ),
                                              child: Text(
                                                row['details'],
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.black,
                                                  fontSize: 11,
                                                ),
                                                textAlign: TextAlign.center,
                                                maxLines: 2,
                                              ),
                                            ),
                                          ),
                                          _vDataDivider(),
                                          SizedBox(
                                            width: drW,
                                            child: Padding(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    vertical: 7,
                                                    horizontal: 4,
                                                  ),
                                              child: Text(
                                                row['debit'] > 0
                                                    ? "PKR ${row['debit'].toStringAsFixed(0)}"
                                                    : "-",
                                                style: TextStyle(
                                                  fontWeight: FontWeight.w900,
                                                  color: Colors.red.shade900,
                                                  fontSize: 12,
                                                ),
                                                textAlign: TextAlign.center,
                                                maxLines: 1,
                                              ),
                                            ),
                                          ),
                                          _vDataDivider(),
                                          SizedBox(
                                            width: crW,
                                            child: Padding(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    vertical: 7,
                                                    horizontal: 4,
                                                  ),
                                              child: Text(
                                                row['credit'] > 0
                                                    ? "PKR ${row['credit'].toStringAsFixed(0)}"
                                                    : "-",
                                                style: TextStyle(
                                                  fontWeight: FontWeight.w900,
                                                  color: Colors.green.shade900,
                                                  fontSize: 12,
                                                ),
                                                textAlign: TextAlign.center,
                                                maxLines: 1,
                                              ),
                                            ),
                                          ),
                                          _vDataDivider(),
                                          SizedBox(
                                            width: balW,
                                            child: Padding(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    vertical: 7,
                                                    horizontal: 4,
                                                  ),
                                              child: Text(
                                                "PKR ${row['balance'].toStringAsFixed(0)}",
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.w900,
                                                  color: Colors.black,
                                                  fontSize: 13,
                                                ),
                                                textAlign: TextAlign.center,
                                                maxLines: 1,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  }),
                                ],
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}
