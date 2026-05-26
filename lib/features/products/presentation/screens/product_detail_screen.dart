import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/product_model.dart';
import '../../controller/products_controller.dart';
import 'add_product_screen.dart';

// ✅ HELPER: Strictly truncates decimals without rounding up
String formatTruncated(double value, bool keepDecimals) {
  if (value <= 0) return "0";
  if (!keepDecimals) {
    return value.truncate().toString(); // e.g. 9.99 -> "9"
  } else {
    String str = value.toString();
    int dotIndex = str.indexOf('.');
    if (dotIndex != -1 && str.length > dotIndex + 4) {
      return str.substring(0, dotIndex + 4); // e.g. 14.70588 -> "14.705"
    }
    return str;
  }
}

class ProductDetailScreen extends StatefulWidget {
  final ProductModel product;

  const ProductDetailScreen({Key? key, required this.product})
    : super(key: key);

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  final ProductsController controller = Get.find<ProductsController>();
  int _currentImageIndex = 0;

  // Magnifier Variables
  Offset? _dragPosition;
  bool _showMagnifier = false;
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) FocusScope.of(context).requestFocus(_focusNode);
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  void _handleKeyEvent(RawKeyEvent event) {
    if (event is RawKeyDownEvent) {
      if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
        _nextImage();
      } else if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
        _previousImage();
      }
    }
  }

  void _nextImage() {
    setState(() {
      _currentImageIndex++;
      if (_currentImageIndex >= widget.product.images.length) {
        _currentImageIndex = 0;
      }
    });
  }

  void _previousImage() {
    setState(() {
      _currentImageIndex--;
      if (_currentImageIndex < 0) {
        _currentImageIndex = widget.product.images.length - 1;
      }
    });
  }

  void _showFullScreenImage(BuildContext context, int initialIndex) {
    showDialog(
      context: context,
      builder: (context) {
        return FullScreenImageViewer(
          images: widget.product.images,
          initialIndex: initialIndex,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return RawKeyboardListener(
      focusNode: _focusNode,
      autofocus: true,
      onKey: _handleKeyEvent,
      child: Scaffold(
        backgroundColor: const Color(0xFF1E1E2C),
        appBar: AppBar(
          backgroundColor: const Color(0xFF1E1E2C),
          elevation: 0,
          toolbarHeight: 80,
          title: Text(
            widget.product.name,
            style: GoogleFonts.orbitron(color: Colors.white),
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.cyanAccent),
            onPressed: () => Get.back(),
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.only(top: 10, right: 10),
              child: IconButton(
                iconSize: 28,
                icon: const Icon(Icons.edit, color: Colors.white),
                onPressed: () {
                  Get.to(() => AddProductScreen(productToEdit: widget.product));
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 10, right: 20),
              child: IconButton(
                iconSize: 28,
                icon: const Icon(Icons.delete, color: Colors.redAccent),
                onPressed: () {
                  Get.defaultDialog(
                    title: "Delete Product?",
                    titleStyle: GoogleFonts.orbitron(color: Colors.white),
                    backgroundColor: const Color(0xFF2A2D3E),
                    middleText:
                        "Are you sure you want to permanently delete ${widget.product.name}?",
                    middleTextStyle: const TextStyle(color: Colors.white70),
                    textConfirm: "Delete",
                    textCancel: "Cancel",
                    confirmTextColor: Colors.white,
                    buttonColor: Colors.redAccent,
                    onConfirm: () {
                      if (widget.product.id != null) {
                        controller.deleteProduct(widget.product.id!);
                        Get.back();
                        Get.back();
                      }
                    },
                  );
                },
              ),
            ),
          ],
        ),
        body: LayoutBuilder(
          builder: (context, constraints) {
            bool isDesktop = constraints.maxWidth > 900;
            return SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  isDesktop
                      ? Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(flex: 4, child: _buildImageGallery()),
                            const SizedBox(width: 30),
                            Expanded(flex: 6, child: _buildProductDetails()),
                          ],
                        )
                      : Column(
                          children: [
                            _buildImageGallery(),
                            const SizedBox(height: 20),
                            _buildProductDetails(),
                          ],
                        ),

                  const SizedBox(height: 40),
                  // ✅ NEW: COMMISSION DISTRIBUTION CHART INJECTED HERE
                  _CommissionDistributionChart(product: widget.product),
                  const SizedBox(height: 40),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildImageGallery() {
    bool hasImages = widget.product.images.isNotEmpty;
    return Stack(
      children: [
        Container(
          height: 400,
          width: double.infinity,
          decoration: BoxDecoration(
            color: const Color(0xFF2A2D3E),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white10),
          ),
          child: !hasImages
              ? const Center(
                  child: Icon(
                    Icons.image_not_supported,
                    size: 60,
                    color: Colors.white24,
                  ),
                )
              : GestureDetector(
                  onTap: () =>
                      _showFullScreenImage(context, _currentImageIndex),
                  onLongPressStart: (details) {
                    setState(() {
                      _showMagnifier = true;
                      _dragPosition = details.localPosition;
                    });
                  },
                  onLongPressMoveUpdate: (details) {
                    setState(() {
                      _dragPosition = details.localPosition;
                    });
                  },
                  onLongPressEnd: (details) {
                    setState(() {
                      _showMagnifier = false;
                      _dragPosition = null;
                    });
                  },
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Image.network(
                            widget.product.images[_currentImageIndex],
                            fit: BoxFit.contain,
                            loadingBuilder: (_, child, progress) =>
                                progress == null
                                ? child
                                : const Center(
                                    child: CircularProgressIndicator(
                                      color: Colors.cyanAccent,
                                    ),
                                  ),
                            errorBuilder: (_, __, ___) => const Icon(
                              Icons.broken_image,
                              color: Colors.white24,
                              size: 60,
                            ),
                          ),
                        ),
                      ),
                      if (_showMagnifier && _dragPosition != null)
                        Positioned(
                          left: _dragPosition!.dx - 60,
                          top: _dragPosition!.dy - 60,
                          child: RawMagnifier(
                            decoration: const MagnifierDecoration(
                              shape: CircleBorder(
                                side: BorderSide(
                                  color: Colors.cyanAccent,
                                  width: 3,
                                ),
                              ),
                              opacity: 1.0,
                            ),
                            size: const Size(120, 120),
                            magnificationScale: 2.0,
                            focalPointOffset: Offset(
                              _dragPosition!.dx - 60,
                              _dragPosition!.dy - 60,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
        ),
        if (hasImages)
          Positioned(
            bottom: 15,
            right: 15,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.7),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                "${_currentImageIndex + 1} / ${widget.product.images.length}",
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        if (hasImages && widget.product.images.length > 1) ...[
          Positioned(
            left: 10,
            top: 0,
            bottom: 0,
            child: Center(
              child: IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    color: Colors.black45,
                    borderRadius: BorderRadius.circular(50),
                  ),
                  child: const Icon(
                    Icons.arrow_back_ios,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                onPressed: _previousImage,
              ),
            ),
          ),
          Positioned(
            right: 10,
            top: 0,
            bottom: 0,
            child: Center(
              child: IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    color: Colors.black45,
                    borderRadius: BorderRadius.circular(50),
                  ),
                  child: const Icon(
                    Icons.arrow_forward_ios,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                onPressed: _nextImage,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildProductDetails() {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('admin_settings')
          .doc('global_config')
          .snapshots(),
      builder: (context, snapshot) {
        // Safe defaults
        double profitPerPoint = 100.0;
        bool showDecimals = true;

        if (snapshot.hasData && snapshot.data!.exists) {
          final data = snapshot.data!.data() as Map<String, dynamic>;
          profitPerPoint =
              double.tryParse(data['profitPerPoint']?.toString() ?? '100.0') ??
              100.0;
          showDecimals =
              data['showDecimals']?.toString().toLowerCase() == 'true' ||
              data['showDecimals'] == true;
        }

        double grossProfit =
            widget.product.salePrice - widget.product.purchasePrice;
        if (grossProfit < 0) grossProfit = 0;

        double calculatedPoints = 0;
        if (profitPerPoint > 0) {
          calculatedPoints = grossProfit / profitPerPoint;
        }

        String displayPoints = formatTruncated(calculatedPoints, showDecimals);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ✅ NEW: Firestore Product ID (UID) Badge Added Here
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              margin: const EdgeInsets.only(bottom: 15),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.white24),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.fingerprint,
                    color: Colors.cyanAccent,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    "Product ID: ${widget.product.id ?? 'Unknown'}",
                    style: GoogleFonts.comicNeue(
                      color: Colors.white70,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.1,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.cyanAccent.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.cyanAccent),
              ),
              child: Text(
                widget.product.brand,
                style: const TextStyle(
                  color: Colors.cyanAccent,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 15),
            Text(
              widget.product.name,
              style: GoogleFonts.orbitron(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              "Model: ${widget.product.modelNumber}",
              style: GoogleFonts.comicNeue(color: Colors.white54, fontSize: 16),
            ),
            const SizedBox(height: 30),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF2A2D3E),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Price",
                              style: TextStyle(color: Colors.white54),
                            ),
                            Text(
                              "PKR ${widget.product.salePrice}",
                              style: GoogleFonts.comicNeue(
                                color: Colors.greenAccent,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        height: 40,
                        width: 1,
                        color: Colors.white10,
                        margin: const EdgeInsets.symmetric(horizontal: 10),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Stock",
                              style: TextStyle(color: Colors.white54),
                            ),
                            Text(
                              "${widget.product.stockQuantity}",
                              style: GoogleFonts.comicNeue(
                                color: Colors.white,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const Icon(Icons.star, color: Colors.amber, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        "Earned Points: $displayPoints", // ✅ FIX Applied
                        style: const TextStyle(
                          color: Colors.amber,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Text(
              "Description",
              style: GoogleFonts.orbitron(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: const Color(0xFF2A2D3E),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                widget.product.description.isEmpty
                    ? "No description available."
                    : widget.product.description,
                style: GoogleFonts.comicNeue(
                  color: Colors.white70,
                  fontSize: 14,
                ),
              ),
            ),
            const SizedBox(height: 20),
            _buildInfoRow("Category", widget.product.category),
            _buildInfoRow("Sub-Category", widget.product.subCategory),
            _buildInfoRow("Location", widget.product.deliveryLocation),
            _buildInfoRow("Warranty", widget.product.warranty),
            const SizedBox(height: 20),
            Text(
              "Vendor Information",
              style: GoogleFonts.orbitron(
                color: Colors.purpleAccent,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),

            // ✅ FIX: Vendor Real Name & Store Name fetched safely
            FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance
                  .collection('vendors')
                  .doc(widget.product.vendorId)
                  .get(),
              builder: (context, vSnap) {
                String storeName = "null";
                String ownerName = "null";

                if (vSnap.hasData && vSnap.data!.exists) {
                  var vData = vSnap.data!.data() as Map<String, dynamic>;
                  storeName = vData['storeName']?.toString() ?? "null";
                  ownerName = vData['ownerName']?.toString() ?? "null";
                }

                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const CircleAvatar(
                    backgroundColor: Colors.white10,
                    child: Icon(Icons.store, color: Colors.white),
                  ),
                  title: Text(
                    "ID: ${widget.product.vendorId}",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 5),
                    child: Text(
                      "Store: $storeName\nOwner: $ownerName",
                      style: const TextStyle(
                        color: Colors.white70,
                        height: 1.4,
                        fontSize: 14,
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Text(
            "$label: ",
            style: const TextStyle(
              color: Colors.white54,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          Text(
            value,
            style: const TextStyle(color: Colors.white, fontSize: 16),
          ),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// ✅ NEW WIDGET: COMMISSION DISTRIBUTION CHART
// ════════════════════════════════════════════════════════════════════════════

class _CommissionDistributionChart extends StatefulWidget {
  final ProductModel product;

  const _CommissionDistributionChart({required this.product});

  @override
  State<_CommissionDistributionChart> createState() =>
      _CommissionDistributionChartState();
}

class _CommissionDistributionChartState
    extends State<_CommissionDistributionChart> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  bool isLoading = true;
  double mlmDistributionPercent = 56.95;
  double cashbackPercent = 14.705;
  double diamondShoppingWalletPercent = 25.0;
  int totalLevels = 13;
  Map<int, double> levelPercentages = {};

  double profitPerPoint = 100.0;
  bool showDecimals = true;

  @override
  void initState() {
    super.initState();
    _fetchSettings();
  }

  Future<void> _fetchSettings() async {
    try {
      DocumentSnapshot varDoc = await _db
          .collection('admin_settings')
          .doc('mlm_variables')
          .get();
      DocumentSnapshot configDoc = await _db
          .collection('admin_settings')
          .doc('global_config')
          .get();

      if (varDoc.exists) {
        var data = varDoc.data() as Map<String, dynamic>;
        mlmDistributionPercent =
            double.tryParse(
              data['mlmDistributionPercent']?.toString() ?? '56.95',
            ) ??
            56.95;
        cashbackPercent =
            double.tryParse(data['cashbackPercent']?.toString() ?? '14.705') ??
            14.705;
        diamondShoppingWalletPercent =
            double.tryParse(
              data['diamondShoppingWalletPercent']?.toString() ?? '25.0',
            ) ??
            25.0;
        totalLevels =
            int.tryParse(data['totalLevels']?.toString() ?? '13') ?? 13;
      }

      if (configDoc.exists) {
        var cData = configDoc.data() as Map<String, dynamic>;
        profitPerPoint =
            double.tryParse(cData['profitPerPoint']?.toString() ?? '100.0') ??
            100.0;
        showDecimals =
            cData['showDecimals']?.toString().toLowerCase() == 'true' ||
            cData['showDecimals'] == true;
      }

      QuerySnapshot levelsSnap = await _db
          .collection('mlm_settings')
          .doc('config')
          .collection('commissions')
          .get();
      if (levelsSnap.docs.isNotEmpty) {
        for (var doc in levelsSnap.docs) {
          if (doc.id.startsWith('level_')) {
            int levelNum = int.tryParse(doc.id.split('_').last) ?? 0;
            double pct =
                double.tryParse(
                  (doc.data() as Map<String, dynamic>)['percentage']
                          ?.toString() ??
                      '0.0',
                ) ??
                0.0;
            levelPercentages[levelNum] = pct;
          }
        }
      } else {
        for (int i = 1; i <= totalLevels; i++) {
          levelPercentages[i] = i == 1 ? 14.705 : (i == 2 ? 13.235 : 10.0);
        }
      }

      if (mounted) setState(() => isLoading = false);
    } catch (e) {
      debugPrint("Commission Chart Error: $e");
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.cyanAccent),
      );
    }

    double grossProfit =
        widget.product.salePrice - widget.product.purchasePrice;
    if (grossProfit < 0) grossProfit = 0;

    double totalCommissionFund = grossProfit * (mlmDistributionPercent / 100);

    double calculatedPoints = profitPerPoint > 0
        ? grossProfit / profitPerPoint
        : 0;
    String displayPoints = formatTruncated(calculatedPoints, showDecimals);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF2A2D3E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Info
          Padding(
            padding: const EdgeInsets.all(25),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Commission Distribution",
                  style: GoogleFonts.orbitron(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _infoText(
                      "Purchase Price:",
                      widget.product.purchasePrice.truncate().toString(),
                    ),
                    _infoText(
                      "Sale Price:",
                      widget.product.salePrice.truncate().toString(),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _infoText(
                      "Gross Profit:",
                      grossProfit.truncate().toString(),
                      color: Colors.greenAccent,
                    ),
                    _infoText("Points:", displayPoints, color: Colors.amber),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _infoText(
                      "Commission %:",
                      formatTruncated(mlmDistributionPercent, true) + "%",
                    ), // Exact Percent Truncated
                    _infoText(
                      "Total Commission Fund:",
                      "PKR ${formatTruncated(totalCommissionFund, true)}",
                      color: Colors.amberAccent,
                      size: 16,
                    ),
                  ],
                ),
              ],
            ),
          ),

          // ✅ NEW FULL WIDTH TABLE
          Table(
            border: TableBorder.all(color: Colors.white12, width: 1.5),
            columnWidths: const {
              0: FlexColumnWidth(1.4),
              1: FlexColumnWidth(1.6),
              2: FlexColumnWidth(2.5),
              3: FlexColumnWidth(2.5),
              4: FlexColumnWidth(2.5),
              5: FlexColumnWidth(2.5),
            },
            children: [
              TableRow(
                decoration: const BoxDecoration(color: Colors.black38),
                children: [
                  _tableHeader("Lvl"),
                  _tableHeader("%"),
                  _tableHeader("Bronze", color: Colors.brown.shade300),
                  _tableHeader("Silver", color: Colors.grey.shade400),
                  _tableHeader("Gold", color: Colors.amber),
                  _tableHeader("Diamond", color: Colors.cyanAccent),
                ],
              ),
              _buildTableRow("Cash Back", cashbackPercent, totalCommissionFund),
              for (int i = 1; i <= totalLevels; i++)
                _buildTableRow(
                  i == 1 ? "Direct" : "$i",
                  levelPercentages[i] ?? 0.0,
                  totalCommissionFund,
                ),
            ],
          ),
        ],
      ),
    );
  }

  TableRow _buildTableRow(String lvlLabel, double percent, double totalFund) {
    double baseAmount = totalFund * (percent / 100);

    return TableRow(
      children: [
        _cell(lvlLabel, isBold: true),
        _cell(formatTruncated(percent, true)), // Show exact truncated percent
        _rankTableCell(baseAmount, 25.0),
        _rankTableCell(baseAmount, 50.0),
        _rankTableCell(baseAmount, 75.0),
        _rankTableCell(baseAmount, 100.0),
      ],
    );
  }

  Widget _cell(String text, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 4),
      child: Center(
        child: Text(
          text,
          style: GoogleFonts.comicNeue(
            color: isBold ? Colors.white : Colors.white70,
            fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
            fontSize: 16,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _tableHeader(String text, {Color color = Colors.white}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 4),
      child: Center(
        child: Text(
          text,
          style: GoogleFonts.comicNeue(
            color: color,
            fontWeight: FontWeight.w900,
            fontSize: 18,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _rankTableCell(double baseAmount, double rankPercentage) {
    double totalForRank = baseAmount * (rankPercentage / 100);
    double shoppingWallet = totalForRank * (diamondShoppingWalletPercent / 100);
    double mainWallet = totalForRank - shoppingWallet;

    if (totalForRank <= 0) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Center(
          child: Text(
            "0",
            style: TextStyle(
              color: Colors.redAccent,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Truncate Money completely (No decimals inside boxes)
          Text(
            totalForRank.truncate().toString(),
            style: const TextStyle(
              color: Colors.redAccent,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          Container(
            height: 1.5,
            width: double.infinity,
            color: Colors.white24,
            margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Text(
                mainWallet.truncate().toString(),
                style: const TextStyle(
                  color: Colors.blueAccent,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Container(height: 16, width: 1.5, color: Colors.white24),
              Text(
                shoppingWallet.truncate().toString(),
                style: const TextStyle(
                  color: Colors.greenAccent,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _infoText(
    String label,
    String value, {
    Color color = Colors.white,
    double size = 16,
  }) {
    return Row(
      children: [
        Text(
          "$label ",
          style: TextStyle(
            color: Colors.white54,
            fontSize: size,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: size,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// FULL SCREEN IMAGE VIEWER
// ════════════════════════════════════════════════════════════════════════════

class FullScreenImageViewer extends StatefulWidget {
  final List<String> images;
  final int initialIndex;

  const FullScreenImageViewer({
    Key? key,
    required this.images,
    required this.initialIndex,
  }) : super(key: key);

  @override
  State<FullScreenImageViewer> createState() => _FullScreenImageViewerState();
}

class _FullScreenImageViewerState extends State<FullScreenImageViewer> {
  late PageController _pageController;
  late int _currentIndex;
  final FocusNode _dialogFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _dialogFocusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _dialogFocusNode.dispose();
    super.dispose();
  }

  void _goToNext() {
    setState(() {
      _currentIndex++;
      if (_currentIndex >= widget.images.length) _currentIndex = 0;
      _pageController.jumpToPage(_currentIndex);
    });
  }

  void _goToPrevious() {
    setState(() {
      _currentIndex--;
      if (_currentIndex < 0) _currentIndex = widget.images.length - 1;
      _pageController.jumpToPage(_currentIndex);
    });
  }

  @override
  Widget build(BuildContext context) {
    return RawKeyboardListener(
      focusNode: _dialogFocusNode,
      onKey: (event) {
        if (event is RawKeyDownEvent) {
          if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
            _goToNext();
          } else if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
            _goToPrevious();
          } else if (event.logicalKey == LogicalKeyboardKey.escape) {
            Navigator.pop(context);
          }
        }
      },
      child: Dialog(
        backgroundColor: Colors.black,
        insetPadding: EdgeInsets.zero,
        child: Stack(
          alignment: Alignment.center,
          children: [
            PageView.builder(
              controller: _pageController,
              itemCount: widget.images.length,
              onPageChanged: (index) {
                setState(() {
                  _currentIndex = index;
                });
              },
              itemBuilder: (context, index) {
                return InteractiveViewer(
                  minScale: 0.1,
                  maxScale: 5.0,
                  child: Center(
                    child: Image.network(
                      widget.images[index],
                      fit: BoxFit.contain,
                      loadingBuilder: (_, child, progress) => progress == null
                          ? child
                          : const Center(
                              child: CircularProgressIndicator(
                                color: Colors.cyanAccent,
                              ),
                            ),
                      errorBuilder: (_, __, ___) => const Icon(
                        Icons.broken_image,
                        color: Colors.white54,
                        size: 80,
                      ),
                    ),
                  ),
                );
              },
            ),
            Positioned(
              top: 40,
              right: 20,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 30),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            Positioned(
              bottom: 40,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  "${_currentIndex + 1} / ${widget.images.length}",
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            if (widget.images.length > 1) ...[
              Positioned(
                left: 10,
                child: IconButton(
                  icon: const Icon(
                    Icons.arrow_back_ios,
                    color: Colors.white,
                    size: 40,
                  ),
                  onPressed: _goToPrevious,
                ),
              ),
              Positioned(
                right: 10,
                child: IconButton(
                  icon: const Icon(
                    Icons.arrow_forward_ios,
                    color: Colors.white,
                    size: 40,
                  ),
                  onPressed: _goToNext,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
