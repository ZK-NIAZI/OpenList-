-- ============================================
-- TASK UPDATE NOTIFICATIONS SETUP
-- ============================================
-- This script creates triggers to send notifications when:
-- 1. Task title is changed
-- 2. Task completion status is toggled
-- 3. Task due date is changed
-- 4. Block content is updated
-- ============================================

-- ============================================
-- FUNCTION: Notify on Item (Task) Updates
-- ============================================
CREATE OR REPLACE FUNCTION notify_item_update()
RETURNS TRIGGER AS $$
DECLARE
  share_record RECORD;
  editor_name TEXT;
  change_description TEXT;
BEGIN
  -- Get editor's name from profiles
  SELECT display_name INTO editor_name
  FROM profiles
  WHERE id = auth.uid();
  
  -- Fallback if no display name
  IF editor_name IS NULL OR editor_name = '' THEN
    editor_name := 'Someone';
  END IF;
  
  -- Determine what changed
  IF OLD.title IS DISTINCT FROM NEW.title THEN
    change_description := 'updated the title of';
  ELSIF OLD.is_completed IS DISTINCT FROM NEW.is_completed THEN
    IF NEW.is_completed THEN
      change_description := 'completed';
    ELSE
      change_description := 'reopened';
    END IF;
  ELSIF OLD.due_date IS DISTINCT FROM NEW.due_date THEN
    change_description := 'changed the due date of';
  ELSE
    change_description := 'updated';
  END IF;
  
  -- Send notification to all users who have access to this item (except the editor)
  FOR share_record IN 
    SELECT user_id 
    FROM item_shares 
    WHERE item_id = NEW.id 
    AND user_id != auth.uid()
  LOOP
    INSERT INTO notifications (
      user_id,
      type,
      title,
      message,
      item_id,
      related_user_id,
      is_read,
      created_at,
      updated_at
    ) VALUES (
      share_record.user_id,
      'update',
      'Task updated',
      editor_name || ' ' || change_description || ' "' || NEW.title || '"',
      NEW.id,
      auth.uid(),
      false,
      NOW(),
      NOW()
    );
  END LOOP;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================
-- TRIGGER: Item Update Notification
-- ============================================
-- Drop existing trigger if it exists
DROP TRIGGER IF EXISTS item_update_notification ON items;

-- Create trigger that fires on UPDATE
CREATE TRIGGER item_update_notification
AFTER UPDATE ON items
FOR EACH ROW
WHEN (
  -- Only trigger when these specific fields change
  OLD.title IS DISTINCT FROM NEW.title 
  OR OLD.is_completed IS DISTINCT FROM NEW.is_completed
  OR OLD.due_date IS DISTINCT FROM NEW.due_date
)
EXECUTE FUNCTION notify_item_update();

-- ============================================
-- FUNCTION: Notify on Block Content Updates
-- ============================================
CREATE OR REPLACE FUNCTION notify_block_update()
RETURNS TRIGGER AS $$
DECLARE
  share_record RECORD;
  editor_name TEXT;
  item_title TEXT;
BEGIN
  -- Get editor's name from profiles
  SELECT display_name INTO editor_name
  FROM profiles
  WHERE id = auth.uid();
  
  -- Fallback if no display name
  IF editor_name IS NULL OR editor_name = '' THEN
    editor_name := 'Someone';
  END IF;
  
  -- Get the item title
  SELECT title INTO item_title
  FROM items
  WHERE id = NEW.item_id;
  
  -- If item not found, skip notification
  IF item_title IS NULL THEN
    RETURN NEW;
  END IF;
  
  -- Send notification to all users who have access to this item (except the editor)
  FOR share_record IN 
    SELECT user_id 
    FROM item_shares 
    WHERE item_id = NEW.item_id 
    AND user_id != auth.uid()
  LOOP
    INSERT INTO notifications (
      user_id,
      type,
      title,
      message,
      item_id,
      related_user_id,
      is_read,
      created_at,
      updated_at
    ) VALUES (
      share_record.user_id,
      'update',
      'Content updated',
      editor_name || ' updated content in "' || item_title || '"',
      NEW.item_id,
      auth.uid(),
      false,
      NOW(),
      NOW()
    );
  END LOOP;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================
-- TRIGGER: Block Update Notification
-- ============================================
-- Drop existing trigger if it exists
DROP TRIGGER IF EXISTS block_update_notification ON blocks;

-- Create trigger that fires on UPDATE
CREATE TRIGGER block_update_notification
AFTER UPDATE ON blocks
FOR EACH ROW
WHEN (
  -- Only trigger when content changes
  OLD.content IS DISTINCT FROM NEW.content
)
EXECUTE FUNCTION notify_block_update();

-- ============================================
-- VERIFICATION
-- ============================================
-- Check if triggers are enabled
SELECT 
  trigger_name,
  event_manipulation,
  event_object_table,
  action_statement
FROM information_schema.triggers
WHERE trigger_name IN ('item_update_notification', 'block_update_notification')
ORDER BY event_object_table, trigger_name;

-- ============================================
-- TESTING INSTRUCTIONS
-- ============================================
-- 1. Share a task from Account A to Account B
-- 2. Edit the task title on Account A
-- 3. Check notifications table for Account B:
--    SELECT * FROM notifications WHERE user_id = '<account_b_user_id>' ORDER BY created_at DESC LIMIT 5;
-- 4. Edit block content on Account A
-- 5. Check notifications again for Account B
-- ============================================
