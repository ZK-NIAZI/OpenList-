-- ============================================
-- DEBUG NOTIFICATION TRIGGERS
-- ============================================

-- 1. Check if the trigger exists and is enabled
SELECT 
  tgname as trigger_name,
  CASE tgenabled
    WHEN 'O' THEN 'enabled'
    WHEN 'D' THEN 'disabled'
    WHEN 'R' THEN 'replica'
    WHEN 'A' THEN 'always'
    ELSE 'unknown'
  END as status,
  tgrelid::regclass as table_name,
  pg_get_triggerdef(oid) as trigger_definition
FROM pg_trigger
WHERE tgname IN ('trigger_notify_on_block_edit', 'trigger_notify_on_item_edit')
AND tgisinternal = false;

-- 2. Check if the function exists
SELECT 
  proname as function_name,
  pg_get_functiondef(oid) as function_definition
FROM pg_proc
WHERE proname IN ('notify_on_block_edit', 'notify_on_item_edit');

-- 3. Test the trigger manually by updating a block
-- First, let's see what blocks exist
SELECT 
  b.id as block_id,
  b.item_id,
  i.title as item_title,
  b.content,
  b.updated_at
FROM blocks b
JOIN items i ON i.id = b.item_id
ORDER BY b.updated_at DESC
LIMIT 5;

-- 4. Check notifications table
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

-- 5. Check item_shares to see who should receive notifications
SELECT 
  s.id,
  s.item_id,
  i.title as item_title,
  s.user_id,
  s.permission,
  u.email as user_email
FROM item_shares s
JOIN items i ON i.id = s.item_id
LEFT JOIN auth.users u ON u.id = s.user_id
ORDER BY s.created_at DESC;

-- 6. Check RLS policies on notifications table
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
WHERE tablename = 'notifications';
