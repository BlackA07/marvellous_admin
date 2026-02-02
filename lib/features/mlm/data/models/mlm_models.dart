class CommissionLevel {
  int level;
  double percentage;
  double amount;

  CommissionLevel({
    required this.level,
    required this.percentage,
    this.amount = 0.0,
  });

  factory CommissionLevel.fromJson(Map<String, dynamic> json) {
    return CommissionLevel(
      level: json['level'] ?? 0,
      percentage: (json['percentage'] ?? 0).toDouble(),
      amount: (json['amount'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {'level': level, 'percentage': percentage, 'amount': amount};
  }

  @override
  String toString() {
    return 'CommissionLevel(level: $level, percentage: $percentage%, amount: Rs $amount)';
  }
}

class MLMNode {
  final String id;
  final String name;
  final String role;
  final String? profileImage;
  final List<MLMNode> children;

  MLMNode({
    required this.id,
    required this.name,
    required this.role,
    this.profileImage,
    this.children = const [],
  });

  String get initials {
    if (name.isEmpty) return "U";
    final parts = name.trim().split(" ");
    if (parts.length > 1) {
      return "${parts[0][0]}${parts[1][0]}".toUpperCase();
    }
    return parts[0][0].toUpperCase();
  }

  factory MLMNode.fromJson(Map<String, dynamic> json) {
    return MLMNode(
      id: json['id'],
      name: json['name'],
      role: json['role'],
      profileImage: json['profileImage'],
      children: (json['children'] as List<dynamic>? ?? [])
          .map((e) => MLMNode.fromJson(e))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'role': role,
      'profileImage': profileImage,
      'children': children.map((e) => e.toJson()).toList(),
    };
  }
}
