# Current Issues Summary

## Issue 1: Delete Notifications Not Being Created
**Status**: ⚠️ SQL fix ready - USER MUST RUN IT

**Problem**: When deleting a shared item, no notification is sent to other users.

**Root Cause**: Delete notification trigger not properly configured in database.

**Solution**: 
1. Open Supabase SQL Editor
2. Run `fix_all_current_issues.sql` (fixes both edit and delete notifications)
3. OR run `setup_delete_notifications.sql` (delete notifications only)
4. Verify with `verify_delete_notifications.sql`

**What the SQL does**:
- Creates delete notification trigger function
- Sets up BEFORE DELETE trigger on items table
- Adds RLS policies to allow deletion
- Uses 'unshare' notification type (matches NotificationType enum)
- Gets deleter name from profiles.display_name with fallbacks
- Notifies all shared users and owner (except deleter)

**Evidence from logs**:
```
✅ Item deleted from Supabase
📥 Fetched 0 notifications  ← No delete notification created
```

---

## Issue 2: Duplicate Items Being Created (Untitled Note appearing twice)
**Status**: FIXED ✅

**Problem**: Same item was being created twice during sync, appearing as duplicate in pinned notes.

**Root Cause**: When combining owned items and shared items, the same item could appear in both lists if the user both owns it AND has it shared with them. The code was not deduplicating before saving.

**Solution Applied**:
1. Added deduplication logic using a Map to ensure each item ID only appears once
2. Updated existingItemsMap after each save to prevent duplicates even if deduplication fails
3. Added debug logging to show unique item count after deduplication

**Changes Made**: `lib/data/sync/sync_manager.dart` - `_pullFromSupabase` method

---

## Issue 3: Notification Timestamp Display
**Status**: FIXED ✅

**Solution**: Custom time formatter added that shows:
- "just now" for < 1 minute
- "X mins ago" for < 1 hour
- "X hrs ago" for < 24 hours
- "X days ago" for < 7 days
- "DD/MM/YYYY HH:MM" for older

Timer refreshes every minute while on alerts screen.

---

## Issue 4: Isar Query Compilation Error in Alerts Screen
**Status**: FIXED ✅

**Problem**: Compilation error "The method 'findAll' isn't defined for the type 'QueryBuilder<NotificationModel, NotificationModel, QWhere>'"

**Root Cause**: Incorrect Isar query syntax - cannot use `.where().findAll()` without proper query chain.

**Solution Applied**: Changed to iterate through all notifications using `.count()` and `.get()` pattern, then sort manually.

**Changes Made**: `lib/features/alerts/presentation/alerts_screen.dart` - `_loadNotifications` method

---

## Next Steps

1. **Immediate**: Run `fix_all_current_issues.sql` to enable delete notifications (if file exists)
2. **Test**: Verify duplicate items no longer appear after sync
3. **Test**: Verify notification timestamps update correctly
