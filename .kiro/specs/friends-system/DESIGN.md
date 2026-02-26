# Friends System Design

**Feature**: Add Friend & Friend Management  
**Date**: February 26, 2026  
**Status**: Design Phase

---

## Overview

Replace email-based sharing/assignment with a friend system where users can:
- Send friend requests via email
- Accept/reject requests
- See friends with profile pictures and names
- Share/assign tasks by tapping friend avatars

---

## User Flow

### 1. Add Friend
```
Sidebar → "Add Friend" button → Enter email → Send request
→ Notification sent to friend
→ Pending request shows in "Friends" section
```

### 2. Accept Friend Request
```
Receive notification → Tap notification → See request details
→ Accept/Reject buttons
→ If accepted: Friend added to both users' friend lists
→ Notification sent to requester
```

### 3. Share with Friend
```
Task detail → Share button → Friend list appears (avatars + names)
→ Tap friend avatar → Select permission (view/edit)
→ Share → Friend receives notification
```

### 4. Assign to Friend
```
Task detail → Assign button → Friend list appears (avatars + names)
→ Tap friend avatar → Assigned
→ Friend receives notification
```

---

## Database Schema

### New Table: `friendships`

```sql
CREATE TABLE friendships (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  friend_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  status TEXT NOT NULL CHECK (status IN ('pending', 'accepted', 'rejected', 'blocked')),
  requested_by UUID NOT NULL REFERENCES auth.users(id),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(user_id, friend_id)
);

-- Indexes
CREATE INDEX idx_friendships_user_id ON friendships(user_id);
CREATE INDEX idx_friendships_friend_id ON friendships(friend_id);
CREATE INDEX idx_friendships_status ON friendships(status);
```

### Update `items` table for assignees

```sql
-- Add assignee column to items
ALTER TABLE items ADD COLUMN assigned_to UUID REFERENCES auth.users(id);
CREATE INDEX idx_items_assigned_to ON items(assigned_to);
```

### Update `notifications` table

```sql
-- Add new notification types
-- 'friend_request_sent'
-- 'friend_request_accepted'
-- 'friend_request_rejected'
-- 'task_assigned'
```

---

## UI Components

### 1. Sidebar - Friends Section

```
┌─────────────────────────┐
│ Inbox                   │
│ Today                   │
│ Upcoming                │
│ Notes                   │
│ Tasks                   │
├─────────────────────────┤
│ Friends                 │ ← New section
│  ○ John Doe             │
│  ○ Jane Smith           │
│  ○ Mike Johnson         │
│  + Add Friend           │ ← Button
├─────────────────────────┤
│ Settings                │
└─────────────────────────┘
```

### 2. Add Friend Dialog

```
┌─────────────────────────────────┐
│  Add Friend                  ✕  │
├─────────────────────────────────┤
│                                 │
│  Enter friend's email:          │
│  ┌───────────────────────────┐ │
│  │ friend@example.com        │ │
│  └───────────────────────────┘ │
│                                 │
│  ┌─────────────────────────┐   │
│  │   Send Friend Request   │   │
│  └─────────────────────────┘   │
│                                 │
└─────────────────────────────────┘
```

### 3. Friend Requests Screen

```
┌─────────────────────────────────┐
│  Friend Requests             ✕  │
├─────────────────────────────────┤
│                                 │
│  Pending Requests (2)           │
│  ┌───────────────────────────┐ │
│  │ ○ John Doe                │ │
│  │   john@example.com        │ │
│  │   [Accept] [Reject]       │ │
│  └───────────────────────────┘ │
│  ┌───────────────────────────┐ │
│  │ ○ Jane Smith              │ │
│  │   jane@example.com        │ │
│  │   [Accept] [Reject]       │ │
│  └───────────────────────────┘ │
│                                 │
│  Sent Requests (1)              │
│  ┌───────────────────────────┐ │
│  │ ○ Mike Johnson            │ │
│  │   mike@example.com        │ │
│  │   Pending...              │ │
│  └───────────────────────────┘ │
│                                 │
└─────────────────────────────────┘
```

