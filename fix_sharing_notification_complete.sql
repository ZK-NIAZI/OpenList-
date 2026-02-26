-- ============================================
-- COMPLETE FIX FOR SHARING NOTIFICATION ERROR
-- ============================================
-- This fixes the PostgrestException: function create_notification(uuid, unknown, unknown, text, uuid, uuid) does not exist
-- Root cause: The function expects p_item_id as TEXT but triggers pass UUID

-- Step 1: Drop the existing trigger
DROP TRIGGER IF EXISTS trigger_notify_on_share ON item_shares;

-- Step 2: Drop the old function with wrong signature
DROP FUNCTION IF EXISTS create_notification(UUID, TEXT, TEXT, TEXT, TEXT, UUID);
DROP FUNCTION IF EXISTS create_notification(UUID, TEXT, TEXT, TEXT, UUID, UUID);

-- Step 3: Create the correct function with UUID parameter for item_id
CREATE OR REPLACE FUNCTION create_notification(
    p_user_id UUID,
    p_type TEXT,
    p_title TEXT,
    p_message TEXT,
    p_item_id UUID DEFAULT NULL,
    p_related_user_id UUID DEFAULT NULL
)
RETURNS UUID AS $$
DECLARE
    v_notification_id UUID;
BEGIN
    INSERT INTO notifications (user_id, type, title, message, item_id, related_user_id)
    VALUES (p_user_id, p_type, p_title, p_message, p_item_id::TEXT, p_related_user_id)
    RETURNING id INTO v_notification_id;
    
    RETURN v_notification_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Step 4: Recreate the trigger function with correct parameter types
CREATE OR REPLACE FUNCTION notify_on_share()
RETURNS TRIGGER AS $$
DECLARE
    v_item_title TEXT;
    v_sharer_email TEXT;
BEGIN
    -- Get item title
    SELECT title INTO v_item_title FROM items WHERE id = NEW.item_id;
    
    -- Get sharer email
    SELECT email INTO v_sharer_email FROM auth.users WHERE id = NEW.shared_by;
    
    -- Create notification for the user being shared with
    -- Now passing UUID directly (function signature accepts UUID)
    PERFORM create_notification(
        NEW.user_id,
        'share',
        'New shared item',
        v_sharer_email || ' shared "' || v_item_title || '" with you',
        NEW.item_id,  -- Pass as UUID (function will cast to TEXT internally)
        NEW.shared_by -- Pass as UUID
    );
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Step 5: Recreate the trigger
CREATE TRIGGER trigger_notify_on_share
AFTER INSERT ON item_shares
FOR EACH ROW
EXECUTE FUNCTION notify_on_share();

-- Step 6: Verify the fix
SELECT '✅ Sharing notification fix applied successfully!' as status;

-- Show the function signature to confirm
SELECT 
    routine_name,
    string_agg(
        parameter_name || ' ' || 
        CASE 
            WHEN data_type = 'USER-DEFINED' THEN udt_name
            ELSE data_type
        END, 
        ', ' ORDER BY ordinal_position
    ) as parameters
FROM information_schema.parameters
WHERE specific_schema = 'public' 
AND routine_name = 'create_notification'
GROUP BY routine_name;
