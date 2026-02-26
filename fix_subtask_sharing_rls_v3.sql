-- Fix RLS policy to allow access to sub-tasks when parent is shared
-- This version avoids ALL recursion by ONLY checking item_shares table

-- Drop existing SELECT policies
DROP POLICY IF EXISTS "Users can view their own items and shared items" ON items;
DROP POLICY IF EXISTS "Users can view their own items, shared items, and sub-tasks of shared items" ON items;
DROP POLICY IF EXISTS "Users can view accessible items and their sub-tasks" ON items;

-- Create new SELECT policy that ONLY checks item_shares (no recursion possible)
CREATE POLICY "Users can view their items and shared items with children"
ON items FOR SELECT
USING (
  -- Own items (created by current user)
  auth.uid() = created_by
  OR
  -- Items directly shared with current user
  EXISTS (
    SELECT 1 
    FROM item_shares 
    WHERE item_shares.item_id = items.id 
    AND item_shares.user_id = auth.uid()
  )
  OR
  -- Items whose parent is shared with current user
  -- This allows sub-tasks to be visible when parent is shared
  EXISTS (
    SELECT 1 
    FROM item_shares 
    WHERE item_shares.item_id = items.parent_id 
    AND item_shares.user_id = auth.uid()
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
  qual
FROM pg_policies
WHERE tablename = 'items' 
AND policyname = 'Users can view their items and shared items with children';

-- Show all current policies on items table
SELECT 
  policyname,
  cmd,
  permissive
FROM pg_policies
WHERE tablename = 'items'
ORDER BY policyname;
