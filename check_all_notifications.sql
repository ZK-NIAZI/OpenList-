-- Check all notifications in the database
SELECT 
  n.id,
  n.user_id,
  u.email as user_email,
  n.type,
  n.title,
  n.message,
  n.item_id,
  i.title as item_title,
  n.related_user_id,
  ru.email as related_user_email,
  n.is_read,
  n.created_at,
  n.updated_at
FROM notifications n
LEFT JOIN auth.users u ON u.id = n.user_id
LEFT JOIN items i ON i.id = n.item_id
LEFT JOIN auth.users ru ON ru.id = n.related_user_id
ORDER BY n.created_at DESC
LIMIT 20;

-- Count notifications by type
SELECT 
  type,
  COUNT(*) as count,
  SUM(CASE WHEN is_read THEN 0 ELSE 1 END) as unread_count
FROM notifications
GROUP BY type;
