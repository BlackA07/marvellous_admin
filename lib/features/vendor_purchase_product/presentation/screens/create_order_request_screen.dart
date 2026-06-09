import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../controller/order_request_controller.dart';
import '../widgets/searchable_selection_field.dart';

class CreateOrderRequestScreen extends StatelessWidget {
  const CreateOrderRequestScreen({super.key});

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
    final controller = Get.put(OrderRequestController());

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      appBar: AppBar(
        title: Text(
          "Create Order Request",
          style: GoogleFonts.comicNeue(
            fontSize: 26,
            fontWeight: FontWeight.w900,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.black,
        elevation: 2,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Obx(() {
        if (controller.isLoading.value && controller.vendors.isEmpty) {
          return const Center(
            child: CircularProgressIndicator(color: Colors.black),
          );
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ═══════════════════════════════════════════════════════
              // DATE PICKER
              // ═══════════════════════════════════════════════════════
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Order Date:",
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
                        initialDate: controller.orderDate.value,
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2100),
                      );
                      if (picked != null) {
                        controller.orderDate.value = picked;
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
                          Text(
                            DateFormat(
                              'dd MMMM, yyyy',
                            ).format(controller.orderDate.value),
                            style: GoogleFonts.comicNeue(
                              color: Colors.black,
                              fontWeight: FontWeight.w900,
                              fontSize: 18,
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

              // ═══════════════════════════════════════════════════════
              // STEP 1: VENDOR SEARCH & DETAILS TABLE
              // ═══════════════════════════════════════════════════════
              SearchableSelectionField(
                label: "Step 1: Select Vendor",
                hint: "Search Store or Owner...",
                selectedValue: controller.selectedVendor.value == null
                    ? null
                    : "${controller.selectedVendor.value!['storeName']} (${controller.selectedVendor.value!['ownerName']})",
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

              // ✅ Vendor Details Table — WITH profile image (same as VendorPurchaseScreen)
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
                                'N/A',
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
                                : 'General',
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 35),

              // ═══════════════════════════════════════════════════════
              // STEP 2: SEARCH & ADD PRODUCTS
              // ═══════════════════════════════════════════════════════
              SearchableSelectionField(
                label: "Step 2: Search & Add Products",
                hint: "Type Product Name or Model...",
                selectedValue: controller.productSearchQuery.value.isEmpty
                    ? null
                    : controller.productSearchQuery.value,
                items: controller.products
                    .map((e) => "${e['name']} - ${e['modelNumber']}")
                    .toList(),
                onSelected: (val) {
                  controller.handleProductSelection(val);
                },
              ),

              const SizedBox(height: 35),

              // ═══════════════════════════════════════════════════════
              // STEP 3: REQUESTED ITEMS LIST
              // ═══════════════════════════════════════════════════════
              Text(
                "Requested Items:",
                style: GoogleFonts.comicNeue(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: Colors.black,
                ),
              ),
              const Divider(color: Colors.black, thickness: 2, height: 20),

              if (controller.cartItems.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(25),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.black26),
                  ),
                  child: Center(
                    child: Text(
                      "No products added to the request yet.",
                      style: GoogleFonts.comicNeue(
                        fontSize: 18,
                        color: Colors.black54,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                )
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: controller.cartItems.length,
                  itemBuilder: (ctx, i) {
                    var item = controller.cartItems[i];
                    return CartItemTile(
                      item: item,
                      index: i,
                      controller: controller,
                      buildImage: _buildBase64Image, // ✅ Pass image builder
                    );
                  },
                ),

              const SizedBox(height: 35),

              // ═══════════════════════════════════════════════════════
              // CART SUMMARY & SUBMIT BUTTON
              // ═══════════════════════════════════════════════════════
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.amber.shade200,
                  border: Border.all(color: Colors.black, width: 2.5),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Total Unique Items:",
                          style: GoogleFonts.comicNeue(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: Colors.black,
                          ),
                        ),
                        Text(
                          "${controller.cartItems.length}",
                          style: GoogleFonts.comicNeue(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            color: Colors.black,
                          ),
                        ),
                      ],
                    ),
                    const Divider(
                      color: Colors.black,
                      thickness: 1.5,
                      height: 20,
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "GRAND TOTAL:",
                          style: GoogleFonts.comicNeue(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            color: Colors.black,
                          ),
                        ),
                        Text(
                          "PKR ${controller.grandTotal.value.toStringAsFixed(0)}",
                          style: GoogleFonts.comicNeue(
                            fontSize: 26,
                            fontWeight: FontWeight.w900,
                            color: Colors.green.shade900,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 25),

              SizedBox(
                width: double.infinity,
                height: 65,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: controller.isLoading.value
                      ? null
                      : controller.sendOrderRequest,
                  child: controller.isLoading.value
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(
                          "SEND ORDER REQUEST TO VENDOR",
                          style: GoogleFonts.comicNeue(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 50),
            ],
          ),
        );
      }),
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

// ══════════════════════════════════════════════════════════════════════════════
// Custom Widget: CartItemTile — WITH product image
// ══════════════════════════════════════════════════════════════════════════════
class CartItemTile extends StatefulWidget {
  final Map<String, dynamic> item;
  final int index;
  final OrderRequestController controller;
  final Widget Function(String?, double)
  buildImage; // ✅ Image builder passed in

  const CartItemTile({
    super.key,
    required this.item,
    required this.index,
    required this.controller,
    required this.buildImage,
  });

  @override
  State<CartItemTile> createState() => _CartItemTileState();
}

class _CartItemTileState extends State<CartItemTile> {
  late TextEditingController qtyCtrl;

  @override
  void initState() {
    super.initState();
    qtyCtrl = TextEditingController(text: widget.item['requestQty'].toString());
  }

  @override
  void didUpdateWidget(covariant CartItemTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.item['requestQty'] != widget.item['requestQty']) {
      if (!FocusScope.of(context).hasFocus) {
        qtyCtrl.text = widget.item['requestQty'].toString();
      }
    }
  }

  @override
  void dispose() {
    qtyCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    double unitPrice = (widget.item['purchasePrice'] ?? 0).toDouble();
    double itemTotal = unitPrice * widget.item['requestQty'];

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.black, width: 2),
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // ✅ Product Image
          widget.buildImage(widget.item['image'], 65),
          const SizedBox(width: 12),

          // -- Product Details --
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "${widget.item['productName']}",
                  style: GoogleFonts.comicNeue(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "Model: ${widget.item['model']}",
                  style: GoogleFonts.comicNeue(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.black54,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  "Unit: PKR $unitPrice",
                  style: GoogleFonts.comicNeue(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade900,
                  ),
                ),
              ],
            ),
          ),

          // -- Quantity TextField & Item Total --
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                SizedBox(
                  width: 80,
                  height: 40,
                  child: TextField(
                    controller: qtyCtrl,
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.comicNeue(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                    decoration: InputDecoration(
                      contentPadding: EdgeInsets.zero,
                      border: OutlineInputBorder(
                        borderSide: const BorderSide(
                          color: Colors.black,
                          width: 1.5,
                        ),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: const BorderSide(
                          color: Colors.blue,
                          width: 2.5,
                        ),
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    onChanged: (val) {
                      int newQty = int.tryParse(val) ?? 0;
                      setState(() {
                        widget.item['requestQty'] = newQty;
                      });
                      widget.controller.updateItemQty(
                        widget.item['productId'],
                        newQty,
                      );
                    },
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  "Total: PKR ${itemTotal.toStringAsFixed(0)}",
                  style: GoogleFonts.comicNeue(
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    color: Colors.green.shade800,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 5),

          // -- Delete Icon --
          IconButton(
            padding: EdgeInsets.zero,
            alignment: Alignment.topRight,
            icon: const Icon(Icons.delete_forever, color: Colors.red, size: 28),
            onPressed: () => widget.controller.removeFromCart(widget.index),
          ),
        ],
      ),
    );
  }
}
