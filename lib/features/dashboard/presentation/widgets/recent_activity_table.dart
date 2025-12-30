import 'package:flutter/material.dart';
import '../../models/recent_activity_model.dart';

class RecentActivityTable extends StatelessWidget {
  final List<RecentActivityModel> activities;

  const RecentActivityTable({Key? key, required this.activities})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2D3E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Recent Activity",
            style: TextStyle(
              fontFamily: 'Comic Sans MS',
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),

          // Check if list is empty
          if (activities.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(20.0),
                child: Text(
                  "No recent activity found.",
                  style: TextStyle(color: Colors.white54),
                ),
              ),
            )
          else
            // LayoutBuilder se hum available width nikalenge
            LayoutBuilder(
              builder: (context, constraints) {
                // Agar Available Width 600 se ziada hai (Laptop), to width match karo.
                // Agar kam hai (Phone), to minimum 600 rakho taake scroll ho.
                double minWidth = constraints.maxWidth < 600
                    ? 600
                    : constraints.maxWidth;

                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minWidth: minWidth),
                    child: DataTable(
                      horizontalMargin: 10, // Thora gap side se
                      columnSpacing: 20,
                      // Heading Row Color
                      headingRowColor: MaterialStateProperty.resolveWith(
                        (states) => Colors.white.withOpacity(0.02),
                      ),
                      columns: const [
                        DataColumn(
                          label: Text(
                            'User',
                            style: TextStyle(
                              fontFamily: 'Comic Sans MS',
                              color: Colors.white54,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        DataColumn(
                          label: Text(
                            'Action',
                            style: TextStyle(
                              fontFamily: 'Comic Sans MS',
                              color: Colors.white54,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        DataColumn(
                          label: Text(
                            'Time',
                            style: TextStyle(
                              fontFamily: 'Comic Sans MS',
                              color: Colors.white54,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        DataColumn(
                          label: Text(
                            'Status',
                            style: TextStyle(
                              fontFamily: 'Comic Sans MS',
                              color: Colors.white54,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                      rows: activities.map((activity) {
                        return DataRow(
                          cells: [
                            DataCell(
                              Text(
                                activity.user,
                                style: const TextStyle(
                                  fontFamily: 'Comic Sans MS',
                                  color: Colors.white,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            DataCell(
                              Text(
                                activity.action,
                                style: const TextStyle(
                                  fontFamily: 'Comic Sans MS',
                                  color: Colors.white70,
                                ),
                              ),
                            ),
                            DataCell(
                              Text(
                                activity.timestamp,
                                style: const TextStyle(
                                  fontFamily: 'Comic Sans MS',
                                  color: Colors.white38,
                                ),
                              ),
                            ),
                            DataCell(_buildStatusBadge(activity.status)),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    switch (status) {
      case 'Completed':
        color = Colors.greenAccent;
        break;
      case 'Pending':
        color = Colors.orangeAccent;
        break;
      case 'Failed':
        color = Colors.redAccent;
        break;
      default:
        color = Colors.grey;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Text(
        status,
        style: TextStyle(
          fontFamily: 'Comic Sans MS',
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
