import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/mlm_controller.dart';
import '../widgets/mlm_node_widget.dart';

class MLMTreeViewScreen extends StatelessWidget {
  const MLMTreeViewScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(MLMController());

    return Scaffold(
      appBar: AppBar(
        title: const Text("Network Hierarchy"),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => controller.loadData(),
          ),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        if (controller.rootNode.value == null) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.account_tree, size: 80, color: Colors.grey),
                SizedBox(height: 20),
                Text(
                  "No Network Data Found",
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                ),
                SizedBox(height: 10),
                Text(
                  "Make sure a root user exists with isAdmin = true",
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        return LayoutBuilder(
          builder: (context, constraints) {
            return InteractiveViewer(
              constrained: false,
              boundaryMargin: const EdgeInsets.all(200),
              minScale: 0.1,
              maxScale: 4.0,
              child: Container(
                constraints: BoxConstraints(
                  minWidth: constraints.maxWidth,
                  minHeight: constraints.maxHeight,
                ),
                alignment: Alignment.topCenter,
                padding: const EdgeInsets.only(top: 50, bottom: 100),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: MLMNodeWidget(
                    node: controller.rootNode.value!,
                    isRoot: true,
                  ),
                ),
              ),
            );
          },
        );
      }),
    );
  }
}
