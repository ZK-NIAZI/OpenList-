# Debug Update Sync Issue - Testing Guide

## Changes Made

### 1. Fixed Save Logic in `task_detail_screen.dart`
**Problem**: The `_autoSave()` method was checking `_hasChanges` flag, but this flag could be set to false before dispose() was called, causing the dispose() save to be skipped.

**Solution**: 
- Removed `_hasChanges` check from `_autoSave()`
- Now compares actual title change instead of relying on flag
- Simplified dispose() to just clean up resources
- WillPopScope and back button both call `_autoSave()` which now always checks for changes

### 2. Enhanced Logging in `task_detail_screen.dart`
- **Title change tracking**: Logs when user types and `_hasChanges` is set
- **Dispose tracking**: Logs when dispose() is called and what conditions are met
- **Current state logging**: Shows item title, _hasChanges value, and syncStatus

### 2. Comprehensive Logging in `item_repository.dart`
- **updateItem() detailed flow**:
  - Item details (title, id, itemId)
  - syncStatus BEFORE and AFTER setting to pending
  - Isar write transaction completion
  - Verification read to confirm item was saved correctly
  - Sync trigger confirmation
- **getPendingItems() database dump**:
  - Shows ALL items in database with their sync status
  - Shows filtered pending items
  - Helps identify if items are being saved but not marked as pending

### 3. What the Logs Will Tell Us

The logs will reveal one of these scenarios:

#### Scenario A: Dispose Not Called
```
🔵 Title changed to: Test1 EDITED
🔵 _hasChanges set to true
(No dispose logs)
```
**Problem**: dispose() isn't being called when user navigates away
**Solution**: Use WillPopScope or addListener on title controller

#### Scenario B: _hasChanges is False
```
🔵 DISPOSE CALLED - _currentItem: Test1, _hasChanges: false
⚠️  Dispose: No save needed (_currentItem null or no changes)
```
**Problem**: _hasChanges isn't being set to true when user types
**Solution**: Check if onChanged is actually firing

#### Scenario C: updateItem Not Called
```
🔵 DISPOSE CALLED - _currentItem: Test1, _hasChanges: true
🔵 Disposing - saving item: Test1 EDITED
(No updateItem logs)
```
**Problem**: updateItem() isn't being invoked
**Solution**: Check if _repository.updateItem() is actually called

#### Scenario D: Item Saved But Not Marked Pending
```
🔵 ========== UPDATE ITEM START ==========
🔵 New syncStatus AFTER setting: pending (1)
✅ Item updated in Isar
🔍 Verification - Item in DB: Test1 EDITED, syncStatus: synced
```
**Problem**: Item is being saved but syncStatus isn't persisting
**Solution**: Check Isar schema generation or enum handling

#### Scenario E: Everything Works But Sync Doesn't Find It
```
✅ Item updated in Isar: Test1 EDITED (marked as pending)
🔍 Verification - Item in DB: Test1 EDITED, syncStatus: pending
📊 Sync status: 0 pending items found
```
**Problem**: getPendingItems() filter isn't working
**Solution**: Check Isar query or enum comparison

## Testing Steps

### Step 1: Create a Note
1. Open the app
2. Create a new note with title "Test1"
3. Check console for creation logs
4. Verify note appears in list

### Step 2: Edit the Note
1. Open "Test1" note
2. Change title to "Test1 EDITED"
3. Watch console for:
   ```
   🔵 Title changed to: Test1 EDITED
   🔵 _hasChanges set to true
   ```

### Step 3: Navigate Back
1. Press back button
2. Watch console for:
   ```
   🔵 DISPOSE CALLED - _currentItem: Test1 EDITED, _hasChanges: true
   🔵 Disposing - saving item: Test1 EDITED
   🔵 ========== UPDATE ITEM START ==========
   ...
   ✅ Item updated in Isar: Test1 EDITED (marked as pending)
   🔍 Verification - Item in DB: Test1 EDITED, syncStatus: pending
   ```

