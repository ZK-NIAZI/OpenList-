# Sharing Feature Fix Summary

## Changes Made

### 1. Added Sync Trigger After Sharing
**File**: `lib/features/sharing/presentation/share_dialog.dart`
- Added import for `SyncManager`
- After creating a share, immediately trigger sync to push to Supabase
- This ensures the share is uploaded before User B tries to fetch it

### 2. Enhanced Debug Logging
**File**: `lib/data/sync/sync_manager.dart`

#### In `_pullFromSupabase()`:
- Added detailed logging when fetching shared items
- Shows how many share records were found
- Lists each shared item being fetched
- Helps debug if items aren't appearing for User B

#### In `_pushSharingToSupabase()`:
- Added detailed logging when pushing shares
- Shows the exact data being sent (shareId, item_id, user_id, permission)
- Helps verify the share was created correctly

### 3. Created Test Guide
**File**: `SHARING_TEST_GUIDE.md`
- Step-by-step instructions for testing sharing
- Expected debug logs to watch for
- Common issues and solutions
- SQL queries for debugging

## How Sharing Works

### Architecture
```
User A (Sharer)                    Supabase                    User B (Recipient)
─────────────────                  ────────                    ──────────────────
1. Create note
2. Click share button
3. Enter User B's email
4. Email → UUID lookup          → get_user_id_by_email()
5. Create ItemShareModel
   (local Isar, pending)
6. Trigger sync                  → Push to item_shares table
                                    (item_id, user_id, permission)
                                                                7. Log in
                                                                8. Auto-sync pulls
                                 ← Query item_shares            9. Fetch shared items
                                   WHERE user_id = B's UUID
                                                                10. Save to local Isar
                                                                11. Display in UI
```

### Database Schema

#### item_shares table
```sql
CREATE TABLE item_shares (
  id UUID PRIMARY KEY,
  item_id UUID NOT NULL REFERENCES items(id),
  user_id UUID NOT NULL REFERENCES auth.users(id),  -- UUID of recipient
  permission TEXT ('edit' or 'view'),
  shared_by UUID REFERENCES auth.users(id),         -- UUID of sharer
  shared_at TIMESTAMP,
  created_at TIMESTAMP,
  updated_at TIMESTAMP
);
```

#### RLS Policies
- Users can SELECT shares where they are the recipient OR the sharer
- Users can INSERT shares for items they own
- Users can UPDATE/DELETE shares for items they own

## Testing Checklist

### Prerequisites
- [ ] Two user accounts created (User A and User B)
- [ ] `fix_sharing_complete.sql` has been run in Supabase
- [ ] `get_user_id_by_email()` function exists in Supabase
- [ ] RLS policies are enabled on all tables

### Test Flow
- [ ] User A creates a note
- [ ] User A shares note with User B's email
- [ ] Success message appears: "✅ Shared with [email]"
- [ ] Sync completes (watch sync indicator)
- [ ] Check Supabase: `item_shares` table has new record
- [ ] User B logs in
- [ ] Auto-sync runs on login
- [ ] User B sees the shared note in dashboard/notes
- [ ] User B can open and view the note
- [ ] If permission is 'edit', User B can modify the note
- [ ] Changes sync back to Supabase
- [ ] User A sees User B's changes after sync

### Debug Logs to Verify

#### When User A shares (check console):
```
🔄 Triggering sync after sharing...
📤 Pushing 1 item shares to Supabase...
📤 Syncing share:
   shareId: [UUID]
   item_id: [UUID]
   user_id: [User B UUID]
   permission: view
   shared_by: [User A UUID]
✅ Synced share to Supabase successfully
```

#### When User B logs in (check console):
```
📥 Pulling from Supabase for user: [User B UUID]
🔍 Looking for shares with user_id=[User B UUID]
📥 Found 1 share records for this user
   📄 Share: item_id=[UUID]
🔍 Fetching items with IDs: [[UUID]]
📥 Fetched 1 shared items from Supabase
   📄 Shared item: [Note Title] (id: [UUID])
💾 Saving item from Supabase: [Note Title]
✅ Pull completed - saved 1 items to local database
```

## Troubleshooting

### Issue: "User with email X not found"
**Cause**: User B hasn't registered yet, or email doesn't match
**Solution**: 
1. Verify User B has an account
2. Check email spelling (case-sensitive)
3. Test the function: `SELECT get_user_id_by_email('[email]');`

### Issue: Share created but User B doesn't see note
**Cause**: Sync not running, or RLS policy blocking access
**Solution**:
1. Check debug logs - is sync pulling shared items?
2. Verify RLS policies allow User B to read the item
3. Check `item_shares` table has correct `user_id` (UUID, not email)
4. Run this query as User B:
```sql
SELECT * FROM items 
WHERE id IN (
  SELECT item_id FROM item_shares 
  WHERE user_id = '[User B UUID]'
);
```

### Issue: RLS policy error "infinite recursion"
**Cause**: Policies reference each other in a loop
**Solution**: Run `fix_sharing_complete.sql` to recreate simple policies

### Issue: Blocks not syncing for shared items
**Cause**: Blocks RLS policy doesn't allow shared access
**Solution**: Verify blocks policies include:
```sql
CREATE POLICY "blocks_select_shared"
  ON blocks FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM items 
      JOIN item_shares ON item_shares.item_id = items.id
      WHERE items.id = blocks.item_id 
      AND item_shares.user_id = auth.uid()
    )
  );
```

## Key Points

1. **UUID vs Email**: Always use UUID for database operations, email only for lookup
2. **Sync Timing**: Share must be pushed to Supabase before recipient can pull it
3. **RLS Policies**: Must allow both owner AND shared users to access items
4. **Local Storage**: Shared items are stored in recipient's local Isar database
5. **Permissions**: 'view' = read-only, 'edit' = read + write
6. **Blocks**: Shared items include their blocks (content)

## Next Steps

1. Test the sharing flow with two accounts
2. Watch the debug logs to verify each step
3. If issues occur, check the troubleshooting section
4. Verify in Supabase dashboard that data is correct
5. Test both 'view' and 'edit' permissions
6. Test editing shared items and syncing changes
