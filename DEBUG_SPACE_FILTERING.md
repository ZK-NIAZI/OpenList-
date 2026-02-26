# Debug: Space Filtering Not Working

## Problem
Items showing in both Personal and Shared spaces when they shouldn't.

## Root Causes

### 1. **No Shares in Database**
If you haven't actually shared any items yet, ALL items will show as "Personal" because `isItemShared()` returns `false`.

**Test:**
1. Run `check_item_shares.sql` in Supabase SQL Editor
2. Check if there are ANY rows in `item_shares` table
3. If empty → that's why everything is "Personal"

### 2. **Offline Mode**
If the app is offline, `isItemShared()` catches the error and returns `false`, so everything appears as "Personal".

**Test:**
1. Check if you have internet connection
2. Check Supabase dashboard → is it accessible?
3. Look at Flutter console for error messages

### 3. **Wrong User ID**
If `createdBy` field doesn't match your current user ID, items won't show in Personal.

**Test:**
```sql
-- Check your current user ID
SELECT auth.uid();

-- Check who created the items
SELECT title, created_by FROM items;

-- They should match!
```

## How to Test Properly

### Step 1: Create a Personal Note
1. Create a new note (don't share it)
2. Click "Personal" in sidebar
3. Should see the note ✅
4. Click "Shared" in sidebar
5. Should NOT see the note ✅

### Step 2: Share the Note
1. Open the note
2. Click share icon
3. Share with another user (or yourself for testing)
4. Click "Personal" in sidebar
5. Should NOT see the note anymore ❌
6. Click "Shared" in sidebar
7. Should see the note ✅

### Step 3: Check Console Logs
Look for these logs in Flutter console:
```
🔍 watchPersonalItems: currentUserId = abc-123...
🔍 watchPersonalItems: Got 5 items created by user
   📄 "My Note" - isShared: false
   📄 "Shared Note" - isShared: true
✅ watchPersonalItems: Returning 4 personal items
```

## Quick Fix: Force Refresh

If filtering seems stuck:

1. **Hot Restart** the app (not hot reload)
2. **Pull to refresh** on dashboard
3. **Re-login** to clear any cached state

## SQL Queries to Debug

### Check if item is actually shared:
```sql
SELECT * FROM item_shares WHERE item_id = 'YOUR_ITEM_ID_HERE';
```

### Check all your items:
```sql
SELECT 
  items.title,
  items.created_by,
  COUNT(item_shares.id) as share_count
FROM items
LEFT JOIN item_shares ON item_shares.item_id = items.id
WHERE items.created_by = auth.uid()
GROUP BY items.id, items.title;
```

### Manually add a share for testing:
```sql
-- Get your user ID
SELECT auth.uid();

-- Get an item ID
SELECT id, title FROM items LIMIT 1;

-- Create a share (replace the IDs)
INSERT INTO item_shares (item_id, user_id, permission)
VALUES ('ITEM_ID_HERE', 'USER_ID_HERE', 'view');
```

## Expected Behavior

| Scenario | Personal | Shared |
|----------|----------|--------|
| New note (not shared) | ✅ Shows | ❌ Hidden |
| Note shared by you | ❌ Hidden | ✅ Shows |
| Note shared with you | ❌ Hidden | ✅ Shows |
| Note you created + received back | ❌ Hidden | ✅ Shows |

## Common Mistakes

❌ **Thinking "Personal" means "created by me"**
- Wrong! Personal = created by me AND not shared

❌ **Not actually sharing items**
- The share dialog must complete successfully
- Check `item_shares` table to confirm

❌ **Testing with same account**
- Share with a different account to see real behavior
- Or share with yourself (it works for testing)

## If Still Not Working

1. Check Flutter console for error messages
2. Run `check_item_shares.sql` and share the results
3. Check if `isItemShared()` is returning correct values (look for logs)
4. Verify Supabase connection is working (try pull-to-refresh)

## Next Steps

After fixing, test this flow:
1. Create 3 notes
2. Share 1 note
3. Personal should show 2 notes
4. Shared should show 1 note
5. Total = 3 notes (no duplicates!)
