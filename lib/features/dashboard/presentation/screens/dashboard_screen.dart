// lib/features/reports/shared/views/dashboard_screen.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controller/dashboard_controller.dart';
import '../widgets/stat_summary_card.dart';
import '../widgets/sales_chart_card.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final DashboardController controller = Get.put(DashboardController());

    return SafeArea(
      child: Obx(() {
        if (controller.isLoading.value) {
          return const Center(
            child: CircularProgressIndicator(color: Colors.cyanAccent),
          );
        }

        return LayoutBuilder(
          builder: (context, constraints) {
            final bool isWideScreen = constraints.maxWidth > 1100;

            return SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // ================= TOP CHART SECTION =================
                  SalesChartCard(),
                  const SizedBox(height: 20),

                  // ================= METRICS GRID SECTION =================
                  GridView.builder(
                    physics: const NeverScrollableScrollPhysics(),
                    shrinkWrap: true,
                    itemCount: controller.statsList.length,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: isWideScreen
                          ? 3
                          : (constraints.maxWidth > 600 ? 2 : 1),
                      crossAxisSpacing: 15,
                      mainAxisSpacing: 15,
                      childAspectRatio: isWideScreen ? 2.5 : 2.0,
                    ),
                    itemBuilder: (context, index) {
                      return StatSummaryCard(info: controller.statsList[index]);
                    },
                  ),
                ],
              ),
            );
          },
        );
      }),
    );
  }
}
