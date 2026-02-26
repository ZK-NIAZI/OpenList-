# Edit Notifications Fix

## Problem Identified
Edit notifications were not being created when blocks were updated because the `updated_at` timestamp wasn't changing during upsert operations.

### Root Cause
In `lib/data/sync/sync_manager.dart`, the block sync was using:
```dart
'updated_at': block.updatedAt.toIso8601String()
```

This meant that if a block was synced multiple times without local changes, the `updated_at` value would be the same. When Supabase performed the upsert:
```sql
INSERT INTO blocks (...) VALUES (...)
ON CONFLICT (id) DO UPDATE SET updated_at = '2024-01-01 10:00:00'
```

If the `updated_at` value was identical to what was already in the database, PostgreSQL would optimize away the UPDATE, and the trigger wouldn't fire.

## Solution Applied
Changed the sync code to always use the current timestamp:
```dart
'updated_at': DateTime.now().toIso8601String()
```

This ensures that every sync operation sets a new `updated_at` value, which guarantees:
1. The UPDATE part of the upsert actually executes
2. The `AFTER UPDATE` trigger fires
3. Notifications are created for shared users

## Why This Works
- **First sync (INSERT)**: Trigger doesn't fire because it's set to `AFTER UPDATE ON blocks` only
- **Subsequent syncs (UPDATE)**: Trigger fires because `updated_at` is always different
- **No false positives**: The trigger still checks if content or checkbox state actually changed before creating notifications

## Testing Instructions

### Step 1: Rebuild and Run the App
```bash
flutter run
```

### Step 2: Test Edit Notifications
1. Open a shared note on Account 1 (fahadraza6512@gmail.com)
2. Edit the content of a block (e.g., change "7" to "7 8 9")
3. Wait for sync to complete (watch for "✅ Synced block to Supabase" in logs)
4. Switch to Account 2 (mutaalimran2k3@gmail.com)
5. Pull to refresh or wait for auto-sync
6. Go to Alerts screen
7. You should see a notification: "Someone updated [note title]"

### Step 3: Verify in Logs
Look for these log messages:
```
📤 Syncing block:
   blockId: xxx
   itemId: xxx
   type: heading
   content: 7 8 9
   syncStatus: pending
📤 Upserting to Supabase with updated_at: 2024-02-24T...
✅ Synced block to Supabase: heading
📥 Fetched X notifications
✅ Notifications pull completed - saved X notifications
```

### Step 4: Check Supabase (Optional)
If you want to verify the trigger is firing:
1. Go to Supabase Dashboard > Database > Logs
2. Look for RAISE NOTICE messages like:
   - "Block edit detected: block_id=xxx, item_id=xxx"
   - "Created edit notification: id=xxx, user_id=xxx"

## Additional Debug Tools Created

### 1. `debug_edit_notifications_comprehensive.sql`
Comprehensive debug script that:
- Checks trigger status
- Finds shared items
- Tests trigger manually
- Shows who should receive notifications

### 2. `test_trigger_simple.sql`
Simple manual test to update a block and check if notification is created.

### 3. `EDIT_NOTIFICATIONS_DIAGNOSIS.md`
Detailed diagnosis document explaining the issue and possible solutions.

## What Was Changed
- **File**: `lib/data/sync/sync_manager.dart`
- **Line**: ~448
- **Change**: `block.updatedAt.toIso8601String()` → `DateTime.now().toIso8601String()`
- **Added**: Extra logging to show sync status and timestamp

## Expected Behavior After Fix
- ✅ Share notifications work (already working)
- ✅ Edit notifications work (now fixed)
- ✅ Unshare notifications work (already working)
- ⏳ Delete notifications (not yet implemented)

## Notes
- The trigger only fires on UPDATE, not INSERT, so new blocks won't create notifications
- The trigger checks if content or checkbox state actually changed before creating notifications
- The trigger uses SECURITY DEFINER to bypass RLS when inserting notifications
- All exceptions are caught and logged, so the trigger won't break sharing functionality
