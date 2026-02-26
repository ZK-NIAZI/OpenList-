-- Check if sub-tasks exist in the database
-- Run this in Supabase SQL Editor to verify sub-tasks are being created

-- 1. Check all items with parent_id (sub-tasks)
SELECT 
  id,
  title,
  parent_id,
  created_by,
  created_at
FROM items
WHERE parent_id IS NOT NULL
ORDER BY created_at DESC;

-- 2. Check parent-child relationships
SELECT 
  p.id as parent_id,
  p.title as parent_title,
  c.id as child_id,
  c.title as child_title,
  c.created_by as child_creator
FROM items p
INNER JOIN items c ON c.parent_id = p.id
ORDER BY p.title, c.title;

-- 3. Check if shared items have sub-tasks
SELECT 
  s.item_id as shared_parent_id,
  i.title as shared_parent_title,
  s.user_id as shared_with_user,
  COUNT(c.id) as subtask_count
FROM item_shares s
INNER JOIN items i ON i.id = s.item_id
LEFT JOIN items c ON c.parent_id = s.item_id
GROUP BY s.item_id, i.title, s.user_id
HAVING COUNT(c.id) > 0;

-- 4. Check specific user's access to sub-tasks
-- First, get your user ID:
SELECT id, email FROM auth.users ORDER BY created_at DESC LIMIT 5;

-- Then uncomment and run this query, replacing YOUR_USER_ID with actual UUID:
/*
SELECT 
  i.id,
  i.title,
  i.parent_id,
  i.created_by,
  CASE 
    WHEN i.created_by = 'YOUR_USER_ID' THEN 'Owned'
    WHEN EXISTS (SELECT 1 FROM item_shares WHERE item_id = i.id AND user_id = 'YOUR_USER_ID') THEN 'Directly Shared'
    WHEN EXISTS (SELECT 1 FROM item_shares WHERE item_id = i.parent_id AND user_id = 'YOUR_USER_ID') THEN 'Parent Shared'
    ELSE 'No Access'
  END as access_type
FROM items i
WHERE parent_id IS NOT NULL
ORDER BY i.created_at DESC;
*/
