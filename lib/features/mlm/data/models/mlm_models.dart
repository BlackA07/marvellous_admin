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
  final int totalMembers; // Total active people under this node (all levels)
  final int paidMembers; // How many paid fees (all levels)
  final int remainingSlots; // For level display (7 - current children)
  final bool isOverflow; // Placed under different parent than referrer
  final bool
  isDirectReferral; // Joined using root user's referral code directly

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
    this.isOverflow = false,
    this.isDirectReferral = false,
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
      isOverflow: json['isOverflow'] ?? false,
      isDirectReferral: json['isDirectReferral'] ?? false,
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
      'isOverflow': isOverflow,
      'isDirectReferral': isDirectReferral,
    };
  }

  MLMNode copyWith({
    String? uid,
    String? name,
    String? image,
    String? myReferralCode,
    int? level,
    bool? isMLMActive,
    bool? hasPaidFee,
    String? rank,
    double? totalCommissionEarned,
    List<MLMNode>? children,
    int? totalMembers,
    int? paidMembers,
    int? remainingSlots,
    bool? isOverflow,
    bool? isDirectReferral,
  }) {
    return MLMNode(
      uid: uid ?? this.uid,
      name: name ?? this.name,
      image: image ?? this.image,
      myReferralCode: myReferralCode ?? this.myReferralCode,
      level: level ?? this.level,
      isMLMActive: isMLMActive ?? this.isMLMActive,
      hasPaidFee: hasPaidFee ?? this.hasPaidFee,
      rank: rank ?? this.rank,
      totalCommissionEarned:
          totalCommissionEarned ?? this.totalCommissionEarned,
      children: children ?? this.children,
      totalMembers: totalMembers ?? this.totalMembers,
      paidMembers: paidMembers ?? this.paidMembers,
      remainingSlots: remainingSlots ?? this.remainingSlots,
      isOverflow: isOverflow ?? this.isOverflow,
      isDirectReferral: isDirectReferral ?? this.isDirectReferral,
    );
  }
}
