# AI Extraction Implementation Plan

## PHASE 1: UI/Layout Changes ✅ (Do This First)

### Current State
- Notes and Tasks both open in `TaskDetailScreen` (route: `/task/${id}`)
- Tasks can add sub-tasks with quick-add layout (date, time, reminder)
- Notes currently show sub-task button but without date/time options

### Required Changes

#### 1. Update TaskDetailScreen for Notes
**File:** `lib/features/task/presentation/task_detail_screen.dart`

**Changes:**
- When item type is `NOTE`, show "Add Task" button instead of "Add Sub-task"
- "Add Task" should open quick-add sheet with date/time/reminder options
- Created tasks become children of the note (parent_id = note.itemId)
- Tasks created from notes should display with full task UI (checkbox, due date badge)

#### 2. Keep Existing Task Behavior
- When item type is `TASK`, keep current "Add Sub-task" button
- Sub-tasks open in same quick-add layout (already working)
- All sharing and notification functionality remains unchanged

### Implementation Steps

1. **Detect item type in TaskDetailScreen**
   ```dart
   final isNote = _currentItem!.type == ItemType.note;
   final isTask = _currentItem!.type == ItemType.task;
   ```

2. **Conditional button rendering**
   ```dart
   ElevatedButton.icon(
     onPressed: isNote ? _addTaskToNote : _addSubTask,
     icon: const Icon(Icons.add),
     label: Text(isNote ? 'Add Task' : 'Add Sub-task'),
   )
   ```

3. **Add task to note function**
   ```dart
   Future<void> _addTaskToNote() async {
     // Show quick-add sheet
     final result = await showModalBottomSheet(
       context: context,
       builder: (context) => QuickAddSheet(
         parentId: _currentItem!.itemId,
         isSubTask: true,
       ),
     );
     // Task is created with parent_id set to note
   }
   ```

4. **Update sub-tasks list title**
   ```dart
   Text(
     isNote 
       ? '✅ Tasks ($completedCount/${subTasks.length} completed)'
       : '📋 Sub-tasks ($completedCount/${subTasks.length} completed)',
   )
   ```

---

## PHASE 2: AI Extraction (Do After UI Changes)

### Goal
Extract structured data from natural language text to auto-create tasks with dates, times, and reminders.

### Examples
- "Buy groceries tomorrow" → Task with due date = tomorrow
- "Meeting with John on Friday at 3pm" → Task with due date = Friday 3pm
- "Deadline in 2 days" → Task with due date = today + 2 days
- "Call mom next week" → Task with due date = next Monday
- "Submit report by end of month" → Task with due date = last day of current month

### Model Options

#### Option 1: Gemini 1.5 Flash (RECOMMENDED) ⭐
**Pros:**
- Free tier: 15 requests/minute, 1M requests/day
- Fast response time (~1-2 seconds)
- Excellent at structured output (JSON mode)
- Good at date/time extraction
- Supports function calling
- 1M token context window

**Cons:**
- Requires API key (free from Google AI Studio)
- Internet connection required

**Cost:** FREE for your use case

#### Option 2: Claude 3.5 Haiku (Alternative)
**Pros:**
- Very fast and accurate
- Excellent instruction following
- Good at structured extraction

**Cons:**
- Costs money ($0.25 per 1M input tokens)
- Requires Anthropic API key

#### Option 3: GPT-4o-mini (Alternative)
**Pros:**
- Fast and cheap
- Good at structured tasks
- Reliable

**Cons:**
- Costs money ($0.15 per 1M input tokens)
- Requires OpenAI API key

#### Option 4: Local LLM (Not Recommended)
**Pros:**
- No API costs
- Works offline

**Cons:**
- Requires significant device resources
- Slower on mobile
- Less accurate than cloud models
- Complex setup

### Recommended: Gemini 1.5 Flash

**Why:**
1. FREE for your usage volume
2. Fast enough for real-time extraction
3. Excellent at structured JSON output
4. Easy to integrate with Flutter
5. Reliable date/time parsing

---

## PHASE 3: Implementation Architecture

### 1. Add Gemini Package
```yaml
# pubspec.yaml
dependencies:
  google_generative_ai: ^0.2.0
```

### 2. Create AI Service
```dart
// lib/services/ai_extraction_service.dart
class AIExtractionService {
  final GenerativeModel _model;
  
  AIExtractionService(String apiKey) 
    : _model = GenerativeModel(
        model: 'gemini-1.5-flash',
        apiKey: apiKey,
      );
  
  Future<TaskExtraction?> extractTask(String text) async {
    // Send prompt to Gemini
    // Parse response
    // Return structured data
  }
}
```

### 3. Extraction Data Model
```dart
class TaskExtraction {
  final String title;
  final DateTime? dueDate;
  final DateTime? reminderAt;
  final bool isTask; // vs note
  final List<String> keywords;
  
  TaskExtraction({
    required this.title,
    this.dueDate,
    this.reminderAt,
    required this.isTask,
    this.keywords = const [],
  });
}
```

