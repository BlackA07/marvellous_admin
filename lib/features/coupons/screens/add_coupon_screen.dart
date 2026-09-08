// lib/features/coupons/screens/add_coupon_screen.dart
//
// Part two of the split: the offer itself. Pick a saved design at the top,
// then set up the rules below. Only the sections that matter for the chosen
// coupon type are shown — a registration-fee coupon has no products, no buy
// limit and no cart rules, so those sections are simply not rendered.

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/pallete.dart';
import '../controllers/coupon_editor_controller.dart';
import '../models/coupon_model.dart';
import 'widgets/coupon_form_parts.dart';
import 'widgets/coupon_preview_card.dart';
import 'widgets/coupon_ui.dart';

class AddCouponScreen extends StatefulWidget {
  final CouponModel? editCoupon;
  const AddCouponScreen({super.key, this.editCoupon});

  @override
  State<AddCouponScreen> createState() => _AddCouponScreenState();
}

class _AddCouponScreenState extends State<AddCouponScreen> {
  late final String _tag;
  late final CouponEditorController controller;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    // A unique tag per screen instance, so old state never carries over.
    _tag =
        'coupon_'
        '${widget.editCoupon?.id ?? DateTime.now().microsecondsSinceEpoch}';
    controller = Get.put(CouponEditorController(), tag: _tag);
    if (widget.editCoupon != null) {
      controller.setEditing(widget.editCoupon!);
    } else {
      controller.perCustomerLimitController.text = '1';
    }
  }

  @override
  void dispose() {
    Get.delete<CouponEditorController>(tag: _tag, force: true);
    _scrollController.dispose();
    super.dispose();
  }

  bool get _isEdit => widget.editCoupon != null;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Pallete.metalDark,
      appBar: AppBar(
        backgroundColor: Pallete.metalDark,
        elevation: 0,
        title: Text(
          _isEdit ? 'Edit Coupon' : 'Create Coupon',
          style: GoogleFonts.orbitron(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          Obx(
            () => Padding(
              padding: const EdgeInsets.only(right: 12),
              child: TextButton.icon(
                onPressed: controller.isSaving.value ? null : _onSave,
                icon: const Icon(Icons.save_outlined, size: 17),
                label: Text(_isEdit ? 'Save' : 'Publish'),
                style: TextButton.styleFrom(foregroundColor: kCouponAccent),
              ),
            ),
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth > 1080;
          if (wide) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _form(maxWidth: 720)),
                Container(
                  width: 1,
                  height: double.infinity,
                  color: kCouponBorder,
                ),
                SizedBox(
                  width: 400,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: _previewPanel(),
                  ),
                ),
              ],
            );
          }
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 720),
                    child: _previewPanel(compact: true),
                  ),
                ),
              ),
              const Divider(height: 1, color: kCouponBorder),
              Expanded(child: _form(maxWidth: 720)),
            ],
          );
        },
      ),
    );
  }

  // ─── PREVIEW ────────────────────────────────────────────────────────────

  Widget _previewPanel({bool compact = false}) {
    return Obx(() {
      final coupon = controller.preview;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(
                Icons.visibility_outlined,
                size: 15,
                color: kCouponAccent,
              ),
              const SizedBox(width: 7),
              Text(
                'Live Preview',
                style: GoogleFonts.comicNeue(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: Colors.white70,
                ),
              ),
              const Spacer(),
              _StatusPill(status: coupon.status),
            ],
          ),
          const SizedBox(height: 10),
          CouponPreviewCard(coupon: coupon, compact: compact),
          if (!compact) ...[
            const SizedBox(height: 16),
            _SummaryPanel(controller: controller),
          ],
        ],
      );
    });
  }

  // ─── FORM ───────────────────────────────────────────────────────────────

  Widget _form({required double maxWidth}) {
    return SingleChildScrollView(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              CouponDesignSection(controller: controller),
              CouponTypeSection(controller: controller),
              _detailsSection(),
              CouponBenefitSection(controller: controller),

              // Sections below depend on the type: fee coupons are charged on
              // the membership fee, not on a cart, so they skip these.
              Obx(() {
                final type = controller.type.value;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (type.usesProductScope)
                      CouponScopeSection(controller: controller),
                    CouponAudienceSection(controller: controller),
                    CouponLocationSection(controller: controller),
                    if (type.usesCartRules)
                      CouponCartRulesSection(controller: controller),
                  ],
                );
              }),

              CouponScheduleSection(controller: controller),
              const SizedBox(height: 6),
              Obx(
                () => SizedBox(
                  height: 50,
                  child: FilledButton.icon(
                    onPressed: controller.isSaving.value ? null : _onSave,
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
                        : const Icon(Icons.check_circle_outline, size: 19),
                    label: Text(
                      controller.isSaving.value
                          ? 'Saving...'
                          : (_isEdit ? 'Save Changes' : 'Publish Coupon'),
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
    );
  }

  Widget _detailsSection() {
    return CouponSection(
      title: 'Coupon Details',
      icon: Icons.confirmation_number_outlined,
      subtitle: 'The code and name your customers will see',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          CouponTextField(
            controller: controller.codeController,
            label: 'Coupon code',
            hint: 'e.g. SAVE20',
            icon: Icons.qr_code_2,
            uppercase: true,
            maxLength: 24,
            helper: 'A-Z, 0-9, - and _ only',
            suffix: IconButton(
              tooltip: 'Auto generate',
              onPressed: controller.generateCode,
              icon: const Icon(
                Icons.auto_awesome,
                size: 17,
                color: kCouponAccent,
              ),
            ),
          ),
          const SizedBox(height: 12),
          CouponTextField(
            controller: controller.titleController,
            label: 'Title',
            hint: 'e.g. Eid Special Discount',
            icon: Icons.title,
            maxLength: 60,
          ),
          const SizedBox(height: 12),
          CouponTextField(
            controller: controller.descriptionController,
            label: 'Description (optional)',
            hint: 'A short line shown on the coupon card',
            maxLines: 2,
            maxLength: 160,
          ),
          const SizedBox(height: 12),
          CouponTextField(
            controller: controller.termsController,
            label: 'Terms & conditions (optional)',
            hint: 'One point per line',
            maxLines: 3,
          ),
        ],
      ),
    );
  }

  // ─── SAVE ───────────────────────────────────────────────────────────────

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
              ? 'Coupon updated.'
              : 'Coupon published — customers can use it now.',
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
    if (_isEdit) {
      Get.back();
      return;
    }

    controller.reset();
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }
}

