# Fix Delete Notifications - Quick Guide

## The Problem
When you delete a shared item, the other user doesn't get a notification.

## The Solution (3 Steps)

### Step 1: Run the SQL Fix
1. Open your Supabase project dashboard
2. Go to **SQL Editor**
3. Copy and paste the contents of `fix_all_current_issues.sql`
4. Click **Run**
5. You should see "✅ ALL FIXES APPLIED!" message

### Step 2: Verify It Worked
1. In SQL Editor, copy and paste the contents of `verify_delete_notifications.sql`
2. Click **Run**
3. All checks should show ✅

### Step 3: Test It
1. In your app, share an item with another user
2. Delete that item
3. The other user should receive a notification: "[Your Name] deleted [Item Title]"
4. Check Supabase logs (Logs section) for "DELETE TRIGGER FIRED" messages

## What Gets Fixed
- ✅ Delete notifications will be created when items are deleted
- ✅ Edit notifications will use correct 'update' type (not 'edit')
- ✅ Both will show the actual user's name (not "Someone")
- ✅ RLS policies allow deletion of owned and shared items

## Files Available
- `fix_all_current_issues.sql` - Fixes everything (RECOMMENDED)
- `setup_delete_notifications.sql` - Delete notifications only
- `verify_delete_notifications.sql` - Check if it's working
- `test_delete_notification.sql` - Debug trigger status

## Troubleshooting

### If notifications still don't appear:
1. Check Supabase logs for "DELETE TRIGGER FIRED"
2. Run `verify_delete_notifications.sql` to see what's missing
3. Make sure the item was actually shared (check item_shares table)
4. Verify the app is syncing (check sync logs)

### If you see "Someone deleted" instead of actual name:
- The profiles table might not have display_name set
- The trigger will fall back to email username
- Check: `SELECT id, display_name FROM profiles;`
