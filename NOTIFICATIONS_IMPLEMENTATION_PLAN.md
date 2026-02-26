# Notifications Implementation Plan

## Architecture: Database-Based Notifications

Use Supabase triggers to create notification records that sync via existing infrastructure.

## Notification Types

1. **share** - Someone shared an item with you
2. **unshare** - Owner removed your access to an item
3. **edit** - Someone edited a shared item
4. **comment** - Someone commented on a shared item (future)

## Database Schema

```sql
CREATE TABLE notifications (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  type TEXT NOT NULL CHECK (type IN ('share', 'unshare', 'edit', 'comment')),
  title TEXT NOT NULL,
  message TEXT NOT NULL,
  item_id UUID, -- Reference to the item
  related_user_id UUID REFERENCES auth.users(id), -- Who triggered it
  is_read BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_notifications_user_id ON notifications(user_id);
CREATE INDEX idx_notifications_is_read ON notifications(is_read);
```

## Triggers

### 1. On Share (item_shares INSERT)
```sql
CREATE OR REPLACE FUNCTION notify_on_share()
RETURNS TRIGGER AS $$
DECLARE
  v_item_title TEXT;
  v_sharer_email TEXT;
BEGIN
  SELECT title INTO v_item_title FROM items WHERE id = NEW.item_id;
  SELECT email INTO v_sharer_email FROM auth.users WHERE id = NEW.shared_by;
  
  INSERT INTO notifications (user_id, type, title, message, item_id, related_user_id)
  VALUES (
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
```

### 2. On Unshare (item_shares DELETE)
```sql
CREATE OR REPLACE FUNCTION notify_on_unshare()
RETURNS TRIGGER AS $$
DECLARE
  v_item_title TEXT;
BEGIN
  SELECT title INTO v_item_title FROM items WHERE id = OLD.item_id;
  
  INSERT INTO notifications (user_id, type, title, message, item_id)
  VALUES (
    OLD.user_id,
    'unshare',
    'Access removed',
    'Your access to "' || v_item_title || '" was removed',
    OLD.item_id
  );
  
  RETURN OLD;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER trigger_notify_on_unshare
AFTER DELETE ON item_shares
FOR EACH ROW
EXECUTE FUNCTION notify_on_unshare();
```

### 3. On Edit (items UPDATE)
```sql
CREATE OR REPLACE FUNCTION notify_on_item_edit()
RETURNS TRIGGER AS $$
DECLARE
  v_share RECORD;
  v_editor_email TEXT;
BEGIN
  -- Only notify if item was actually updated
  IF OLD.updated_at <> NEW.updated_at THEN
    SELECT email INTO v_editor_email FROM auth.users WHERE id = auth.uid();
    
    -- Notify all users who have access (except the editor)
    FOR v_share IN 
      SELECT user_id FROM item_shares 
      WHERE item_id = NEW.id AND user_id <> auth.uid()
    LOOP
      INSERT INTO notifications (user_id, type, title, message, item_id, related_user_id)
      VALUES (
        v_share.user_id,
        'edit',
        'Item updated',
        v_editor_email || ' updated "' || NEW.title || '"',
        NEW.id,
        auth.uid()
      );
    END LOOP;
    
    -- Also notify the owner if they didn't make the edit
    IF NEW.created_by <> auth.uid() THEN
      INSERT INTO notifications (user_id, type, title, message, item_id, related_user_id)
      VALUES (
        NEW.created_by,
        'edit',
        'Item updated',
        v_editor_email || ' updated "' || NEW.title || '"',
        NEW.id,
        auth.uid()
      );
    END IF;
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER trigger_notify_on_item_edit
AFTER UPDATE ON items
FOR EACH ROW
EXECUTE FUNCTION notify_on_item_edit();
```

## Flutter Implementation

### 1. Notification Model
```dart
@collection
class NotificationModel {
  Id id = Isar.autoIncrement;
  
  @Index()
  late String notificationId; // UUID from Supabase
  
  @Index()
  late String userId;
  
  @enumerated
  late NotificationType type;
  
  late String title;
  late String message;
  
  String? itemId;
  String? relatedUserId;
  
  @Index()
  late bool isRead;
  
  late DateTime createdAt;
  
  @enumerated
  late SyncStatus syncStatus;
}

enum NotificationType {
  share,
  unshare,
  edit,
  comment,
}
```

### 2. Sync Notifications (add to SyncManager)
```dart
// Pull notifications from Supabase
Future<void> _pullNotificationsFromSupabase() async {
  final supabase = Supabase.instance.client;
  final userId = supabase.auth.currentUser?.id;
  
  final notifications = await supabase
      .from('notifications')
      .select()
      .eq('user_id', userId)
      .order('created_at', ascending: false);
  
  // Save to Isar (similar to items/shares)
}
```

### 3. Notifications Screen
- Show list of notifications
- Badge on sidebar showing unread count
- Mark as read when tapped
- Navigate to item when notification tapped

## Benefits

✅ Simple - uses existing sync infrastructure
✅ Offline-first - notifications sync when online
✅ No external dependencies
✅ Consistent with app architecture
✅ Easy to extend (add more notification types)

## Future Enhancements

- Push notifications via Firebase Cloud Messaging (optional)
- Notification preferences (mute certain types)
- Batch notifications (daily digest)
- In-app notification center with filters

## Implementation Steps

1. Run SQL to create notifications table + triggers
2. Create NotificationModel in Flutter
3. Add notification sync to SyncManager
4. Create notifications screen
5. Add unread badge to sidebar
6. Test all notification types
