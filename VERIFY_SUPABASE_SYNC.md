# How to Verify Supabase Sync

## Current Status
- ✅ **Isar (Local DB)**: Working perfectly - all data saves locally
- ✅ **Sync Manager**: Running and monitoring connectivity
- ⚠️ **Supabase Sync**: Enabled but needs tables created first

## Step 1: Create Supabase Tables

1. Go to your Supabase project dashboard: https://supabase.com/dashboard
2. Navigate to **SQL Editor**
3. Copy the contents of `supabase_schema.sql`
4. Paste and run the SQL script
5. Verify tables are created in **Table Editor**:
   - `items` table
   - `blocks` table

## Step 2: Test the App

### Test Offline-First (Isar)
1. Turn off WiFi/mobile data
2. Open the app
3. Create a task via Quick Add
4. Check console logs:
   ```
   ✅ Item saved to Isar (offline-first): [task name]
   📴 Offline - changes will sync when online
   ```
5. Task should appear on dashboard immediately

### Test Sync to Supabase
1. Turn WiFi/mobile data back on
2. Check console logs:
   ```
   📡 Connectivity changed: ONLINE
   ✅ Back online! Syncing pending changes...
   🔄 Starting sync cycle...
   📥 Pulling from Supabase...
   📤 Pushing X pending items to Supabase...
   ✅ Synced to Supabase: [task name]
   ✅ Sync cycle completed successfully
   ```

### Verify in Supabase Dashboard
1. Go to **Table Editor** → **items** table
2. You should see your tasks with:
   - `id` (UUID)
   - `title`
   - `type` (task/note)
   - `is_completed`
   - `created_by` (your user ID)
   - `created_at`, `updated_at`

## Step 3: Test Real-Time Sync

### Create Task Online
1. Ensure you're online
2. Create a task via Quick Add
3. Console should show:
   ```
   ✅ Item saved to Isar (offline-first): [task name]
   🔄 Starting sync cycle...
   ✅ Synced to Supabase: [task name]
   ```
4. Check Supabase dashboard - task should appear within seconds

### Edit Task
1. Open a task detail page
2. Edit the title
3. Leave the page (auto-save triggers)
4. Console should show:
   ```
   ✅ Item updated in Isar: [new title]
   🔄 Starting sync cycle...
   ✅ Synced to Supabase: [new title]
   ```
5. Refresh Supabase dashboard - title should be updated

### Toggle Complete
1. Toggle a task complete on dashboard
2. Console should show:
   ```
   ✅ Item toggled: [task name] - true
   🔄 Starting sync cycle...
   ✅ Synced to Supabase: [task name]
   ```
3. Check Supabase - `is_completed` should be `true`

## Common Issues

### "relation 'items' does not exist"
- **Cause**: Supabase tables not created yet
- **Fix**: Run `supabase_schema.sql` in Supabase SQL Editor

### "Not authenticated, skipping push"
- **Cause**: User not logged in
- **Fix**: Ensure you're logged in via the auth flow

### "Failed to sync item: ..."
- **Cause**: Network error or RLS policy issue
- **Fix**: Check console for detailed error message

## Monitoring Sync Status

### In Console
Watch for these key logs:
- `📡 Connectivity changed: ONLINE/OFFLINE`
- `🔄 Starting sync cycle...`
- `📤 Pushing X pending items...`
- `✅ Synced to Supabase: [task name]`
- `❌ Failed to sync item: [error]`

### In Supabase Dashboard
1. Go to **Table Editor** → **items**
2. Sort by `updated_at` descending
3. Recent changes should appear at the top
4. Check `created_by` matches your user ID

### In App
- Tasks created offline will have a sync indicator (if you add the SyncStatusDot widget)
- Once synced, the indicator changes color
- All changes are instant in the UI (Isar streams)

## Architecture Summary

```
User Action (Create/Edit Task)
    ↓
1. Write to Isar (instant, offline-first)
    ↓
2. Mark as SyncStatus.pending
    ↓
3. UI updates immediately (Isar stream)
    ↓
4. SyncManager detects pending items
    ↓
5. If online → Push to Supabase
    ↓
6. Mark as SyncStatus.synced
    ↓
7. If offline → Wait for connectivity
    ↓
8. When online → Auto-sync pending items
```

## Next Steps

After verifying sync works:
1. Implement conflict resolution (if same item edited on multiple devices)
2. Add sync status indicators in UI
3. Implement pull sync (fetch remote changes)
4. Add blocks sync (for task detail content)
5. Add real-time subscriptions (Supabase Realtime)
