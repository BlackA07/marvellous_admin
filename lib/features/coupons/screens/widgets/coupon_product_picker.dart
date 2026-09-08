// lib/features/coupons/screens/widgets/coupon_product_picker.dart
//
// Product chooser. Two modes:
//   • multi  → which products the coupon covers (scope = specific products)
//   • single → the gift of a free-product coupon (exactly one)

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../controllers/coupon_editor_controller.dart';
import '../../models/coupon_model.dart';
import 'coupon_ui.dart';

/// Multi-select. Returns null on cancel, otherwise the new selection.
Future<List<CouponProductRef>?> showCouponProductPicker(
  BuildContext context, {
  required CouponEditorController controller,
  required List<CouponProductRef> initial,
}) {
  return showDialog<List<CouponProductRef>>(
    context: context,
    builder: (_) => _ProductPickerDialog(
      controller: controller,
      initial: initial,
      multiSelect: true,
    ),
  );
}

/// Single-select (the free gift). Returns null on cancel.
Future<CouponProductRef?> showCouponSingleProductPicker(
  BuildContext context, {
  required CouponEditorController controller,
  CouponProductRef? initial,
}) async {
  final result = await showDialog<List<CouponProductRef>>(
    context: context,
    builder: (_) => _ProductPickerDialog(
      controller: controller,
      initial: initial == null ? const [] : [initial],
      multiSelect: false,
    ),
  );
  if (result == null || result.isEmpty) return null;
  return result.first;
}

class _ProductPickerDialog extends StatefulWidget {
  final CouponEditorController controller;
  final List<CouponProductRef> initial;
  final bool multiSelect;

  const _ProductPickerDialog({
    required this.controller,
    required this.initial,
    required this.multiSelect,
  });

  @override
  State<_ProductPickerDialog> createState() => _ProductPickerDialogState();
}

class _ProductPickerDialogState extends State<_ProductPickerDialog> {
  late final List<CouponProductRef> _selected = List.of(widget.initial);
  String _query = '';
  String _category = 'All';

  @override
  void initState() {
    super.initState();
    widget.controller.ensureProducts();
  }

  List<CouponProductRef> _filtered(List<CouponProductRef> all) {
    final q = _query.trim().toLowerCase();
    return all.where((p) {
      if (_category != 'All' && p.category != _category) return false;
      if (q.isEmpty) return true;
      return p.name.toLowerCase().contains(q) ||
          p.category.toLowerCase().contains(q);
    }).toList();
  }

  void _toggle(CouponProductRef product) {
    setState(() {
      if (widget.multiSelect) {
        _selected.contains(product)
            ? _selected.remove(product)
            : _selected.add(product);
      } else {
        _selected
          ..clear()
          ..add(product);
      }
    });
    if (!widget.multiSelect) Navigator.pop(context, List.of(_selected));
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: kCouponSurface,
      insetPadding: const EdgeInsets.all(24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 640, maxHeight: 660),
        child: Obx(() {
          final all = widget.controller.allProducts;
          final categories = <String>{
            'All',
            ...all.map((p) => p.category).where((c) => c.trim().isNotEmpty),
          }.toList();
          final list = _filtered(all);

          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 16, 10, 10),
                child: Row(
                  children: [
                    const Icon(
                      Icons.inventory_2_outlined,
                      color: kCouponAccent,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        widget.multiSelect
                            ? 'Select Products'
                            : 'Select Free Product',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Refresh',
                      onPressed: () =>
                          widget.controller.ensureProducts(force: true),
                      icon: const Icon(
                        Icons.refresh,
                        size: 19,
                        color: Colors.white54,
                      ),
                    ),
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

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                child: CouponSearchField(
                  hint: 'Search by product or category...',
                  onChanged: (v) => setState(() => _query = v),
                ),
              ),

              if (categories.length > 1)
                SizedBox(
                  height: 46,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.fromLTRB(18, 10, 18, 0),
                    itemCount: categories.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (_, i) => CouponChip(
                      label: categories[i],
                      selected: _category == categories[i],
                      onTap: () => setState(() => _category = categories[i]),
                    ),
                  ),
                ),

              const SizedBox(height: 8),
              const Divider(height: 1, color: kCouponBorder),

              Expanded(
                child: widget.controller.isLoadingProducts.value && all.isEmpty
                    ? const Center(
                        child: CircularProgressIndicator(color: kCouponAccent),
                      )
                    : list.isEmpty
                    ? const Center(
                        child: Text(
                          'No products found',
                          style: TextStyle(color: Colors.white38),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        itemCount: list.length,
                        itemBuilder: (context, i) {
                          final product = list[i];
                          final selected = _selected.contains(product);
                          return _ProductRow(
                            product: product,
                            selected: selected,
                            multiSelect: widget.multiSelect,
                            onTap: () => _toggle(product),
                          );
                        },
                      ),
              ),

              if (widget.multiSelect) ...[
                const Divider(height: 1, color: kCouponBorder),
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 12, 18, 14),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${_selected.length} selected',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: _selected.isEmpty
                            ? null
                            : () => setState(_selected.clear),
                        child: const Text('Clear'),
                      ),
                      const SizedBox(width: 6),
                      FilledButton(
                        onPressed: () =>
                            Navigator.pop(context, List.of(_selected)),
                        style: FilledButton.styleFrom(
                          backgroundColor: kCouponAccent,
                          foregroundColor: Colors.black,
                        ),
                        child: const Text('Done'),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          );
        }),
      ),
    );
  }
}

class _ProductRow extends StatelessWidget {
  final CouponProductRef product;
  final bool selected;
  final bool multiSelect;
  final VoidCallback onTap;

  const _ProductRow({
    required this.product,
    required this.selected,
    required this.multiSelect,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(9),
        decoration: BoxDecoration(
          color: selected
              ? kCouponAccent.withValues(alpha: 0.10)
              : kCouponSurfaceAlt,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? kCouponAccent : kCouponBorder,
          ),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                width: 42,
                height: 42,
                child: product.image.isEmpty
                    ? Container(
                        color: Colors.white10,
                        child: const Icon(
                          Icons.image_not_supported_outlined,
                          size: 17,
                          color: Colors.white24,
                        ),
                      )
                    : Image.network(
                        product.image,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          color: Colors.white10,
                          child: const Icon(
                            Icons.broken_image_outlined,
                            size: 17,
                            color: Colors.white24,
                          ),
                        ),
                      ),
              ),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    [
                      if (product.category.isNotEmpty) product.category,
                      'PKR ${NumberFormat('#,##0').format(product.price)}',
                    ].join(' · '),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11.5,
                      color: Colors.white38,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              multiSelect
                  ? (selected
                        ? Icons.check_box_rounded
                        : Icons.check_box_outline_blank_rounded)
                  : (selected
                        ? Icons.radio_button_checked
                        : Icons.radio_button_unchecked),
              size: 20,
              color: selected ? kCouponAccent : Colors.white24,
            ),
          ],
        ),
      ),
    );
  }
}
