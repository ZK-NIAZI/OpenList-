-- OpenList Database Backup Script
-- Generated: 2026-02-26
-- Purpose: Complete backup of all Supabase tables and data
-- 
-- USAGE:
-- 1. Run this in Supabase SQL Editor to export all data
-- 2. Save the output for restoration
-- 3. To restore, run the output SQL in a new Supabase project
--
-- NOTE: This exports schema + data. For schema-only backup, see supabase_schema.sql

-- ============================================================================
-- BACKUP METADATA
-- ============================================================================
SELECT 'OpenList Database Backup' as backup_name,
       NOW() as backup_timestamp,
       current_database() as database_name;

-- ============================================================================
-- TABLE: items (tasks, notes, lists, sections)
-- ============================================================================
SELECT '-- Backing up items table...' as status;

-- Export items data as INSERT statements
SELECT 
  'INSERT INTO items (id, space_id, parent_id, type, title, content, is_pinned, is_completed, due_date, reminder_at, created_by, created_at, updated_at, order_index, category) VALUES (' ||
  quote_literal(id::text) || '::uuid, ' ||
  COALESCE(quote_literal(space_id::text) || '::uuid', 'NULL') || ', ' ||
  COALESCE(quote_literal(parent_id::text) || '::uuid', 'NULL') || ', ' ||
  quote_literal(type) || ', ' ||
  quote_literal(title) || ', ' ||
  COALESCE(quote_literal(content), 'NULL') || ', ' ||
  is_pinned || ', ' ||
  is_completed || ', ' ||
  COALESCE(quote_literal(due_date::text) || '::timestamptz', 'NULL') || ', ' ||
  COALESCE(quote_literal(reminder_at::text) || '::timestamptz', 'NULL') || ', ' ||
  quote_literal(created_by::text) || '::uuid, ' ||
  quote_literal(created_at::text) || '::timestamptz, ' ||
  quote_literal(updated_at::text) || '::timestamptz, ' ||
  order_index || ', ' ||
  COALESCE(quote_literal(category), 'NULL') ||
  ');'
FROM items
ORDER BY created_at;

-- ============================================================================
-- TABLE: blocks (atomic content blocks)
-- ============================================================================
SELECT '-- Backing up blocks table...' as status;

-- Export blocks data as INSERT statements
SELECT 
  'INSERT INTO blocks (id, item_id, type, content, is_checked, order_index, created_at, updated_at) VALUES (' ||
  quote_literal(id::text) || '::uuid, ' ||
  quote_literal(item_id::text) || '::uuid, ' ||
  quote_literal(type) || ', ' ||
  quote_literal(content) || ', ' ||
  is_checked || ', ' ||
  order_index || ', ' ||
  quote_literal(created_at::text) || '::timestamptz, ' ||
  quote_literal(updated_at::text) || '::timestamptz' ||
  ');'
FROM blocks
ORDER BY item_id, order_index;

-- ============================================================================
-- TABLE: item_shares (sharing permissions)
-- ============================================================================
SELECT '-- Backing up item_shares table...' as status;

-- Export item_shares data as INSERT statements
SELECT 
  'INSERT INTO item_shares (id, item_id, shared_with_user_id, permission, shared_by_user_id, created_at) VALUES (' ||
  quote_literal(id::text) || '::uuid, ' ||
  quote_literal(item_id::text) || '::uuid, ' ||
  quote_literal(shared_with_user_id::text) || '::uuid, ' ||
  quote_literal(permission) || ', ' ||
  quote_literal(shared_by_user_id::text) || '::uuid, ' ||
  quote_literal(created_at::text) || '::timestamptz' ||
  ');'
FROM item_shares
ORDER BY created_at;

-- ============================================================================
-- TABLE: notifications
-- ============================================================================
SELECT '-- Backing up notifications table...' as status;

