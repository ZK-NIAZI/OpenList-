-- =====================================================
-- CLEAR ALL DATA (KEEP USER ACCOUNTS)
-- =====================================================
-- This script deletes all notes, tasks, blocks, spaces, 
-- and sharing data while preserving user accounts.
-- Run this in Supabase SQL Editor.
-- =====================================================

-- Delete all sharing data
DELETE FROM item_shares;
DELETE FROM space_members;

-- Delete all blocks (note content)
DELETE FROM blocks;

-- Delete all items (notes and tasks)
DELETE FROM items;

-- Delete all spaces
DELETE FROM spaces;

-- =====================================================
-- VERIFICATION QUERIES
-- =====================================================
-- Run these to verify data was deleted:

-- Should return 0 for all:
SELECT COUNT(*) as items_count FROM items;
SELECT COUNT(*) as blocks_count FROM blocks;
SELECT COUNT(*) as spaces_count FROM spaces;
SELECT COUNT(*) as item_shares_count FROM item_shares;
SELECT COUNT(*) as space_members_count FROM space_members;

-- Should still show your users:
SELECT COUNT(*) as users_count FROM auth.users;

-- =====================================================
-- NOTES:
-- =====================================================
-- - User accounts in auth.users are NOT deleted
-- - User profiles in public.profiles are NOT deleted
-- - You can still log in with existing accounts
-- - All notes, tasks, and sharing data are removed
-- =====================================================
