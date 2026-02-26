# Backup and Restore Guide

## Quick Backup Checklist

Before making risky changes, do BOTH:

1. ✅ **Git commit** (saves code)
2. ✅ **Database backup** (saves data)

---

## 1. Code Backup (Git)

### Create Restore Point
```bash
git add .
git commit -m "STABLE: Working state before [describe change]"
git push origin main  # Optional: push to remote
```

### Restore from Git
```bash
# See all commits
git log --oneline

# Restore to specific commit
git checkout <commit-hash>

# Or create a new branch from that point
git checkout -b restore-point <commit-hash>
```

---

## 2. Database Backup (Supabase)

### Quick Backup (Run in Supabase SQL Editor)

Replace `YYYYMMDD_HHMM` with current date/time (e.g., `20260225_1730`):

```sql
-- Backup all tables
CREATE TABLE items_backup_20260225_1730 AS SELECT * FROM items;
CREATE TABLE blocks_backup_20260225_1730 AS SELECT * FROM blocks;
CREATE TABLE item_shares_backup_20260225_1730 AS SELECT * FROM item_shares;
CREATE TABLE notifications_backup_20260225_1730 AS SELECT * FROM notifications;
CREATE TABLE profiles_backup_20260225_1730 AS SELECT * FROM profiles;

-- Verify
SELECT 'items' as table, COUNT(*) FROM items_backup_20260225_1730
UNION ALL SELECT 'blocks', COUNT(*) FROM blocks_backup_20260225_1730
UNION ALL SELECT 'item_shares', COUNT(*) FROM item_shares_backup_20260225_1730
UNION ALL SELECT 'notifications', COUNT(*) FROM notifications_backup_20260225_1730
UNION ALL SELECT 'profiles', COUNT(*) FROM profiles_backup_20260225_1730;
```

### Restore from Backup

⚠️ **WARNING: This deletes current data!**

```sql
-- Restore items
TRUNCATE items CASCADE;
INSERT INTO items SELECT * FROM items_backup_20260225_1730;

-- Restore blocks
TRUNCATE blocks CASCADE;
INSERT INTO blocks SELECT * FROM blocks_backup_20260225_1730;

-- Restore item_shares
TRUNCATE item_shares CASCADE;
INSERT INTO item_shares SELECT * FROM item_shares_backup_20260225_1730;

-- Restore notifications
TRUNCATE notifications CASCADE;
INSERT INTO notifications SELECT * FROM notifications_backup_20260225_1730;

-- Restore profiles
TRUNCATE profiles CASCADE;
INSERT INTO profiles SELECT * FROM profiles_backup_20260225_1730;
```

### List All Backups

```sql
SELECT table_name 
FROM information_schema.tables 
WHERE table_schema = 'public' 
  AND table_name LIKE '%_backup_%'
ORDER BY table_name;
```

### Delete Old Backups

```sql
-- Delete specific backup
DROP TABLE IF EXISTS items_backup_20260225_1730;
DROP TABLE IF EXISTS blocks_backup_20260225_1730;
-- etc...

-- Or delete all backups (careful!)
DO $$ 
DECLARE 
    r RECORD;
BEGIN
    FOR r IN (SELECT tablename FROM pg_tables 
              WHERE schemaname = 'public' 
              AND tablename LIKE '%_backup_%') 
    LOOP
        EXECUTE 'DROP TABLE IF EXISTS ' || quote_ident(r.tablename) || ' CASCADE';
    END LOOP;
END $$;
```

---

## 3. Local Isar Database Backup

The Isar database is stored locally on each device. To backup:

### Android
```bash
# Pull from device
adb pull /data/data/com.example.openlist/app_flutter/isar.isar ./backup/isar_backup.isar

# Restore to device
adb push ./backup/isar_backup.isar /data/data/com.example.openlist/app_flutter/isar.isar
```

### Or just clear and re-sync
The easiest way is to sign out (which clears local data) and sign back in (which re-syncs from Supabase).

---

## 4. Full Project Backup

### Create Complete Backup
```bash
# Create backup directory
mkdir -p ../openlist_backups/backup_20260225

# Copy entire project (excluding build files)
rsync -av --exclude 'build' \
          --exclude 'node_modules' \
          --exclude '.dart_tool' \
          --exclude '.gradle' \
          . ../openlist_backups/backup_20260225/

# Or use zip
zip -r ../openlist_backup_20260225.zip . \
    -x "build/*" "node_modules/*" ".dart_tool/*" ".gradle/*"
```

---

## 5. Automated Backup Script

Create a script to backup both code and database:

### backup.sh (Linux/Mac)
```bash
#!/bin/bash
TIMESTAMP=$(date +%Y%m%d_%H%M)

# Git commit
git add .
git commit -m "AUTO BACKUP: $TIMESTAMP"

# Database backup (requires Supabase CLI)
supabase db dump -f "backups/db_backup_$TIMESTAMP.sql"

echo "✅ Backup complete: $TIMESTAMP"
```

### backup.bat (Windows)
```batch
@echo off
set TIMESTAMP=%date:~-4%%date:~-7,2%%date:~-10,2%_%time:~0,2%%time:~3,2%

git add .
git commit -m "AUTO BACKUP: %TIMESTAMP%"

echo ✅ Backup complete: %TIMESTAMP%
```

---

## Best Practices

1. **Before risky changes**: Always create both git commit AND database backup
2. **Name backups clearly**: Use timestamps and descriptions
3. **Test restores**: Occasionally test that your backups actually work
4. **Keep multiple backups**: Don't overwrite old backups immediately
5. **Document changes**: Write clear commit messages
6. **Clean up old backups**: Delete backups older than 30 days

---

## Emergency Recovery

If something goes wrong:

1. **Don't panic** - you have backups!
2. **Check git log** - find the last working commit
3. **Check database backups** - find the matching database backup
4. **Restore code first** - `git checkout <commit>`
5. **Restore database** - Run restore SQL
6. **Test thoroughly** - Make sure everything works
7. **Document what went wrong** - Learn from it

---

## Current Stable State

**Date**: 2026-02-25
**Status**: ✅ WORKING
**Features**:
- Delete notifications working
- Duplicate cleanup working
- All enum values handled
- Database constraint updated

**To create restore point NOW**:
```bash
git add .
git commit -m "✅ STABLE: Delete notifications and duplicate fix complete"
```

Then run `create_database_backup.sql` with today's timestamp.
