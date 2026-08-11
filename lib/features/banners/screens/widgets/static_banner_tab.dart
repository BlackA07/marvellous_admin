import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import '../../controllers/banner_editor_controller.dart';

class StaticBannerTab extends StatelessWidget {
  const StaticBannerTab({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<BannerEditorController>();

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth > 700
            ? 700.0
            : constraints.maxWidth;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Center(
            child: SizedBox(
              width: maxWidth,
              child: Column(
                children: [
                  Text(
                    'Upload a ready-made banner image. Recommended size: 1200 x 600px (2:1 ratio). '
                    'If your image is a different ratio you\'ll be asked to crop it.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                  ),
                  const SizedBox(height: 20),
                  Obx(() {
                    final bytes = controller.staticImageBytes.value;
                    final url = controller.staticImageUrl.value;
                    return AspectRatio(
                      aspectRatio: 2 / 1,
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: Colors.grey.shade300),
                          color: Colors.grey.shade100,
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: bytes != null
                            ? Image.memory(bytes, fit: BoxFit.cover)
                            : (url.isNotEmpty
                                  ? Image.network(url, fit: BoxFit.cover)
                                  : const Center(
                                      child: Icon(
                                        Icons.add_photo_alternate,
                                        size: 48,
                                        color: Colors.grey,
                                      ),
                                    )),
                      ),
                    );
                  }),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: () async {
                      final picked = await controller.pickStaticImageFile();
                      if (picked == null) return;

                      final rawBytes = await picked.readAsBytes();
                      final decoded = await decodeImageFromList(rawBytes);
                      final ratio = decoded.width / decoded.height;
                      const targetRatio = 2 / 1;

                      if ((ratio - targetRatio).abs() > 0.03) {
                        final croppedBytes = await _cropTo2x1(picked);
                        if (croppedBytes != null) {
                          controller.setStaticImageBytes(
                            croppedBytes,
                            picked.name,
                          );
                          return;
                        }
                      }
                      controller.setStaticImageBytes(rawBytes, picked.name);
                    },
                    icon: const Icon(Icons.upload),
                    label: const Text('Select Image'),
                  ),
                  const SizedBox(height: 30),
                  Obx(
                    () => SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: controller.isSaving.value
                            ? null
                            : () async {
                                final ok = await controller.saveStaticBanner();
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
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<Uint8List?> _cropTo2x1(XFile picked) async {
    final cropped = await ImageCropper().cropImage(
      sourcePath: picked.path,
      aspectRatio: const CropAspectRatio(ratioX: 2, ratioY: 1),
      uiSettings: [
        AndroidUiSettings(toolbarTitle: 'Crop to 2:1', lockAspectRatio: true),
        IOSUiSettings(title: 'Crop to 2:1', aspectRatioLockEnabled: true),
        // page mode instead of a fixed-height dialog — fixes the
        // "BOTTOM OVERFLOWED" error on web when the browser window is short
        WebUiSettings(
          context: Get.context!,
          presentStyle: WebPresentStyle.page,
        ),
      ],
    );
    if (cropped == null) return null;
    return cropped.readAsBytes();
  }
}
