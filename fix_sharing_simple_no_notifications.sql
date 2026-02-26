-- ============================================
-- SIMPLE FIX FOR SHARING - NO NOTIFICATIONS
-- ============================================
-- This removes the notification trigger that's causing sharing to fail
-- We'll get notifications working later - first priority is sharing

-- Step 1: Drop the trigger that's causing the error
DROP TRIGGER IF EXISTS trigger_notify_on_share ON item_shares;

-- Step 2: Drop the trigger function
DROP FUNCTION IF EXISTS notify_on_share();

-- Step 3: Drop the notification function (we'll recreate it later when we fix notifications)
DROP FUNCTION IF EXISTS create_notification(UUID, TEXT, TEXT, TEXT, TEXT, UUID);
DROP FUNCTION IF EXISTS create_notification(UUID, TEXT, TEXT, TEXT, UUID, UUID);

-- Step 4: Verify the fix
SELECT '✅ Sharing trigger removed - sharing should work now!' as status;

-- Step 5: Verify item_shares table exists and is ready
SELECT 
    table_name,
    column_name,
    data_type
FROM information_schema.columns
WHERE table_name = 'item_shares'
ORDER BY ordinal_position;
