-- =====================================================
-- FIX RLS POLICIES - Remove Infinite Recursion
-- =====================================================
-- Run this in Supabase SQL Editor to fix the policies
-- =====================================================

-- Drop existing problematic policies
DROP POLICY IF EXISTS "Users can view their own items and shared items" ON items;
DROP POLICY IF EXISTS "Users can view their own shares and items shared with them" ON item_shares;
DROP POLICY IF EXISTS "Users can view space members where they are members" ON space_members;

-- =====================================================
-- ITEMS TABLE - Simplified RLS
-- =====================================================

-- Users can view items they created
CREATE POLICY "Users can view their own items"
ON items FOR SELECT
USING (auth.uid() = created_by);

-- Users can view items shared with them (simple check, no recursion)
CREATE POLICY "Users can view shared items"
ON items FOR SELECT
USING (
  EXISTS (
    SELECT 1 FROM item_shares
    WHERE item_shares.item_id = items.id
    AND item_shares.user_id = auth.uid()
  )
);

-- Users can insert their own items
CREATE POLICY "Users can insert their own items"
ON items FOR INSERT
WITH CHECK (auth.uid() = created_by);

-- Users can update their own items
CREATE POLICY "Users can update their own items"
ON items FOR UPDATE
USING (auth.uid() = created_by);

-- Users can update items shared with them (if they have edit permission)
CREATE POLICY "Users can update shared items with edit permission"
ON items FOR UPDATE
USING (
  EXISTS (
    SELECT 1 FROM item_shares
    WHERE item_shares.item_id = items.id
    AND item_shares.user_id = auth.uid()
    AND item_shares.permission = 'edit'
  )
);

-- Users can delete their own items
CREATE POLICY "Users can delete their own items"
ON items FOR DELETE
USING (auth.uid() = created_by);

-- =====================================================
-- ITEM_SHARES TABLE - Simplified RLS
-- =====================================================

-- Users can view shares for items they own
CREATE POLICY "Users can view shares for their items"
ON item_shares FOR SELECT
USING (
  shared_by = auth.uid()
  OR user_id = auth.uid()
);

-- Users can insert shares for items they own
CREATE POLICY "Users can create shares for their items"
ON item_shares FOR INSERT
WITH CHECK (
  shared_by = auth.uid()
  AND EXISTS (
    SELECT 1 FROM items
    WHERE items.id = item_shares.item_id
    AND items.created_by = auth.uid()
  )
);

-- Users can update shares they created
CREATE POLICY "Users can update their shares"
ON item_shares FOR UPDATE
USING (shared_by = auth.uid());

-- Users can delete shares they created
CREATE POLICY "Users can delete their shares"
ON item_shares FOR DELETE
USING (shared_by = auth.uid());

-- =====================================================
-- SPACE_MEMBERS TABLE - Simplified RLS
-- =====================================================

-- Users can view space members where they are a member
CREATE POLICY "Users can view space members"
ON space_members FOR SELECT
USING (
  user_id = auth.uid()
  OR invited_by = auth.uid()
  OR EXISTS (
    SELECT 1 FROM space_members sm
    WHERE sm.space_id = space_members.space_id
    AND sm.user_id = auth.uid()
  )
);

-- Users can insert space members for spaces they own
CREATE POLICY "Users can add space members"
ON space_members FOR INSERT
WITH CHECK (
  invited_by = auth.uid()
  AND EXISTS (
    SELECT 1 FROM spaces
    WHERE spaces.space_id = space_members.space_id
    AND spaces.owner_id = auth.uid()
  )
);

-- Users can update space members they invited
CREATE POLICY "Users can update space members"
ON space_members FOR UPDATE
USING (invited_by = auth.uid());

-- Users can delete space members they invited
CREATE POLICY "Users can delete space members"
ON space_members FOR DELETE
USING (invited_by = auth.uid());

-- =====================================================
-- VERIFICATION
-- =====================================================
-- Check that policies are created:
SELECT schemaname, tablename, policyname 
FROM pg_policies 
WHERE tablename IN ('items', 'item_shares', 'space_members')
ORDER BY tablename, policyname;
