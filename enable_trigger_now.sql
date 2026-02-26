-- Enable the trigger
ALTER TABLE blocks ENABLE TRIGGER trigger_notify_on_block_edit;

-- Verify it's enabled
SELECT 
  tgname as trigger_name,
  CASE tgenabled
    WHEN 'O' THEN '✅ ENABLED'
    WHEN 'D' THEN '❌ DISABLED'
    ELSE tgenabled::text
  END as status,
  tgrelid::regclass as table_name
FROM pg_trigger
WHERE tgname = 'trigger_notify_on_block_edit';

SELECT '✅ Trigger is now enabled!' as result;
