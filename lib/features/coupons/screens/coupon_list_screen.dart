// lib/features/coupons/screens/coupon_list_screen.dart
//
// All coupons — stats, search, status / type filters, and quick actions on
// every card (toggle, details, edit, duplicate, delete, copy code).

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/pallete.dart';
import '../controllers/coupon_list_controller.dart';
import '../models/coupon_model.dart';
import 'add_coupon_screen.dart';
import 'widgets/coupon_preview_card.dart';
import 'widgets/coupon_ui.dart';

class CouponListScreen extends StatelessWidget {
  const CouponListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(CouponListController());

    return Scaffold(
      backgroundColor: Pallete.metalDark,
      appBar: AppBar(
        backgroundColor: Pallete.metalDark,
        elevation: 0,
        title: Text(
          'Coupons',
          style: GoogleFonts.orbitron(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: kCouponAccent,
        foregroundColor: Colors.black,
        onPressed: () => Get.to(() => const AddCouponScreen()),
        icon: const Icon(Icons.add),
        label: const Text(
          'Create Coupon',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(
            child: CircularProgressIndicator(color: kCouponAccent),
          );
        }

        final list = controller.filteredCoupons;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _StatsBar(controller: controller),
            _FilterBar(controller: controller),
            Expanded(
              child: controller.coupons.isEmpty
                  ? const _EmptyState(
                      icon: Icons.local_activity_outlined,
                      title: 'No coupons yet',
                      subtitle:
                          'Tap "Create Coupon" below to publish your first offer.',
                    )
                  : list.isEmpty
                  ? _EmptyState(
                      icon: Icons.search_off,
                      title: 'Nothing matches',
                      subtitle: 'Try changing the search or the filters.',
                      action: TextButton.icon(
                        onPressed: controller.clearFilters,
                        icon: const Icon(Icons.clear_all, size: 17),
                        label: const Text('Clear filters'),
                      ),
                    )
                  : LayoutBuilder(
                      builder: (context, constraints) {
                        final width = constraints.maxWidth;
                        int columns = 1;
                        if (width > 1400) {
                          columns = 3;
                        } else if (width > 900) {
                          columns = 2;
                        }
                        return GridView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 90),
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: columns,
                                mainAxisExtent: 250,
                                crossAxisSpacing: 16,
                                mainAxisSpacing: 16,
                              ),
                          itemCount: list.length,
                          itemBuilder: (context, index) => _CouponCard(
                            coupon: list[index],
                            controller: controller,
                          ),
                        );
                      },
                    ),
            ),
          ],
        );
      }),
    );
  }
}

// ─── STATS ────────────────────────────────────────────────────────────────

