# SHARING FEATURE - COMPLETE FIX INSTRUCTIONS

## ROOT CAUSE IDENTIFIED

The sharing feature had THREE fundamental problems:

### 1. **Wrong Data Type Approach**
- **Problem**: Trying to store EMAIL addresses in `user_id` columns that are defined as UUID
- **Why it failed**: UUID columns have foreign key constraints to `auth.users(id)`, can't store text
- **Impact**: PostgreSQL errors about type mismatch, foreign key violations

### 2. **Infinite Recursion in RLS Policies**
- **Problem**: The `space_members` policy was querying itself in a subquery
- **Example of bad policy**:
  ```sql
  CREATE POLICY "members_select" ON space_members
  USING (
    user_id = auth.uid() OR
    space_id IN (
      SELECT space_id FROM space_members WHERE user_id = auth.uid()
    )
  );
  ```
- **Why it fails**: The policy queries `space_members`, which triggers the same policy again → infinite loop
- **Impact**: `PostgrestException: infinite recursion detected in policy`

### 3. **Complex Policy Dependencies**
- **Problem**: Policies on different tables referencing each other created circular dependencies
- **Impact**: Couldn't alter column types because policies depended on them

## THE PROPER SOLUTION

Instead of changing column types, we:
1. **Keep UUID columns** with proper foreign keys
2. **Add email lookup function** to convert email → UUID
3. **Simplify all RLS policies** to avoid recursion
4. **Update Flutter code** to use the lookup function

---

## STEP-BY-STEP FIX

### Step 1: Run the SQL Script

1. Open your Supabase Dashboard
2. Go to SQL Editor
3. Copy and paste the contents of `fix_sharing_proper.sql`
4. Click "Run"

This script will:
- Drop ALL existing policies (clean slate)
- Ensure tables have correct UUID structure
- Create `get_user_id_by_email()` helper function
- Create simple, non-recursive RLS policies
- Set up proper access control

### Step 2: Verify the Database

After running the script, verify:

```sql
-- Check that the function exists
SELECT routine_name 
FROM information_schema.routines 
WHERE routine_name = 'get_user_id_by_email';

-- Check policies are created
SELECT tablename, policyname 
FROM pg_policies 
WHERE schemaname = 'public' 
ORDER BY tablename, policyname;

-- Test the lookup function
SELECT get_user_id_by_email('your-test-email@example.com');
```

### Step 3: Flutter Code Changes

The Flutter code has been updated in:
- `lib/features/sharing/presentation/share_dialog.dart` - Now uses email lookup
- `lib/data/sync/sync_manager.dart` - Queries by UUID only

### Step 4: Test the Sharing Flow

