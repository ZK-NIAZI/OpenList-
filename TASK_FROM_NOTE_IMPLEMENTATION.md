# Task from Note Implementation

## Problem Statement
When users clicked the "Task" button in the bottom toolbar of a note detail page, it created a sub-task with NO date/time options. These tasks:
- ❌ Didn't show in the main Tasks page
- ❌ Didn't show in Upcoming section  
- ❌ Had no way to set urgency, due date, or reminder
- ❌ Were children of the note (parent_id set)

## Solution
Changed the "Task" button behavior to:
- ✅ Show the QuickAddSheet (same as sidebar quick-add)
- ✅ Create a **standalone task** (NO parent_id)
- ✅ Task appears in main Tasks page
- ✅ Task appears in Upcoming section
- ✅ Task is referenced from the note via a block (not a child)

## Changes Made

### 1. Updated `_addTaskBlock()` in TaskDetailScreen
**File:** `lib/features/task/presentation/task_detail_screen.dart`

**Before:**
```dart
Future<void> _addTaskBlock() async {
  // Created a child task with parent_id
  final taskItem = await _repository.createItem(
    title: 'New Task',
    type: ItemType.task,
  );
  // No date/time options
}
```

**After:**
```dart
Future<void> _addTaskBlock() async {
  // Show QuickAddSheet for full task creation
  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => const QuickAddSheet(),
  );
  
  // Get the newly created task and reference it in the note
  final recentTasks = await _repository.getRecentTasks(limit: 1);
  if (recentTasks.isNotEmpty) {
    final taskItem = recentTasks.first;
    
    // Create block reference (NOT a parent-child relationship)
    await _repository.createBlock(
      itemId: _currentItem!.itemId,
      type: BlockType.subTask,
      content: taskItem.itemId,
      orderIndex: _blocksNotifier.value.length,
    );
  }
}
```

### 2. Added `getRecentTasks()` Method
**File:** `lib/data/repositories/item_repository.dart`

```dart
// Get most recently created tasks (for linking from notes)
Future<List<ItemModel>> getRecentTasks({int limit = 1}) async {
  final isar = await _isarService.db;
  
  final tasks = await isar.itemModels
      .filter()
      .typeEqualTo(ItemType.task)
      .sortByCreatedAtDesc()
      .limit(limit)
      .findAll();
  
  return tasks;
}
```

## How It Works Now

### User Flow
1. User opens a note detail page
2. Clicks "Task" button in bottom toolbar
3. QuickAddSheet appears with:
   - Task title input
   - Category selection (Personal/Work/Urgent)
   - Due date picker
   - Reminder time picker
   - Recurring options
   - Space selector
4. User fills in task details
5. Clicks "Add Task"
6. Task is created as a **standalone task** (no parent_id)
7. A block reference is added to the note
8. Task appears in:
   - ✅ Main Tasks page
   - ✅ Upcoming section
   - ✅ Note content (as a clickable task block)

### Data Structure

**Task (ItemModel):**
```dart
{
  itemId: "uuid-123",
  title: "Buy groceries",
  type: ItemType.task,
  parentId: null,  // ← NO parent! Standalone task
  dueDate: DateTime(2026, 2, 26),
  reminderAt: DateTime(2026, 2, 26, 9, 0),
  category: "Personal",
  // ... other fields
}
```

**Block Reference (BlockModel):**
```dart
{
  blockId: "uuid-456",
  itemId: "note-uuid",  // ← The note's ID
  type: BlockType.subTask,
  content: "uuid-123",  // ← References the task
  orderIndex: 3,
}
```

## Benefits

1. **Full Task Features**: Users can set due dates, reminders, categories
2. **Appears Everywhere**: Task shows in Tasks page, Upcoming, Dashboard
3. **Still Linked to Note**: Block reference keeps the connection
4. **No Confusion**: Clear that it's a real task, not just a note item
5. **Consistent UX**: Same quick-add experience everywhere

## Sharing & Notifications

All existing sharing and notification functionality remains unchanged:
- ✅ Tasks can be shared independently
- ✅ Notes can be shared independently
- ✅ Notifications work for both
- ✅ RLS policies apply correctly

## Next Steps

### Phase 1: Test Current Implementation ✅
- Test creating tasks from notes
- Verify tasks appear in Tasks page
- Verify tasks appear in Upcoming
- Verify block reference works
- Test editing/deleting tasks

### Phase 2: AI Extraction (Future)
Once this is working, we'll add AI extraction to:
- Parse natural language ("Buy milk tomorrow")
- Extract dates ("in 2 days", "next Friday")
- Extract times ("at 3pm")
- Auto-fill QuickAddSheet fields
- Suggest task vs note classification

See `AI_EXTRACTION_PLAN.md` for details.

## Testing Checklist

- [ ] Open a note
- [ ] Click "Task" button in bottom toolbar
- [ ] QuickAddSheet appears
- [ ] Fill in task details (title, due date, reminder)
- [ ] Click "Add Task"
- [ ] Task appears in note as a block
- [ ] Task appears in Tasks page
- [ ] Task appears in Upcoming section
- [ ] Click task block in note → opens task detail
- [ ] Edit task → changes reflect everywhere
- [ ] Delete task → block reference removed from note
- [ ] Share note → task remains independent
- [ ] Share task → note remains independent

