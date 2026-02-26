-- Manual test to see if trigger fires
-- This will update a block and check if notification is created

-- Step 1: Update the block directly
UPDATE blocks
SET 
  content = content || ' [TEST]',
  updated_at = NOW()
WHERE item_id = '1d84b9ae-f02c-48b8-a3a7-13881407f538'
AND id = '318b15c4-67dc-467f-9a1b-fd7c5c5b3659'
RETURNING id, content, updated_at;

-- Step 2: Wait a moment, then check if notification was created
SELECT 
  id,
  user_id,
  type,
  title,
  message,
  created_at
FROM notifications
WHERE created_at > NOW() - INTERVAL '1 minute'
ORDER BY created_at DESC;

-- Step 3: If no notification, check if trigger exists
SELECT 
  tgname,
  tgenabled,
  tgrelid::regclass as table_name
FROM pg_trigger
WHERE tgname = 'trigger_notify_on_block_edit';
