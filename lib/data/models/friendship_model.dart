import 'package:isar/isar.dart';
import 'user_model.dart';

part 'friendship_model.g.dart';

@collection
class FriendshipModel {
  Id get isarId => fastHash(id);

  @Index()
  final String id;

  @Index()
  final String userId;

  @Index()
  final String friendId;

  @Index()
  final String status; // pending, accepted, rejected, blocked

  final String requestedBy;

  final DateTime createdAt;
  final DateTime updatedAt;

  // Populated field (not stored in Isar, loaded separately)
  @ignore
  UserModel? friend;

  FriendshipModel({
    required this.id,
    required this.userId,
    required this.friendId,
    required this.status,
    required this.requestedBy,
    required this.createdAt,
    required this.updatedAt,
    this.friend,
  });

  // JSON serialization
  factory FriendshipModel.fromJson(Map<String, dynamic> json) {
    return FriendshipModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      friendId: json['friend_id'] as String,
      status: json['status'] as String,
      requestedBy: json['requested_by'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      friend: json['friend'] != null 
          ? UserModel.fromJson(json['friend'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'friend_id': friendId,
      'status': status,
      'requested_by': requestedBy,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  // Copy with
  FriendshipModel copyWith({
    String? id,
    String? userId,
    String? friendId,
    String? status,
    String? requestedBy,
    DateTime? createdAt,
    DateTime? updatedAt,
    UserModel? friend,
  }) {
    return FriendshipModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      friendId: friendId ?? this.friendId,
      status: status ?? this.status,
      requestedBy: requestedBy ?? this.requestedBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      friend: friend ?? this.friend,
    );
  }

  // Helper methods
  bool get isPending => status == 'pending';
  bool get isAccepted => status == 'accepted';
  bool get isRejected => status == 'rejected';
  bool get isBlocked => status == 'blocked';

  bool isSentByMe(String currentUserId) => requestedBy == currentUserId;
  bool isReceivedByMe(String currentUserId) => 
      requestedBy != currentUserId && friendId == currentUserId;
}

// Fast hash function for Isar ID
int fastHash(String string) {
  var hash = 0xcbf29ce484222325;
  var i = 0;
  while (i < string.length) {
    final codeUnit = string.codeUnitAt(i++);
    hash ^= codeUnit >> 8;
    hash *= 0x100000001b3;
    hash ^= codeUnit & 0xFF;
    hash *= 0x100000001b3;
  }
  return hash;
}
