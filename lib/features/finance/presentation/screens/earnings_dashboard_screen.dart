// File: lib/features/finance/presentation/screens/earnings_dashboard_screen.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/finance_controller.dart';
import '../widgets/earning_summary_card.dart';
import 'earnings_history_screen.dart'; // History Screen Import
import '../../../orders/presentation/screens/order_detail_screen.dart'; // Detail Screen Import

class EarningsDashboardScreen extends StatelessWidget {
  const EarningsDashboardScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Ensure controller is loaded
    final controller = Get.isRegistered<FinanceController>()
        ? Get.find<FinanceController>()
        : Get.put(FinanceController());

    double width = MediaQuery.of(context).size.width;
    bool isDesktop = width > 800;

    return Scaffold(
      appBar: AppBar(title: const Text("Earnings Overview")),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- TOP CARDS GRID (With Click & Animation) ---
              Obx(
                () => GridView.count(
                  crossAxisCount: isDesktop ? 3 : 1,
                  childAspectRatio: isDesktop ? 2.5 : 2.2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    EarningSummaryCard(
                      title: "Total Earnings",
                      amount:
                          "PKR ${controller.totalEarnings.toStringAsFixed(0)}",
                      icon: Icons.account_balance_wallet,
                      color: Colors.blueAccent,
                      onTap: () {
                        Get.to(
                          () => const EarningsHistoryScreen(
                            title: "Total Earnings History",
                            filterType: 'all',
                          ),
                        );
                      },
                    ),
                    EarningSummaryCard(
                      title: "This Month",
                      amount:
                          "PKR ${controller.monthlyEarnings.toStringAsFixed(0)}",
                      icon: Icons.calendar_today,
                      color: Colors.orangeAccent,
                      onTap: () {
                        Get.to(
                          () => const EarningsHistoryScreen(
                            title: "Monthly Earnings",
                            filterType: 'month',
                          ),
                        );
                      },
                    ),
                    EarningSummaryCard(
                      title: "Today's Sale",
                      amount:
                          "PKR ${controller.dailyEarnings.toStringAsFixed(0)}",
                      icon: Icons.today,
                      color: Colors.green,
                      onTap: () {
                        Get.to(
                          () => const EarningsHistoryScreen(
                            title: "Today's Sales",
                            filterType: 'today',
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 30),

              // --- RECENT TRANSACTIONS (Real Data Only) ---
              Text(
                "Recent Transactions",
                style: TextStyle(
                  fontSize: isDesktop ? 20 : 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),

              // Obx lagaya taake jaise hi data aye update ho
              Obx(() {
                if (controller.recentOrders.isEmpty) {
                  return Container(
                    padding: const EdgeInsets.all(20),
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Center(
                      child: Text(
                        "No Transactions Yet.\nReal data will appear here once orders are completed.",
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: controller.recentOrders.length,
                  itemBuilder: (context, index) {
                    final order = controller.recentOrders[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      child: ListTile(
                        leading: Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(8),
                            image: order.productImage.isNotEmpty
                                ? DecorationImage(
                                    image: NetworkImage(order.productImage),
                                    fit: BoxFit.cover,
                                  )
                                : null,
                          ),
                          child: order.productImage.isEmpty
                              ? const Icon(Icons.shopping_bag)
                              : null,
                        ),
                        title: Text(
                          order.productName,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text("Customer: ${order.customerName}"),
                        trailing: Text(
                          "PKR ${order.price}",
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                        onTap: () {
                          // Click pe detail screen
                          Get.to(() => OrderDetailScreen(order: order));
                        },
                      ),
                    );
                  },
                );
              }),
            ],
          ),
        ),
      ),
    );
  }
}
