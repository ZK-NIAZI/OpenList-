-- ============================================
-- FIX NOTIFICATION TYPES
-- Change 'edit' to 'update' to match NotificationType enum
-- ============================================

-- ============================================
-- TRIGGER: Notify on Edit (using 'update' type)
-- ============================================

CREATE OR REPLACE FUNCTION notify_on_item_edit()
RETURNS TRIGGER AS $$
DECLARE
  v_share RECORD;
  v_editor_name TEXT;
  v_current_user UUID;
BEGIN
  -- Only notify if item was actually updated (not just created)
  IF TG_OP = 'UPDATE' AND OLD.updated_at <> NEW.updated_at THEN
    -- Get current user
    v_current_user := auth.uid();
    
    -- Skip if no current user (shouldn't happen but safety check)
    IF v_current_user IS NULL THEN
      RETURN NEW;
    END IF;
    
    -- Get editor name from profiles table (display_name only)
    BEGIN
      SELECT display_name INTO v_editor_name 
      FROM profiles 
      WHERE id = v_current_user;
      
      IF v_editor_name IS NULL OR v_editor_name = '' THEN
        -- Fallback to email from auth.users
        SELECT email INTO v_editor_name FROM auth.users WHERE id = v_current_user;
        
        -- Extract username from email if we got it
        IF v_editor_name IS NOT NULL AND v_editor_name LIKE '%@%' THEN
          v_editor_name := split_part(v_editor_name, '@', 1);
        END IF;
      END IF;
      
      -- Final fallback
      IF v_editor_name IS NULL OR v_editor_name = '' THEN
        v_editor_name := 'Someone';
      END IF;
    EXCEPTION WHEN OTHERS THEN
      v_editor_name := 'Someone';
    END;
    
    -- Notify all users who have access (except the editor)
    FOR v_share IN 
      SELECT user_id FROM item_shares 
      WHERE item_id = NEW.id AND user_id <> v_current_user
    LOOP
      BEGIN
        INSERT INTO notifications (user_id, type, title, message, item_id, related_user_id)
        VALUES (
          v_share.user_id,
          'update',  -- Changed from 'edit' to 'update'
          'Item updated',
          v_editor_name || ' updated "' || NEW.title || '"',
          NEW.id,
          v_current_user
        );
      EXCEPTION WHEN OTHERS THEN
        RAISE WARNING 'Failed to create edit notification: %', SQLERRM;
      END;
    END LOOP;
    
    -- Also notify the owner if they didn't make the edit
    IF NEW.created_by <> v_current_user AND NEW.created_by IS NOT NULL THEN
      BEGIN
        INSERT INTO notifications (user_id, type, title, message, item_id, related_user_id)
        VALUES (
          NEW.created_by,
          'update',  -- Changed from 'edit' to 'update'
          'Item updated',
          v_editor_name || ' updated "' || NEW.title || '"',
          NEW.id,
          v_current_user
        );
      EXCEPTION WHEN OTHERS THEN
        RAISE WARNING 'Failed to create owner edit notification: %', SQLERRM;
      END;
    END IF;
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS trigger_notify_on_item_edit ON items;
CREATE TRIGGER trigger_notify_on_item_edit
AFTER UPDATE ON items
FOR EACH ROW
EXECUTE FUNCTION notify_on_item_edit();

-- ============================================
-- TRIGGER: Notify on Delete (using 'unshare' type)
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
  
  -- Notify all users who had access (except the deleter)
  FOR v_share IN 
    SELECT user_id FROM item_shares 
    WHERE item_id = OLD.id AND user_id <> v_current_user
  LOOP
    BEGIN
      INSERT INTO notifications (user_id, type, title, message, item_id, related_user_id)
      VALUES (
        v_share.user_id,
        'unshare',  -- Using 'unshare' for delete notifications
        'Item deleted',
        v_deleter_name || ' deleted "' || OLD.title || '"',
        OLD.id,
        v_current_user
      );
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
        'unshare',  -- Using 'unshare' for delete notifications
        'Item deleted',
        v_deleter_name || ' deleted "' || OLD.title || '"',
        OLD.id,
        v_current_user
      );
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

SELECT '✅ Notification types fixed! Edit notifications now use "update" type.' as status;

-- Show all notification triggers
SELECT 
  trigger_name,
  event_manipulation,
  event_object_table,
  action_timing
FROM information_schema.triggers 
WHERE trigger_schema = 'public' 
AND trigger_name LIKE '%notify%'
ORDER BY event_object_table, trigger_name;
