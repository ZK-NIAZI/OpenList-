import 'package:isar/isar.dart';

part 'user_model.g.dart';

@collection
class UserModel {
  Id id = Isar.autoIncrement;

  @Index(unique: true)
  late String userId; // Supabase UUID

  late String email;

  late String displayName;

  String? avatarUrl;

  @enumerated
  late UserPlan plan;

  String? fcmToken;

  late DateTime createdAt;

  late DateTime updatedAt;

  @enumerated
  late SyncStatus syncStatus;

  UserModel({
    this.id = Isar.autoIncrement,
    required this.userId,
    required this.email,
    required this.displayName,
    this.avatarUrl,
    this.plan = UserPlan.free,
    this.fcmToken,
    DateTime? createdAtParam,
    DateTime? updatedAtParam,
    this.syncStatus = SyncStatus.synced,
  })  : createdAt = createdAtParam ?? DateTime.now(),
        updatedAt = updatedAtParam ?? DateTime.now();

  // Convert from Supabase JSON
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      userId: json['id'] as String,
      email: json['email'] as String,
      displayName: json['display_name'] as String? ?? json['email'].toString().split('@')[0],
      avatarUrl: json['avatar_url'] as String?,
      plan: UserPlan.values.firstWhere(
        (e) => e.name == (json['plan'] ?? 'free'),
        orElse: () => UserPlan.free,
      ),
      fcmToken: json['fcm_token'] as String?,
      createdAtParam: json['created_at'] != null ? DateTime.parse(json['created_at'] as String) : null,
      updatedAtParam: json['updated_at'] != null ? DateTime.parse(json['updated_at'] as String) : null,
    );
  }

  // Convert to Supabase JSON
  Map<String, dynamic> toJson() {
    return {
      'id': userId,
      'email': email,
      'display_name': displayName,
      'avatar_url': avatarUrl,
      'plan': plan.name,
      'fcm_token': fcmToken,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  // Get initials for avatar fallback
  String get initials {
    final parts = displayName.split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return displayName.isNotEmpty ? displayName[0].toUpperCase() : '?';
  }
}

enum UserPlan {
  free,
  pro,
  enterprise,
}

enum SyncStatus {
  synced,
  pending,
  error,
}
