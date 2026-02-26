-- ============================================
-- FIX EDIT NOTIFICATIONS - TRIGGER ON BLOCKS
-- ============================================
-- The real issue: We're editing BLOCKS, not ITEMS
-- So we need to trigger notifications when blocks are updated

-- Drop existing triggers
DROP TRIGGER IF EXISTS trigger_notify_on_item_edit ON items;
DROP TRIGGER IF EXISTS trigger_notify_on_block_edit ON blocks;
DROP FUNCTION IF EXISTS notify_on_block_edit();

-- Create function to notify on block edits
CREATE OR REPLACE FUNCTION notify_on_block_edit()
RETURNS TRIGGER AS $$
DECLARE
  v_share RECORD;
  v_item RECORD;
  v_editor_id UUID;
BEGIN
  -- Only notify if block was actually updated (content changed)
  IF TG_OP = 'UPDATE' AND (
    OLD.content <> NEW.content OR 
    OLD.is_checked <> NEW.is_checked OR
    OLD.updated_at <> NEW.updated_at
  ) THEN
    
    -- Get the item details
    SELECT id, title, created_by INTO v_item
    FROM items 
    WHERE id = NEW.item_id;
    
    -- Skip if item not found
    IF v_item.id IS NULL THEN
      RETURN NEW;
    END IF;
    
    -- Try to get the current authenticated user
    BEGIN
      v_editor_id := auth.uid();
    EXCEPTION WHEN OTHERS THEN
      v_editor_id := NULL;
    END;
    
    -- If we can't get auth.uid(), fallback to item owner
    IF v_editor_id IS NULL THEN
      v_editor_id := v_item.created_by;
    END IF;
    
    -- Notify all users who have access (except the editor)
    FOR v_share IN 
      SELECT user_id FROM item_shares 
      WHERE item_id = v_item.id 
      AND user_id <> COALESCE(v_editor_id, '00000000-0000-0000-0000-000000000000'::UUID)
    LOOP
      BEGIN
        INSERT INTO notifications (user_id, type, title, message, item_id, related_user_id)
        VALUES (
          v_share.user_id,
          'edit',
          'Item updated',
          'Someone updated "' || v_item.title || '"',
          v_item.id,
          v_editor_id
        );
        
        RAISE NOTICE 'Created edit notification for user % on item %', v_share.user_id, v_item.id;
      EXCEPTION WHEN OTHERS THEN
        RAISE WARNING 'Failed to create edit notification for user %: %', v_share.user_id, SQLERRM;
      END;
    END LOOP;
    
    -- Also notify the owner if they're not the editor
    IF v_item.created_by IS NOT NULL AND 
       v_item.created_by <> COALESCE(v_editor_id, '00000000-0000-0000-0000-000000000000'::UUID) THEN
      BEGIN
        INSERT INTO notifications (user_id, type, title, message, item_id, related_user_id)
        VALUES (
          v_item.created_by,
          'edit',
          'Item updated',
          'Someone updated "' || v_item.title || '"',
          v_item.id,
          v_editor_id
        );
        
        RAISE NOTICE 'Created edit notification for owner % on item %', v_item.created_by, v_item.id;
      EXCEPTION WHEN OTHERS THEN
        RAISE WARNING 'Failed to create owner edit notification: %', SQLERRM;
      END;
    END IF;
    
    -- Also update the item's updated_at timestamp
    BEGIN
      UPDATE items 
      SET updated_at = NOW() 
      WHERE id = v_item.id;
    EXCEPTION WHEN OTHERS THEN
      RAISE WARNING 'Failed to update item timestamp: %', SQLERRM;
    END;
    
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create trigger on blocks table
CREATE TRIGGER trigger_notify_on_block_edit
AFTER UPDATE ON blocks
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
  tgrelid::regclass as table_name
FROM pg_trigger
WHERE tgname = 'trigger_notify_on_block_edit';

SELECT '✅ Block edit notifications enabled!' as result;
