-- Fix RLS policies to allow editing sub-tasks and viewing their blocks
-- This allows users to edit sub-tasks and see blocks when parent is shared

-- ============================================
-- PART 1: Fix UPDATE policy for items (allow editing sub-tasks)
-- ============================================

-- Drop existing UPDATE policy
DROP POLICY IF EXISTS "Users can update their own items and shared items with edit permission" ON items;

-- Create new UPDATE policy that includes sub-tasks of shared items
CREATE POLICY "Users can update their items, shared items with edit permission, and sub-tasks"
ON items FOR UPDATE
USING (
  -- Own items
  auth.uid() = created_by
  OR
  -- Items shared with edit permission
  EXISTS (
    SELECT 1 
    FROM item_shares 
    WHERE item_shares.item_id = items.id 
    AND item_shares.user_id = auth.uid()
    AND item_shares.permission = 'edit'
  )
  OR
  -- Sub-tasks where parent has edit permission
  EXISTS (
    SELECT 1 
    FROM item_shares 
    WHERE item_shares.item_id = items.parent_id 
    AND item_shares.user_id = auth.uid()
    AND item_shares.permission = 'edit'
  )
);

-- ============================================
-- PART 2: Fix SELECT policy for blocks (allow viewing blocks of sub-tasks)
-- ============================================

-- Drop existing SELECT policy for blocks
DROP POLICY IF EXISTS "Users can view blocks of their items and shared items" ON blocks;

-- Create new SELECT policy that includes blocks of sub-tasks
CREATE POLICY "Users can view blocks of their items, shared items, and sub-tasks"
ON blocks FOR SELECT
USING (
  -- Blocks of items user created
  item_id IN (
    SELECT id FROM items WHERE created_by = auth.uid()
  )
  OR
  -- Blocks of items directly shared with user
  item_id IN (
    SELECT item_id FROM item_shares WHERE user_id = auth.uid()
  )
  OR
  -- Blocks of sub-tasks (where parent is shared with user)
  item_id IN (
    SELECT id FROM items 
    WHERE parent_id IN (
      SELECT item_id FROM item_shares WHERE user_id = auth.uid()
    )
  )
);

-- ============================================
-- PART 3: Fix UPDATE policy for blocks (allow editing blocks of sub-tasks)
-- ============================================

-- Drop existing UPDATE policy for blocks
DROP POLICY IF EXISTS "Users can update blocks of their items and shared items with edit permission" ON blocks;

-- Create new UPDATE policy that includes blocks of sub-tasks
CREATE POLICY "Users can update blocks of their items, shared items, and sub-tasks"
ON blocks FOR UPDATE
USING (
  -- Blocks of items user created
  item_id IN (
    SELECT id FROM items WHERE created_by = auth.uid()
  )
  OR
  -- Blocks of items shared with edit permission
  item_id IN (
    SELECT item_id FROM item_shares 
    WHERE user_id = auth.uid() 
    AND permission = 'edit'
  )
  OR
  -- Blocks of sub-tasks (where parent has edit permission)
  item_id IN (
    SELECT id FROM items 
    WHERE parent_id IN (
      SELECT item_id FROM item_shares 
      WHERE user_id = auth.uid() 
      AND permission = 'edit'
    )
  )
);

-- ============================================
-- PART 4: Fix INSERT policy for blocks (allow creating blocks in sub-tasks)
-- ============================================

-- Drop existing INSERT policy for blocks
DROP POLICY IF EXISTS "Users can insert blocks into their items and shared items with edit permission" ON blocks;

-- Create new INSERT policy that includes blocks of sub-tasks
CREATE POLICY "Users can insert blocks into their items, shared items, and sub-tasks"
ON blocks FOR INSERT
WITH CHECK (
  -- Blocks of items user created
  item_id IN (
    SELECT id FROM items WHERE created_by = auth.uid()
  )
  OR
  -- Blocks of items shared with edit permission
  item_id IN (
    SELECT item_id FROM item_shares 
    WHERE user_id = auth.uid() 
    AND permission = 'edit'
  )
  OR
  -- Blocks of sub-tasks (where parent has edit permission)
  item_id IN (
    SELECT id FROM items 
    WHERE parent_id IN (
      SELECT item_id FROM item_shares 
      WHERE user_id = auth.uid() 
      AND permission = 'edit'
    )
  )
);

-- ============================================
-- PART 5: Fix DELETE policy for blocks (allow deleting blocks from sub-tasks)
-- ============================================

-- Drop existing DELETE policy for blocks
DROP POLICY IF EXISTS "Users can delete blocks from their items and shared items with edit permission" ON blocks;

-- Create new DELETE policy that includes blocks of sub-tasks
CREATE POLICY "Users can delete blocks from their items, shared items, and sub-tasks"
ON blocks FOR DELETE
USING (
  -- Blocks of items user created
  item_id IN (
    SELECT id FROM items WHERE created_by = auth.uid()
  )
  OR
  -- Blocks of items shared with edit permission
  item_id IN (
    SELECT item_id FROM item_shares 
    WHERE user_id = auth.uid() 
    AND permission = 'edit'
  )
  OR
  -- Blocks of sub-tasks (where parent has edit permission)
  item_id IN (
    SELECT id FROM items 
    WHERE parent_id IN (
      SELECT item_id FROM item_shares 
      WHERE user_id = auth.uid() 
      AND permission = 'edit'
    )
  )
);

-- ============================================
-- Verify all policies were created
-- ============================================

-- Check items policies
SELECT 
  policyname,
  cmd,
  permissive
FROM pg_policies
WHERE tablename = 'items'
ORDER BY cmd, policyname;

-- Check blocks policies
SELECT 
  policyname,
  cmd,
  permissive
FROM pg_policies
WHERE tablename = 'blocks'
ORDER BY cmd, policyname;
