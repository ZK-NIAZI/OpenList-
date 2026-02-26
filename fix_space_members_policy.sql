-- =====================================================
-- FIX SPACE_MEMBERS INFINITE RECURSION
-- =====================================================

-- Drop the problematic policy
DROP POLICY IF EXISTS "members_select" ON space_members;

-- Create a simple policy without recursion
CREATE POLICY "members_select"
ON space_members FOR SELECT
USING (
  user_id = auth.uid()
  OR invited_by = auth.uid()
);

-- Verify
SELECT tablename, policyname, cmd 
FROM pg_policies 
WHERE tablename = 'space_members';
