class RecentActivityModel {
  final String id;
  final String user;
  final String action;
  final String timestamp;
  final String status; // 'Completed', 'Pending', 'Failed'

  RecentActivityModel({
    required this.id,
    required this.user,
    required this.action,
    required this.timestamp,
    required this.status,
  });
}
