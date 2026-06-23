import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class ApproveChequesScreen extends StatefulWidget {
  const ApproveChequesScreen({super.key});

  @override
  State<ApproveChequesScreen> createState() => _ApproveChequesScreenState();
}

class _ApproveChequesScreenState extends State<ApproveChequesScreen> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ✅ APPROVE CHEQUE METHOD: Isme paymentDate ko current time pe shift kar diya gaya hai
  Future<void> _approveCheque(
    String docId,
    double amount,
    String? bankId,
  ) async {
    Get.defaultDialog(
      title: "Approve Cheque",
      titleStyle: GoogleFonts.comicNeue(
        fontWeight: FontWeight.w900,
        color: Colors.green.shade800,
      ),
      middleText:
          "Are you sure this cheque has been cleared?\nThis will deduct PKR $amount from the assigned bank and mark the payment as completed today.",
      textConfirm: "Approve & Clear",
      textCancel: "Cancel",
      confirmTextColor: Colors.white,
      buttonColor: Colors.green.shade700,
      onConfirm: () async {
        Get.back();
        try {
          WriteBatch batch = _db.batch();

          // 1. Mark as cleared AND shift the paymentDate to NOW
          batch.update(_db.collection('vendor_payment_history').doc(docId), {
            'isCleared': true,
            'paymentDate':
                FieldValue.serverTimestamp(), // ✅ Jis din approve hoga, ledger mein wahi date aayegi!
          });

          // 2. Deduct from assigned bank
          if (bankId != null && bankId.isNotEmpty) {
            batch.update(
              _db
                  .collection('company_finances')
                  .doc('main_finances')
                  .collection('banks')
                  .doc(bankId),
              {'balance': FieldValue.increment(-amount)},
            );
          }

          await batch.commit();

          Get.snackbar(
            "Success",
            "Cheque cleared and amount deducted successfully.",
            backgroundColor: Colors.green,
            colorText: Colors.white,
          );
        } catch (e) {
          Get.snackbar(
            "Error",
            e.toString(),
            backgroundColor: Colors.red,
            colorText: Colors.white,
          );
        }
      },
    );
  }

  // ✅ EDIT CHEQUE METHOD: Bank aur Date change karne ke liye
  Future<void> _showEditDialog(String docId, Map<String, dynamic> data) async {
    DateTime selectedDate = data['chequeDate'] != null
        ? (data['chequeDate'] as Timestamp).toDate()
        : DateTime.now();

    String? selectedBankId = data['chequeBankId'] ?? data['bankId'];
    String? selectedBankName = data['chequeBankName'] ?? data['bankName'];

    // Fetch banks list
    var banksSnap = await _db
        .collection('company_finances')
        .doc('main_finances')
        .collection('banks')
        .get();
    var banksList = banksSnap.docs;

    Get.defaultDialog(
      title: "Edit Cheque Details",
      titleStyle: GoogleFonts.comicNeue(
        fontWeight: FontWeight.w900,
        fontSize: 22,
      ),
      content: StatefulBuilder(
        builder: (context, setModalState) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Select Clearing Bank:",
                  style: GoogleFonts.comicNeue(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 5),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: Colors.black54),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      isExpanded: true,
                      value: selectedBankId,
                      hint: const Text("Select Bank"),
                      items: banksList.map((b) {
                        var bData = b.data();
                        String name =
                            "${bData['name'] ?? bData['bankName']} - ${bData['accountTitle'] ?? ''}";
                        return DropdownMenuItem(value: b.id, child: Text(name));
                      }).toList(),
                      onChanged: (val) {
                        setModalState(() {
                          selectedBankId = val;
                          var bDoc = banksList.firstWhere(
                            (element) => element.id == val,
                          );
                          var d = bDoc.data();
                          selectedBankName =
                              "${d['name'] ?? d['bankName']} - ${d['accountTitle'] ?? ''}";
                        });
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  "Cheque Cash Date:",
                  style: GoogleFonts.comicNeue(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 5),
                InkWell(
                  onTap: () async {
                    DateTime? picked = await showDatePicker(
                      context: context,
                      initialDate: selectedDate,
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2100),
                    );
                    if (picked != null) {
                      setModalState(() => selectedDate = picked);
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: Colors.black54),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          DateFormat('dd MMM, yyyy').format(selectedDate),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const Icon(Icons.calendar_month, color: Colors.black87),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
      textConfirm: "Save Changes",
      textCancel: "Cancel",
      confirmTextColor: Colors.white,
      buttonColor: Colors.black,
      onConfirm: () async {
        Get.back();
        try {
          await _db.collection('vendor_payment_history').doc(docId).update({
            'chequeBankId': selectedBankId,
            'chequeBankName': selectedBankName,
            'chequeDate': Timestamp.fromDate(selectedDate),
          });
          Get.snackbar(
            "Success",
            "Cheque details updated.",
            backgroundColor: Colors.green,
            colorText: Colors.white,
          );
        } catch (e) {
          Get.snackbar(
            "Error",
            e.toString(),
            backgroundColor: Colors.red,
            colorText: Colors.white,
          );
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      appBar: AppBar(
        title: Text(
          "Pending Cheques",
          style: GoogleFonts.comicNeue(
            fontSize: 26,
            fontWeight: FontWeight.w900,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _db
            .collection('vendor_payment_history')
            .where('paymentMode', isEqualTo: 'Cheque')
            .where('isCleared', isEqualTo: false)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Text(
                "No pending cheques found.",
                style: GoogleFonts.comicNeue(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              var doc = snapshot.data!.docs[index];
              var data = doc.data() as Map<String, dynamic>;

              double amount = (data['paidAmount'] ?? 0.0).toDouble();
              DateTime cDate = data['chequeDate'] != null
                  ? (data['chequeDate'] as Timestamp).toDate()
                  : DateTime.now();
              String vendor = data['vendorName'] ?? 'Unknown Vendor';
              String bankId = data['chequeBankId'] ?? data['bankId'];

              return Card(
                elevation: 3,
                margin: const EdgeInsets.only(bottom: 15),
                // ✅ FIX: Card ki shape mein border lagane ke liye 'side' aur 'BorderSide' use hota hai
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: Colors.amber.shade700, width: 1.5),
                ),
                child: InkWell(
                  // ✅ Click karne par edit dialog khulega
                  onTap: () => _showEditDialog(doc.id, data),
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.all(15),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                "$vendor",
                                style: GoogleFonts.comicNeue(
                                  fontWeight: FontWeight.w900,
                                  fontSize: 20,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.amber.shade100,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                "Pending",
                                style: TextStyle(
                                  color: Colors.amber.shade900,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "Bill Ref: ${data['billNumber']}",
                          style: const TextStyle(
                            color: Colors.black54,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Divider(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Amount",
                                  style: TextStyle(
                                    color: Colors.grey.shade600,
                                    fontSize: 12,
                                  ),
                                ),
                                Text(
                                  "PKR ${amount.toStringAsFixed(0)}",
                                  style: GoogleFonts.comicNeue(
                                    fontWeight: FontWeight.w900,
                                    fontSize: 18,
                                    color: Colors.red.shade700,
                                  ),
                                ),
                              ],
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  "Cheque Date",
                                  style: TextStyle(
                                    color: Colors.grey.shade600,
                                    fontSize: 12,
                                  ),
                                ),
                                Text(
                                  DateFormat('dd MMM yyyy').format(cDate),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Icon(
                              Icons.account_balance,
                              size: 16,
                              color: Colors.blue.shade800,
                            ),
                            const SizedBox(width: 5),
                            Expanded(
                              child: Text(
                                data['chequeBankName'] ??
                                    data['bankName'] ??
                                    'No Bank Assigned',
                                style: TextStyle(
                                  color: Colors.blue.shade900,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 15),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.black,
                                ),
                                onPressed: () => _showEditDialog(doc.id, data),
                                icon: const Icon(Icons.edit, size: 18),
                                label: const Text("Edit Details"),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green.shade700,
                                ),
                                onPressed: () =>
                                    _approveCheque(doc.id, amount, bankId),
                                icon: const Icon(
                                  Icons.check_circle,
                                  size: 18,
                                  color: Colors.white,
                                ),
                                label: const Text(
                                  "Approve",
                                  style: TextStyle(color: Colors.white),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