class _StatsBar extends StatelessWidget {
  final CouponListController controller;
  const _StatsBar({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient: kCouponHeaderGradient,
      ),
      child: Wrap(
        alignment: WrapAlignment.spaceAround,
        runSpacing: 14,
        children: [
          _StatItem(label: 'Total', value: '${controller.coupons.length}'),
          _StatItem(
            label: 'Live',
            value: '${controller.liveCount}',
            color: CouponStatus.live.color,
          ),
          _StatItem(
            label: 'Scheduled',
            value: '${controller.scheduledCount}',
            color: CouponStatus.scheduled.color,
          ),
          _StatItem(
            label: 'Expired',
            value: '${controller.expiredCount}',
            color: CouponStatus.expired.color,
          ),
          _StatItem(
            label: 'Paused',
            value: '${controller.pausedCount}',
            color: CouponStatus.paused.color,
          ),
          _StatItem(
            label: 'Redemptions',
            value: '${controller.totalRedemptions}',
            color: kCouponAccent,
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label, value;
  final Color? color;
  const _StatItem({required this.label, required this.value, this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: TextStyle(
              color: color ?? Colors.white,
              fontSize: 21,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 11.5),
          ),
        ],
      ),
    );
  }
}

// ─── FILTERS ──────────────────────────────────────────────────────────────

class _FilterBar extends StatelessWidget {
  final CouponListController controller;
  const _FilterBar({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          CouponSearchField(
            hint: 'Search by code, title or type...',
            onChanged: (v) => controller.searchQuery.value = v,
          ),
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                CouponChip(
                  label: 'All',
                  selected: controller.statusFilter.value == null &&
                      controller.typeFilter.value == null,
                  onTap: () {
                    controller.statusFilter.value = null;
                    controller.typeFilter.value = null;
                  },
                ),
                const SizedBox(width: 8),
                ...CouponStatus.values.map(
                  (s) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: CouponChip(
                      label: '${s.label} (${controller.countOf(s)})',
                      color: s.color,
                      selected: controller.statusFilter.value == s,
                      onTap: () => controller.statusFilter.value =
                          controller.statusFilter.value == s ? null : s,
                    ),
                  ),
                ),
                Container(
                  width: 1,
                  height: 22,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  color: kCouponBorder,
                ),
                const SizedBox(width: 8),
                ...CouponType.values.map(
                  (t) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: CouponChip(
                      label: t.label,
                      icon: t.icon,
                      selected: controller.typeFilter.value == t,
                      onTap: () => controller.typeFilter.value =
                          controller.typeFilter.value == t ? null : t,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── CARD ─────────────────────────────────────────────────────────────────

class _CouponCard extends StatelessWidget {
  final CouponModel coupon;
  final CouponListController controller;
  const _CouponCard({required this.coupon, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: kCouponSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kCouponBorder),
        boxShadow: const [
          BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, 3)),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
            child: Row(
              children: [
                _StatusBadge(status: coupon.status),
                const SizedBox(width: 8),
                if (coupon.usageLimitTotal > 0)
                  Expanded(
                    child: _UsageBar(coupon: coupon),
                  )
                else
                  Expanded(
                    child: Text(
                      '${coupon.usedCount} used · unlimited',
                      style: const TextStyle(
                        fontSize: 10.5,
                        color: Colors.white38,
                      ),
                    ),
                  ),
                Transform.scale(
                  scale: 0.7,
                  child: Switch(
                    value: coupon.isActive,
                    activeThumbColor: Colors.green,
                    onChanged: (_) => controller.toggleActive(coupon),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
              child: CouponPreviewCard(coupon: coupon, compact: true),
            ),
          ),
          const Divider(height: 1, color: kCouponBorder),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            child: Row(
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: Text(
                      'Updated ${DateFormat('dd MMM yy').format(coupon.updatedAt ?? coupon.createdAt)}',
                      style: const TextStyle(
                        fontSize: 10.5,
                        color: Colors.white38,
                      ),
                    ),
                  ),
                ),
                _iconButton(
                  Icons.copy_all_outlined,
                  'Copy code',
                  () async {
                    await Clipboard.setData(
                      ClipboardData(text: coupon.code),
                    );
                    Get.snackbar(
                      'Copied',
                      '${coupon.code} copied to the clipboard',
                      backgroundColor: Colors.blueGrey.shade800,
                      colorText: Colors.white,
                      duration: const Duration(seconds: 2),
                    );
                  },
                ),
                _iconButton(
                  Icons.info_outline,
                  'Details',
                  () => _showDetails(context),
                ),
                _iconButton(
                  Icons.edit_outlined,
                  'Edit',
                  () => Get.to(() => AddCouponScreen(editCoupon: coupon)),
                ),
                _iconButton(
                  Icons.content_copy,
                  'Duplicate',
                  () => controller.duplicateCoupon(coupon),
                ),
                _iconButton(
                  Icons.delete_outline,
                  'Delete',
                  () => _confirmDelete(context),
                  color: Colors.redAccent,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _iconButton(
    IconData icon,
    String tooltip,
    VoidCallback onPressed, {
    Color color = Colors.white54,
  }) {
    return IconButton(
      tooltip: tooltip,
      onPressed: onPressed,
      visualDensity: VisualDensity.compact,
      constraints: const BoxConstraints(minWidth: 34, minHeight: 34),
      padding: EdgeInsets.zero,
      icon: Icon(icon, size: 17, color: color),
    );
  }

  void _confirmDelete(BuildContext context) {
    Get.dialog(
      AlertDialog(
        backgroundColor: kCouponSurface,
        title: const Text('Delete Coupon', style: TextStyle(fontSize: 17)),
        content: Text(
          'Delete "${coupon.code}"? This cannot be undone.',
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              controller.deleteCoupon(coupon.id);
              Get.back();
            },
            child: const Text(
              'Delete',
              style: TextStyle(color: Colors.redAccent),
            ),
          ),
        ],
      ),
    );
  }

  void _showDetails(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => CouponDetailsDialog(coupon: coupon),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final CouponStatus status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: status.color.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: status.color.withValues(alpha: 0.6)),
      ),
      child: Text(
        status.label,
        style: TextStyle(
          fontSize: 9.5,
          fontWeight: FontWeight.w800,
          color: status.color,
        ),
      ),
    );
  }
}

class _UsageBar extends StatelessWidget {
  final CouponModel coupon;
  const _UsageBar({required this.coupon});

  @override
  Widget build(BuildContext context) {
    final ratio = coupon.usageLimitTotal == 0
        ? 0.0
        : (coupon.usedCount / coupon.usageLimitTotal).clamp(0.0, 1.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '${coupon.usedCount} / ${coupon.usageLimitTotal} used',
          style: const TextStyle(fontSize: 10.5, color: Colors.white54),
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: ratio,
            minHeight: 4,
            backgroundColor: Colors.white12,
            valueColor: AlwaysStoppedAnimation(
              ratio >= 1 ? Colors.redAccent : kCouponAccent,
            ),
          ),
        ),
      ],
    );
  }
}

// ─── DETAILS DIALOG ───────────────────────────────────────────────────────

