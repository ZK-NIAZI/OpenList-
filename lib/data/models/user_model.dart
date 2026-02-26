import 'package:isar/isar.dart';

part 'user_model.g.dart';

@collection
class UserModel {
  Id id = Isar.autoIncrement;

  @Index(unique: true)
  late String userId; // Supabase UUID

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
      displayName: json['display_name'] as String,
      avatarUrl: json['avatar_url'] as String?,
      plan: UserPlan.values.firstWhere(
        (e) => e.name == json['plan'],
        orElse: () => UserPlan.free,
      ),
      fcmToken: json['fcm_token'] as String?,
      createdAtParam: DateTime.parse(json['created_at'] as String),
      updatedAtParam: DateTime.parse(json['updated_at'] as String),
    );
  }

  // Convert to Supabase JSON
  Map<String, dynamic> toJson() {
    return {
      'id': userId,
      'display_name': displayName,
      'avatar_url': avatarUrl,
      'plan': plan.name,
      'fcm_token': fcmToken,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
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
