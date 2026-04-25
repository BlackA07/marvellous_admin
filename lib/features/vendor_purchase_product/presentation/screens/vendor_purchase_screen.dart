import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../controller/purchase_controller.dart';
import '../widgets/payment_terms_section.dart';
import '../widgets/searchable_selection_field.dart';

class VendorPurchaseScreen extends StatefulWidget {
  const VendorPurchaseScreen({super.key});

  @override
  State<VendorPurchaseScreen> createState() => _VendorPurchaseScreenState();
}

class _VendorPurchaseScreenState extends State<VendorPurchaseScreen> {
  final controller = Get.put(PurchaseController());

  final qtyCtrl = TextEditingController(text: "1");
  final priceCtrl = TextEditingController();
  var tempSelectedProduct = Rxn<Map<String, dynamic>>();

  Key _paymentTermsKey = UniqueKey();

  void _resetScreen() {
    qtyCtrl.text = "1";
    priceCtrl.clear();
    tempSelectedProduct.value = null;
    controller.clearData();
    setState(() {
      _paymentTermsKey = UniqueKey();
    });
  }

  void _addItem() {
    if (tempSelectedProduct.value == null) {
      Get.snackbar(
        "Required",
        "Select a product first.",
        backgroundColor: Colors.black,
        colorText: Colors.white,
      );
      return;
    }
    double qty = double.tryParse(qtyCtrl.text) ?? 0;
    double price = double.tryParse(priceCtrl.text) ?? 0;

    if (qty <= 0 || price <= 0) {
      Get.snackbar(
        "Required",
        "Quantity and Price must be valid.",
        backgroundColor: Colors.black,
        colorText: Colors.white,
      );
      return;
    }

    controller.addItemToBill(tempSelectedProduct.value!, qty.toInt(), price);

    tempSelectedProduct.value = null;
    qtyCtrl.text = "1";
    priceCtrl.clear();
    FocusScope.of(context).unfocus();
  }

