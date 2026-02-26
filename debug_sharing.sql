-- Debug Sharing Issues
-- Run these queries in Supabase SQL Editor to diagnose sharing problems

-- 1. Check if item_shares table exists and has data
SELECT COUNT(*) as total_shares FROM item_shares;

-- 2. See all shares
SELECT 
  id,
  item_id,
  user_id,
  permission,
  shared_by,
  created_at
FROM item_shares
ORDER BY created_at DESC
LIMIT 10;

-- 3. Check if items exist
SELECT COUNT(*) as total_items FROM items;

-- 4. See recent items
SELECT 
  id,
  title,
  created_by,
  created_at
FROM items
ORDER BY created_at DESC
LIMIT 10;

-- 5. Check RLS policies for item_shares
SELECT 
  schemaname,
  tablename,
  policyname,
  cmd
FROM pg_policies 
WHERE tablename = 'item_shares'
ORDER BY policyname;

-- 6. Check RLS policies for items (SELECT)
SELECT 
  schemaname,
  tablename,
  policyname,
  cmd
FROM pg_policies 
WHERE tablename = 'items'
AND cmd = 'SELECT'
ORDER BY policyname;

-- 7. Get current user ID (run this while logged in as the user)
SELECT auth.uid() as current_user_id;

-- 8. Check if user can see their shares (replace with actual user_id)
-- SELECT * FROM item_shares WHERE user_id = 'YOUR_USER_ID_HERE';

-- 9. Test if user can see shared items (replace with actual user_id)
-- SELECT i.* 
-- FROM items i
-- JOIN item_shares s ON s.item_id = i.id
-- WHERE s.user_id = 'YOUR_USER_ID_HERE';
