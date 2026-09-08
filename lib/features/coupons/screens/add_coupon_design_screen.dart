// lib/features/coupons/screens/add_coupon_design_screen.dart
//
// Part one of the split: this screen is only about how a coupon card LOOKS.
// No rules, no dates, no targeting — those live on the Create Coupon screen,
// which simply picks one of the designs saved here.

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/pallete.dart';
import '../controllers/coupon_design_controller.dart';
import '../models/coupon_design_model.dart';
import '../models/coupon_model.dart';
import 'widgets/coupon_preview_card.dart';
import 'widgets/coupon_ui.dart';

class AddCouponDesignScreen extends StatefulWidget {
  final CouponDesignModel? editDesign;
  const AddCouponDesignScreen({super.key, this.editDesign});

  @override
  State<AddCouponDesignScreen> createState() => _AddCouponDesignScreenState();
}

class _AddCouponDesignScreenState extends State<AddCouponDesignScreen> {
  late final String _tag;
  late final CouponDesignEditorController controller;
  final ScrollController _scrollController = ScrollController();

  /// The preview shows a sample of whichever type you are curious about.
  final Rx<CouponType> _previewType = CouponType.percentageDiscount.obs;

  @override
  void initState() {
    super.initState();
    _tag =
        'coupon_design_'
        '${widget.editDesign?.id ?? DateTime.now().microsecondsSinceEpoch}';
    controller = Get.put(CouponDesignEditorController(), tag: _tag);
    if (widget.editDesign != null) controller.setEditing(widget.editDesign!);
  }

  @override
  void dispose() {
    Get.delete<CouponDesignEditorController>(tag: _tag, force: true);
    _scrollController.dispose();
    super.dispose();
  }

