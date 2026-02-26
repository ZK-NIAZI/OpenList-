-- ============================================
-- FIX UPSERT TRIGGER ISSUE
-- ============================================
-- Problem: Supabase upsert() uses INSERT ... ON CONFLICT DO UPDATE
-- This might not trigger AFTER UPDATE triggers properly
-- Solution: Ensure trigger fires on both INSERT and UPDATE

-- Drop existing trigger
DROP TRIGGER IF EXISTS trigger_notify_on_block_edit ON blocks;

-- Recreate trigger to fire on BOTH INSERT and UPDATE
CREATE TRIGGER trigger_notify_on_block_edit
AFTER INSERT OR UPDATE ON blocks
FOR EACH ROW
EXECUTE FUNCTION notify_on_block_edit();

-- Verify trigger is enabled
SELECT 
  tgname as trigger_name,
  CASE tgenabled
    WHEN 'O' THEN 'enabled'
    WHEN 'D' THEN 'disabled'
    ELSE 'unknown'
  END as status,
  tgrelid::regclass as table_name,
  CASE 
    WHEN tgtype & 2 = 2 THEN 'BEFORE'
    WHEN tgtype & 4 = 4 THEN 'INSTEAD OF'
    ELSE 'AFTER'
  END as timing,
  CASE 
    WHEN tgtype & 4 = 4 THEN 'INSERT'
    WHEN tgtype & 8 = 8 THEN 'DELETE'
    WHEN tgtype & 16 = 16 THEN 'UPDATE'
    WHEN tgtype & 32 = 32 THEN 'TRUNCATE'
    ELSE 'MULTIPLE'
  END as event
FROM pg_trigger
WHERE tgname = 'trigger_notify_on_block_edit';

SELECT '✅ Trigger now fires on INSERT OR UPDATE!' as result;
