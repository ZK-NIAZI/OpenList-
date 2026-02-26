-- =====================================================
-- FIX EDIT PERMISSION FOR SHARED ITEMS (Complete Fix)
-- =====================================================
-- This script fixes ALL RLS policies for items and blocks
-- to allow shared users with edit permission to:
-- 1. SELECT (read) items and blocks
-- 2. INSERT new blocks
-- 3. UPDATE existing items and blocks
-- 4. DELETE blocks (optional, for checklist items)
-- =====================================================

-- =====================================================
-- ITEMS TABLE POLICIES
-- =====================================================

-- Drop all existing policies for items
DROP POLICY IF EXISTS "items_select_own" ON items;
DROP POLICY IF EXISTS "items_select_shared" ON items;
DROP POLICY IF EXISTS "items_insert_own" ON items;
DROP POLICY IF EXISTS "items_update_own" ON items;
DROP POLICY IF EXISTS "items_update_shared" ON items;
DROP POLICY IF EXISTS "items_delete_own" ON items;

-- SELECT: Owner can read their own items
CREATE POLICY "items_select_own"
  ON items FOR SELECT
  USING (created_by = auth.uid());

-- SELECT: Shared users can read items shared with them
CREATE POLICY "items_select_shared"
  ON items FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM item_shares 
      WHERE item_shares.item_id = items.id 
      AND item_shares.user_id = auth.uid()
    )
  );

-- INSERT: Only owner can create new items
CREATE POLICY "items_insert_own"
  ON items FOR INSERT
  WITH CHECK (created_by = auth.uid());

-- UPDATE: Owner can update their own items
CREATE POLICY "items_update_own"
  ON items FOR UPDATE
  USING (created_by = auth.uid())
  WITH CHECK (created_by = auth.uid());

-- UPDATE: Shared users with edit permission can update items
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

-- DELETE: Only owner can delete items
CREATE POLICY "items_delete_own"
  ON items FOR DELETE
  USING (created_by = auth.uid());

-- =====================================================
-- BLOCKS TABLE POLICIES
-- =====================================================

-- Drop all existing policies for blocks
DROP POLICY IF EXISTS "blocks_select_own" ON blocks;
DROP POLICY IF EXISTS "blocks_select_shared" ON blocks;
DROP POLICY IF EXISTS "blocks_insert_own" ON blocks;
DROP POLICY IF EXISTS "blocks_insert_shared" ON blocks;
DROP POLICY IF EXISTS "blocks_update_own" ON blocks;
DROP POLICY IF EXISTS "blocks_update_shared" ON blocks;
DROP POLICY IF EXISTS "blocks_delete_own" ON blocks;
DROP POLICY IF EXISTS "blocks_delete_shared" ON blocks;

-- SELECT: Owner can read blocks of their items
CREATE POLICY "blocks_select_own"
  ON blocks FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM items 
      WHERE items.id = blocks.item_id 
      AND items.created_by = auth.uid()
    )
  );

-- SELECT: Shared users can read blocks of items shared with them
CREATE POLICY "blocks_select_shared"
  ON blocks FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM items 
      JOIN item_shares ON item_shares.item_id = items.id
      WHERE items.id = blocks.item_id 
      AND item_shares.user_id = auth.uid()
    )
  );

-- INSERT: Owner can insert blocks for their items
CREATE POLICY "blocks_insert_own"
  ON blocks FOR INSERT
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM items 
      WHERE items.id = blocks.item_id 
      AND items.created_by = auth.uid()
    )
  );

-- INSERT: Shared users with edit permission can insert blocks
CREATE POLICY "blocks_insert_shared"
  ON blocks FOR INSERT
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM items 
      JOIN item_shares ON item_shares.item_id = items.id
      WHERE items.id = blocks.item_id 
      AND item_shares.user_id = auth.uid()
      AND item_shares.permission = 'edit'
    )
  );

-- UPDATE: Owner can update blocks of their items
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

-- UPDATE: Shared users with edit permission can update blocks
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

-- DELETE: Owner can delete blocks of their items
CREATE POLICY "blocks_delete_own"
  ON blocks FOR DELETE
  USING (
    EXISTS (
      SELECT 1 FROM items 
      WHERE items.id = blocks.item_id 
      AND items.created_by = auth.uid()
    )
  );

-- DELETE: Shared users with edit permission can delete blocks
CREATE POLICY "blocks_delete_shared"
  ON blocks FOR DELETE
  USING (
    EXISTS (
      SELECT 1 FROM items 
      JOIN item_shares ON item_shares.item_id = items.id
      WHERE items.id = blocks.item_id 
      AND item_shares.user_id = auth.uid()
      AND item_shares.permission = 'edit'
    )
  );

-- =====================================================
-- VERIFICATION QUERIES
-- =====================================================

-- Show all policies for items
SELECT 
  schemaname,
  tablename,
  policyname,
  cmd,
  qual IS NOT NULL as has_using,
  with_check IS NOT NULL as has_with_check
FROM pg_policies 
WHERE schemaname = 'public'
AND tablename = 'items'
ORDER BY policyname;

-- Show all policies for blocks
SELECT 
  schemaname,
  tablename,
  policyname,
  cmd,
  qual IS NOT NULL as has_using,
  with_check IS NOT NULL as has_with_check
FROM pg_policies 
WHERE schemaname = 'public'
AND tablename = 'blocks'
ORDER BY policyname;

-- Test query: Check if a specific user can see shared items
-- Replace [user_uuid] with actual UUID to test
-- SELECT * FROM items WHERE id IN (
--   SELECT item_id FROM item_shares WHERE user_id = '[user_uuid]'
-- );

-- Test query: Check shares for a specific item
-- Replace [item_id] with actual item ID to test
-- SELECT * FROM item_shares WHERE item_id = '[item_id]';
