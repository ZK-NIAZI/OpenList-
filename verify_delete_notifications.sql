-- ============================================
-- VERIFY DELETE NOTIFICATIONS SETUP
-- Run this to check if everything is configured correctly
-- ============================================

-- Check 1: Does the delete trigger exist?
SELECT 
  '1️⃣ Delete Trigger Exists?' as check,
  CASE 
    WHEN COUNT(*) > 0 THEN '✅ YES'
    ELSE '❌ NO - Run fix_all_current_issues.sql'
  END as status
FROM pg_trigger
WHERE tgname = 'trigger_notify_on_item_delete'
AND tgisinternal = false;

-- Check 2: Is the delete trigger enabled?
SELECT 
  '2️⃣ Delete Trigger Enabled?' as check,
  CASE tgenabled
    WHEN 'O' THEN '✅ YES'
    WHEN 'D' THEN '❌ NO - Run: ALTER TABLE items ENABLE TRIGGER trigger_notify_on_item_delete;'
    ELSE '⚠️ UNKNOWN'
  END as status
FROM pg_trigger
WHERE tgname = 'trigger_notify_on_item_delete'
AND tgisinternal = false;

-- Check 3: Does the delete function exist?
SELECT 
  '3️⃣ Delete Function Exists?' as check,
  CASE 
    WHEN COUNT(*) > 0 THEN '✅ YES'
    ELSE '❌ NO - Run fix_all_current_issues.sql'
  END as status
FROM pg_proc
WHERE proname = 'notify_on_item_delete';

-- Check 4: Are RLS policies for deletion in place?
SELECT 
  '4️⃣ Delete RLS Policies?' as check,
  CASE 
    WHEN COUNT(*) >= 2 THEN '✅ YES (' || COUNT(*) || ' policies)'
    WHEN COUNT(*) = 1 THEN '⚠️ PARTIAL (only ' || COUNT(*) || ' policy)'
    ELSE '❌ NO - Run fix_all_current_issues.sql'
  END as status
FROM pg_policies
WHERE tablename = 'items'
AND policyname LIKE '%delete%';

-- Check 5: Show recent delete notifications
SELECT 
  '5️⃣ Recent Delete Notifications' as check,
  CASE 
    WHEN COUNT(*) > 0 THEN '✅ Found ' || COUNT(*) || ' delete notifications'
    ELSE '⚠️ No delete notifications yet (test by deleting a shared item)'
  END as status
FROM notifications
WHERE type = 'unshare';

-- Show the actual delete notifications if any exist
SELECT 
  '📬 Delete Notifications' as info,
  type,
  title,
  message,
  created_at,
  is_read
FROM notifications
WHERE type = 'unshare'
ORDER BY created_at DESC
LIMIT 5;

-- Summary
SELECT '
📋 SUMMARY:
- If all checks show ✅, delete notifications are ready
- If any show ❌, run fix_all_current_issues.sql
- Test by deleting a shared item and checking notifications

To test:
1. Share an item with another user
2. Delete the item
3. Check the other user receives a notification
4. Check Supabase logs for "DELETE TRIGGER FIRED"
' as summary;
