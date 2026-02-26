# Real-time Notifications Implementation

## Overview

We've implemented real-time notifications using **Supabase Realtime (WebSockets)** instead of periodic polling. This provides instant updates when shared items are edited by other users.

## Architecture

### Components

1. **RealtimeService** (`lib/data/realtime/realtime_service.dart`)
   - Manages WebSocket subscriptions to Supabase tables
   - Handles real-time events and updates local Isar database
   - Provides callbacks for UI updates

2. **SyncManager** (updated)
   - Integrates RealtimeService
   - Starts/stops realtime subscriptions based on connectivity
   - Forwards notifications to UI

3. **NotificationOverlay** (`lib/core/widgets/notification_overlay.dart`)
   - Displays notification banners when updates arrive
   - Auto-dismisses after 5 seconds

## How It Works

### 1. Subscriptions

RealtimeService subscribes to three tables:

- **items**: Detects when items are created, updated, or deleted
- **blocks**: Detects when content blocks are edited
- **notifications**: Receives instant notification delivery

### 2. Filtering

- Only processes changes relevant to the current user (owned or shared items)
- Skips updates for items that are pending locally (user is editing)
- Prevents echo (doesn't process user's own changes)

### 3. Real-time Flow

```
User A edits shared item
    ↓
Supabase triggers notification
    ↓
WebSocket sends event to User B
    ↓
RealtimeService receives event
    ↓
Updates local Isar database
    ↓
UI automatically updates (via Isar streams)
    ↓
NotificationOverlay shows banner
```

### 4. Conflict Resolution

- Local pending changes (syncStatus.pending) are NEVER overwritten by realtime updates
- User's edits always take priority
- Realtime updates only apply to synced items

## Benefits vs Polling

| Feature | Polling | Realtime (WebSockets) |
|---------|---------|----------------------|
| Update Speed | 5-30 seconds delay | Instant (<1 second) |
| Battery Usage | High (constant requests) | Low (single connection) |
| Network Usage | High (repeated requests) | Low (event-driven) |
| Scalability | Poor (N users = N requests) | Excellent (1 connection per user) |
| Offline Handling | Manual retry | Automatic reconnection |

## Usage

### Starting Realtime

Realtime starts automatically when:
- App launches and user is online
- User comes back online after being offline

```dart
SyncManager.instance.start(); // Starts both sync and realtime
```

### Stopping Realtime

Realtime stops automatically when:
- User goes offline
- App is closed

```dart
SyncManager.instance.stop(); // Stops both sync and realtime
```

### Notification Callbacks

Set up notification callback in your UI:

```dart
SyncManager.instance.onNewNotification = (notification) {
  NotificationOverlay.show(context, notification);
};
```

## Database Triggers

The notification system relies on PostgreSQL triggers in Supabase that create notification records when:
- Items are shared
- Blocks are edited
- Comments are added
- Users are mentioned

These triggers are defined in `fix_edit_permission_complete.sql`.

## Testing

### Test Real-time Updates

1. Open app on Device A (User 1)
2. Open app on Device B (User 2)
3. Share an item from User 1 to User 2
4. Edit the item on Device A
5. Device B should receive notification instantly

### Expected Behavior

- Notification banner appears at top of screen
- Item content updates automatically in the list
- No manual refresh needed
- Works even when app is in foreground

## Troubleshooting

### Notifications Not Appearing

1. Check if realtime is connected:
   ```dart
   print(RealtimeService.instance.isSubscribed); // Should be true
   ```

2. Check Supabase logs for trigger execution

3. Verify RLS policies allow notification creation

### Delayed Updates

- Check network connectivity
- Verify WebSocket connection is active
- Check if item is pending locally (will skip realtime update)

## Future Enhancements

- [ ] Background notifications (when app is closed)
- [ ] Push notifications via FCM
- [ ] Notification history screen
- [ ] Mark all as read functionality
- [ ] Notification preferences/settings
- [ ] Sound/vibration on notification
- [ ] Group notifications by item
