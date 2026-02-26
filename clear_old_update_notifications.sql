-- Clear old update notifications so new ones with user names can be created
DELETE FROM notifications
WHERE type = 'update';

-- Verify
SELECT COUNT(*) as remaining_update_notifications
FROM notifications
WHERE type = 'update';
