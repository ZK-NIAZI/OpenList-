-- =====================================================
-- FIX EDIT PERMISSION FOR SHARED ITEMS (Simple Version)
-- =====================================================

-- Drop existing update policies for items
DROP POLICY IF EXISTS "items_update_own" ON items;
DROP POLICY IF EXISTS "items_update_shared" ON items;

-- Drop existing update policies for blocks
DROP POLICY IF EXISTS "blocks_update_own" ON blocks;
DROP POLICY IF EXISTS "blocks_update_shared" ON blocks;

-- =====================================================
-- ITEMS UPDATE POLICIES (with WITH CHECK clause)
-- =====================================================

-- Owner can update their own items
CREATE POLICY "items_update_own"
  ON items FOR UPDATE
  USING (created_by = auth.uid())
  WITH CHECK (created_by = auth.uid());

-- Shared users with edit permission can update items
CREATE POLICY "items_update_shared"
  ON items FOR UPDATE
  USING (
    EXISTS (
      SELECT 1 FROM item_shares 
      WHERE item_shares.item_id = items.id 
      AND item_shares.user_id = auth.uid()
      AND item_shares.permission = 'edit'
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM item_shares 
      WHERE item_shares.item_id = items.id 
      AND item_shares.user_id = auth.uid()
      AND item_shares.permission = 'edit'
    )
  );

-- =====================================================
-- BLOCKS UPDATE POLICIES (with WITH CHECK clause)
-- =====================================================

-- Owner can update blocks of their items
CREATE POLICY "blocks_update_own"
  ON blocks FOR UPDATE
  USING (
    EXISTS (
      SELECT 1 FROM items 
      WHERE items.id = blocks.item_id 
      AND items.created_by = auth.uid()
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM items 
      WHERE items.id = blocks.item_id 
      AND items.created_by = auth.uid()
    )
  );

-- Shared users with edit permission can update blocks
CREATE POLICY "blocks_update_shared"
  ON blocks FOR UPDATE
  USING (
    EXISTS (
      SELECT 1 FROM items 
      JOIN item_shares ON item_shares.item_id = items.id
      WHERE items.id = blocks.item_id 
      AND item_shares.user_id = auth.uid()
      AND item_shares.permission = 'edit'
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM items 
      JOIN item_shares ON item_shares.item_id = items.id
      WHERE items.id = blocks.item_id 
      AND item_shares.user_id = auth.uid()
      AND item_shares.permission = 'edit'
    )
  );

-- Show the policies
SELECT 
  schemaname,
  tablename,
  policyname,
  cmd,
  qual IS NOT NULL as has_using,
  with_check IS NOT NULL as has_with_check
FROM pg_policies 
WHERE schemaname = 'public'
AND tablename IN ('items', 'blocks')
AND policyname LIKE '%update%'
ORDER BY tablename, policyname;
