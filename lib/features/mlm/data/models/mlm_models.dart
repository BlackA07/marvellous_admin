// File: lib/features/mlm/data/models/mlm_models.dart

class CommissionLevel {
  int level;
  double percentage;

  CommissionLevel({required this.level, required this.percentage});

  // Firebase se data lane k liye
  factory CommissionLevel.fromJson(Map<String, dynamic> json) {
    return CommissionLevel(
      level: json['level'] ?? 0,
      percentage: (json['percentage'] ?? 0).toDouble(),
    );
  }

  // Firebase men save karne k liye
  Map<String, dynamic> toJson() {
    return {'level': level, 'percentage': percentage};
  }
}

class MLMNode {
  final String id;
  final String name;
  final String role; // e.g., Admin, Vendor, Rider
  final String? profileImage; // Agar image URL ho
  final List<MLMNode> children;

  MLMNode({
    required this.id,
    required this.name,
    required this.role,
    this.profileImage,
    this.children = const [],
  });

  // Initials nikalne k liye (Arslan Ali -> AA)
  String get initials {
    if (name.isEmpty) return "U";
    List<String> parts = name.trim().split(" ");
    if (parts.length > 1) {
      return "${parts[0][0]}${parts[1][0]}".toUpperCase();
    }
    return parts[0][0].toUpperCase();
  }
}
