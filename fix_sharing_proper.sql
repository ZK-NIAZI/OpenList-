-- =====================================================
-- PROPER FIX FOR SHARING FEATURE
-- =====================================================
-- This approach keeps UUID columns and adds email lookup
-- =====================================================

-- Step 1: Drop ALL existing policies to start fresh
-- =====================================================

DO $$ 
DECLARE
    r RECORD;
BEGIN
    FOR r IN (
        SELECT schemaname, tablename, policyname 
        FROM pg_policies 
        WHERE schemaname = 'public'
    ) LOOP
        EXECUTE 'DROP POLICY IF EXISTS "' || r.policyname || '" ON ' || r.schemaname || '.' || r.tablename;
        RAISE NOTICE 'Dropped policy: % on table %', r.policyname, r.tablename;
    END LOOP;
END $$;

-- Step 2: Ensure tables exist with correct structure
-- =====================================================

-- Create item_shares if not exists (with UUID columns)
CREATE TABLE IF NOT EXISTS item_shares (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  item_id UUID NOT NULL REFERENCES items(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  permission TEXT NOT NULL CHECK (permission IN ('edit', 'view')),
  shared_by UUID REFERENCES auth.users(id),
  shared_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(item_id, user_id)
);

-- Create space_members if not exists (with UUID columns)
CREATE TABLE IF NOT EXISTS space_members (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  space_id UUID NOT NULL REFERENCES spaces(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  role TEXT NOT NULL CHECK (role IN ('owner', 'editor', 'viewer')),
  invited_by UUID REFERENCES auth.users(id),
  invited_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  accepted_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(space_id, user_id)
);

-- Create indexes
CREATE INDEX IF NOT EXISTS idx_item_shares_item_id ON item_shares(item_id);
CREATE INDEX IF NOT EXISTS idx_item_shares_user_id ON item_shares(user_id);
CREATE INDEX IF NOT EXISTS idx_space_members_space_id ON space_members(space_id);
CREATE INDEX IF NOT EXISTS idx_space_members_user_id ON space_members(user_id);

-- Enable RLS
ALTER TABLE item_shares ENABLE ROW LEVEL SECURITY;
ALTER TABLE space_members ENABLE ROW LEVEL SECURITY;

-- Step 3: Create helper function to lookup user by email
-- =====================================================

CREATE OR REPLACE FUNCTION get_user_id_by_email(email_address TEXT)
RETURNS UUID AS $$
DECLARE
  user_uuid UUID;
BEGIN
  SELECT id INTO user_uuid
  FROM auth.users
  WHERE email = email_address
  LIMIT 1;
  
  RETURN user_uuid;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Step 4: Create simple, non-recursive RLS policies
-- =====================================================

-- ITEM_SHARES POLICIES
CREATE POLICY "item_shares_select"
  ON item_shares FOR SELECT
  USING (
    user_id = auth.uid() OR
    shared_by = auth.uid()
  );

CREATE POLICY "item_shares_insert"
  ON item_shares FOR INSERT
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM items 
      WHERE items.id = item_shares.item_id 
      AND items.created_by = auth.uid()
    )
  );

CREATE POLICY "item_shares_update"
  ON item_shares FOR UPDATE
  USING (
    EXISTS (
      SELECT 1 FROM items 
      WHERE items.id = item_shares.item_id 
      AND items.created_by = auth.uid()
    )
  );

CREATE POLICY "item_shares_delete"
  ON item_shares FOR DELETE
  USING (
    EXISTS (
      SELECT 1 FROM items 
      WHERE items.id = item_shares.item_id 
      AND items.created_by = auth.uid()
    )
  );

-- SPACE_MEMBERS POLICIES (simple, no recursion)
CREATE POLICY "space_members_select"
  ON space_members FOR SELECT
  USING (
    user_id = auth.uid() OR
    invited_by = auth.uid()
  );

CREATE POLICY "space_members_insert"
  ON space_members FOR INSERT
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM spaces 
      WHERE spaces.id = space_members.space_id 
      AND spaces.owner_id = auth.uid()
    )
  );

CREATE POLICY "space_members_update"
  ON space_members FOR UPDATE
  USING (
    EXISTS (
      SELECT 1 FROM spaces 
      WHERE spaces.id = space_members.space_id 
      AND spaces.owner_id = auth.uid()
    )
  );

CREATE POLICY "space_members_delete"
  ON space_members FOR DELETE
  USING (
    EXISTS (
      SELECT 1 FROM spaces 
      WHERE spaces.id = space_members.space_id 
      AND spaces.owner_id = auth.uid()
    )
  );

-- ITEMS POLICIES
CREATE POLICY "items_select_own"
  ON items FOR SELECT
  USING (created_by = auth.uid());

CREATE POLICY "items_select_shared"
  ON items FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM item_shares 
      WHERE item_shares.item_id = items.id 
      AND item_shares.user_id = auth.uid()
    )
  );

CREATE POLICY "items_select_space_shared"
  ON items FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM space_members 
      WHERE space_members.space_id = items.space_id 
      AND space_members.user_id = auth.uid()
    )
  );

CREATE POLICY "items_insert"
  ON items FOR INSERT
  WITH CHECK (created_by = auth.uid());

CREATE POLICY "items_update_own"
  ON items FOR UPDATE
  USING (created_by = auth.uid());

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
  USING (created_by = auth.uid());

-- SPACES POLICIES
CREATE POLICY "spaces_select_own"
  ON spaces FOR SELECT
  USING (owner_id = auth.uid());

CREATE POLICY "spaces_select_shared"
  ON spaces FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM space_members 
      WHERE space_members.space_id = spaces.id 
      AND space_members.user_id = auth.uid()
    )
  );

CREATE POLICY "spaces_insert"
  ON spaces FOR INSERT
  WITH CHECK (owner_id = auth.uid());

CREATE POLICY "spaces_update"
  ON spaces FOR UPDATE
  USING (owner_id = auth.uid());

CREATE POLICY "spaces_delete"
  ON spaces FOR DELETE
  USING (owner_id = auth.uid());

-- BLOCKS POLICIES
CREATE POLICY "blocks_select_own"
  ON blocks FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM items 
      WHERE items.id = blocks.item_id 
      AND items.created_by = auth.uid()
    )
  );

CREATE POLICY "blocks_select_shared"
  ON blocks FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM items 
      JOIN item_shares ON item_shares.item_id = items.id
      WHERE items.id = blocks.item_id 
      AND item_shares.user_id = auth.uid()
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

CREATE POLICY "blocks_update_own"
  ON blocks FOR UPDATE
  USING (
    EXISTS (
      SELECT 1 FROM items 
      WHERE items.id = blocks.item_id 
      AND items.created_by = auth.uid()
    )
  );

CREATE POLICY "blocks_update_shared"
  ON blocks FOR UPDATE
  USING (
    EXISTS (
      SELECT 1 FROM items 
      JOIN item_shares ON item_shares.item_id = items.id
      WHERE items.id = blocks.item_id 
      AND item_shares.user_id = auth.uid()
      AND item_shares.permission = 'edit'
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

-- Step 5: Verify setup
-- =====================================================

SELECT 'Tables created' AS status;
SELECT tablename, policyname FROM pg_policies WHERE schemaname = 'public' ORDER BY tablename, policyname;
