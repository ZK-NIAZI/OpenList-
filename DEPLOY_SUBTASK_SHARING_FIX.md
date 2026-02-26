# Deploy Sub-task Sharing Fix

## Problem
When user 1 shares note "00" with user 2, the sub-tasks (090909, 000000, 99999) owned by user 1 are NOT visible to user 2.

## Root Cause
The RLS SELECT policy only allows users to see:
- Items they created (`auth.uid() = created_by`)
- Items directly shared with them (`id IN (SELECT item_id FROM item_shares WHERE user_id = auth.uid())`)
- But NOT sub-tasks of shared items (where `parent_id` is in shared items)

## Why Previous Fix Failed
The first attempt (`fix_subtask_sharing_rls.sql`) caused infinite recursion because:
- Using `parent_id IN (SELECT item_id FROM item_shares...)` caused PostgreSQL to recursively evaluate the RLS policy
- ANY subquery that references the `items` table triggers recursion
- Error: `PostgrestException(message: infinite recursion detected in policy for relation "items", code: 42P17)`

## New Approach (v3)
The working fix uses `EXISTS` with explicit table references:
```sql
EXISTS (
  SELECT 1 
  FROM item_shares 
  WHERE item_shares.item_id = items.parent_id 
  AND item_shares.user_id = auth.uid()
)
```
This ONLY checks the `item_shares` table, avoiding any recursion into `items` table.

## Solution
Update the RLS policy to include: `parent_id IN (SELECT item_id FROM item_shares WHERE user_id = auth.uid())`

This allows users to see sub-tasks when the parent item is shared with them.

## Deployment Steps

### Step 1: Deploy SQL Fix
1. Open Supabase Dashboard
2. Go to SQL Editor
3. Copy and paste the contents of `fix_subtask_sharing_rls_v3.sql` (NOT v1 or v2!)
4. Click "Run" to execute
5. Verify the output shows the new policy was created

**IMPORTANT:** Use `fix_subtask_sharing_rls_v3.sql` - the previous versions caused infinite recursion!

### Step 2: Verify Policy
Run this query in SQL Editor to confirm the policy exists:
```sql
SELECT schemaname, tablename, policyname, permissive, roles, cmd, qual
FROM pg_policies
WHERE tablename = 'items' AND policyname LIKE '%view%';
```

Expected output: Should show policy named "Users can view their own items, shared items, and sub-tasks of shared items"

### Step 3: Test on Second User's Device
1. Force close the app on second user's device (d8fd378d-ae52-42d9-ab11-c6fb5113f0c0)
2. Reopen the app (this triggers a fresh sync)
3. Navigate to shared note "00"
4. Check if sub-tasks (090909, 000000, 99999) now appear

### Step 4: Verify in Logs
Look for these log messages:
```
🔍 watchSubTasks stream emitted X sub-tasks
📥 Fetched X sub-tasks from Supabase
```

Where X should be 3 (the number of sub-tasks)

## Verification Queries

### Check if sub-tasks exist in database
```sql
SELECT id, title, parent_id, created_by
FROM items
WHERE parent_id IS NOT NULL
ORDER BY created_at DESC;
```

### Check what second user should see
Replace `YOUR_USER_ID` with: `d8fd378d-ae52-42d9-ab11-c6fb5113f0c0`
```sql
SELECT 
  i.id,
  i.title,
  i.parent_id,
  CASE 
    WHEN i.created_by = 'YOUR_USER_ID'::uuid THEN '✅ Owned'
    WHEN EXISTS (
      SELECT 1 FROM item_shares 
      WHERE item_id = i.id 
      AND user_id = 'YOUR_USER_ID'::uuid
    ) THEN '🔗 Directly Shared'
    WHEN i.parent_id IS NOT NULL AND EXISTS (
      SELECT 1 FROM item_shares 
      WHERE item_id = i.parent_id 
      AND user_id = 'YOUR_USER_ID'::uuid
    ) THEN '👶 Parent Shared (NEW!)'
    ELSE '❌ No Access'
  END as access_type
FROM items i
ORDER BY i.created_at DESC;
```

## Expected Results
- Second user should see 3 sub-tasks with access_type = '👶 Parent Shared (NEW!)'
- Sub-tasks should appear in the task detail screen when viewing note "00"
- Tapping a sub-task should open its detail page

## Rollback (if needed)
If something goes wrong, restore the original policy:
```sql
DROP POLICY IF EXISTS "Users can view their own items, shared items, and sub-tasks of shared items" ON items;

CREATE POLICY "Users can view their own items and shared items"
ON items FOR SELECT
USING (
  auth.uid() = created_by
  OR
  id IN (
    SELECT item_id 
    FROM item_shares 
    WHERE user_id = auth.uid()
  )
);
```

## Notes
- This fix does NOT require app restart, only a fresh sync
- The fix avoids infinite recursion by only checking `item_shares` table, not `items` table
- Sub-tasks inherit access from their parent automatically
- No changes needed to the Flutter code - it already fetches sub-tasks correctly
