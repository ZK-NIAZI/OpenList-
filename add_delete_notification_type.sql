-- =====================================================
-- ADD 'delete' NOTIFICATION TYPE
-- =====================================================
-- This allows delete notifications to be created
-- Date: 2026-02-25

-- Drop the existing constraint
ALTER TABLE notifications 
DROP CONSTRAINT IF EXISTS notifications_type_check;

-- Add new constraint with 'delete' type included
ALTER TABLE notifications 
ADD CONSTRAINT notifications_type_check 
CHECK (type IN ('share', 'unshare', 'update', 'delete', 'reminder', 'deadline', 'comment'));

-- Verify the constraint
SELECT 
    '✅ Notification types updated!' as status,
    'Allowed types: share, unshare, update, delete, reminder, deadline, comment' as info;

-- Show current constraint
SELECT 
    conname as constraint_name,
    pg_get_constraintdef(oid) as constraint_definition
FROM pg_constraint
WHERE conname = 'notifications_type_check';

