-- ============================================
-- TEST NOTIFICATIONS SYSTEM
-- ============================================

-- Step 1: Check if all triggers exist
SELECT 
  '=== INSTALLED TRIGGERS ===' as info;

SELECT 
  trigger_name,
  event_manipulation as event,
  event_object_table as table_name
FROM information_schema.triggers 
WHERE trigger_schema = 'public' 
AND trigger_name LIKE '%notify%'
ORDER BY event_object_table, trigger_name;

-- Step 2: Check all notifications
SELECT 
  '=== ALL NOTIFICATIONS ===' as info;

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
ORDER BY created_at DESC;

-- Step 3: Check item_shares (to see what's shared)
SELECT 
  '=== ITEM SHARES ===' as info;

SELECT 
  id,
  item_id,
  user_id,
  permission,
  shared_by,
  created_at
FROM item_shares
ORDER BY created_at DESC;

-- Step 4: Check items (to see what exists)
SELECT 
  '=== ITEMS ===' as info;

SELECT 
  id,
  title,
  type,
  created_by,
  updated_at
FROM items
ORDER BY updated_at DESC
LIMIT 10;

-- Step 5: Test if triggers are enabled
SELECT 
  '=== TRIGGER STATUS ===' as info;

SELECT 
  tgname as trigger_name,
  tgenabled as enabled,
  tgrelid::regclass as table_name
FROM pg_trigger
WHERE tgname LIKE '%notify%'
AND tgisinternal = false;
