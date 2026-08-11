import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../controller/products_controller.dart';
import '../../models/product_model.dart';

class TopTrendingScreen extends StatefulWidget {
  const TopTrendingScreen({super.key});

  @override
  State<TopTrendingScreen> createState() => _TopTrendingScreenState();
}

class _TopTrendingScreenState extends State<TopTrendingScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _showZeroViews = false;
  bool _showZeroRatings = false;
  bool _showZeroReviews = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<ProductsController>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Top Trending Items'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Views'),
            Tab(text: 'Ratings'),
            Tab(text: 'Reviews'),
          ],
        ),
      ),
      body: Obx(() {
        // ✅ Sirf products — packages exclude hain
        final products = controller.productsOnly;

        return TabBarView(
          controller: _tabController,
          children: [
            _buildList(
              products: products,
              valueGetter: (p) => p.views.toDouble(),
              showZero: _showZeroViews,
              onToggleZero: (v) => setState(() => _showZeroViews = v),
              zeroLabel: 'Show 0 views',
              valueLabel: 'views',
              formatValue: (v) => v.toInt().toString(),
              // ✅ Views tab ke liye expand ki zaroorat nahi (koi user list nahi)
              expandable: false,
              reviewsOnly: false,
            ),
            _buildList(
              products: products,
              valueGetter: (p) => p.averageRating,
              showZero: _showZeroRatings,
              onToggleZero: (v) => setState(() => _showZeroRatings = v),
              zeroLabel: 'Show 0 ratings',
              valueLabel: 'rating',
              formatValue: (v) => v.toStringAsFixed(1),
              // ✅ Tap karne pe har ratings dene wale user ki detail khulegi
              expandable: true,
              // ✅ Ratings tab mein sab dikhein — comment ho ya na ho
              reviewsOnly: false,
            ),
            _buildList(
              products: products,
              valueGetter: (p) => p.totalReviews.toDouble(),
              showZero: _showZeroReviews,
              onToggleZero: (v) => setState(() => _showZeroReviews = v),
              zeroLabel: 'Show 0 reviews',
              valueLabel: 'reviews',
              formatValue: (v) => v.toInt().toString(),
              // ✅ Tap karne pe har review dene wale user ki detail khulegi
              expandable: true,
              // ✅ Sirf wo entries jinme actual likha hua comment ho — star
              // only (bina comment) ratings yahan expand mein nahi aayengi
              reviewsOnly: true,
            ),
          ],
        );
      }),
    );
  }

  Widget _buildList({
    required List<ProductModel> products,
    required double Function(ProductModel) valueGetter,
    required bool showZero,
    required void Function(bool) onToggleZero,
    required String zeroLabel,
    required String valueLabel,
    required String Function(double) formatValue,
    required bool expandable,
    required bool reviewsOnly,
  }) {
    var list = List<ProductModel>.from(products);
    if (!showZero) {
      list = list.where((p) => valueGetter(p) > 0).toList();
    }
    list.sort((a, b) => valueGetter(b).compareTo(valueGetter(a)));

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${list.length} products',
                style: GoogleFonts.comicNeue(
                  fontSize: 13,
                  color: Colors.white70, // ✅ dark background pe ab visible hai
                  fontWeight: FontWeight.w700,
                ),
              ),
              Row(
                children: [
                  Text(
                    zeroLabel,
                    style: GoogleFonts.comicNeue(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.white, // ✅ explicit white
                    ),
                  ),
                  Switch(value: showZero, onChanged: onToggleZero),
                ],
              ),
            ],
          ),
        ),
        Expanded(
          child: list.isEmpty
              ? const Center(child: Text('No products found'))
              : ListView.separated(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  itemCount: list.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final p = list[index];
                    return _ProductTile(
                      rank: index + 1,
                      product: p,
                      value: valueGetter(p),
                      valueLabel: valueLabel,
                      formatValue: formatValue,
                      expandable: expandable,
                      reviewsOnly: reviewsOnly,
                    );
                  },
                ),
        ),
      ],
    );
  }
}

// ✅ Ek review/rating record + uska user data (phone, referral code) joined
class _ReviewWithUser {
  final String userName;
  final double rating;
  final String comment;
  final String phone;
  final String referralCode;

  _ReviewWithUser({
    required this.userName,
    required this.rating,
    required this.comment,
    required this.phone,
    required this.referralCode,
  });
}

class _ProductTile extends StatefulWidget {
  final int rank;
  final ProductModel product;
  final double value;
  final String valueLabel;
  final String Function(double) formatValue;
  final bool expandable;
  final bool reviewsOnly;

