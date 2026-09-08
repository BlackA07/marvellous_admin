// lib/features/coupons/screens/widgets/coupon_form_parts.dart
//
// The sections of the Create / Edit Coupon screen. Each one reads straight
// from CouponEditorController, so the form and the live preview never drift.
//
// Sections only render the fields that matter for the chosen coupon type — a
// registration-fee coupon, for example, never shows product or cart rules.

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../controllers/coupon_editor_controller.dart';
import '../../models/coupon_design_model.dart';
import '../../models/coupon_model.dart';
import '../coupon_designs_screen.dart';
import 'coupon_customer_picker.dart';
import 'coupon_location_picker.dart';
import 'coupon_product_picker.dart';
import 'coupon_ui.dart';

// ─── 1. DESIGN PICKER ─────────────────────────────────────────────────────

/// Pick one of the saved card designs. The styling itself is edited on the
/// Coupon Designs screen — here you only choose the look.
class CouponDesignSection extends StatelessWidget {
  final CouponEditorController controller;
  const CouponDesignSection({super.key, required this.controller});

  Future<void> _openDesigns() async {
    await Get.to(() => const CouponDesignsScreen());
    await controller.ensureDesigns(force: true);
  }

  @override
  Widget build(BuildContext context) {
    return CouponSection(
      title: 'Card Design',
      icon: Icons.palette_outlined,
      subtitle: 'Pick the look of the coupon card',
      trailing: TextButton.icon(
        onPressed: _openDesigns,
        icon: const Icon(Icons.tune, size: 15),
        label: const Text('Manage', style: TextStyle(fontSize: 12)),
        style: TextButton.styleFrom(foregroundColor: kCouponAccent),
      ),
      child: Obx(() {
        final designs = controller.allDesigns;
        final selectedId = controller.designId.value;

        if (controller.isLoadingDesigns.value && designs.isEmpty) {
          return const SizedBox(
            height: 60,
            child: Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: kCouponAccent,
                ),
              ),
            ),
          );
        }

        if (designs.isEmpty) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const CouponHint(
                text:
                    'No designs saved yet. The coupon will use the default '
                    'look until you create one.',
                icon: Icons.brush_outlined,
                color: Colors.orangeAccent,
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 42,
                child: OutlinedButton.icon(
                  onPressed: _openDesigns,
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Create a design'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: kCouponAccent,
                    side: const BorderSide(color: kCouponAccent),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          );
        }

        return SizedBox(
          height: 104,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: designs.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (context, i) {
              final design = designs[i];
              return _DesignSwatch(
                design: design,
                selected: design.id == selectedId,
                onTap: () => controller.applyDesign(design),
              );
            },
          ),
        );
      }),
    );
  }
}

class _DesignSwatch extends StatelessWidget {
  final CouponDesignModel design;
  final bool selected;
  final VoidCallback onTap;