  void _showSuccessPopup() {
    Get.defaultDialog(
      title: "Transaction Saved!",
      titlePadding: const EdgeInsets.only(top: 25, bottom: 10),
      titleStyle: GoogleFonts.comicNeue(
        color: Colors.green.shade800,
        fontWeight: FontWeight.w900,
        fontSize: 26,
      ),
      content: Padding(
        padding: const EdgeInsets.all(15.0),
        child: Column(
          children: [
            const Icon(Icons.check_circle, color: Colors.green, size: 70),
            const SizedBox(height: 20),
            Text(
              "Ledger and stock updated successfully.",
              textAlign: TextAlign.center,
              style: GoogleFonts.comicNeue(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: const Color.fromARGB(255, 255, 255, 255),
              ),
            ),
          ],
        ),
      ),
      barrierDismissible: false,
      confirm: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.black,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          minimumSize: const Size(200, 55),
        ),
        onPressed: () {
          Get.back();
          _resetScreen();
        },
        child: Text(
          "Close & Start New",
          style: GoogleFonts.comicNeue(
            color: Colors.white,
            fontWeight: FontWeight.w900,
            fontSize: 18,
          ),
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
          "Purchase Products",
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
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ✅ EDITABLE DATE ROW
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Bill Date:",
                  style: GoogleFonts.comicNeue(
                    fontWeight: FontWeight.w900,
                    fontSize: 20,
                    color: Colors.black,
                  ),
                ),
                InkWell(
                  onTap: () async {
                    DateTime? picked = await showDatePicker(
                      context: context,
                      initialDate: controller.billDate.value,
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2100),
                      builder: (context, child) {
                        return Theme(
                          data: ThemeData.light().copyWith(
                            colorScheme: const ColorScheme.light(
                              primary: Colors.black,
                              onPrimary: Colors.white,
                            ),
                            textButtonTheme: TextButtonThemeData(
                              style: TextButton.styleFrom(
                                foregroundColor: Colors.black,
                              ),
                            ),
                          ),
                          child: child!,
                        );
                      },
                    );
                    if (picked != null) {
                      controller.billDate.value = picked;
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 15,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: Colors.black, width: 2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Obx(
                          () => Text(
                            DateFormat(
                              'dd MMMM, yyyy',
                            ).format(controller.billDate.value),
                            style: GoogleFonts.comicNeue(
                              color: Colors.black,
                              fontWeight: FontWeight.w900,
                              fontSize: 18,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        const Icon(
                          Icons.calendar_month,
                          color: Colors.black,
                          size: 24,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 35, color: Colors.black, thickness: 2),

            Obx(
              () => SearchableSelectionField(
                label: "Select Vendor / Store Name",
                hint: "Search Store or Owner...",
                selectedValue: controller.selectedVendor.value == null
                    ? null
                    : "${controller.selectedVendor.value?['storeName']} (${controller.selectedVendor.value?['ownerName']})",
                items: controller.vendors
                    .map((e) => "${e['storeName']} (${e['ownerName']})")
                    .toList(),
                onSelected: (val) {
                  var v = controller.vendors.firstWhere(
                    (e) => "${e['storeName']} (${e['ownerName']})" == val,
                  );
                  controller.setVendor(v);
                },
              ),
            ),

            const SizedBox(height: 30),

            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: Colors.black, width: 2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "ADD ITEMS TO BILL",
                    style: GoogleFonts.comicNeue(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: Colors.black,
                    ),
                  ),
                  const Divider(
                    color: Colors.black,
                    height: 25,
                    thickness: 1.5,
                  ),

                  Obx(
                    () => SearchableSelectionField(
                      label: "Select Product",
                      hint: "Search Product...",
                      selectedValue: tempSelectedProduct.value == null
                          ? null
                          : "${tempSelectedProduct.value?['name']} - ${tempSelectedProduct.value?['modelNumber']}",
                      items: controller.products
                          .map((e) => "${e['name']} - ${e['modelNumber']}")
                          .toList(),
                      onSelected: (val) {
                        var p = controller.products.firstWhere(
                          (e) => "${e['name']} - ${e['modelNumber']}" == val,
                        );
                        tempSelectedProduct.value = p;
                        priceCtrl.text = p['purchasePrice'].toString();
                      },
                    ),
                  ),

                  const SizedBox(height: 25),
                  Row(
                    children: [
                      Expanded(
                        child: _buildInput("Quantity", qtyCtrl, isNum: true),
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: _buildInput(
                          "Purchase Price",
                          priceCtrl,
                          isNum: true,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 25),
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: _addItem,
                      icon: const Icon(
                        Icons.add,
                        color: Colors.white,
                        size: 28,
                      ),
                      label: Text(
                        "ADD TO BILL",
                        style: GoogleFonts.comicNeue(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 18,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 35),

            Obx(() {
              if (controller.addedItems.isEmpty) return const SizedBox();
              return Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue.shade900, width: 2.5),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "BILL ITEMS",
                      style: GoogleFonts.comicNeue(
                        fontWeight: FontWeight.w900,
                        fontSize: 22,
                        color: Colors.black,
                      ),
                    ),
                    const Divider(
                      color: Colors.black,
                      height: 25,
                      thickness: 1.5,
                    ),
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: controller.addedItems.length,
                      itemBuilder: (ctx, i) {
                        var item = controller.addedItems[i];
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(
                            "${item['productName']} (${item['model']})",
                            style: GoogleFonts.comicNeue(
                              fontWeight: FontWeight.w900,
                              fontSize: 18,
                              color: Colors.black,
                            ),
                          ),
                          subtitle: Text(
                            "${item['quantity']} x PKR ${item['unitPrice']}",
                            style: GoogleFonts.comicNeue(
                              color: Colors.black87,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                "PKR ${item['totalItemPrice']}",
                                style: GoogleFonts.comicNeue(
                                  fontWeight: FontWeight.w900,
                                  fontSize: 18,
                                  color: Colors.black,
                                ),
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.delete,
                                  color: Colors.red,
                                  size: 30,
                                ),
                                onPressed: () =>
                                    controller.removeItemFromBill(i),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                ),
              );
            }),

            const SizedBox(height: 35),

            Obx(
              () => Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.green.shade800, width: 2.5),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Previous Balance:",
                          style: GoogleFonts.comicNeue(
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                            color: Colors.black,
                          ),
                        ),
                        Text(
                          "PKR ${controller.previousBalance.value.toStringAsFixed(0)}",
                          style: GoogleFonts.comicNeue(
                            fontWeight: FontWeight.w900,
                            fontSize: 22,
                            color: Colors.red.shade900,
                          ),
                        ),
                      ],
                    ),
                    const Divider(
                      color: Colors.black,
                      thickness: 1.5,
                      height: 30,
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "GRAND TOTAL:",
                          style: GoogleFonts.comicNeue(
                            fontWeight: FontWeight.w900,
                            fontSize: 24,
                            color: Colors.black,
                          ),
                        ),
                        Text(
                          "PKR ${controller.calculateGrandTotal().toStringAsFixed(0)}",
                          style: GoogleFonts.comicNeue(
                            fontWeight: FontWeight.w900,
                            fontSize: 30,
                            color: Colors.green.shade900,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 40),

            Obx(
              () => PaymentTermsSection(
                key: _paymentTermsKey,
                totalBill: controller.calculateGrandTotal(),
                onSaveSuccess: _showSuccessPopup,
              ),
            ),

            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  Widget _buildInput(
    String label,
    TextEditingController ctrl, {
    bool isNum = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.comicNeue(
            fontSize: 18,
            color: Colors.black,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 5),
        TextField(
          controller: ctrl,
          keyboardType: isNum ? TextInputType.number : TextInputType.text,
          style: GoogleFonts.comicNeue(
            fontWeight: FontWeight.w900,
            fontSize: 18,
            color: Colors.black,
          ),
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.black, width: 2),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.black, width: 2),
            ),
          ),
        ),
      ],
    );
  }
}
