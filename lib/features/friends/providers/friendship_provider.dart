import 'package:flutter/foundation.dart';
import '../../../data/models/friendship_model.dart';
import '../../../services/friendship_service.dart';

class FriendshipProvider extends ChangeNotifier {
  final FriendshipService _friendshipService;

  FriendshipProvider({required FriendshipService friendshipService})
      : _friendshipService = friendshipService;

  // State
  List<FriendshipModel> _friends = [];
  List<FriendshipModel> _pendingRequests = [];
  List<FriendshipModel> _sentRequests = [];
  bool _isLoading = false;
  String? _error;

  // Getters
  List<FriendshipModel> get friends => _friends;
  List<FriendshipModel> get pendingRequests => _pendingRequests;
  List<FriendshipModel> get sentRequests => _sentRequests;
  bool get isLoading => _isLoading;
  String? get error => _error;
  int get pendingRequestsCount => _pendingRequests.length;

  // ============================================================================
  // LOAD DATA
  // ============================================================================

  /// Load all friendship data
  Future<void> loadFriendships(String userId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Load friends with details
      _friends = await _friendshipService.getFriendsWithDetails();
      
      // Load pending requests with details
      _pendingRequests = await _friendshipService.getPendingRequestsWithDetails(userId);
      
      // Load sent requests
      _sentRequests = await _friendshipService.getSentRequests(userId);

      _error = null;
    } catch (e) {
      _error = e.toString();
      print('Error loading friendships: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Refresh friendships
  Future<void> refresh(String userId) async {
    await loadFriendships(userId);
  }

  // ============================================================================
  // FRIEND ACTIONS
  // ============================================================================

  /// Send friend request
  Future<bool> sendFriendRequest(String friendEmail) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final friendship = await _friendshipService.sendFriendRequest(friendEmail);
      _sentRequests.add(friendship);
      _error = null;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Accept friend request
  Future<bool> acceptFriendRequest(String friendshipId) async {
    try {
      final friendship = await _friendshipService.acceptFriendRequest(friendshipId);
      
      // Remove from pending requests
      _pendingRequests.removeWhere((f) => f.id == friendshipId);
      
      // Add to friends
      _friends.add(friendship);
      
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Reject friend request
  Future<bool> rejectFriendRequest(String friendshipId) async {
    try {
      await _friendshipService.rejectFriendRequest(friendshipId);
      
      // Remove from pending requests
      _pendingRequests.removeWhere((f) => f.id == friendshipId);
      
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Remove friend
  Future<bool> removeFriend(String friendshipId) async {
    try {
      await _friendshipService.removeFriend(friendshipId);
      
      // Remove from friends
      _friends.removeWhere((f) => f.id == friendshipId);
      
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Block friend
  Future<bool> blockFriend(String friendshipId) async {
    try {
      await _friendshipService.blockFriend(friendshipId);
      
      // Remove from friends
      _friends.removeWhere((f) => f.id == friendshipId);
      
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // ============================================================================
  // HELPERS
  // ============================================================================

  /// Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  /// Check if user is already a friend
  bool isFriend(String userId) {
    return _friends.any((f) => f.friendId == userId || f.userId == userId);
  }

  /// Check if friend request already sent
  bool isRequestSent(String userId) {
    return _sentRequests.any((f) => f.friendId == userId);
  }

  /// Check if friend request received
  bool isRequestReceived(String userId) {
    return _pendingRequests.any((f) => f.userId == userId);
  }
}
