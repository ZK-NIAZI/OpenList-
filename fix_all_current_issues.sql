-- ============================================
-- FIX ALL CURRENT ISSUES
-- Run this in Supabase SQL Editor to fix:
-- 1. Edit notifications (change 'edit' to 'update' type)
-- 2. Delete notifications (enable and use 'unshare' type)
-- 3. RLS policies for deletion
-- ============================================

-- ============================================
-- PART 1: Fix Edit Notifications (use 'update' type)
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
-- PART 2: Setup Delete Notifications (use 'unshare' type)
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
  
  RAISE NOTICE 'DELETE TRIGGER FIRED for item: % (id: %)', OLD.title, OLD.id;
  RAISE NOTICE 'Current user: %', v_current_user;
  
  -- Skip if no current user
  IF v_current_user IS NULL THEN
    RAISE NOTICE 'No current user, skipping notifications';
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
  
  RAISE NOTICE 'Deleter name: %', v_deleter_name;
  
  -- Notify all users who had access (except the deleter)
  FOR v_share IN 
    SELECT user_id FROM item_shares 
    WHERE item_id = OLD.id AND user_id <> v_current_user
  LOOP
    BEGIN
      RAISE NOTICE 'Creating delete notification for user: %', v_share.user_id;
      
      INSERT INTO notifications (user_id, type, title, message, item_id, related_user_id)
      VALUES (
        v_share.user_id,
        'unshare',  -- Using 'unshare' for delete notifications
        'Item deleted',
        v_deleter_name || ' deleted "' || OLD.title || '"',
        OLD.id,
        v_current_user
      );
      
      RAISE NOTICE '✅ Delete notification created for user: %', v_share.user_id;
    EXCEPTION WHEN OTHERS THEN
      RAISE WARNING 'Failed to create delete notification for user %: %', v_share.user_id, SQLERRM;
    END;
  END LOOP;
  
  -- Also notify the owner if they didn't delete it
  IF OLD.created_by <> v_current_user AND OLD.created_by IS NOT NULL THEN
    BEGIN
      RAISE NOTICE 'Creating delete notification for owner: %', OLD.created_by;
      
      INSERT INTO notifications (user_id, type, title, message, item_id, related_user_id)
      VALUES (
        OLD.created_by,
        'unshare',  -- Using 'unshare' for delete notifications
        'Item deleted',
        v_deleter_name || ' deleted "' || OLD.title || '"',
        OLD.id,
        v_current_user
      );
      
      RAISE NOTICE '✅ Delete notification created for owner: %', OLD.created_by;
    EXCEPTION WHEN OTHERS THEN
      RAISE WARNING 'Failed to create owner delete notification: %', SQLERRM;
    END;
  END IF;
  
  RAISE NOTICE 'DELETE TRIGGER COMPLETED';
  
  RETURN OLD;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS trigger_notify_on_item_delete ON items;
CREATE TRIGGER trigger_notify_on_item_delete
BEFORE DELETE ON items
FOR EACH ROW
EXECUTE FUNCTION notify_on_item_delete();

-- ============================================
-- PART 3: Enable All Triggers
-- ============================================

ALTER TABLE items ENABLE TRIGGER trigger_notify_on_item_edit;
ALTER TABLE items ENABLE TRIGGER trigger_notify_on_item_delete;

-- ============================================
-- PART 4: Add RLS Policies for Deletion
-- ============================================

-- Allow users to delete their own items
DROP POLICY IF EXISTS "Users can delete their own items" ON items;
CREATE POLICY "Users can delete their own items"
ON items FOR DELETE
USING (auth.uid() = created_by);

-- Allow users to delete items shared with them if they have edit permission
DROP POLICY IF EXISTS "Users can delete shared items with edit permission" ON items;
CREATE POLICY "Users can delete shared items with edit permission"
ON items FOR DELETE
USING (
  EXISTS (
    SELECT 1 FROM item_shares
    WHERE item_shares.item_id = items.id
    AND item_shares.user_id = auth.uid()
    AND item_shares.permission = 'edit'
  )
);

-- ============================================
-- VERIFICATION
-- ============================================

-- Check all notification triggers
SELECT 
  '✅ Notification Triggers' as check_type,
  tgname as trigger_name,
  CASE tgenabled
    WHEN 'O' THEN '✅ ENABLED'
    WHEN 'D' THEN '❌ DISABLED'
    ELSE '⚠️ OTHER'
  END as status,
  tgrelid::regclass as table_name,
  CASE 
    WHEN tgtype & 2 = 2 THEN 'BEFORE'
    WHEN tgtype & 4 = 4 THEN 'AFTER'
    ELSE 'INSTEAD OF'
  END as timing
FROM pg_trigger
WHERE tgname LIKE '%notify%'
AND tgisinternal = false
ORDER BY tgrelid::regclass, tgname;

-- Check RLS policies
SELECT 
  '✅ RLS Policies' as check_type,
  schemaname,
  tablename,
  policyname,
  cmd as command
FROM pg_policies
WHERE tablename = 'items'
AND policyname LIKE '%delete%'
ORDER BY policyname;

SELECT '
✅ ALL FIXES APPLIED!

What was fixed:
1. Edit notifications now use "update" type (not "edit")
2. Delete notifications now use "unshare" type
3. Both triggers get user display_name from profiles table
4. RLS policies allow deletion of owned and shared items
5. Debug logging added to track trigger execution

Next steps:
1. Test editing a shared item - should show "[Name] updated [Title]"
2. Test deleting a shared item - should show "[Name] deleted [Title]"
3. Check Supabase logs for "DELETE TRIGGER FIRED" messages
4. Verify notifications appear in the app

To check notifications:
SELECT type, title, message, created_at 
FROM notifications 
ORDER BY created_at DESC 
LIMIT 10;
' as instructions;
