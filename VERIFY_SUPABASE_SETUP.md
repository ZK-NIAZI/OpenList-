# Verify Supabase Setup for Sharing

## Quick Verification Checklist

Run these queries in your Supabase SQL Editor to verify everything is set up correctly:

### 1. Check if sharing tables exist
```sql
SELECT table_name 
FROM information_schema.tables 
WHERE table_schema = 'public' 
AND table_name IN ('item_shares', 'space_members');
```
**Expected**: Should return 2 rows (item_shares, space_members)

### 2. Check if helper function exists
```sql
SELECT routine_name 
FROM information_schema.routines 
WHERE routine_schema = 'public' 
AND routine_name = 'get_user_id_by_email';
```
**Expected**: Should return 1 row (get_user_id_by_email)

### 3. Test the helper function
```sql
-- Replace with an actual user email from your auth.users table
SELECT get_user_id_by_email('your-test-email@example.com');
```
**Expected**: Should return a UUID (not null)

### 4. Check RLS is enabled
```sql
SELECT tablename, rowsecurity 
FROM pg_tables 
WHERE schemaname = 'public' 
AND tablename IN ('items', 'blocks', 'item_shares', 'space_members', 'spaces');
```
**Expected**: All tables should have rowsecurity = true

### 5. Check RLS policies exist
```sql
SELECT tablename, policyname, cmd 
FROM pg_policies 
WHERE schemaname = 'public' 
AND tablename IN ('items', 'item_shares')
ORDER BY tablename, policyname;
```
**Expected**: Should see multiple policies for each table:
- items: items_select_own, items_select_shared, items_select_space_shared, items_insert, items_update_own, items_update_shared, items_delete
- item_shares: item_shares_select, item_shares_insert, item_shares_update, item_shares_delete

### 6. Check column types are correct
```sql
SELECT 
  table_name,
  column_name,
  data_type
FROM information_schema.columns
WHERE table_schema = 'public'
AND table_name = 'item_shares'
AND column_name IN ('id', 'item_id', 'user_id', 'shared_by')
ORDER BY column_name;
```
**Expected**: All should be 'uuid' type, NOT 'text'

### 7. Verify foreign key constraints
```sql
SELECT
  tc.table_name,
  tc.constraint_name,
  kcu.column_name,
  ccu.table_name AS foreign_table_name,
  ccu.column_name AS foreign_column_name
FROM information_schema.table_constraints AS tc
JOIN information_schema.key_column_usage AS kcu
  ON tc.constraint_name = kcu.constraint_name
JOIN information_schema.constraint_column_usage AS ccu
  ON ccu.constraint_name = tc.constraint_name
WHERE tc.constraint_type = 'FOREIGN KEY'
AND tc.table_name = 'item_shares';
```
**Expected**: Should show foreign keys to items(id) and auth.users(id)

## If Any Checks Fail

### Missing tables or wrong structure
Run this script:
```bash
fix_sharing_complete.sql
```

### Missing helper function
The function should be created by `fix_sharing_complete.sql`, but if it's missing:
```sql
CREATE OR REPLACE FUNCTION get_user_id_by_email(email_address TEXT)
RETURNS UUID AS $
DECLARE
  user_uuid UUID;
BEGIN
  SELECT id INTO user_uuid
  FROM auth.users
  WHERE email = email_address
  LIMIT 1;
  
  RETURN user_uuid;
END;
$ LANGUAGE plpgsql SECURITY DEFINER;
```

### Wrong column types (TEXT instead of UUID)
You need to recreate the tables. Run:
```bash
fix_sharing_complete.sql
```
**WARNING**: This will delete existing sharing data!

### Missing RLS policies
Run:
```bash
fix_sharing_complete.sql
```

## Test Sharing Manually in Supabase

### 1. Get two user UUIDs
```sql
SELECT id, email FROM auth.users LIMIT 2;
```
Note down:
- User A UUID: `[UUID-A]`
- User A email: `[email-A]`
- User B UUID: `[UUID-B]`
- User B email: `[email-B]`

### 2. Create a test item as User A
```sql
-- Set the auth context to User A
SET request.jwt.claims TO '{"sub": "[UUID-A]"}';

INSERT INTO items (id, title, type, created_by)
VALUES (
  gen_random_uuid(),
  'Test Shared Item',
  'note',
  '[UUID-A]'
)
RETURNING id;
```
Note down the returned item ID: `[ITEM-ID]`

### 3. Share the item with User B
```sql
INSERT INTO item_shares (id, item_id, user_id, permission, shared_by)
VALUES (
  gen_random_uuid(),
  '[ITEM-ID]',
  '[UUID-B]',
  'view',
  '[UUID-A]'
);
```

### 4. Verify User B can see the item
```sql
-- Set the auth context to User B
SET request.jwt.claims TO '{"sub": "[UUID-B]"}';

-- Try to select the shared item
SELECT * FROM items WHERE id = '[ITEM-ID]';
```
**Expected**: Should return the item (not empty)

### 5. Verify User B can see the share record
```sql
-- Still as User B
SELECT * FROM item_shares WHERE item_id = '[ITEM-ID]';
```
**Expected**: Should return the share record

## Common Issues

### Issue: "permission denied for table item_shares"
**Cause**: RLS is enabled but no policies allow access
**Solution**: Run `fix_sharing_complete.sql` to create policies

### Issue: "null value in column 'user_id' violates not-null constraint"
**Cause**: Trying to insert email instead of UUID
**Solution**: Use `get_user_id_by_email()` function to convert email to UUID

### Issue: "infinite recursion detected in policy"
**Cause**: Policies reference each other in a loop
**Solution**: Run `fix_sharing_complete.sql` to create simple, non-recursive policies

### Issue: Function returns NULL
**Cause**: User with that email doesn't exist
**Solution**: Verify the email exists in `auth.users` table

## Final Verification

After running all checks, you should have:
- ✅ item_shares table with UUID columns
- ✅ space_members table with UUID columns
- ✅ get_user_id_by_email() function working
- ✅ RLS enabled on all tables
- ✅ RLS policies allowing shared access
- ✅ Foreign key constraints in place
- ✅ Manual test showing User B can see shared items

If all checks pass, the sharing feature should work in your Flutter app!
