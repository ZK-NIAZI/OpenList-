-- ============================================
-- TEST DELETE NOTIFICATION TRIGGER
-- ============================================

-- Check if the delete trigger exists and is enabled
SELECT 
  'Delete Trigger Status' as check_type,
  tgname as trigger_name,
  CASE tgenabled
    WHEN 'O' THEN '✅ enabled'
    WHEN 'D' THEN '❌ disabled'
    ELSE '⚠️ other'
  END as status,
  tgrelid::regclass as table_name,
  CASE 
    WHEN tgtype & 2 = 2 THEN 'BEFORE'
    WHEN tgtype & 4 = 4 THEN 'AFTER'
    ELSE 'INSTEAD OF'
  END as timing
FROM pg_trigger
WHERE tgname = 'trigger_notify_on_item_delete'
AND tgisinternal = false;

-- Check recent notifications to see if any delete notifications were created
SELECT 
  'Recent Delete Notifications' as check_type,
  type,
  title,
  message,
  created_at
FROM notifications
WHERE type = 'unshare'
ORDER BY created_at DESC
LIMIT 5;

-- Show the trigger function definition
SELECT 
  'Trigger Function' as check_type,
  pg_get_functiondef(oid) as function_definition
FROM pg_proc
WHERE proname = 'notify_on_item_delete';
