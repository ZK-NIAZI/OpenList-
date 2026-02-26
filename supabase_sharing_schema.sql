-- Space Members Table (for sharing entire spaces)
CREATE TABLE IF NOT EXISTS space_members (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  space_id UUID NOT NULL REFERENCES spaces(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  role TEXT NOT NULL CHECK (role IN ('owner', 'editor', 'viewer')),
  invited_by UUID REFERENCES auth.users(id),
  invited_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  accepted_at TIMESTAMP WITH TIME ZONE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(space_id, user_id)
);

-- Item Shares Table (for sharing individual tasks/notes)
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

-- Indexes for performance
CREATE INDEX IF NOT EXISTS idx_space_members_space_id ON space_members(space_id);
CREATE INDEX IF NOT EXISTS idx_space_members_user_id ON space_members(user_id);
CREATE INDEX IF NOT EXISTS idx_item_shares_item_id ON item_shares(item_id);
CREATE INDEX IF NOT EXISTS idx_item_shares_user_id ON item_shares(user_id);

-- Enable RLS
ALTER TABLE space_members ENABLE ROW LEVEL SECURITY;
ALTER TABLE item_shares ENABLE ROW LEVEL SECURITY;

-- RLS Policies for space_members
CREATE POLICY "Users can view space members for spaces they belong to"
  ON space_members FOR SELECT
  USING (
    user_id = auth.uid() OR
    space_id IN (
      SELECT space_id FROM space_members WHERE user_id = auth.uid()
    )
  );

CREATE POLICY "Space owners can insert members"
  ON space_members FOR INSERT
  WITH CHECK (
    space_id IN (
      SELECT space_id FROM space_members 
      WHERE user_id = auth.uid() AND role = 'owner'
    )
  );

CREATE POLICY "Space owners can update members"
  ON space_members FOR UPDATE
  USING (
    space_id IN (
      SELECT space_id FROM space_members 
      WHERE user_id = auth.uid() AND role = 'owner'
    )
  );

CREATE POLICY "Space owners can delete members"
  ON space_members FOR DELETE
  USING (
    space_id IN (
      SELECT space_id FROM space_members 
      WHERE user_id = auth.uid() AND role = 'owner'
    )
  );

-- RLS Policies for item_shares
CREATE POLICY "Users can view shares for their items"
  ON item_shares FOR SELECT
  USING (
    user_id = auth.uid() OR
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

-- Update items RLS to include shared items
DROP POLICY IF EXISTS "Users can view their own items" ON items;
CREATE POLICY "Users can view their own and shared items"
  ON items FOR SELECT
  USING (
    created_by = auth.uid() OR
    id IN (
      SELECT item_id FROM item_shares WHERE user_id = auth.uid()
    ) OR
    space_id IN (
      SELECT space_id FROM space_members WHERE user_id = auth.uid()
    )
  );

-- Update spaces RLS to include shared spaces
DROP POLICY IF EXISTS "Users can view their own spaces" ON spaces;
CREATE POLICY "Users can view their own and shared spaces"
  ON spaces FOR SELECT
  USING (
    owner_id = auth.uid() OR
    id IN (
      SELECT space_id FROM space_members WHERE user_id = auth.uid()
    )
  );

-- Function to automatically add creator as owner when space is created
CREATE OR REPLACE FUNCTION add_space_owner()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO space_members (space_id, user_id, role, invited_by)
  VALUES (NEW.id, NEW.owner_id, 'owner', NEW.owner_id);
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER on_space_created
  AFTER INSERT ON spaces
  FOR EACH ROW
  EXECUTE FUNCTION add_space_owner();
