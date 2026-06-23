import 'dart:convert';
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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (Get.arguments != null && Get.arguments['orderRequest'] != null) {
        controller.loadOrderRequest(Get.arguments['orderRequest']);
      }
    });
  }

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

    var product = tempSelectedProduct.value!;
    controller.addItemToBill(product, qty.toInt(), price);

    // ✅ FIX: Agar controller RAM/ROM ko list mein add karna bhool gaya hai,
    // toh hum yahan forcefully usay inject karwa rahay hain taake UI par show ho jaye.
    if (controller.addedItems.isNotEmpty) {
      var lastItem = controller.addedItems.last;
      lastItem['ram'] = product['ram'] ?? '';
      lastItem['storage'] = product['storage'] ?? '';
      lastItem['brand'] = product['brand'] ?? '';
      lastItem['model'] = product['modelNumber'] ?? product['model'] ?? 'N/A';
      controller.addedItems[controller.addedItems.length - 1] = lastItem;
    }

    tempSelectedProduct.value = null;
    qtyCtrl.text = "1";
    priceCtrl.clear();
    FocusScope.of(context).unfocus();

    // Payment terms refresh karo
    setState(() {
      _paymentTermsKey = UniqueKey();
    });
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
                color: Colors.black,
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

  // ✅ FAST & CRASH-PROOF UNIVERSAL IMAGE BUILDER (Handles both Cloudinary URLs & Base64)
  Widget _buildBase64Image(String? base64String, double size) {
    if (base64String == null || base64String.isEmpty) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(
          Icons.image_not_supported,
          size: size * 0.5,
          color: Colors.grey,
        ),
      );
    }

    try {
      // ✅ 1. Agar Cloudinary URL hai (Migration ke baad)
      if (base64String.startsWith('http')) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: Image.network(
            base64String,
            width: size,
            height: size,
            fit: BoxFit.cover,
            cacheWidth: (size * 2).toInt(), // 🔥 SPEED FIX: RAM Optimization
            errorBuilder: (context, error, stackTrace) => Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(
                Icons.broken_image,
                size: size * 0.5,
                color: Colors.grey,
              ),
            ),
          ),
        );
      }

      // ✅ 2. Agar purana Base64 Data hai (Migration se pehle ka)
      String cleanBase64 = base64String.contains(',')
          ? base64String.split(',').last
          : base64String;
      return ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: Image.memory(
          base64Decode(cleanBase64),
          width: size,
          height: size,
          fit: BoxFit.cover,
          cacheWidth: (size * 2).toInt(), // 🔥 SPEED FIX: RAM Optimization
          errorBuilder: (context, error, stackTrace) => Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(
              Icons.broken_image,
              size: size * 0.5,
              color: Colors.grey,
            ),
          ),
        ),
      );
    } catch (e) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(Icons.broken_image, size: size * 0.5, color: Colors.grey),
      );
    }
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
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(
            child: CircularProgressIndicator(color: Colors.black),
          );
        }

        return SingleChildScrollView(
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

              Obx(() {
                // ✅ FIX: Duplicate vendors ko remove karne ke liye .toSet() use kiya gaya hai
                var uniqueVendorItems = controller.vendors
                    .map((e) => "${e['storeName']} (${e['ownerName']})")
                    .toSet()
                    .toList();

                return SearchableSelectionField(
                  label: "Select Vendor / Store Name",
                  hint: "Search Store or Owner...",
                  selectedValue: controller.selectedVendor.value == null
                      ? null
                      : "${controller.selectedVendor.value?['storeName']} (${controller.selectedVendor.value?['ownerName']})",
                  items: uniqueVendorItems,
                  onSelected: (val) {
                    var v = controller.vendors.firstWhere(
                      (e) => "${e['storeName']} (${e['ownerName']})" == val,
                    );
                    controller.setVendor(v);
                  },
                );
              }),

              // ✅ NEW: Vendor Details Table
              if (controller.selectedVendor.value != null) ...[
                const SizedBox(height: 15),
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: Colors.black, width: 2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Table(
                    columnWidths: const {
                      0: FixedColumnWidth(70),
                      1: FlexColumnWidth(2),
                      2: FlexColumnWidth(2),
                      3: FlexColumnWidth(1.5),
                    },
                    border: TableBorder.symmetric(
                      inside: const BorderSide(color: Colors.black12, width: 1),
                    ),
                    children: [
                      TableRow(
                        decoration: const BoxDecoration(
                          color: Colors.black,
                          borderRadius: BorderRadius.vertical(
                            top: Radius.circular(6),
                          ),
                        ),
                        children: [
                          _tableHeaderCell("Image"),
                          _tableHeaderCell("Store & Owner"),
                          _tableHeaderCell("Contact"),
                          _tableHeaderCell("Category"),
                        ],
                      ),
                      TableRow(
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: _buildBase64Image(
                              controller.selectedVendor.value!['profileImage'],
                              50,
                            ),
                          ),
                          _tableDataCell(
                            "${controller.selectedVendor.value!['storeName']}\n(${controller.selectedVendor.value!['ownerName']})",
                            isBold: true,
                          ),
                          _tableDataCell(
                            controller
                                    .selectedVendor
                                    .value!['contactPersonPhone'] ??
                                controller
                                    .selectedVendor
                                    .value!['storePhone'] ??
                                "N/A",
                          ),
                          _tableDataCell(
                            (controller.selectedVendor.value!['categories'] !=
                                        null &&
                                    controller
                                        .selectedVendor
                                        .value!['categories']
                                        .isNotEmpty)
                                ? controller
                                      .selectedVendor
                                      .value!['categories'][0]
                                : "General",
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],

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
                        items: controller.products.map((e) {
                          String label = "${e['name']} - ${e['modelNumber']}";
                          String brand = e['brand'] ?? '';
                          String ram = e['ram'] ?? '';
                          String storage = e['storage'] ?? '';
                          List<String> extra = [
                            if (brand.isNotEmpty) brand,
                            if (ram.isNotEmpty) 'RAM:$ram',
                            if (storage.isNotEmpty) 'ROM:$storage',
                          ];
                          if (extra.isNotEmpty)
                            label += ' (${extra.join(' | ')})';
                          return label;
                        }).toList(),
                        onSelected: (val) {
                          var p = controller.products.firstWhere((e) {
                            String label = "${e['name']} - ${e['modelNumber']}";
                            String brand = e['brand'] ?? '';
                            String ram = e['ram'] ?? '';
                            String storage = e['storage'] ?? '';
                            List<String> extra = [
                              if (brand.isNotEmpty) brand,
                              if (ram.isNotEmpty) 'RAM:$ram',
                              if (storage.isNotEmpty) 'ROM:$storage',
                            ];
                            if (extra.isNotEmpty)
                              label += ' (${extra.join(' | ')})';
                            return label == val;
                          });
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

                          // ✅ FIX: Har value string mein convert kar li hai
                          String ram = (item['ram'] ?? '').toString();
                          String storage = (item['storage'] ?? '').toString();
                          String brand = (item['brand'] ?? '').toString();

                          final unitPriceCtrl = TextEditingController(
                            text: item['unitPrice'].toString(),
                          );

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12.0),
                            child: Row(
                              children: [
                                _buildBase64Image(item['image'], 60),
                                const SizedBox(width: 15),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "${item['productName']} (${item['model'] ?? 'N/A'})",
                                        style: GoogleFonts.comicNeue(
                                          fontWeight: FontWeight.w900,
                                          fontSize: 18,
                                          color: Colors.black,
                                        ),
                                      ),
                                      if (brand.isNotEmpty)
                                        Text(
                                          brand,
                                          style: GoogleFonts.comicNeue(
                                            fontSize: 13,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.deepPurple,
                                          ),
                                        ),
                                      // ✅ FIX: RAM aur ROM ab perfectly show hoga
                                      if (ram.isNotEmpty || storage.isNotEmpty)
                                        Text(
                                          [
                                            if (ram.isNotEmpty) 'RAM: $ram',
                                            if (storage.isNotEmpty)
                                              'ROM: $storage',
                                          ].join('  |  '),
                                          style: GoogleFonts.comicNeue(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.teal.shade700,
                                          ),
                                        ),
                                      const SizedBox(height: 6),
                                      // Editable unit price
                                      SizedBox(
                                        width: 150,
                                        height: 36,
                                        child: TextField(
                                          controller: unitPriceCtrl,
                                          keyboardType: TextInputType.number,
                                          style: GoogleFonts.comicNeue(
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.blue.shade900,
                                          ),
                                          decoration: InputDecoration(
                                            prefixText: 'PKR ',
                                            prefixStyle: GoogleFonts.comicNeue(
                                              fontSize: 13,
                                              color: Colors.blue.shade900,
                                              fontWeight: FontWeight.bold,
                                            ),
                                            contentPadding:
                                                const EdgeInsets.symmetric(
                                                  horizontal: 8,
                                                  vertical: 6,
                                                ),
                                            border: OutlineInputBorder(
                                              borderSide: const BorderSide(
                                                color: Colors.black,
                                                width: 1.5,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                            ),
                                            focusedBorder: OutlineInputBorder(
                                              borderSide: const BorderSide(
                                                color: Colors.blue,
                                                width: 2,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                            ),
                                          ),
                                          onChanged: (val) {
                                            double newPrice =
                                                double.tryParse(val) ?? 0;
                                            controller
                                                    .addedItems[i]['unitPrice'] =
                                                newPrice;
                                            controller
                                                    .addedItems[i]['totalItemPrice'] =
                                                newPrice * item['quantity'];
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Row(
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
                    border: Border.all(
                      color: Colors.green.shade800,
                      width: 2.5,
                    ),
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

              PaymentTermsSection(
                key: _paymentTermsKey,
                totalBill: controller.calculateGrandTotal(),
                onSaveSuccess: _showSuccessPopup,
              ),

              const SizedBox(height: 100),
            ],
          ),
        );
      }),
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

  // ── Helper Widgets For Vendor Table ──
  Widget _tableHeaderCell(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 5),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: GoogleFonts.comicNeue(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
      ),
    );
  }

  Widget _tableDataCell(String text, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 5),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: GoogleFonts.comicNeue(
          color: Colors.black,
          fontWeight: isBold ? FontWeight.w900 : FontWeight.bold,
          fontSize: 13,
        ),
      ),
    );
  }
}
