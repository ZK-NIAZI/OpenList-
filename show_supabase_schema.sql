-- Get all tables in the public schema
SELECT 
    'Tables:' as info_type,
    table_name,
    NULL as column_name,
    NULL as data_type
FROM information_schema.tables 
WHERE table_schema = 'public' 
AND table_type = 'BASE TABLE'

UNION ALL

-- Get all columns for each table
SELECT 
    'Columns:' as info_type,
    table_name,
    column_name,
    data_type
FROM information_schema.columns
WHERE table_schema = 'public'
ORDER BY info_type DESC, table_name, column_name;

-- Get all functions
SELECT 
    'Functions:' as info_type,
    routine_name as function_name,
    routine_type
FROM information_schema.routines
WHERE routine_schema = 'public'
ORDER BY routine_name;

-- Get all triggers
SELECT 
    'Triggers:' as info_type,
    trigger_name,
    event_object_table as table_name,
    action_timing || ' ' || event_manipulation as trigger_event
FROM information_schema.triggers
WHERE trigger_schema = 'public'
ORDER BY event_object_table, trigger_name;

-- Get RLS policies
SELECT 
    'RLS Policies:' as info_type,
    tablename,
    policyname,
    cmd as command
FROM pg_policies
WHERE schemaname = 'public'
ORDER BY tablename, policyname;
