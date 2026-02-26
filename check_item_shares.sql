-- Check all item_shares to see what's shared
SELECT 
  item_shares.id,
  item_shares.item_id,
  items.title as item_title,
  item_shares.user_id,
  profiles.display_name as shared_with,
  item_shares.permission,
  item_shares.created_at
FROM item_shares
LEFT JOIN items ON items.id = item_shares.item_id
LEFT JOIN profiles ON profiles.id = item_shares.user_id
ORDER BY item_shares.created_at DESC;

-- Count shares per item
SELECT 
  items.title,
  items.id as item_id,
  COUNT(item_shares.id) as share_count
FROM items
LEFT JOIN item_shares ON item_shares.item_id = items.id
GROUP BY items.id, items.title
ORDER BY share_count DESC;
