# Friends System - Implementation Tasks

**Feature**: Add Friend & Friend Management  
**Date**: February 26, 2026

---

## Phase 1: Database & Backend (Foundation)

### Task 1.1: Database Schema
- [ ] Create `friendships` table in Supabase
- [ ] Add indexes for performance
- [ ] Add RLS policies for friendships
- [ ] Add `assigned_to` column to items table
- [ ] Update items RLS policies for assignees
- [ ] Add new notification types (friend_request_sent, friend_request_accepted, task_assigned)
- [ ] Test schema in Supabase SQL Editor

**Files to create**:
- `setup_friendships_schema.sql`

**Estimated time**: 30 minutes

---

### Task 1.2: Friendship Model
- [ ] Create `FriendshipModel` class
- [ ] Add Isar annotations for local storage
- [ ] Add JSON serialization
- [ ] Generate Isar code
- [ ] Update `UserModel` with avatarUrl field

**Files to create/update**:
- `lib/data/models/friendship_model.dart`
- `lib/data/models/user_model.dart` (update)

**Estimated time**: 20 minutes

---

### Task 1.3: Friendship Repository
- [ ] Create `FriendshipRepository` class
- [ ] Implement local CRUD (Isar)
- [ ] Implement remote CRUD (Supabase)
- [ ] Implement sync logic
- [ ] Add error handling

**Files to create**:
- `lib/data/repositories/friendship_repository.dart`

**Estimated time**: 45 minutes

---

### Task 1.4: Friendship Service
- [ ] Create `FriendshipService` class
- [ ] Implement sendFriendRequest()
- [ ] Implement acceptFriendRequest()
- [ ] Implement rejectFriendRequest()
- [ ] Implement getFriends()
- [ ] Implement getPendingRequests()
- [ ] Implement getSentRequests()
- [ ] Implement removeFriend()
- [ ] Add notification triggers

**Files to create**:
- `lib/services/friendship_service.dart`

**Estimated time**: 1 hour

---

## Phase 2: UI - Friend Management

### Task 2.1: Friends Section in Sidebar
- [ ] Add "Friends" section in sidebar
- [ ] Show friends list with avatars and names
- [ ] Add "Add Friend" button
- [ ] Add badge for pending requests count
- [ ] Handle tap on friend (navigate to profile/chat)

**Files to update**:
- `lib/features/sidebar/presentation/app_sidebar.dart`

**Estimated time**: 30 minutes

---

### Task 2.2: Add Friend Dialog
- [ ] Create `AddFriendDialog` widget
- [ ] Add email input field
- [ ] Add "Send Request" button
- [ ] Show loading state
- [ ] Show success/error messages
- [ ] Validate email format
- [ ] Handle edge cases (self-request, already friends, etc.)

**Files to create**:
- `lib/features/friends/presentation/add_friend_dialog.dart`

**Estimated time**: 45 minutes

---

### Task 2.3: Friend Requests Screen
- [ ] Create `FriendRequestsScreen` widget
- [ ] Show pending requests (received)
- [ ] Show sent requests
- [ ] Add Accept/Reject buttons
- [ ] Show loading states
- [ ] Handle empty states
- [ ] Add pull-to-refresh

**Files to create**:
- `lib/features/friends/presentation/friend_requests_screen.dart`

**Estimated time**: 1 hour

---

### Task 2.4: Friendship Provider
- [ ] Create `FriendshipProvider` class
- [ ] Implement state management
- [ ] Load friends on init
- [ ] Handle real-time updates
- [ ] Add loading/error states

**Files to create**:
- `lib/features/friends/providers/friendship_provider.dart`

**Estimated time**: 30 minutes

---

## Phase 3: Share with Friends

### Task 3.1: Update Share Dialog
- [ ] Update `ShareDialog` to show friends
- [ ] Display friends as avatars with names
- [ ] Make avatars tappable
- [ ] Show selected state
- [ ] Keep email input as fallback
- [ ] Update share logic to use friend_id

**Files to update**:
- `lib/features/sharing/presentation/share_dialog.dart`

**Estimated time**: 45 minutes

---

### Task 3.2: Friend Avatar Component
- [ ] Create `FriendAvatar` widget
- [ ] Show profile picture or initials
- [ ] Add name label below
- [ ] Add selected state styling
- [ ] Handle tap events
- [ ] Add loading state

