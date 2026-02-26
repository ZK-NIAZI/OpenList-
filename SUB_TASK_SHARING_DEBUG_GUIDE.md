# Sub-Task Sharing Debug Guide

## Current Status

The code for sub-task sharing is implemented but may not be working as expected. This guide will help debug the issue.

---

## Implementation Summary

### What's Implemented

1. **SyncManager** - Fetches sub-tasks of shared items
2. **RealtimeService** - Checks if item is child of shared parent
3. **ItemRepository** - Methods to create and manage sub-tasks
4. **TaskDetailScreen** - UI to add and view sub-tasks

### How It Should Work

```
User A creates:
  Parent Task (id: parent-123)
  ├─ Sub-task 1 (id: child-1, parent_id: parent-123)
  └─ Sub-task 2 (id: child-2, parent_id: parent-123)

User A shares Parent Task with User B:
  - Creates item_share (item_id: parent-123, user_id: user-b-id)

User B syncs:
  1. Pulls shared items → finds parent-123
  2. Queries items WHERE parent_id IN [parent-123]
  3. Should find child-1 and child-2
  4. Saves all 3 items to Isar
```

---

## Debugging Steps

### Step 1: Verify Sub-Tasks Exist in Database

Run this SQL in Supabase SQL Editor:

```sql
-- Check if any sub-tasks exist
SELECT 
  id,
  title,
  parent_id,
  created_by,
  created_at
FROM items
WHERE parent_id IS NOT NULL
ORDER BY created_at DESC
LIMIT 20;
```

**Expected Result:** Should see sub-tasks with non-null parent_id

**If empty:** Sub-tasks haven't been created yet or parent_id is null

### Step 2: Check Specific User's Sub-Tasks

Replace `USER_ID_HERE` with actual user ID:

```sql
-- Check sub-tasks created by specific user
SELECT 
  i.id,
  i.title,
  i.parent_id,
  p.title as parent_title
FROM items i
LEFT JOIN items p ON p.id = i.parent_id
WHERE i.parent_id IS NOT NULL
  AND i.created_by = 'USER_ID_HERE'
ORDER BY i.created_at DESC;
```

### Step 3: Check Shared Parent with Sub-Tasks

```sql
-- Check if shared items have sub-tasks
SELECT 
  s.item_id as shared_parent_id,
  i.title as shared_parent_title,
  s.user_id as shared_with_user,
  c.id as child_id,
  c.title as child_title
FROM item_shares s
INNER JOIN items i ON i.id = s.item_id
LEFT JOIN items c ON c.parent_id = s.item_id
WHERE c.id IS NOT NULL;
```

**Expected Result:** Should see shared parents with their children

**If empty:** Either no items are shared, or shared items have no children

### Step 4: Check App Logs

Look for these log messages when syncing:

```
🔍 ========== SUB-TASK FETCHING START ==========
🔍 Items in map before sub-task fetch: X
🔍 Item IDs that could be parents: [...]
🔍 Fetching sub-tasks for X parent items...
🔍 Parent IDs: [...]
📥 Fetched X sub-tasks from Supabase
```

**If you see:**
- "⚠️ No sub-tasks found" → Query returned 0 results
- "⚠️ itemsMap is empty" → No items to fetch sub-tasks for
- "❌ Error fetching sub-tasks" → Query failed

### Step 5: Test Sub-Task Creation

1. Open a task detail page
2. Tap "Add Sub-task" button
3. Check logs for:
   ```
   📤 Syncing: New Sub-task (itemId: xxx)
   ```
4. Verify in Supabase that item has parent_id set

### Step 6: Test Sharing

1. User A creates parent task with sub-tasks
2. User A shares parent with User B
3. User B triggers sync (pull to refresh)
4. Check User B's logs for sub-task fetching
5. Verify User B can see sub-tasks in UI

---

## Common Issues

### Issue 1: Sub-Tasks Not Created

**Symptom:** No sub-tasks in database

**Solution:**
1. Create a parent task
2. Open task detail
3. Tap "Add Sub-task"
4. Wait for sync
5. Check database

### Issue 2: parent_id is NULL