  bool get _isEdit => widget.editDesign != null;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Pallete.metalDark,
      appBar: AppBar(
        backgroundColor: Pallete.metalDark,
        elevation: 0,
        title: Text(
          _isEdit ? 'Edit Design' : 'New Design',
          style: GoogleFonts.orbitron(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
      body: Column(
        children: [
          // The preview stays pinned so every change is visible immediately.
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 700),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Obx(
                      () => CouponPreviewCard(
                        coupon: controller.preview.sampleCoupon(
                          type: _previewType.value,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      height: 34,
                      child: Obx(() {
                        // Read the Rx here, not inside itemBuilder: that
                        // callback runs during layout, after Obx has finished
                        // collecting its dependencies.
                        final active = _previewType.value;
                        return ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: CouponType.values.length,
                          separatorBuilder: (_, __) => const SizedBox(width: 8),
                          itemBuilder: (_, i) {
                            final type = CouponType.values[i];
                            return CouponChip(
                              label: type.label,
                              icon: type.icon,
                              selected: active == type,
                              onTap: () => _previewType.value = type,
                            );
                          },
                        );
                      }),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const Divider(height: 1, color: kCouponBorder),

          Expanded(
            child: SingleChildScrollView(
              controller: _scrollController,
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 700),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      CouponSection(
                        title: 'Design Name',
                        icon: Icons.badge_outlined,
                        subtitle: 'How you will recognise it when creating a coupon',
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            CouponTextField(
                              controller: controller.nameController,
                              label: 'Name',
                              hint: 'e.g. Eid Gold, Winter Sale',
                              icon: Icons.style_outlined,
                              maxLength: 40,
                            ),
                            const SizedBox(height: 12),
                            CouponTextField(
                              controller: controller.badgeController,
                              label: 'Badge text (optional)',
                              hint: 'e.g. LIMITED, EID SPECIAL',
                              icon: Icons.local_offer_outlined,
                              uppercase: true,
                              maxLength: 16,
                            ),
                          ],
                        ),
                      ),

                      CouponSection(
                        title: 'Quick Presets',
                        icon: Icons.auto_awesome,
                        subtitle: 'Start from a ready-made colour set',
                        child: Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: CouponDesignEditorController.presets
                              .map(
                                (preset) => _PresetSwatch(
                                  preset: preset,
                                  onTap: () => controller.applyPreset(preset),
                                ),
                              )
                              .toList(),
                        ),
                      ),

                      CouponSection(
                        title: 'Colours',
                        icon: Icons.palette_outlined,
                        subtitle: 'Background, text and accent',
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _label('Background'),
                            Obx(
                              () => CouponColorRow(
                                selectedHex:
                                    controller.backgroundColorHex.value,
                                onPick: (hex) =>
                                    controller.backgroundColorHex.value = hex,
                              ),
                            ),
                            const SizedBox(height: 18),
                            _label('Text'),
                            Obx(
                              () => CouponColorRow(
                                selectedHex: controller.textColorHex.value,
                                onPick: (hex) =>
                                    controller.textColorHex.value = hex,
                              ),
                            ),
                            const SizedBox(height: 18),
                            _label('Accent (code, border, icon)'),
                            Obx(
                              () => CouponColorRow(
                                selectedHex: controller.accentColorHex.value,
                                onPick: (hex) =>
                                    controller.accentColorHex.value = hex,
                              ),
                            ),
                          ],
                        ),
                      ),

                      CouponSection(
                        title: 'Typography',
                        icon: Icons.text_fields,
                        subtitle: 'Font used on the coupon card',
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _FontPicker(controller: controller),
                            const SizedBox(height: 14),
                            Obx(
                              () => CouponSwitchTile(
                                icon: Icons.format_bold,
                                title: 'Bold text',
                                subtitle: 'Heavier weight on the card',
                                value: controller.isBold.value,
                                onChanged: (v) => controller.isBold.value = v,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 6),
                      Obx(
                        () => SizedBox(
                          height: 50,
                          child: FilledButton.icon(
                            onPressed: controller.isSaving.value
                                ? null
                                : _onSave,
                            style: FilledButton.styleFrom(
                              backgroundColor: kCouponAccent,
                              foregroundColor: Colors.black,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            icon: controller.isSaving.value
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.black,
                                    ),
                                  )
                                : const Icon(
                                    Icons.check_circle_outline,
                                    size: 19,
                                  ),
                            label: Text(
                              controller.isSaving.value
                                  ? 'Saving...'
                                  : (_isEdit
                                        ? 'Save Changes'
                                        : 'Save Design'),
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _label(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 9),
    child: Text(
      text,
      style: const TextStyle(
        fontSize: 12.5,
        fontWeight: FontWeight.w700,
        color: Colors.white70,
      ),
    ),
  );

  Future<void> _onSave() async {
    final ok = await controller.save();
    if (!ok || !mounted) return;

    await Get.dialog(
      AlertDialog(
        backgroundColor: kCouponSurface,
        icon: const Icon(Icons.check_circle, color: Colors.green, size: 42),
        title: const Text('Saved', style: TextStyle(fontSize: 18)),
        content: Text(
          _isEdit
              ? 'Design updated.'
              : 'Design saved — you can pick it when creating a coupon.',
          textAlign: TextAlign.center,
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          FilledButton(
            onPressed: () => Get.back(),
            style: FilledButton.styleFrom(
              backgroundColor: kCouponAccent,
              foregroundColor: Colors.black,
            ),
            child: const Text('OK'),
          ),
        ],
      ),
      barrierDismissible: false,
    );

    if (!mounted) return;
    Get.back();
  }
}

class _PresetSwatch extends StatelessWidget {
  final Map<String, String> preset;
  final VoidCallback onTap;
  const _PresetSwatch({required this.preset, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final bg = CouponModel.colorFromHex(preset['bg']!);
    final accent = CouponModel.colorFromHex(preset['accent']!);
    final text = CouponModel.colorFromHex(preset['text']!);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 132,
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: kCouponSurfaceAlt,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: kCouponBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              height: 34,
              decoration: BoxDecoration(
                color: bg,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: accent.withValues(alpha: 0.6)),
              ),
              alignment: Alignment.center,
              child: Text(
                'Aa 20% OFF',
                style: TextStyle(
                  color: text,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              preset['name']!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 11, color: Colors.white60),
            ),
          ],
        ),
      ),
    );
  }
}

class _FontPicker extends StatelessWidget {
  final CouponDesignEditorController controller;
  const _FontPicker({required this.controller});

  static final Map<String, TextStyle> _cache = {};

  static TextStyle _styleFor(String family) {
    return _cache.putIfAbsent(family, () {
      const fallback = TextStyle(fontSize: 13);
      if (family == 'Default') return fallback;
      try {
        return GoogleFonts.getFont(family, fontSize: 13);
      } catch (_) {
        return fallback;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => Wrap(
        spacing: 8,
        runSpacing: 8,
        children: kCouponFonts.map((font) {
          final selected = controller.fontFamily.value == font;
          return InkWell(
            onTap: () => controller.fontFamily.value = font,
            borderRadius: BorderRadius.circular(10),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: selected
                    ? kCouponAccent.withValues(alpha: 0.14)
                    : kCouponSurfaceAlt,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: selected ? kCouponAccent : kCouponBorder,
                ),
              ),
              child: Text(
                font,
                style: _styleFor(font).copyWith(
                  color: selected ? Colors.white : Colors.white60,
                  fontWeight: selected ? FontWeight.w700 : null,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
