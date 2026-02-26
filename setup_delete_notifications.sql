-- ============================================
-- SETUP DELETE NOTIFICATIONS
-- Run this in Supabase SQL Editor
-- ============================================

-- ============================================
-- STEP 1: Create/Update Delete Notification Function
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
    
    RAISE NOTICE 'Display name from profiles: %', v_deleter_name;
    
    IF v_deleter_name IS NULL OR v_deleter_name = '' THEN
      -- Fallback to email from auth.users
      SELECT email INTO v_deleter_name FROM auth.users WHERE id = v_current_user;
      
      RAISE NOTICE 'Email from auth.users: %', v_deleter_name;
      
      -- Extract username from email if we got it
      IF v_deleter_name IS NOT NULL AND v_deleter_name LIKE '%@%' THEN
        v_deleter_name := split_part(v_deleter_name, '@', 1);
        RAISE NOTICE 'Extracted username from email: %', v_deleter_name;
      END IF;
    END IF;
    
    -- Final fallback
    IF v_deleter_name IS NULL OR v_deleter_name = '' THEN
      v_deleter_name := 'Someone';
      RAISE NOTICE 'Using fallback name: Someone';
    END IF;
  EXCEPTION WHEN OTHERS THEN
    v_deleter_name := 'Someone';
    RAISE NOTICE 'Exception getting deleter name: %, using fallback', SQLERRM;
  END;
  
  RAISE NOTICE 'Final deleter name: %', v_deleter_name;
  
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

-- ============================================
-- STEP 2: Create/Replace Delete Trigger
-- ============================================

DROP TRIGGER IF EXISTS trigger_notify_on_item_delete ON items;

CREATE TRIGGER trigger_notify_on_item_delete
BEFORE DELETE ON items
FOR EACH ROW
EXECUTE FUNCTION notify_on_item_delete();

-- ============================================
-- STEP 3: Ensure Trigger is Enabled
-- ============================================

ALTER TABLE items ENABLE TRIGGER trigger_notify_on_item_delete;

-- ============================================
-- STEP 4: Add RLS Policies for Deletion
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
-- STEP 5: Verification
-- ============================================

-- Check trigger status
SELECT 
  '✅ Trigger Status' as check_type,
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
WHERE tgname = 'trigger_notify_on_item_delete'
AND tgisinternal = false;

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
✅ DELETE NOTIFICATIONS SETUP COMPLETE!

Next steps:
1. Delete a shared item from the app
2. Check Supabase logs for "DELETE TRIGGER FIRED" messages
3. Check notifications table for new delete notifications
4. Verify the other user receives the notification

To check notifications:
SELECT * FROM notifications WHERE type = ''unshare'' ORDER BY created_at DESC LIMIT 5;
' as instructions;
