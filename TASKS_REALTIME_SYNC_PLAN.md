# Tasks Real-Time Sync & Notifications Plan

## Problem Statement
1. ✅ **FIXED**: Tasks tab not respecting Personal/Shared filter
2. ❌ **TODO**: Shared tasks not showing real-time edits (notes work, tasks don't)
3. ❌ **TODO**: No update notifications for tasks (notes have them)

---

## Step 1: Fix Tasks Tab Filtering ✅ DONE

### Changes Made:
- Added `selectedSpace` from provider
- Created `_getFilteredStream()` helper method
- Updated all 3 StreamBuilders (Today, Upcoming, Later) to use filtered stream
- Now respects Personal/Shared filter like Dashboard and Notes

---

## Step 2: Enable Real-Time Sync for Tasks ❌ TODO

### Current State:
- Notes have real-time sync working
- Tasks don't sync edits between users
- Need to check RealtimeService implementation

### What Needs to Happen:
1. **Check if RealtimeService listens to `items` table**
   - Currently might only listen to `blocks` table
   - Need to add listener for `items` table changes

2. **Update RealtimeService to handle item updates**
   ```dart
   // Listen to items table
   supabase
     .channel('items_channel')
     .on(
       RealtimeListenTypes.postgresChanges,
       ChannelFilter(
         event: '*',
         schema: 'public',
         table: 'items',
       ),
       (payload, [ref]) {
         // Handle item update
         _handleItemUpdate(payload);
       },
     )
     .subscribe();
   ```

3. **Implement `_handleItemUpdate()` method**
   - Parse payload
   - Update Isar with new data
   - Trigger UI refresh

### Files to Modify:
- `lib/data/sync/realtime_service.dart` (or similar)
- Add items table listener
- Handle UPDATE, INSERT, DELETE events

---

## Step 3: Add Update Notifications for Tasks ❌ TODO

### Current State:
- Notes have update notifications working
- Tasks don't create notifications on edit
- Delete notifications work for tasks

### What Needs to Happen:

#### 3.1: Database Trigger for Task Updates
Create SQL trigger similar to notes:

```sql
CREATE OR REPLACE FUNCTION notify_item_update()
RETURNS TRIGGER AS $$
DECLARE
  share_record RECORD;
  editor_name TEXT;
BEGIN
  -- Get editor's name
  SELECT display_name INTO editor_name
  FROM profiles
  WHERE id = auth.uid();
  
  IF editor_name IS NULL THEN
    editor_name := 'Someone';
  END IF;
  
  -- Only notify if item is shared
  FOR share_record IN 
    SELECT user_id 
    FROM item_shares 
    WHERE item_id = NEW.id 
    AND user_id != auth.uid()
  LOOP
    INSERT INTO notifications (
      user_id,
      type,
      title,
      message,
      item_id,
      related_user_id,
      is_read,
      created_at,
      updated_at
    ) VALUES (
      share_record.user_id,
      'update',
      'Task updated',
      editor_name || ' updated "' || NEW.title || '"',
      NEW.id,
      auth.uid(),
      false,
      NOW(),
      NOW()
    );
  END LOOP;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER item_update_notification
AFTER UPDATE ON items
FOR EACH ROW
WHEN (OLD.title IS DISTINCT FROM NEW.title 
      OR OLD.is_completed IS DISTINCT FROM NEW.is_completed
      OR OLD.due_date IS DISTINCT FROM NEW.due_date)
EXECUTE FUNCTION notify_item_update();
```

#### 3.2: Test the Trigger
1. User A shares task with User B
2. User A edits the task title
3. User B should receive notification: "User A updated 'Task Name'"

---

## Step 4: Add Block Update Notifications ❌ TODO

### Current State:
- Block edits don't create notifications
- Only item-level changes are tracked

### What Needs to Happen:

#### 4.1: Database Trigger for Block Updates
```sql
CREATE OR REPLACE FUNCTION notify_block_update()
RETURNS TRIGGER AS $$
DECLARE
  share_record RECORD;
  editor_name TEXT;
  item_title TEXT;
BEGIN
  -- Get editor's name
  SELECT display_name INTO editor_name
  FROM profiles
  WHERE id = auth.uid();
  
  IF editor_name IS NULL THEN
    editor_name := 'Someone';
  END IF;
  
  -- Get item title
  SELECT title INTO item_title
  FROM items
  WHERE id = NEW.item_id;
  
  -- Notify all users who have access to this item
  FOR share_record IN 
    SELECT user_id 
    FROM item_shares 
    WHERE item_id = NEW.item_id 
    AND user_id != auth.uid()
  LOOP
    INSERT INTO notifications (
      user_id,
      type,
      title,
      message,
      item_id,
      related_user_id,
      is_read,
      created_at,
      updated_at
    ) VALUES (
      share_record.user_id,
      'update',
      'Content updated',
      editor_name || ' updated content in "' || item_title || '"',
      NEW.item_id,
      auth.uid(),
      false,
      NOW(),
      NOW()
    );
  END LOOP;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER block_update_notification
AFTER UPDATE ON blocks
FOR EACH ROW
WHEN (OLD.content IS DISTINCT FROM NEW.content)
EXECUTE FUNCTION notify_block_update();
```

---

## Implementation Order

### Phase 1: Real-Time Sync (Most Important)
1. Check RealtimeService implementation
2. Add items table listener
3. Test: Edit task on Account A → See update on Account B

### Phase 2: Update Notifications
1. Create SQL trigger for item updates
2. Test: Edit task → Other user gets notification
3. Create SQL trigger for block updates
4. Test: Edit block → Other user gets notification

### Phase 3: Polish
1. Throttle notifications (don't spam on every keystroke)
2. Add timestamps to notifications
3. Test all scenarios

---

## Testing Checklist

### Real-Time Sync:
- [ ] Edit task title on Account A → Updates on Account B
- [ ] Toggle task completion on Account A → Updates on Account B
- [ ] Change due date on Account A → Updates on Account B
- [ ] Edit block content on Account A → Updates on Account B
- [ ] Add new block on Account A → Appears on Account B
- [ ] Delete block on Account A → Removes on Account B

### Notifications:
- [ ] Edit task title → Notification sent
- [ ] Toggle completion → Notification sent
- [ ] Change due date → Notification sent
- [ ] Edit block content → Notification sent
- [ ] Multiple edits → Don't spam notifications
- [ ] Notification shows correct editor name
- [ ] Notification shows correct timestamp

---

## Current Status
✅ Step 1: Tasks tab filtering - DONE
❌ Step 2: Real-time sync - TODO
❌ Step 3: Update notifications - TODO
❌ Step 4: Block notifications - TODO

**Next Action:** Implement Step 2 (Real-time sync for tasks)