  const _ProductTile({
    required this.rank,
    required this.product,
    required this.value,
    required this.valueLabel,
    required this.formatValue,
    this.expandable = false,
    this.reviewsOnly = false,
  });

  @override
  State<_ProductTile> createState() => _ProductTileState();
}

class _ProductTileState extends State<_ProductTile> {
  bool _expanded = false;
  Future<List<_ReviewWithUser>>? _reviewsFuture;

  void _toggleExpand() {
    if (!widget.expandable) return;
    setState(() {
      _expanded = !_expanded;
      // ✅ Sirf pehli dafa expand hone par fetch — dobara close/open pe
      // cache se hi dikhega, extra Firestore reads nahi hongi.
      _reviewsFuture ??= _fetchReviews();
    });
  }

  Future<List<_ReviewWithUser>> _fetchReviews() async {
    final String? pid = widget.product.id;
    if (pid == null || pid.isEmpty) return [];

    final db = FirebaseFirestore.instance;

    final reviewsSnap = await db
        .collection('products')
        .doc(pid)
        .collection('reviews')
        .orderBy('timestamp', descending: true)
        .get();

    final List<_ReviewWithUser> result = [];

    for (final doc in reviewsSnap.docs) {
      final data = doc.data();
      final String userId = (data['userId'] ?? '').toString();
      String phone = '';
      String referralCode = '';

      if (userId.isNotEmpty) {
        try {
          final userDoc = await db.collection('users').doc(userId).get();
          if (userDoc.exists) {
            final uData = userDoc.data() as Map<String, dynamic>;
            phone = (uData['phone'] ?? '').toString();
            referralCode = (uData['referralCode'] ?? '').toString();
          }
        } catch (_) {
          // Agar user doc read na ho paye, phone/referral khali reh jayenge
        }
      }

      final String comment = (data['comment'] ?? '').toString();

      // ✅ Reviews tab (reviewsOnly == true) mein sirf wahi entries jaayen
      // jinme user ne actual likha hua comment diya ho. Sirf star wali
      // (bina comment) rating yahan skip ho jayegi — wo sirf Ratings tab
      // mein hi dikhegi.
      if (widget.reviewsOnly && comment.trim().isEmpty) {
        continue;
      }

      result.add(
        _ReviewWithUser(
          userName: (data['userName'] ?? 'Unknown').toString(),
          rating: (data['rating'] is num)
              ? (data['rating'] as num).toDouble()
              : 0.0,
          comment: comment,
          phone: phone,
          referralCode: referralCode,
        ),
      );
    }

    return result;
  }

