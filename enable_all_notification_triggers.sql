-- ============================================
-- ENABLE ALL NOTIFICATION TRIGGERS
-- ============================================

-- Enable trigger on share
ALTER TABLE item_shares ENABLE TRIGGER trigger_notify_on_share;

-- Enable trigger on unshare
ALTER TABLE item_shares ENABLE TRIGGER trigger_notify_on_unshare;

-- Enable trigger on edit
ALTER TABLE items ENABLE TRIGGER trigger_notify_on_item_edit;

-- Enable trigger on delete
ALTER TABLE items ENABLE TRIGGER trigger_notify_on_item_delete;

-- Verify all triggers are now enabled
SELECT 
  tgname as trigger_name,
  CASE tgenabled
    WHEN 'O' THEN 'enabled'
    WHEN 'D' THEN 'disabled'
    WHEN 'R' THEN 'replica'
    WHEN 'A' THEN 'always'
    ELSE 'unknown'
  END as status,
  tgrelid::regclass as table_name
FROM pg_trigger
WHERE tgname LIKE '%notify%'
AND tgisinternal = false
ORDER BY tgrelid::regclass, tgname;

SELECT '✅ All notification triggers enabled!' as result;
