import 'package:isar/isar.dart';
import 'package:openlist/core/models/sync_status.dart';

part 'item_share_model.g.dart';

@collection
class ItemShareModel {
  Id id = Isar.autoIncrement;

  @Index()
  late String shareId; // UUID for syncing

  @Index()
  late String itemId;

  @Index()
  late String userId;

  @enumerated
  late SharePermission permission;

  String? sharedBy;
  DateTime? sharedAt;

  late DateTime createdAt;
  late DateTime updatedAt;

  @enumerated
  late SyncStatus syncStatus;

  // User details (cached from user profile)
  String? userName;
  String? userEmail;
  String? userAvatar;

  ItemShareModel({
    this.shareId = '',
    this.itemId = '',
    this.userId = '',
    this.permission = SharePermission.view,
    this.sharedBy,
    this.sharedAt,
    DateTime? createdAtParam,
    DateTime? updatedAtParam,
    this.syncStatus = SyncStatus.pending,
    this.userName,
    this.userEmail,
    this.userAvatar,
  })  : createdAt = createdAtParam ?? DateTime.now(),
        updatedAt = updatedAtParam ?? DateTime.now();
}

enum SharePermission {
  edit,
  view,
}
