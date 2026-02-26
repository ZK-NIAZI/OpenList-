-- =====================================================
-- FIX NOTES MULTIPLYING AND BLOCK DELETION ISSUES
-- =====================================================
-- Run this in Supabase SQL Editor
-- =====================================================

-- Step 1: Clear all test data
DELETE FROM notifications;
DELETE FROM item_shares;
DELETE FROM space_members;
DELETE FROM blocks;
DELETE FROM items;
DELETE FROM spaces;

-- Step 2: Verify blocks table has correct types
ALTER TABLE blocks DROP CONSTRAINT IF EXISTS blocks_type_check;

ALTER TABLE blocks ADD CONSTRAINT blocks_type_check 
  CHECK (type IN ('text', 'heading', 'checklist', 'bullet', 'image', 'code', 'task', 'subTask'));

-- Step 3: Check if content column is TEXT (unlimited)
SELECT 
  column_name,
  data_type,
  character_maximum_length
FROM information_schema.columns
WHERE table_name = 'blocks' AND column_name = 'content';

-- If content is VARCHAR with a limit, change it to TEXT
-- ALTER TABLE blocks ALTER COLUMN content TYPE TEXT;

SELECT '✅ Database cleaned and block types updated!' as result;
SELECT 'Now clear app data on your Android device and restart' as next_step;
