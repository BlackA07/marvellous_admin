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

    // Metallic Gradient from TextField
    const faceGradient = LinearGradient(
      begin: Alignment.topRight,
      end: Alignment.bottomLeft,
      colors: [
        Colors.white, // Top Highlight
        Color.fromARGB(255, 218, 221, 227), // Light Silver
        Color(0xFF98A2B3), // Darker Silver
        Color(0xFF667085), // Shadow Base
      ],
      stops: [0.0, 0.2, 0.6, 1.0],
    );

    return Container(
      height: 350,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        // Applied Gradient Here
        gradient: faceGradient,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.6)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            offset: const Offset(0, 4),
            blurRadius: 6,
          ),
        ],
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
                    color: Colors.black87, // Font Black
                    fontSize: isDesktop ? 16 : 13,
                    fontWeight:
                        FontWeight.w900, // Thora aur bold metallic look k liye
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
                            // Selected: Cyan bg, Unselected: Transparent
                            color: isSelected
                                ? Colors.cyanAccent.withOpacity(0.3)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isSelected
                                  ? Colors
                                        .cyan[700]! // Darker border for visibility
                                  : Colors.black12,
                            ),
                          ),
                          child: Text(
                            filter,
                            style: TextStyle(
                              fontFamily: 'Comic Sans MS',
                              // Font Black
                              color: isSelected ? Colors.black : Colors.black54,
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
                    // Grid lines dark taake silver pe dikhen
                    return FlLine(color: Colors.black12, strokeWidth: 1);
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
                          color: Colors.black87, // Font Black
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
                        return SideTitleWidget(
                          meta: meta, // Updated for newer fl_chart
                          space: 8.0,
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
                            color: Colors.black87, // Font Black
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        );
                      },
                      reservedSize: 40,
                    ),
                  ),
                ),
                borderData: FlBorderData(
                  show: true,
                  // L-Shape Border Dark
                  border: const Border(
                    bottom: BorderSide(color: Colors.black26, width: 1),
                    left: BorderSide(color: Colors.black26, width: 1),
                    top: BorderSide(color: Colors.transparent),
                    right: BorderSide(color: Colors.transparent),
                  ),
                ),
                minX: 0,
                maxX: 6,
                minY: 0,
                maxY: 50000,
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
                    // Line Gradient thora dark kiya taake silver pe shine kare
                    gradient: const LinearGradient(
                      colors: [Colors.blueAccent, Colors.purpleAccent],
                    ),
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: [
                          Colors.blueAccent.withOpacity(0.3),
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
