# Simplify Spaces Architecture

## Problem
- Spaces table in Supabase is empty
- Complex sync logic between local SpaceModel and Supabase
- Items reference space_id (UUID) which doesn't exist
- Over-engineered for simple filtering

## Solution
Use simple TEXT column for space names instead of separate table

## Changes Required

### 1. Database (Supabase)
- Drop `spaces` table
- Drop `space_members` table  
- Change `items.space_id` (UUID) to `items.space` (TEXT)
- Default all items to 'Personal' space

### 2. Flutter Models
- Remove `SpaceModel` entirely
- Remove `SpaceMemberModel` (not needed for simple spaces)
- Change `ItemModel.spaceId` to `ItemModel.space` (String)
- Hardcode available spaces: ['Personal', 'Work']

### 3. Flutter Repositories
- Remove `SpaceRepository` entirely
- Remove space sync logic from `SyncManager`
- Update `ItemRepository` to use space names
- Remove `SharingRepository.addSpaceMember()` methods

### 4. Flutter UI
- Update sidebar to use hardcoded space list
- Update space filter to use space names
- Update quick add to use space names
- Remove "Add Space" functionality (keep it simple)

### 5. Space Provider
- Change from storing space ID to storing space name
- Default to 'Personal'

## Benefits
- Much simpler architecture
- No sync complexity for spaces
- Easier to understand and maintain
- Faster queries (no joins needed)
- Works immediately without Supabase setup

## Migration Path
1. Run `simplify_spaces.sql` in Supabase
2. Regenerate Isar schemas: `flutter pub run build_runner build --delete-conflicting-outputs`
3. Update all Dart code
4. Test thoroughly
