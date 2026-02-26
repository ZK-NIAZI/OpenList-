# Deploy Sub-task Edit and Blocks Fix

## Problems
1. **Can't edit sub-tasks**: When user 2 opens a sub-task of a shared note, they can't edit it
2. **Sub-task blocks not showing**: The content (blocks) of sub-tasks don't appear for user 2

## Root Causes
1. **UPDATE policy for items**: Doesn't allow updating sub-tasks when parent is shared
2. **SELECT policy for blocks**: Doesn't allow viewing blocks of sub-tasks when parent is shared
3. **UPDATE/INSERT/DELETE policies for blocks**: Don't allow editing blocks of sub-tasks

## Solution
Update RLS policies to check if the parent item is shared with edit permission.

## Deployment Steps

### Step 1: Deploy SQL Fix
1. Open Supabase Dashboard
2. Go to SQL Editor
3. Copy and paste the contents of `fix_subtask_edit_and_blocks.sql`
4. Click "Run" to execute
5. Verify the output shows all policies were created successfully

### Step 2: Verify Policies
The output should show:
- **items table**: UPDATE policy includes sub-tasks
- **blocks table**: SELECT, INSERT, UPDATE, DELETE policies all include sub-tasks

### Step 3: Test on Second User's Device
1. Force close the app on second user's device
2. Reopen the app
3. Navigate to shared note "neck" (c2d1e69c-5384-4e56-ba37-d1a9ce5d0628)
4. Open sub-task "0000" or "tasking"
5. Try editing the sub-task title - should work now
6. Try adding blocks (text, checklist, etc.) - should work now
7. Blocks should now be visible

### Step 4: Verify in Logs
Look for these log messages:
```
✅ Synced to Supabase: [sub-task name]
✅ Synced block to Supabase: [block type]
```

No more RLS policy violation errors (code: 42501)

## What This Fix Does

### For Items (Tasks/Notes)
```sql
-- Old: Only own items and directly shared items
auth.uid() = created_by OR id IN (SELECT item_id FROM item_shares...)

-- New: Also includes sub-tasks of shared items
OR parent_id IN (SELECT item_id FROM item_shares WHERE permission = 'edit')
```

### For Blocks
```sql
-- Old: Only blocks of own items and directly shared items
item_id IN (SELECT id FROM items WHERE created_by = auth.uid())
OR item_id IN (SELECT item_id FROM item_shares...)

-- New: Also includes blocks of sub-tasks
OR item_id IN (
  SELECT id FROM items 
  WHERE parent_id IN (SELECT item_id FROM item_shares WHERE permission = 'edit')
)
```

## Expected Results
- User 2 can now edit sub-tasks (0000, tasking) of shared note "neck"
- User 2 can see and edit blocks within those sub-tasks
- User 2 can add new blocks to sub-tasks
- User 2 can delete blocks from sub-tasks
- All changes sync back to user 1 in real-time

## Notes
- This fix requires edit permission on the parent item
- View-only shares won't allow editing sub-tasks (as expected)
- Sub-tasks inherit edit permission from their parent automatically
- No changes needed to the Flutter code
