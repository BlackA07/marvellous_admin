// lib/features/reports/shared/widgets/sales_chart_card.dart

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../controller/dashboard_controller.dart';

class SalesChartCard extends StatelessWidget {
  final DashboardController controller = Get.find();

  SalesChartCard({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    bool isDesktop = width > 1100;

    const faceGradient = LinearGradient(
      begin: Alignment.topRight,
      end: Alignment.bottomLeft,
      colors: [
        Colors.white,
        Color(0xFFDADDE3),
        Color(0xFF98A2B3),
        Color(0xFF667085),
      ],
      stops: [0.0, 0.2, 0.6, 1.0],
    );

    return Container(
      height: 380,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Revenue vs Expenses (PKR)",
                      style: TextStyle(
                        fontFamily: 'Comic Sans MS',
                        color: Colors.black87,
                        fontSize: isDesktop ? 18 : 14,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Row(
                      children: [
                        _legendDot(Colors.blueAccent, "Sales"),
                        const SizedBox(width: 10),
                        _legendDot(Colors.redAccent, "Expenses"),
                      ],
                    ),
                  ],
                ),
              ),
              // ✅ NAYA: Custom button added in the list
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: ["Day", "Week", "Month", "Year", "Custom"].map((
                    filter,
                  ) {
                    return Obx(() {
                      bool isSelected =
                          controller.selectedFilter.value == filter;

                      // Agar custom select hai toh button pe date range show karwa dein
                      String buttonText = filter;
                      if (filter == 'Custom' &&
                          isSelected &&
                          controller.customStartDate.value != null) {
                        String sDate = DateFormat(
                          'dd MMM',
                        ).format(controller.customStartDate.value!);
                        String eDate = DateFormat(
                          'dd MMM',
                        ).format(controller.customEndDate.value!);
                        buttonText = "$sDate - $eDate";
                      }

                      return InkWell(
                        onTap: () {
                          if (filter == 'Custom') {
                            controller.selectCustomDateRange(context);
                          } else {
                            controller.updateFilter(filter);
                          }
                        },
                        child: Container(
                          margin: const EdgeInsets.only(left: 5),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? Colors.cyanAccent.withOpacity(0.3)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isSelected
                                  ? Colors.cyan[700]!
                                  : Colors.black12,
                            ),
                          ),
                          child: Text(
                            buttonText,
                            style: TextStyle(
                              fontFamily: 'Comic Sans MS',
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
          const SizedBox(height: 20),

          // GRAPH SECTION
          Expanded(
            child: Obx(
              () => LineChart(
                LineChartData(
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    getDrawingHorizontalLine: (value) =>
                        FlLine(color: Colors.black12, strokeWidth: 1),
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
                            color: Colors.black87,
                            fontWeight: FontWeight.bold,
                            fontSize: 10,
                          );
                          String text = '';
                          String filter = controller.selectedFilter.value;

                          if (filter == 'Day' && value % 4 == 0)
                            text = '${value.toInt()}h';
                          else if (filter == 'Week') {
                            List<String> days = [
                              '',
                              'Mon',
                              'Tue',
                              'Wed',
                              'Thu',
                              'Fri',
                              'Sat',
                              'Sun',
                            ];
                            if (value > 0 && value <= 7)
                              text = days[value.toInt()];
                          } else if ((filter == 'Month' ||
                                  (filter == 'Custom' &&
                                      controller.customEndDate.value!
                                              .difference(
                                                controller
                                                    .customStartDate
                                                    .value!,
                                              )
                                              .inDays <=
                                          31)) &&
                              value % 5 == 0) {
                            text = value.toInt().toString();
                          } else if (filter == 'Year' ||
                              (filter == 'Custom' &&
                                  controller.customEndDate.value!
                                          .difference(
                                            controller.customStartDate.value!,
                                          )
                                          .inDays >
                                      31)) {
                            List<String> m = [
                              '',
                              'Jan',
                              'Feb',
                              'Mar',
                              'Apr',
                              'May',
                              'Jun',
                              'Jul',
                              'Aug',
                              'Sep',
                              'Oct',
                              'Nov',
                              'Dec',
                            ];
                            if (value > 0 && value <= 12)
                              text = m[value.toInt()];
                          }

                          return SideTitleWidget(
                            meta: meta,
                            space: 8.0,
                            child: Text(text, style: style),
                          );
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 45,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            "${(value / 1000).toStringAsFixed(0)}k",
                            style: const TextStyle(
                              color: Colors.black87,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  borderData: FlBorderData(
                    show: true,
                    border: const Border(
                      bottom: BorderSide(color: Colors.black26, width: 1),
                      left: BorderSide(color: Colors.black26, width: 1),
                      top: BorderSide(color: Colors.transparent),
                      right: BorderSide(color: Colors.transparent),
                    ),
                  ),
                  minX: controller.selectedFilter.value == 'Day' ? 0 : 1,
                  maxX: controller.selectedFilter.value == 'Day'
                      ? 23
                      : (controller.selectedFilter.value == 'Week'
                            ? 7
                            : (controller.selectedFilter.value == 'Month' ||
                                      (controller.selectedFilter.value ==
                                              'Custom' &&
                                          controller.customEndDate.value!
                                                  .difference(
                                                    controller
                                                        .customStartDate
                                                        .value!,
                                                  )
                                                  .inDays <=
                                              31)
                                  ? 31
                                  : 12)),
                  minY: 0,
                  maxY: controller.chartMaxY.value,
                  lineBarsData: [
                    LineChartBarData(
                      spots: controller.salesSpots,
                      isCurved: true,
                      color: Colors.blueAccent,
                      barWidth: 3,
                      isStrokeCapRound: true,
                      dotData: FlDotData(show: false),
                      belowBarData: BarAreaData(
                        show: true,
                        color: Colors.blueAccent.withOpacity(0.2),
                      ),
                    ),
                    LineChartBarData(
                      spots: controller.expenseSpots,
                      isCurved: true,
                      color: Colors.redAccent,
                      barWidth: 3,
                      isStrokeCapRound: true,
                      dotData: FlDotData(show: false),
                      belowBarData: BarAreaData(
                        show: true,
                        color: Colors.redAccent.withOpacity(0.2),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _legendDot(Color color, String text) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          text,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}
