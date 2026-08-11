import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/banner_editor_controller.dart';
import '../models/banner_model.dart';
import 'widgets/static_banner_tab.dart';
import 'widgets/custom_banner_tab.dart';
import 'widgets/banner_action_picker.dart';

class BannerAddScreen extends StatelessWidget {
  final BannerModel? editBanner;
  const BannerAddScreen({super.key, this.editBanner});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(BannerEditorController());
    if (editBanner != null) {
      controller.setEditingBanner(editBanner!);
    }

    final initialTab = editBanner?.type == BannerType.custom ? 1 : 0;

    return DefaultTabController(
      length: 2,
      initialIndex: initialTab,
      child: Scaffold(
        appBar: AppBar(
          title: Text(editBanner == null ? 'Add Banner' : 'Edit Banner'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Ready Image', icon: Icon(Icons.image)),
              Tab(text: 'Custom Design', icon: Icon(Icons.brush)),
            ],
          ),
        ),
        body: Column(
          children: [
            _ActionTargetBar(controller: controller),
            const Expanded(
              child: TabBarView(
                children: [StaticBannerTab(), CustomBannerTab()],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Shown above both tabs — lets admin pick whether this banner opens a
/// specific product or a category/subcategory listing when tapped.
class _ActionTargetBar extends StatelessWidget {
  final BannerEditorController controller;
  const _ActionTargetBar({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final type = controller.actionType.value;
      String label;
      IconData icon;
      switch (type) {
        case BannerActionType.product:
          label = 'Opens product: ${controller.actionProductName.value}';
          icon = Icons.inventory_2_outlined;
          break;
        case BannerActionType.category:
          final sub = controller.actionSubCategoryName.value;
          label = sub.isEmpty
              ? 'Opens category: ${controller.actionCategoryName.value}'
              : 'Opens: ${controller.actionCategoryName.value} > $sub';
          icon = Icons.category_outlined;
          break;
        case BannerActionType.none:
          label = 'No target selected — tap to choose';
          icon = Icons.touch_app_outlined;
          break;
      }

      return Container(
        margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: type == BannerActionType.none
              ? Colors.grey.shade100
              : Colors.deepPurple.shade50,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: type == BannerActionType.none
                ? Colors.grey.shade300
                : Colors.deepPurple.shade200,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 18,
              color: type == BannerActionType.none
                  ? Colors.grey.shade600
                  : Colors.deepPurple,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: type == BannerActionType.none
                      ? Colors.grey.shade700
                      : Colors.deepPurple.shade700,
                ),
              ),
            ),
            if (type != BannerActionType.none)
              IconButton(
                icon: const Icon(Icons.close, size: 18),
                onPressed: controller.clearAction,
                tooltip: 'Clear target',
              ),
            TextButton(
              onPressed: () async {
                final result = await showBannerActionPicker(context);
                if (result == null) return;
                if (result.type == 'product') {
                  controller.setProductAction(
                    result.productId!,
                    result.productName!,
                  );
                } else {
                  controller.setCategoryAction(
                    result.categoryName!,
                    result.subCategoryName,
                  );
                }
              },
              child: Text(
                type == BannerActionType.none ? 'Select' : 'Change',
                style: const TextStyle(
                  color: Colors.black,
                ), // <--- Yahan color add karna hai
              ),
            ),
          ],
        ),
      );
    });
  }
}
