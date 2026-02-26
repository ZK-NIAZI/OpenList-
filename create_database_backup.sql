-- =====================================================
-- DATABASE BACKUP SCRIPT
-- =====================================================
-- Run this before making risky changes
-- Date: 2026-02-25

-- Generate timestamp for unique backup names
-- Replace YYYYMMDD_HHMM with current timestamp when running

-- Create backup tables
CREATE TABLE IF NOT EXISTS items_backup_YYYYMMDD_HHMM AS 
SELECT * FROM items;

CREATE TABLE IF NOT EXISTS blocks_backup_YYYYMMDD_HHMM AS 
SELECT * FROM blocks;

CREATE TABLE IF NOT EXISTS item_shares_backup_YYYYMMDD_HHMM AS 
SELECT * FROM item_shares;

CREATE TABLE IF NOT EXISTS notifications_backup_YYYYMMDD_HHMM AS 
SELECT * FROM notifications;

CREATE TABLE IF NOT EXISTS profiles_backup_YYYYMMDD_HHMM AS 
SELECT * FROM profiles;

CREATE TABLE IF NOT EXISTS space_members_backup_YYYYMMDD_HHMM AS 
SELECT * FROM space_members;

-- Verify backup was created
SELECT 
    'Backup created successfully!' as status,
    NOW() as backup_time;

-- Show record counts
SELECT 'items' as table_name, COUNT(*) as records FROM items_backup_YYYYMMDD_HHMM
UNION ALL
SELECT 'blocks', COUNT(*) FROM blocks_backup_YYYYMMDD_HHMM
UNION ALL
SELECT 'item_shares', COUNT(*) FROM item_shares_backup_YYYYMMDD_HHMM
UNION ALL
SELECT 'notifications', COUNT(*) FROM notifications_backup_YYYYMMDD_HHMM
UNION ALL
SELECT 'profiles', COUNT(*) FROM profiles_backup_YYYYMMDD_HHMM
UNION ALL
SELECT 'space_members', COUNT(*) FROM space_members_backup_YYYYMMDD_HHMM;

-- =====================================================
-- TO RESTORE FROM BACKUP:
-- =====================================================
-- WARNING: This will DELETE all current data!
-- 
-- TRUNCATE items CASCADE;
-- INSERT INTO items SELECT * FROM items_backup_YYYYMMDD_HHMM;
-- 
-- TRUNCATE blocks CASCADE;
-- INSERT INTO blocks SELECT * FROM blocks_backup_YYYYMMDD_HHMM;
-- 
-- TRUNCATE item_shares CASCADE;
-- INSERT INTO item_shares SELECT * FROM item_shares_backup_YYYYMMDD_HHMM;
-- 
-- TRUNCATE notifications CASCADE;
-- INSERT INTO notifications SELECT * FROM notifications_backup_YYYYMMDD_HHMM;
-- 
-- TRUNCATE profiles CASCADE;
-- INSERT INTO profiles SELECT * FROM profiles_backup_YYYYMMDD_HHMM;
-- 
-- TRUNCATE space_members CASCADE;
-- INSERT INTO space_members SELECT * FROM space_members_backup_YYYYMMDD_HHMM;
-- =====================================================
