-- Fix RLS Policy for Sub-Tasks
-- This allows users to create sub-tasks that inherit the parent's creator

-- Drop existing policies
DROP POLICY IF EXISTS "Users can insert their own items" ON items;
DROP POLICY IF EXISTS "Users can insert items" ON items;

-- Create new INSERT policy that allows:
-- 1. Creating items where you are the creator
-- 2. Creating sub-tasks (children) of items you own or have access to
CREATE POLICY "Users can insert items and sub-tasks"
ON items
FOR INSERT
TO authenticated
WITH CHECK (
  -- Allow if you're the creator
  auth.uid() = created_by
  OR
  -- Allow if this is a sub-task of an item you own
  (
    parent_id IS NOT NULL
    AND EXISTS (
      SELECT 1 FROM items parent
      WHERE parent.id = items.parent_id
      AND parent.created_by = auth.uid()
    )
  )
  OR
  -- Allow if this is a sub-task of an item shared with you
  (
    parent_id IS NOT NULL
    AND EXISTS (
      SELECT 1 FROM item_shares
      WHERE item_shares.item_id = items.parent_id
      AND item_shares.user_id = auth.uid()
      AND item_shares.permission = 'edit'
    )
  )
);

-- Verify the policy was created
SELECT 
  schemaname,
  tablename,
  policyname,
  permissive,
  roles,
  cmd,
  qual,
  with_check
FROM pg_policies
WHERE tablename = 'items'
AND policyname = 'Users can insert items and sub-tasks';
