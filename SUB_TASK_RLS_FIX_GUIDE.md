# Sub-Task RLS Policy Fix

## Problem Identified ✅

Sub-tasks are **NOT syncing to Supabase** due to Row Level Security (RLS) policy violation:

```
❌ Failed to sync item sub: PostgrestException(
  message: new row violates row-level security policy for table "items",
  code: 42501,
  details: Forbidden
)
```

## Root Cause

When you create a sub-task:
1. App creates it locally in Isar ✅
2. Sub-task inherits `created_by` from parent ✅
3. App tries to sync to Supabase ❌
4. **RLS policy blocks it** because `created_by` doesn't match current user

Example:
```
User A (id: aaa-111) creates Parent Task
User A creates Sub-task → created_by = aaa-111 ✅

User A tries to sync Sub-task to Supabase
RLS Policy checks: Is auth.uid() == created_by?
  auth.uid() = aaa-111
  created_by = aaa-111
  Result: ✅ ALLOWED

BUT if User B (id: bbb-222) creates sub-task of shared item:
User B creates Sub-task → created_by = aaa-111 (inherited from parent)
User B tries to sync to Supabase
RLS Policy checks: Is auth.uid() == created_by?
  auth.uid() = bbb-222
  created_by = aaa-111
  Result: ❌ BLOCKED
```

## Solution

Update the RLS INSERT policy to allow sub-task creation.

### Option 1: Secure Policy (Recommended)

Run `fix_subtask_rls_policy.sql` in Supabase SQL Editor.

This policy allows:
- Creating items where you are the creator
- Creating sub-tasks of items you own
- Creating sub-tasks of items shared with you (with edit permission)

### Option 2: Simple Policy (Easier)

Run `fix_subtask_rls_simple.sql` in Supabase SQL Editor.

This policy allows:
- Any authenticated user to insert items
- Less secure but simpler
- Access control still enforced by SELECT policies

---

## How to Fix

### Step 1: Run the SQL Fix

**Option A (Recommended):**
1. Open Supabase Dashboard
2. Go to SQL Editor
3. Copy and paste `fix_subtask_rls_policy.sql`
4. Click "Run"

**Option B (Simpler):**
1. Open Supabase Dashboard
2. Go to SQL Editor
3. Copy and paste `fix_subtask_rls_simple.sql`
4. Click "Run"

### Step 2: Verify the Fix

Run this query to check the policy:

```sql
SELECT 
  policyname,
  cmd,
  with_check
FROM pg_policies
WHERE tablename = 'items'
AND cmd = 'INSERT';
```

Should see:
- `Users can insert items and sub-tasks` (Option A)
- OR `Users can insert items` (Option B)

### Step 3: Test in App

1. Create a parent task
2. Add a sub-task
3. Check logs - should see:
   ```
   ✅ Synced to Supabase: sub
   ```
   Instead of:
   ```
   ❌ Failed to sync item sub: PostgrestException...
   ```

---

## Understanding the Logs

### Before Fix (Current State)

```
I/flutter: 📄 sub - syncStatus: pending (1)
I/flutter: 📤 Syncing: sub (itemId: eec7a093-ceef-4eb1-a25b-4329e9aa75df)
I/flutter: ❌ Failed to sync item sub: PostgrestException(
  message: new row violates row-level security policy for table "items",
  code: 42501
)
```

Sub-task stuck as "pending" forever, never syncs.

### After Fix (Expected)

```
I/flutter: 📄 sub - syncStatus: pending (1)
I/flutter: 📤 Syncing: sub (itemId: eec7a093-ceef-4eb1-a25b-4329e9aa75df)
I/flutter: ✅ Synced to Supabase: sub
I/flutter: 📄 sub - syncStatus: synced (0)
```

Sub-task syncs successfully!

---

## Why This Happens

### The Inheritance Design

Sub-tasks inherit `created_by` from parent to maintain ownership chain:

```
Parent Task (created_by: User A)
├─ Sub-task 1 (created_by: User A) ← Inherited
├─ Sub-task 2 (created_by: User A) ← Inherited
└─ Sub-task 3 (created_by: User A) ← Inherited
```

This ensures:
- All tasks in hierarchy have same owner
- Permissions cascade correctly
- Deletion cascades properly

### The RLS Problem

Old RLS policy:
```sql
CREATE POLICY "Users can insert their own items"
ON items FOR INSERT
WITH CHECK (auth.uid() = created_by);
```

This blocks sub-task creation when:
- User B creates sub-task of User A's shared item
- `auth.uid()` = User B
- `created_by` = User A (inherited)
- Policy blocks: User B ≠ User A ❌

### The Fix

New RLS policy adds exception for sub-tasks:
```sql
WITH CHECK (
  auth.uid() = created_by  -- Normal items
  OR
  (parent_id IS NOT NULL AND ...)  -- Sub-tasks allowed
)
```

---

## Testing Checklist

After applying the fix:

- [ ] Create parent task
- [ ] Add sub-task
- [ ] Check logs for "✅ Synced to Supabase"
- [ ] Verify sub-task appears in Supabase
- [ ] Share parent with another user
- [ ] Other user creates sub-task
- [ ] Verify other user's sub-task syncs
- [ ] Verify both users see all sub-tasks

---

## Troubleshooting

### Issue: Policy creation fails

**Error:** `policy "Users can insert their own items" already exists`

**Solution:**
1. The DROP POLICY commands should handle this
2. If not, manually drop the policy:
   ```sql
   DROP POLICY "Users can insert their own items" ON items;
   ```
3. Then run the fix again

### Issue: Still getting RLS error after fix

**Possible Causes:**
1. Policy not applied correctly
2. Wrong policy name
3. Cache issue

**Solution:**
1. Verify policy exists:
   ```sql
   SELECT * FROM pg_policies WHERE tablename = 'items';
   ```
2. Try Option 2 (simple policy)
3. Restart app to clear any caches

### Issue: Sub-tasks sync but don't appear for shared users

**This is a different issue** - covered in `SUB_TASK_SHARING_STATUS.md`

The RLS fix only solves the sync problem. Sharing is handled separately.

---

## Summary

✅ **Problem:** Sub-tasks not syncing due to RLS policy
✅ **Cause:** `created_by` inheritance conflicts with RLS check
✅ **Solution:** Update RLS policy to allow sub-task creation
✅ **Files:** `fix_subtask_rls_policy.sql` or `fix_subtask_rls_simple.sql`

Run the SQL fix, test in app, and sub-tasks should sync successfully!
