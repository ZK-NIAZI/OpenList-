-- Check notification messages to see if they show user names
SELECT 
  id,
  user_id,
  type,
  title,
  message,
  related_user_id,
  created_at
FROM notifications
ORDER BY created_at DESC
LIMIT 10;
