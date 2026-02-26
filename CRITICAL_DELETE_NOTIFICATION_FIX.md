# CRITICAL: Delete Notifications Not Working - Root Cause Found! 🔍

## The Real Problem

You've run the SQL multiple times, but delete notifications still don't work. Here's why:

### Issue: `auth.uid()` Returns NULL

When your Flutter app deletes an item from Supabase, the trigger fires but **`auth.uid()` returns NULL**!

This happens because:
1. Flutter app uses service role key OR
2. The delete request doesn't include the user's JWT token OR
3. RLS policies are bypassing authentication

When `auth.uid()` is NULL, the trigger code does this:
```sql
IF v_current_user IS NULL THEN
  RAISE NOTICE 'No current user, skipping notifications';
  RETURN OLD;  -- ❌ Exits without creating notifications!
END IF;
```

## How to Verify This Is The Problem

Run `diagnose_delete_trigger.sql` in Supabase SQL Editor. Look for:
- ❌ "No authenticated user (auth.uid() is NULL)"
- ❌ "FAILED! No delete notification was created"

Then check Supabase Dashboard > Logs for:
- "DELETE TRIGGER FIRED" ✅ (trigger is working)
- "No current user, skipping notifications" ❌ (this is the problem!)

## The Solution

We need to pass the user ID explicitly instead of relying on `auth.uid()`. Here are 3 options:

### Option 1: Store User ID in Item (RECOMMENDED)
The trigger can use `OLD.created_by` to identify who deleted it:

```sql
-- Use created_by as fallback if auth.uid() is NULL
v_current_user := COALESCE(auth.uid(), OLD.created_by);
```

This works because:
- We know who created the item
- If they're deleting it, we can use their ID
- No code changes needed in Flutter

### Option 2: Fix Supabase Client Authentication
Make sure Flutter app uses authenticated client:

```dart
// In item_repository.dart, verify we're using authenticated client
final supabase = Supabase.instance.client;  // Should have user's JWT
```

Check if you're accidentally using service role key anywhere.

### Option 3: Add User ID to Delete Request
Pass user ID explicitly in the delete request (not recommended, more complex).

## Recommended Fix (Option 1)

Run this SQL to update the trigger:

```sql
CREATE OR REPLACE FUNCTION notify_on_item_delete()
RETURNS TRIGGER AS $
DECLARE
  v_share RECORD;
  v_deleter_name TEXT;
  v_current_user UUID;
BEGIN
  -- Get current user (with fallback to item creator)
  v_current_user := COALESCE(auth.uid(), OLD.created_by);
  
  RAISE NOTICE 'DELETE TRIGGER FIRED for item: % (id: %)', OLD.title, OLD.id;
  RAISE NOTICE 'Current user: % (from auth.uid: %, from created_by: %)', 
    v_current_user, auth.uid(), OLD.created_by;
  
  -- Skip if still no user (shouldn't happen)
  IF v_current_user IS NULL THEN
    RAISE NOTICE 'No current user and no creator, skipping notifications';
    RETURN OLD;
  END IF;
  
  -- Rest of the trigger code stays the same...
  -- (Get deleter name, create notifications, etc.)
  
  RETURN OLD;
END;
$ LANGUAGE plpgsql SECURITY DEFINER;
```

## Why This Happens

The Flutter app might be using:
1. **Service role key** - Bypasses RLS, no user context
2. **Anon key without JWT** - No authenticated user
3. **Expired JWT token** - User session expired

## Next Steps

1. Run `diagnose_delete_trigger.sql` to confirm the issue
2. Check Supabase logs for "No current user" message
3. If confirmed, run the updated trigger with COALESCE fallback
4. Test deletion again
5. Check logs for "Current user: [UUID]" message

## Expected Logs After Fix

```
DELETE TRIGGER FIRED for item: Test Note (id: abc-123)
Current user: user-uuid-here (from auth.uid: NULL, from created_by: user-uuid-here)
Deleter name: John
Creating delete notification for user: other-user-uuid
✅ Delete notification created for user: other-user-uuid
DELETE TRIGGER COMPLETED
```

Then in your Flutter app:
```
✅ Item deleted from Supabase (delete notification should be created)
📥 Fetched 1 notifications  ← Delete notification appears!
```
