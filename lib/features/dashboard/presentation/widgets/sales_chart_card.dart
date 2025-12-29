import 'package:fl_chart/fl_chart.dart'; // Ensure fl_chart is in pubspec.yaml
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controller/dashboard_controller.dart';

class SalesChartCard extends StatelessWidget {
  final DashboardController controller = Get.find();

  SalesChartCard({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    bool isDesktop = width > 1100;

    return Container(
      height: 350,
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
                  "Sales Overview (PKR)",
                  style: TextStyle(
                    fontFamily: 'Comic Sans MS',
                    color: Colors.white,
                    fontSize: isDesktop ? 16 : 13,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              // Filter Buttons
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
                              fontSize: isDesktop ? 13 : 10,
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
          const SizedBox(height: 30),

          // GRAPH SECTION
          Expanded(
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(color: Colors.white10, strokeWidth: 1);
                  },
                ),
                titlesData: FlTitlesData(
                  show: true,
                  rightTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      interval: 1,
                      getTitlesWidget: (value, meta) {
                        const style = TextStyle(
                          color: Colors.white54,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        );
                        String text;
                        switch (value.toInt()) {
                          case 0:
                            text = 'Mon';
                            break;
                          case 2:
                            text = 'Wed';
                            break;
                          case 4:
                            text = 'Fri';
                            break;
                          case 6:
                            text = 'Sun';
                            break;
                          default:
                            return Container();
                        }
                        // FIX: Updated SideTitleWidget usage
                        return SideTitleWidget(
                          space: 8.0,
                          meta: meta, // Required parameter passed here
                          child: Text(text, style: style),
                        );
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 10000,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          "${(value / 1000).toStringAsFixed(0)}k",
                          style: const TextStyle(
                            color: Colors.white54,
                            fontSize: 10,
                          ),
                        );
                      },
                      reservedSize: 40,
                    ),
                  ),
                ),
                borderData: FlBorderData(
                  show: true,
                  // L-Shape Border (Bottom and Left only)
                  border: const Border(
                    bottom: BorderSide(color: Colors.white24, width: 1),
                    left: BorderSide(color: Colors.white24, width: 1),
                    top: BorderSide(color: Colors.transparent),
                    right: BorderSide(color: Colors.transparent),
                  ),
                ),
                minX: 0,
                maxX: 6,
                minY: 0,
                maxY: 50000, // Dynamic max logic can be added
                lineBarsData: [
                  LineChartBarData(
                    spots: const [
                      FlSpot(0, 5000),
                      FlSpot(1, 15000),
                      FlSpot(2, 10000),
                      FlSpot(3, 25000),
                      FlSpot(4, 18000),
                      FlSpot(5, 35000),
                      FlSpot(6, 42000),
                    ],
                    isCurved: true,
                    gradient: const LinearGradient(
                      colors: [Colors.cyanAccent, Colors.purpleAccent],
                    ),
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: [
                          Colors.cyanAccent.withOpacity(0.2),
                          Colors.purpleAccent.withOpacity(0.0),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
