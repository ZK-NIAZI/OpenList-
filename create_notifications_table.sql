    -- =====================================================
    -- NOTIFICATIONS TABLE
    -- =====================================================

    CREATE TABLE IF NOT EXISTS notifications (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    type TEXT NOT NULL CHECK (type IN ('share', 'update', 'reminder', 'deadline', 'comment')),
    title TEXT NOT NULL,
    message TEXT NOT NULL,
    item_id TEXT, -- Reference to the related item (UUID string)
    related_user_id UUID REFERENCES auth.users(id), -- User who triggered the notification
    is_read BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
    );

    -- Create index for faster queries
    CREATE INDEX IF NOT EXISTS idx_notifications_user_id ON notifications(user_id);
    CREATE INDEX IF NOT EXISTS idx_notifications_created_at ON notifications(created_at DESC);
    CREATE INDEX IF NOT EXISTS idx_notifications_is_read ON notifications(is_read);

    -- =====================================================
    -- RLS POLICIES FOR NOTIFICATIONS
    -- =====================================================

    -- Enable RLS
    ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;

    -- Users can only see their own notifications
    CREATE POLICY "notifications_select_own"
    ON notifications FOR SELECT
    USING (user_id = auth.uid());

    -- Users can mark their own notifications as read
    CREATE POLICY "notifications_update_own"
    ON notifications FOR UPDATE
    USING (user_id = auth.uid())
    WITH CHECK (user_id = auth.uid());

    -- System can insert notifications for any user (via service role)
    CREATE POLICY "notifications_insert_system"
    ON notifications FOR INSERT
    WITH CHECK (true);

    -- Users can delete their own notifications
    CREATE POLICY "notifications_delete_own"
    ON notifications FOR DELETE
    USING (user_id = auth.uid());

    -- =====================================================
    -- FUNCTION TO CREATE NOTIFICATION
    -- =====================================================

    CREATE OR REPLACE FUNCTION create_notification(
    p_user_id UUID,
    p_type TEXT,
    p_title TEXT,
    p_message TEXT,
    p_item_id TEXT DEFAULT NULL,
    p_related_user_id UUID DEFAULT NULL
    )
    RETURNS UUID AS $$
    DECLARE
    v_notification_id UUID;
    BEGIN
    INSERT INTO notifications (user_id, type, title, message, item_id, related_user_id)
    VALUES (p_user_id, p_type, p_title, p_message, p_item_id, p_related_user_id)
    RETURNING id INTO v_notification_id;
    
    RETURN v_notification_id;
    END;
    $$ LANGUAGE plpgsql SECURITY DEFINER;

    -- =====================================================
    -- TRIGGER: Notify on item share
    -- =====================================================

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
    PERFORM create_notification(
        NEW.user_id,
        'share',
        'New shared item',
        v_sharer_email || ' shared "' || v_item_title || '" with you',
        NEW.item_id,
        NEW.shared_by
    );
    
    RETURN NEW;
    END;
    $$ LANGUAGE plpgsql SECURITY DEFINER;

    CREATE TRIGGER trigger_notify_on_share
    AFTER INSERT ON item_shares
    FOR EACH ROW
    EXECUTE FUNCTION notify_on_share();

    -- =====================================================
    -- TRIGGER: Notify on item update (for shared items)
    -- =====================================================

    CREATE OR REPLACE FUNCTION notify_on_item_update()
    RETURNS TRIGGER AS $$
    DECLARE
    v_share RECORD;
    v_updater_email TEXT;
    BEGIN
    -- Only notify if item was actually updated (not just created)
    IF TG_OP = 'UPDATE' AND OLD.updated_at <> NEW.updated_at THEN
        -- Get updater email
        SELECT email INTO v_updater_email FROM auth.users WHERE id = auth.uid();
        
        -- Notify all users who have access to this item (except the updater)
        FOR v_share IN 
        SELECT user_id FROM item_shares 
        WHERE item_id = NEW.id AND user_id <> auth.uid()
        LOOP
        PERFORM create_notification(
            v_share.user_id,
            'update',
            'Item updated',
            v_updater_email || ' updated "' || NEW.title || '"',
            NEW.id,
            auth.uid()
        );
        END LOOP;
        
        -- Also notify the owner if they didn't make the update
        IF NEW.created_by <> auth.uid() THEN
        PERFORM create_notification(
            NEW.created_by,
            'update',
            'Item updated',
            v_updater_email || ' updated "' || NEW.title || '"',
            NEW.id,
            auth.uid()
        );
        END IF;
    END IF;
    
    RETURN NEW;
    END;
    $$ LANGUAGE plpgsql SECURITY DEFINER;

    CREATE TRIGGER trigger_notify_on_item_update
    AFTER UPDATE ON items
    FOR EACH ROW
    EXECUTE FUNCTION notify_on_item_update();

    -- =====================================================
    -- VERIFICATION
    -- =====================================================

    -- Check if table was created
    SELECT 'Notifications table created successfully' AS status
    WHERE EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'notifications');

    -- Show all policies
    SELECT 
    schemaname,
    tablename,
    policyname,
    cmd
    FROM pg_policies 
    WHERE schemaname = 'public'
    AND tablename = 'notifications'
    ORDER BY policyname;