  const _DesignSwatch({
    required this.design,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final accent = CouponModel.colorFromHex(design.accentColorHex);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: 150,
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: selected
              ? kCouponAccent.withValues(alpha: 0.10)
              : kCouponSurfaceAlt,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? kCouponAccent : kCouponBorder,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: CouponModel.colorFromHex(design.backgroundColorHex),
                  borderRadius: BorderRadius.circular(9),
                  border: Border.all(color: accent.withValues(alpha: 0.6)),
                ),
                alignment: Alignment.center,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.local_activity, size: 15, color: accent),
                    const SizedBox(width: 6),
                    Text(
                      '20% OFF',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        color: CouponModel.colorFromHex(design.textColorHex),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Expanded(
                  child: Text(
                    design.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: selected ? Colors.white : Colors.white60,
                    ),
                  ),
                ),
                if (selected)
                  const Icon(
                    Icons.check_circle,
                    size: 14,
                    color: kCouponAccent,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─── 2. TYPE ──────────────────────────────────────────────────────────────

class CouponTypeSection extends StatelessWidget {
  final CouponEditorController controller;
  const CouponTypeSection({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return CouponSection(
      title: 'Coupon Type',
      icon: Icons.style_outlined,
      subtitle: 'What the customer gets',
      child: Obx(() {
        // Read the Rx here: LayoutBuilder's callback runs later, during layout,
        // so a read inside it would not register with this Obx.
        final selected = controller.type.value;
        return LayoutBuilder(
          builder: (context, constraints) {
            final columns = constraints.maxWidth > 560 ? 2 : 1;
            const spacing = 10.0;
            final width =
                (constraints.maxWidth - spacing * (columns - 1)) / columns;
            return Wrap(
              spacing: spacing,
              runSpacing: spacing,
              children: CouponType.values.map((type) {
                return SizedBox(
                  width: width,
                  child: CouponOptionTile(
                    icon: type.icon,
                    title: type.label,
                    subtitle: type.hint,
                    selected: selected == type,
                    onTap: () => controller.type.value = type,
                  ),
                );
              }).toList(),
            );
          },
        );
      }),
    );
  }
}

// ─── 3. BENEFIT VALUE (changes with the type) ─────────────────────────────

class CouponBenefitSection extends StatelessWidget {
  final CouponEditorController controller;
  const CouponBenefitSection({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final type = controller.type.value;
      return CouponSection(
        title: 'Discount Value',
        icon: Icons.calculate_outlined,
        subtitle: type.hint,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: _fieldsFor(type),
        ),
      );
    });
  }

  List<Widget> _fieldsFor(CouponType type) {
    switch (type) {
      case CouponType.percentageDiscount:
        return [
          CouponTextField(
            controller: controller.discountValueController,
            label: 'Discount percentage',
            hint: 'e.g. 20',
            icon: Icons.percent_rounded,
            numeric: true,
            helper: 'Between 1 and 100',
          ),
          const SizedBox(height: 12),
          CouponTextField(
            controller: controller.maxDiscountController,
            label: 'Maximum discount (optional)',
            hint: 'Leave empty for no cap',
            prefixText: 'PKR  ',
            numeric: true,
            helper: 'Caps the discount on large orders',
          ),
          _converted(controller.maxDiscountAmount.value),
        ];

      case CouponType.fixedAmountDiscount:
        return [
          CouponTextField(
            controller: controller.discountValueController,
            label: 'Flat discount amount',
            hint: 'e.g. 500',
            prefixText: 'PKR  ',
            numeric: true,
            helper:
                'Stored in PKR and converted to the buyer\'s currency at the '
                'live rate',
          ),
          _converted(controller.discountValue.value),
        ];

      case CouponType.freeDelivery:
        return [
          const CouponHint(
            text:
                'The delivery fee is waived when the coupon applies. Add a '
                'limit below only if you want to cover part of it.',
          ),
          const SizedBox(height: 12),
          CouponTextField(
            controller: controller.freeDeliveryCapController,
            label: 'Free delivery limit (optional)',
            hint: 'Leave empty to cover the full fee',
            prefixText: 'PKR  ',
            numeric: true,
          ),
          _converted(controller.freeDeliveryCap.value),
        ];

      case CouponType.registrationFeeDiscount:
        return [
          Row(
            children: [
              Expanded(
                child: CouponOptionTile(
                  icon: Icons.percent_rounded,
                  title: 'Percentage',
                  selected: controller.registrationDiscountIsPercent.value,
                  onTap: () =>
                      controller.registrationDiscountIsPercent.value = true,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: CouponOptionTile(
                  icon: Icons.payments_outlined,
                  title: 'Fixed (PKR)',
                  selected: !controller.registrationDiscountIsPercent.value,
                  onTap: () =>
                      controller.registrationDiscountIsPercent.value = false,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          CouponTextField(
            controller: controller.discountValueController,
            label: controller.registrationDiscountIsPercent.value
                ? 'Registration discount %'
                : 'Registration discount amount',
            prefixText: controller.registrationDiscountIsPercent.value
                ? null
                : 'PKR  ',
            icon: controller.registrationDiscountIsPercent.value
                ? Icons.percent_rounded
                : null,
            numeric: true,
            helper: 'Applied to the membership fee (100% waives it completely)',
          ),
          if (!controller.registrationDiscountIsPercent.value)
            _converted(controller.discountValue.value),
        ];

      case CouponType.freeProduct:
        return [
          _FreeProductTile(controller: controller),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerLeft,
            child: CouponStepper(
              label: 'Free quantity',
              value: controller.freeProductQty.value,
              min: 1,
              max: 20,
              onChanged: (v) => controller.freeProductQty.value = v,
            ),
          ),
        ];

      case CouponType.buyOneGetOne:
        return [
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              CouponStepper(
                label: 'Buy',
                value: controller.buyQuantity.value,
                min: 1,
                max: 20,
                onChanged: (v) => controller.buyQuantity.value = v,
              ),
              CouponStepper(
                label: 'Get free',
                value: controller.getQuantity.value,
                min: 1,
                max: 20,
                onChanged: (v) => controller.getQuantity.value = v,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Buy ${controller.buyQuantity.value}, get '
            '${controller.getQuantity.value} free — '
            '${controller.buyQuantity.value + controller.getQuantity.value} '
            'items in total, paid for ${controller.buyQuantity.value}.',
            style: const TextStyle(fontSize: 11.5, color: Colors.white54),
          ),
        ];
    }
  }

  /// Live foreign equivalents of a PKR amount.
  Widget _converted(double amount) {
    final values = controller.convertedPreview(amount);
    if (values.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Wrap(
        spacing: 7,
        runSpacing: 7,
        children: [
          const Text('≈', style: TextStyle(color: Colors.white38, fontSize: 12)),
          ...values.map(
            (v) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: kCouponSurfaceAlt,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: kCouponBorder),
              ),
              child: Text(
                v,
                style: const TextStyle(fontSize: 10.5, color: Colors.white54),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FreeProductTile extends StatelessWidget {
  final CouponEditorController controller;
  const _FreeProductTile({required this.controller});

  @override
  Widget build(BuildContext context) {
    // Its own Obx: this tile builds outside the parent Obx's closure, so it
    // has to track the selection itself.
    return Obx(() => _tile(context, controller.freeProduct.value));
  }

  Widget _tile(BuildContext context, CouponProductRef? product) {
    return InkWell(
      onTap: () async {
        final picked = await showCouponSingleProductPicker(
          context,
          controller: controller,
          initial: product,
        );
        if (picked != null) controller.freeProduct.value = picked;
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: kCouponSurfaceAlt,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: product == null ? Colors.orange.shade700 : kCouponAccent,
          ),
        ),
        child: Row(
          children: [
            if (product == null)
              const Icon(
                Icons.card_giftcard_rounded,
                color: Colors.orange,
                size: 22,
              )
            else
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
                            size: 16,
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
                              size: 16,
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
                    product?.name ?? 'Choose the free product',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: product == null ? Colors.orange : Colors.white,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    product == null
                        ? 'Tap to pick the product given for free'
                        : 'PKR ${NumberFormat('#,##0').format(product.price)}'
                              '${product.category.isEmpty ? '' : ' · ${product.category}'}',
                    style: const TextStyle(
                      fontSize: 11.5,
                      color: Colors.white38,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.edit, size: 16, color: Colors.white38),
          ],
        ),
      ),
    );
  }
}

// ─── 4. APPLIES TO (products / categories) ────────────────────────────────

class CouponScopeSection extends StatelessWidget {
  final CouponEditorController controller;
  const CouponScopeSection({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return CouponSection(
      title: 'Applies To',
      icon: Icons.inventory_2_outlined,
      subtitle: 'Which products the coupon works on',
      child: Obx(() {
        final scope = controller.scope.value;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ...CouponScope.values.map(
              (s) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: CouponOptionTile(
                  icon: s.icon,
                  title: s.label,
                  selected: scope == s,
                  onTap: () => controller.scope.value = s,
                ),
              ),
            ),

            if (scope == CouponScope.specificProducts) ...[
              const SizedBox(height: 6),
              _PickerButton(
                icon: Icons.add_shopping_cart,
                label: controller.selectedProducts.isEmpty
                    ? 'Select products'
                    : '${controller.selectedProducts.length} products selected — change',
                onTap: () async {
                  final picked = await showCouponProductPicker(
                    context,
                    controller: controller,
                    initial: controller.selectedProducts,
                  );
                  if (picked != null) {
                    controller.selectedProducts.assignAll(picked);
                  }
                },
              ),
              if (controller.selectedProducts.isNotEmpty) ...[
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: controller.selectedProducts
                      .map(
                        (p) => CouponChip(
                          label: p.name,
                          selected: true,
                          onTap: () {},
                          onDelete: () => controller.selectedProducts.remove(p),
                        ),
                      )
                      .toList(),
                ),
              ],
            ],

            if (scope == CouponScope.specificCategories) ...[
              const SizedBox(height: 6),
              _CategoryPicker(controller: controller),
            ],
          ],
        );
      }),
    );
  }
}

class _CategoryPicker extends StatefulWidget {
  final CouponEditorController controller;
  const _CategoryPicker({required this.controller});

  @override
  State<_CategoryPicker> createState() => _CategoryPickerState();
}

class _CategoryPickerState extends State<_CategoryPicker> {
  @override
  void initState() {
    super.initState();
    widget.controller.ensureCategories();
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (widget.controller.isLoadingCategories.value &&
          widget.controller.allCategories.isEmpty) {
        return const Padding(
          padding: EdgeInsets.symmetric(vertical: 14),
          child: Center(
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: kCouponAccent,
              ),
            ),
          ),
        );
      }
      if (widget.controller.allCategories.isEmpty) {
        return const CouponHint(
          text: 'No categories found — add them under Products › Categories.',
          icon: Icons.warning_amber_rounded,
          color: Colors.orange,
        );
      }
      return Wrap(
        spacing: 8,
        runSpacing: 8,
        children: widget.controller.allCategories.map((c) {
          final selected = widget.controller.selectedCategories.contains(c);
          return CouponChip(
            label: c,
            icon: Icons.category_outlined,
            selected: selected,
            onTap: () => widget.controller.toggleCategory(c),
          );
        }).toList(),
      );
    });
  }
}

// ─── 5. AUDIENCE ──────────────────────────────────────────────────────────

class CouponAudienceSection extends StatelessWidget {
  final CouponEditorController controller;
  const CouponAudienceSection({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return CouponSection(
      title: 'Who Gets It',
      icon: Icons.groups_2_outlined,
      subtitle: 'Which customers can see and use this coupon',
      child: Obx(() {
        final audience = controller.audience.value;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ...CouponAudience.values.map(
              (a) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: CouponOptionTile(
                  icon: a.icon,
                  title: a.label,
                  subtitle: _audienceHint(a),
                  selected: audience == a,
                  onTap: () => controller.audience.value = a,
                ),
              ),
            ),
            if (audience == CouponAudience.specificCustomers) ...[
              const SizedBox(height: 6),
              _PickerButton(
                icon: Icons.person_add_alt,
                label: controller.selectedCustomers.isEmpty
                    ? 'Select customers'
                    : '${controller.selectedCustomers.length} customers selected — change',
                onTap: () async {
                  final picked = await showCouponCustomerPicker(
                    context,
                    controller: controller,
                    initial: controller.selectedCustomers,
                  );
                  if (picked != null) {
                    controller.selectedCustomers.assignAll(picked);
                  }
                },
              ),
              if (controller.selectedCustomers.isNotEmpty) ...[
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: controller.selectedCustomers
                      .map(
                        (c) => CouponChip(
                          label: c.name,
                          icon: Icons.person,
                          selected: true,
                          onTap: () {},
                          onDelete: () =>
                              controller.selectedCustomers.remove(c),
                        ),
                      )
                      .toList(),
                ),
              ],
            ],
          ],
        );
      }),
    );
  }

  String? _audienceHint(CouponAudience audience) {
    switch (audience) {
      case CouponAudience.allCustomers:
        return 'Every registered user, active or not';
      case CouponAudience.activeMembers:
        return 'Paid membership or active MLM status';
      case CouponAudience.inactiveMembers:
        return 'Users who have not activated yet — good for win-backs';
      case CouponAudience.specificCustomers:
        return 'Only the customers you pick';
    }
  }
}

