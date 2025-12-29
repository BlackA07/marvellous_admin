class RecentActivityModel {
  final String?
  id; // ID can be nullable if not strictly used for navigation yet
  final String user;
  final String action;
  final String timestamp;
  final String status; // 'Completed', 'Pending', 'Failed'

  RecentActivityModel({
    this.id,
    required this.user,
    required this.action,
    required this.timestamp,
    required this.status,
  });
}
