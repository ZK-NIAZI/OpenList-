-- Check the most recent notifications to see what's being created
SELECT 
  id,
  user_id,
  type,
  title,
  message,
  item_id,
  created_at
FROM notifications
ORDER BY created_at DESC
LIMIT 10;
