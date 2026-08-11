import 'package:flutter/material.dart';
import 'package:get/get.dart';

class BackgroundPickerGrid extends StatelessWidget {
  final RxList<String> images;
  final void Function(String) onSelect;
  final VoidCallback onUploadNew;

  const BackgroundPickerGrid({
    super.key,
    required this.images,
    required this.onSelect,
    required this.onUploadNew,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Choose a background design',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          Text(
            'Pick from previously uploaded backgrounds, or upload a new one.',
            style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Obx(() {
              // ✅ forces GetX to register this Rx as a dependency of Obx
              // (reading it *inside* the deferred LayoutBuilder below would
              // happen outside Obx's tracking scope and silently break).
              final imgs = images.toList();

              return LayoutBuilder(
                builder: (context, constraints) {
                  final width = constraints.maxWidth;
                  final crossAxisCount = width > 900
                      ? 4
                      : (width > 600 ? 3 : 2);
                  return GridView.builder(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: crossAxisCount,
                      childAspectRatio: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                    ),
                    itemCount: imgs.length + 1,
                    itemBuilder: (context, index) {
                      if (index == imgs.length) {
                        return InkWell(
                          onTap: onUploadNew,
                          child: Container(
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey.shade400),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.add_photo_alternate,
                                    color: Colors.grey,
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    'Upload new',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }
                      final url = imgs[index];
                      return InkWell(
                        onTap: () => onSelect(url),
                        borderRadius: BorderRadius.circular(10),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.network(url, fit: BoxFit.cover),
                        ),
                      );
                    },
                  );
                },
              );
            }),
          ),
        ],
      ),
    );
  }
}
