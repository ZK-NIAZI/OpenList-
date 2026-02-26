# Edit Permission Debug Guide

## Current Status
- User B can VIEW shared items ✅
- User B can see blocks with content ✅
- RLS policies updated to allow edit permission ✅
- `onChanged` callback NOT firing when User B types ❌

## Problem
When User B (with edit permission) types in a TextFormField, the `onChanged` callback is not being called. This means `updateBlock()` is never invoked, so changes don't save.

## Debug Steps

### Step 1: Verify SQL Script Was Run
1. Open Supabase SQL Editor
2. Run this query to check if policies exist:
```sql
SELECT 
  schemaname,
  tablename,
  policyname,
  cmd,
  qual IS NOT NULL as has_using,
  with_check IS NOT NULL as has_with_check
FROM pg_policies 
WHERE schemaname = 'public'
AND tablename IN ('items', 'blocks')
AND policyname LIKE '%update%'
ORDER BY tablename, policyname;
```

Expected output:
- `items_update_own` - has_using: true, has_with_check: true
- `items_update_shared` - has_using: true, has_with_check: true
- `blocks_update_own` - has_using: true, has_with_check: true
- `blocks_update_shared` - has_using: true, has_with_check: true

If policies are missing, run: `fix_edit_permission_simple.sql`

### Step 2: Test User B Can Type
1. Login as User B
2. Open a shared note (with edit permission)
3. Tap on a text block
4. Check console logs:
   - Look for: `🔵 Building text block: [blockId] with content: "[content]"`
   - Try typing some text
   - Look for: `🔵 ========== TEXT BLOCK ONCHANGED FIRED ==========`

### Step 3: Diagnose the Issue

#### If you see "Building text block" but NOT "ONCHANGED FIRED":
- The TextFormField is rendering but `onChanged` is not being called
- This is a Flutter widget issue, not a database issue
- Possible causes:
  1. TextFormField is disabled or read-only (check if there's a `readOnly: true` property)
  2. Widget is rebuilding too frequently, resetting the field
  3. ValueKey is causing widget to not update properly

#### If you see "ONCHANGED FIRED" but changes don't save:
- The callback IS working, but `updateBlock()` is failing
- Check logs for: `🔵 ========== UPDATE BLOCK START ==========`
- If you see this, check for errors in the update process
- If you DON'T see this, the repository method is not being called

#### If you DON'T see "Building text block" at all:
- The blocks are not loading for User B
- Check if blocks are being pulled from Supabase
- Look for: `🔵 Blocks stream updated: X blocks received`

### Step 4: Test Database Permissions Directly
Run this in Supabase SQL Editor (replace UUIDs with actual values):

```sql
-- Test if User B can update a block
-- Replace [user_b_uuid] with User B's actual UUID
-- Replace [block_id] with actual block ID
-- Replace [item_id] with actual item ID

-- First, verify the share exists
SELECT * FROM item_shares 
WHERE item_id = '[item_id]' 
AND user_id = '[user_b_uuid]';

-- Then try to update as User B (this simulates what the app does)
-- You'll need to use Supabase's auth.uid() function or test via the app
```

### Step 5: Alternative Solution - Use TextEditingController
If `onChanged` continues to not fire, we can switch to using TextEditingController with a debounced save:

```dart
// In _TaskDetailScreenState
final Map<String, TextEditingController> _blockControllers = {};
Timer? _saveTimer;

@override
void dispose() {
  _saveTimer?.cancel();
  for (var controller in _blockControllers.values) {
    controller.dispose();
  }
  super.dispose();
}

Widget _buildTextBlock(BlockModel block) {
  // Get or create controller
  if (!_blockControllers.containsKey(block.blockId)) {
    _blockControllers[block.blockId] = TextEditingController(text: block.content);
    _blockControllers[block.blockId]!.addListener(() {
      _debouncedSave(block, _blockControllers[block.blockId]!.text);
    });
  }
  
  return TextField(
    controller: _blockControllers[block.blockId],
    // ... rest of the properties
  );
}

void _debouncedSave(BlockModel block, String newContent) {
  _saveTimer?.cancel();
  _saveTimer = Timer(const Duration(milliseconds: 500), () {
    if (block.content != newContent) {
      block.content = newContent;
      _repository.updateBlock(block);
    }
  });
}
```

## Next Actions
1. Run `fix_edit_permission_simple.sql` in Supabase if not already done
2. Test as User B and check console logs
3. Report back which logs you see (or don't see)
4. If `onChanged` is not firing, we'll implement the TextEditingController solution
