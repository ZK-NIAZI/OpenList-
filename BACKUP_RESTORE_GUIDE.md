# OpenList Backup & Restore Guide

**Last Updated**: February 26, 2026  
**Version**: 1.0

---

## Overview

This guide covers both Git code backups and Supabase database backups for the OpenList project.

---

## 1. GIT BACKUP

### Current Backup Status

✅ **Initial Commit**: Created on master branch  
✅ **Backup Branch**: `backup-2026-02-26-ai-extraction-complete`  
✅ **Commit Message**: "feat: AI task extraction complete - Gemini 2.5 Flash integration with Quick Add and Notes"

### Creating New Backups

To create a new timestamped backup without overwriting previous ones:

```bash
# 1. Make sure all changes are committed
git add .
git commit -m "Your commit message describing the changes"

# 2. Create a timestamped backup branch
git checkout -b backup-YYYY-MM-DD-description

# Example:
git checkout -b backup-2026-02-27-image-upload-feature

# 3. Switch back to master to continue working
git checkout master
```

### Viewing All Backups

```bash
# List all branches (backups)
git branch -a

# View commit history
git log --oneline --graph --all
```

### Restoring from a Backup

```bash
# 1. View available backups
git branch -a

# 2. Switch to the backup branch
git checkout backup-2026-02-26-ai-extraction-complete

# 3. Create a new branch from this backup to work on
git checkout -b restore-from-backup-2026-02-26

# 4. Or merge backup into master (careful!)
git checkout master
git merge backup-2026-02-26-ai-extraction-complete
```

### Backup Naming Convention

Format: `backup-YYYY-MM-DD-feature-description`

Examples:
- `backup-2026-02-26-ai-extraction-complete`
- `backup-2026-02-27-image-upload-added`
- `backup-2026-03-01-before-major-refactor`
- `backup-2026-03-05-production-ready`

---

## 2. DATABASE BACKUP

### Quick Backup (Using Provided Script)

**File**: `database_backup.sql`

#### Step 1: Run Backup Script

1. Open Supabase Dashboard → SQL Editor
2. Copy contents of `database_backup.sql`
3. Click "Run"
4. Copy all output results
5. Save to a file: `backup-YYYY-MM-DD-HH-MM.sql`

#### Step 2: Save Backup File

```bash
# Create backups directory
mkdir -p backups/database

# Save with timestamp
# Example: backups/database/backup-2026-02-26-14-30.sql
```

### What Gets Backed Up

The backup script exports:
- ✅ All items (tasks, notes, lists, sections)
- ✅ All blocks (atomic content blocks)
- ✅ All item_shares (sharing permissions)
- ✅ All notifications
- ✅ All spaces (if table exists)
- ✅ All space_members (if table exists)

### What Does NOT Get Backed Up

- ❌ User accounts (auth.users) - managed by Supabase Auth
- ❌ Storage files (images) - need separate backup
- ❌ Realtime subscriptions - recreated automatically
- ❌ RLS policies - defined in schema, not data

---

## 3. COMPLETE BACKUP PROCEDURE

### Full Backup Checklist

```bash
# 1. Git Backup
git add .
git commit -m "feat: description of current state"
git checkout -b backup-$(date +%Y-%m-%d)-description
git checkout master

# 2. Database Backup
# - Run database_backup.sql in Supabase SQL Editor
# - Save output to backups/database/backup-$(date +%Y-%m-%d-%H-%M).sql

# 3. Document Backup
# - Copy .env file (if exists)
# - Copy supabase_schema.sql
# - Copy any custom SQL scripts
```

### Automated Backup Script (Optional)

Create `backup.sh` (Linux/Mac) or `backup.bat` (Windows):

```bash
#!/bin/bash
# backup.sh - Automated backup script

DATE=$(date +%Y-%m-%d)
TIME=$(date +%H-%M)

# Git backup
echo "Creating Git backup..."
git add .
git commit -m "Automated backup: $DATE $TIME"
git checkout -b backup-$DATE-auto
git checkout master

echo "✅ Git backup complete: backup-$DATE-auto"
echo "⚠️  Remember to run database_backup.sql in Supabase!"
```

---

## 4. RESTORATION PROCEDURES

### Restoring Code (Git)

```bash
# 1. List available backups
git branch -a

# 2. Checkout the backup you want
git checkout backup-2026-02-26-ai-extraction-complete

# 3. Verify it's the right version
git log --oneline -5

# 4. Create new working branch or merge to master
git checkout -b restored-working-branch
# OR
git checkout master
git reset --hard backup-2026-02-26-ai-extraction-complete
```

### Restoring Database

#### Prerequisites
1. Have a backup SQL file from `database_backup.sql` output
2. Access to Supabase Dashboard
3. Schema already created (run `supabase_schema.sql` first)

#### Step-by-Step Restoration

```sql
-- 1. CLEAR EXISTING DATA (CAREFUL!)
-- Only if you want a clean restore
TRUNCATE items CASCADE;
TRUNCATE blocks CASCADE;
TRUNCATE item_shares CASCADE;
TRUNCATE notifications CASCADE;

-- 2. RUN BACKUP SQL
-- Copy and paste the INSERT statements from your backup file
-- Run in Supabase SQL Editor

-- 3. VERIFY RESTORATION
SELECT 'items' as table_name, COUNT(*) as count FROM items
UNION ALL
SELECT 'blocks', COUNT(*) FROM blocks
UNION ALL
SELECT 'item_shares', COUNT(*) FROM item_shares
UNION ALL
SELECT 'notifications', COUNT(*) FROM notifications;

-- 4. TEST FUNCTIONALITY
-- - Login to app
-- - Check if tasks/notes appear
-- - Test creating new items
-- - Test sharing
-- - Test notifications
```

