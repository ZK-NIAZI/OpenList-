-- ============================================
-- DEBUG ALL CURRENT ISSUES
-- ============================================

-- 1. Check if share notification trigger exists and is enabled
SELECT 
  'Share Trigger Status' as check_type,
  tgname as trigger_name,
  CASE tgenabled
    WHEN 'O' THEN 'enabled'
    WHEN 'D' THEN 'disabled'
    ELSE 'other'
  END as status
FROM pg_trigger
WHERE tgname = 'trigger_notify_on_share'
AND tgisinternal = false;

-- 2. Check recent notifications to see what's being created
SELECT 
  'Recent Notifications' as check_type,
  type,
  title,
  message,
  created_at,
  NOW() - created_at as age
FROM notifications
ORDER BY created_at DESC
LIMIT 5;

-- 3. Check if there are any RLS policies blocking deletes
SELECT 
  'Delete Policies' as check_type,
  schemaname,
  tablename,
  policyname,
  cmd,
  qual
FROM pg_policies
WHERE tablename IN ('items', 'blocks')
AND cmd = 'DELETE';

-- 4. Test if we can manually create a share notification
DO $$
DECLARE
  test_user_id UUID;
  test_item_id UUID;
BEGIN
  -- Get a real user ID
  SELECT id INTO test_user_id FROM auth.users LIMIT 1;
  
  -- Get a real item ID
  SELECT id INTO test_item_id FROM items LIMIT 1;
  
  IF test_user_id IS NOT NULL AND test_item_id IS NOT NULL THEN
    RAISE NOTICE 'Testing notification creation with user % and item %', test_user_id, test_item_id;
    
    -- Try to insert a test notification
    INSERT INTO notifications (user_id, type, title, message, item_id)
    VALUES (
      test_user_id,
      'share',
      'Test notification',
      'This is a test',
      test_item_id
    );
    
    RAISE NOTICE '✅ Test notification created successfully';
    
    -- Clean up
    DELETE FROM notifications WHERE title = 'Test notification';
  ELSE
    RAISE NOTICE '⚠️ No users or items found for testing';
  END IF;
END $$;
