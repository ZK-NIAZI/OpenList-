-- ============================================
-- FIX DELETE NOTIFICATION MESSAGE
-- Change "Item deleted" to "Item removed"
-- ============================================

CREATE OR REPLACE FUNCTION notify_on_item_delete()
RETURNS TRIGGER AS $$
DECLARE
  v_share RECORD;
  v_deleter_name TEXT;
  v_current_user UUID;
BEGIN
  -- Get current user
  v_current_user := auth.uid();
  
  -- Skip if no current user
  IF v_current_user IS NULL THEN
    RETURN OLD;
  END IF;
  
  -- Get deleter name from profiles table (display_name only)
  BEGIN
    SELECT display_name INTO v_deleter_name 
    FROM profiles 
    WHERE id = v_current_user;
    
    IF v_deleter_name IS NULL OR v_deleter_name = '' THEN
      -- Fallback to email from auth.users
      SELECT email INTO v_deleter_name FROM auth.users WHERE id = v_current_user;
      
      -- Extract username from email if we got it
      IF v_deleter_name IS NOT NULL AND v_deleter_name LIKE '%@%' THEN
        v_deleter_name := split_part(v_deleter_name, '@', 1);
      END IF;
    END IF;
    
    -- Final fallback
    IF v_deleter_name IS NULL OR v_deleter_name = '' THEN
      v_deleter_name := 'Someone';
    END IF;
  EXCEPTION WHEN OTHERS THEN
    v_deleter_name := 'Someone';
  END;
  
  RAISE NOTICE 'DELETE TRIGGER FIRED: Item % being deleted by %', OLD.id, v_deleter_name;
  
  -- Notify all users who had access (except the deleter)
  FOR v_share IN 
    SELECT user_id FROM item_shares 
    WHERE item_id = OLD.id AND user_id <> v_current_user
  LOOP
    BEGIN
      INSERT INTO notifications (user_id, type, title, message, item_id, related_user_id)
      VALUES (
        v_share.user_id,
        'unshare',
        'Item removed',  -- Changed from "Item deleted" to "Item removed"
        v_deleter_name || ' removed "' || OLD.title || '"',  -- Changed "deleted" to "removed"
        OLD.id,
        v_current_user
      );
      RAISE NOTICE 'Created delete notification for user %', v_share.user_id;
    EXCEPTION WHEN OTHERS THEN
      RAISE WARNING 'Failed to create delete notification: %', SQLERRM;
    END;
  END LOOP;
  
  -- Also notify the owner if they didn't delete it
  IF OLD.created_by <> v_current_user AND OLD.created_by IS NOT NULL THEN
    BEGIN
      INSERT INTO notifications (user_id, type, title, message, item_id, related_user_id)
      VALUES (
        OLD.created_by,
        'unshare',
        'Item removed',  -- Changed from "Item deleted" to "Item removed"
        v_deleter_name || ' removed "' || OLD.title || '"',  -- Changed "deleted" to "removed"
        OLD.id,
        v_current_user
      );
      RAISE NOTICE 'Created delete notification for owner %', OLD.created_by;
    EXCEPTION WHEN OTHERS THEN
      RAISE WARNING 'Failed to create owner delete notification: %', SQLERRM;
    END;
  END IF;
  
  RETURN OLD;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS trigger_notify_on_item_delete ON items;
CREATE TRIGGER trigger_notify_on_item_delete
BEFORE DELETE ON items
FOR EACH ROW
EXECUTE FUNCTION notify_on_item_delete();

-- ============================================
-- VERIFICATION
-- ============================================

SELECT '✅ Delete notification message updated to "removed"!' as status;

-- Show the trigger
SELECT 
  trigger_name,
  event_manipulation,
  event_object_table,
  action_timing
FROM information_schema.triggers 
WHERE trigger_schema = 'public' 
AND trigger_name = 'trigger_notify_on_item_delete';
