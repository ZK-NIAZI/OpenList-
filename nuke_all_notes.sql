-- ============================================
-- NUKE ALL NOTES (keeps tasks)
-- ============================================

-- Delete all blocks for notes first (to avoid foreign key issues)
DELETE FROM blocks 
WHERE item_id IN (
  SELECT id FROM items WHERE type = 'note'
);

-- Delete all shares for notes
DELETE FROM item_shares 
WHERE item_id IN (
  SELECT id FROM items WHERE type = 'note'
);

-- Delete all notes
DELETE FROM items WHERE type = 'note';

-- Verify deletion
SELECT 
  'Notes deleted' as status,
  (SELECT COUNT(*) FROM items WHERE type = 'note') as remaining_notes,
  (SELECT COUNT(*) FROM items WHERE type = 'task') as remaining_tasks;