1. **Restart your Flutter app** (hot restart won't work, need full restart)
   ```bash
   flutter run
   ```

2. **Create a test note/task** as User A

3. **Share with User B's email**:
   - Click share button
   - Enter User B's email address
   - Select permission (view/edit)
   - Click "Share"

4. **Verify in Supabase**:
   - Go to Table Editor → `item_shares`
   - You should see a record with:
     - `item_id`: UUID of the item
     - `user_id`: UUID of User B (not email!)
     - `permission`: 'view' or 'edit'

5. **Log in as User B**:
   - Sign out from User A
   - Sign in with User B's email
   - Wait for sync to complete
   - You should see the shared item

---

## HOW IT WORKS NOW

### Sharing Flow (Technical)

1. **User A shares item with "userb@example.com"**
   ```dart
   // Flutter calls Supabase RPC function
   final userId = await supabase.rpc('get_user_id_by_email', 
     params: {'email_address': 'userb@example.com'}
   );
   // Returns: "abc-123-def-456" (User B's UUID)
   ```

2. **Create share record with UUID**
   ```dart
   await sharingRepository.shareItem(
     itemId: 'item-uuid',
     userId: 'abc-123-def-456', // UUID, not email!
     permission: SharePermission.view,
   );
   ```

3. **Sync to Supabase**
   ```sql
   INSERT INTO item_shares (item_id, user_id, permission, shared_by)
   VALUES ('item-uuid', 'abc-123-def-456', 'view', 'user-a-uuid');
   ```

4. **User B logs in and pulls data**
   ```sql
   SELECT * FROM items WHERE id IN (
     SELECT item_id FROM item_shares WHERE user_id = 'abc-123-def-456'
   );
   ```

5. **RLS Policy allows access**
   ```sql
   -- items_select_shared policy
   EXISTS (
     SELECT 1 FROM item_shares 
     WHERE item_shares.item_id = items.id 
     AND item_shares.user_id = auth.uid()
   )
   ```

### RLS Policy Structure (Non-Recursive)

All policies now follow this pattern:

```sql
-- Simple, direct checks (no recursion)
CREATE POLICY "policy_name" ON table_name
USING (
  column = auth.uid() OR  -- Direct column check
  EXISTS (                -- Subquery to OTHER table (not same table)
    SELECT 1 FROM other_table 
    WHERE condition
  )
);
```

**Key principle**: Never query the same table in its own policy!

---

## TROUBLESHOOTING

### Error: "User with email X not found"

**Cause**: The email doesn't exist in your Supabase auth.users table

**Solution**: 
1. Make sure User B has signed up first
2. Check in Supabase Dashboard → Authentication → Users
3. Verify the email is correct

### Error: "infinite recursion detected"

**Cause**: The SQL script didn't run completely

**Solution**:
1. Run this to drop ALL policies:
   ```sql
   DO $$ 
   DECLARE r RECORD;
   BEGIN
     FOR r IN (SELECT schemaname, tablename, policyname FROM pg_policies WHERE schemaname = 'public') LOOP
       EXECUTE 'DROP POLICY IF EXISTS "' || r.policyname || '" ON ' || r.schemaname || '.' || r.tablename;
     END LOOP;
   END $$;
   ```
2. Then run `fix_sharing_proper.sql` again

### Shared items not appearing

**Check these in order**:

1. **Verify share record exists**:
   ```sql
   SELECT * FROM item_shares WHERE item_id = 'your-item-id';
   ```

2. **Verify user_id is UUID, not email**:
   ```sql
   SELECT user_id, pg_typeof(user_id) FROM item_shares;
   -- Should show: uuid
   ```

3. **Check sync logs**:
   ```
   I/flutter: 📥 Fetched X item shares
   I/flutter: 📥 Fetched Y shared items from Supabase
   ```

4. **Verify RLS policies**:
   ```sql
   SELECT * FROM pg_policies WHERE tablename = 'item_shares';
   ```

### Compilation errors in Flutter

**Error**: `The getter 'userEmail' isn't defined`

**Solution**: Already fixed in the code updates above. Do a full restart:
```bash
flutter clean
flutter pub get
flutter run
```

---

## TESTING CHECKLIST

- [ ] SQL script runs without errors
- [ ] `get_user_id_by_email` function exists
- [ ] All policies created (check with `SELECT * FROM pg_policies`)
- [ ] Flutter app compiles without errors
- [ ] User A can create items
- [ ] User A can share with User B's email
- [ ] Share record appears in `item_shares` table with UUID
- [ ] User B can log in
- [ ] User B sees shared items after sync
- [ ] User B can view shared items
- [ ] User B can edit items (if permission = 'edit')
- [ ] User B cannot edit items (if permission = 'view')

---

## ARCHITECTURE SUMMARY

```
┌─────────────────────────────────────────────────────────────┐
│                     SHARING ARCHITECTURE                     │
└─────────────────────────────────────────────────────────────┘

User A (Flutter App)
  │
  ├─ Enters User B's email: "userb@example.com"
  │
  ├─ Calls: supabase.rpc('get_user_id_by_email')
  │   └─> Returns: "uuid-of-user-b"
  │
  ├─ Creates local share record (Isar)
  │   └─> userId: "uuid-of-user-b"
  │
  ├─ Syncs to Supabase
  │   └─> INSERT INTO item_shares (user_id) VALUES ('uuid-of-user-b')
  │
  └─ ✅ Share complete

User B (Flutter App)
  │
  ├─ Logs in with "userb@example.com"
  │   └─> auth.uid() = "uuid-of-user-b"
  │
  ├─ Pulls data from Supabase
  │   └─> SELECT * FROM item_shares WHERE user_id = 'uuid-of-user-b'
  │
  ├─ Fetches shared items
  │   └─> SELECT * FROM items WHERE id IN (shared_item_ids)
  │
  ├─ RLS Policy checks:
  │   └─> EXISTS (SELECT 1 FROM item_shares WHERE user_id = auth.uid())
  │   └─> ✅ Allowed
  │
  └─ ✅ User B sees shared items
```

---

## FILES MODIFIED

1. `fix_sharing_proper.sql` - Complete database fix
2. `lib/features/sharing/presentation/share_dialog.dart` - Email lookup
3. `lib/data/sync/sync_manager.dart` - UUID-based queries
4. `SHARING_FIX_INSTRUCTIONS.md` - This guide

---

## NEXT STEPS

After completing the fix:

1. Test with two real accounts
2. Verify permissions work correctly (view vs edit)
3. Test space sharing (similar flow)
4. Add error handling for edge cases
5. Consider adding user search/autocomplete

---

## SUPPORT

If you encounter issues:

1. Check Supabase logs (Dashboard → Logs)
2. Check Flutter console for sync errors
3. Verify database structure matches expected schema
4. Test the `get_user_id_by_email` function manually

The sharing feature should now work correctly with proper UUID handling and no infinite recursion!
