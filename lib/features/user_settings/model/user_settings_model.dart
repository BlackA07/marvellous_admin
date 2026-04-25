class UserSettingsModel {
  final String staffId;
  final Map<String, List<String>> permissions;
  final DateTime updatedAt;

  UserSettingsModel({
    required this.staffId,
    required this.permissions,
    required this.updatedAt,
  });

  Map<String, dynamic> toFirestore() {
    return {
      'staffId': staffId,
      'permissions': permissions,
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory UserSettingsModel.fromFirestore(
    Map<String, dynamic> map,
    String docId,
  ) {
    // Convert dynamic map to Map<String, List<String>> safely
    Map<String, List<String>> parsedPermissions = {};
    if (map['permissions'] != null) {
      final Map<String, dynamic> rawPerms = map['permissions'];
      rawPerms.forEach((key, value) {
        parsedPermissions[key] = List<String>.from(value);
      });
    }

    return UserSettingsModel(
      staffId: map['staffId'] ?? docId,
      permissions: parsedPermissions,
      updatedAt: map['updatedAt'] != null
          ? DateTime.parse(map['updatedAt'])
          : DateTime.now(),
    );
  }
}
