import '../data/models/friendship_model.dart';
import '../data/models/user_model.dart';
import '../data/repositories/friendship_repository.dart';

class FriendshipService {
  final FriendshipRepository _repository;

  FriendshipService({required FriendshipRepository repository})
      : _repository = repository;

  // ============================================================================
  // FRIEND MANAGEMENT
  // ============================================================================

  /// Send friend request by email
  Future<FriendshipModel> sendFriendRequest(String friendEmail) async {
    // Validate email
    if (friendEmail.isEmpty || !friendEmail.contains('@')) {
      throw Exception('Invalid email address');
    }

    // Check if user exists
    final user = await _repository.getUserByEmail(friendEmail);
    if (user == null) {
      throw Exception('User with this email not found');
    }

    // Send request
    return await _repository.sendFriendRequest(friendEmail);
  }

  /// Accept friend request
  Future<FriendshipModel> acceptFriendRequest(String friendshipId) async {
    return await _repository.acceptFriendRequest(friendshipId);
  }

  /// Reject friend request
  Future<void> rejectFriendRequest(String friendshipId) async {
    await _repository.rejectFriendRequest(friendshipId);
  }

  /// Remove friend
  Future<void> removeFriend(String friendshipId) async {
    await _repository.removeFriend(friendshipId);
  }

  /// Block friend
  Future<void> blockFriend(String friendshipId) async {
    await _repository.blockFriend(friendshipId);
  }

  // ============================================================================
  // FRIEND LISTS
  // ============================================================================

  /// Get all accepted friends
  Future<List<FriendshipModel>> getFriends() async {
    try {
      // Try to get from remote first
      final friendships = await _repository.getFriendshipsRemote();
      final accepted = friendships.where((f) => f.status == 'accepted').toList();
      
      // Save to local
      await _repository.saveFriendshipsLocal(accepted);
      
      return accepted;
    } catch (e) {
      // Fallback to local if offline
      print('Error fetching friends, using local: $e');
      return await _repository.getAcceptedFriendsLocal();
    }
  }

  /// Get pending friend requests (received)
  Future<List<FriendshipModel>> getPendingRequests(String userId) async {
    try {
      // Try to get from remote first
      final friendships = await _repository.getFriendshipsRemote();
      final pending = friendships
          .where((f) => 
              f.status == 'pending' && 
              f.friendId == userId &&
              f.requestedBy != userId)
          .toList();
      
      return pending;
    } catch (e) {
      // Fallback to local if offline
      print('Error fetching pending requests, using local: $e');
      return await _repository.getPendingRequestsLocal(userId);
    }
  }

  /// Get sent friend requests
  Future<List<FriendshipModel>> getSentRequests(String userId) async {
    try {
      // Try to get from remote first
      final friendships = await _repository.getFriendshipsRemote();
      final sent = friendships
          .where((f) => 
              f.status == 'pending' && 
              f.userId == userId &&
              f.requestedBy == userId)
          .toList();
      
      return sent;
    } catch (e) {
      // Fallback to local if offline
      print('Error fetching sent requests, using local: $e');
      return await _repository.getSentRequestsLocal(userId);
    }
  }

  /// Get blocked friends
  Future<List<FriendshipModel>> getBlockedFriends() async {
    try {
      final friendships = await _repository.getFriendshipsRemote();
      return friendships.where((f) => f.status == 'blocked').toList();
    } catch (e) {
      print('Error fetching blocked friends: $e');
      return [];
    }
  }

  // ============================================================================
  // SYNC
  // ============================================================================

  /// Sync all friendships
  Future<void> syncFriendships() async {
    await _repository.syncFriendships();
  }

  // ============================================================================
  // SEARCH
  // ============================================================================

  /// Search user by email
  Future<UserModel?> searchUserByEmail(String email) async {
    return await _repository.getUserByEmail(email);
  }

  /// Get friend details (populate UserModel)
  Future<List<FriendshipModel>> getFriendsWithDetails() async {
    final friendships = await getFriends();
    
    // Get all friend IDs
    final friendIds = friendships.map((f) => f.friendId).toList();
    
    // Fetch user details
    final users = await _repository.getUsersByIds(friendIds);
    
    // Create map for quick lookup
    final userMap = {for (var user in users) user.userId: user};
    
    // Populate friend data
    return friendships.map((friendship) {
      return friendship.copyWith(
        friend: userMap[friendship.friendId],
      );
    }).toList();
  }

  /// Get pending requests with details
  Future<List<FriendshipModel>> getPendingRequestsWithDetails(String userId) async {
    final requests = await getPendingRequests(userId);
    
    // Get all requester IDs
    final requesterIds = requests.map((r) => r.userId).toList();
    
    // Fetch user details
    final users = await _repository.getUsersByIds(requesterIds);
    
    // Create map for quick lookup
    final userMap = {for (var user in users) user.userId: user};
    
    // Populate friend data
    return requests.map((request) {
      return request.copyWith(
        friend: userMap[request.userId],
      );
    }).toList();
  }
}
