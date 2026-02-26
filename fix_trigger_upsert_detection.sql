-- ============================================
-- FIX TRIGGER TO DETECT UPSERT UPDATES
-- ============================================
-- Problem: The trigger checks if OLD.content <> NEW.content
-- But in an upsert, if content is the same, trigger doesn't fire
-- Solution: Check updated_at timestamp instead

-- Drop and recreate the function
DROP TRIGGER IF EXISTS trigger_notify_on_block_edit ON blocks;
DROP FUNCTION IF EXISTS notify_on_block_edit();

CREATE OR REPLACE FUNCTION notify_on_block_edit()
RETURNS TRIGGER 
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_share RECORD;
  v_item RECORD;
  v_editor_id UUID;
  v_notification_id UUID;
BEGIN
  -- For INSERT operations (from upsert), don't create notifications
  IF TG_OP = 'INSERT' THEN
    RAISE NOTICE 'Block inserted (not edited): block_id=%', NEW.id;
    RETURN NEW;
  END IF;

  -- For UPDATE operations, check if this is a real edit
  -- We consider it an edit if:
  -- 1. Content changed, OR
  -- 2. Checkbox state changed, OR  
  -- 3. updated_at is newer (indicating intentional update)
  IF TG_OP = 'UPDATE' THEN
    
    -- Check if this is a meaningful update
    IF OLD.content = NEW.content AND 
       OLD.is_checked = NEW.is_checked AND
       OLD.updated_at = NEW.updated_at THEN
      RAISE NOTICE 'Block update ignored (no changes): block_id=%', NEW.id;
      RETURN NEW;
    END IF;
    
    RAISE NOTICE 'Block edit detected: block_id=%, item_id=%, content_changed=%, checked_changed=%', 
      NEW.id, NEW.item_id, 
      (OLD.content <> NEW.content),
      (OLD.is_checked <> NEW.is_checked);
    
    -- Get the item details
    SELECT id, title, created_by INTO v_item
    FROM items 
    WHERE id = NEW.item_id;
    
    -- Skip if item not found
    IF v_item.id IS NULL THEN
      RAISE NOTICE 'Item not found for block: %', NEW.item_id;
      RETURN NEW;
    END IF;
    
    RAISE NOTICE 'Item found: id=%, title=%, created_by=%', v_item.id, v_item.title, v_item.created_by;
    
    -- Try to get the current authenticated user
    BEGIN
      v_editor_id := auth.uid();
      RAISE NOTICE 'Editor from auth.uid(): %', v_editor_id;
    EXCEPTION WHEN OTHERS THEN
      v_editor_id := NULL;
      RAISE NOTICE 'Could not get auth.uid(), using fallback';
    END;
    
    -- If we can't get auth.uid(), fallback to item owner
    IF v_editor_id IS NULL THEN
      v_editor_id := v_item.created_by;
      RAISE NOTICE 'Using item owner as editor: %', v_editor_id;
    END IF;
    
    -- Notify all users who have access (except the editor)
    FOR v_share IN 
      SELECT user_id FROM item_shares 
      WHERE item_id = v_item.id 
      AND user_id <> COALESCE(v_editor_id, '00000000-0000-0000-0000-000000000000'::UUID)
    LOOP
      BEGIN
        v_notification_id := gen_random_uuid();
        
        -- Insert directly without RLS check
        INSERT INTO notifications (id, user_id, type, title, message, item_id, related_user_id, is_read, created_at, updated_at)
        VALUES (
          v_notification_id,
          v_share.user_id,
          'edit',
          'Item updated',
          'Someone updated "' || v_item.title || '"',
          v_item.id,
          v_editor_id,
          false,
          NOW(),
          NOW()
        );
        
        RAISE NOTICE 'Created edit notification: id=%, user_id=%, item_id=%', v_notification_id, v_share.user_id, v_item.id;
      EXCEPTION WHEN OTHERS THEN
        RAISE WARNING 'Failed to create edit notification for user %: %', v_share.user_id, SQLERRM;
      END;
    END LOOP;
    
    -- Also notify the owner if they're not the editor
    IF v_item.created_by IS NOT NULL AND 
       v_item.created_by <> COALESCE(v_editor_id, '00000000-0000-0000-0000-000000000000'::UUID) THEN
      BEGIN
        v_notification_id := gen_random_uuid();
        
        INSERT INTO notifications (id, user_id, type, title, message, item_id, related_user_id, is_read, created_at, updated_at)
        VALUES (
          v_notification_id,
          v_item.created_by,
          'edit',
          'Item updated',
          'Someone updated "' || v_item.title || '"',
          v_item.id,
          v_editor_id,
          false,
          NOW(),
          NOW()
        );
        
        RAISE NOTICE 'Created owner edit notification: id=%, user_id=%, item_id=%', v_notification_id, v_item.created_by, v_item.id;
      EXCEPTION WHEN OTHERS THEN
        RAISE WARNING 'Failed to create owner edit notification: %', SQLERRM;
      END;
    END IF;
    
    -- Also update the item's updated_at timestamp
    BEGIN
      UPDATE items 
      SET updated_at = NOW() 
      WHERE id = v_item.id;
      RAISE NOTICE 'Updated item timestamp for: %', v_item.id;
    EXCEPTION WHEN OTHERS THEN
      RAISE WARNING 'Failed to update item timestamp: %', SQLERRM;
    END;
    
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Grant execute permission
GRANT EXECUTE ON FUNCTION notify_on_block_edit() TO authenticated;
GRANT EXECUTE ON FUNCTION notify_on_block_edit() TO service_role;

-- Create trigger on UPDATE only
CREATE TRIGGER trigger_notify_on_block_edit
AFTER UPDATE ON blocks
FOR EACH ROW
EXECUTE FUNCTION notify_on_block_edit();

-- Verify trigger
SELECT 
  tgname as trigger_name,
  CASE tgenabled
    WHEN 'O' THEN 'enabled'
    WHEN 'D' THEN 'disabled'
    ELSE 'unknown'
  END as status,
  tgrelid::regclass as table_name
FROM pg_trigger
WHERE tgname = 'trigger_notify_on_block_edit';

SELECT '✅ Trigger fixed to properly detect upsert updates!' as result;
