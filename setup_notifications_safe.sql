-- ============================================
-- NOTIFICATIONS SETUP - SAFE IMPLEMENTATION
-- ============================================
-- This script adds notifications WITHOUT breaking existing functionality

-- Step 1: Create notifications table
CREATE TABLE IF NOT EXISTS notifications (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  type TEXT NOT NULL CHECK (type IN ('share', 'unshare', 'edit', 'comment')),
  title TEXT NOT NULL,
  message TEXT NOT NULL,
  item_id UUID, -- Reference to the item (stored as UUID, not FK to avoid cascade issues)
  related_user_id UUID REFERENCES auth.users(id), -- Who triggered the notification
  is_read BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create indexes for performance
CREATE INDEX IF NOT EXISTS idx_notifications_user_id ON notifications(user_id);
CREATE INDEX IF NOT EXISTS idx_notifications_is_read ON notifications(is_read);
CREATE INDEX IF NOT EXISTS idx_notifications_created_at ON notifications(created_at DESC);

-- Enable RLS
ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;

-- RLS Policies: Users can only see their own notifications
CREATE POLICY "notifications_select_own"
ON notifications FOR SELECT
USING (user_id = auth.uid());

CREATE POLICY "notifications_update_own"
ON notifications FOR UPDATE
USING (user_id = auth.uid())
WITH CHECK (user_id = auth.uid());

CREATE POLICY "notifications_delete_own"
ON notifications FOR DELETE
USING (user_id = auth.uid());

-- System can insert notifications (via triggers)
CREATE POLICY "notifications_insert_system"
ON notifications FOR INSERT
WITH CHECK (true);

-- ============================================
-- TRIGGER 1: Notify on Share
-- ============================================

CREATE OR REPLACE FUNCTION notify_on_share()
RETURNS TRIGGER AS $$
DECLARE
  v_item_title TEXT;
  v_sharer_email TEXT;
BEGIN
  -- Get item title (with error handling)
  BEGIN
    SELECT title INTO v_item_title FROM items WHERE id = NEW.item_id;
    IF v_item_title IS NULL THEN
      v_item_title := 'Untitled';
    END IF;
  EXCEPTION WHEN OTHERS THEN
    v_item_title := 'Untitled';
  END;
  
  -- Get sharer email (with error handling)
  BEGIN
    SELECT email INTO v_sharer_email FROM auth.users WHERE id = NEW.shared_by;
    IF v_sharer_email IS NULL THEN
      v_sharer_email := 'Someone';
    END IF;
  EXCEPTION WHEN OTHERS THEN
    v_sharer_email := 'Someone';
  END;
  
  -- Create notification (wrapped in exception handler to not break sharing)
  BEGIN
    INSERT INTO notifications (user_id, type, title, message, item_id, related_user_id)
    VALUES (
      NEW.user_id,
      'share',
      'New shared item',
      v_sharer_email || ' shared "' || v_item_title || '" with you',
      NEW.item_id,
      NEW.shared_by
    );
  EXCEPTION WHEN OTHERS THEN
    -- Log error but don't fail the share operation
    RAISE WARNING 'Failed to create share notification: %', SQLERRM;
  END;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create trigger (drop first if exists)
DROP TRIGGER IF EXISTS trigger_notify_on_share ON item_shares;
CREATE TRIGGER trigger_notify_on_share
AFTER INSERT ON item_shares
FOR EACH ROW
EXECUTE FUNCTION notify_on_share();

-- ============================================
-- TRIGGER 2: Notify on Unshare
-- ============================================

CREATE OR REPLACE FUNCTION notify_on_unshare()
RETURNS TRIGGER AS $$
DECLARE
  v_item_title TEXT;
BEGIN
  -- Get item title (with error handling)
  BEGIN
    SELECT title INTO v_item_title FROM items WHERE id = OLD.item_id;
    IF v_item_title IS NULL THEN
      v_item_title := 'Untitled';
    END IF;
  EXCEPTION WHEN OTHERS THEN
    v_item_title := 'Untitled';
  END;
  
  -- Create notification (wrapped in exception handler)
  BEGIN
    INSERT INTO notifications (user_id, type, title, message, item_id)
    VALUES (
      OLD.user_id,
      'unshare',
      'Access removed',
      'Your access to "' || v_item_title || '" was removed',
      OLD.item_id
    );
  EXCEPTION WHEN OTHERS THEN
    RAISE WARNING 'Failed to create unshare notification: %', SQLERRM;
  END;
  
  RETURN OLD;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create trigger
DROP TRIGGER IF EXISTS trigger_notify_on_unshare ON item_shares;
CREATE TRIGGER trigger_notify_on_unshare
AFTER DELETE ON item_shares
FOR EACH ROW
EXECUTE FUNCTION notify_on_unshare();

-- ============================================
-- TRIGGER 3: Notify on Edit (OPTIONAL - can enable later)
-- ============================================
-- Commented out for now to avoid notification spam
-- Uncomment when ready to enable edit notifications

/*
CREATE OR REPLACE FUNCTION notify_on_item_edit()
RETURNS TRIGGER AS $$
DECLARE
  v_share RECORD;
  v_editor_email TEXT;
  v_current_user UUID;
BEGIN
  -- Only notify if item was actually updated (not just created)
  IF TG_OP = 'UPDATE' AND OLD.updated_at <> NEW.updated_at THEN
    -- Get current user
    v_current_user := auth.uid();
    
    -- Get editor email
    BEGIN
      SELECT email INTO v_editor_email FROM auth.users WHERE id = v_current_user;
      IF v_editor_email IS NULL THEN
        v_editor_email := 'Someone';
      END IF;
    EXCEPTION WHEN OTHERS THEN
      v_editor_email := 'Someone';
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
          'edit',
          'Item updated',
          v_editor_email || ' updated "' || NEW.title || '"',
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
          'edit',
          'Item updated',
          v_editor_email || ' updated "' || NEW.title || '"',
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
*/

-- ============================================
-- VERIFICATION
-- ============================================

SELECT '✅ Notifications setup complete!' as status;

-- Show created objects
SELECT 'Tables created:' as info;
SELECT table_name FROM information_schema.tables 
WHERE table_schema = 'public' AND table_name = 'notifications';

SELECT 'Triggers created:' as info;
SELECT trigger_name, event_object_table 
FROM information_schema.triggers 
WHERE trigger_schema = 'public' 
AND trigger_name LIKE '%notify%';

SELECT 'Functions created:' as info;
SELECT routine_name 
FROM information_schema.routines 
WHERE routine_schema = 'public' 
AND routine_name LIKE '%notify%';
