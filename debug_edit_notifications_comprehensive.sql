-- ============================================
-- COMPREHENSIVE DEBUG FOR EDIT NOTIFICATIONS
-- ============================================

-- STEP 1: Check if trigger exists and is enabled
SELECT '=== STEP 1: Trigger Status ===' as step;
SELECT 
  tgname as trigger_name,
  CASE tgenabled
    WHEN 'O' THEN 'enabled'
    WHEN 'D' THEN 'disabled'
    WHEN 'R' THEN 'replica'
    WHEN 'A' THEN 'always'
    ELSE 'unknown'
  END as status,
  tgrelid::regclass as table_name
FROM pg_trigger
WHERE tgname = 'trigger_notify_on_block_edit'
AND tgisinternal = false;

-- STEP 2: Check if function exists
SELECT '=== STEP 2: Function Exists ===' as step;
SELECT 
  proname as function_name,
  prosecdef as is_security_definer
FROM pg_proc
WHERE proname = 'notify_on_block_edit';

-- STEP 3: Find a shared item with blocks
SELECT '=== STEP 3: Shared Items with Blocks ===' as step;
SELECT 
  i.id as item_id,
  i.title,
  i.created_by as owner_id,
  COUNT(DISTINCT s.user_id) as share_count,
  COUNT(DISTINCT b.id) as block_count
FROM items i
LEFT JOIN item_shares s ON s.item_id = i.id
LEFT JOIN blocks b ON b.item_id = i.id
WHERE EXISTS (SELECT 1 FROM item_shares WHERE item_id = i.id)
GROUP BY i.id, i.title, i.created_by
ORDER BY i.updated_at DESC
LIMIT 5;

-- STEP 4: Show who should receive notifications for the most recent shared item
SELECT '=== STEP 4: Who Should Get Notifications ===' as step;
WITH recent_shared_item AS (
  SELECT i.id, i.title, i.created_by
  FROM items i
  WHERE EXISTS (SELECT 1 FROM item_shares WHERE item_id = i.id)
  ORDER BY i.updated_at DESC
  LIMIT 1
)
SELECT 
  'Owner' as role,
  r.created_by as user_id,
  r.title as item_title
FROM recent_shared_item r
UNION ALL
SELECT 
  'Shared with' as role,
  s.user_id,
  r.title as item_title
FROM recent_shared_item r
JOIN item_shares s ON s.item_id = r.id;

-- STEP 5: Check existing notifications
SELECT '=== STEP 5: Existing Notifications ===' as step;
SELECT 
  n.id,
  n.type,
  n.title,
  n.message,
  n.user_id,
  n.item_id,
  n.is_read,
  n.created_at,
  i.title as item_title
FROM notifications n
LEFT JOIN items i ON i.id = n.item_id
ORDER BY n.created_at DESC
LIMIT 10;

-- STEP 6: Test trigger manually
SELECT '=== STEP 6: Manual Trigger Test ===' as step;
SELECT 'About to update a block to test trigger...' as message;

-- Find a block from a shared item
WITH test_block AS (
  SELECT b.id, b.content
  FROM blocks b
  JOIN items i ON i.id = b.item_id
  WHERE EXISTS (SELECT 1 FROM item_shares WHERE item_id = i.id)
  ORDER BY b.updated_at DESC
  LIMIT 1
)
UPDATE blocks
SET content = content || ' [TEST]',
    updated_at = NOW()
WHERE id = (SELECT id FROM test_block)
RETURNING id as updated_block_id, content as new_content;

-- STEP 7: Check if notification was created
SELECT '=== STEP 7: Check for New Notification ===' as step;
SELECT 
  n.id,
  n.type,
  n.title,
  n.message,
  n.user_id,
  n.created_at,
  i.title as item_title
FROM notifications n
LEFT JOIN items i ON i.id = n.item_id
WHERE n.created_at > NOW() - INTERVAL '1 minute'
ORDER BY n.created_at DESC;

-- STEP 8: Check Postgres logs (if you have access)
SELECT '=== STEP 8: Instructions ===' as step;
SELECT 'If no notification was created, check Supabase Dashboard > Database > Logs for RAISE NOTICE messages' as instruction;
