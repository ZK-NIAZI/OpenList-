-- =====================================================
-- FIX EDIT PERMISSION FOR SHARED ITEMS
-- =====================================================
-- This script fixes the RLS policies to allow users
-- with edit permission to actually update items and blocks
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

-- =====================================================
-- VERIFY POLICIES
-- =====================================================

DO $
BEGIN
  RAISE NOTICE '✅ Update policies recreated with WITH CHECK clauses';
  RAISE NOTICE '✅ Shared users with edit permission can now update items and blocks';
  RAISE NOTICE '';
  RAISE NOTICE '📝 Test the fix:';
  RAISE NOTICE '1. User A shares a note with User B (edit permission)';
  RAISE NOTICE '2. User B edits the note';
  RAISE NOTICE '3. Changes should sync to Supabase';
  RAISE NOTICE '4. User A should see User B''s changes';
END $;

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
