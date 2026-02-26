# Critical Fixes Needed

## Summary
The app has compilation errors due to missing files and inconsistent space implementation.

## Issues

### 1. Missing Files (DELETED)
- `lib/features/sidebar/presentation/app_sidebar.dart` - NEEDS TO BE RECREATED
- `lib/features/alerts/presentation/alerts_screen.dart` - NEEDS TO BE RECREATED

### 2. Space Implementation Inconsistency
The code uses `spaceId` but the `ItemModel` has `space` (string name, not ID).

**Current ItemModel field:**
```dart
String? space; // Space name: 'Personal', 'Work', etc.
```

**Code expects:**
```dart
String? spaceId; // Space ID (UUID)
```

### 3. Files That Need Space Field Fixed
All these files reference `item.spaceId` which doesn't exist:
- `lib/data/sync/sync_manager.dart` (lines 176, 366)
- `lib/features/upcoming/presentation/upcoming_screen.dart` (line 73)
- `lib/features/dashboard/presentation/dashboard_screen.dart` (lines 168, 201, 260)
- `lib/features/tasks/presentation/tasks_screen.dart` (lines 133, 176, 231)
- `lib/features/notes/presentation/notes_screen.dart` (lines 169, 216)
- `lib/data/repositories/item_repository.dart` (line 39)

## Recommended Solution

### Option 1: Use `space` (string name) - SIMPLER
Change all `spaceId` references to `space` and use space names like "Personal", "Work" instead of IDs.

### Option 2: Add `spaceId` field - MORE COMPLEX
Add `spaceId` field to ItemModel and regenerate Isar code.

## Immediate Actions Needed

1. Recreate missing files (sidebar, alerts screen)
2. Choose Option 1 or 2 for space implementation
3. Run `flutter pub run build_runner build --delete-conflicting-outputs`
4. Fix all compilation errors

## Current Status
- App cannot compile
- Multiple files deleted
- Space feature partially implemented
- Search feature complete ✅
- Upcoming feature complete ✅
