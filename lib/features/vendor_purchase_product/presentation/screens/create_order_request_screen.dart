import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../controller/order_request_controller.dart';

class CreateOrderRequestScreen extends StatelessWidget {
  const CreateOrderRequestScreen({super.key});

  // ✅ UNIVERSAL IMAGE BUILDER — Cloudinary URL ya Base64 dono handle karta hai
  static Widget buildUniversalImage(
    String? src,
    double size, {
    double radius = 6,
  }) {
    if (src == null || src.trim().isEmpty) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(radius),
        ),
        child: Icon(
          Icons.image_not_supported,
          size: size * 0.5,
          color: Colors.grey,
        ),
      );
    }
    try {
      if (src.startsWith('http')) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(radius),
          child: Image.network(
            src,
            width: size,
            height: size,
            fit: BoxFit.cover,
            cacheWidth: (size * 2).toInt(),
            errorBuilder: (_, __, ___) => Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(radius),
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
      final clean = src.contains(',') ? src.split(',').last : src;
      return ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: Image.memory(
          base64Decode(clean),
          width: size,
          height: size,
          fit: BoxFit.cover,
          cacheWidth: (size * 2).toInt(),
          errorBuilder: (_, __, ___) => Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(radius),
            ),
            child: Icon(
              Icons.broken_image,
              size: size * 0.5,
              color: Colors.grey,
            ),
          ),
        ),
      );
    } catch (_) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(radius),
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
              // ═══ DATE PICKER ═══════════════════════════════════════
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
                      if (picked != null) controller.orderDate.value = picked;
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

              // ═══ STEP 1: VENDOR SELECTION ═══════════════════════════
              Text(
                "Step 1: Select Vendor",
                style: GoogleFonts.comicNeue(
                  fontWeight: FontWeight.w900,
                  fontSize: 20,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 10),

              // Vendor Search Field with image list
              _VendorSearchField(controller: controller),

              // ═══ STEP 2: PRODUCT SEARCH ══════════════════════════════
              const SizedBox(height: 30),
              Text(
                "Step 2: Search & Add Products",
                style: GoogleFonts.comicNeue(
                  fontWeight: FontWeight.w900,
                  fontSize: 20,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 10),

              // Product Search Field with image + price list
              _ProductSearchField(controller: controller),

              const SizedBox(height: 30),

              // ═══ STEP 3: CART ITEMS ═════════════════════════════════
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
                    );
                  },
                ),

              const SizedBox(height: 30),

              // ═══ SUMMARY & SUBMIT ════════════════════════════════════
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
}

// ══════════════════════════════════════════════════════════════════
// VENDOR SEARCH FIELD — image + name + phone in dropdown
// ══════════════════════════════════════════════════════════════════
class _VendorSearchField extends StatefulWidget {
  final OrderRequestController controller;
  const _VendorSearchField({required this.controller});

  @override
  State<_VendorSearchField> createState() => _VendorSearchFieldState();
}

class _VendorSearchFieldState extends State<_VendorSearchField> {
  final TextEditingController _ctrl = TextEditingController();
  final FocusNode _focus = FocusNode();
  List<Map<String, dynamic>> _filtered = [];
  bool _showList = false;

  @override
  void initState() {
    super.initState();
    // Pre-fill if editing
    final sel = widget.controller.selectedVendor.value;
    if (sel != null) {
      _ctrl.text = "${sel['storeName']} (${sel['ownerName']})";
    }
    _focus.addListener(() {
      if (!_focus.hasFocus) {
        Future.delayed(
          const Duration(milliseconds: 150),
          () => setState(() => _showList = false),
        );
      }
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _filter(String q) {
    final all = List<Map<String, dynamic>>.from(widget.controller.vendors);
    if (q.trim().isEmpty) {
      setState(() {
        _filtered = all
          ..sort(
            (a, b) => (a['storeName'] ?? '').toLowerCase().compareTo(
              (b['storeName'] ?? '').toLowerCase(),
            ),
          );
        _showList = true;
      });
      return;
    }
    final lower = q.toLowerCase();
    setState(() {
      _filtered =
          all.where((v) {
            return (v['storeName'] ?? '').toLowerCase().contains(lower) ||
                (v['ownerName'] ?? '').toLowerCase().contains(lower) ||
                (v['storePhone'] ?? '').contains(lower);
          }).toList()..sort(
            (a, b) => (a['storeName'] ?? '').toLowerCase().compareTo(
              (b['storeName'] ?? '').toLowerCase(),
            ),
          );
      _showList = true;
    });
  }

  void _select(Map<String, dynamic> vendor) {
    widget.controller.setVendor(vendor);
    _ctrl.text = "${vendor['storeName']} (${vendor['ownerName']})";
    setState(() => _showList = false);
    _focus.unfocus();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Search TextField
        TextField(
          controller: _ctrl,
          focusNode: _focus,
          style: GoogleFonts.comicNeue(
            color: Colors.black,
            fontSize: 17,
            fontWeight: FontWeight.w900,
          ),
          decoration: InputDecoration(
            hintText: "Search store name or owner...",
            hintStyle: GoogleFonts.comicNeue(
              color: Colors.black45,
              fontSize: 15,
            ),
            prefixIcon: const Icon(Icons.search, color: Colors.black, size: 24),
            suffixIcon: IconButton(
              icon: const Icon(
                Icons.arrow_drop_down_circle_outlined,
                color: Colors.black,
                size: 26,
              ),
              onPressed: () {
                _filter('');
                _focus.requestFocus();
              },
            ),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Colors.black, width: 2),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Colors.black, width: 2),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Colors.black, width: 3),
            ),
          ),
          onChanged: _filter,
          onTap: () => _filter(_ctrl.text),
        ),

