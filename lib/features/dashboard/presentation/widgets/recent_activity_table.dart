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

          // SingleChildScrollView added for Horizontal Scrolling
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: ConstrainedBox(
              // Minimum width taake web pe full stretch ho, mobile pe scroll ho
              constraints: BoxConstraints(minWidth: 600),
              child: DataTable(
                horizontalMargin: 0,
                columnSpacing: 20,
                columns: const [
                  DataColumn(
                    label: Text(
                      'User',
                      style: TextStyle(
                        fontFamily: 'Comic Sans MS',
                        color: Colors.white54,
                      ),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      'Action',
                      style: TextStyle(
                        fontFamily: 'Comic Sans MS',
                        color: Colors.white54,
                      ),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      'Time',
                      style: TextStyle(
                        fontFamily: 'Comic Sans MS',
                        color: Colors.white54,
                      ),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      'Status',
                      style: TextStyle(
                        fontFamily: 'Comic Sans MS',
                        color: Colors.white54,
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
        ),
      ),
    );
  }
}
