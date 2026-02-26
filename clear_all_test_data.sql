-- =====================================================
-- CLEAR ALL TEST DATA (SUPABASE SIDE)
-- =====================================================
-- This clears all notes, tasks, subtasks, blocks, and notifications
-- Run this in Supabase SQL Editor
-- =====================================================

-- Delete all notifications first (has foreign keys)
DELETE FROM notifications;

-- Delete all sharing data
DELETE FROM item_shares;
DELETE FROM space_members;

-- Delete all blocks (note content, checklists, task references)
DELETE FROM blocks;

-- Delete all items (notes, tasks, subtasks)
DELETE FROM items;

-- Delete all spaces
DELETE FROM spaces;

-- =====================================================
-- VERIFICATION
-- =====================================================
SELECT 
  (SELECT COUNT(*) FROM items) as items_count,
  (SELECT COUNT(*) FROM blocks) as blocks_count,
  (SELECT COUNT(*) FROM notifications) as notifications_count,
  (SELECT COUNT(*) FROM item_shares) as shares_count,
  (SELECT COUNT(*) FROM spaces) as spaces_count;

SELECT '✅ All test data cleared from Supabase!' as result;

-- =====================================================
-- NOTES:
-- =====================================================
-- After running this SQL in Supabase:
-- 1. Close your app completely (force stop)
-- 2. Clear app data: Settings > Apps > OpenList > Storage > Clear Data
-- 3. Restart the app and log in again
-- 
-- This will give you a completely fresh start for testing!
-- =====================================================