        // Dropdown List
        if (_showList && _filtered.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(top: 4),
            constraints: const BoxConstraints(maxHeight: 320),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: Colors.black, width: 2),
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  decoration: const BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(8),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Select Vendor",
                        style: GoogleFonts.comicNeue(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 16,
                        ),
                      ),
                      GestureDetector(
                        onTap: () => setState(() => _showList = false),
                        child: const Icon(
                          Icons.close,
                          color: Colors.white,
                          size: 22,
                        ),
                      ),
                    ],
                  ),
                ),
                // List
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    padding: EdgeInsets.zero,
                    itemCount: _filtered.length,
                    separatorBuilder: (_, __) =>
                        const Divider(height: 1, color: Colors.black12),
                    itemBuilder: (context, i) {
                      final v = _filtered[i];
                      final String? img = v['profileImage'];
                      final String phone =
                          v['storePhone'] ?? v['contactPersonPhone'] ?? '';

                      return InkWell(
                        onTap: () => _select(v),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          child: Row(
                            children: [
                              // Profile image
                              CreateOrderRequestScreen.buildUniversalImage(
                                img,
                                52,
                                radius: 26,
                              ),
                              const SizedBox(width: 14),
                              // Details
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      v['storeName'] ?? '',
                                      style: GoogleFonts.comicNeue(
                                        fontWeight: FontWeight.w900,
                                        fontSize: 16,
                                        color: Colors.black,
                                      ),
                                    ),
                                    Text(
                                      v['ownerName'] ?? '',
                                      style: GoogleFonts.comicNeue(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.deepPurple,
                                      ),
                                    ),
                                    if (phone.isNotEmpty)
                                      Text(
                                        phone,
                                        style: GoogleFonts.comicNeue(
                                          fontSize: 12,
                                          color: Colors.black45,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              const Icon(
                                Icons.chevron_right,
                                color: Colors.black26,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),

        // Selected Vendor Card
        Obx(() {
          final sel = widget.controller.selectedVendor.value;
          if (sel == null) return const SizedBox.shrink();
          final String phone =
              sel['contactPersonPhone'] ?? sel['storePhone'] ?? 'N/A';
          final String category =
              (sel['categories'] != null && sel['categories'].isNotEmpty)
              ? sel['categories'][0]
              : 'General';

          return Container(
            margin: const EdgeInsets.only(top: 14),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: Colors.black, width: 2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                CreateOrderRequestScreen.buildUniversalImage(
                  sel['profileImage'],
                  60,
                  radius: 30,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        sel['storeName'] ?? '',
                        style: GoogleFonts.comicNeue(
                          fontWeight: FontWeight.w900,
                          fontSize: 18,
                          color: Colors.black,
                        ),
                      ),
                      Text(
                        sel['ownerName'] ?? '',
                        style: GoogleFonts.comicNeue(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.deepPurple,
                        ),
                      ),
                      Text(
                        phone,
                        style: GoogleFonts.comicNeue(
                          fontSize: 13,
                          color: Colors.black54,
                          fontWeight: FontWeight.bold,
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
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    category,
                    style: GoogleFonts.comicNeue(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}

// ══════════════════════════════════════════════════════════════════
// PRODUCT SEARCH FIELD — image + name + price in dropdown
// ══════════════════════════════════════════════════════════════════
class _ProductSearchField extends StatefulWidget {
  final OrderRequestController controller;
  const _ProductSearchField({required this.controller});

  @override
  State<_ProductSearchField> createState() => _ProductSearchFieldState();
}

class _ProductSearchFieldState extends State<_ProductSearchField> {
  final TextEditingController _ctrl = TextEditingController();
  final FocusNode _focus = FocusNode();
  List<Map<String, dynamic>> _filtered = [];
  bool _showList = false;

  @override
  void initState() {
    super.initState();
    _focus.addListener(() {
      if (!_focus.hasFocus) {
        Future.delayed(
          const Duration(milliseconds: 150),
          () => setState(() => _showList = false),
        );
      }
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _filter(String q) {
    final all = List<Map<String, dynamic>>.from(widget.controller.products);
    if (q.trim().isEmpty) {
      setState(() {
        _filtered = all
          ..sort(
            (a, b) => (a['name'] ?? '').toLowerCase().compareTo(
              (b['name'] ?? '').toLowerCase(),
            ),
          );
        _showList = true;
      });
      return;
    }
    final lower = q.toLowerCase();
    setState(() {
      _filtered =
          all.where((p) {
            return (p['name'] ?? '').toLowerCase().contains(lower) ||
                (p['modelNumber'] ?? '').toLowerCase().contains(lower) ||
                (p['brand'] ?? '').toLowerCase().contains(lower);
          }).toList()..sort(
            (a, b) => (a['name'] ?? '').toLowerCase().compareTo(
              (b['name'] ?? '').toLowerCase(),
            ),
          );
      _showList = true;
    });
  }

  void _select(Map<String, dynamic> product) {
    // Build the label string that controller expects
    String label = "${product['name']} - ${product['modelNumber']}";
    String brand = product['brand'] ?? '';
    String ram = product['ram'] ?? '';
    String storage = product['storage'] ?? '';
    List<String> extra = [
      if (brand.isNotEmpty) brand,
      if (ram.isNotEmpty) 'RAM:$ram',
      if (storage.isNotEmpty) 'ROM:$storage',
    ];
    if (extra.isNotEmpty) label += ' (${extra.join(' | ')})';
    widget.controller.handleProductSelection(label);
    _ctrl.clear();
    setState(() => _showList = false);
    _focus.unfocus();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Search TextField
        TextField(
          controller: _ctrl,
          focusNode: _focus,
          style: GoogleFonts.comicNeue(
            color: Colors.black,
            fontSize: 17,
            fontWeight: FontWeight.w900,
          ),
          decoration: InputDecoration(
            hintText: "Type product name or model...",
            hintStyle: GoogleFonts.comicNeue(
              color: Colors.black45,
              fontSize: 15,
            ),
            prefixIcon: const Icon(Icons.search, color: Colors.black, size: 24),
            suffixIcon: IconButton(
              icon: const Icon(
                Icons.arrow_drop_down_circle_outlined,
                color: Colors.black,
                size: 26,
              ),
              onPressed: () {
                _filter('');
                _focus.requestFocus();
              },
            ),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Colors.black, width: 2),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Colors.black, width: 2),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Colors.black, width: 3),
            ),
          ),
          onChanged: _filter,
          onTap: () => _filter(_ctrl.text),
        ),

        // Dropdown List
        if (_showList && _filtered.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(top: 4),
            constraints: const BoxConstraints(maxHeight: 350),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: Colors.black, width: 2),
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  decoration: const BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(8),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Select Product",
                        style: GoogleFonts.comicNeue(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 16,
                        ),
                      ),
                      GestureDetector(
                        onTap: () => setState(() => _showList = false),
                        child: const Icon(
                          Icons.close,
                          color: Colors.white,
                          size: 22,
                        ),
                      ),
                    ],
                  ),
                ),
                // List
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    padding: EdgeInsets.zero,
                    itemCount: _filtered.length,
                    separatorBuilder: (_, __) =>
                        const Divider(height: 1, color: Colors.black12),
                    itemBuilder: (context, i) {
                      final p = _filtered[i];
                      // First image — Cloudinary URL ya Base64
                      String? img;
                      if (p['images'] != null &&
                          (p['images'] as List).isNotEmpty) {
                        img = p['images'][0];
                      }
                      final String brand = p['brand'] ?? '';
                      final String model = p['modelNumber'] ?? '';
                      final String ram = p['ram'] ?? '';
                      final String storage = p['storage'] ?? '';
                      final num price = p['purchasePrice'] ?? 0;

                      return InkWell(
                        onTap: () => _select(p),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          child: Row(
                            children: [
                              // Product image
                              CreateOrderRequestScreen.buildUniversalImage(
                                img,
                                58,
                                radius: 8,
                              ),
                              const SizedBox(width: 14),
                              // Details
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      p['name'] ?? '',
                                      style: GoogleFonts.comicNeue(
                                        fontWeight: FontWeight.w900,
                                        fontSize: 15,
                                        color: Colors.black,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    if (brand.isNotEmpty)
                                      Text(
                                        brand,
                                        style: GoogleFonts.comicNeue(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.deepPurple,
                                        ),
                                      ),
                                    Row(
                                      children: [
                                        if (model.isNotEmpty)
                                          Text(
                                            model,
                                            style: GoogleFonts.comicNeue(
                                              fontSize: 12,
                                              color: Colors.black45,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        if (ram.isNotEmpty) ...[
                                          Text(
                                            "  ${ram}",
                                            style: GoogleFonts.comicNeue(
                                              fontSize: 12,
                                              color: Colors.teal.shade700,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                        if (storage.isNotEmpty) ...[
                                          Text(
                                            " / ${storage}",
                                            style: GoogleFonts.comicNeue(
                                              fontSize: 12,
                                              color: Colors.teal.shade700,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              // Purchase Price
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    "PKR",
                                    style: GoogleFonts.comicNeue(
                                      fontSize: 11,
                                      color: Colors.black45,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    price.toStringAsFixed(0),
                                    style: GoogleFonts.comicNeue(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w900,
                                      color: Colors.green.shade800,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

// ══════════════════════════════════════════════════════════════════
// CartItemTile — cart mein product image + editable qty + price
// ══════════════════════════════════════════════════════════════════
class CartItemTile extends StatefulWidget {
  final Map<String, dynamic> item;
  final int index;
  final OrderRequestController controller;

  const CartItemTile({
    super.key,
    required this.item,
    required this.index,
    required this.controller,
  });

  @override
  State<CartItemTile> createState() => _CartItemTileState();
}

class _CartItemTileState extends State<CartItemTile> {
  late TextEditingController qtyCtrl;
  late TextEditingController priceCtrl;

  @override
  void initState() {
    super.initState();
    qtyCtrl = TextEditingController(text: widget.item['requestQty'].toString());
    priceCtrl = TextEditingController(
      text: (widget.item['purchasePrice'] ?? 0).toString(),
    );
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
    priceCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final String brand = widget.item['brand'] ?? '';
    final String ram = widget.item['ram'] ?? '';
    final String storage = widget.item['storage'] ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
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
          // Product Image
          CreateOrderRequestScreen.buildUniversalImage(
            widget.item['image'],
            65,
            radius: 8,
          ),
          const SizedBox(width: 12),

          // Details
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "${widget.item['productName']}",
                  style: GoogleFonts.comicNeue(
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                    color: Colors.black,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (brand.isNotEmpty)
                  Text(
                    brand,
                    style: GoogleFonts.comicNeue(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.deepPurple,
                    ),
                  ),
                Text(
                  "Model: ${widget.item['model']}",
                  style: GoogleFonts.comicNeue(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.black54,
                  ),
                ),
                if (ram.isNotEmpty || storage.isNotEmpty)
                  Text(
                    [
                      if (ram.isNotEmpty) 'RAM: $ram',
                      if (storage.isNotEmpty) 'ROM: $storage',
                    ].join('  |  '),
                    style: GoogleFonts.comicNeue(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.teal.shade700,
                    ),
                  ),
                const SizedBox(height: 6),
                // Editable price
                SizedBox(
                  width: 130,
                  height: 36,
                  child: TextField(
                    controller: priceCtrl,
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
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 6,
                      ),
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
                          width: 2,
                        ),
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    onChanged: (val) {
                      double newPrice = double.tryParse(val) ?? 0;
                      setState(() => widget.item['purchasePrice'] = newPrice);
                      widget.controller.updateItemPrice(
                        widget.item['productId'],
                        newPrice,
                      );
                    },
                  ),
                ),
              ],
            ),
          ),

          // Qty + Total + Delete
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
                      setState(() => widget.item['requestQty'] = newQty);
                      widget.controller.updateItemQty(
                        widget.item['productId'],
                        newQty,
                      );
                    },
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "PKR ${((widget.item['purchasePrice'] ?? 0).toDouble() * (widget.item['requestQty'] as num).toDouble()).toStringAsFixed(0)}",
                  style: GoogleFonts.comicNeue(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    color: Colors.green.shade800,
                  ),
                ),
                IconButton(
                  padding: EdgeInsets.zero,
                  icon: const Icon(
                    Icons.delete_forever,
                    color: Colors.red,
                    size: 26,
                  ),
                  onPressed: () =>
                      widget.controller.removeFromCart(widget.index),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
