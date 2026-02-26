# Deploy Task Update Notifications

## Status
✅ Real-time sync is working (confirmed from logs)
✅ Manual notifications are working (confirmed from logs)
🆕 Need to deploy automatic notification triggers

---

## What You Need To Do

### Step 1: Run SQL Script in Supabase

1. Open Supabase Dashboard
2. Go to **SQL Editor**
3. Copy the entire content of `setup_task_update_notifications.sql`
4. Paste and click **Run**

This will create:
- `notify_item_update()` function - Sends notifications when task title, completion, or due date changes
- `item_update_notification` trigger - Automatically calls the function on item updates
- `notify_block_update()` function - Sends notifications when block content changes
- `block_update_notification` trigger - Automatically calls the function on block updates

---

## Step 2: Verify Triggers Are Active

Run this query in Supabase SQL Editor:

```sql
SELECT 
  trigger_name,
  event_manipulation,
  event_object_table,
  action_statement
FROM information_schema.triggers
WHERE trigger_name IN ('item_update_notification', 'block_update_notification')
ORDER BY event_object_table, trigger_name;
```

You should see 2 triggers:
- `item_update_notification` on `items` table
- `block_update_notification` on `blocks` table

---

## Step 3: Test Notifications

### Test 1: Task Title Update
1. Open app on Account A (mutaalimran2k3@gmail.com)
2. Open the shared task "shared"
3. Change the title to "shared task updated"
4. Switch to Account B (fahadraza6512@gmail.com)
5. Check Alerts screen - should see: "mutaalimran2k3 updated the title of 'shared task updated'"

### Test 2: Task Completion
1. On Account A, mark the task as complete
2. On Account B, check Alerts - should see: "mutaalimran2k3 completed 'shared task updated'"
3. On Account A, uncheck the task
4. On Account B, check Alerts - should see: "mutaalimran2k3 reopened 'shared task updated'"

### Test 3: Block Content Update
1. On Account A, edit the block content (change "5" to "updated content")
2. On Account B, check Alerts - should see: "mutaalimran2k3 updated content in 'shared task updated'"

---

## What's Already Working (From Logs)

✅ Block sync to Supabase:
```
I/flutter: ✅ Synced block to Supabase: heading
```

✅ Manual notification creation:
```
I/flutter: 📬 Creating notification for user d0d175fd-67e1-4b55-92a4-bf8d31d5cf20: "mutaalimran2k3 updated "shared""
I/flutter: ✅ Created edit notification for user: d0d175fd-67e1-4b55-92a4-bf8d31d5cf20
```

✅ Notification pull:
```
I/flutter: 📥 Fetched 3 notifications
I/flutter: ✅ Notifications pull completed - saved 3 notifications
```

✅ Real-time sync infrastructure is active and working

---

## Troubleshooting

### If notifications don't appear:

1. **Check if triggers are enabled**
   ```sql
   SELECT * FROM information_schema.triggers 
   WHERE trigger_name IN ('item_update_notification', 'block_update_notification');
   ```

2. **Check if notifications are being created**
   ```sql
   SELECT * FROM notifications 
   ORDER BY created_at DESC 
   LIMIT 10;
   ```

3. **Check app logs for errors**
   - Look for "📬" (notification received)
   - Look for "❌" (errors)

4. **Verify user has display_name in profiles**
   ```sql
   SELECT id, email, display_name FROM profiles;
   ```

---

## Summary

Once you run the SQL script, the system will automatically:
1. Detect when a task title, completion, or due date changes
2. Detect when block content changes
3. Send notifications to all users who have access (except the editor)
4. Show notifications in the Alerts screen via real-time sync

The infrastructure is complete and working - you just need to deploy the triggers!
