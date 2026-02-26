-- Fix RLS policy to allow access to sub-tasks when parent is shared
-- This version uses a SECURITY DEFINER function to avoid infinite recursion

-- Step 1: Create a helper function that checks if a user has access to an item
-- SECURITY DEFINER means it runs with the privileges of the function owner (bypasses RLS)
CREATE OR REPLACE FUNCTION public.user_has_item_access(item_uuid uuid, user_uuid uuid)
RETURNS boolean
LANGUAGE sql
SECURITY DEFINER
STABLE
AS $$
  -- Check if user created the item OR item is shared with them
  SELECT EXISTS (
    SELECT 1 FROM public.items 
    WHERE id = item_uuid 
    AND created_by = user_uuid
  )
  OR EXISTS (
    SELECT 1 FROM public.item_shares 
    WHERE item_id = item_uuid 
    AND user_id = user_uuid
  );
$$;

-- Step 2: Drop existing SELECT policy
DROP POLICY IF EXISTS "Users can view their own items and shared items" ON items;
DROP POLICY IF EXISTS "Users can view their own items, shared items, and sub-tasks of shared items" ON items;

-- Step 3: Create new SELECT policy using the helper function
CREATE POLICY "Users can view accessible items and their sub-tasks"
ON items FOR SELECT
USING (
  -- Own items
  auth.uid() = created_by
  OR
  -- Directly shared items
  id IN (
    SELECT item_id 
    FROM item_shares 
    WHERE user_id = auth.uid()
  )
  OR
  -- Sub-tasks where parent is accessible (uses SECURITY DEFINER function to avoid recursion)
  (
    parent_id IS NOT NULL 
    AND user_has_item_access(parent_id, auth.uid())
  )
);

-- Step 4: Verify the policy was created
SELECT schemaname, tablename, policyname, permissive, roles, cmd
FROM pg_policies
WHERE tablename = 'items' AND policyname LIKE '%accessible%';

-- Step 5: Test the function (optional - uncomment to test)
-- Replace YOUR_USER_ID and YOUR_ITEM_ID with actual values
/*
SELECT user_has_item_access(
  'YOUR_ITEM_ID'::uuid,
  'YOUR_USER_ID'::uuid
);
*/
