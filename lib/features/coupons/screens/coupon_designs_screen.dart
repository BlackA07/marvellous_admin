// lib/features/coupons/screens/coupon_designs_screen.dart
//
// The design library. Everything here is about looks only; the Create Coupon
// screen picks one of these and then handles the rules.

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/pallete.dart';
import '../controllers/coupon_design_controller.dart';
import '../models/coupon_design_model.dart';
import 'add_coupon_design_screen.dart';
import 'widgets/coupon_preview_card.dart';
import 'widgets/coupon_ui.dart';

class CouponDesignsScreen extends StatelessWidget {
  const CouponDesignsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(CouponDesignListController());

    return Scaffold(
      backgroundColor: Pallete.metalDark,
      appBar: AppBar(
        backgroundColor: Pallete.metalDark,
        elevation: 0,
        title: Text(
          'Coupon Designs',
          style: GoogleFonts.orbitron(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: kCouponAccent,
        foregroundColor: Colors.black,
        onPressed: () => Get.to(() => const AddCouponDesignScreen()),
        icon: const Icon(Icons.add),
        label: const Text(
          'New Design',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(
            child: CircularProgressIndicator(color: kCouponAccent),
          );
        }
        if (controller.designs.isEmpty) {
          return const _EmptyDesigns();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 14, 16, 0),
              child: CouponHint(
                text:
                    'A design only controls how the card looks. Create the '
                    'offer itself under Coupons › Create Coupon and pick one '
                    'of these designs there.',
              ),
            ),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final width = constraints.maxWidth;
                  int columns = 1;
                  if (width > 1400) {
                    columns = 3;
                  } else if (width > 900) {
                    columns = 2;
                  }
                  return GridView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 90),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: columns,
                      mainAxisExtent: 232,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                    ),
                    itemCount: controller.designs.length,
                    itemBuilder: (context, i) => _DesignCard(
                      design: controller.designs[i],
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

class _DesignCard extends StatelessWidget {
  final CouponDesignModel design;
  final CouponDesignListController controller;

  const _DesignCard({required this.design, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: kCouponSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kCouponBorder),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    design.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ),
                Text(
                  DateFormat(
                    'dd MMM yy',
                  ).format(design.updatedAt ?? design.createdAt),
                  style: const TextStyle(fontSize: 10.5, color: Colors.white38),
                ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
              child: CouponPreviewCard(
                coupon: design.sampleCoupon(),
                compact: true,
              ),
            ),
          ),
          const Divider(height: 1, color: kCouponBorder),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton.icon(
                onPressed: () =>
                    Get.to(() => AddCouponDesignScreen(editDesign: design)),
                icon: const Icon(Icons.edit_outlined, size: 16),
                label: const Text('Edit', style: TextStyle(fontSize: 12)),
                style: TextButton.styleFrom(foregroundColor: Colors.white70),
              ),
              TextButton.icon(
                onPressed: () => controller.duplicateDesign(design),
                icon: const Icon(Icons.content_copy, size: 15),
                label: const Text('Duplicate', style: TextStyle(fontSize: 12)),
                style: TextButton.styleFrom(foregroundColor: Colors.white70),
              ),
              IconButton(
                tooltip: 'Delete',
                onPressed: () => _confirmDelete(context),
                icon: const Icon(
                  Icons.delete_outline,
                  size: 18,
                  color: Colors.redAccent,
                ),
              ),
              const SizedBox(width: 4),
            ],
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    Get.dialog(
      AlertDialog(
        backgroundColor: kCouponSurface,
        title: const Text('Delete Design', style: TextStyle(fontSize: 17)),
        content: Text(
          'Delete "${design.name}"? Coupons already using it keep their look.',
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              controller.deleteDesign(design.id);
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
}

class _EmptyDesigns extends StatelessWidget {
  const _EmptyDesigns();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.brush_outlined, size: 46, color: Colors.white24),
          const SizedBox(height: 14),
          const Text(
            'No designs yet',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 6),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              'Create a design first, then use it on any number of coupons.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12.5, color: Colors.white38),
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: () => Get.to(() => const AddCouponDesignScreen()),
            style: FilledButton.styleFrom(
              backgroundColor: kCouponAccent,
              foregroundColor: Colors.black,
            ),
            icon: const Icon(Icons.add, size: 18),
            label: const Text('New Design'),
          ),
        ],
      ),
    );
  }
}
