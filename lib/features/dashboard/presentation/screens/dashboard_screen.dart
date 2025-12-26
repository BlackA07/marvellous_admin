import 'package:flutter/material.dart';
import 'package:get/get.dart';

// Controller & Widgets Imports
import '../../controller/dashboard_controller.dart';
import '../widgets/stat_summary_card.dart';
import '../widgets/recent_activity_table.dart';
import '../widgets/sales_chart_card.dart';

class DashboardScreen extends StatelessWidget {
  final DashboardController controller = Get.put(DashboardController());

  DashboardScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Obx(() {
        if (controller.isLoading.value) {
          return const Center(
            child: CircularProgressIndicator(color: Colors.cyanAccent),
          );
        }

        if (controller.dashboardData.value == null) {
          return const Center(
            child: Text("No Data", style: TextStyle(color: Colors.white)),
          );
        }

        final data = controller.dashboardData.value!;

        return LayoutBuilder(
          builder: (context, constraints) {
            final bool isWideScreen = constraints.maxWidth > 1100;

            return SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // ================= TOP SECTION =================
                  if (isWideScreen)
                    IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // -------- CHART (40%) --------
                          Expanded(flex: 4, child: SalesChartCard()),

                          const SizedBox(width: 20),

                          // -------- STATS (60%) --------
                          Expanded(
                            flex: 6,
                            child: Column(
                              children: [
                                Expanded(
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: StatSummaryCard(
                                          info: data.stats[0],
                                        ),
                                      ),
                                      const SizedBox(width: 20),
                                      Expanded(
                                        child: StatSummaryCard(
                                          info: data.stats[1],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 20),
                                Expanded(
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: StatSummaryCard(
                                          info: data.stats[2],
                                        ),
                                      ),
                                      const SizedBox(width: 20),
                                      Expanded(
                                        child: StatSummaryCard(
                                          info: data.stats[3],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    // ================= MOBILE / TABLET =================
                    Column(
                      children: [
                        SalesChartCard(),
                        const SizedBox(height: 20),
                        GridView.builder(
                          physics: const NeverScrollableScrollPhysics(),
                          shrinkWrap: true,
                          itemCount: data.stats.length,
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                crossAxisSpacing: 15,
                                mainAxisSpacing: 15,
                                childAspectRatio: 1.4,
                              ),
                          itemBuilder: (context, index) {
                            return StatSummaryCard(info: data.stats[index]);
                          },
                        ),
                      ],
                    ),

                  const SizedBox(height: 20),

                  // ================= BOTTOM SECTION =================
                  RecentActivityTable(activities: data.recentActivities),
                ],
              ),
            );
          },
        );
      }),
    );
  }
}
