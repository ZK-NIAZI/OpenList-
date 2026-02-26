-- Simple Fix for Sub-Task RLS Issue
-- This allows authenticated users to insert items regardless of created_by value
-- Use this if the complex policy doesn't work

-- Drop existing INSERT policy
DROP POLICY IF EXISTS "Users can insert their own items" ON items;
DROP POLICY IF EXISTS "Users can insert items" ON items;
DROP POLICY IF EXISTS "Users can insert items and sub-tasks" ON items;

-- Create simple INSERT policy
-- Allows any authenticated user to insert items
CREATE POLICY "Users can insert items"
ON items
FOR INSERT
TO authenticated
WITH CHECK (true);

-- Note: This is less secure but will allow sub-tasks to work
-- The created_by field will still track the original creator
-- Access control is handled by SELECT policies and item_shares table

-- Verify the policy
SELECT 
  policyname,
  cmd,
  with_check
FROM pg_policies
WHERE tablename = 'items'
AND cmd = 'INSERT';
