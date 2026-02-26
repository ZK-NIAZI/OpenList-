-- Check notifications in database
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
LIMIT 20;

-- Check notification count per user
SELECT 
  user_id,
  COUNT(*) as total_notifications,
  SUM(CASE WHEN is_read THEN 0 ELSE 1 END) as unread_count
FROM notifications
GROUP BY user_id;

-- Check if triggers are enabled
SELECT 
  tgname as trigger_name,
  CASE tgenabled
    WHEN 'O' THEN 'enabled'
    WHEN 'D' THEN 'disabled'
    WHEN 'R' THEN 'replica'
    WHEN 'A' THEN 'always'
    ELSE 'unknown'
  END as status,
  tgrelid::regclass as table_name
FROM pg_trigger
WHERE tgname LIKE '%notify%'
AND tgisinternal = false
ORDER BY tgrelid::regclass, tgname;
