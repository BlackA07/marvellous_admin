import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import '../../controllers/banner_editor_controller.dart';
import '../../models/banner_element_model.dart';
import 'background_picker_grid.dart';
import 'draggable_element_widget.dart';
import 'element_toolbar.dart';
import 'add_element_sheet.dart';

class CustomBannerTab extends StatelessWidget {
  const CustomBannerTab({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<BannerEditorController>();

    return Obx(() {
      if (controller.selectedBackground.value.isEmpty) {
        return BackgroundPickerGrid(
          images: controller.backgroundImages,
          onSelect: controller.selectBackground,
          onUploadNew: () async {
            final picker = ImagePicker();
            final picked = await picker.pickImage(source: ImageSource.gallery);
            if (picked != null) {
              final bytes = await picked.readAsBytes();
              await controller.uploadNewBackground(bytes, picked.name);
            }
          },
        );
      }

      return LayoutBuilder(
        builder: (context, constraints) {
          final maxCanvasWidth = constraints.maxWidth > 900
              ? 800.0
              : constraints.maxWidth - 32;

          return Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Center(
                    child: Column(
                      children: [
                        // undo / redo
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Obx(
                              () => IconButton(
                                icon: const Icon(Icons.undo),
                                tooltip: 'Undo',
                                onPressed: controller.canUndo.value
                                    ? controller.undo
                                    : null,
                              ),
                            ),
                            Obx(
                              () => IconButton(
                                icon: const Icon(Icons.redo),
                                tooltip: 'Redo',
                                onPressed: controller.canRedo.value
                                    ? controller.redo
                                    : null,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(
                          width: maxCanvasWidth,
                          child: AspectRatio(
                            aspectRatio: 2 / 1,
                            child: GestureDetector(
                              onTap: controller.deselect,
                              child: RepaintBoundary(
                                key: controller.repaintKey,
                                child: Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(4),
                                    image: DecorationImage(
                                      image: NetworkImage(
                                        controller.selectedBackground.value,
                                      ),
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                  child: LayoutBuilder(
                                    builder: (context, canvasConstraints) {
                                      final canvasSize = Size(
                                        canvasConstraints.maxWidth,
                                        canvasConstraints.maxHeight,
                                      );
                                      return Obx(
                                        () => Stack(
                                          children: controller.elements
                                              .map(
                                                (el) => DraggableElementWidget(
                                                  key: ValueKey(el.id),
                                                  element: el,
                                                  canvasSize: canvasSize,
                                                  isSelected:
                                                      controller
                                                          .selectedElementId
                                                          .value ==
                                                      el.id,
                                                  onTap: () => controller
                                                      .selectElement(el.id),
                                                  onDoubleTap: () =>
                                                      _handleDoubleTap(
                                                        context,
                                                        controller,
                                                        el,
                                                      ),
                                                  onDragStart: () =>
                                                      controller.pushHistory(),
                                                  onDragEnd: (dx, dy) =>
                                                      controller.updatePosition(
                                                        el.id,
                                                        dx,
                                                        dy,
                                                      ),
                                                ),
                                              )
                                              .toList(),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          alignment: WrapAlignment.center,
                          children: [
                            _addBtn(
                              context,
                              controller,
                              'Title',
                              Icons.title,
                              BannerElementType.title,
                            ),
                            _addBtn(
                              context,
                              controller,
                              'Subtitle',
                              Icons.short_text,
                              BannerElementType.subtitle,
                            ),
                            _addBtn(
                              context,
                              controller,
                              'Message',
                              Icons.notes,
                              BannerElementType.message,
                            ),
                            _addBtn(
                              context,
                              controller,
                              'Button',
                              Icons.smart_button,
                              BannerElementType.button,
                            ),
                            _addBtn(
                              context,
                              controller,
                              'Image',
                              Icons.image,
                              BannerElementType.image,
                            ),
                            ActionChip(
                              avatar: const Icon(Icons.wallpaper, size: 18),
                              label: const Text('Change Background'),
                              onPressed: () =>
                                  controller.selectedBackground.value = '',
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Obx(() {
                final selected = controller.selectedElement;
                if (selected == null) return const SizedBox.shrink();
                return ElementToolbar(
                  element: selected,
                  controller: controller,
                );
              }),
              SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                  child: Obx(
                    () => SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: controller.isSaving.value
                            ? null
                            : () async {
                                final ok = await controller.saveCustomBanner();
                                if (ok) Get.back();
                              },
                        child: controller.isSaving.value
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text('Post Banner'),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      );
    });
  }

  Future<void> _handleDoubleTap(
    BuildContext context,
    BannerEditorController controller,
    dynamic el,
  ) async {
    if (el.type == BannerElementType.image) {
      controller.replaceElementImage(el.id);
    } else {
      final edited = await showAddElementSheet(
        context,
        el.type,
        initialValue: el.content,
      );
      if (edited != null && edited.isNotEmpty) {
        controller.updateContent(el.id, edited);
      }
    }
  }

  Widget _addBtn(
    BuildContext context,
    BannerEditorController controller,
    String label,
    IconData icon,
    BannerElementType type,
  ) {
    return ActionChip(
      avatar: Icon(icon, size: 18),
      label: Text(label),
      onPressed: () async {
        if (type == BannerElementType.image) {
          final picker = ImagePicker();
          final picked = await picker.pickImage(source: ImageSource.gallery);
          if (picked == null) return;
          Get.dialog(
            const Center(child: CircularProgressIndicator()),
            barrierDismissible: false,
          );
          final bytes = await picked.readAsBytes();
          final url = await controller.uploadElementImageAndGetUrl(
            bytes,
            picked.name,
          );
          Get.back();
          controller.addElement(type, imageUrl: url);
        } else {
          final text = await showAddElementSheet(context, type);
          if (text != null && text.isNotEmpty)
            controller.addElement(type, content: text);
        }
      },
    );
  }
}
