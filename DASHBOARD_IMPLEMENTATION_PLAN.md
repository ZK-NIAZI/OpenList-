# Dashboard Implementation Plan

## Phase 1: Core Layout & Navigation ✅
- [x] Bottom navigation bar (Home, Tasks, Notes, Alerts)
- [ ] Top app bar with menu, title, avatars, notifications
- [ ] Main scrollable content area
- [ ] Responsive layout

## Phase 2: Overall Progress Widget
- [ ] Circular progress indicator (custom painter)
- [ ] Progress percentage display
- [ ] Stats breakdown (Active, Completed, Overdue)
- [ ] Horizontal segmented progress bar
- [ ] Real-time data from Supabase

## Phase 3: Pinned Notes Section
- [ ] Horizontal scrollable list
- [ ] Note card widget with:
  - Color-coded tags
  - Title and preview
  - Background colors
  - Tap to open note
- [ ] "See all" navigation
- [ ] Pin/unpin functionality in database

## Phase 4: Today's Tasks Section
- [ ] Task list widget
- [ ] Task item with:
  - Colored left border (status indicator)
  - Checkbox with animation
  - Task title and details
  - Time and location
  - Avatar/menu
  - Strikethrough for completed
- [ ] Filter tasks by today's date
- [ ] Swipe actions (delete, edit)

## Phase 5: Quick Add Feature
- [ ] Bottom input bar
- [ ] Quick add dialog/bottom sheet
- [ ] Create task or note quickly
- [ ] Smart detection (task vs note)

## Phase 6: Additional Features
- [ ] Collaboration avatars (shared spaces)
- [ ] Notification system
- [ ] Pull to refresh
- [ ] Empty states
- [ ] Loading states
- [ ] Error handling

## Database Schema Additions Needed:
```sql
-- Add pinned field to notes
ALTER TABLE notes ADD COLUMN is_pinned BOOLEAN DEFAULT FALSE;

-- Add status field to tasks for color coding
ALTER TABLE tasks ADD COLUMN status TEXT DEFAULT 'active'; -- active, completed, overdue

-- Add time field to tasks
ALTER TABLE tasks ADD COLUMN scheduled_time TIME;
```

## Widgets to Create:
1. `DashboardScreen` - Main container
2. `DashboardAppBar` - Top bar with avatars
3. `ProgressCard` - Overall progress widget
4. `CircularProgressPainter` - Custom circular progress
5. `SegmentedProgressBar` - Horizontal color bar
6. `PinnedNotesSection` - Horizontal scrollable notes
7. `NoteCard` - Individual note card
8. `TodayTasksSection` - Task list for today
9. `TaskItem` - Individual task with checkbox
10. `QuickAddBar` - Bottom quick add input
11. `BottomNavBar` - Navigation bar

## Color Scheme:
- Active/Primary: #6366F1 (Indigo)
- Completed/Success: #10B981 (Green)
- Overdue/Danger: #EF4444 (Red)
- Warning: #F59E0B (Orange)
- Background: #F1F5F9 (Slate-100)
- Cards: #FFFFFF (White)

## Next Steps:
1. Update database schema with new fields
2. Create reusable widget components
3. Build dashboard screen layout
4. Implement each section progressively
5. Add animations and polish
6. Test with real data