### 4. Share with Friends (Updated)

```
┌─────────────────────────────────┐
│  Share Task                  ✕  │
├─────────────────────────────────┤
│                                 │
│  Select Friend:                 │
│                                 │
│  ┌─────┐  ┌─────┐  ┌─────┐    │
│  │ ○   │  │ ○   │  │ ○   │    │
│  │John │  │Jane │  │Mike │    │
│  └─────┘  └─────┘  └─────┘    │
│                                 │
│  Permission:                    │
│  ○ View only                    │
│  ○ Can edit                     │
│                                 │
│  ┌─────────────────────────┐   │
│  │        Share Task       │   │
│  └─────────────────────────┘   │
│                                 │
└─────────────────────────────────┘
```

### 5. Assign Task (New)

```
┌─────────────────────────────────┐
│  Assign Task                 ✕  │
├─────────────────────────────────┤
│                                 │
│  Select Friend:                 │
│                                 │
│  ┌─────┐  ┌─────┐  ┌─────┐    │
│  │ ○   │  │ ○   │  │ ○   │    │
│  │John │  │Jane │  │Mike │    │
│  └─────┘  └─────┘  └─────┘    │
│                                 │
│  ┌─────────────────────────┐   │
│  │      Assign Task        │   │
│  └─────────────────────────┘   │
│                                 │
└─────────────────────────────────┘
```

---

## Features

### Phase 1: Friend Management
- ✅ Add friend by email
- ✅ Send friend request
- ✅ Accept/reject friend requests
- ✅ View friends list in sidebar
- ✅ Friend request notifications
- ✅ Friend acceptance notifications

### Phase 2: Share with Friends
- ✅ Update share dialog to show friends (avatars + names)
- ✅ Tap avatar to select friend
- ✅ Share with selected friend
- ✅ Show shared items with friend avatars

### Phase 3: Assign Tasks
- ✅ Add "Assign" button in task detail
- ✅ Show friend picker (avatars + names)
- ✅ Assign task to friend
- ✅ Show assignee avatar in task card
- ✅ Filter tasks by assignee
- ✅ Assignment notifications

---

## Technical Implementation

### Models

#### FriendshipModel
```dart
class FriendshipModel {
  final String id;
  final String userId;
  final String friendId;
  final String status; // pending, accepted, rejected, blocked
  final String requestedBy;
  final DateTime createdAt;
  final DateTime updatedAt;
  
  // Populated fields
  final UserModel? friend; // Friend's profile
}
```

#### UserModel (Update)
```dart
class UserModel {
  final String id;
  final String email;
  final String? displayName;
  final String? avatarUrl; // Profile picture
  final DateTime createdAt;
}
```

### Services

#### FriendshipService
```dart
class FriendshipService {
  // Send friend request
  Future<void> sendFriendRequest(String friendEmail);
  
  // Accept friend request
  Future<void> acceptFriendRequest(String friendshipId);
  
  // Reject friend request
  Future<void> rejectFriendRequest(String friendshipId);
  
  // Get friends list
  Future<List<FriendshipModel>> getFriends();
  
  // Get pending requests (received)
  Future<List<FriendshipModel>> getPendingRequests();
  
  // Get sent requests
  Future<List<FriendshipModel>> getSentRequests();
  
  // Remove friend
  Future<void> removeFriend(String friendshipId);
  
  // Block friend
  Future<void> blockFriend(String friendshipId);
}
```

#### ItemRepository (Update)
```dart
// Add assignee methods
Future<void> assignTask(String itemId, String userId);
Future<void> unassignTask(String itemId);
Future<List<ItemModel>> getTasksAssignedToMe();
Future<List<ItemModel>> getTasksAssignedTo(String userId);
```

### Repositories