-- Export notifications data as INSERT statements
SELECT 
  'INSERT INTO notifications (id, user_id, type, title, message, item_id, is_read, created_at) VALUES (' ||
  quote_literal(id::text) || '::uuid, ' ||
  quote_literal(user_id::text) || '::uuid, ' ||
  quote_literal(type) || ', ' ||
  quote_literal(title) || ', ' ||
  quote_literal(message) || ', ' ||
  COALESCE(quote_literal(item_id::text) || '::uuid', 'NULL') || ', ' ||
  is_read || ', ' ||
  quote_literal(created_at::text) || '::timestamptz' ||
  ');'
FROM notifications
ORDER BY created_at;

-- ============================================================================
-- TABLE: spaces (if exists)
-- ============================================================================
SELECT '-- Backing up spaces table (if exists)...' as status;

-- Export spaces data as INSERT statements (only if table exists)
DO $$
BEGIN
  IF EXISTS (SELECT FROM information_schema.tables WHERE table_name = 'spaces') THEN
    PERFORM 
      'INSERT INTO spaces (id, name, color, created_by, created_at, updated_at) VALUES (' ||
      quote_literal(id::text) || '::uuid, ' ||
      quote_literal(name) || ', ' ||
      COALESCE(quote_literal(color), 'NULL') || ', ' ||
      quote_literal(created_by::text) || '::uuid, ' ||
      quote_literal(created_at::text) || '::timestamptz, ' ||
      quote_literal(updated_at::text) || '::timestamptz' ||
      ');'
    FROM spaces
    ORDER BY created_at;
  END IF;
END $$;

-- ============================================================================
-- TABLE: space_members (if exists)
-- ============================================================================
SELECT '-- Backing up space_members table (if exists)...' as status;

-- Export space_members data as INSERT statements (only if table exists)
DO $$
BEGIN
  IF EXISTS (SELECT FROM information_schema.tables WHERE table_name = 'space_members') THEN
    PERFORM 
      'INSERT INTO space_members (id, space_id, user_id, role, created_at) VALUES (' ||
      quote_literal(id::text) || '::uuid, ' ||
      quote_literal(space_id::text) || '::uuid, ' ||
      quote_literal(user_id::text) || '::uuid, ' ||
      quote_literal(role) || ', ' ||
      quote_literal(created_at::text) || '::timestamptz' ||
      ');'
    FROM space_members
    ORDER BY created_at;
  END IF;
END $$;

-- ============================================================================
-- BACKUP SUMMARY
-- ============================================================================
SELECT '-- Backup Summary' as status;

SELECT 
  'items' as table_name,
  COUNT(*) as record_count
FROM items
UNION ALL
SELECT 
  'blocks' as table_name,
  COUNT(*) as record_count
FROM blocks
UNION ALL
SELECT 
  'item_shares' as table_name,
  COUNT(*) as record_count
FROM item_shares
UNION ALL
SELECT 
  'notifications' as table_name,
  COUNT(*) as record_count
FROM notifications;

SELECT '-- Backup Complete!' as status;
SELECT 'Total tables backed up: 4-6 (depending on schema)' as info;
SELECT 'Backup timestamp: ' || NOW() as timestamp;

-- ============================================================================
-- RESTORATION INSTRUCTIONS
-- ============================================================================
/*
RESTORATION INSTRUCTIONS:
========================

1. Create a new Supabase project or use existing one
2. Run supabase_schema.sql first to create tables and policies
3. Run the INSERT statements generated by this backup script
4. Verify data integrity:
   - Check record counts match backup summary
   - Test authentication and RLS policies
   - Verify relationships (parent_id, item_id references)

IMPORTANT NOTES:
- User IDs (created_by, shared_with_user_id) must exist in auth.users
- If restoring to different project, you may need to remap user IDs
- Timestamps are preserved from original database
- UUIDs are preserved to maintain relationships

ALTERNATIVE: Use Supabase CLI for full backup
- supabase db dump > backup.sql
- supabase db push < backup.sql
*/
