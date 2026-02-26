import 'package:openlist/data/local/isar_service.dart';
import 'package:openlist/data/models/item_share_model.dart';
import 'package:openlist/data/models/space_member_model.dart';
import 'package:openlist/core/models/sync_status.dart';
import 'package:openlist/data/repositories/item_repository.dart';
import 'package:uuid/uuid.dart';

class SharingRepository {
  final IsarService _isarService = IsarService.instance;
  final _uuid = const Uuid();

  // ==================== Space Members ====================

  /// Get all members of a space
  Future<List<SpaceMemberModel>> getSpaceMembers(String spaceId) async {
    final isar = await _isarService.db;
    final count = await isar.spaceMemberModels.count();
    final allMembers = <SpaceMemberModel>[];
    
    for (int i = 0; i < count; i++) {
      final member = await isar.spaceMemberModels.get(i + 1);
      if (member != null && member.spaceId == spaceId) {
        allMembers.add(member);
      }
    }
    
    return allMembers;
  }

  /// Watch space members
  Stream<List<SpaceMemberModel>> watchSpaceMembers(String spaceId) async* {
    final isar = await _isarService.db;
    await for (final _ in isar.spaceMemberModels.watchLazy()) {
      yield await getSpaceMembers(spaceId);
    }
  }

  /// Add member to space
  Future<SpaceMemberModel> addSpaceMember({
    required String spaceId,
    required String userId,
    required MemberRole role,
    String? invitedBy,
    String? userName,
    String? userEmail,
  }) async {
    final isar = await _isarService.db;
    final member = SpaceMemberModel(
      memberId: _uuid.v4(),
      spaceId: spaceId,
      userId: userId,
      role: role,
      invitedBy: invitedBy,
      invitedAt: DateTime.now(),
      syncStatus: SyncStatus.pending,
      userName: userName,
      userEmail: userEmail,
    );

    await isar.writeTxn(() async {
      await isar.spaceMemberModels.put(member);
    });

    return member;
  }

  /// Update member role
  Future<void> updateMemberRole(int memberId, MemberRole newRole) async {
    final isar = await _isarService.db;
    await isar.writeTxn(() async {
      final member = await isar.spaceMemberModels.get(memberId);
      if (member != null) {
        member.role = newRole;
        member.updatedAt = DateTime.now();
        member.syncStatus = SyncStatus.pending;
        await isar.spaceMemberModels.put(member);
      }
    });
  }

  /// Remove member from space
  Future<void> removeSpaceMember(int memberId) async {
    final isar = await _isarService.db;
    await isar.writeTxn(() async {
      await isar.spaceMemberModels.delete(memberId);
    });
  }

  /// Check if user is member of space
  Future<bool> isSpaceMember(String spaceId, String userId) async {
    final members = await getSpaceMembers(spaceId);
    return members.any((m) => m.userId == userId);
  }

  /// Get user's role in space
  Future<MemberRole?> getUserRoleInSpace(String spaceId, String userId) async {
    final members = await getSpaceMembers(spaceId);
    final member = members.where((m) => m.userId == userId).firstOrNull;
    return member?.role;
  }

  // ==================== Item Shares ====================

  /// Get all shares for an item
  Future<List<ItemShareModel>> getItemShares(String itemId) async {
    final isar = await _isarService.db;
    final count = await isar.itemShareModels.count();
    final allShares = <ItemShareModel>[];
    
    for (int i = 0; i < count; i++) {
      final share = await isar.itemShareModels.get(i + 1);
      if (share != null && share.itemId == itemId) {
        allShares.add(share);
      }
    }
    
    return allShares;
  }

  /// Watch item shares
  Stream<List<ItemShareModel>> watchItemShares(String itemId) async* {
    final isar = await _isarService.db;
    await for (final _ in isar.itemShareModels.watchLazy()) {
      yield await getItemShares(itemId);
    }
  }

  /// Share item with user
  Future<ItemShareModel> shareItem({
    required String itemId,
    required String userId,
    required SharePermission permission,
    String? sharedBy,
    String? userName,
    String? userEmail,
  }) async {
    final isar = await _isarService.db;
    final share = ItemShareModel(
      shareId: _uuid.v4(),
      itemId: itemId,
      userId: userId,
      permission: permission,
      sharedBy: sharedBy,
      sharedAt: DateTime.now(),
      syncStatus: SyncStatus.pending,
      userName: userName,
      userEmail: userEmail,
    );

    await isar.writeTxn(() async {
      await isar.itemShareModels.put(share);
    });
    
    // Clear share status cache so filtering updates immediately
    ItemRepository().clearShareCache();

    return share;
  }

  /// Update share permission
  Future<void> updateSharePermission(int shareId, SharePermission newPermission) async {
    final isar = await _isarService.db;
    await isar.writeTxn(() async {
      final share = await isar.itemShareModels.get(shareId);
      if (share != null) {
        share.permission = newPermission;
        share.updatedAt = DateTime.now();
        share.syncStatus = SyncStatus.pending;
        await isar.itemShareModels.put(share);
      }
    });
  }

  /// Remove item share
  Future<void> removeItemShare(int shareId) async {
    final isar = await _isarService.db;
    await isar.writeTxn(() async {
      await isar.itemShareModels.delete(shareId);
    });
    
    // Clear share status cache so filtering updates immediately
    ItemRepository().clearShareCache();
  }

  /// Check if item is shared with user
  Future<bool> isItemSharedWithUser(String itemId, String userId) async {
    final shares = await getItemShares(itemId);
    return shares.any((s) => s.userId == userId);
  }

  /// Get user's permission for item
  Future<SharePermission?> getUserPermissionForItem(String itemId, String userId) async {
    final shares = await getItemShares(itemId);
    final share = shares.where((s) => s.userId == userId).firstOrNull;
    return share?.permission;
  }

  /// Get all items shared with user
  Future<List<ItemShareModel>> getItemsSharedWithUser(String userId) async {
    final isar = await _isarService.db;
    final count = await isar.itemShareModels.count();
    final userShares = <ItemShareModel>[];
    
    for (int i = 0; i < count; i++) {
      final share = await isar.itemShareModels.get(i + 1);
      if (share != null && share.userId == userId) {
        userShares.add(share);
      }
    }
    
    return userShares;
  }

  /// Get all spaces user is member of
  Future<List<SpaceMemberModel>> getUserSpaceMemberships(String userId) async {
    final isar = await _isarService.db;
    final count = await isar.spaceMemberModels.count();
    final userMemberships = <SpaceMemberModel>[];
    
    for (int i = 0; i < count; i++) {
      final member = await isar.spaceMemberModels.get(i + 1);
      if (member != null && member.userId == userId) {
        userMemberships.add(member);
      }
    }
    
    return userMemberships;
  }
}
