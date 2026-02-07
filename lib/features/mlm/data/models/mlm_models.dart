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
  final String uid;
  final String name;
  final String image;
  final String myReferralCode;
  final int level;
  final bool isMLMActive;
  final bool hasPaidFee;
  final String rank; // bronze, silver, gold, diamond
  final double totalCommissionEarned;
  final List<MLMNode> children;
  final int totalMembers; // Total people under this node (all levels)
  final int paidMembers; // How many paid fees (all levels)
  final int remainingSlots; // For level display (7 - current children)

  MLMNode({
    required this.uid,
    required this.name,
    required this.image,
    required this.myReferralCode,
    required this.level,
    required this.isMLMActive,
    required this.hasPaidFee,
    required this.rank,
    required this.totalCommissionEarned,
    this.children = const [],
    this.totalMembers = 0,
    this.paidMembers = 0,
    this.remainingSlots = 0,
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
      uid: json['uid'] ?? '',
      name: json['name'] ?? 'User',
      image: json['image'] ?? '',
      myReferralCode: json['myReferralCode'] ?? '',
      level: json['level'] ?? 0,
      isMLMActive: json['isMLMActive'] ?? false,
      hasPaidFee: json['hasPaidFee'] ?? false,
      rank: json['rank'] ?? 'bronze',
      totalCommissionEarned: (json['totalCommissionEarned'] ?? 0).toDouble(),
      children: (json['children'] as List<dynamic>? ?? [])
          .map((e) => MLMNode.fromJson(e))
          .toList(),
      totalMembers: json['totalMembers'] ?? 0,
      paidMembers: json['paidMembers'] ?? 0,
      remainingSlots: json['remainingSlots'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'name': name,
      'image': image,
      'myReferralCode': myReferralCode,
      'level': level,
      'isMLMActive': isMLMActive,
      'hasPaidFee': hasPaidFee,
      'rank': rank,
      'totalCommissionEarned': totalCommissionEarned,
      'children': children.map((e) => e.toJson()).toList(),
      'totalMembers': totalMembers,
      'paidMembers': paidMembers,
      'remainingSlots': remainingSlots,
    };
  }
}
