-- Simple Sub-Tasks Check
-- Run these queries one by one in Supabase SQL Editor

-- ============================================
-- 1. CHECK IF ANY SUB-TASKS EXIST
-- ============================================
SELECT 
  id,
  title,
  parent_id,
  created_by,
  created_at
FROM items
WHERE parent_id IS NOT NULL
ORDER BY created_at DESC
LIMIT 20;

-- Expected: Should see rows with non-null parent_id
-- If empty: No sub-tasks have been created yet


-- ============================================
-- 2. COUNT SUB-TASKS
-- ============================================
SELECT 
  COUNT(*) as total_subtasks
FROM items
WHERE parent_id IS NOT NULL;

-- Expected: Number > 0 if sub-tasks exist


-- ============================================
-- 3. PARENT-CHILD RELATIONSHIPS
-- ============================================
SELECT 
  p.id as parent_id,
  p.title as parent_title,
  p.created_by as parent_creator,
  c.id as child_id,
  c.title as child_title,
  c.created_by as child_creator
FROM items p
INNER JOIN items c ON c.parent_id = p.id
ORDER BY p.title, c.title;

-- Expected: Shows parent tasks with their children
-- If empty: No parent-child relationships exist


-- ============================================
-- 4. SHARED PARENTS WITH SUB-TASKS
-- ============================================
SELECT 
  s.item_id as shared_parent_id,
  i.title as shared_parent_title,
  s.user_id as shared_with_user,
  COUNT(c.id) as subtask_count,
  STRING_AGG(c.title, ', ') as subtask_titles
FROM item_shares s
INNER JOIN items i ON i.id = s.item_id
LEFT JOIN items c ON c.parent_id = s.item_id
GROUP BY s.item_id, i.title, s.user_id
HAVING COUNT(c.id) > 0;

-- Expected: Shows shared items that have sub-tasks
-- If empty: No shared items have sub-tasks


-- ============================================
-- 5. GET YOUR USER ID
-- ============================================
SELECT 
  id as user_id,
  email,
  created_at
FROM auth.users
ORDER BY created_at DESC
LIMIT 5;

-- Copy your user_id from the results above


-- ============================================
-- 6. ALL ITEMS YOU HAVE ACCESS TO
-- (Run this after getting your user_id from query 5)
-- Replace 'YOUR_USER_ID_HERE' with actual UUID from query 5
-- ============================================
-- INSTRUCTIONS: 
-- 1. Run query 5 above to get your user_id
-- 2. Copy the UUID
-- 3. Uncomment the query below (remove /* and */)
-- 4. Replace YOUR_USER_ID_HERE with your actual UUID
-- 5. Run the query
/*
SELECT 
  i.id,
  i.title,
  i.parent_id,
  i.type,
  CASE 
    WHEN i.created_by = 'YOUR_USER_ID_HERE'::uuid THEN '✅ Owned'
    WHEN EXISTS (
      SELECT 1 FROM item_shares 
      WHERE item_id = i.id 
      AND user_id = 'YOUR_USER_ID_HERE'::uuid
    ) THEN '🔗 Directly Shared'
    WHEN i.parent_id IS NOT NULL AND EXISTS (
      SELECT 1 FROM item_shares 
      WHERE item_id = i.parent_id 
      AND user_id = 'YOUR_USER_ID_HERE'::uuid
    ) THEN '👶 Parent Shared'
    ELSE '❌ No Access'
  END as access_type
FROM items i
ORDER BY 
  CASE 
    WHEN i.parent_id IS NULL THEN 0
    ELSE 1
  END,
  i.created_at DESC;
*/


-- ============================================
-- 7. QUICK DIAGNOSTIC
-- ============================================
SELECT 
  'Total Items' as metric,
  COUNT(*)::text as value
FROM items
UNION ALL
SELECT 
  'Items with parent_id (sub-tasks)',
  COUNT(*)::text
FROM items
WHERE parent_id IS NOT NULL
UNION ALL
SELECT 
  'Parent items (have children)',
  COUNT(DISTINCT parent_id)::text
FROM items
WHERE parent_id IS NOT NULL
UNION ALL
SELECT 
  'Total shares',
  COUNT(*)::text
FROM item_shares
UNION ALL
SELECT 
  'Shared items with sub-tasks',
  COUNT(DISTINCT s.item_id)::text
FROM item_shares s
WHERE EXISTS (
  SELECT 1 FROM items c 
  WHERE c.parent_id = s.item_id
);

-- This gives you a quick overview of your data
