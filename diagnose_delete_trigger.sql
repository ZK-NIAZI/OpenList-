-- ============================================
-- DIAGNOSE DELETE TRIGGER ISSUE
-- Run this to find out WHY delete notifications aren't working
-- ============================================

-- Step 1: Verify trigger exists and is enabled
SELECT 
  '1️⃣ TRIGGER STATUS' as step,
  tgname as trigger_name,
  CASE tgenabled
    WHEN 'O' THEN '✅ ENABLED'
    WHEN 'D' THEN '❌ DISABLED'
    ELSE '⚠️ UNKNOWN: ' || tgenabled
  END as status,
  pg_get_triggerdef(oid) as definition
FROM pg_trigger
WHERE tgname = 'trigger_notify_on_item_delete'
AND tgisinternal = false;

-- Step 2: Check if function exists
SELECT 
  '2️⃣ FUNCTION EXISTS' as step,
  proname as function_name,
  prosrc as source_code
FROM pg_proc
WHERE proname = 'notify_on_item_delete';

-- Step 3: Check current items and their shares
SELECT 
  '3️⃣ CURRENT ITEMS & SHARES' as step,
  i.id as item_id,
  i.title,
  i.created_by as owner_id,
  COUNT(s.id) as share_count,
  STRING_AGG(s.user_id::text, ', ') as shared_with_users
FROM items i
LEFT JOIN item_shares s ON s.item_id = i.id
GROUP BY i.id, i.title, i.created_by
ORDER BY i.created_at DESC
LIMIT 5;

-- Step 4: Check recent notifications
SELECT 
  '4️⃣ RECENT NOTIFICATIONS' as step,
  type,
  title,
  message,
  item_id,
  created_at
FROM notifications
ORDER BY created_at DESC
LIMIT 10;

-- Step 5: Test trigger manually with a real scenario
DO $$
DECLARE
  v_test_item_id UUID;
  v_current_user UUID;
  v_share_user UUID;
  v_notification_count INT;
BEGIN
  RAISE NOTICE '========================================';
  RAISE NOTICE '5️⃣ MANUAL TRIGGER TEST';
  RAISE NOTICE '========================================';
  
  -- Get current user
  v_current_user := auth.uid();
  RAISE NOTICE 'Current user: %', v_current_user;
  
  IF v_current_user IS NULL THEN
    RAISE NOTICE '❌ ERROR: No authenticated user (auth.uid() is NULL)';
    RAISE NOTICE '   This means you are not logged in to Supabase';
    RAISE NOTICE '   The trigger needs auth.uid() to work';
    RETURN;
  END IF;
  
  -- Find another user to share with
  SELECT id INTO v_share_user
  FROM auth.users
  WHERE id != v_current_user
  LIMIT 1;
  
  IF v_share_user IS NULL THEN
    RAISE NOTICE '❌ ERROR: No other user found to test with';
    RAISE NOTICE '   You need at least 2 users in the system';
    RETURN;
  END IF;
  
  RAISE NOTICE 'Share user: %', v_share_user;
  
  -- Create test item
  v_test_item_id := gen_random_uuid();
  
  INSERT INTO items (id, title, type, created_by, created_at, updated_at)
  VALUES (v_test_item_id, 'TEST DELETE NOTIFICATION', 'note', v_current_user, NOW(), NOW());
  
  RAISE NOTICE '✅ Created test item: %', v_test_item_id;
  
  -- Share it
  INSERT INTO item_shares (id, item_id, user_id, permission, shared_by, shared_at, created_at, updated_at)
  VALUES (gen_random_uuid(), v_test_item_id, v_share_user, 'view', v_current_user, NOW(), NOW(), NOW());
  
  RAISE NOTICE '✅ Shared item with user: %', v_share_user;
  
  -- Check shares exist before delete
  SELECT COUNT(*) INTO v_notification_count
  FROM item_shares
  WHERE item_id = v_test_item_id;
  
  RAISE NOTICE '📊 Shares before delete: %', v_notification_count;
  
  -- Delete the item (trigger should fire)
  RAISE NOTICE '🗑️  Deleting item now...';
  DELETE FROM items WHERE id = v_test_item_id;
  RAISE NOTICE '✅ Item deleted';
  
  -- Check if notification was created
  SELECT COUNT(*) INTO v_notification_count
  FROM notifications
  WHERE item_id = v_test_item_id;
  
  IF v_notification_count > 0 THEN
    RAISE NOTICE '✅✅✅ SUCCESS! Delete notification was created!';
    RAISE NOTICE '   Notification count: %', v_notification_count;
  ELSE
    RAISE NOTICE '❌❌❌ FAILED! No delete notification was created';
    RAISE NOTICE '   This means the trigger did not work';
  END IF;
  
  -- Show the notification if it exists
  FOR v_notification_count IN 
    SELECT 1 FROM notifications WHERE item_id = v_test_item_id
  LOOP
    RAISE NOTICE '📧 Notification details:';
    FOR v_notification_count IN 
      SELECT type, title, message FROM notifications WHERE item_id = v_test_item_id
    LOOP
      RAISE NOTICE '   Type: %', (SELECT type FROM notifications WHERE item_id = v_test_item_id LIMIT 1);
      RAISE NOTICE '   Title: %', (SELECT title FROM notifications WHERE item_id = v_test_item_id LIMIT 1);
      RAISE NOTICE '   Message: %', (SELECT message FROM notifications WHERE item_id = v_test_item_id LIMIT 1);
    END LOOP;
  END LOOP;
  
  -- Clean up
  DELETE FROM notifications WHERE item_id = v_test_item_id;
  DELETE FROM item_shares WHERE item_id = v_test_item_id;
  
  RAISE NOTICE '🧹 Cleanup complete';
  RAISE NOTICE '========================================';
END $$;

-- Step 6: Instructions
SELECT '
========================================
📋 WHAT TO DO NEXT:
========================================

1. Look at the output above, especially step 5️⃣

2. Check for these specific errors:
   ❌ "No authenticated user" = You need to be logged in
   ❌ "No other user found" = You need 2+ users
   ❌ "FAILED! No delete notification" = Trigger not working

3. Go to Supabase Dashboard > Logs
   - Look for "DELETE TRIGGER FIRED" messages
   - Look for any error messages
   - Check the timestamp matches when you ran this

4. If trigger is not firing:
   - The trigger might not be attached to the table
   - Run fix_all_current_issues.sql again
   - Check if RLS is blocking the trigger

5. If trigger fires but no notification:
   - Check the RAISE NOTICE messages in logs
   - There might be an error in the trigger code
   - The INSERT might be failing silently

========================================
' as instructions;