// ─── SIDE PANEL SUMMARY ───────────────────────────────────────────────────

class _SummaryPanel extends StatelessWidget {
  final CouponEditorController controller;
  const _SummaryPanel({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final coupon = controller.preview;
      final error = controller.validate();

      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: kCouponSurface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: kCouponBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Summary',
              style: GoogleFonts.comicNeue(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 12),
            _row('Type', coupon.type.label),
            _row('Benefit', coupon.headline),
            if (coupon.type.usesProductScope)
              _row('Applies to', coupon.scopeSummary),
            _row('Audience', coupon.audienceSummary),
            _row('Locations', coupon.locationSummary),
            if (coupon.type.usesMinPurchase)
              _row(
                'Buy limit',
                coupon.minPurchaseAmount > 0
                    ? 'PKR ${coupon.minPurchaseAmount.toStringAsFixed(0)}+'
                    : 'No minimum',
              ),
            _row(
              'Total uses',
              coupon.usageLimitTotal > 0
                  ? '${coupon.usageLimitTotal}'
                  : 'Unlimited',
            ),
            _row(
              'Per customer',
              coupon.usageLimitPerCustomer > 0
                  ? '${coupon.usageLimitPerCustomer}'
                  : 'Unlimited',
            ),
            if (coupon.autoApply) _row('Auto apply', 'Yes'),
            if (coupon.firstOrderOnly) _row('First order only', 'Yes'),
            _row(
              'Design',
              coupon.designName.isEmpty ? 'Default' : coupon.designName,
            ),
            const SizedBox(height: 12),
            CouponHint(
              text: error ?? 'Everything checks out — ready to publish.',
              icon: error == null
                  ? Icons.check_circle_outline
                  : Icons.error_outline,
              color: error == null ? Colors.greenAccent : Colors.orangeAccent,
            ),
          ],
        ),
      );
    });
  }

  Widget _row(String label, String value) => Padding(
    padding: const EdgeInsets.only(bottom: 7),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 110,
          child: Text(
            label,
            style: const TextStyle(fontSize: 11.5, color: Colors.white38),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 11.5,
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    ),
  );
}

class _StatusPill extends StatelessWidget {
  final CouponStatus status;
  const _StatusPill({required this.status});

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
          fontSize: 10,
          fontWeight: FontWeight.w800,
          color: status.color,
        ),
      ),
    );
  }
}