// ─── 6. LOCATIONS ─────────────────────────────────────────────────────────

class CouponLocationSection extends StatelessWidget {
  final CouponEditorController controller;
  const CouponLocationSection({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return CouponSection(
      title: 'Locations',
      icon: Icons.public,
      subtitle: 'Which countries, states or cities this coupon covers',
      child: Obx(() {
        final scope = controller.locationScope.value;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ...CouponLocationScope.values.map(
              (s) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: CouponOptionTile(
                  icon: s == CouponLocationScope.everywhere
                      ? Icons.travel_explore
                      : Icons.edit_location_alt_outlined,
                  title: s.label,
                  selected: scope == s,
                  onTap: () => controller.locationScope.value = s,
                ),
              ),
            ),
            if (scope == CouponLocationScope.specific) ...[
              const SizedBox(height: 6),
              _PickerButton(
                icon: Icons.map_outlined,
                label: controller.selectedLocations.isEmpty
                    ? 'Select locations'
                    : '${controller.selectedLocations.length} zones selected — change',
                onTap: () async {
                  final picked = await showCouponLocationPicker(
                    context,
                    initial: controller.selectedLocations,
                  );
                  if (picked != null) {
                    controller.selectedLocations.assignAll(picked);
                  }
                },
              ),
              if (controller.selectedLocations.isNotEmpty) ...[
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: controller.selectedLocations
                      .map(
                        (l) => CouponChip(
                          label: l.pathLabel,
                          icon: l.level == 'country'
                              ? Icons.flag_outlined
                              : l.level == 'state'
                              ? Icons.map_outlined
                              : Icons.location_city,
                          selected: true,
                          onTap: () {},
                          onDelete: () =>
                              controller.selectedLocations.remove(l),
                        ),
                      )
                      .toList(),
                ),
              ],
            ],
          ],
        );
      }),
    );
  }
}

