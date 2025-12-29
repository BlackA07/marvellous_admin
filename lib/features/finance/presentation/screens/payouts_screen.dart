import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/finance_controller.dart';
import '../widgets/payout_request_card.dart';

class PayoutsScreen extends StatelessWidget {
  const PayoutsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Controller already put in Dashboard or put here
    final controller = Get.isRegistered<FinanceController>()
        ? Get.find<FinanceController>()
        : Get.put(FinanceController());

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Payout Requests"),
          bottom: const TabBar(
            tabs: [
              Tab(text: "Customers", icon: Icon(Icons.person)),
              Tab(text: "Vendors", icon: Icon(Icons.store)),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // --- CUSTOMERS TAB ---
            Obx(() {
              if (controller.customerPayouts.isEmpty) {
                return const Center(
                  child: Text("No Pending Customer Requests"),
                );
              }
              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: controller.customerPayouts.length,
                itemBuilder: (context, index) {
                  final req = controller.customerPayouts[index];
                  return PayoutRequestCard(
                    request: req,
                    onAccept: () => controller.approvePayout(req.id),
                    onReject: () => controller.rejectPayout(req.id),
                  );
                },
              );
            }),

            // --- VENDORS TAB ---
            Obx(() {
              if (controller.vendorPayouts.isEmpty) {
                return const Center(child: Text("No Pending Vendor Requests"));
              }
              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: controller.vendorPayouts.length,
                itemBuilder: (context, index) {
                  final req = controller.vendorPayouts[index];
                  return PayoutRequestCard(
                    request: req,
                    onAccept: () => controller.approvePayout(req.id),
                    onReject: () => controller.rejectPayout(req.id),
                  );
                },
              );
            }),
          ],
        ),
      ),
    );
  }
}
