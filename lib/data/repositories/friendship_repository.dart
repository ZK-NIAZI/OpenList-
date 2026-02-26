import 'package:isar/isar.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../local/isar_service.dart';
import '../models/friendship_model.dart';
import '../models/user_model.dart';

class FriendshipRepository {
  final IsarService _isarService;
  final SupabaseClient _supabase;

  FriendshipRepository({
    required IsarService isarService,
    required SupabaseClient supabase,
  })  : _isarService = isarService,
        _supabase = supabase;

  // ============================================================================
  // LOCAL (ISAR) OPERATIONS
  // ============================================================================

  /// Get all friendships from local database
  Future<List<FriendshipModel>> getFriendshipsLocal() async {
    final isar = await _isarService.db;
    return await isar.friendshipModels.where().findAll();
  }

  /// Get accepted friends from local database
  Future<List<FriendshipModel>> getAcceptedFriendsLocal() async {
    final isar = await _isarService.db;
    return await isar.friendshipModels
        .filter()
        .statusEqualTo('accepted')
        .findAll();
  }

  /// Get pending friend requests (received) from local database
  Future<List<FriendshipModel>> getPendingRequestsLocal(String userId) async {
    final isar = await _isarService.db;
    return await isar.friendshipModels
        .filter()
        .statusEqualTo('pending')
        .friendIdEqualTo(userId)
        .findAll();
  }

  /// Get sent friend requests from local database
  Future<List<FriendshipModel>> getSentRequestsLocal(String userId) async {
    final isar = await _isarService.db;
    return await isar.friendshipModels
        .filter()
        .statusEqualTo('pending')
        .userIdEqualTo(userId)
        .findAll();
  }

  /// Save friendship to local database
  Future<void> saveFriendshipLocal(FriendshipModel friendship) async {
    final isar = await _isarService.db;
    await isar.writeTxn(() async {
      await isar.friendshipModels.put(friendship);
    });
  }

  /// Save multiple friendships to local database
  Future<void> saveFriendshipsLocal(List<FriendshipModel> friendships) async {
    final isar = await _isarService.db;
    await isar.writeTxn(() async {
      await isar.friendshipModels.putAll(friendships);
    });
  }

  /// Delete friendship from local database
  Future<void> deleteFriendshipLocal(String friendshipId) async {
    final isar = await _isarService.db;
    final friendship = await isar.friendshipModels
        .filter()
        .idEqualTo(friendshipId)
        .findFirst();
    
    if (friendship != null) {
      await isar.writeTxn(() async {
        await isar.friendshipModels.delete(friendship.isarId);
      });
    }
  }

  // ============================================================================
  // REMOTE (SUPABASE) OPERATIONS
  // ============================================================================

  /// Get all friendships from Supabase
  Future<List<FriendshipModel>> getFriendshipsRemote() async {
    try {
      // Fetch friendships without join
      final response = await _supabase
          .from('friendships')
          .select('*')
          .order('created_at', ascending: false);

      final friendships = (response as List)
          .map((json) => FriendshipModel.fromJson(json))
          .toList();

      // Fetch friend details separately
      final friendIds = friendships
          .map((f) => f.friendId)
          .where((id) => id != null)
          .toSet()
          .toList();

      if (friendIds.isNotEmpty) {
        final users = await getUsersByIds(friendIds.cast<String>());
        final userMap = {for (var u in users) u.id: u};

        // Attach friend details
        for (var friendship in friendships) {
          if (friendship.friendId != null) {
            friendship.friend = userMap[friendship.friendId];
          }
        }
      }

      return friendships;
    } catch (e) {
      print('Error fetching friendships: $e');
      rethrow;
    }
  }

  /// Send friend request
  Future<FriendshipModel> sendFriendRequest(String friendEmail) async {
    try {
      final currentUserId = _supabase.auth.currentUser?.id;
      if (currentUserId == null) throw Exception('Not authenticated');

      // Find user by email
      final friendResponse = await _supabase
          .from('profiles')
          .select()
          .eq('email', friendEmail)
          .single();

      final friendId = friendResponse['id'] as String;

      // Check if friendship already exists
      final existingResponse = await _supabase
          .from('friendships')
          .select()
          .or('and(user_id.eq.$currentUserId,friend_id.eq.$friendId),and(user_id.eq.$friendId,friend_id.eq.$currentUserId)')
          .maybeSingle();

      if (existingResponse != null) {
        throw Exception('Friendship already exists');
      }

      // Create friendship request
      final response = await _supabase
          .from('friendships')
          .insert({
            'user_id': currentUserId,
            'friend_id': friendId,
            'status': 'pending',
            'requested_by': currentUserId,
          })
          .select('*')
          .single();

      final friendship = FriendshipModel.fromJson(response);
      
      // Fetch friend details separately
      final friendUser = await getUserById(friendId);
      friendship.friend = friendUser;
      
      // Save to local
      await saveFriendshipLocal(friendship);
      
      return friendship;
    } catch (e) {
      print('Error sending friend request: $e');
      rethrow;
    }
  }

