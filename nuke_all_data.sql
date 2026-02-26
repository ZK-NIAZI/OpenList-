-- ⚠️ WARNING: This will delete ALL data from ALL accounts ⚠️
-- This includes all items (notes/tasks), blocks, shares, notifications, and space members
-- This action CANNOT be undone!

-- Delete all blocks first (child records)
DELETE FROM blocks;

-- Delete all item shares
DELETE FROM item_shares;

-- Delete all space members
DELETE FROM space_members;

-- Delete all notifications
DELETE FROM notifications;

-- Delete all items (notes and tasks)
DELETE FROM items;

-- Verify deletion
SELECT 
    'items' as table_name, 
    COUNT(*) as remaining_records 
FROM items
UNION ALL
SELECT 
    'blocks' as table_name, 
    COUNT(*) as remaining_records 
FROM blocks
UNION ALL
SELECT 
    'item_shares' as table_name, 
    COUNT(*) as remaining_records 
FROM item_shares
UNION ALL
SELECT 
    'space_members' as table_name, 
    COUNT(*) as remaining_records 
FROM space_members
UNION ALL
SELECT 
    'notifications' as table_name, 
    COUNT(*) as remaining_records 
FROM notifications;

-- Show success message
SELECT '✅ All data deleted successfully. All tables are now empty.' as status;
