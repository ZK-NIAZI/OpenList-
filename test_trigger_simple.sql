-- ============================================
-- SIMPLE TRIGGER TEST
-- ============================================
-- This will help us determine if the trigger fires at all

-- Step 1: Find a shared item
SELECT 
  i.id as item_id,
  i.title,
  i.created_by as owner_id
FROM items i
WHERE EXISTS (SELECT 1 FROM item_shares WHERE item_id = i.id)
ORDER BY i.updated_at DESC
LIMIT 1;

-- Step 2: Find a block from that item (use the item_id from step 1)
-- REPLACE 'YOUR_ITEM_ID_HERE' with the actual item_id from step 1
SELECT 
  id as block_id,
  content,
  updated_at
FROM blocks
WHERE item_id = 'YOUR_ITEM_ID_HERE'
LIMIT 1;

-- Step 3: Update that block directly (use the block_id from step 2)
-- REPLACE 'YOUR_BLOCK_ID_HERE' with the actual block_id from step 2
UPDATE blocks
SET 
  content = content || ' [MANUAL TEST]',
  updated_at = NOW()
WHERE id = 'YOUR_BLOCK_ID_HERE'
RETURNING id, content, updated_at;

-- Step 4: Check if notification was created
SELECT 
  id,
  type,
  title,
  message,
  user_id,
  item_id,
  created_at
FROM notifications
WHERE created_at > NOW() - INTERVAL '1 minute'
ORDER BY created_at DESC;

-- Step 5: If no notification, check who should have received one
-- REPLACE 'YOUR_ITEM_ID_HERE' with the item_id from step 1
SELECT 
  'Owner' as role,
  created_by as user_id
FROM items
WHERE id = 'YOUR_ITEM_ID_HERE'
UNION ALL
SELECT 
  'Shared with' as role,
  user_id
FROM item_shares
WHERE item_id = 'YOUR_ITEM_ID_HERE';