  /// Accept friend request
  Future<FriendshipModel> acceptFriendRequest(String friendshipId) async {
    try {
      final response = await _supabase
          .from('friendships')
          .update({'status': 'accepted'})
          .eq('id', friendshipId)
          .select('*')
          .single();

      final friendship = FriendshipModel.fromJson(response);
      
      // Fetch friend details separately
      if (friendship.friendId != null) {
        final friendUser = await getUserById(friendship.friendId!);
        friendship.friend = friendUser;
      }
      
      // Update local
      await saveFriendshipLocal(friendship);
      
      return friendship;
    } catch (e) {
      print('Error accepting friend request: $e');
      rethrow;
    }
  }

  /// Reject friend request
  Future<void> rejectFriendRequest(String friendshipId) async {
    try {
      await _supabase
          .from('friendships')
          .update({'status': 'rejected'})
          .eq('id', friendshipId);

      // Delete from local
      await deleteFriendshipLocal(friendshipId);
    } catch (e) {
      print('Error rejecting friend request: $e');
      rethrow;
    }
  }

  /// Remove friend (delete friendship)
  Future<void> removeFriend(String friendshipId) async {
    try {
      await _supabase
          .from('friendships')
          .delete()
          .eq('id', friendshipId);

      // Delete from local
      await deleteFriendshipLocal(friendshipId);
    } catch (e) {
      print('Error removing friend: $e');
      rethrow;
    }
  }

  /// Block friend
  Future<void> blockFriend(String friendshipId) async {
    try {
      await _supabase
          .from('friendships')
          .update({'status': 'blocked'})
          .eq('id', friendshipId);

      // Update local
      final friendship = await _supabase
          .from('friendships')
          .select('*')
          .eq('id', friendshipId)
          .single();

      final friendshipModel = FriendshipModel.fromJson(friendship);
      
      // Fetch friend details separately
      if (friendshipModel.friendId != null) {
        final friendUser = await getUserById(friendshipModel.friendId!);
        friendshipModel.friend = friendUser;
      }

      await saveFriendshipLocal(friendshipModel);
    } catch (e) {
      print('Error blocking friend: $e');
      rethrow;
    }
  }

  // ============================================================================
  // SYNC OPERATIONS
  // ============================================================================

  /// Sync friendships from remote to local
  Future<void> syncFriendships() async {
    try {
      final remoteFriendships = await getFriendshipsRemote();
      await saveFriendshipsLocal(remoteFriendships);
    } catch (e) {
      print('Error syncing friendships: $e');
      rethrow;
    }
  }

  /// Get user by email (for friend search)
  Future<UserModel?> getUserByEmail(String email) async {
    try {
      final response = await _supabase
          .from('profiles')
          .select()
          .eq('email', email)
          .maybeSingle();

      if (response == null) return null;
      
      return UserModel.fromJson(response);
    } catch (e) {
      print('Error getting user by email: $e');
      return null;
    }
  }

  /// Get user by ID
  Future<UserModel?> getUserById(String userId) async {
    try {
      final response = await _supabase
          .from('profiles')
          .select()
          .eq('id', userId)
          .maybeSingle();

      if (response == null) return null;
      
      return UserModel.fromJson(response);
    } catch (e) {
      print('Error getting user by ID: $e');
      return null;
    }
  }

  /// Get multiple users by IDs (for populating friend data)
  Future<List<UserModel>> getUsersByIds(List<String> userIds) async {
    try {
      if (userIds.isEmpty) return [];

      final response = await _supabase
          .from('profiles')
          .select()
          .inFilter('id', userIds);

      return (response as List)
          .map((json) => UserModel.fromJson(json))
          .toList();
    } catch (e) {
      print('Error getting users by IDs: $e');
      return [];
    }
  }
}