### Restoring to New Supabase Project

```sql
-- 1. Create new Supabase project
-- 2. Run supabase_schema.sql to create tables
-- 3. Run backup SQL to insert data
-- 4. Update .env with new Supabase URL and keys
-- 5. Remap user IDs if needed (see below)
```

#### User ID Remapping (if needed)

If restoring to a different Supabase project with different users:

```sql
-- Create mapping table
CREATE TEMP TABLE user_id_mapping (
  old_id UUID,
  new_id UUID
);

-- Insert mappings
INSERT INTO user_id_mapping VALUES
  ('old-user-uuid-1', 'new-user-uuid-1'),
  ('old-user-uuid-2', 'new-user-uuid-2');

-- Update items
UPDATE items i
SET created_by = m.new_id
FROM user_id_mapping m
WHERE i.created_by = m.old_id;

-- Update item_shares
UPDATE item_shares s
SET 
  shared_with_user_id = m1.new_id,
  shared_by_user_id = m2.new_id
FROM user_id_mapping m1, user_id_mapping m2
WHERE s.shared_with_user_id = m1.old_id
  AND s.shared_by_user_id = m2.old_id;

-- Update notifications
UPDATE notifications n
SET user_id = m.new_id
FROM user_id_mapping m
WHERE n.user_id = m.old_id;
```

---

## 5. BACKUP BEST PRACTICES

### Frequency

- **Git Backups**: 
  - Before major features
  - After completing features
  - Before refactoring
  - Daily if actively developing

- **Database Backups**:
  - Daily during active development
  - Before schema changes
  - Before data migrations
  - Weekly for production

### Storage

- **Git**: Push to remote repository (GitHub, GitLab, Bitbucket)
- **Database**: Store backup files in:
  - Local: `backups/database/`
  - Cloud: Google Drive, Dropbox, S3
  - Version control: Separate backup repo (for small databases)

### Retention Policy

- Keep last 7 daily backups
- Keep last 4 weekly backups
- Keep monthly backups for 6 months
- Keep major version backups indefinitely

### Testing Backups

Test restoration quarterly:
1. Create test Supabase project
2. Restore latest backup
3. Verify all data loads correctly
4. Test app functionality
5. Document any issues

---

## 6. EMERGENCY RECOVERY

### If Git Repository is Corrupted

```bash
# 1. Check if any backup branches exist
git branch -a

# 2. If branches exist, checkout backup
git checkout backup-2026-02-26-ai-extraction-complete

# 3. If repository is completely broken
# - Clone from remote (GitHub/GitLab)
# - Or restore from local backup directory
```

### If Database is Corrupted

```sql
-- 1. Immediately stop all writes
-- 2. Export current state (even if corrupted)
SELECT * FROM items INTO OUTFILE '/tmp/items_emergency.csv';

-- 3. Restore from latest backup
-- (Follow restoration procedure above)

-- 4. Manually merge any recent changes if needed
```

### If Both Git and Database are Lost

1. Check remote Git repository (GitHub/GitLab)
2. Check cloud backup storage (Drive/Dropbox)
3. Check local backup directories
4. Check Supabase automatic backups (if enabled)
5. Contact Supabase support for point-in-time recovery

---

## 7. BACKUP VERIFICATION

### Git Backup Verification

```bash
# Check backup exists
git branch | grep backup-2026-02-26

# Check backup content
git checkout backup-2026-02-26-ai-extraction-complete
git log --oneline -5
git diff master

# Verify files
ls -la lib/
ls -la android/
```

### Database Backup Verification

```sql
-- Count records in backup file
grep -c "INSERT INTO items" backup-2026-02-26-14-30.sql
grep -c "INSERT INTO blocks" backup-2026-02-26-14-30.sql

-- Verify backup file is valid SQL
-- Try running in test environment first
```

---

## 8. TROUBLESHOOTING

### Git Issues

**Problem**: "fatal: A branch named 'backup-...' already exists"
```bash
# Solution: Use different name or delete old backup
git branch -D backup-2026-02-26-ai-extraction-complete
# Then create new backup
```

**Problem**: "Your local changes would be overwritten"
```bash
# Solution: Commit or stash changes first
git stash
git checkout backup-branch
git stash pop
```

### Database Issues

**Problem**: "duplicate key value violates unique constraint"
```sql
-- Solution: Clear existing data first
TRUNCATE items CASCADE;
-- Then run backup SQL
```

**Problem**: "foreign key constraint violation"
```sql
-- Solution: Disable triggers temporarily
SET session_replication_role = 'replica';
-- Run backup SQL
SET session_replication_role = 'origin';
```

---

## 9. QUICK REFERENCE

### Create Backup
```bash
# Git
git checkout -b backup-$(date +%Y-%m-%d)-description

# Database
# Run database_backup.sql in Supabase SQL Editor
```

### List Backups
```bash
# Git
git branch -a

# Database
ls -la backups/database/
```

### Restore Backup
```bash
# Git
git checkout backup-2026-02-26-ai-extraction-complete

# Database
# Run backup SQL file in Supabase SQL Editor
```

---

## 10. CONTACTS & RESOURCES

- **Supabase Dashboard**: https://app.supabase.com
- **Supabase Docs**: https://supabase.com/docs
- **Git Documentation**: https://git-scm.com/doc
- **Project Repository**: [Your GitHub/GitLab URL]

---

**Remember**: Backups are only useful if you test restoration regularly!
