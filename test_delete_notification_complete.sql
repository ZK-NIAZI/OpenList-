-- ============================================
-- COMPLETE DELETE NOTIFICATION TEST
-- This will show you EXACTLY what's happening
-- ============================================

-- Step 1: Check current state
SELECT '=== STEP 1: CURRENT STATE ===' as step;

SELECT 
  'Items' as table_name,
  id,
  title,
  created_by as owner
FROM items
ORDER BY created_at DESC
LIMIT 5;

SELECT 
  'Item Shares' as table_name,
  item_id,
  user_id as shared_with,
  permission
FROM item_shares
ORDER BY created_at DESC
LIMIT 5;

SELECT 
  'Recent Notifications' as table_name,
  type,
  title,
  message,
  created_at
FROM notifications
ORDER BY created_at DESC
LIMIT 5;

-- Step 2: Get current user info
SELECT '=== STEP 2: CURRENT USER ===' as step;

SELECT 
  auth.uid() as current_user_id,
  auth.email() as current_user_email;

-- Step 3: Create test scenario
SELECT '=== STEP 3: CREATING TEST SCENARIO ===' as step;

DO $$
DECLARE
  v_item_id UUID;
  v_user1_id UUID;
  v_user2_id UUID;
  v_share_count INT;
  v_notification_count INT;
BEGIN
  -- Get two users
  SELECT id INTO v_user1_id FROM auth.users ORDER BY created_at LIMIT 1;
  SELECT id INTO v_user2_id FROM auth.users WHERE id != v_user1_id ORDER BY created_at LIMIT 1;
  
  IF v_user2_id IS NULL THEN
    RAISE NOTICE 'ERROR: Need at least 2 users in the system';
    RAISE NOTICE 'Current users:';
    FOR v_user1_id IN SELECT id FROM auth.users LOOP
      RAISE NOTICE '  - %', v_user1_id;
    END LOOP;
    RETURN;
  END IF;
  
  RAISE NOTICE 'User 1 (owner): %', v_user1_id;
  RAISE NOTICE 'User 2 (shared with): %', v_user2_id;
  
  -- Create test item owned by user1
  v_item_id := gen_random_uuid();
  
  INSERT INTO items (id, title, type, created_by, created_at, updated_at)
  VALUES (v_item_id, 'TEST DELETE NOTIFICATION', 'note', v_user1_id, NOW(), NOW());
  
  RAISE NOTICE 'Created item: % (owner: %)', v_item_id, v_user1_id;
  
  -- Share it with user2
  INSERT INTO item_shares (id, item_id, user_id, permission, shared_by, shared_at, created_at, updated_at)
  VALUES (gen_random_uuid(), v_item_id, v_user2_id, 'view', v_user1_id, NOW(), NOW(), NOW());
  
  RAISE NOTICE 'Shared item with user: %', v_user2_id;
  
  -- Verify share exists
  SELECT COUNT(*) INTO v_share_count
  FROM item_shares
  WHERE item_id = v_item_id;
  
  RAISE NOTICE 'Share count before delete: %', v_share_count;
  
  -- Now simulate what your Flutter app does
  RAISE NOTICE '--- SIMULATING FLUTTER APP DELETE ---';
  
  -- Delete blocks (none in this test)
  RAISE NOTICE 'Step 1: Delete blocks';
  DELETE FROM blocks WHERE item_id = v_item_id;
  
  -- Check if shares still exist
  SELECT COUNT(*) INTO v_share_count
  FROM item_shares
  WHERE item_id = v_item_id;
  RAISE NOTICE 'Shares still exist: %', v_share_count;
  
  -- Delete the item (trigger should fire HERE)
  RAISE NOTICE 'Step 2: Delete item (trigger fires now)';
  DELETE FROM items WHERE id = v_item_id;
  
  -- Check if notification was created
  SELECT COUNT(*) INTO v_notification_count
  FROM notifications
  WHERE item_id = v_item_id;
  
  IF v_notification_count > 0 THEN
    RAISE NOTICE '✅ SUCCESS! Notification was created';
    RAISE NOTICE 'Notification count: %', v_notification_count;
    
    -- Show the notification
    FOR v_share_count IN 
      SELECT 1 FROM notifications WHERE item_id = v_item_id
    LOOP
      RAISE NOTICE 'Notification details:';
      RAISE NOTICE '  Type: %', (SELECT type FROM notifications WHERE item_id = v_item_id LIMIT 1);
      RAISE NOTICE '  Title: %', (SELECT title FROM notifications WHERE item_id = v_item_id LIMIT 1);
      RAISE NOTICE '  Message: %', (SELECT message FROM notifications WHERE item_id = v_item_id LIMIT 1);
      RAISE NOTICE '  User: %', (SELECT user_id FROM notifications WHERE item_id = v_item_id LIMIT 1);
    END LOOP;
  ELSE
    RAISE NOTICE '❌ FAILED! No notification was created';
    RAISE NOTICE 'Checking why...';
    
    -- Check if trigger exists
    SELECT COUNT(*) INTO v_share_count
    FROM pg_trigger
    WHERE tgname = 'trigger_notify_on_item_delete';
    
    IF v_share_count = 0 THEN
      RAISE NOTICE '  - Trigger does not exist!';
    ELSE
      RAISE NOTICE '  - Trigger exists';
    END IF;
    
    -- Check if auth.uid() returns NULL
    IF auth.uid() IS NULL THEN
      RAISE NOTICE '  - auth.uid() is NULL (this is the problem!)';
    ELSE
      RAISE NOTICE '  - auth.uid() is: %', auth.uid();
    END IF;
  END IF;
  
  -- Delete item_shares (cleanup)
  RAISE NOTICE 'Step 3: Delete item_shares';
  DELETE FROM item_shares WHERE item_id = v_item_id;
  
  -- Clean up notifications
  DELETE FROM notifications WHERE item_id = v_item_id;
  
  RAISE NOTICE '--- TEST COMPLETE ---';
END $$;

-- Step 4: Check Supabase logs
SELECT '
=== STEP 4: NEXT STEPS ===

1. Look at the output above
2. Check if notification was created
3. Go to Supabase Dashboard > Logs
4. Look for messages starting with "DELETE TRIGGER FIRED"
5. Check if auth.uid() is NULL

If auth.uid() is NULL:
  - Run fix_delete_trigger_auth_issue.sql
  - It adds fallback to use created_by

If trigger does not exist:
  - Run fix_all_current_issues.sql

If notification was created:
  - The trigger works! Problem is in your test
  - Make sure you are deleting an item that is SHARED with another user
' as instructions;
