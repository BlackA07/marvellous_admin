import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/orders_controller.dart';
import '../widgets/order_card.dart';

class OrderHistoryScreen extends StatefulWidget {
  const OrderHistoryScreen({Key? key}) : super(key: key);

  @override
  State<OrderHistoryScreen> createState() => _OrderHistoryScreenState();
}

class _OrderHistoryScreenState extends State<OrderHistoryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final OrdersController controller = Get.find(); // Find existing controller

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    controller.fetchHistory(); // Fetch data when screen loads
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("History"),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: "Customer History"),
            Tab(text: "Vendor History"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Customer List
          Obx(
            () => ListView.builder(
              itemCount: controller.historyOrders.length,
              itemBuilder: (context, index) {
                final order = controller.historyOrders[index];
                return CommonListCard(
                  title: order.productName,
                  subtitle: order.status.toUpperCase(),
                  imageUrl: order.productImage,
                  price: order.price.toString(),
                  isHistory: true, // Hides Accept/Reject
                  onView: () {},
                  onAccept: () {},
                  onReject: () {},
                );
              },
            ),
          ),

          // Vendor List
          Obx(
            () => ListView.builder(
              itemCount: controller.historyRequests.length,
              itemBuilder: (context, index) {
                final req = controller.historyRequests[index];
                return CommonListCard(
                  title: req.productName,
                  subtitle: "${req.requestType} - ${req.status}",
                  imageUrl: req.productImage,
                  price: req.productPrice.toString(),
                  isHistory: true,
                  onView: () {},
                  onAccept: () {},
                  onReject: () {},
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
