-- ============================================
-- VERIFY EDIT NOTIFICATIONS SETUP
-- ============================================
-- Run this to confirm everything is configured correctly

-- 1. Check if trigger exists and is enabled
SELECT '=== 1. Trigger Status ===' as step;
SELECT 
  tgname as trigger_name,
  CASE tgenabled
    WHEN 'O' THEN '✅ ENABLED'
    WHEN 'D' THEN '❌ DISABLED'
    ELSE '⚠️  UNKNOWN'
  END as status,
  tgrelid::regclass as table_name
FROM pg_trigger
WHERE tgname = 'trigger_notify_on_block_edit'
AND tgisinternal = false;

-- 2. Check if function exists
SELECT '=== 2. Function Status ===' as step;
SELECT 
  proname as function_name,
  CASE prosecdef
    WHEN true THEN '✅ SECURITY DEFINER (bypasses RLS)'
    ELSE '⚠️  Not security definer'
  END as security_mode
FROM pg_proc
WHERE proname = 'notify_on_block_edit';

-- 3. Check notifications table exists
SELECT '=== 3. Notifications Table ===' as step;
SELECT 
  tablename,
  '✅ EXISTS' as status
FROM pg_tables
WHERE tablename = 'notifications'
AND schemaname = 'public';

-- 4. Check RLS policies on notifications
SELECT '=== 4. Notifications RLS Policies ===' as step;
SELECT 
  policyname,
  cmd as operation,
  CASE 
    WHEN policyname LIKE '%own%' THEN '✅ Users can see their own'
    WHEN policyname LIKE '%insert%' THEN '✅ System can insert'
    ELSE '✅ Policy exists'
  END as description
FROM pg_policies
WHERE tablename = 'notifications'
ORDER BY policyname;

-- 5. Check if there are any shared items
SELECT '=== 5. Shared Items Count ===' as step;
SELECT 
  COUNT(DISTINCT item_id) as shared_items_count,
  COUNT(*) as total_shares,
  CASE 
    WHEN COUNT(DISTINCT item_id) > 0 THEN '✅ Items are shared'
    ELSE '⚠️  No shared items found'
  END as status
FROM item_shares;

-- 6. Show recent shared items
SELECT '=== 6. Recent Shared Items ===' as step;
SELECT 
  i.id,
  i.title,
  i.created_by as owner_id,
  COUNT(s.user_id) as shared_with_count
FROM items i
JOIN item_shares s ON s.item_id = i.id
GROUP BY i.id, i.title, i.created_by
ORDER BY i.updated_at DESC
LIMIT 5;

-- 7. Check existing notifications
SELECT '=== 7. Existing Notifications ===' as step;
SELECT 
  type,
  COUNT(*) as count,
  MAX(created_at) as most_recent
FROM notifications
GROUP BY type
ORDER BY type;

-- 8. Summary
SELECT '=== 8. Setup Summary ===' as step;
SELECT 
  CASE 
    WHEN EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'trigger_notify_on_block_edit' AND tgenabled = 'O')
      AND EXISTS (SELECT 1 FROM pg_proc WHERE proname = 'notify_on_block_edit')
      AND EXISTS (SELECT 1 FROM pg_tables WHERE tablename = 'notifications')
      AND EXISTS (SELECT 1 FROM item_shares)
    THEN '✅ ALL SYSTEMS GO! Edit notifications should work.'
    ELSE '⚠️  Some components are missing. Check the steps above.'
  END as status;

-- 9. Next steps
SELECT '=== 9. Next Steps ===' as step;
SELECT 
  'To test: Edit a shared note block in the Flutter app and check if notification appears' as instruction
UNION ALL
SELECT 
  'Check Flutter logs for: "📤 Upserting to Supabase with updated_at"' as instruction
UNION ALL
SELECT 
  'Check Supabase logs for: "Block edit detected" and "Created edit notification"' as instruction;
