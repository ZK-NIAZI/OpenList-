-- ============================================
-- NOTIFICATIONS SETUP - CLEAN INSTALL
-- ============================================
-- Drops existing objects first, then creates fresh

-- Step 1: Drop existing triggers
DROP TRIGGER IF EXISTS trigger_notify_on_share ON item_shares;
DROP TRIGGER IF EXISTS trigger_notify_on_unshare ON item_shares;
DROP TRIGGER IF EXISTS trigger_notify_on_item_edit ON items;
DROP TRIGGER IF EXISTS trigger_notify_on_item_update ON items;

-- Step 2: Drop existing functions
DROP FUNCTION IF EXISTS notify_on_share();
DROP FUNCTION IF EXISTS notify_on_unshare();
DROP FUNCTION IF EXISTS notify_on_item_edit();
DROP FUNCTION IF EXISTS notify_on_item_update();

-- Step 3: Drop existing policies
DROP POLICY IF EXISTS "notifications_select_own" ON notifications;
DROP POLICY IF EXISTS "notifications_update_own" ON notifications;
DROP POLICY IF EXISTS "notifications_delete_own" ON notifications;
DROP POLICY IF EXISTS "notifications_insert_system" ON notifications;

-- Step 4: Create notifications table (if not exists)
CREATE TABLE IF NOT EXISTS notifications (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  type TEXT NOT NULL CHECK (type IN ('share', 'unshare', 'edit', 'comment')),
  title TEXT NOT NULL,
  message TEXT NOT NULL,
  item_id UUID, -- Reference to the item
  related_user_id UUID REFERENCES auth.users(id),
  is_read BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Step 5: Create indexes
CREATE INDEX IF NOT EXISTS idx_notifications_user_id ON notifications(user_id);
CREATE INDEX IF NOT EXISTS idx_notifications_is_read ON notifications(is_read);
CREATE INDEX IF NOT EXISTS idx_notifications_created_at ON notifications(created_at DESC);

-- Step 6: Enable RLS
ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;

-- Step 7: Create RLS Policies
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

CREATE TRIGGER trigger_notify_on_unshare
AFTER DELETE ON item_shares
FOR EACH ROW
EXECUTE FUNCTION notify_on_unshare();

-- ============================================
-- VERIFICATION
-- ============================================

SELECT '✅ Notifications setup complete!' as status;

-- Show notification count
SELECT 
  'Notifications table ready' as info,
  COUNT(*) as existing_notifications
FROM notifications;