**Symptom:** Sub-tasks exist but parent_id is null

**Solution:**
- Check ItemRepository.createSubTask() - should set parentId
- Check sync code - should include 'parent_id' in data
- Verify Supabase schema allows parent_id

### Issue 3: Query Returns 0 Results

**Symptom:** Logs show "Fetched 0 sub-tasks"

**Possible Causes:**
1. No sub-tasks exist for those parents
2. Query syntax issue with `.inFilter()`
3. Parent IDs don't match

**Solution:**
- Run SQL query manually to verify sub-tasks exist
- Check if parent IDs in logs match database
- Try alternative query syntax (see below)

### Issue 4: Sub-Tasks Not Syncing to User B

**Symptom:** User A sees sub-tasks, User B doesn't

**Solution:**
1. Verify parent is shared with User B
2. Check User B's sync logs
3. Verify sub-task fetching code is executing
4. Check RealtimeService for parent-child check

---

## Alternative Query Syntax

If `.inFilter()` doesn't work, try this alternative:

```dart
// Instead of:
final subTasks = await supabase
    .from('items')
    .select()
    .inFilter('parent_id', parentIds);

// Try:
final subTasks = await supabase
    .from('items')
    .select()
    .in_('parent_id', parentIds);

// Or with explicit filter:
final subTasks = await supabase
    .from('items')
    .select()
    .filter('parent_id', 'in', '(${parentIds.join(',')})');
```

---

## Testing Checklist

- [ ] Create parent task
- [ ] Add sub-task via "Add Sub-task" button
- [ ] Verify sub-task has parent_id in Isar
- [ ] Trigger sync
- [ ] Verify sub-task has parent_id in Supabase
- [ ] Share parent task with another user
- [ ] Other user triggers sync
- [ ] Check logs for sub-task fetching
- [ ] Verify other user sees sub-tasks in UI
- [ ] Create new sub-task as User A
- [ ] Verify User B sees it in real-time

---

## Next Steps

1. Run SQL queries to verify data exists
2. Check app logs during sync
3. If query returns 0, try alternative syntax
4. If still not working, add more detailed logging
5. Test with fresh data (create new parent + children)

---

## Code Locations

- **Sub-task fetching:** `lib/data/sync/sync_manager.dart` (lines ~226-260)
- **Sub-task creation:** `lib/data/repositories/item_repository.dart` (lines ~67-105)
- **Realtime check:** `lib/data/realtime/realtime_service.dart` (lines ~147-165)
- **UI:** `lib/features/task/presentation/task_detail_screen.dart` (lines ~895-912)

---

## Expected Logs (Success Case)

```
📥 Pulling from Supabase for user: user-a-id
📥 Fetched 5 owned items from Supabase
📥 Fetched 2 shared items from Supabase
   ➕ Added owned item to map: Parent Task (id: parent-123)
   ➕ Added shared item to map: Shared Note (id: note-456)
📊 Total unique items after deduplication: 7
🔍 ========== SUB-TASK FETCHING START ==========
🔍 Items in map before sub-task fetch: 7
🔍 Item IDs that could be parents: [parent-123, note-456, ...]
🔍 Fetching sub-tasks for 7 parent items...
🔍 Parent IDs: [parent-123, note-456, ...]
📥 Fetched 3 sub-tasks from Supabase
   📄 Found sub-task: "Sub-task 1" (id: child-1, parent: parent-123)
   ➕ Added sub-task to map
   📄 Found sub-task: "Sub-task 2" (id: child-2, parent: parent-123)
   ➕ Added sub-task to map
   📄 Found sub-task: "Sub-task 3" (id: child-3, parent: parent-123)
   ➕ Added sub-task to map
🔍 Items in map after sub-task fetch: 10
🔍 ========== SUB-TASK FETCHING END ==========
📊 Total unique items after deduplication: 10 (owned: 5, shared: 2)
```

---

## Summary

The implementation is complete, but we need to verify:
1. Sub-tasks are being created with parent_id
2. Sub-tasks are syncing to Supabase
3. The query is returning results
4. Shared users are receiving sub-tasks

Use this guide to systematically debug the issue!
