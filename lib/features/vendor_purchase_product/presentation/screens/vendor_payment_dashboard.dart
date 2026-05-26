import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
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
  String? selectedVendorImage; // Already there
  List<dynamic> selectedCategories = []; // ✅ NEW: For categories
  String? selectedContactPhone; // ✅ NEW: For contact person phone
  double globalTotalRemaining = 0.0;

  bool isFullScreen = false;

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

  // ✅ Bill type ka full label banata hai — e.g. "CREDIT • MONTHLY", "CASH BILL", etc.
  String _getBillTypeLabel(Map<String, dynamic> data) {
    String pMode = data['paymentMode'] ?? '';
    String cType = data['creditType'] ?? '';
    if (pMode == 'Cash') return 'CASH BILL';
    if (pMode == 'Both') {
      if (cType.isNotEmpty) return 'BOTH • ${cType.toUpperCase()}';
      return 'BOTH';
    }
    if (pMode == 'Credit') {
      if (cType.isNotEmpty) return 'CREDIT • ${cType.toUpperCase()}';
      return 'CREDIT';
    }
    return pMode.toUpperCase();
  }

  // ✅ Bill number prefix (e.g. BD-1234, BW-1234, M-1234, CA-1234)
  String _getBillPrefix(Map<String, dynamic> data) {
    String pMode = data['paymentMode'] ?? '';
    String cType = data['creditType'] ?? '';
    if (pMode == 'Cash') return 'CA';
    if (pMode == 'Both') {
      if (cType == 'Daily') return 'BD';
      if (cType == 'Weekly') return 'BW';
      if (cType == 'Monthly') return 'BM';
      return 'BC';
    }
    if (pMode == 'Credit') {
      if (cType == 'Daily') return 'D';
      if (cType == 'Weekly') return 'W';
      if (cType == 'Monthly') return 'M';
      return 'C';
    }
    return 'B';
  }

  Color _getBillTypeColor(Map<String, dynamic> data) {
    String pMode = data['paymentMode'] ?? '';
    if (pMode == 'Cash') return Colors.green.shade800;
    if (pMode == 'Both') return Colors.purple.shade800;
    return Colors.blue.shade800;
  }

  Color _getBillTypeBgColor(Map<String, dynamic> data) {
    String pMode = data['paymentMode'] ?? '';
    if (pMode == 'Cash') return Colors.green.shade100;
    if (pMode == 'Both') return Colors.purple.shade100;
    return Colors.blue.shade100;
  }

  Future<void> _pickImage(
    void Function(void Function()) setModalState,
    Function(String) onImagePicked,
  ) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
    );
    if (pickedFile != null) {
      final bytes = await pickedFile.readAsBytes();
      setModalState(() {
        onImagePicked(base64Encode(bytes));
      });
    }
  }

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

    String selectedPurchaseIdForPayment = activeBills.first.id;
    var firstData = activeBills.first.data() as Map<String, dynamic>;
    String bNum = firstData['billNumber']?.toString() ?? 'N/A';
    String selectedBillNumberForPayment = bNum == 'null' ? 'N/A' : bNum;
    double selectedBillRemainingForPayment = _getCalculatedRemaining(firstData);

    final amountCtrl = TextEditingController();
    final noteCtrl = TextEditingController();
    DateTime paymentDate = DateTime.now();
    String paymentMode = 'Cash';

    String? selectedBankId;
    String? selectedBankName;
    String? bankScreenshotBase64;
    final chequeNumberCtrl = TextEditingController();
    DateTime? chequeDate;

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
                            String prefix = _getBillPrefix(data);
                            String typeLabel = _getBillTypeLabel(data);
                            return DropdownMenuItem(
                              value: doc.id,
                              child: Text(
                                "[$prefix] Bill #$dropBNum • $typeLabel (Rem: PKR ${rem.toStringAsFixed(0)})",
                                style: const TextStyle(
                                  color: Colors.black,
                                  fontWeight: FontWeight.w900,
                                ),
                                overflow: TextOverflow.ellipsis,
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
                              selectedPurchaseIdForPayment = val!;
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
                      "Payment Amount (Max: PKR ${selectedBillRemainingForPayment.toStringAsFixed(0)}):",
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
                                    onChanged: (v) => setModalState(() {
                                      paymentMode = v!;
                                      selectedBankId = null;
                                      selectedBankName = null;
                                      bankScreenshotBase64 = null;
                                      chequeDate = null;
                                      chequeNumberCtrl.clear();
                                    }),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    if (paymentMode == 'Bank Transfer') ...[
                      const SizedBox(height: 15),
                      Container(
                        padding: const EdgeInsets.all(15),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.blue.shade900),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Select Bank",
                              style: GoogleFonts.comicNeue(
                                color: Colors.black,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 5),
                            FutureBuilder<QuerySnapshot>(
                              future: _db
                                  .collection('company_finances')
                                  .doc('main_finances')
                                  .collection('banks')
                                  .get(),
                              builder: (context, snapshot) {
                                if (snapshot.connectionState ==
                                    ConnectionState.waiting)
                                  return const LinearProgressIndicator(
                                    color: Colors.black,
                                  );
                                if (snapshot.hasError)
                                  return Text(
                                    "Error: ${snapshot.error}",
                                    style: const TextStyle(
                                      color: Colors.red,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  );
                                if (!snapshot.hasData ||
                                    snapshot.data!.docs.isEmpty)
                                  return const Text(
                                    "No Banks Found. Please add a bank first.",
                                    style: TextStyle(
                                      color: Colors.red,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  );
                                var bankDocs = snapshot.data!.docs;
                                return Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    border: Border.all(color: Colors.black45),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: DropdownButtonHideUnderline(
                                    child: DropdownButton<String>(
                                      isExpanded: true,
                                      hint: Text(
                                        "Choose a Bank...",
                                        style: GoogleFonts.comicNeue(
                                          color: Colors.black54,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      value: selectedBankId,
                                      items: bankDocs.map((doc) {
                                        var d =
                                            doc.data() as Map<String, dynamic>;
                                        String name =
                                            d['name'] ?? 'Unknown Bank';
                                        if (d['accountTitle'] != null &&
                                            d['accountTitle']
                                                .toString()
                                                .isNotEmpty) {
                                          name = "$name - ${d['accountTitle']}";
                                        }
                                        return DropdownMenuItem(
                                          value: doc.id,
                                          child: Text(
                                            name,
                                            style: GoogleFonts.comicNeue(
                                              color: Colors.black,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        );
                                      }).toList(),
                                      onChanged: (v) {
                                        setModalState(() {
                                          selectedBankId = v;
                                          var bDoc = bankDocs.firstWhere(
                                            (doc) => doc.id == v,
                                          );
                                          var d =
                                              bDoc.data()
                                                  as Map<String, dynamic>;
                                          selectedBankName =
                                              "${d['name']} - ${d['accountTitle']}";
                                        });
                                      },
                                    ),
                                  ),
                                );
                              },
                            ),
                            const SizedBox(height: 15),
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.black,
                              ),
                              onPressed: () => _pickImage(
                                setModalState,
                                (img) => bankScreenshotBase64 = img,
                              ),
                              icon: const Icon(
                                Icons.image,
                                color: Colors.white,
                              ),
                              label: Text(
                                bankScreenshotBase64 == null
                                    ? "Attach Screenshot"
                                    : "Change Screenshot",
                                style: const TextStyle(color: Colors.white),
                              ),
                            ),
                            if (bankScreenshotBase64 != null) ...[
                              const SizedBox(height: 10),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.memory(
                                  base64Decode(bankScreenshotBase64!),
                                  height: 100,
                                  width: double.infinity,
                                  fit: BoxFit.contain,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ] else if (paymentMode == 'Cheque') ...[
                      const SizedBox(height: 15),
                      Container(
                        padding: const EdgeInsets.all(15),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.orange.shade900),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Cheque Number",
                              style: GoogleFonts.comicNeue(
                                fontWeight: FontWeight.bold,
                                color: Colors
                                    .black, // ✅ Ensure color is explicitly black
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 5),
                            TextField(
                              controller: chequeNumberCtrl,
                              style: const TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.bold,
                              ),
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: Colors.white,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 15,
                                  vertical: 10,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                            const SizedBox(height: 15),
                            Text(
                              "Cheque Date",
                              style: GoogleFonts.comicNeue(
                                fontWeight: FontWeight.bold,
                                color: Colors
                                    .black, // ✅ Ensure color is explicitly black
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 5),
                            InkWell(
                              onTap: () async {
                                DateTime? picked = await showDatePicker(
                                  context: context,
                                  initialDate: chequeDate ?? DateTime.now(),
                                  firstDate: DateTime(2000),
                                  lastDate: DateTime(2100),
                                );
                                if (picked != null)
                                  setModalState(() => chequeDate = picked);
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 14,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.black45),
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      chequeDate == null
                                          ? "Select Date"
                                          : DateFormat(
                                              'dd MMM, yyyy',
                                            ).format(chequeDate!),
                                      style: const TextStyle(
                                        color: Colors.black,
                                        fontWeight: FontWeight.bold,
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
                    ],

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
                                  if (paymentMode == 'Bank Transfer' &&
                                      selectedBankId == null) {
                                    Get.snackbar(
                                      "Required",
                                      "Please select a bank.",
                                      backgroundColor: Colors.red,
                                      colorText: Colors.white,
                                    );
                                    return;
                                  }
                                  if (paymentMode == 'Cheque' &&
                                      chequeNumberCtrl.text.isEmpty) {
                                    Get.snackbar(
                                      "Required",
                                      "Please enter cheque number.",
                                      backgroundColor: Colors.red,
                                      colorText: Colors.white,
                                    );
                                    return;
                                  }
                                  bool
                                  success = await _paymentController.processPayment(
                                    purchaseId: selectedPurchaseIdForPayment,
                                    vendorId: selectedVendorId!,
                                    vendorName: selectedVendorName!,
                                    billNumber: selectedBillNumberForPayment,
                                    totalBillRemaining:
                                        selectedBillRemainingForPayment,
                                    payingAmount: amount,
                                    paymentDate: paymentDate,
                                    paymentMode: paymentMode,
                                    note: noteCtrl.text.isEmpty
                                        ? "Payment towards Bill #$selectedBillNumberForPayment"
                                        : noteCtrl.text,
                                    bankId: selectedBankId,
                                    bankName: selectedBankName,
                                    screenshotBase64: bankScreenshotBase64,
                                    chequeNumber: chequeNumberCtrl.text,
                                    chequeDate: chequeDate,
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

  void _openEditPaymentDialog(
    Map<String, dynamic> payData,
    String docId,
    String billNum,
    String purchaseId,
  ) {
    TextEditingController editAmountCtrl = TextEditingController(
      text: payData['paidAmount'].toString(),
    );
    TextEditingController editNoteCtrl = TextEditingController(
      text: payData['note'] ?? '',
    );
    DateTime editDate = _parseDate(payData['paymentDate']);
    String editMode = payData['paymentMode'] ?? 'Cash';

    if (!["Cash", "Bank Transfer", "Cheque"].contains(editMode)) {
      editMode = "Cash";
    }

    String? selectedBankId = payData['bankId'];
    String? selectedBankName = payData['bankName'];
    String? bankScreenshotBase64 = payData['screenshot'];
    TextEditingController chequeNumberCtrl = TextEditingController(
      text: payData['chequeNumber'] ?? '',
    );
    DateTime? chequeDate = payData['chequeDate'] != null
        ? _parseDate(payData['chequeDate'])
        : null;

    double originalAmount =
        double.tryParse(payData['paidAmount'].toString()) ?? 0.0;

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
                      "EDIT PAYMENT",
                      style: GoogleFonts.comicNeue(
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                        color: Colors.blue.shade900,
                      ),
                    ),
                    Text(
                      "Bill #: $billNum",
                      style: GoogleFonts.comicNeue(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black54,
                      ),
                    ),
                    const Divider(
                      color: Colors.black,
                      thickness: 2,
                      height: 20,
                    ),

                    Text(
                      "Payment Amount:",
                      style: GoogleFonts.comicNeue(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 5),
                    TextField(
                      controller: editAmountCtrl,
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
                                    initialDate: editDate,
                                    firstDate: DateTime(2000),
                                    lastDate: DateTime(2100),
                                  );
                                  if (picked != null)
                                    setModalState(() => editDate = picked);
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
                                        ).format(editDate),
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
                                    value: editMode,
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
                                    onChanged: (v) => setModalState(() {
                                      editMode = v!;
                                      if (editMode != 'Bank Transfer') {
                                        selectedBankId = null;
                                        selectedBankName = null;
                                        bankScreenshotBase64 = null;
                                      }
                                      if (editMode != 'Cheque') {
                                        chequeDate = null;
                                        chequeNumberCtrl.clear();
                                      }
                                    }),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    if (editMode == 'Bank Transfer') ...[
                      const SizedBox(height: 15),
                      Container(
                        padding: const EdgeInsets.all(15),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.blue.shade900),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Select Bank",
                              style: GoogleFonts.comicNeue(
                                color: Colors.black,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 5),
                            FutureBuilder<QuerySnapshot>(
                              future: _db
                                  .collection('company_finances')
                                  .doc('main_finances')
                                  .collection('banks')
                                  .get(),
                              builder: (context, snapshot) {
                                if (snapshot.connectionState ==
                                    ConnectionState.waiting)
                                  return const LinearProgressIndicator(
                                    color: Colors.black,
                                  );
                                if (snapshot.hasError)
                                  return Text(
                                    "Error: ${snapshot.error}",
                                    style: const TextStyle(
                                      color: Colors.red,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  );
                                if (!snapshot.hasData ||
                                    snapshot.data!.docs.isEmpty)
                                  return const Text(
                                    "No Banks Found. Please add a bank first.",
                                    style: TextStyle(
                                      color: Colors.red,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  );
                                var bankDocs = snapshot.data!.docs;
                                return Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    border: Border.all(color: Colors.black45),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: DropdownButtonHideUnderline(
                                    child: DropdownButton<String>(
                                      isExpanded: true,
                                      hint: Text(
                                        "Choose a Bank...",
                                        style: GoogleFonts.comicNeue(
                                          color: Colors.black54,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      value: selectedBankId,
                                      items: bankDocs.map((doc) {
                                        var d =
                                            doc.data() as Map<String, dynamic>;
                                        String name =
                                            d['name'] ?? 'Unknown Bank';
                                        if (d['accountTitle'] != null &&
                                            d['accountTitle']
                                                .toString()
                                                .isNotEmpty) {
                                          name = "$name - ${d['accountTitle']}";
                                        }
                                        return DropdownMenuItem(
                                          value: doc.id,
                                          child: Text(
                                            name,
                                            style: GoogleFonts.comicNeue(
                                              color: Colors.black,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        );
                                      }).toList(),
                                      onChanged: (v) {
                                        setModalState(() {
                                          selectedBankId = v;
                                          var bDoc = bankDocs.firstWhere(
                                            (doc) => doc.id == v,
                                          );
                                          var d =
                                              bDoc.data()
                                                  as Map<String, dynamic>;
                                          selectedBankName =
                                              "${d['name']} - ${d['accountTitle']}";
                                        });
                                      },
                                    ),
                                  ),
                                );
                              },
                            ),
                            const SizedBox(height: 15),
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.black,
                              ),
                              onPressed: () => _pickImage(
                                setModalState,
                                (img) => bankScreenshotBase64 = img,
                              ),
                              icon: const Icon(
                                Icons.image,
                                color: Colors.white,
                              ),
                              label: Text(
                                bankScreenshotBase64 == null
                                    ? "Attach Screenshot"
                                    : "Change Screenshot",
                                style: const TextStyle(color: Colors.white),
                              ),
                            ),
                            if (bankScreenshotBase64 != null) ...[
                              const SizedBox(height: 10),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.memory(
                                  base64Decode(bankScreenshotBase64!),
                                  height: 100,
                                  width: double.infinity,
                                  fit: BoxFit.contain,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ] else if (editMode == 'Cheque') ...[
                      const SizedBox(height: 15),
                      Container(
                        padding: const EdgeInsets.all(15),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.orange.shade900),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Cheque Number",
                              style: GoogleFonts.comicNeue(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 5),
                            TextField(
                              controller: chequeNumberCtrl,
                              style: const TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.bold,
                              ),
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: Colors.white,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 15,
                                  vertical: 10,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                            const SizedBox(height: 15),
                            Text(
                              "Cheque Date",
                              style: GoogleFonts.comicNeue(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 5),
                            InkWell(
                              onTap: () async {
                                DateTime? picked = await showDatePicker(
                                  context: context,
                                  initialDate: chequeDate ?? DateTime.now(),
                                  firstDate: DateTime(2000),
                                  lastDate: DateTime(2100),
                                );
                                if (picked != null)
                                  setModalState(() => chequeDate = picked);
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 14,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.black45),
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      chequeDate == null
                                          ? "Select Date"
                                          : DateFormat(
                                              'dd MMM, yyyy',
                                            ).format(chequeDate!),
                                      style: const TextStyle(
                                        color: Colors.black,
                                        fontWeight: FontWeight.bold,
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
                    ],

                    const SizedBox(height: 15),
                    Text(
                      "Note:",
                      style: GoogleFonts.comicNeue(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 5),
                    TextField(
                      controller: editNoteCtrl,
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
                      ),
                    ),

                    const SizedBox(height: 25),
                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: Obx(
                        () => ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue.shade900,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          onPressed: _paymentController.isLoading.value
                              ? null
                              : () async {
                                  double newAmt =
                                      double.tryParse(editAmountCtrl.text) ??
                                      0.0;
                                  if (newAmt <= 0) {
                                    Get.snackbar(
                                      "Invalid",
                                      "Amount must be greater than zero.",
                                      backgroundColor: Colors.red,
                                      colorText: Colors.white,
                                    );
                                    return;
                                  }
                                  if (editMode == 'Bank Transfer' &&
                                      selectedBankId == null) {
                                    Get.snackbar(
                                      "Required",
                                      "Please select a bank.",
                                      backgroundColor: Colors.red,
                                      colorText: Colors.white,
                                    );
                                    return;
                                  }
                                  if (editMode == 'Cheque' &&
                                      chequeNumberCtrl.text.isEmpty) {
                                    Get.snackbar(
                                      "Required",
                                      "Please enter cheque number.",
                                      backgroundColor: Colors.red,
                                      colorText: Colors.white,
                                    );
                                    return;
                                  }
                                  bool success = await _paymentController
                                      .editPaymentTransaction(
                                        paymentDocId: docId,
                                        purchaseId: purchaseId,
                                        vendorId: selectedVendorId!,
                                        vendorName: selectedVendorName!,
                                        billNumber: billNum,
                                        oldAmount: originalAmount,
                                        newAmount: newAmt,
                                        paymentDate: editDate,
                                        paymentMode: editMode,
                                        note: editNoteCtrl.text,
                                        bankId: selectedBankId,
                                        bankName: selectedBankName,
                                        screenshotBase64: bankScreenshotBase64,
                                        chequeNumber: chequeNumberCtrl.text,
                                        chequeDate: chequeDate,
                                      );
                                  if (success) {
                                    Navigator.of(context).pop();
                                  }
                                },
                          child: _paymentController.isLoading.value
                              ? const CircularProgressIndicator(
                                  color: Colors.white,
                                )
                              : Text(
                                  "UPDATE PAYMENT",
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
    return WillPopScope(
      onWillPop: () async {
        if (isFullScreen) {
          setState(() => isFullScreen = false);
          return false;
        }
        return true;
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: isFullScreen
            ? AppBar(
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
                  onPressed: () => setState(() => isFullScreen = false),
                ),
                title: Text(
                  "Full Screen Ledger",
                  style: GoogleFonts.comicNeue(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: Colors.black,
                  ),
                ),
                backgroundColor: Colors.white,
                elevation: 2,
                centerTitle: true,
              )
            : AppBar(
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
            // ── Vendor Selection ──
            if (!isFullScreen)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
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
                            selectedVendorImage =
                                data['image'] ??
                                data['imageUrl'] ??
                                data['profileImage'] ??
                                '';

                            // ✅ NEW: Extracting categories and phone number
                            selectedCategories = data['categories'] ?? [];
                            selectedContactPhone =
                                data['contactPersonPhone'] ?? 'N/A';
                          });
                        },
                      ),
                    if (selectedVendorId != null) ...[
                      const SizedBox(height: 10),
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
                          children: [
                            // ✅ Vendor Image
                            _buildVendorAvatar(),
                            const SizedBox(width: 10),
                            // ... existing code ...
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
                                    "$selectedOwnerName | 📞 $selectedContactPhone", // ✅ Updated to show Phone
                                    style: GoogleFonts.comicNeue(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.blue.shade700,
                                    ),
                                  ),
                                  if (selectedCategories
                                      .isNotEmpty) // ✅ NEW: Showing categories
                                    Text(
                                      "Categories: ${selectedCategories.join(', ')}",
                                      style: GoogleFonts.comicNeue(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black54,
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
                                    snapshot.data!.data()
                                        as Map<String, dynamic>?;
                                globalTotalRemaining =
                                    (data?['beginningBalance'] ?? 0.0)
                                        .toDouble();
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
                                    "PAYABLE:\nPKR ${globalTotalRemaining.toStringAsFixed(0)}",
                                    style: GoogleFonts.comicNeue(
                                      color: globalTotalRemaining > 0
                                          ? Colors.red.shade900
                                          : Colors.green.shade900,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w900,
                                    ),
                                    textAlign: TextAlign.center,
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

            // ── Tab Bar ──
            if (selectedVendorId != null)
              Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  border: Border(
                    bottom: BorderSide(color: Colors.black, width: 2),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
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
                    IconButton(
                      icon: Icon(
                        isFullScreen ? Icons.fullscreen_exit : Icons.fullscreen,
                        color: Colors.black,
                        size: 30,
                      ),
                      onPressed: () {
                        setState(() => isFullScreen = !isFullScreen);
                      },
                    ),
                    const SizedBox(width: 8),
                  ],
                ),
              ),

            // ── Tab Content ──
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
      ),
    );
  }

  // ✅ Vendor Avatar widget
  // ✅ Vendor Avatar widget (Updated for Base64 Profile Images)
  Widget _buildVendorAvatar() {
    bool hasImage =
        selectedVendorImage != null && selectedVendorImage!.isNotEmpty;

    ImageProvider? imageProvider;
    if (hasImage) {
      if (!selectedVendorImage!.startsWith('http')) {
        // Base64 image
        imageProvider = MemoryImage(base64Decode(selectedVendorImage!));
      } else {
        // URL image fallback
        imageProvider = NetworkImage(selectedVendorImage!);
      }
    }

    return CircleAvatar(
      radius: 26,
      backgroundColor: Colors.blue.shade200,
      backgroundImage: imageProvider,
      child: !hasImage
          ? Text(
              (selectedStoreName ?? 'V').substring(0, 1).toUpperCase(),
              style: GoogleFonts.comicNeue(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: Colors.white,
              ),
            )
          : null,
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
          return ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green.shade900,
              minimumSize: const Size(double.infinity, 55),
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

    // ✅ Product images (first item's image)
    String firstProductImage = '';
    if (items.isNotEmpty && items[0]['image'] != null) {
      firstProductImage = items[0]['image'].toString();
    }

    String storeName = billData['storeName'] ?? selectedStoreName ?? 'N/A';
    String ownerName = billData['ownerName'] ?? selectedOwnerName ?? 'N/A';

    String typeLabel = _getBillTypeLabel(billData);
    String prefix = _getBillPrefix(billData);
    Color typeColor = _getBillTypeColor(billData);
    Color typeBgColor = _getBillTypeBgColor(billData);

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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ✅ Product image thumbnail
                if (firstProductImage.isNotEmpty)
                  Container(
                    width: 56,
                    height: 56,
                    margin: const EdgeInsets.only(right: 10),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.black26),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(7),
                      child: Image.network(
                        firstProductImage,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Icon(
                          Icons.inventory_2_outlined,
                          size: 28,
                          color: Colors.black38,
                        ),
                      ),
                    ),
                  ),
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
                      // ✅ Type badge with prefix
                      Container(
                        margin: const EdgeInsets.only(top: 2, bottom: 4),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: typeBgColor,
                          border: Border.all(color: typeColor),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          "[$prefix] $typeLabel",
                          style: GoogleFonts.comicNeue(
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                            color: typeColor,
                          ),
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

                double totalRemainingFromDues = 0.0;
                List<Map<String, dynamic>> dueRows = [];

                for (var doc in dues) {
                  var d = doc.data() as Map<String, dynamic>;
                  double original =
                      (d['originalAmountDue'] ?? d['amountDue'] ?? 0.0)
                          .toDouble();
                  double paid = (d['paidAmount'] ?? 0.0).toDouble();
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
                    LayoutBuilder(
                      builder: (ctx, constraints) {
                        double tableWidth = constraints.maxWidth;
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
                              _tableHeaderRow(
                                dateW,
                                dayW,
                                origW,
                                paidW,
                                statusW,
                              ),
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

  Widget _tableDueRow({
    required Map<String, dynamic> row,
    required double dateW,
    required double dayW,
    required double origW,
    required double paidW,
    required double statusW,
  }) {
    DateTime date = row['date'];
    String day = DateFormat('EEE').format(date);
    double original = row['original'];
    double paid = row['paid'];
    bool isPaidRow = row['isPaid'];
    bool isAdvance = row['isAdvance'];

    String status;
    Color statusColor;
    Color rowBg;

    if (isAdvance) {
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
                var purchaseDoc = purchases[index];
                var pData = purchaseDoc.data() as Map<String, dynamic>;
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

                // ✅ Product image for ledger card
                String firstProductImage = '';
                if (items.isNotEmpty && items[0]['image'] != null) {
                  firstProductImage = items[0]['image'].toString();
                }

                String storeName =
                    pData['storeName'] ?? selectedStoreName ?? 'N/A';
                String ownerName =
                    pData['ownerName'] ?? selectedOwnerName ?? 'N/A';

                String typeLabel = _getBillTypeLabel(pData);
                String prefix = _getBillPrefix(pData);
                Color typeColor = _getBillTypeColor(pData);
                Color typeBgColor = _getBillTypeBgColor(pData);

                var billPayments = payments.where((payDoc) {
                  return (payDoc.data() as Map)['billNumber'] == bNum;
                }).toList();

                billPayments.sort(
                  (a, b) => _parseDate(
                    (a.data() as Map)['paymentDate'],
                  ).compareTo(_parseDate((b.data() as Map)['paymentDate'])),
                );

                double sumOfManualPayments = 0.0;
                for (var payDoc in billPayments) {
                  sumOfManualPayments +=
                      double.tryParse(
                        (payDoc.data() as Map)['paidAmount']?.toString() ?? '0',
                      ) ??
                      0.0;
                }

                double initialAdvance =
                    (totalCashPaidInDB - sumOfManualPayments).clamp(
                      0.0,
                      double.infinity,
                    );

                List<Map<String, dynamic>> billLedgerRows = [];
                double runningBalance = 0.0;

                runningBalance += billTotal;
                billLedgerRows.add({
                  'docId': null,
                  'date': pDate,
                  'details': "Bill Generated",
                  'debit': billTotal,
                  'credit': 0.0,
                  'balance': runningBalance,
                  'rawMap': null,
                });

                if (initialAdvance > 0.01) {
                  runningBalance -= initialAdvance;
                  billLedgerRows.add({
                    'docId': null,
                    'date': pDate.add(const Duration(seconds: 1)),
                    'details': "Advance Cash Paid",
                    'debit': 0.0,
                    'credit': initialAdvance,
                    'balance': runningBalance,
                    'rawMap': null,
                  });
                }

                for (var payDoc in billPayments) {
                  var payMap = payDoc.data() as Map<String, dynamic>;
                  double pAmt =
                      double.tryParse(
                        payMap['paidAmount']?.toString() ?? '0',
                      ) ??
                      0.0;
                  String mode = payMap['paymentMode'] ?? 'Cash';
                  DateTime payD = _parseDate(payMap['paymentDate']);
                  runningBalance -= pAmt;
                  billLedgerRows.add({
                    'docId': payDoc.id,
                    'date': payD,
                    'details': "Payment ($mode)",
                    'debit': 0.0,
                    'credit': pAmt,
                    'balance': runningBalance,
                    'rawMap': payMap,
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
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // ✅ Product image in ledger card
                            if (firstProductImage.isNotEmpty)
                              Container(
                                width: 52,
                                height: 52,
                                margin: const EdgeInsets.only(right: 10),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.black26),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(7),
                                  child: Image.network(
                                    firstProductImage,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => const Icon(
                                      Icons.inventory_2_outlined,
                                      size: 26,
                                      color: Colors.black38,
                                    ),
                                  ),
                                ),
                              ),
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
                                  // ✅ Type badge with prefix in ledger
                                  Container(
                                    margin: const EdgeInsets.only(
                                      top: 2,
                                      bottom: 4,
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: typeBgColor,
                                      border: Border.all(color: typeColor),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      "[$prefix] $typeLabel",
                                      style: GoogleFonts.comicNeue(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w900,
                                        color: typeColor,
                                      ),
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
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
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
                                const SizedBox(height: 8),
                                InkWell(
                                  onTap: () {
                                    Get.defaultDialog(
                                      title: "Delete Bill",
                                      middleText:
                                          "Permanently delete Bill #$bNum?",
                                      textConfirm: "Delete",
                                      confirmTextColor: Colors.white,
                                      buttonColor: Colors.red.shade900,
                                      onConfirm: () {
                                        Get.back();
                                        _paymentController
                                            .deleteBillTransaction(
                                              purchaseId: purchaseDoc.id,
                                              vendorId: selectedVendorId!,
                                              billNumber: bNum,
                                            );
                                      },
                                    );
                                  },
                                  child: const Icon(
                                    Icons.delete_forever,
                                    color: Colors.red,
                                    size: 28,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const Divider(
                          color: Colors.black26,
                          thickness: 1,
                          height: 14,
                        ),

                        LayoutBuilder(
                          builder: (ctx, constraints) {
                            double w = constraints.maxWidth;
                            double dW = w * 0.17;
                            double detW = w * 0.23;
                            double drW = w * 0.15;
                            double crW = w * 0.15;
                            double balW = w * 0.15;
                            double actW = w * 0.10;

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
                                          const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 11,
                                          ),
                                        ),
                                        _vDivider(),
                                        _headerCell(
                                          "Details",
                                          detW,
                                          const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 11,
                                          ),
                                        ),
                                        _vDivider(),
                                        _headerCell(
                                          "Debit",
                                          drW,
                                          const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 11,
                                          ),
                                        ),
                                        _vDivider(),
                                        _headerCell(
                                          "Credit",
                                          crW,
                                          const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 11,
                                          ),
                                        ),
                                        _vDivider(),
                                        _headerCell(
                                          "Balance",
                                          balW,
                                          const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 11,
                                          ),
                                        ),
                                        _vDivider(),
                                        _headerCell(
                                          "Edit",
                                          actW,
                                          const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 11,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
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
                                                    horizontal: 2,
                                                  ),
                                              child: Text(
                                                DateFormat(
                                                  'dd-MMM-yy',
                                                ).format(row['date']),
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.black,
                                                  fontSize: 10,
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
                                                    horizontal: 2,
                                                  ),
                                              child: Text(
                                                row['details'],
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.black,
                                                  fontSize: 10,
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
                                                    horizontal: 2,
                                                  ),
                                              child: Text(
                                                row['debit'] > 0
                                                    ? "${row['debit'].toStringAsFixed(0)}"
                                                    : "-",
                                                style: TextStyle(
                                                  fontWeight: FontWeight.w900,
                                                  color: Colors.red.shade900,
                                                  fontSize: 11,
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
                                                    horizontal: 2,
                                                  ),
                                              child: Text(
                                                row['credit'] > 0
                                                    ? "${row['credit'].toStringAsFixed(0)}"
                                                    : "-",
                                                style: TextStyle(
                                                  fontWeight: FontWeight.w900,
                                                  color: Colors.green.shade900,
                                                  fontSize: 11,
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
                                                    horizontal: 2,
                                                  ),
                                              child: Text(
                                                "${row['balance'].toStringAsFixed(0)}",
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.w900,
                                                  color: Colors.black,
                                                  fontSize: 12,
                                                ),
                                                textAlign: TextAlign.center,
                                                maxLines: 1,
                                              ),
                                            ),
                                          ),
                                          _vDataDivider(),
                                          SizedBox(
                                            width: actW,
                                            child: row['docId'] != null
                                                ? InkWell(
                                                    onTap: () {
                                                      _openEditPaymentDialog(
                                                        row['rawMap'],
                                                        row['docId'],
                                                        bNum,
                                                        purchaseDoc.id,
                                                      );
                                                    },
                                                    child: const Icon(
                                                      Icons.edit,
                                                      size: 18,
                                                      color: Colors.blue,
                                                    ),
                                                  )
                                                : const SizedBox(),
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
