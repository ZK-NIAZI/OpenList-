-- =====================================================
-- FIX SHARING SCHEMA: Change UUID columns to TEXT
-- =====================================================
-- This script changes user_id, shared_by, and invited_by 
-- from UUID to TEXT to support email-based sharing

-- Step 1: Drop all policies that reference the columns we're changing
-- =====================================================

-- Drop item_shares policies
DROP POLICY IF EXISTS "Users can view shares for their items" ON item_shares;
DROP POLICY IF EXISTS "Item owners can share items" ON item_shares;
DROP POLICY IF EXISTS "Item owners can update shares" ON item_shares;
DROP POLICY IF EXISTS "Item owners can delete shares" ON item_shares;

-- Drop space_members policies
DROP POLICY IF EXISTS "Users can view space members for spaces they belong to" ON space_members;
DROP POLICY IF EXISTS "Space owners can insert members" ON space_members;
DROP POLICY IF EXISTS "Space owners can update members" ON space_members;
DROP POLICY IF EXISTS "Space owners can delete members" ON space_members;
DROP POLICY IF EXISTS "members_select" ON space_members;

-- Drop items policies that reference item_shares
DROP POLICY IF EXISTS "Users can view their own and shared items" ON items;
DROP POLICY IF EXISTS "Users can view their own items" ON items;

-- Drop spaces policies that reference space_members
DROP POLICY IF EXISTS "Users can view their own and shared spaces" ON spaces;
DROP POLICY IF EXISTS "Users can view their own spaces" ON spaces;

-- Step 2: Drop all foreign key constraints
-- =====================================================

-- Drop foreign keys on item_shares
ALTER TABLE item_shares DROP CONSTRAINT IF EXISTS item_shares_user_id_fkey;
ALTER TABLE item_shares DROP CONSTRAINT IF EXISTS item_shares_shared_by_fkey;

-- Drop foreign keys on space_members
ALTER TABLE space_members DROP CONSTRAINT IF EXISTS space_members_user_id_fkey;
ALTER TABLE space_members DROP CONSTRAINT IF EXISTS space_members_invited_by_fkey;

-- Step 3: Change column types from UUID to TEXT
-- =====================================================

-- Change item_shares columns
ALTER TABLE item_shares ALTER COLUMN user_id TYPE TEXT;
ALTER TABLE item_shares ALTER COLUMN shared_by TYPE TEXT;

-- Change space_members columns
ALTER TABLE space_members ALTER COLUMN user_id TYPE TEXT;
ALTER TABLE space_members ALTER COLUMN invited_by TYPE TEXT;

-- Step 4: Recreate RLS policies with TEXT support
-- =====================================================

-- RLS Policies for item_shares
CREATE POLICY "Users can view shares for their items"
  ON item_shares FOR SELECT
  USING (
    user_id = auth.uid()::text OR
    user_id = auth.email() OR
    item_id IN (
      SELECT id FROM items WHERE created_by = auth.uid()
    )
  );

CREATE POLICY "Item owners can share items"
  ON item_shares FOR INSERT
  WITH CHECK (
    item_id IN (
      SELECT id FROM items WHERE created_by = auth.uid()
    )
  );

CREATE POLICY "Item owners can update shares"
  ON item_shares FOR UPDATE
  USING (
    item_id IN (
      SELECT id FROM items WHERE created_by = auth.uid()
    )
  );

CREATE POLICY "Item owners can delete shares"
  ON item_shares FOR DELETE
  USING (
    item_id IN (
      SELECT id FROM items WHERE created_by = auth.uid()
    )
  );

-- RLS Policies for space_members (simplified to avoid recursion)
CREATE POLICY "members_select"
  ON space_members FOR SELECT
  USING (
    user_id = auth.uid()::text OR
    user_id = auth.email() OR
    invited_by = auth.uid()::text OR
    invited_by = auth.email()
  );

CREATE POLICY "Space owners can insert members"
  ON space_members FOR INSERT
  WITH CHECK (
    space_id IN (
      SELECT id FROM spaces WHERE owner_id = auth.uid()
    )
  );

CREATE POLICY "Space owners can update members"
  ON space_members FOR UPDATE
  USING (
    space_id IN (
      SELECT id FROM spaces WHERE owner_id = auth.uid()
    )
  );

CREATE POLICY "Space owners can delete members"
  ON space_members FOR DELETE
  USING (
    space_id IN (
      SELECT id FROM spaces WHERE owner_id = auth.uid()
    )
  );

-- Update items RLS to include shared items (with TEXT support)
CREATE POLICY "Users can view their own and shared items"
  ON items FOR SELECT
  USING (
    created_by = auth.uid() OR
    id IN (
      SELECT item_id FROM item_shares 
      WHERE user_id = auth.uid()::text OR user_id = auth.email()
    ) OR
    space_id IN (
      SELECT space_id FROM space_members 
      WHERE user_id = auth.uid()::text OR user_id = auth.email()
    )
  );

-- Update spaces RLS to include shared spaces (with TEXT support)
CREATE POLICY "Users can view their own and shared spaces"
  ON spaces FOR SELECT
  USING (
    owner_id = auth.uid() OR
    id IN (
      SELECT space_id FROM space_members 
      WHERE user_id = auth.uid()::text OR user_id = auth.email()
    )
  );

-- Step 5: Verify the changes
-- =====================================================

-- Check column types
SELECT 
  table_name, 
  column_name, 
  data_type 
FROM information_schema.columns 
WHERE table_name IN ('item_shares', 'space_members') 
  AND column_name IN ('user_id', 'shared_by', 'invited_by')
ORDER BY table_name, column_name;

-- Check policies
SELECT 
  tablename, 
  policyname, 
  cmd 
FROM pg_policies 
WHERE tablename IN ('item_shares', 'space_members', 'items', 'spaces')
ORDER BY tablename, policyname;
