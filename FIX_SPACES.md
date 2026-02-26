# Fix Spaces - Remaining Changes

## Files that still need `.spaceId` changed to `.space`:

1. `lib/features/dashboard/presentation/dashboard_screen.dart` - lines 168, 201, 260
2. `lib/features/notes/presentation/notes_screen.dart` - lines 169, 216

## Search and replace in each file:
```
item.spaceId == selectedSpaceId
```
TO:
```
item.space == selectedSpaceId
```

## Then regenerate Isar:
```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

## Then recreate missing files:
1. `lib/features/sidebar/presentation/app_sidebar.dart`
2. `lib/features/alerts/presentation/alerts_screen.dart`
