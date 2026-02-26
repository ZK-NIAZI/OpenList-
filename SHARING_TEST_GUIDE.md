# Sharing Feature Test Guide

## Setup
You need TWO user accounts to test sharing:
- User A (sharer): The person who creates and shares the note
- User B (recipient): The person who receives the shared note

## Test Steps

### Step 1: User A - Create and Share a Note
1. Log in as User A
2. Create a new note (e.g., "Test Shared Note")
3. Add some content to the note
4. Wait for sync to complete (watch for sync indicator)
5. Open the note detail screen
6. Tap the share button in the AppBar
7. Enter User B's email address
8. Select permission (view or edit)
9. Tap "Share"
10. You should see: "✅ Shared with [email]"
11. Wait for sync to complete

### Step 2: Check Supabase (Optional)
1. Go to your Supabase dashboard
2. Open the `item_shares` table
3. You should see a record with:
   - `item_id`: UUID of the note
   - `user_id`: UUID of User B
   - `permission`: 'view' or 'edit'
   - `shared_by`: UUID of User A

### Step 3: User B - Receive Shared Note
1. Log out from User A
2. Log in as User B
3. The app will auto-sync on login
4. Check the dashboard or notes screen
5. You should see "Test Shared Note" appear

## Debug Logs to Watch

### When User A shares:
```
🔄 Triggering sync after sharing...
📤 Pushing X item shares to Supabase...
📤 Syncing share:
   shareId: [UUID]
   item_id: [UUID]
   user_id: [UUID of User B]
   permission: view/edit
   shared_by: [UUID of User A]
✅ Synced share to Supabase successfully
```

### When User B logs in:
```
📥 Pulling from Supabase for user: [User B UUID]
🔍 Looking for shares with user_id=[User B UUID]
📥 Found X share records for this user
   📄 Share: item_id=[UUID]
🔍 Fetching items with IDs: [list of UUIDs]
📥 Fetched X shared items from Supabase
   📄 Shared item: Test Shared Note (id: [UUID])
💾 Saving item from Supabase: Test Shared Note
✅ Pull completed - saved X items to local database
```

## Common Issues

### Issue 1: "User with email X not found"
- Make sure User B has registered an account
- The email must match exactly (case-sensitive)
- Check that `get_user_id_by_email()` function exists in Supabase

### Issue 2: Share created but User B doesn't see the note
- Check if sync is running on User B's device
- Look for the debug logs above
- Verify RLS policies in Supabase allow User B to read the item
- Check that `item_shares` table has the correct `user_id` (UUID, not email)

### Issue 3: RLS policy error
- Run `fix_sharing_complete.sql` to recreate all policies
- Make sure all tables have RLS enabled
- Verify the policies allow reading shared items

## SQL Queries to Debug

### Check if share was created:
```sql
SELECT * FROM item_shares 
WHERE item_id = '[item UUID]';
```

### Check if User B can see the item:
```sql
-- Run this as User B (set auth.uid() to User B's UUID)
SELECT * FROM items 
WHERE id IN (
  SELECT item_id FROM item_shares 
  WHERE user_id = '[User B UUID]'
);
```

### Check user UUID by email:
```sql
SELECT get_user_id_by_email('[email]');
```

## Expected Behavior

✅ User A shares note → Share record created in local Isar
✅ Sync pushes share to Supabase `item_shares` table
✅ User B logs in → Sync pulls shared items
✅ User B sees the shared note in their dashboard/notes
✅ User B can open and view the note
✅ If permission is 'edit', User B can modify the note
✅ Changes sync back to Supabase
✅ User A sees User B's changes after sync
