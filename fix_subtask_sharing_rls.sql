-- Fix RLS policy to allow access to sub-tasks when parent is shared
-- This allows users to see sub-tasks of items that are shared with them

-- Drop existing SELECT policy
DROP POLICY IF EXISTS "Users can view their own items and shared items" ON items;

-- Create new SELECT policy that includes sub-tasks of shared items
-- Note: We avoid infinite recursion by only checking item_shares table, not items table
CREATE POLICY "Users can view their own items, shared items, and sub-tasks of shared items"
ON items FOR SELECT
USING (
  auth.uid() = created_by  -- Own items
  OR
  id IN (  -- Directly shared items
    SELECT item_id 
    FROM item_shares 
    WHERE user_id = auth.uid()
  )
  OR
  parent_id IN (  -- Sub-tasks of shared items (check if parent is shared)
    SELECT item_id 
    FROM item_shares 
    WHERE user_id = auth.uid()
  )
);

-- Verify the policy was created
SELECT schemaname, tablename, policyname, permissive, roles, cmd, qual
FROM pg_policies
WHERE tablename = 'items' AND policyname LIKE '%view%';