### Step 4: Wait for Sync
1. Wait 2-3 seconds for sync to trigger
2. Watch console for:
   ```
   🔄 Starting sync cycle...
   📊 Sync status: X pending items found
   🔍 Total items in database: X
      📄 Test1 EDITED - syncStatus: pending (1)
   🔍 getPendingItems: Found 1 pending items
      ⏳ Test1 EDITED (syncStatus: pending)
   📤 Pushing 1 pending items to Supabase...
   📤 Syncing: Test1 EDITED (itemId: xxx)
   ✅ Synced to Supabase: Test1 EDITED
   ```

### Step 5: Verify in Supabase
1. Go to Supabase dashboard
2. Check `items` table
3. Find the item by UUID
4. Verify `title` column shows "Test1 EDITED"
5. Verify `updated_at` is recent

### Step 6: Test Cross-Device Sync
1. Log out from the app
2. Log back in
3. Wait for sync to pull
4. Check if "Test1 EDITED" appears (not "Test1")

## Expected Console Output (Success)

```
🔵 Title changed to: Test1 EDITED
🔵 _hasChanges set to true
🔵 DISPOSE CALLED - _currentItem: Test1 EDITED, _hasChanges: true
🔵 Disposing - saving item: Test1 EDITED
🔵 Current syncStatus before update: synced
🔵 ========== UPDATE ITEM START ==========
🔵 Item title: Test1 EDITED
🔵 Item id (Isar): 123
🔵 Item itemId (UUID): abc-def-ghi
🔵 Current syncStatus BEFORE update: synced (0)
🔵 New syncStatus AFTER setting: pending (1)
🔵 About to write to Isar...
🔵 Isar put() completed
✅ Item updated in Isar: Test1 EDITED (marked as pending)
🔍 Verification - Item in DB: Test1 EDITED, syncStatus: pending
🔵 Triggering sync...
🔵 ========== UPDATE ITEM END ==========
🔄 Starting sync cycle...
📥 Pulling from Supabase for user: xxx
📥 Fetched X owned items from Supabase
📊 Sync status: X pending items found
🔍 Total items in database: X
   📄 Test1 EDITED - syncStatus: pending (1)
🔍 getPendingItems: Found 1 pending items
   ⏳ Test1 EDITED (syncStatus: pending)
📤 Pushing 1 pending items to Supabase...
📋 Items to sync: Test1 EDITED
📤 Syncing: Test1 EDITED (itemId: abc-def-ghi)
✅ Synced to Supabase: Test1 EDITED
✅ Successfully synced 1 items
✅ Sync cycle completed successfully
```

## What to Report

After testing, report:

1. **Which scenario occurred** (A, B, C, D, or E from above)
2. **Full console output** from the test
3. **What you see in the UI** (does the title update in the list?)
4. **What you see in Supabase** (is the item there? what's the title?)

## Quick Fixes to Try

If the issue persists, we can try these immediate fixes:

### Fix 1: Save on Every Keystroke
```dart
@override
void initState() {
  super.initState();
  _loadTask();
  
  // Save on every change
  _titleController.addListener(() {
    if (_currentItem != null) {
      _currentItem!.title = _titleController.text;
      _repository.updateItem(_currentItem!);
    }
  });
}
```

### Fix 2: Force Save on Back Button
```dart
leading: IconButton(
  icon: Icon(Icons.arrow_back),
  onPressed: () async {
    if (_currentItem != null) {
      _currentItem!.title = _titleController.text.trim();
      await _repository.updateItem(_currentItem!);
    }
    Navigator.pop(context);
  },
),
```

### Fix 3: Use Timer for Auto-Save
```dart
Timer? _debounceTimer;

void _onTitleChanged(String value) {
  _debounceTimer?.cancel();
  _debounceTimer = Timer(Duration(seconds: 1), () {
    if (_currentItem != null) {
      _currentItem!.title = value;
      _repository.updateItem(_currentItem!);
    }
  });
}
```

## Notes

- The logging is very verbose on purpose - we need to see exactly where the flow breaks
- Once we identify the issue, we'll remove most of the debug logs
- The sync infrastructure is solid - we just need to ensure updates trigger it correctly
