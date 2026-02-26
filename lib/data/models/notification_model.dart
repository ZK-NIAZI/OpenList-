import 'package:isar/isar.dart';
import 'package:openlist/core/models/sync_status.dart';

part 'notification_model.g.dart';

@collection
class NotificationModel {
  Id id = Isar.autoIncrement;

  @Index()
  late String notificationId; // UUID from Supabase

  @Index()
  late String userId; // Who receives the notification

  @Enumerated(EnumType.name)
  late NotificationType type;

  late String title;
  late String message;

  String? itemId; // Related item UUID
  String? relatedUserId; // Who triggered the notification

  @Index()
  late bool isRead;

  late DateTime createdAt;
  late DateTime updatedAt;

  @Enumerated(EnumType.name)
  late SyncStatus syncStatus;

  NotificationModel({
    this.id = Isar.autoIncrement,
    required this.notificationId,
    required this.userId,
    required this.type,
    required this.title,
    required this.message,
    this.itemId,
    this.relatedUserId,
    this.isRead = false,
    DateTime? createdAtParam,
    DateTime? updatedAtParam,
    this.syncStatus = SyncStatus.synced,
  })  : createdAt = createdAtParam ?? DateTime.now(),
        updatedAt = updatedAtParam ?? DateTime.now();
}

enum NotificationType {
  share,
  unshare,
  update,
  delete,
  comment,
  reminder,
  deadline,
}
