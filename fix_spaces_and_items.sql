-- =====================================================
-- FIX SPACES AND ITEMS
-- =====================================================

-- Step 1: Ensure spaces table exists
CREATE TABLE IF NOT EXISTS spaces (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  owner_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  color TEXT NOT NULL DEFAULT '#6366F1',
  icon TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create index
CREATE INDEX IF NOT EXISTS idx_spaces_owner_id ON spaces(owner_id);

-- Enable RLS
ALTER TABLE spaces ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if they exist
DROP POLICY IF EXISTS "spaces_select_own" ON spaces;
DROP POLICY IF EXISTS "spaces_insert_own" ON spaces;
DROP POLICY IF EXISTS "spaces_update_own" ON spaces;
DROP POLICY IF EXISTS "spaces_delete_own" ON spaces;

-- RLS Policies
CREATE POLICY "spaces_select_own"
  ON spaces FOR SELECT
  USING (owner_id = auth.uid());

CREATE POLICY "spaces_insert_own"
  ON spaces FOR INSERT
  WITH CHECK (owner_id = auth.uid());

CREATE POLICY "spaces_update_own"
  ON spaces FOR UPDATE
  USING (owner_id = auth.uid())
  WITH CHECK (owner_id = auth.uid());

CREATE POLICY "spaces_delete_own"
  ON spaces FOR DELETE
  USING (owner_id = auth.uid());

-- Step 2: Add space_id column to items if it doesn't exist
DO $$ 
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'items' AND column_name = 'space_id'
  ) THEN
    ALTER TABLE items ADD COLUMN space_id UUID REFERENCES spaces(id) ON DELETE SET NULL;
    CREATE INDEX idx_items_space_id ON items(space_id);
  END IF;
END $$;

-- Step 3: Create default spaces for ALL existing users
INSERT INTO spaces (owner_id, name, color)
SELECT 
  u.id,
  'Personal',
  '#6366F1'
FROM auth.users u
WHERE NOT EXISTS (
  SELECT 1 FROM spaces WHERE owner_id = u.id AND name = 'Personal'
);

INSERT INTO spaces (owner_id, name, color)
SELECT 
  u.id,
  'Work',
  '#F59E0B'
FROM auth.users u
WHERE NOT EXISTS (
  SELECT 1 FROM spaces WHERE owner_id = u.id AND name = 'Work'
);

-- Step 4: Assign all existing items without space_id to Personal space
UPDATE items
SET space_id = (
  SELECT id FROM spaces 
  WHERE owner_id = items.created_by 
  AND name = 'Personal' 
  LIMIT 1
)
WHERE space_id IS NULL
AND created_by IS NOT NULL;

-- =====================================================
-- VERIFICATION
-- =====================================================

-- Show all spaces
SELECT 
  spaces.id,
  spaces.name,
  spaces.color,
  auth.users.email as owner_email,
  spaces.created_at
FROM spaces
JOIN auth.users ON auth.users.id = spaces.owner_id
ORDER BY spaces.created_at DESC;

-- Show items with their spaces
SELECT 
  items.id,
  items.title,
  items.space_id,
  spaces.name as space_name,
  auth.users.email as owner_email
FROM items
LEFT JOIN spaces ON spaces.id = items.space_id
LEFT JOIN auth.users ON auth.users.id = items.created_by
ORDER BY items.updated_at DESC
LIMIT 20;

-- Count items per space
SELECT 
  spaces.name,
  COUNT(items.id) as item_count
FROM spaces
LEFT JOIN items ON items.space_id = spaces.id
GROUP BY spaces.id, spaces.name
ORDER BY spaces.name;
