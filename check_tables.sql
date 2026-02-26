-- =====================================================
-- CHECK IF ALL REQUIRED TABLES EXIST
-- =====================================================
-- Run this in Supabase SQL Editor to verify setup
-- =====================================================

-- Check if tables exist
SELECT 
    table_name,
    CASE 
        WHEN table_name IN (
            SELECT tablename 
            FROM pg_tables 
            WHERE schemaname = 'public'
        ) THEN '✅ EXISTS'
        ELSE '❌ MISSING'
    END as status
FROM (
    VALUES 
        ('items'),
        ('blocks'),
        ('spaces'),
        ('item_shares'),
        ('space_members')
) AS required_tables(table_name);

-- =====================================================
-- If any table shows ❌ MISSING, you need to run:
-- 1. supabase_schema.sql (for items, blocks, spaces)
-- 2. supabase_sharing_schema.sql (for item_shares, space_members)
-- =====================================================
