// File: lib/features/mlm/presentation/screens/mlm_tree_view.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/mlm_controller.dart';
import '../widgets/mlm_node_widget.dart';

class MLMTreeViewScreen extends StatelessWidget {
  const MLMTreeViewScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Controller inject kar rahe hen
    final controller = Get.put(MLMController());

    return Scaffold(
      appBar: AppBar(
        title: const Text("Network Hierarchy"),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: controller.loadData,
          ),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        if (controller.rootNode.value == null) {
          return const Center(child: Text("No Data Found"));
        }

        return LayoutBuilder(
          builder: (context, constraints) {
            // InteractiveViewer se zoom in/out hoga
            return InteractiveViewer(
              constrained: false, // Infinite scroll allow karta he
              boundaryMargin: const EdgeInsets.all(100),
              minScale: 0.1,
              maxScale: 4.0,
              child: Container(
                // Screen k center se start ho
                constraints: BoxConstraints(
                  minWidth: constraints.maxWidth,
                  minHeight: constraints.maxHeight,
                ),
                alignment: Alignment.topCenter,
                padding: const EdgeInsets.only(top: 50, bottom: 50),
                child: MLMNodeWidget(
                  node: controller.rootNode.value!,
                  isRoot: true,
                ),
              ),
            );
          },
        );
      }),
    );
  }
}
