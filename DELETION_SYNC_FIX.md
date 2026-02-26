# Deletion Sync Fix for Shared Items

## Problem
When a note is deleted by one user:
- ✅ Note deleted for the owner
- ✅ Blocks (content) deleted for shared user  
- ❌ Note item itself NOT deleted for shared user
- ❌ No delete notification sent to shared user

## Root Cause
The database triggers were using incorrect notification types:
- Edit trigger was using 'edit' type (doesn't exist in NotificationType enum)
- Valid types are: 'share', 'unshare', 'update', 'comment'

## Solution
Created `fix_notification_types.sql` which:

1. **Fixed Edit Notifications**
   - Changed notification type from 'edit' to 'update'
   - Uses display_name from profiles table
   - Falls back to email username if display_name not available
   - Final fallback to "Someone"

2. **Fixed Delete Notifications**
   - Uses 'unshare' type (already correct)
   - Uses display_name from profiles table
   - Same fallback logic as edit notifications

3. **How It Works**
   - When item is deleted, BEFORE DELETE trigger fires
   - Trigger creates notifications for all shared users
   - Realtime service receives DELETE event
   - Calls `_deleteItemLocally()` which:
     - Deletes all blocks for the item
     - Deletes the item itself
   - Shared users receive notification and item is removed

## Files Modified
- `fix_notification_types.sql` - New file with corrected triggers

## Files Involved (No Changes Needed)
- `lib/data/realtime/realtime_service.dart` - Already handles DELETE events correctly
- `lib/data/models/notification_model.dart` - Defines valid notification types
- `enable_edit_delete_notifications.sql` - Original trigger (now superseded)

## Testing Steps
1. Run `fix_notification_types.sql` in Supabase SQL Editor
2. User A shares a note with User B
3. User A edits the note → User B should see "User A updated 'Note Title'" notification
4. User A deletes the note → User B should see "User A deleted 'Note Title'" notification
5. Verify note is removed from User B's list

## Technical Details

### Notification Type Mapping
```dart
enum NotificationType {
  share,    // When item is shared
  unshare,  // When item is unshared OR deleted
  update,   // When item is edited
  comment,  // For future comment feature
}
```

### Realtime Flow
```
DELETE in Supabase
  ↓
BEFORE DELETE trigger creates notifications
  ↓
Realtime service receives DELETE event
  ↓
_handleItemChange() detects DELETE
  ↓
_deleteItemLocally() removes item + blocks
  ↓
onDataChanged() callback refreshes UI
```

### Notification Flow
```
Trigger inserts into notifications table
  ↓
Realtime service receives INSERT on notifications
  ↓
_handleNotificationChange() saves locally
  ↓
onNewNotification() callback shows notification
```