**Files to create**:
- `lib/core/widgets/friend_avatar.dart`

**Estimated time**: 30 minutes

---

## Phase 4: Assign Tasks

### Task 4.1: Assign Task Dialog
- [ ] Create `AssignTaskDialog` widget
- [ ] Show friends as avatars with names
- [ ] Make avatars tappable
- [ ] Show currently assigned user
- [ ] Add "Unassign" option
- [ ] Handle assignment logic

**Files to create**:
- `lib/features/task/presentation/assign_task_dialog.dart`

**Estimated time**: 45 minutes

---

### Task 4.2: Update Task Detail Screen
- [ ] Add "Assign" button in task detail
- [ ] Show assigned user avatar
- [ ] Handle tap on assignee (show profile)
- [ ] Update UI when assignment changes
- [ ] Add unassign option

**Files to update**:
- `lib/features/task/presentation/task_detail_screen.dart`

**Estimated time**: 30 minutes

---

### Task 4.3: Update Item Repository
- [ ] Add assignTask() method
- [ ] Add unassignTask() method
- [ ] Add getTasksAssignedToMe() method
- [ ] Add getTasksAssignedTo() method
- [ ] Update sync logic for assigned_to field

**Files to update**:
- `lib/data/repositories/item_repository.dart`

**Estimated time**: 30 minutes

---

### Task 4.4: Show Assignee in Task Cards
- [ ] Update task card widget
- [ ] Show assignee avatar in corner
- [ ] Add tooltip with assignee name
- [ ] Handle unassigned state

**Files to update**:
- `lib/features/dashboard/presentation/dashboard_screen.dart`
- `lib/features/tasks/presentation/tasks_screen.dart`
- `lib/features/upcoming/presentation/upcoming_screen.dart`

**Estimated time**: 30 minutes

---

## Phase 5: Notifications

### Task 5.1: Friend Request Notifications
- [ ] Create notification when friend request sent
- [ ] Create notification when friend request accepted
- [ ] Create notification when friend request rejected
- [ ] Add notification handlers
- [ ] Navigate to correct screen on tap

**Files to update**:
- `lib/data/repositories/friendship_repository.dart`
- `lib/features/alerts/presentation/alerts_screen.dart`

**Estimated time**: 30 minutes

---

### Task 5.2: Assignment Notifications
- [ ] Create notification when task assigned
- [ ] Create notification when task unassigned
- [ ] Add notification handlers
- [ ] Navigate to task detail on tap

**Files to update**:
- `lib/data/repositories/item_repository.dart`
- `lib/features/alerts/presentation/alerts_screen.dart`

**Estimated time**: 20 minutes

---

## Phase 6: Testing & Polish

### Task 6.1: Integration Testing
- [ ] Test send friend request
- [ ] Test accept/reject friend request
- [ ] Test share with friend
- [ ] Test assign task to friend
- [ ] Test offline sync
- [ ] Test real-time updates
- [ ] Test edge cases

**Estimated time**: 1 hour

---

### Task 6.2: UI Polish
- [ ] Add animations for friend requests
- [ ] Add haptic feedback
- [ ] Improve loading states
- [ ] Add empty states
- [ ] Add error states
- [ ] Improve accessibility

**Estimated time**: 45 minutes

---

### Task 6.3: Documentation
- [ ] Update README with friends feature
- [ ] Create user guide for adding friends
- [ ] Document API endpoints
- [ ] Add code comments

**Estimated time**: 30 minutes

---

## Summary

**Total Tasks**: 23  
**Estimated Total Time**: 12-14 hours  
**Phases**: 6

### Time Breakdown by Phase
- Phase 1 (Database & Backend): 3 hours
- Phase 2 (Friend Management UI): 3 hours
- Phase 3 (Share with Friends): 1.5 hours
- Phase 4 (Assign Tasks): 2.5 hours
- Phase 5 (Notifications): 1 hour
- Phase 6 (Testing & Polish): 2.5 hours

---

## Priority Order

1. **High Priority** (MVP):
   - Phase 1: Database & Backend
   - Phase 2: Friend Management UI
   - Phase 3: Share with Friends

2. **Medium Priority**:
   - Phase 4: Assign Tasks
   - Phase 5: Notifications

3. **Low Priority** (Polish):
   - Phase 6: Testing & Polish

---

**Status**: Ready to start Phase 1 ✅
