-- =====================================================
-- FIX SHARING SCHEMA: Change UUID columns to TEXT
-- =====================================================
-- This script changes user_id, shared_by, and invited_by 
-- from UUID to TEXT to support email-based sharing

-- Step 1: Drop ALL policies on ALL tables in the public schema
-- =====================================================

DO $$ 
DECLARE
    r RECORD;
BEGIN
    -- Drop all policies on all tables in public schema
    FOR r IN (
        SELECT schemaname, tablename, policyname 
        FROM pg_policies 
        WHERE schemaname = 'public'
    ) LOOP
        EXECUTE 'DROP POLICY IF EXISTS "' || r.policyname || '" ON ' || r.schemaname || '.' || r.tablename;
        RAISE NOTICE 'Dropped policy: % on table %', r.policyname, r.tablename;
    END LOOP;
END $$;

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

-- RLS Policies for items
CREATE POLICY "Users can view their own items"
  ON items FOR SELECT
  USING (created_by = auth.uid());

CREATE POLICY "Users can view shared items"
  ON items FOR SELECT
  USING (
    id IN (
      SELECT item_id FROM item_shares 
      WHERE user_id = auth.uid()::text OR user_id = auth.email()
    )
  );

CREATE POLICY "Users can view items in shared spaces"
  ON items FOR SELECT
  USING (
    space_id IN (
      SELECT space_id FROM space_members 
      WHERE user_id = auth.uid()::text OR user_id = auth.email()
    )
  );

CREATE POLICY "Users can insert their own items"
  ON items FOR INSERT
  WITH CHECK (created_by = auth.uid());

CREATE POLICY "Users can update their own items"
  ON items FOR UPDATE
  USING (created_by = auth.uid());

CREATE POLICY "Users can update shared items with edit permission"
  ON items FOR UPDATE
  USING (
    id IN (
      SELECT item_id FROM item_shares 
      WHERE (user_id = auth.uid()::text OR user_id = auth.email())
        AND permission = 'edit'
    )
  );

CREATE POLICY "Users can delete their own items"
  ON items FOR DELETE
  USING (created_by = auth.uid());

-- RLS Policies for spaces
CREATE POLICY "Users can view their own spaces"
  ON spaces FOR SELECT
  USING (owner_id = auth.uid());

CREATE POLICY "Users can view shared spaces"
  ON spaces FOR SELECT
  USING (
    id IN (
      SELECT space_id FROM space_members 
      WHERE user_id = auth.uid()::text OR user_id = auth.email()
    )
  );

CREATE POLICY "Users can insert their own spaces"
  ON spaces FOR INSERT
  WITH CHECK (owner_id = auth.uid());

CREATE POLICY "Users can update their own spaces"
  ON spaces FOR UPDATE
  USING (owner_id = auth.uid());

CREATE POLICY "Users can delete their own spaces"
  ON spaces FOR DELETE
  USING (owner_id = auth.uid());

-- RLS Policies for blocks
CREATE POLICY "Users can view blocks for their items"
  ON blocks FOR SELECT
  USING (
    item_id IN (
      SELECT id FROM items WHERE created_by = auth.uid()
    )
  );

CREATE POLICY "Users can view blocks for shared items"
  ON blocks FOR SELECT
  USING (
    item_id IN (
      SELECT item_id FROM item_shares 
      WHERE user_id = auth.uid()::text OR user_id = auth.email()
    )
  );

CREATE POLICY "Users can insert blocks for their items"
  ON blocks FOR INSERT
  WITH CHECK (
    item_id IN (
      SELECT id FROM items WHERE created_by = auth.uid()
    )
  );

CREATE POLICY "Users can update blocks for their items"
  ON blocks FOR UPDATE
  USING (
    item_id IN (
      SELECT id FROM items WHERE created_by = auth.uid()
    )
  );

CREATE POLICY "Users can update blocks for shared items with edit permission"
  ON blocks FOR UPDATE
  USING (
    item_id IN (
      SELECT item_id FROM item_shares 
      WHERE (user_id = auth.uid()::text OR user_id = auth.email())
        AND permission = 'edit'
    )
  );

CREATE POLICY "Users can delete blocks for their items"
  ON blocks FOR DELETE
  USING (
    item_id IN (
      SELECT id FROM items WHERE created_by = auth.uid()
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
WHERE schemaname = 'public'
ORDER BY tablename, policyname;