  void _copyPhone(String phone) {
    Clipboard.setData(ClipboardData(text: phone));
    Get.snackbar(
      "Copied",
      "Phone number copied: $phone",
      backgroundColor: Colors.green,
      colorText: Colors.white,
      duration: const Duration(seconds: 2),
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  Widget _buildStars(double rating) {
    final int full = rating.round().clamp(0, 5);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) {
        return Icon(
          i < full ? Icons.star : Icons.star_border,
          size: 16,
          color: Colors.amber,
        );
      }),
    );
  }

  Widget _buildReviewsPanel() {
    return FutureBuilder<List<_ReviewWithUser>>(
      future: _reviewsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Center(
              child: SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2.5),
              ),
            ),
          );
        }

        if (snapshot.hasError) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Text(
              "Couldn't load reviews.",
              style: GoogleFonts.comicNeue(color: Colors.red, fontSize: 12),
            ),
          );
        }

        final reviews = snapshot.data ?? [];
        if (reviews.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Text(
              widget.reviewsOnly
                  // ✅ Iska matlab is product par sirf star ratings di gayi
                  // hain, koi likha hua review nahi — Ratings tab check karein
                  ? "No written reviews yet — only star ratings given so far."
                  : "No reviews yet for this product.",
              style: GoogleFonts.comicNeue(color: Colors.black45, fontSize: 12),
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Divider(height: 20),
            ...reviews.map((r) => _buildReviewRow(r)).toList(),
          ],
        );
      },
    );
  }

  Widget _buildReviewRow(_ReviewWithUser r) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.black12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  r.userName,
                  style: GoogleFonts.comicNeue(
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                    color: Colors.black,
                  ),
                ),
              ),
              _buildStars(r.rating),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              // Referral Code
              if (r.referralCode.isNotEmpty) ...[
                Icon(Icons.share, size: 13, color: Colors.deepPurple.shade400),
                const SizedBox(width: 4),
                Text(
                  r.referralCode,
                  style: GoogleFonts.comicNeue(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Colors.deepPurple,
                  ),
                ),
                const SizedBox(width: 14),
              ],
              // Phone + Copy button
              if (r.phone.isNotEmpty) ...[
                Icon(Icons.phone, size: 13, color: Colors.green.shade700),
                const SizedBox(width: 4),
                Text(
                  r.phone,
                  style: GoogleFonts.comicNeue(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Colors.green.shade800,
                  ),
                ),
                const SizedBox(width: 4),
                InkWell(
                  onTap: () => _copyPhone(r.phone),
                  borderRadius: BorderRadius.circular(6),
                  child: const Padding(
                    padding: EdgeInsets.all(3),
                    child: Icon(Icons.copy, size: 14, color: Colors.black54),
                  ),
                ),
              ] else
                Text(
                  "No phone on file",
                  style: GoogleFonts.comicNeue(
                    fontSize: 11,
                    fontStyle: FontStyle.italic,
                    color: Colors.black38,
                  ),
                ),
            ],
          ),
          if (r.comment.trim().isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              r.comment,
              style: GoogleFonts.comicNeue(fontSize: 12, color: Colors.black87),
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.product;
    final specs = <String>[];
    if (product.modelNumber.isNotEmpty) specs.add(product.modelNumber);
    if ((product.ram ?? '').isNotEmpty) specs.add('${product.ram}GB RAM');
    if ((product.storage ?? '').isNotEmpty)
      specs.add('${product.storage}GB Storage');

    final String pointsStr = product.showDecimalPoints
        ? product.productPoints.toStringAsFixed(2)
        : product.productPoints.floor().toString();

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        // ✅ Poore card pe tap karne se expand/collapse hoga (sirf
        // ratings/reviews tab par — expandable == true)
        onTap: widget.expandable ? _toggleExpand : null,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.black12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 30,
                    child: Text(
                      '#${widget.rank}',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.orbitron(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.deepPurple,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // ✅ image size 56 → 84
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: SizedBox(
                      width: 84,
                      height: 84,
                      child: product.images.isNotEmpty
                          ? Image.network(
                              product.images[0],
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                color: Colors.grey.shade200,
                                child: const Icon(
                                  Icons.image_not_supported,
                                  color: Colors.black38,
                                ),
                              ),
                            )
                          : Container(
                              color: Colors.grey.shade200,
                              child: const Icon(
                                Icons.image_not_supported,
                                color: Colors.black38,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          product.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.comicNeue(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'ID: ${product.id ?? "-"}',
                          style: GoogleFonts.comicNeue(
                            fontSize: 11,
                            color: Colors.black45,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (specs.isNotEmpty) ...[
                          const SizedBox(height: 3),
                          Text(
                            specs.join(' · '),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.comicNeue(
                              fontSize: 12,
                              color: Colors.black87,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                        const SizedBox(height: 3),
                        Text(
                          '${product.brand.isNotEmpty ? product.brand : "-"} · ${product.category}'
                          '${product.subCategory.isNotEmpty ? " / ${product.subCategory}" : ""}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.comicNeue(
                            fontSize: 12,
                            color: Colors.black54,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Text(
                              'Rs. ${product.salePrice.toStringAsFixed(0)}',
                              style: GoogleFonts.comicNeue(
                                fontSize: 15,
                                fontWeight: FontWeight.w900,
                                color: Colors.black,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.amber.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.star,
                                    size: 13,
                                    color: Colors.amber,
                                  ),
                                  const SizedBox(width: 3),
                                  Text(
                                    '$pointsStr Pts',
                                    style: GoogleFonts.comicNeue(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.amber[900],
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
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.deepPurple.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          widget.formatValue(widget.value),
                          style: GoogleFonts.orbitron(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: Colors.deepPurple,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          widget.valueLabel,
                          style: GoogleFonts.comicNeue(
                            fontSize: 10,
                            color: Colors.deepPurple,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // ✅ Expand/Collapse indicator — sirf jab expandable ho
                  if (widget.expandable) ...[
                    const SizedBox(width: 4),
                    Icon(
                      _expanded
                          ? Icons.keyboard_arrow_up
                          : Icons.keyboard_arrow_down,
                      color: Colors.black45,
                    ),
                  ],
                ],
              ),
              // ✅ Expanded panel — har review/rating dene wale user ki detail
              if (widget.expandable && _expanded) _buildReviewsPanel(),
            ],
          ),
        ),
      ),
    );
  }
}