### 4. Prompt Engineering
```
You are a task extraction assistant. Analyze the following text and extract:
1. Task title (cleaned up)
2. Due date (if mentioned)
3. Reminder time (if mentioned)
4. Whether this is a task or just a note

Text: "{user_input}"
Current date: {current_date}

Return JSON:
{
  "title": "cleaned task title",
  "dueDate": "ISO 8601 date or null",
  "reminderAt": "ISO 8601 datetime or null",
  "isTask": true/false,
  "keywords": ["deadline", "tomorrow", etc]
}

Rules:
- "tomorrow" = current date + 1 day
- "in X days" = current date + X days
- "next week" = next Monday
- "end of month" = last day of current month
- If no time specified, use 9:00 AM
- If text is just notes/thoughts, set isTask=false
```

### 5. Integration Points

#### A. Quick Add Dialog
- User types text
- On submit, call AI extraction
- Show extracted data for confirmation
- User can edit before saving

#### B. Note to Task Conversion
- When adding task to note
- AI analyzes note content
- Suggests task with extracted date
- User confirms or edits

#### C. Smart Paste
- Detect when user pastes text
- Auto-extract if it looks like a task
- Show suggestion toast

---

## PHASE 4: User Experience Flow

### Flow 1: Quick Add with AI
```
1. User opens quick add
2. Types: "Buy groceries tomorrow at 5pm"
3. AI extracts:
   - Title: "Buy groceries"
   - Due: Tomorrow 5:00 PM
   - Reminder: Tomorrow 4:30 PM (30 min before)
4. Show preview with extracted data
5. User confirms or edits
6. Task created
```

### Flow 2: Note to Task
```
1. User has note: "Remember to call John about the project deadline next Friday"
2. Clicks "Add Task" in note
3. AI suggests:
   - Title: "Call John about project deadline"
   - Due: Next Friday 9:00 AM
4. User confirms
5. Task created as child of note
```

### Flow 3: Batch Extraction
```
1. User has note with multiple tasks:
   "- Buy milk tomorrow
    - Call dentist on Monday
    - Submit report by Friday"
2. Clicks "Extract Tasks" button
3. AI finds 3 tasks
4. Shows preview of all 3
5. User confirms
6. All tasks created
```

---

## PHASE 5: Settings & Configuration

### AI Settings Screen
```dart
- Enable/Disable AI extraction
- API key configuration
- Auto-extract on paste (toggle)
- Default reminder time (30 min before, 1 hour before, etc)
- Extraction confidence threshold
```

### Privacy Considerations
- API key stored securely (flutter_secure_storage)
- User data sent to Google AI (disclose in privacy policy)
- Option to disable AI features
- No data stored by Google (per Gemini API terms)

---

## PHASE 6: Testing Strategy

### Test Cases
1. Simple dates: "tomorrow", "today", "next week"
2. Specific dates: "on Friday", "March 15th"
3. Relative dates: "in 3 days", "in 2 weeks"
4. Times: "at 3pm", "at 15:00", "in the morning"
5. Keywords: "deadline", "due", "by", "before"
6. Non-tasks: "I went to the store" (should not create task)
7. Multiple tasks in one text
8. Ambiguous text

### Edge Cases
- Past dates (should warn user)
- Invalid dates ("on Blursday")
- Multiple dates in one text
- No date mentioned
- Very long text (>1000 chars)

---

## PHASE 7: Rollout Plan

### Step 1: UI Changes (Week 1)
- Update TaskDetailScreen for notes
- Add "Add Task" button for notes
- Test with manual task creation

### Step 2: AI Integration (Week 2)
- Add Gemini package
- Create AI service
- Implement extraction logic
- Add settings screen

### Step 3: Testing (Week 3)
- Test all date formats
- Test edge cases
- Get user feedback
- Refine prompts

### Step 4: Polish (Week 4)
- Add loading states
- Add error handling
- Add confirmation dialogs
- Add analytics

---

## Cost Estimation

### Gemini 1.5 Flash (FREE Tier)
- 15 requests/minute
- 1,500,000 requests/day
- Assuming 100 extractions/day per user
- Can support 15,000 users for FREE

### If you exceed free tier:
- Gemini 1.5 Flash: $0.075 per 1M input tokens
- Average extraction: ~200 tokens
- 1M extractions = $15
- Very affordable even at scale

---

## Next Steps

1. ✅ Deploy `fix_subtask_notifications.sql` to Supabase
2. 🔄 Implement UI changes in TaskDetailScreen
3. 🔄 Test note → task creation flow
4. 🔄 Get Gemini API key from Google AI Studio
5. 🔄 Implement AI extraction service
6. 🔄 Add extraction to quick-add flow
7. 🔄 Test and refine

---

## Questions to Answer

1. Should AI extraction be automatic or manual (button click)?
2. Should we show confidence scores to users?
3. Should we support batch extraction (multiple tasks from one note)?
4. Should we add a "Smart Paste" feature?
5. Should we store extraction history for learning?

