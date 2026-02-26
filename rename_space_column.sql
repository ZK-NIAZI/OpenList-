-- Rename space_id column to space in items table
-- This allows storing space names directly instead of IDs

ALTER TABLE items 
RENAME COLUMN space_id TO space;

-- Update the column type to text if needed (it should already be text/uuid)
-- If it was a UUID reference, we're now storing plain text space names like 'Personal', 'Work'

-- Verify the change
SELECT column_name, data_type 
FROM information_schema.columns 
WHERE table_name = 'items' AND column_name = 'space';
