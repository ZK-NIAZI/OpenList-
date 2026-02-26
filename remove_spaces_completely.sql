-- Remove spaces feature completely from Supabase
-- This simplifies the app and ensures sharing works seamlessly

-- First, drop any policies that depend on the space column
DROP POLICY IF EXISTS items_select_space_shared ON items;
DROP POLICY IF EXISTS items_select_space ON items;
DROP POLICY IF EXISTS items_insert_space ON items;
DROP POLICY IF EXISTS items_update_space ON items;
DROP POLICY IF EXISTS items_delete_space ON items;

-- Now drop the space_id column from items table
ALTER TABLE items 
DROP COLUMN IF EXISTS space_id CASCADE;

-- Also drop space column if it exists
ALTER TABLE items 
DROP COLUMN IF EXISTS space CASCADE;

-- Verify the change
SELECT column_name, data_type 
FROM information_schema.columns 
WHERE table_name = 'items' 
ORDER BY ordinal_position;
