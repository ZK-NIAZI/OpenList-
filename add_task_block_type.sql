-- ============================================
-- ADD 'task' AND 'subTask' BLOCK TYPES TO BLOCKS TABLE
-- ============================================
-- This allows blocks to reference tasks (for embedding tasks in notes)
-- Using 'subTask' to match the Dart enum name
-- ============================================

-- Drop the existing check constraint
ALTER TABLE blocks DROP CONSTRAINT IF EXISTS blocks_type_check;

-- Add new check constraint with 'task' and 'subTask' types included
ALTER TABLE blocks ADD CONSTRAINT blocks_type_check 
  CHECK (type IN ('text', 'heading', 'checklist', 'bullet', 'image', 'code', 'task', 'subTask'));

-- Verify the constraint was updated
SELECT 
  conname as constraint_name,
  pg_get_constraintdef(oid) as constraint_definition
FROM pg_constraint
WHERE conname = 'blocks_type_check';

SELECT '✅ Block type constraint updated! Now allows: text, heading, checklist, bullet, image, code, task, subTask' as result;

