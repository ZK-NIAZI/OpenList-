-- ============================================
-- VERIFY NOTIFICATION TRIGGERS
-- ============================================
-- Run this to check which notification triggers are currently active
-- ============================================

-- Check all triggers on items and blocks tables
SELECT 
  trigger_name,
  event_manipulation as event,
  event_object_table as table_name,
  action_timing as timing,
  action_statement as function_call
FROM information_schema.triggers
WHERE event_object_table IN ('items', 'blocks', 'notifications')
ORDER BY event_object_table, trigger_name;

-- Check if notification functions exist
SELECT 
  routine_name as function_name,
  routine_type as type,
  data_type as returns
FROM information_schema.routines
WHERE routine_name LIKE '%notify%'
ORDER BY routine_name;

-- Check recent notifications (last 10)
SELECT 
  id,
  user_id,
  type,
  title,
  message,
  item_id,
  is_read,
  created_at
FROM notifications
ORDER BY created_at DESC
LIMIT 10;

-- Count notifications by type
SELECT 
  type,
  COUNT(*) as count,
  COUNT(CASE WHEN is_read THEN 1 END) as read_count,
  COUNT(CASE WHEN NOT is_read THEN 1 END) as unread_count
FROM notifications
GROUP BY type
ORDER BY count DESC;
