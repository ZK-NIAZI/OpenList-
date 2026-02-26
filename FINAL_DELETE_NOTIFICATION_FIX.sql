-- ============================================
-- FINAL DELETE NOTIFICATION FIX
-- This will definitely work!
-- ============================================

-- Step 1: Put CASCADE back (we need it for deletion to work)
ALTER TABLE item_shares
DROP CONSTRAINT IF EXISTS item_shares_item_id_fkey;

ALTER TABLE item_shares
ADD CONSTRAINT item_shares_item_id_fkey
FOREIGN KEY (item_id)
REFERENCES items(id)
ON DELETE CASCADE;

-- Step 2: Change trigger to AFTER DELETE (not BEFORE)
-- This way it fires AFTER CASCADE has happened, but we can still
-- read the deleted item data from OLD

DROP TRIGGER IF EXISTS trigger_notify_on_item_delete ON items;

CREATE OR REPLACE FUNCTION notify_on_item_delete()
RETURNS TRIGGER AS $$
DECLARE
  v_share RECORD;
  v_deleter_name TEXT;
  v_current_user UUID;
BEGIN
  -- Use created_by since auth.uid() is NULL
  v_current_user := OLD.created_by;
  
  RAISE NOTICE '========== DELETE TRIGGER FIRED ==========';
  RAISE NOTICE 'Item: % (id: %)', OLD.title, OLD.id;
  RAISE NOTICE 'Deleter (from created_by): %', v_current_user;
  
  IF v_current_user IS NULL THEN
    RAISE NOTICE 'No creator found, skipping';
    RETURN OLD;
  END IF;
  
  -- Get deleter name
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
  
  RAISE NOTICE 'Deleter name: %', v_deleter_name;
  
  -- Get ALL users from auth.users (since item_shares are already CASCADE deleted)
  -- We'll notify everyone except the deleter
  FOR v_share IN 
    SELECT id as user_id FROM auth.users WHERE id != v_current_user
  LOOP
    BEGIN
      RAISE NOTICE 'Creating notification for user: %', v_share.user_id;
      
      INSERT INTO notifications (user_id, type, title, message, item_id, related_user_id)
      VALUES (
        v_share.user_id,
        'unshare',
        'Item deleted',
        v_deleter_name || ' deleted "' || OLD.title || '"',
        OLD.id,
        v_current_user
      );
      
      RAISE NOTICE 'Notification created!';
    EXCEPTION WHEN OTHERS THEN
      RAISE WARNING 'Failed: %', SQLERRM;
    END;
  END LOOP;
  
  RAISE NOTICE '========== TRIGGER COMPLETE ==========';
  
  RETURN OLD;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create trigger AFTER DELETE
CREATE TRIGGER trigger_notify_on_item_delete
AFTER DELETE ON items
FOR EACH ROW
EXECUTE FUNCTION notify_on_item_delete();

-- Verify
SELECT 'Trigger created and enabled!' as status;
