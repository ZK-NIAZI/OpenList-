# Real-time Notifications Testing Guide

## Prerequisites

- 2 devices or emulators
- 2 different user accounts
- Both devices connected to internet
- App installed on both devices

## Test Scenarios

### Test 1: Share Notification

**Goal**: Verify that sharing an item sends a notification

**Steps**:
1. Device A: Sign in as User 1
2. Device B: Sign in as User 2
3. Device A: Create a new task "Test Task"
4. Device A: Click share icon, enter User 2's email, grant "Edit" permission
5. Device A: Click "Share"

**Expected Result**:
- Device B: Notification banner appears: "Item shared with you"
- Device B: Task appears in task list
- Console shows: `⚡ New notification received`

---

### Test 2: Edit Notification (Real-time)

**Goal**: Verify that editing shared content triggers instant notification

**Steps**:
1. Device A: Open the shared task from Test 1
2. Device A: Edit the title to "Test Task - Updated"
3. Device A: Edit a content block
4. Wait 1-2 seconds

**Expected Result**:
- Device B: Notification banner appears: "Someone updated 'Test Task'"
- Device B: Task title updates automatically in the list
- Device B: Content updates when opening the task
- Console shows: `⚡ Block change detected: UPDATE`

---

### Test 3: Bidirectional Editing

**Goal**: Verify that both users can edit and receive notifications

**Steps**:
1. Device B: Open the shared task
2. Device B: Edit a content block
3. Device B: Add a new block
4. Wait 1-2 seconds

**Expected Result**:
- Device A: Notification banner appears: "Someone updated 'Test Task - Updated'"
- Device A: Content updates automatically
- Both devices show the same content

---

### Test 4: Offline/Online Behavior

**Goal**: Verify that realtime reconnects after going offline

**Steps**:
1. Device B: Turn off WiFi/mobile data
2. Device A: Edit the shared task
3. Wait 5 seconds
4. Device B: Turn on WiFi/mobile data
5. Wait 5 seconds

**Expected Result**:
- Device B: Console shows `🛑 Realtime service stopped` when offline
- Device B: Console shows `⚡ Starting Realtime subscriptions` when online
- Device B: Receives missed updates after reconnecting
- Device B: Shows notification for the edit

---

### Test 5: Conflict Resolution

**Goal**: Verify that local edits are not overwritten by realtime

**Steps**:
1. Device B: Start editing a block (type but don't save yet)
2. Device A: Edit the SAME block and save
3. Device B: Continue typing (block is pending locally)
4. Device B: Save the block

**Expected Result**:
- Device B: Local edits are preserved (not overwritten)
- Device B: Console shows `⏭️ Block is pending locally, skipping realtime update`
- After Device B saves, Device A receives the update

---

### Test 6: Delete Notification

**Goal**: Verify that deleting shared items notifies other users

**Steps**:
1. Device A: Delete the shared task
2. Wait 1-2 seconds

**Expected Result**:
- Device B: Task disappears from list automatically
- Device B: Console shows `⚡ Items change detected: DELETE`
- No error messages

---

### Test 7: Multiple Notifications

**Goal**: Verify that multiple rapid edits don't cause issues

**Steps**:
1. Device A: Rapidly edit multiple blocks (5-10 edits in 10 seconds)
2. Wait 5 seconds

**Expected Result**:
- Device B: Receives all updates
- Device B: May show multiple notification banners (or grouped)
- No crashes or errors
- Final state matches Device A

---

### Test 8: Permission Check

**Goal**: Verify that users without access don't receive updates

**Steps**:
1. Device A: Create a new task "Private Task"
2. Device A: DO NOT share with User 2
3. Device A: Edit the task
4. Wait 5 seconds

**Expected Result**:
- Device B: Does NOT receive notification
- Device B: Task does NOT appear in list
- Device B: Console shows `⏭️ Item not relevant to current user, skipping`

---

## Console Log Verification

### Successful Realtime Connection

```
⚡ Starting Realtime subscriptions for user: <uuid>
✅ Subscribed to items table
✅ Subscribed to blocks table
✅ Subscribed to notifications table
✅ Realtime subscriptions active
```

### Receiving Notification

```
⚡ New notification received
📬 New notification: Item updated
✅ Notification saved locally via realtime
📬 Showing notification overlay: Item updated
```

### Receiving Block Update

```
⚡ Block change detected: UPDATE
📥 Block UPDATE: <block_id> (itemId: <item_id>)
✅ Block saved locally via realtime
🔄 Data changed via realtime
```

### Skipping Pending Item

```
⏭️ Block is pending locally, skipping realtime update
```

### Skipping Irrelevant Item

```
⏭️ Item not relevant to current user, skipping
```

---

## Performance Checks

### Network Usage

1. Open Android Settings > Network & Internet > Data usage
2. Find OpenList app
3. Note data usage before test
4. Perform Test 2 (Edit Notification)
5. Check data usage after test

**Expected**: Minimal increase (<1 KB per notification)

### Battery Usage

1. Open Android Settings > Battery > Battery usage
2. Find OpenList app
3. Note battery usage before test
4. Leave app open for 30 minutes with realtime active
5. Check battery usage after test

**Expected**: Similar to before (realtime should not significantly increase battery drain)

### Memory Usage

1. Open Android Settings > Developer options > Running services
2. Find OpenList app
3. Note memory usage

**Expected**: No memory leaks, stable memory usage over time

---

## Troubleshooting

### Notifications Not Appearing

**Check**:
1. Is realtime connected? Look for `✅ Realtime subscriptions active` in console
2. Is user online? Check connectivity
3. Are RLS policies correct? Check Supabase dashboard
4. Is notification trigger enabled? Run `check_trigger_status_now.sql`

**Fix**:
```dart
// Force restart realtime
await RealtimeService.instance.stop();
await RealtimeService.instance.start();
```

### Delayed Updates

**Check**:
1. Network quality (WiFi vs mobile data)
2. Supabase region (closer = faster)
3. Device performance

**Fix**:
- Use WiFi instead of mobile data
- Restart app to refresh connection

### Duplicate Notifications

**Check**:
1. Multiple app instances running?
2. Multiple realtime subscriptions?

**Fix**:
```dart
// Ensure only one instance
if (RealtimeService.instance.isSubscribed) {
  await RealtimeService.instance.stop();
}
await RealtimeService.instance.start();
```

---

## Success Criteria

✅ All 8 test scenarios pass
✅ Notifications appear within 1 second
✅ No crashes or errors
✅ Battery usage is acceptable
✅ Network usage is minimal
✅ UI updates automatically
✅ Conflict resolution works correctly
✅ Offline/online transitions work smoothly

---

## Known Limitations

1. **Background notifications**: Currently only works when app is in foreground
2. **Notification grouping**: Multiple rapid edits show multiple banners
3. **Notification history**: No persistent history screen yet
4. **Sound/vibration**: No audio/haptic feedback yet

These can be addressed in future updates if needed.
