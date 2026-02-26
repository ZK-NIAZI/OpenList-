# Task Block Implementation Guide
Creating tasks inline within notes, just like headings and checklists

---

## 🎯 Concept

Users can add task blocks directly in notes using the "/" command, just like they add headings or checklists. Each task block is a clickable item that opens a full task detail page.

---

## 📊 Data Flow

```
Note Detail Page
  ↓ User types "/"
Block Type Picker appears
  ├─ Heading
  ├─ Text
  ├─ Checklist
  ├─ 📋 Task (NEW!)
  └─ Image
  ↓ User selects "Task"
Create Task Item in database (type=task)
  ↓ Returns task item_id
Create Block in note (type=task, content=item_id)
  ↓ Block saved
Task Block Widget displays in note
  ↓ User taps task block
Navigate to Task Detail Page (full task editor)
  ↓ User can add sub-tasks
Navigate to Child Task Detail Page
```

---

## 🗄️ Database Structure

### Block Model
```dart
class BlockModel {
  int id;
  String blockId;
  String itemId;           // The note this block belongs to
  BlockType type;          // text, heading, checklist, task (NEW!)
  String content;          // For task blocks: stores the task item_id
  bool isChecked;          // For task blocks: completion status
  int orderIndex;
  DateTime updatedAt;
  SyncStatus syncStatus;
}
```

### Item Model (unchanged)
```dart
class ItemModel {
  int id;
  String itemId;
  String? parentId;        // For sub-tasks: parent task item_id
  ItemType type;           // task, note, list
  String title;
  bool isCompleted;
  DateTime? dueDate;
  DateTime? reminderAt;
  String? createdBy;
  // ... other fields
}
```

---

## 🎨 UI Components

### 1. Task Block in Note (Read-only view)
```
┌─────────────────────────────────────┐
│ 📝 Meeting Notes                    │
│                                     │
│ # Action Items                      │  ← Heading block
│                                     │
│ ☐ Finalize design mockups          │  ← Task block (unchecked)
│   📅 Due: Mar 15                    │
│                                     │
│ ☑ Review with team                  │  ← Task block (checked)
│   ✓ Completed                       │
│                                     │
│ Follow up next week                 │  ← Text block
└─────────────────────────────────────┘
```

### 2. Block Type Picker (When user types "/")
```
┌─────────────────────────────────────┐
│ /                                   │  ← User typed "/"
│ ┌─────────────────────────────┐   │
│ │ 📝 Heading                  │   │
│ │ 📄 Text                     │   │
│ │ ☑️ Checklist                │   │
│ │ 📋 Task                     │   │  ← NEW!
│ │ 🖼️ Image                    │   │
│ └─────────────────────────────┘   │
└─────────────────────────────────────┘
```

### 3. Task Block Widget (Inline in note)
```dart
class TaskBlockWidget extends StatelessWidget {
  final BlockModel block;
  final ItemModel taskItem; // Fetched using block.content as item_id
  
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        // Navigate to task detail page
        context.push('/task/${taskItem.id}');
      },
      child: Container(
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            // Checkbox
            Checkbox(
              value: taskItem.isCompleted,
              onChanged: (value) {
                // Toggle completion
              },
            ),
            // Task title
            Expanded(
              child: Text(
                taskItem.title,
                style: TextStyle(
                  decoration: taskItem.isCompleted 
                    ? TextDecoration.lineThrough 
                    : null,
                ),
              ),
            ),
            // Due date badge (if set)
            if (taskItem.dueDate != null)
              Chip(
                label: Text('📅 ${formatDate(taskItem.dueDate)}'),
                backgroundColor: Colors.blue.shade50,
              ),
            // Arrow icon
            Icon(Icons.chevron_right),
          ],
        ),
      ),
    );
  }
}
```

---

## 🔧 Implementation Steps

