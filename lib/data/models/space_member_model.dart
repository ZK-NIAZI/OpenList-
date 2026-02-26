import 'package:isar/isar.dart';
import 'package:openlist/core/models/sync_status.dart';

part 'space_member_model.g.dart';

@collection
class SpaceMemberModel {
  Id id = Isar.autoIncrement;

  @Index()
  late String memberId; // UUID for syncing

  @Index()
  late String spaceId;

  @Index()
  late String userId;

  @enumerated
  late MemberRole role;

  String? invitedBy;
  DateTime? invitedAt;
  DateTime? acceptedAt;

  late DateTime createdAt;
  late DateTime updatedAt;

  @enumerated
  late SyncStatus syncStatus;

  // User details (cached from user profile)
  String? userName;
  String? userEmail;
  String? userAvatar;

  SpaceMemberModel({
    this.memberId = '',
    this.spaceId = '',
    this.userId = '',
    this.role = MemberRole.viewer,
    this.invitedBy,
    this.invitedAt,
    this.acceptedAt,
    DateTime? createdAtParam,
    DateTime? updatedAtParam,
    this.syncStatus = SyncStatus.pending,
    this.userName,
    this.userEmail,
    this.userAvatar,
  })  : createdAt = createdAtParam ?? DateTime.now(),
        updatedAt = updatedAtParam ?? DateTime.now();
}

enum MemberRole {
  owner,
  editor,
  viewer,
}
