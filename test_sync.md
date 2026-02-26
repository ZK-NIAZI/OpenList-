# Quick Sync Test Guide

## Before Testing
1. Run `supabase_schema.sql` in your Supabase SQL Editor
2. Make sure you're logged in to the app
3. Open the app console to see logs

## Test 1: Create Task (Online)
**Steps:**
1. Ensure WiFi is ON
2. Open sidebar → Quick Add
3. Type "Test Task 1" → Add Task
4. Watch console logs

**Expected Console Output:**
```
✅ Item saved to Isar (offline-first): Test Task 1
🔄 Starting sync cycle...
📥 Pulling from Supabase...
📤 Pushing 1 pending items to Supabase...
✅ Synced to Supabase: Test Task 1
✅ Sync cycle completed successfully
```

**Verify:**
- Task appears on dashboard immediately
- Go to Supabase → Table Editor → items
- You should see "Test Task 1" with your user ID

---

## Test 2: Create Task (Offline)
**Steps:**
1. Turn OFF WiFi
2. Open sidebar → Quick Add
3. Type "Offline Task" → Add Task
4. Watch console logs

**Expected Console Output:**
```
✅ Item saved to Isar (offline-first): Offline Task
📴 Offline - changes will sync when online
```

**Verify:**
- Task appears on dashboard immediately (from Isar)
- Supabase dashboard shows NO new task yet

---

## Test 3: Go Online (Auto-Sync)
**Steps:**
1. Turn WiFi back ON
2. Wait a few seconds
3. Watch console logs

**Expected Console Output:**
```
📡 Connectivity changed: ONLINE
✅ Back online! Syncing pending changes...
🔄 Starting sync cycle...
📥 Pulling from Supabase...
📤 Pushing 1 pending items to Supabase...
✅ Synced to Supabase: Offline Task
✅ Sync cycle completed successfully
```

**Verify:**
- Refresh Supabase dashboard
- "Offline Task" should now appear

---

## Test 4: Edit Task
**Steps:**
1. Ensure WiFi is ON
2. Click on "Test Task 1" from dashboard
3. Change title to "Updated Task 1"
4. Press back button (auto-save triggers)
5. Watch console logs

**Expected Console Output:**
```
✅ Item updated in Isar: Updated Task 1
🔄 Starting sync cycle...
✅ Synced to Supabase: Updated Task 1
```

**Verify:**
- Dashboard shows "Updated Task 1"
- Supabase dashboard shows updated title

---

## Test 5: Toggle Complete
**Steps:**
1. On dashboard, tap the checkbox next to a task
2. Watch console logs

**Expected Console Output:**
```
✅ Item toggled: Test Task 1 - true
🔄 Starting sync cycle...
✅ Synced to Supabase: Test Task 1
```

**Verify:**
- Task shows as completed (strikethrough)
- Supabase: `is_completed` = true

---

## Troubleshooting

### No sync logs appearing
- Check if SyncManager is started in `main.dart`
- Verify you're logged in (check auth status)

### "relation 'items' does not exist"
- Run `supabase_schema.sql` in Supabase SQL Editor

### "Not authenticated, skipping push"
- Log out and log back in
- Check Supabase auth settings

### Tasks not appearing in Supabase
- Check console for error messages
- Verify RLS policies are set up correctly
- Check if `created_by` matches your user ID

---

## Success Criteria
✅ Tasks save to Isar instantly (offline-first)
✅ Tasks sync to Supabase when online
✅ Offline tasks sync automatically when back online
✅ Edits sync to Supabase
✅ Toggle complete syncs to Supabase
✅ Console logs show sync status clearly
