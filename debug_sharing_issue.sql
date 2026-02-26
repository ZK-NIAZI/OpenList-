-- Debug script to check sharing setup
-- Run this in Supabase SQL Editor to see what's happening

-- 1. Check all users in auth.users
SELECT 
  id as user_id,
  email,
  created_at
FROM auth.users
ORDER BY created_at DESC;

-- 2. Check all items
SELECT 
  id as item_id,
  title,
  type,
  created_by,
  created_at
FROM items
ORDER BY created_at DESC
LIMIT 10;

-- 3. Check all item_shares
SELECT 
  id as share_id,
  item_id,
  user_id,
  permission,
  shared_by,
  created_at
FROM item_shares
ORDER BY created_at DESC;

-- 4. Check if the RPC function exists
SELECT routine_name, routine_definition
FROM information_schema.routines
WHERE routine_name = 'get_user_id_by_email';

-- 5. Test the RPC function with your second account email
-- REPLACE 'second@email.com' with your actual second account email
SELECT get_user_id_by_email('second@email.com');

-- 6. Check RLS policies on items table
SELECT 
  schemaname,
  tablename,
  policyname,
  permissive,
  roles,
  cmd,
  qual,
  with_check
FROM pg_policies
WHERE tablename = 'items';

-- 7. Check RLS policies on item_shares table
SELECT 
  schemaname,
  tablename,
  policyname,
  permissive,
  roles,
  cmd,
  qual,
  with_check
FROM pg_policies
WHERE tablename = 'item_shares';
