# Edit Notifications Not Working - Diagnosis

## Problem
Edit notifications are not being created when blocks are updated from the Flutter app, even though:
- Share notifications work perfectly
- The trigger exists and is enabled
- RLS policies are correct
- The trigger has extensive logging

## Root Cause Analysis

### How the App Updates Blocks
From `lib/data/sync/sync_manager.dart` line 456:
```dart
await supabase.from('blocks').upsert(data);
```

The app uses **UPSERT** which in PostgreSQL translates to:
```sql
INSERT INTO blocks (...) VALUES (...)
ON CONFLICT (id) DO UPDATE SET ...
```

### The Trigger Issue
The trigger is defined as:
```sql
CREATE TRIGGER trigger_notify_on_block_edit
AFTER UPDATE ON blocks
FOR EACH ROW
EXECUTE FUNCTION notify_on_block_edit();
```

**Problem**: `ON CONFLICT DO UPDATE` in PostgreSQL **DOES trigger AFTER UPDATE triggers**, so this should work.

## Possible Causes

### 1. Trigger Not Firing Due to No Changes
If the upsert sets the same values, PostgreSQL might optimize away the UPDATE and not fire the trigger.

**Test**: Check if `updated_at` is actually changing in the upsert.

### 2. Trigger Function Failing Silently
The trigger has exception handlers that catch errors. If something fails, it might not create notifications but also not throw an error.

**Test**: Check Supabase Postgres logs for RAISE NOTICE messages.

### 3. Auth Context Missing
The trigger tries to get `auth.uid()` which might be NULL when called from the Supabase client.

**Test**: Check if notifications are created with NULL `related_user_id`.

### 4. Item Not Shared
The trigger only creates notifications for users in `item_shares`. If the item isn't actually shared, no notifications will be created.

**Test**: Verify the item has entries in `item_shares` table.

## Debugging Steps

### Step 1: Run Comprehensive Debug
Execute `debug_edit_notifications_comprehensive.sql` to:
- Check trigger status
- Find shared items
- Test trigger manually
- Check for notifications

### Step 2: Check Supabase Logs
Go to Supabase Dashboard > Database > Logs and look for:
- `Block edit detected` messages
- `Created edit notification` messages
- Any error messages

### Step 3: Manual Trigger Test
Run `test_trigger_simple.sql` to manually update a block and see if notification is created.

### Step 4: Check Upsert Behavior
The upsert might not be triggering UPDATE if values are identical. Check if `updated_at` is being set to a new timestamp.

## Solutions

### Solution 1: Ensure updated_at Changes
Modify the upsert to always set a new timestamp:
```dart
final data = {
  // ... other fields
  'updated_at': DateTime.now().toIso8601String(), // Always new timestamp
};
```

### Solution 2: Use Explicit UPDATE Instead of UPSERT
For edits (not creates), use UPDATE instead of UPSERT:
```dart
if (block.syncStatus == SyncStatus.pending) {
  // This is an edit, use UPDATE
  await supabase.from('blocks')
    .update(data)
    .eq('id', block.blockId);
} else {
  // This is a create, use INSERT
  await supabase.from('blocks').insert(data);
}
```

### Solution 3: Create Notifications from Flutter
If triggers continue to fail, create notifications directly from Flutter when syncing blocks:
```dart
// After successful block sync
if (isEdit && itemIsShared) {
  await _createEditNotification(block.itemId);
}
```

## Next Steps
1. Run `debug_edit_notifications_comprehensive.sql`
2. Check Supabase logs for RAISE NOTICE messages
3. If trigger isn't firing, apply Solution 1 or 2
4. If trigger fires but fails, check the error in logs
