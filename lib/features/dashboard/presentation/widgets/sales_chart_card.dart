import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controller/dashboard_controller.dart';

class SalesChartCard extends StatelessWidget {
  final DashboardController controller = Get.find();

  SalesChartCard({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Screen width check karte hen font scaling k liye
    double width = MediaQuery.of(context).size.width;
    bool isDesktop = width > 1100;

    return Container(
      height: 300,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2D3E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  "Sales Overview",
                  style: TextStyle(
                    fontFamily: 'Comic Sans MS',
                    color: Colors.white,
                    // Mobile: 16, Desktop: 22
                    fontSize: isDesktop ? 22 : 11,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),

              // Filters - Wrapped in SingleChildScrollView
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: ["Day", "Week", "Month", "Year"].map((filter) {
                    return Obx(() {
                      bool isSelected =
                          controller.selectedFilter.value == filter;
                      return InkWell(
                        onTap: () => controller.updateFilter(filter),
                        child: Container(
                          margin: const EdgeInsets.only(left: 5),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? Colors.cyanAccent.withOpacity(0.2)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isSelected
                                  ? Colors.cyanAccent
                                  : Colors.white12,
                            ),
                          ),
                          child: Text(
                            filter,
                            style: TextStyle(
                              fontFamily: 'Comic Sans MS',
                              color: isSelected
                                  ? Colors.cyanAccent
                                  : Colors.white54,
                              // Mobile: 10, Desktop: 14
                              fontSize: isDesktop ? 14 : 8,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      );
                    });
                  }).toList(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Expanded(
            child: Center(
              child: Text(
                "Chart Goes Here (FlChart)",
                style: TextStyle(
                  fontFamily: 'Comic Sans MS',
                  color: Colors.white24,
                  // Mobile: 14, Desktop: 18
                  fontSize: isDesktop ? 18 : 14,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