### Step 1: Add Task Block Type
```dart
// lib/data/models/block_model.dart
enum BlockType {
  text,
  heading,
  checklist,
  task,      // NEW!
  image,
}
```

### Step 2: Update Block Type Picker
```dart
// lib/features/notes/presentation/note_detail_screen.dart

void _showBlockTypePicker() {
  showModalBottomSheet(
    context: context,
    builder: (context) => ListView(
      children: [
        ListTile(
          leading: Icon(Icons.title),
          title: Text('Heading'),
          onTap: () => _addBlock(BlockType.heading),
        ),
        ListTile(
          leading: Icon(Icons.text_fields),
          title: Text('Text'),
          onTap: () => _addBlock(BlockType.text),
        ),
        ListTile(
          leading: Icon(Icons.check_box),
          title: Text('Checklist'),
          onTap: () => _addBlock(BlockType.checklist),
        ),
        ListTile(
          leading: Icon(Icons.task_alt),
          title: Text('Task'),                    // NEW!
          onTap: () => _addTaskBlock(),           // NEW!
        ),
        ListTile(
          leading: Icon(Icons.image),
          title: Text('Image'),
          onTap: () => _addBlock(BlockType.image),
        ),
      ],
    ),
  );
}

Future<void> _addTaskBlock() async {
  // 1. Create a new task item
  final taskItem = await _itemRepository.createItem(
    title: 'New Task',
    type: ItemType.task,
  );
  
  // 2. Create a block that references this task
  final block = await _itemRepository.createBlock(
    itemId: widget.noteId,           // The note this block belongs to
    type: BlockType.task,
    content: taskItem.itemId,        // Store task item_id in content
    orderIndex: _blocks.length,
  );
  
  // 3. Refresh blocks list
  setState(() {
    _blocks.add(block);
  });
  
  Navigator.pop(context); // Close picker
}
```

### Step 3: Create Task Block Widget
```dart
// lib/core/widgets/block_widgets/task_block_widget.dart

class TaskBlockWidget extends ConsumerWidget {
  final BlockModel block;
  
  const TaskBlockWidget({required this.block});
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Fetch the task item using block.content as item_id
    final taskItemId = block.content;
    
    return FutureBuilder<ItemModel?>(
      future: ref.read(itemRepositoryProvider).getItemByItemId(taskItemId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return CircularProgressIndicator();
        }
        
        final taskItem = snapshot.data!;
        
        return InkWell(
          onTap: () {
            // Navigate to task detail page
            context.push('/task/${taskItem.id}');
          },
          child: Container(
            margin: EdgeInsets.symmetric(vertical: 8),
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              border: Border.all(
                color: taskItem.isCompleted 
                  ? Colors.green.shade300 
                  : Colors.grey.shade300,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                // Checkbox
                Checkbox(
                  value: taskItem.isCompleted,
                  onChanged: (value) async {
                    await ref.read(itemRepositoryProvider)
                      .toggleComplete(taskItem.id);
                  },
                ),
                SizedBox(width: 8),
                // Task title
                Expanded(
                  child: Text(
                    taskItem.title,
                    style: TextStyle(
                      fontSize: 16,
                      decoration: taskItem.isCompleted 
                        ? TextDecoration.lineThrough 
                        : null,
                      color: taskItem.isCompleted 
                        ? Colors.grey 
                        : Colors.black,
                    ),
                  ),
                ),
                // Due date badge
                if (taskItem.dueDate != null) ...[
                  SizedBox(width: 8),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getDueDateColor(taskItem.dueDate!),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '📅 ${_formatDate(taskItem.dueDate!)}',
                      style: TextStyle(fontSize: 12, color: Colors.white),
                    ),
                  ),
                ],
                // Arrow icon
                SizedBox(width: 8),
                Icon(Icons.chevron_right, color: Colors.grey),
              ],
            ),
          ),
        );
      },
    );
  }
  
  Color _getDueDateColor(DateTime dueDate) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final due = DateTime(dueDate.year, dueDate.month, dueDate.day);
    
    if (due.isBefore(today)) {
      return Colors.red; // Overdue
    } else if (due.isAtSameMomentAs(today)) {
      return Colors.orange; // Due today
    } else {
      return Colors.blue; // Future
    }
  }
  
  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(Duration(days: 1));
    final dateOnly = DateTime(date.year, date.month, date.day);
    
    if (dateOnly.isAtSameMomentAs(today)) {
      return 'Today';
    } else if (dateOnly.isAtSameMomentAs(tomorrow)) {
      return 'Tomorrow';
    } else {
      return '${date.month}/${date.day}';
    }
  }
}
```

