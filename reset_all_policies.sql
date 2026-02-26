-- =====================================================
-- RESET ALL RLS POLICIES - Complete Clean Slate
-- =====================================================
-- Run this in Supabase SQL Editor
-- =====================================================

-- Drop ALL existing policies on items table
DROP POLICY IF EXISTS "Users can view their own items and shared items" ON items;
DROP POLICY IF EXISTS "Users can view their own items" ON items;
DROP POLICY IF EXISTS "Users can view shared items" ON items;
DROP POLICY IF EXISTS "Users can insert their own items" ON items;
DROP POLICY IF EXISTS "Users can update their own items" ON items;
DROP POLICY IF EXISTS "Users can update shared items with edit permission" ON items;
DROP POLICY IF EXISTS "Users can delete their own items" ON items;

-- Drop ALL existing policies on item_shares table
DROP POLICY IF EXISTS "Users can view their own shares and items shared with them" ON item_shares;
DROP POLICY IF EXISTS "Users can view shares for their items" ON item_shares;
DROP POLICY IF EXISTS "Users can create shares for their items" ON item_shares;
DROP POLICY IF EXISTS "Users can update their shares" ON item_shares;
DROP POLICY IF EXISTS "Users can delete their shares" ON item_shares;

-- Drop ALL existing policies on space_members table
DROP POLICY IF EXISTS "Users can view space members where they are members" ON space_members;
DROP POLICY IF EXISTS "Users can view space members" ON space_members;
DROP POLICY IF EXISTS "Users can add space members" ON space_members;
DROP POLICY IF EXISTS "Users can update space members" ON space_members;
DROP POLICY IF EXISTS "Users can delete space members" ON space_members;

-- Drop ALL existing policies on blocks table
DROP POLICY IF EXISTS "Users can view blocks for their items" ON blocks;
DROP POLICY IF EXISTS "Users can insert blocks for their items" ON blocks;
DROP POLICY IF EXISTS "Users can update blocks for their items" ON blocks;
DROP POLICY IF EXISTS "Users can delete blocks for their items" ON blocks;

-- Drop ALL existing policies on spaces table
DROP POLICY IF EXISTS "Users can view their own spaces" ON spaces;
DROP POLICY IF EXISTS "Users can insert their own spaces" ON spaces;
DROP POLICY IF EXISTS "Users can update their own spaces" ON spaces;
DROP POLICY IF EXISTS "Users can delete their own spaces" ON spaces;

-- =====================================================
-- CREATE NEW SIMPLIFIED POLICIES
-- =====================================================

-- ==================== ITEMS TABLE ====================

CREATE POLICY "items_select_own"
ON items FOR SELECT
USING (auth.uid() = created_by);

CREATE POLICY "items_select_shared"
ON items FOR SELECT
USING (
  EXISTS (
    SELECT 1 FROM item_shares
    WHERE item_shares.item_id = items.id
    AND item_shares.user_id = auth.uid()
  )
);

CREATE POLICY "items_insert"
ON items FOR INSERT
WITH CHECK (auth.uid() = created_by);

CREATE POLICY "items_update_own"
ON items FOR UPDATE
USING (auth.uid() = created_by);

CREATE POLICY "items_update_shared"
ON items FOR UPDATE
USING (
  EXISTS (
    SELECT 1 FROM item_shares
    WHERE item_shares.item_id = items.id
    AND item_shares.user_id = auth.uid()
    AND item_shares.permission = 'edit'
  )
);

CREATE POLICY "items_delete"
ON items FOR DELETE
USING (auth.uid() = created_by);

-- ==================== BLOCKS TABLE ====================

CREATE POLICY "blocks_select"
ON blocks FOR SELECT
USING (
  EXISTS (
    SELECT 1 FROM items
    WHERE items.id = blocks.item_id
    AND (
      items.created_by = auth.uid()
      OR EXISTS (
        SELECT 1 FROM item_shares
        WHERE item_shares.item_id = items.id
        AND item_shares.user_id = auth.uid()
      )
    )
  )
);

CREATE POLICY "blocks_insert"
ON blocks FOR INSERT
WITH CHECK (
  EXISTS (
    SELECT 1 FROM items
    WHERE items.id = blocks.item_id
    AND items.created_by = auth.uid()
  )
);

CREATE POLICY "blocks_update"
ON blocks FOR UPDATE
USING (
  EXISTS (
    SELECT 1 FROM items
    WHERE items.id = blocks.item_id
    AND (
      items.created_by = auth.uid()
      OR EXISTS (
        SELECT 1 FROM item_shares
        WHERE item_shares.item_id = items.id
        AND item_shares.user_id = auth.uid()
        AND item_shares.permission = 'edit'
      )
    )
  )
);

CREATE POLICY "blocks_delete"
ON blocks FOR DELETE
USING (
  EXISTS (
    SELECT 1 FROM items
    WHERE items.id = blocks.item_id
    AND items.created_by = auth.uid()
  )
);

-- ==================== ITEM_SHARES TABLE ====================

CREATE POLICY "shares_select"
ON item_shares FOR SELECT
USING (
  shared_by = auth.uid()
  OR user_id = auth.uid()
);

CREATE POLICY "shares_insert"
ON item_shares FOR INSERT
WITH CHECK (shared_by = auth.uid());

CREATE POLICY "shares_update"
ON item_shares FOR UPDATE
USING (shared_by = auth.uid());

CREATE POLICY "shares_delete"
ON item_shares FOR DELETE
USING (shared_by = auth.uid());

-- ==================== SPACES TABLE ====================

CREATE POLICY "spaces_select"
ON spaces FOR SELECT
USING (auth.uid() = owner_id);

CREATE POLICY "spaces_insert"
ON spaces FOR INSERT
WITH CHECK (auth.uid() = owner_id);

CREATE POLICY "spaces_update"
ON spaces FOR UPDATE
USING (auth.uid() = owner_id);

CREATE POLICY "spaces_delete"
ON spaces FOR DELETE
USING (auth.uid() = owner_id);

-- ==================== SPACE_MEMBERS TABLE ====================

CREATE POLICY "members_select"
ON space_members FOR SELECT
USING (
  user_id = auth.uid()
  OR invited_by = auth.uid()
);

CREATE POLICY "members_insert"
ON space_members FOR INSERT
WITH CHECK (invited_by = auth.uid());

CREATE POLICY "members_update"
ON space_members FOR UPDATE
USING (invited_by = auth.uid());

CREATE POLICY "members_delete"
ON space_members FOR DELETE
USING (invited_by = auth.uid());

-- =====================================================
-- VERIFICATION
-- =====================================================
SELECT 
  tablename, 
  policyname,
  cmd as operation
FROM pg_policies 
WHERE tablename IN ('items', 'blocks', 'item_shares', 'spaces', 'space_members')
ORDER BY tablename, policyname;
