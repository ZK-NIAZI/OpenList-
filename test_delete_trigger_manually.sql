-- ============================================
-- MANUALLY TEST DELETE TRIGGER
-- Run this in Supabase SQL Editor
-- ============================================

-- Step 1: Check if trigger exists and is enabled
SELECT 
  'Trigger Status' as check_type,
  tgname as trigger_name,
  CASE tgenabled
    WHEN 'O' THEN '✅ ENABLED'
    WHEN 'D' THEN '❌ DISABLED'
    ELSE '⚠️ OTHER: ' || tgenabled
  END as status
FROM pg_trigger
WHERE tgname = 'trigger_notify_on_item_delete'
AND tgisinternal = false;

-- Step 2: Check if function exists
SELECT 
  'Function Exists' as check_type,
  CASE 
    WHEN COUNT(*) > 0 THEN '✅ YES'
    ELSE '❌ NO'
  END as status
FROM pg_proc
WHERE proname = 'notify_on_item_delete';

-- Step 3: Check current user (this is who will be used in auth.uid())
SELECT 
  'Current User' as check_type,
  auth.uid() as user_id,
  auth.email() as email;

-- Step 4: Create a test item and share it
DO $$
DECLARE
  v_test_item_id UUID;
  v_current_user UUID;
  v_other_user UUID;
BEGIN
  v_current_user := auth.uid();
  
  -- Get another user to share with (first user that's not current user)
  SELECT id INTO v_other_user 
  FROM auth.users 
  WHERE id != v_current_user 
  LIMIT 1;
  
  IF v_other_user IS NULL THEN
    RAISE NOTICE '❌ No other user found to test with';
    RETURN;
  END IF;
  
  RAISE NOTICE 'Current user: %', v_current_user;
  RAISE NOTICE 'Other user: %', v_other_user;
  
  -- Create test item
  v_test_item_id := gen_random_uuid();
  
  INSERT INTO items (id, title, type, created_by, created_at, updated_at)
  VALUES (v_test_item_id, 'TEST DELETE TRIGGER', 'note', v_current_user, NOW(), NOW());
  
  RAISE NOTICE 'Created test item: %', v_test_item_id;
  
  -- Share it with other user
  INSERT INTO item_shares (id, item_id, user_id, permission, shared_by, shared_at, created_at, updated_at)
  VALUES (gen_random_uuid(), v_test_item_id, v_other_user, 'view', v_current_user, NOW(), NOW(), NOW());
  
  RAISE NOTICE 'Shared item with user: %', v_other_user;
  
  -- Now delete the item (this should trigger the notification)
  DELETE FROM items WHERE id = v_test_item_id;
  
  RAISE NOTICE 'Deleted item - trigger should have fired';
  
  -- Check if notification was created
  IF EXISTS (SELECT 1 FROM notifications WHERE item_id = v_test_item_id) THEN
    RAISE NOTICE '✅ SUCCESS! Delete notification was created';
  ELSE
    RAISE NOTICE '❌ FAILED! No delete notification was created';
  END IF;
  
  -- Clean up
  DELETE FROM notifications WHERE item_id = v_test_item_id;
  DELETE FROM item_shares WHERE item_id = v_test_item_id;
  
  RAISE NOTICE 'Cleanup complete';
END $$;

-- Step 5: Check Supabase logs
SELECT '
🔍 NEXT STEPS:
1. Check the output above for any errors
2. Go to Supabase Dashboard > Logs
3. Look for "DELETE TRIGGER FIRED" messages
4. If no messages, the trigger is not firing
5. If you see errors, that tells us what is wrong
' as instructions;