### Step 4: Update Block Renderer
```dart
// lib/features/notes/presentation/note_detail_screen.dart

Widget _buildBlock(BlockModel block) {
  switch (block.type) {
    case BlockType.text:
      return TextBlockWidget(block: block);
    case BlockType.heading:
      return HeadingBlockWidget(block: block);
    case BlockType.checklist:
      return ChecklistBlockWidget(block: block);
    case BlockType.task:                          // NEW!
      return TaskBlockWidget(block: block);       // NEW!
    case BlockType.image:
      return ImageBlockWidget(block: block);
    default:
      return SizedBox.shrink();
  }
}
```

---

## 🔄 Sync Behavior

### When Task Block is Created
1. Create task item in Isar (instant)
2. Create block in Isar with content=task_item_id (instant)
3. SyncManager syncs both to Supabase (background)
4. Realtime broadcasts to other users
5. Other users see the task block appear in the note

### When Task is Completed via Block
1. Update task item in Isar (instant)
2. Block widget rebuilds showing checkmark
3. SyncManager syncs to Supabase
4. Realtime broadcasts completion
5. Other users see the task marked complete

### When Task is Opened and Edited
1. User taps task block
2. Navigate to task detail page
3. Edit task title, add blocks, set due date
4. All changes sync normally
5. Task block in note reflects updated title/due date

---

## 🎨 Visual Examples

### Before (Current)
```
┌─────────────────────────────────────┐
│ 📝 Meeting Notes                    │
│                                     │
│ # Action Items                      │
│ - Finalize design mockups           │  ← Plain text
│ - Review with team                  │  ← Plain text
│ - Schedule follow-up                │  ← Plain text
└─────────────────────────────────────┘
```

### After (With Task Blocks)
```
┌─────────────────────────────────────┐
│ 📝 Meeting Notes                    │
│                                     │
│ # Action Items                      │
│                                     │
│ ┌─────────────────────────────┐   │
│ │ ☐ Finalize design mockups   │ → │  ← Clickable task
│ │   📅 Due: Mar 15            │   │
│ └─────────────────────────────┘   │
│                                     │
│ ┌─────────────────────────────┐   │
│ │ ☐ Review with team          │ → │  ← Clickable task
│ │   📅 Due: Mar 16            │   │
│ └─────────────────────────────┘   │
│                                     │
│ ┌─────────────────────────────┐   │
│ │ ☑ Schedule follow-up        │ → │  ← Completed task
│ │   ✓ Completed               │   │
│ └─────────────────────────────┘   │
└─────────────────────────────────────┘
```

---

## ✅ Benefits

1. **Seamless Integration** - Tasks live naturally within notes
2. **Full Task Features** - Each task block opens to full task detail with sub-tasks, due dates, etc.
3. **Real-time Sync** - Task blocks sync like any other block
4. **Completion Tracking** - Check tasks off directly in the note
5. **Context Preservation** - Tasks stay in the context of the meeting/note where they were created

---

## 🚀 Next Steps

After task blocks are working:
1. Add "Add Sub-task" button in task detail page
2. Implement parent-child task relationships
3. Add breadcrumb navigation for sub-tasks
4. Implement due date/reminder inheritance from parent
5. Add auto-completion when all sub-tasks are done
