-- ============================================
-- FIX SUB-TASK NOTIFICATIONS
-- ============================================
-- Enhance notification triggers to notify users when sub-tasks are updated/deleted
-- Users should be notified if they have access to the PARENT item
-- ============================================

-- ============================================
-- PART 1: Enhanced Edit Notification Function
-- ============================================

CREATE OR REPLACE FUNCTION notify_on_item_edit()
RETURNS TRIGGER AS $$
DECLARE
  v_share RECORD;
  v_editor_name TEXT;
  v_current_user UUID;
  v_notified_users UUID[] := ARRAY[]::UUID[];
BEGIN
  -- Only notify if item was actually updated (not just created)
  IF TG_OP = 'UPDATE' AND OLD.updated_at <> NEW.updated_at THEN
    -- Get current user
    v_current_user := auth.uid();
    
    -- Skip if no current user
    IF v_current_user IS NULL THEN
      RETURN NEW;
    END IF;
    
    -- Get editor name from profiles table
    BEGIN
      SELECT display_name INTO v_editor_name 
      FROM profiles 
      WHERE id = v_current_user;
      
      IF v_editor_name IS NULL OR v_editor_name = '' THEN
        SELECT email INTO v_editor_name FROM auth.users WHERE id = v_current_user;
        IF v_editor_name IS NOT NULL AND v_editor_name LIKE '%@%' THEN
          v_editor_name := split_part(v_editor_name, '@', 1);
        END IF;
      END IF;
      
      IF v_editor_name IS NULL OR v_editor_name = '' THEN
        v_editor_name := 'Someone';
      END IF;
    EXCEPTION WHEN OTHERS THEN
      v_editor_name := 'Someone';
    END;
    
    -- Notify users who have DIRECT access to this item
    FOR v_share IN 
      SELECT user_id FROM item_shares 
      WHERE item_id = NEW.id AND user_id <> v_current_user
    LOOP
      BEGIN
        INSERT INTO notifications (user_id, type, title, message, item_id, related_user_id)
        VALUES (
          v_share.user_id,
          'update',
          'Item updated',
          v_editor_name || ' updated "' || NEW.title || '"',
          NEW.id,
          v_current_user
        );
        v_notified_users := array_append(v_notified_users, v_share.user_id);
      EXCEPTION WHEN OTHERS THEN
        RAISE WARNING 'Failed to create edit notification: %', SQLERRM;
      END;
    END LOOP;
    
    -- If this is a SUB-TASK, also notify users who have access to the PARENT
    IF NEW.parent_id IS NOT NULL THEN
      FOR v_share IN 
        SELECT user_id FROM item_shares 
        WHERE item_id = NEW.parent_id 
        AND user_id <> v_current_user
        AND user_id <> ALL(v_notified_users)  -- Don't notify twice
      LOOP
        BEGIN
          INSERT INTO notifications (user_id, type, title, message, item_id, related_user_id)
          VALUES (
            v_share.user_id,
            'update',
            'Sub-task updated',
            v_editor_name || ' updated sub-task "' || NEW.title || '"',
            NEW.id,
            v_current_user
          );
          v_notified_users := array_append(v_notified_users, v_share.user_id);
        EXCEPTION WHEN OTHERS THEN
          RAISE WARNING 'Failed to create sub-task edit notification: %', SQLERRM;
        END;
      END LOOP;
    END IF;
    
    -- Notify the owner if they didn't make the edit and haven't been notified yet
    IF NEW.created_by <> v_current_user 
       AND NEW.created_by IS NOT NULL 
       AND NEW.created_by <> ALL(v_notified_users) THEN
      BEGIN
        INSERT INTO notifications (user_id, type, title, message, item_id, related_user_id)
        VALUES (
          NEW.created_by,
          'update',
          CASE WHEN NEW.parent_id IS NOT NULL THEN 'Sub-task updated' ELSE 'Item updated' END,
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

-- ============================================
-- PART 2: Enhanced Delete Notification Function
-- ============================================

CREATE OR REPLACE FUNCTION notify_on_item_delete()
RETURNS TRIGGER AS $$
DECLARE
  v_share RECORD;
  v_deleter_name TEXT;
  v_current_user UUID;
  v_notified_users UUID[] := ARRAY[]::UUID[];
BEGIN
  -- Get current user
  v_current_user := auth.uid();
  
  -- Skip if no current user
  IF v_current_user IS NULL THEN
    RETURN OLD;
  END IF;
  
  -- Get deleter name from profiles table
  BEGIN
    SELECT display_name INTO v_deleter_name 
    FROM profiles 
    WHERE id = v_current_user;
    
    IF v_deleter_name IS NULL OR v_deleter_name = '' THEN
      SELECT email INTO v_deleter_name FROM auth.users WHERE id = v_current_user;
      IF v_deleter_name IS NOT NULL AND v_deleter_name LIKE '%@%' THEN
        v_deleter_name := split_part(v_deleter_name, '@', 1);
      END IF;
    END IF;
    
    IF v_deleter_name IS NULL OR v_deleter_name = '' THEN
      v_deleter_name := 'Someone';
    END IF;
  EXCEPTION WHEN OTHERS THEN
    v_deleter_name := 'Someone';
  END;
  
  -- Notify users who have DIRECT access to this item
  FOR v_share IN 
    SELECT user_id FROM item_shares 
    WHERE item_id = OLD.id AND user_id <> v_current_user
  LOOP
    BEGIN
      INSERT INTO notifications (user_id, type, title, message, item_id, related_user_id)
      VALUES (
        v_share.user_id,
        'delete',
        'Item deleted',
        v_deleter_name || ' deleted "' || OLD.title || '"',
        OLD.id,
        v_current_user
      );
      v_notified_users := array_append(v_notified_users, v_share.user_id);
    EXCEPTION WHEN OTHERS THEN
      RAISE WARNING 'Failed to create delete notification: %', SQLERRM;
    END;
  END LOOP;
  
  -- If this is a SUB-TASK, also notify users who have access to the PARENT
  IF OLD.parent_id IS NOT NULL THEN
    FOR v_share IN 
      SELECT user_id FROM item_shares 
      WHERE item_id = OLD.parent_id 
      AND user_id <> v_current_user
      AND user_id <> ALL(v_notified_users)  -- Don't notify twice
    LOOP
      BEGIN
        INSERT INTO notifications (user_id, type, title, message, item_id, related_user_id)
        VALUES (
          v_share.user_id,
          'delete',
          'Sub-task deleted',
          v_deleter_name || ' deleted sub-task "' || OLD.title || '"',
          OLD.id,
          v_current_user
        );
        v_notified_users := array_append(v_notified_users, v_share.user_id);
      EXCEPTION WHEN OTHERS THEN
        RAISE WARNING 'Failed to create sub-task delete notification: %', SQLERRM;
      END;
    END LOOP;
  END IF;
  
  -- Notify the owner if they didn't delete it and haven't been notified yet
  IF OLD.created_by <> v_current_user 
     AND OLD.created_by IS NOT NULL 
     AND OLD.created_by <> ALL(v_notified_users) THEN
    BEGIN
      INSERT INTO notifications (user_id, type, title, message, item_id, related_user_id)
      VALUES (
        OLD.created_by,
        'delete',
        CASE WHEN OLD.parent_id IS NOT NULL THEN 'Sub-task deleted' ELSE 'Item deleted' END,
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

-- ============================================
-- PART 3: Recreate Triggers
-- ============================================

DROP TRIGGER IF EXISTS trigger_notify_on_item_edit ON items;
CREATE TRIGGER trigger_notify_on_item_edit
AFTER UPDATE ON items
FOR EACH ROW
EXECUTE FUNCTION notify_on_item_edit();

DROP TRIGGER IF EXISTS trigger_notify_on_item_delete ON items;
CREATE TRIGGER trigger_notify_on_item_delete
BEFORE DELETE ON items
FOR EACH ROW
EXECUTE FUNCTION notify_on_item_delete();

-- ============================================
-- VERIFICATION
-- ============================================

SELECT 
  '✅ Sub-task Notification Triggers Updated!' as status,
  'Now notifying users who have access to parent items when sub-tasks are updated/deleted' as description;

-- Check triggers are enabled
SELECT 
  tgname as trigger_name,
  CASE tgenabled
    WHEN 'O' THEN '✅ ENABLED'
    WHEN 'D' THEN '❌ DISABLED'
    ELSE '⚠️ OTHER'
  END as status,
  tgrelid::regclass as table_name
FROM pg_trigger
WHERE tgname IN ('trigger_notify_on_item_edit', 'trigger_notify_on_item_delete')
AND tgisinternal = false
ORDER BY tgname;