class CouponDetailsDialog extends StatelessWidget {
  final CouponModel coupon;
  const CouponDetailsDialog({super.key, required this.coupon});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: kCouponSurface,
      insetPadding: const EdgeInsets.all(24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 620, maxHeight: 700),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 14, 10, 6),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      coupon.code,
                      style: GoogleFonts.orbitron(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  _StatusBadge(status: coupon.status),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(
                      Icons.close,
                      size: 19,
                      color: Colors.white54,
                    ),
                  ),
                ],
              ),
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(18, 6, 18, 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    CouponPreviewCard(coupon: coupon),
                    const SizedBox(height: 16),
                    _group('Benefit', [
                      _row('Type', coupon.type.label),
                      _row('Value', coupon.headline),
                      if (coupon.maxDiscountAmount > 0)
                        _row(
                          'Max discount',
                          'PKR ${_money(coupon.maxDiscountAmount)}',
                        ),
                      if (coupon.type == CouponType.freeDelivery)
                        _row(
                          'Delivery cap',
                          coupon.freeDeliveryCap > 0
                              ? 'PKR ${_money(coupon.freeDeliveryCap)}'
                              : 'Entire fee waived',
                        ),
                      if (coupon.type == CouponType.freeProduct)
                        _row(
                          'Free item',
                          '${coupon.freeProduct?.name ?? '-'} × ${coupon.freeProductQty}',
                        ),
                      if (coupon.type == CouponType.buyOneGetOne)
                        _row(
                          'Offer',
                          'Buy ${coupon.buyQuantity} → get ${coupon.getQuantity} free',
                        ),
                    ]),
                    _group('Rules', [
                      if (coupon.type.usesMinPurchase)
                        _row(
                          'Buy limit',
                          coupon.minPurchaseAmount > 0
                              ? 'PKR ${_money(coupon.minPurchaseAmount)}+ (any currency)'
                              : 'No minimum',
                        ),
                      _row(
                        'Total uses',
                        coupon.usageLimitTotal > 0
                            ? '${coupon.usedCount} / ${coupon.usageLimitTotal}'
                            : '${coupon.usedCount} used (unlimited)',
                      ),
                      _row(
                        'Per customer',
                        coupon.usageLimitPerCustomer > 0
                            ? '${coupon.usageLimitPerCustomer}'
                            : 'Unlimited',
                      ),
                      if (coupon.type.usesCartRules) ...[
                        _row('Auto apply', coupon.autoApply ? 'Yes' : 'No'),
                        _row(
                          'First order only',
                          coupon.firstOrderOnly ? 'Yes' : 'No',
                        ),
                      ],
                      _row(
                        'Validity',
                        '${DateFormat('dd MMM yyyy, h:mm a').format(coupon.startAt)}  →  '
                            '${DateFormat('dd MMM yyyy, h:mm a').format(coupon.endAt)}',
                      ),
                    ]),
                    if (coupon.type.usesProductScope)
                      _group('Applies To', [
                        _row('Scope', coupon.scope.label),
                        if (coupon.products.isNotEmpty)
                          _chips(coupon.products.map((p) => p.name).toList()),
                        if (coupon.categories.isNotEmpty)
                          _chips(coupon.categories),
                      ]),
                    _group('Audience', [
                      _row('Group', coupon.audience.label),
                      if (coupon.customers.isNotEmpty)
                        _chips(coupon.customers.map((c) => c.name).toList()),
                    ]),
                    _group('Locations', [
                      _row('Scope', coupon.locationScope.label),
                      if (coupon.locations.isNotEmpty)
                        _chips(
                          coupon.locations.map((l) => l.pathLabel).toList(),
                        ),
                    ]),
                    if (coupon.terms.trim().isNotEmpty)
                      _group('Terms & Conditions', [
                        Text(
                          coupon.terms,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.white70,
                            height: 1.4,
                          ),
                        ),
                      ]),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _money(double v) => NumberFormat('#,##0').format(v);

  Widget _group(String title, List<Widget> children) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title.toUpperCase(),
          style: const TextStyle(
            fontSize: 10.5,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.8,
            color: kCouponAccent,
          ),
        ),
        const SizedBox(height: 8),
        ...children,
      ],
    ),
  );

  Widget _row(String label, String value) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 120,
          child: Text(
            label,
            style: const TextStyle(fontSize: 11.5, color: Colors.white38),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    ),
  );

  Widget _chips(List<String> values) => Padding(
    padding: const EdgeInsets.only(top: 4),
    child: Wrap(
      spacing: 7,
      runSpacing: 7,
      children: values
          .map(
            (v) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
              decoration: BoxDecoration(
                color: kCouponSurfaceAlt,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: kCouponBorder),
              ),
              child: Text(
                v,
                style: const TextStyle(fontSize: 10.5, color: Colors.white70),
              ),
            ),
          )
          .toList(),
    ),
  );
}

// ─── EMPTY ────────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? action;

  const _EmptyState({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 46, color: Colors.white24),
          const SizedBox(height: 14),
          Text(
            title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12.5, color: Colors.white38),
            ),
          ),
          if (action != null) ...[const SizedBox(height: 12), action!],
        ],
      ),
    );
  }
}
