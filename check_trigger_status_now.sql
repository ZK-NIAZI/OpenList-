-- Check if trigger exists
SELECT 
  'Trigger Status:' as check_type,
  tgname as name,
  CASE tgenabled
    WHEN 'O' THEN '✅ ENABLED'
    WHEN 'D' THEN '❌ DISABLED'
    ELSE '⚠️  UNKNOWN'
  END as status
FROM pg_trigger
WHERE tgname = 'trigger_notify_on_block_edit'
AND tgisinternal = false;

-- Check if function exists
SELECT 
  'Function Status:' as check_type,
  proname as name,
  '✅ EXISTS' as status
FROM pg_proc
WHERE proname = 'notify_on_block_edit';

-- Check recent block updates
SELECT 
  'Recent Block Updates:' as check_type,
  id,
  item_id,
  content,
  updated_at
FROM blocks
WHERE item_id = '1d84b9ae-f02c-48b8-a3a7-13881407f538'
ORDER BY updated_at DESC
LIMIT 5;

-- Check if any notifications exist at all
SELECT 
  'All Notifications:' as check_type,
  COUNT(*) as total_count
FROM notifications;

-- Check item_shares for this item
SELECT 
  'Item Shares:' as check_type,
  user_id,
  permission
FROM item_shares
WHERE item_id = '1d84b9ae-f02c-48b8-a3a7-13881407f538';
