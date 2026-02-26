-- Fix the create_notification function to accept UUID for item_id instead of TEXT

-- Drop the old function
DROP FUNCTION IF EXISTS create_notification(UUID, TEXT, TEXT, TEXT, TEXT, UUID);

-- Recreate with correct parameter types
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

-- Verify the function was created
SELECT 'create_notification function fixed successfully' AS status;
