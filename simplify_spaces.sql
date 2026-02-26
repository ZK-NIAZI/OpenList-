-- =====================================================
-- SIMPLIFY SPACES - USE TEXT COLUMN INSTEAD OF TABLE
-- =====================================================

-- Step 1: Drop the spaces table and related constraints
DROP TABLE IF EXISTS space_members CASCADE;
DROP TABLE IF EXISTS spaces CASCADE;

-- Step 2: Ensure items table has space column as TEXT (not UUID)
DO $$ 
BEGIN
  -- Drop the old space_id column if it exists
  IF EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'items' AND column_name = 'space_id'
  ) THEN
    ALTER TABLE items DROP COLUMN space_id;
  END IF;
  
  -- Add space column as TEXT if it doesn't exist
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'items' AND column_name = 'space'
  ) THEN
    ALTER TABLE items ADD COLUMN space TEXT DEFAULT 'Personal';
  END IF;
END $$;

-- Step 3: Create index for faster filtering
CREATE INDEX IF NOT EXISTS idx_items_space ON items(space);

-- Step 4: Set default space for all existing items without a space
UPDATE items
SET space = 'Personal'
WHERE space IS NULL OR space = '';

-- =====================================================
-- VERIFICATION
-- =====================================================

-- Show items with their spaces
SELECT 
  items.id,
  items.title,
  items.space,
  items.type,
  auth.users.email as owner_email,
  items.updated_at
FROM items
LEFT JOIN auth.users ON auth.users.id = items.created_by
ORDER BY items.updated_at DESC
LIMIT 20;

-- Count items per space
SELECT 
  COALESCE(space, 'No Space') as space_name,
  COUNT(*) as item_count
FROM items
GROUP BY space
ORDER BY space_name;