// ─── 7. ORDER RULES (cart-based coupons only) ─────────────────────────────

class CouponCartRulesSection extends StatelessWidget {
  final CouponEditorController controller;
  const CouponCartRulesSection({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return CouponSection(
      title: 'Order Rules',
      icon: Icons.shopping_cart_outlined,
      subtitle: 'Optional — leave empty and the coupon works on any order',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          CouponTextField(
            controller: controller.minPurchaseController,
            label: 'Minimum shopping (buy limit)',
            hint: 'e.g. 1000 — empty means no minimum',
            prefixText: 'PKR  ',
            numeric: true,
            helper:
                'The buyer can pay in any currency; the total must be worth at '
                'least this much in PKR',
          ),
          Obx(() {
            final values = controller.convertedPreview(
              controller.minPurchaseAmount.value,
            );
            if (values.isEmpty) return const SizedBox.shrink();
            return Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Wrap(
                spacing: 7,
                runSpacing: 7,
                children: [
                  const Text(
                    'Same as:',
                    style: TextStyle(color: Colors.white38, fontSize: 11),
                  ),
                  ...values.map(
                    (v) => Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: kCouponAccent.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: kCouponAccent.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Text(
                        v,
                        style: const TextStyle(
                          fontSize: 10.5,
                          color: Colors.white70,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
          const SizedBox(height: 14),
          Obx(
            () => CouponSwitchTile(
              icon: Icons.bolt_rounded,
              title: 'Auto apply',
              subtitle:
                  'No code needed — applies as soon as the order qualifies',
              value: controller.autoApply.value,
              onChanged: (v) => controller.autoApply.value = v,
            ),
          ),
          const SizedBox(height: 10),
          Obx(
            () => CouponSwitchTile(
              icon: Icons.fiber_new_outlined,
              title: 'First order only',
              subtitle: 'Only for customers who have never ordered before',
              value: controller.firstOrderOnly.value,
              onChanged: (v) => controller.firstOrderOnly.value = v,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── 8. VALIDITY & LIMITS ─────────────────────────────────────────────────

class CouponScheduleSection extends StatelessWidget {
  final CouponEditorController controller;
  const CouponScheduleSection({super.key, required this.controller});

  static const _quick = <String, Duration>{
    '1 Day': Duration(days: 1),
    '3 Days': Duration(days: 3),
    '1 Week': Duration(days: 7),
    '15 Days': Duration(days: 15),
    '1 Month': Duration(days: 30),
    '3 Months': Duration(days: 90),
  };

  @override
  Widget build(BuildContext context) {
    return CouponSection(
      title: 'Validity & Limits',
      icon: Icons.event_available_outlined,
      subtitle: 'When the coupon runs and how often it can be used',
      child: Obx(() {
        final start = controller.startAt.value;
        final end = controller.endAt.value;
        final duration = controller.validityDuration;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: _DateTimeTile(
                    label: 'Starts',
                    icon: Icons.play_circle_outline,
                    value: start,
                    onPick: controller.setStart,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _DateTimeTile(
                    label: 'Expires',
                    icon: Icons.stop_circle_outlined,
                    value: end,
                    onPick: controller.setEnd,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final entry in _quick.entries)
                  CouponChip(
                    label: entry.key,
                    icon: Icons.timer_outlined,
                    selected: duration.inMinutes == entry.value.inMinutes,
                    onTap: () => controller.applyQuickDuration(entry.value),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            CouponHint(
              text: duration.isNegative
                  ? 'The end date is before the start date.'
                  : 'Runs for ${_durationLabel(duration)}',
              icon: duration.isNegative
                  ? Icons.error_outline
                  : Icons.check_circle_outline,
              color: duration.isNegative ? Colors.redAccent : kCouponAccent,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: CouponTextField(
                    controller: controller.totalLimitController,
                    label: 'Total usage limit',
                    hint: 'Empty = unlimited',
                    icon: Icons.confirmation_number_outlined,
                    numeric: true,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: CouponTextField(
                    controller: controller.perCustomerLimitController,
                    label: 'Per customer limit',
                    hint: 'Empty = unlimited',
                    icon: Icons.person_outline,
                    numeric: true,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            CouponSwitchTile(
              icon: Icons.power_settings_new,
              title: 'Active',
              subtitle: 'Turn off to keep the coupon saved but unavailable',
              value: controller.isActive.value,
              onChanged: (v) => controller.isActive.value = v,
            ),
          ],
        );
      }),
    );
  }

  static String _durationLabel(Duration d) {
    if (d.inDays >= 1) {
      final hours = d.inHours % 24;
      return '${d.inDays} day${d.inDays == 1 ? '' : 's'}'
          '${hours > 0 ? ' $hours hr' : ''}';
    }
    if (d.inHours >= 1) return '${d.inHours} hours';
    return '${d.inMinutes} minutes';
  }
}

class _DateTimeTile extends StatelessWidget {
  final String label;
  final IconData icon;
  final DateTime value;
  final ValueChanged<DateTime> onPick;

  const _DateTimeTile({
    required this.label,
    required this.icon,
    required this.value,
    required this.onPick,
  });

  Future<void> _pick(BuildContext context) async {
    final date = await showDatePicker(
      context: context,
      initialDate: value,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
    );
    if (date == null || !context.mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(value),
    );
    onPick(
      DateTime(
        date.year,
        date.month,
        date.day,
        time?.hour ?? value.hour,
        time?.minute ?? value.minute,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => _pick(context),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        decoration: BoxDecoration(
          color: kCouponSurfaceAlt,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: kCouponBorder),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: kCouponAccent),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(fontSize: 11, color: Colors.white38),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    DateFormat('dd MMM yyyy').format(value),
                    style: const TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    DateFormat('h:mm a').format(value),
                    style: const TextStyle(
                      fontSize: 11.5,
                      color: Colors.white54,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.edit_calendar_outlined,
              size: 15,
              color: Colors.white38,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── SHARED ───────────────────────────────────────────────────────────────

class _PickerButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _PickerButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: OutlinedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 17),
        label: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: kCouponAccent,
          side: const BorderSide(color: kCouponAccent),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}