#### FriendshipRepository
```dart
class FriendshipRepository {
  // Local (Isar)
  Future<void> saveFriendshipLocal(FriendshipModel friendship);
  Future<List<FriendshipModel>> getFriendshipsLocal();
  
  // Remote (Supabase)
  Future<void> saveFriendshipRemote(FriendshipModel friendship);
  Future<List<FriendshipModel>> getFriendshipsRemote();
  
  // Sync
  Future<void> syncFriendships();
}
```

### Providers

#### FriendshipProvider
```dart
class FriendshipProvider extends ChangeNotifier {
  List<FriendshipModel> friends = [];
  List<FriendshipModel> pendingRequests = [];
  List<FriendshipModel> sentRequests = [];
  
  Future<void> loadFriends();
  Future<void> sendRequest(String email);
  Future<void> acceptRequest(String friendshipId);
  Future<void> rejectRequest(String friendshipId);
}
```

---

## RLS Policies

### Friendships Table

```sql
-- Users can view their own friendships
CREATE POLICY "Users can view their friendships"
  ON friendships FOR SELECT
  USING (auth.uid() = user_id OR auth.uid() = friend_id);

-- Users can create friendships (send requests)
CREATE POLICY "Users can send friend requests"
  ON friendships FOR INSERT
  WITH CHECK (auth.uid() = user_id AND auth.uid() = requested_by);

-- Users can update friendships (accept/reject)
CREATE POLICY "Users can update their friendships"
  ON friendships FOR UPDATE
  USING (auth.uid() = user_id OR auth.uid() = friend_id);

-- Users can delete their friendships
CREATE POLICY "Users can delete their friendships"
  ON friendships FOR DELETE
  USING (auth.uid() = user_id OR auth.uid() = friend_id);
```

### Items Table (Update for assignees)

```sql
-- Users can view tasks assigned to them
CREATE POLICY "Users can view assigned tasks"
  ON items FOR SELECT
  USING (
    auth.uid() = created_by 
    OR auth.uid() = assigned_to
    OR EXISTS (
      SELECT 1 FROM item_shares
      WHERE item_shares.item_id = items.id
      AND item_shares.shared_with_user_id = auth.uid()
    )
  );
```

---

## Notifications

### New Notification Types

1. **friend_request_sent**
   - Title: "Friend Request"
   - Message: "{sender_name} sent you a friend request"
   - Action: Open friend requests screen

2. **friend_request_accepted**
   - Title: "Friend Request Accepted"
   - Message: "{friend_name} accepted your friend request"
   - Action: Open friends list

3. **task_assigned**
   - Title: "Task Assigned"
   - Message: "{assigner_name} assigned you a task: {task_title}"
   - Action: Open task detail

---

## Edge Cases

1. **User not found**: Show error "User with this email not found"
2. **Already friends**: Show "You are already friends with this user"
3. **Pending request exists**: Show "Friend request already sent"
4. **Self-request**: Prevent sending request to own email
5. **Blocked user**: Cannot send request to blocked user
6. **Deleted user**: Handle gracefully, show "User no longer available"

---

## Testing Checklist

- [ ] Send friend request by email
- [ ] Receive friend request notification
- [ ] Accept friend request
- [ ] Reject friend request
- [ ] View friends list in sidebar
- [ ] Share task with friend (tap avatar)
- [ ] Assign task to friend (tap avatar)
- [ ] View assigned tasks
- [ ] Remove friend
- [ ] Block friend
- [ ] Offline friend request (sync when online)
- [ ] Real-time friend request updates

---

## Success Metrics

- Users can add friends without typing emails repeatedly
- Sharing is visual (avatars) instead of text (emails)
- Assignment is intuitive (tap avatar)
- Friend requests work offline and sync
- Notifications work for all friend actions

---

## Next Steps

1. Create database schema (friendships table)
2. Create models (FriendshipModel)
3. Create services (FriendshipService)
4. Create repositories (FriendshipRepository)
5. Create providers (FriendshipProvider)
6. Create UI (Add Friend dialog, Friend requests screen)
7. Update Share dialog (show friends with avatars)
8. Create Assign dialog (show friends with avatars)
9. Add notifications
10. Test everything

---

**Status**: Ready for implementation ✅
