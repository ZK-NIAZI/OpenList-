    -- ============================================
    -- FIX DELETE TRIGGER - AUTH.UID() NULL ISSUE
    -- ============================================
    -- Problem: auth.uid() returns NULL when Flutter app deletes items
    -- Solution: Use created_by as fallback to identify the deleter
    -- ============================================

    CREATE OR REPLACE FUNCTION notify_on_item_delete()
    RETURNS TRIGGER AS $$
    DECLARE
    v_share RECORD;
    v_deleter_name TEXT;
    v_current_user UUID;
    v_auth_uid UUID;
    BEGIN
    -- Get auth.uid() for debugging
    v_auth_uid := auth.uid();
    
    -- Use auth.uid() if available, otherwise use created_by as fallback
    v_current_user := COALESCE(auth.uid(), OLD.created_by);
    
    RAISE NOTICE '========================================';
    RAISE NOTICE 'DELETE TRIGGER FIRED';
    RAISE NOTICE '========================================';
    RAISE NOTICE 'Item: % (id: %)', OLD.title, OLD.id;
    RAISE NOTICE 'auth.uid(): %', v_auth_uid;
    RAISE NOTICE 'created_by: %', OLD.created_by;
    RAISE NOTICE 'Using user: %', v_current_user;
    
    -- Skip if still no user (shouldn't happen but safety check)
    IF v_current_user IS NULL THEN
        RAISE NOTICE 'ERROR: No current user and no creator found';
        RAISE NOTICE 'This should never happen - item must have created_by';
        RETURN OLD;
    END IF;
    
    -- Get deleter name from profiles table (display_name only)
    BEGIN
        SELECT display_name INTO v_deleter_name 
        FROM profiles 
        WHERE id = v_current_user;
        
        RAISE NOTICE 'Found display_name in profiles: %', v_deleter_name;
        
        IF v_deleter_name IS NULL OR v_deleter_name = '' THEN
        -- Fallback to email from auth.users
        SELECT email INTO v_deleter_name FROM auth.users WHERE id = v_current_user;
        
        RAISE NOTICE 'Fallback to email: %', v_deleter_name;
        
        -- Extract username from email if we got it
        IF v_deleter_name IS NOT NULL AND v_deleter_name LIKE '%@%' THEN
            v_deleter_name := split_part(v_deleter_name, '@', 1);
            RAISE NOTICE 'Extracted username from email: %', v_deleter_name;
        END IF;
        END IF;
        
        -- Final fallback
        IF v_deleter_name IS NULL OR v_deleter_name = '' THEN
        v_deleter_name := 'Someone';
        RAISE NOTICE 'Using final fallback: Someone';
        END IF;
    EXCEPTION WHEN OTHERS THEN
        v_deleter_name := 'Someone';
        RAISE NOTICE 'Exception getting name, using: Someone';
    END;
    
    RAISE NOTICE 'Deleter name: %', v_deleter_name;
    RAISE NOTICE '----------------------------------------';
    
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
            'unshare',
            'Item deleted',
            v_deleter_name || ' deleted "' || OLD.title || '"',
            OLD.id,
            v_current_user
        );
        
        RAISE NOTICE 'Delete notification created successfully';
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
            'unshare',
            'Item deleted',
            v_deleter_name || ' deleted "' || OLD.title || '"',
            OLD.id,
            v_current_user
        );
        
        RAISE NOTICE 'Delete notification created for owner';
        EXCEPTION WHEN OTHERS THEN
        RAISE WARNING 'Failed to create owner delete notification: %', SQLERRM;
        END;
    END IF;
    
    RAISE NOTICE '========================================';
    RAISE NOTICE 'DELETE TRIGGER COMPLETED';
    RAISE NOTICE '========================================';
    
    RETURN OLD;
    END;
    $$ LANGUAGE plpgsql SECURITY DEFINER;

    -- Drop and recreate the trigger
    DROP TRIGGER IF EXISTS trigger_notify_on_item_delete ON items;
    CREATE TRIGGER trigger_notify_on_item_delete
    BEFORE DELETE ON items
    FOR EACH ROW
    EXECUTE FUNCTION notify_on_item_delete();

    -- Enable the trigger
    ALTER TABLE items ENABLE TRIGGER trigger_notify_on_item_delete;

    -- Verify it's enabled
    SELECT 
    'TRIGGER STATUS' as check_type,
    tgname as trigger_name,
    CASE tgenabled
        WHEN 'O' THEN 'ENABLED'
        WHEN 'D' THEN 'DISABLED'
        ELSE 'OTHER'
    END as status
    FROM pg_trigger
    WHERE tgname = 'trigger_notify_on_item_delete'
    AND tgisinternal = false;
