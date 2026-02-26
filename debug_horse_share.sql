-- Debug query to check if the "horse" share exists in Supabase

-- Check if the horse item exists
SELECT 'Horse item:' as check_type, id, title, created_by 
FROM items 
WHERE id = '875b1cc6-bbd1-44a5-a8bf-43eb51cd0fcc';

-- Check if the share record exists
SELECT 'Share record:' as check_type, id, item_id, user_id, permission, shared_by, created_at
FROM item_shares 
WHERE item_id = '875b1cc6-bbd1-44a5-a8bf-43eb51cd0fcc';

-- Check all shares for Mutaal's user ID
SELECT 'All shares for Mutaal:' as check_type, id, item_id, user_id, permission, shared_by, created_at
FROM item_shares 
WHERE user_id = 'd8fd378d-ae52-42d9-ab11-c6fb5113f0c0'
ORDER BY created_at DESC;

-- Check if there are any RLS policy issues
SELECT 'RLS policies on item_shares:' as check_type, schemaname, tablename, policyname, cmd, qual
FROM pg_policies 
WHERE schemaname = 'public' AND tablename = 'item_shares';
