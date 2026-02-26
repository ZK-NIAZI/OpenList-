-- ============================================
-- FIX CASCADE DELETE ISSUE
-- ============================================
-- Problem: item_shares has CASCADE delete, so shares are deleted
-- BEFORE the trigger can read them to create notifications
-- Solution: Change to NO ACTION so trigger can read shares first
-- ============================================

-- Drop the existing foreign key constraint
ALTER TABLE item_shares
DROP CONSTRAINT IF EXISTS item_shares_item_id_fkey;

-- Recreate it with NO ACTION (trigger will handle cleanup)
ALTER TABLE item_shares
ADD CONSTRAINT item_shares_item_id_fkey
FOREIGN KEY (item_id)
REFERENCES items(id)
ON DELETE NO ACTION;

-- Verify the change
SELECT 
  tc.constraint_name,
  tc.table_name,
  rc.delete_rule
FROM information_schema.table_constraints AS tc
JOIN information_schema.referential_constraints AS rc
  ON tc.constraint_name = rc.constraint_name
WHERE tc.table_name = 'item_shares'
AND tc.constraint_type = 'FOREIGN KEY';

SELECT '
✅ CASCADE DELETE REMOVED!

What changed:
- item_shares foreign key changed from CASCADE to NO ACTION
- Now when you delete an item, shares are NOT auto-deleted
- Trigger can read shares to create notifications
- Your Flutter code deletes shares manually after

Next steps:
1. Test deleting a shared item
2. Check if delete notification appears
3. Verify shares are still cleaned up by your Flutter code

The trigger will now work because item_shares exist when it fires!
' as instructions;
