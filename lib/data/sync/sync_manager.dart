import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:openlist/data/repositories/item_repository.dart';
import 'package:openlist/data/repositories/sharing_repository.dart';
import 'package:openlist/data/models/item_model.dart';
import 'package:openlist/data/models/block_model.dart';
import 'package:openlist/data/models/item_share_model.dart';
import 'package:openlist/data/models/space_member_model.dart';
import 'package:openlist/data/models/notification_model.dart';
import 'package:openlist/data/local/isar_service.dart';
import 'package:openlist/core/models/sync_status.dart';
import 'package:openlist/data/realtime/realtime_service.dart';
import 'package:openlist/services/notification_service.dart';

class SyncManager {
  static final SyncManager instance = SyncManager._();
  SyncManager._();

  final ItemRepository _itemRepository = ItemRepository();
  final SharingRepository _sharingRepository = SharingRepository();
  final IsarService _isarService = IsarService.instance;
  final RealtimeService _realtimeService = RealtimeService.instance;
  StreamSubscription? _connectivitySubscription;
  bool _isSyncing = false;
  bool _isOnline = false;

  // Callback for sync status updates
  Function(bool isSyncing, bool success)? onSyncStatusChanged;
  
  // Callback for new notifications (forwarded from RealtimeService)
  Function(NotificationModel)? onNewNotification;

  // Start monitoring connectivity and sync
  void start() {
    // Listen to connectivity changes
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((result) {
      final wasOffline = !_isOnline;
      _isOnline = result != ConnectivityResult.none;
      
      // If we just came online, sync immediately and start realtime
      if (wasOffline && _isOnline) {
        triggerSync();
        _startRealtime();
      } else if (!_isOnline) {
        // If we went offline, stop realtime
        _stopRealtime();
      }
    });

    // Check initial connectivity
    Connectivity().checkConnectivity().then((result) {
      _isOnline = result != ConnectivityResult.none;
      
      if (_isOnline) {
        triggerSync();
        _startRealtime();
      }
    });
  }

  // Start realtime subscriptions
  Future<void> _startRealtime() async {
    try {
      // Set up callbacks
      _realtimeService.onNewNotification = (notification) {
        print('📬 New notification received: ${notification.title}');
        
        // Show push notification on home screen
        NotificationService().showCollaborationNotification(
          title: notification.title,
          message: notification.message,
          itemId: notification.itemId,
        );
        
        // Forward to UI
        onNewNotification?.call(notification);
      };

      _realtimeService.onDataChanged = () {
        print('🔄 Data changed via realtime');
        // UI will automatically update via Isar streams
      };

      // Start subscriptions
      await _realtimeService.start();
      print('✅ Realtime service started');
    } catch (e) {
      print('❌ Failed to start realtime: $e');
    }
  }

  // Stop realtime subscriptions
  Future<void> _stopRealtime() async {
    try {
      await _realtimeService.stop();
      print('🛑 Realtime service stopped');
    } catch (e) {
      print('❌ Failed to stop realtime: $e');
    }
  }

  // Trigger sync manually (called after any write)
  Future<void> triggerSync() async {
    if (_isSyncing) return;
    if (!_isOnline) return;

    _isSyncing = true;
    onSyncStatusChanged?.call(true, false);
    
    try {
      // Step 1: Pull remote changes first (to avoid conflicts)
      await _pullFromSupabase();
      
      // Step 2: Push local pending changes
      await _pushToSupabase();
      
      // Step 3: Sync sharing data
      await _pushSharingToSupabase();
      await _pullSharingFromSupabase();
      
      onSyncStatusChanged?.call(false, true);
    } catch (e) {
      debugPrint('Sync error: $e');
      onSyncStatusChanged?.call(false, false);
    } finally {
      _isSyncing = false;
    }
  }

  // Pull changes from Supabase
  Future<void> _pullFromSupabase() async {
    try {
      final supabase = Supabase.instance.client;
      
      // Check if user is authenticated
      if (supabase.auth.currentSession == null) {
        print('⚠️  Not authenticated, skipping pull');
        return;
      }

      final userId = supabase.auth.currentUser?.id;
      if (userId == null) {
        print('⚠️  No user ID, skipping pull');
        return;
      }

      print('📥 Pulling from Supabase for user: $userId');
      
      // Get user email first
      final userEmail = supabase.auth.currentUser?.email;
      print('📧 User email: $userEmail');
      
      // Fetch items created by this user
      final ownedItems = await supabase
          .from('items')
          .select()
          .eq('created_by', userId)
          .order('updated_at', ascending: false);
      
      print('📥 Fetched ${ownedItems.length} owned items from Supabase');
      
      // Fetch items shared WITH this user (by UUID, not email)
      print('🔍 Looking for shares with user_id=$userId');
      
      final sharedItemIds = await supabase
          .from('item_shares')
          .select('item_id')
          .eq('user_id', userId);
      
      print('📥 Found ${sharedItemIds.length} share records for this user');
      for (final share in sharedItemIds) {
        print('   📄 Share: item_id=${share['item_id']}');
      }
      
      List<dynamic> sharedItems = [];
      if (sharedItemIds.isNotEmpty) {
        final itemIds = sharedItemIds.map((s) => s['item_id']).toList();
        print('🔍 Fetching items with IDs: $itemIds');
        
        sharedItems = await supabase
            .from('items')
            .select()
            .inFilter('id', itemIds);
        
        print('📥 Fetched ${sharedItems.length} shared items from Supabase');
        
        // Clean up orphaned shares (items that were deleted but shares remain)
        if (sharedItems.length < sharedItemIds.length) {
          final fetchedItemIds = sharedItems.map((item) => item['id'] as String).toSet();
          final orphanedItemIds = itemIds.where((id) => !fetchedItemIds.contains(id)).toList();
          
          print('⚠️  Found ${orphanedItemIds.length} orphaned shares (items deleted but shares remain)');
          for (final orphanedId in orphanedItemIds) {
            print('   🗑️  Cleaning up orphaned share for item: $orphanedId');
            try {
              await supabase
                  .from('item_shares')
                  .delete()
                  .eq('item_id', orphanedId)
                  .eq('user_id', userId);
            } catch (e) {
              print('   ❌ Failed to clean up orphaned share: $e');
            }
          }
        }
        
        for (final item in sharedItems) {
          print('   📄 Shared item: ${item['title']} (id: ${item['id']})');
        }
      }
      
      // Combine owned and shared items, removing duplicates
      // (an item can appear in both lists if user owns it AND it's shared with them)
      final itemsMap = <String, dynamic>{};
      for (final item in ownedItems) {
        final itemId = item['id'] as String;
        itemsMap[itemId] = item;
        print('   ➕ Added owned item to map: ${item['title']} (id: $itemId)');
      }
      for (final item in sharedItems) {
        final itemId = item['id'] as String;
        if (itemsMap.containsKey(itemId)) {
          print('   ⚠️  Skipping duplicate shared item: ${item['title']} (id: $itemId) - already in owned items');
        } else {
          itemsMap[itemId] = item;
          print('   ➕ Added shared item to map: ${item['title']} (id: $itemId)');
        }
      }
      
      // IMPORTANT: Also fetch sub-tasks (children) of shared items
      // Sub-tasks inherit access from their parent
      print('🔍 ========== SUB-TASK FETCHING START ==========');
      print('🔍 Items in map before sub-task fetch: ${itemsMap.length}');
      print('🔍 Item IDs that could be parents: ${itemsMap.keys.toList()}');
      
      if (itemsMap.isNotEmpty) {
        final parentIds = itemsMap.keys.toList();
        print('🔍 Fetching sub-tasks for ${parentIds.length} parent items...');
        print('🔍 Parent IDs: $parentIds');
        
        try {
          // Query sub-tasks using inFilter (correct syntax for this Supabase version)
          final subTasks = await supabase
              .from('items')
              .select()
              .inFilter('parent_id', parentIds);
          
          print('📥 Fetched ${subTasks.length} sub-tasks from Supabase');
          
          if (subTasks.isEmpty) {
            print('⚠️  No sub-tasks found for these parents');
            print('⚠️  This could mean:');
            print('   1. No sub-tasks exist in database');
            print('   2. Sub-tasks have null parent_id');
            print('   3. Query syntax issue');
          }
          
          for (final subTask in subTasks) {
            final subTaskId = subTask['id'] as String;
            final subTaskTitle = subTask['title'] as String;
            final subTaskParentId = subTask['parent_id'] as String?;
            
            print('   📄 Found sub-task: "$subTaskTitle" (id: $subTaskId, parent: $subTaskParentId)');
            
            if (!itemsMap.containsKey(subTaskId)) {
              itemsMap[subTaskId] = subTask;
              print('   ➕ Added sub-task to map');
            } else {
              print('   ⏭️  Sub-task already in map (duplicate)');
            }
          }
        } catch (e) {
          print('❌ Error fetching sub-tasks: $e');
          print('❌ Stack trace: ${StackTrace.current}');
        }
      } else {
        print('⚠️  itemsMap is empty, skipping sub-task fetch');
      }
      
      print('🔍 Items in map after sub-task fetch: ${itemsMap.length}');
      print('🔍 ========== SUB-TASK FETCHING END ==========');
      
      final allItems = itemsMap.values.toList();
      
      print('📊 Total unique items after deduplication: ${allItems.length} (owned: ${ownedItems.length}, shared: ${sharedItems.length})');
      print('📋 Unique item IDs in map: ${itemsMap.keys.toList()}');
      
      // Build a map of existing items by itemId for efficient lookup
      final isar = await _isarService.db;
      final existingItemsMap = <String, int>{};
      final pendingItemIds = <String>{};
      final duplicateIds = <int>[]; // Track duplicates to delete
      
      // Get count and iterate to build map
      final count = await isar.itemModels.count();
      print('🔍 Checking ${count} existing items in Isar for duplicates...');
      
      for (int i = 0; i < count; i++) {
        final existing = await isar.itemModels.get(i + 1);
        if (existing != null) {
          // Check if we already have this itemId
          if (existingItemsMap.containsKey(existing.itemId)) {
            // This is a duplicate! Mark for deletion
            print('⚠️  Found duplicate item in Isar: ${existing.title} (itemId: ${existing.itemId}, local id: ${existing.id})');
            duplicateIds.add(existing.id);
          } else {
            existingItemsMap[existing.itemId] = existing.id;
            // Track pending items - don't overwrite them
            if (existing.syncStatus == SyncStatus.pending) {
              pendingItemIds.add(existing.itemId);
            }
          }
        }
      }
      
      // Clean up duplicates BEFORE saving new items
      if (duplicateIds.isNotEmpty) {
        print('🧹 Cleaning up ${duplicateIds.length} duplicate items from Isar...');
        await isar.writeTxn(() async {
          for (final duplicateId in duplicateIds) {
            await isar.itemModels.delete(duplicateId);
            print('   🗑️  Deleted duplicate with local id: $duplicateId');
          }
        });
        print('✅ Duplicates cleaned up');
      } else {
        print('✅ No duplicates found in Isar');
      }
      
      // Save to local Isar
      for (final itemData in allItems) {
        try {
          final itemId = itemData['id'] as String;
          
          // Skip if this item is pending locally (don't overwrite unsaved changes)
          if (pendingItemIds.contains(itemId)) {
            print('⏭️  Skipping pending item: $itemId (has local changes)');
            continue;
          }
          
          print('💾 Saving item from Supabase: ${itemData['title']} (id: $itemId)');
          print('   📦 Item data: type=${itemData['type']}, createdBy=${itemData['created_by']}');
          
          final item = ItemModel(
            itemId: itemId,
            parentId: itemData['parent_id'] as String?,
            type: ItemType.values.firstWhere(
              (e) => e.name == itemData['type'],
              orElse: () => ItemType.task,
            ),
            title: itemData['title'] as String,
            content: itemData['content'] as String?,
            isPinned: itemData['is_pinned'] as bool? ?? false,
            isCompleted: itemData['is_completed'] as bool? ?? false,
            dueDate: itemData['due_date'] != null 
                ? DateTime.parse(itemData['due_date'] as String)
                : null,
            reminderAt: itemData['reminder_at'] != null
                ? DateTime.parse(itemData['reminder_at'] as String)
                : null,
            createdBy: itemData['created_by'] as String?, // IMPORTANT: Preserve original creator
            createdAtParam: DateTime.parse(itemData['created_at'] as String),
            updatedAtParam: DateTime.parse(itemData['updated_at'] as String),
            orderIndex: itemData['order_index'] as int? ?? 0,
            category: itemData['category'] as String?,
            syncStatus: SyncStatus.synced, // Already synced from server
          );
          
          print('   ✅ ItemModel created successfully');
          
          // Save to Isar (update if exists, insert if new)
          await isar.writeTxn(() async {
            // Check if item already exists and preserve its local id
            if (existingItemsMap.containsKey(item.itemId)) {
              item.id = existingItemsMap[item.itemId]!;
              print('   ♻️  Updating existing item (local id: ${item.id})');
            } else {
              print('   ✨ Creating new item');
            }
            
            await isar.itemModels.put(item);
            print('   ✅ Item saved to Isar successfully');
            
            // Update the map so subsequent iterations can find this item
            existingItemsMap[item.itemId] = item.id;
          });
          
        } catch (e) {
          print('❌ Failed to save item from Supabase: $e');
          print('   Stack trace: ${StackTrace.current}');
        }
      }
      
      print('✅ Pull completed - saved ${allItems.length} items to local database');
      
      // Now pull blocks for all items
      await _pullBlocksFromSupabase();
      
    } catch (e) {
      if (e.toString().contains('PGRST205') || e.toString().contains('Could not find the table')) {
        print('⚠️  Table "items" does not exist in Supabase yet. Please create it using supabase_schema.sql');
      } else {
        print('❌ Pull error: $e');
      }
    }
  }

  // Pull blocks from Supabase
  Future<void> _pullBlocksFromSupabase() async {
    try {
      final supabase = Supabase.instance.client;
      
      if (supabase.auth.currentSession == null) {
        print('⚠️  Not authenticated, skipping blocks pull');
        return;
      }

      print('📥 Pulling blocks from Supabase...');

      // Get all items to know which blocks to fetch
      final isar = await _isarService.db;
      
      // Get all items using proper Isar API
      final itemCount = await isar.itemModels.count();
      final allItems = <ItemModel>[];
      for (int i = 0; i < itemCount; i++) {
        final item = await isar.itemModels.get(i + 1);
        if (item != null) {
          allItems.add(item);
        }
      }
      
      final itemIds = allItems.map((item) => item.itemId).toList();

      if (itemIds.isEmpty) {
        print('⚠️  No items found, skipping blocks pull');
        return;
      }

      // Fetch blocks for all items
      final blocks = await supabase
          .from('blocks')
          .select()
          .inFilter('item_id', itemIds);
      
      print('📥 Fetched ${blocks.length} blocks from Supabase');

      // Build a map of existing blocks by blockId for efficient lookup
      final existingBlocksMap = <String, int>{};
      final pendingBlockIds = <String>{}; // Track pending blocks
      final blockCount = await isar.blockModels.count();
      
      for (int i = 0; i < blockCount; i++) {
        final existing = await isar.blockModels.get(i + 1);
        if (existing != null) {
          existingBlocksMap[existing.blockId] = existing.id;
          // Track pending blocks - don't overwrite them
          if (existing.syncStatus == SyncStatus.pending) {
            pendingBlockIds.add(existing.blockId);
          }
        }
      }

      // Save blocks to local Isar
      for (final blockData in blocks) {
        try {
          final blockId = blockData['id'] as String;
          final itemId = blockData['item_id'] as String;
          final content = blockData['content'] as String? ?? '';
          
          // Skip if this block is pending locally (don't overwrite unsaved changes)
          if (pendingBlockIds.contains(blockId)) {
            print('⏭️  Skipping pending block: $blockId (has local changes)');
            continue;
          }
          
          print('💾 Saving block from Supabase: $blockId (itemId: $itemId, content: "${content.substring(0, content.length > 20 ? 20 : content.length)}")');
          
          final block = BlockModel(
            blockId: blockId,
            itemId: itemId,
            type: BlockType.values.firstWhere(
              (e) => e.name == blockData['type'],
              orElse: () => BlockType.text,
            ),
            content: content,
            isChecked: blockData['is_checked'] as bool? ?? false,
            orderIndex: blockData['order_index'] as int? ?? 0,
            updatedAtParam: DateTime.parse(blockData['updated_at'] as String),
            syncStatus: SyncStatus.synced,
          );

          await isar.writeTxn(() async {
            // Check if block already exists and preserve its local id
            if (existingBlocksMap.containsKey(block.blockId)) {
              block.id = existingBlocksMap[block.blockId]!;
              print('   ♻️  Updating existing block (local id: ${block.id})');
            } else {
              print('   ✨ Creating new block');
            }
            
            await isar.blockModels.put(block);
          });
          
          print('   ✅ Block saved successfully');
        } catch (e) {
          print('❌ Failed to save block from Supabase: $e');
        }
      }

      print('✅ Blocks pull completed - saved ${blocks.length} blocks');
      
    } catch (e) {
      print('❌ Blocks pull error: $e');
    }
  }

  // Push pending changes to Supabase
  Future<void> _pushToSupabase() async {
    try {
      final supabase = Supabase.instance.client;
      
      // Check if user is authenticated
      if (supabase.auth.currentSession == null) {
        print('⚠️  Not authenticated, skipping push');
        return;
      }

      // Get all pending items
      final pendingItems = await _itemRepository.getPendingItems();
      
      print('📊 Sync status: ${pendingItems.length} pending items found');
      
      if (pendingItems.isEmpty) {
        print('✅ No pending items to sync');
      } else {
        print('📤 Pushing ${pendingItems.length} pending items to Supabase...');
        print('📋 Items to sync: ${pendingItems.map((i) => i.title).join(", ")}');

        for (final item in pendingItems) {
          try {
            // Convert to JSON for Supabase
            final data = {
              'id': item.itemId,
              'parent_id': item.parentId,
              'type': item.type.name,
              'title': item.title,
              'content': item.content,
              'is_pinned': item.isPinned,
              'is_completed': item.isCompleted,
              'due_date': item.dueDate?.toIso8601String(),
              'reminder_at': item.reminderAt?.toIso8601String(),
              'created_by': item.createdBy ?? supabase.auth.currentUser?.id, // Preserve original creator
              'created_at': item.createdAt.toIso8601String(),
              'updated_at': item.updatedAt.toIso8601String(),
              'order_index': item.orderIndex,
              'category': item.category,
            };

            print('📤 Syncing: ${item.title} (itemId: ${item.itemId})');
            
            // Upsert to Supabase (will update if exists, insert if new)
            await supabase.from('items').upsert(data);
            
            print('✅ Synced to Supabase: ${item.title}');
            
            // Mark as synced in Isar
            await _itemRepository.markAsSynced(item.id);
            
          } catch (e) {
            print('❌ Failed to sync item ${item.title}: $e');
            // Keep as pending, will retry next sync
          }
        }
        
        print('✅ Successfully synced ${pendingItems.length} items');
      }

      // Now sync blocks
      await _pushBlocksToSupabase();

      print('✅ Push completed');
      
    } catch (e) {
      print('❌ Push error: $e');
      rethrow; // Re-throw to let caller know sync failed
    }
  }

  // Push pending blocks to Supabase
  Future<void> _pushBlocksToSupabase() async {
    try {
      final supabase = Supabase.instance.client;
      
      // Get all pending blocks
      final pendingBlocks = await _itemRepository.getPendingBlocks();
      
      if (pendingBlocks.isEmpty) {
        print('✅ No pending blocks to sync');
        return;
      }

      print('📤 Pushing ${pendingBlocks.length} pending blocks to Supabase...');

      for (final block in pendingBlocks) {
        try {
          print('📤 Syncing block:');
          print('   blockId: ${block.blockId}');
          print('   itemId: ${block.itemId}');
          print('   type: ${block.type.name}');
          print('   content: ${block.content}');
          print('   syncStatus: ${block.syncStatus.name}');
          
          // Convert to JSON for Supabase
          final now = DateTime.now();
          final data = {
            'id': block.blockId,
            'item_id': block.itemId,
            'type': block.type.name,
            'content': block.content,
            'is_checked': block.isChecked,
            'order_index': block.orderIndex,
            'created_at': block.updatedAt.toIso8601String(), // Use updatedAt as createdAt for first sync
            'updated_at': now.toIso8601String(), // Always use current time to trigger notifications
          };

          print('📤 Upserting to Supabase with updated_at: ${now.toIso8601String()}');
          await supabase.from('blocks').upsert(data);
          
          print('✅ Synced block to Supabase: ${block.type.name}');
          
          // Create edit notification for shared items
          await _createEditNotification(block.itemId);
          
          // Mark as synced in Isar
          await _itemRepository.markBlockAsSynced(block.id);
          
        } catch (e) {
          print('❌ Failed to sync block: $e');
          print('❌ Block details: blockId=${block.blockId}, itemId=${block.itemId}');
          // Keep as pending, will retry next sync
        }
      }

      print('✅ Blocks push completed');
      
    } catch (e) {
      print('❌ Blocks push error: $e');
    }
  }

  // Stop sync manager
  void stop() {
    _connectivitySubscription?.cancel();
    _stopRealtime();
    print('🛑 SyncManager stopped');
  }

  // Check if online
  bool get isOnline => _isOnline;

  // ==================== SHARING SYNC ====================

  /// Push item shares to Supabase
  Future<void> _pushSharingToSupabase() async {
    try {
      final supabase = Supabase.instance.client;
      
      if (supabase.auth.currentSession == null) {
        print('⚠️  Not authenticated, skipping sharing push');
        return;
      }

      final userId = supabase.auth.currentUser?.id;
      if (userId == null) return;

      // Get all pending item shares
      final isar = await _isarService.db;
      final shareCount = await isar.itemShareModels.count();
      final allShares = <ItemShareModel>[];
      
      for (int i = 0; i < shareCount; i++) {
        final share = await isar.itemShareModels.get(i + 1);
        if (share != null) {
          allShares.add(share);
        }
      }
      
      final pendingShares = allShares.where((s) => s.syncStatus == SyncStatus.pending).toList();
      
      if (pendingShares.isEmpty) {
        print('✅ No pending shares to sync');
      } else {
        print('📤 Pushing ${pendingShares.length} item shares to Supabase...');
        print('📋 Shares: ${pendingShares.map((s) => '${s.itemId} -> ${s.userId}').join(", ")}');

        for (final share in pendingShares) {
          try {
            final data = {
              'id': share.shareId,
              'item_id': share.itemId,
              'user_id': share.userId,
              'permission': share.permission.name,
              'shared_by': share.sharedBy ?? userId,
              'shared_at': share.sharedAt?.toIso8601String() ?? DateTime.now().toIso8601String(),
              'created_at': share.createdAt.toIso8601String(),
              'updated_at': share.updatedAt.toIso8601String(),
            };

            print('📤 Syncing share:');
            print('   shareId: ${share.shareId}');
            print('   item_id: ${share.itemId}');
            print('   user_id: ${share.userId}');
            print('   permission: ${share.permission.name}');
            print('   shared_by: ${share.sharedBy ?? userId}');
            
            await supabase.from('item_shares').upsert(data);
            
            print('✅ Synced share to Supabase successfully');
            
            // Mark as synced
            await isar.writeTxn(() async {
              share.syncStatus = SyncStatus.synced;
              await isar.itemShareModels.put(share);
            });
            
          } catch (e) {
            print('❌ Failed to sync share: $e');
          }
        }
        
        print('✅ Successfully synced ${pendingShares.length} shares');
      }

      // Get all pending space members
      final memberCount = await isar.spaceMemberModels.count();
      final allMembers = <SpaceMemberModel>[];
      
      for (int i = 0; i < memberCount; i++) {
        final member = await isar.spaceMemberModels.get(i + 1);
        if (member != null) {
          allMembers.add(member);
        }
      }
      
      final pendingMembers = allMembers.where((m) => m.syncStatus == SyncStatus.pending).toList();
      
      if (pendingMembers.isEmpty) {
        print('✅ No pending space members to sync');
      } else {
        print('📤 Pushing ${pendingMembers.length} space members to Supabase...');

        for (final member in pendingMembers) {
          try {
            final data = {
              'id': member.memberId,
              'space_id': member.spaceId,
              'user_id': member.userId,
              'role': member.role.name,
              'invited_by': member.invitedBy ?? userId,
              'invited_at': member.invitedAt?.toIso8601String() ?? DateTime.now().toIso8601String(),
              'accepted_at': member.acceptedAt?.toIso8601String(),
              'created_at': member.createdAt.toIso8601String(),
              'updated_at': member.updatedAt.toIso8601String(),
            };

            await supabase.from('space_members').upsert(data);
            
            print('✅ Synced space member to Supabase');
            
            // Mark as synced
            await isar.writeTxn(() async {
              member.syncStatus = SyncStatus.synced;
              await isar.spaceMemberModels.put(member);
            });
            
          } catch (e) {
            print('❌ Failed to sync space member: $e');
          }
        }
      }

      print('✅ Sharing push completed');
      
    } catch (e) {
      print('❌ Sharing push error: $e');
    }
  }

  /// Pull item shares from Supabase
  Future<void> _pullSharingFromSupabase() async {
    try {
      final supabase = Supabase.instance.client;
      
      if (supabase.auth.currentSession == null) {
        print('⚠️  Not authenticated, skipping sharing pull');
        return;
      }

      final userId = supabase.auth.currentUser?.id;
      if (userId == null) return;

      print('📥 Pulling sharing data from Supabase...');

      // Fetch item shares for this user (by UUID only)
      final shares = await supabase
          .from('item_shares')
          .select()
          .eq('user_id', userId);
      
      print('📥 Fetched ${shares.length} item shares');

      // Build a map of existing shares by shareId for efficient lookup
      final isar = await _isarService.db;
      final existingSharesMap = <String, int>{};
      
      // Get count and iterate to build map
      final shareCount = await isar.itemShareModels.count();
      for (int i = 0; i < shareCount; i++) {
        final existing = await isar.itemShareModels.get(i + 1);
        if (existing != null) {
          existingSharesMap[existing.shareId] = existing.id;
        }
      }

      // Save to local Isar
      for (final shareData in shares) {
        try {
          final share = ItemShareModel(
            shareId: shareData['id'] as String,
            itemId: shareData['item_id'] as String,
            userId: shareData['user_id'] as String,
            permission: SharePermission.values.firstWhere(
              (e) => e.name == shareData['permission'],
              orElse: () => SharePermission.view,
            ),
            sharedBy: shareData['shared_by'] as String?,
            sharedAt: shareData['shared_at'] != null
                ? DateTime.parse(shareData['shared_at'] as String)
                : null,
            createdAtParam: DateTime.parse(shareData['created_at'] as String),
            updatedAtParam: DateTime.parse(shareData['updated_at'] as String),
            syncStatus: SyncStatus.synced,
          );

          await isar.writeTxn(() async {
            // Check if share already exists and preserve its local id
            if (existingSharesMap.containsKey(share.shareId)) {
              share.id = existingSharesMap[share.shareId]!;
            }
            
            await isar.itemShareModels.put(share);
          });
        } catch (e) {
          print('❌ Failed to save share: $e');
        }
      }

      // Fetch space members for this user
      final members = await supabase
          .from('space_members')
          .select()
          .eq('user_id', userId);
      
      print('📥 Fetched ${members.length} space memberships');

      // Build a map of existing members by memberId for efficient lookup
      final existingMembersMap = <String, int>{};
      
      // Get count and iterate to build map
      final memberCount = await isar.spaceMemberModels.count();
      for (int i = 0; i < memberCount; i++) {
        final existing = await isar.spaceMemberModels.get(i + 1);
        if (existing != null) {
          existingMembersMap[existing.memberId] = existing.id;
        }
      }

      for (final memberData in members) {
        try {
          final member = SpaceMemberModel(
            memberId: memberData['id'] as String,
            spaceId: memberData['space_id'] as String,
            userId: memberData['user_id'] as String,
            role: MemberRole.values.firstWhere(
              (e) => e.name == memberData['role'],
              orElse: () => MemberRole.viewer,
            ),
            invitedBy: memberData['invited_by'] as String?,
            invitedAt: memberData['invited_at'] != null
                ? DateTime.parse(memberData['invited_at'] as String)
                : null,
            acceptedAt: memberData['accepted_at'] != null
                ? DateTime.parse(memberData['accepted_at'] as String)
                : null,
            createdAtParam: DateTime.parse(memberData['created_at'] as String),
            updatedAtParam: DateTime.parse(memberData['updated_at'] as String),
            syncStatus: SyncStatus.synced,
          );

          await isar.writeTxn(() async {
            // Check if member already exists and preserve its local id
            if (existingMembersMap.containsKey(member.memberId)) {
              member.id = existingMembersMap[member.memberId]!;
            }
            
            await isar.spaceMemberModels.put(member);
          });
        } catch (e) {
          print('❌ Failed to save space member: $e');
        }
      }

      print('✅ Sharing pull completed');
      
      // Pull notifications
      await _pullNotificationsFromSupabase();
      
    } catch (e) {
      print('❌ Sharing pull error: $e');
    }
  }

  // ==================== NOTIFICATIONS SYNC ====================

  /// Pull notifications from Supabase
  Future<void> _pullNotificationsFromSupabase() async {
    try {
      final supabase = Supabase.instance.client;
      
      if (supabase.auth.currentSession == null) {
        print('⚠️  Not authenticated, skipping notifications pull');
        return;
      }

      final userId = supabase.auth.currentUser?.id;
      if (userId == null) return;

      print('📥 Pulling notifications from Supabase...');

      // Fetch notifications for this user (last 100, ordered by newest first)
      final notifications = await supabase
          .from('notifications')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .limit(100);
      
      print('📥 Fetched ${notifications.length} notifications');

      // Build a map of existing notifications by notificationId
      final isar = await _isarService.db;
      final existingNotificationsMap = <String, int>{};
      
      final notificationCount = await isar.notificationModels.count();
      for (int i = 0; i < notificationCount; i++) {
        final existing = await isar.notificationModels.get(i + 1);
        if (existing != null) {
          existingNotificationsMap[existing.notificationId] = existing.id;
        }
      }

      // Save to local Isar
      for (final notificationData in notifications) {
        try {
          final notification = NotificationModel(
            notificationId: notificationData['id'] as String,
            userId: notificationData['user_id'] as String,
            type: NotificationType.values.firstWhere(
              (e) => e.name == notificationData['type'],
              orElse: () => NotificationType.share,
            ),
            title: notificationData['title'] as String,
            message: notificationData['message'] as String,
            itemId: notificationData['item_id'] as String?,
            relatedUserId: notificationData['related_user_id'] as String?,
            isRead: notificationData['is_read'] as bool? ?? false,
            createdAtParam: DateTime.parse(notificationData['created_at'] as String),
            updatedAtParam: DateTime.parse(notificationData['updated_at'] as String),
            syncStatus: SyncStatus.synced,
          );

          await isar.writeTxn(() async {
            // Check if notification already exists and preserve its local id
            if (existingNotificationsMap.containsKey(notification.notificationId)) {
              notification.id = existingNotificationsMap[notification.notificationId]!;
            }
            
            await isar.notificationModels.put(notification);
          });
        } catch (e) {
          print('❌ Failed to save notification: $e');
        }
      }

      print('✅ Notifications pull completed - saved ${notifications.length} notifications');
      
    } catch (e) {
      print('❌ Notifications pull error: $e');
    }
  }

  /// Mark notification as read (updates locally and syncs to Supabase)
  Future<void> markNotificationAsRead(int notificationId) async {
    try {
      final isar = await _isarService.db;
      final notification = await isar.notificationModels.get(notificationId);
      
      if (notification == null) return;

      // Update locally
      await isar.writeTxn(() async {
        notification.isRead = true;
        notification.updatedAt = DateTime.now();
        await isar.notificationModels.put(notification);
      });

      // Update in Supabase
      final supabase = Supabase.instance.client;
      await supabase
          .from('notifications')
          .update({'is_read': true, 'updated_at': DateTime.now().toIso8601String()})
          .eq('id', notification.notificationId);

      print('✅ Marked notification as read');
    } catch (e) {
      print('❌ Failed to mark notification as read: $e');
    }
  }

  /// Get unread notification count
  Future<int> getUnreadNotificationCount() async {
    try {
      final isar = await _isarService.db;
      final notificationCount = await isar.notificationModels.count();
      int unreadCount = 0;
      
      for (int i = 0; i < notificationCount; i++) {
        final notification = await isar.notificationModels.get(i + 1);
        if (notification != null && !notification.isRead) {
          unreadCount++;
        }
      }
      
      return unreadCount;
    } catch (e) {
      print('❌ Failed to get unread count: $e');
      return 0;
    }
  }

  /// Create edit notification for shared items
  Future<void> _createEditNotification(String itemId) async {
    try {
      final supabase = Supabase.instance.client;
      final currentUserId = supabase.auth.currentUser?.id;
      
      if (currentUserId == null) {
        print('⚠️  No current user, skipping notification');
        return;
      }

      // Get the current user's display name
      String editorName = 'Someone';
      try {
        final profileResponse = await supabase
            .from('profiles')
            .select('display_name')
            .eq('id', currentUserId)
            .single();
        
        editorName = profileResponse['display_name'] as String? ?? 'Someone';
        
        print('👤 Editor name resolved: "$editorName" (from profile display_name)');
      } catch (e) {
        print('⚠️  Could not fetch editor name: $e');
        // Fallback: try to get email from auth user
        try {
          final email = supabase.auth.currentUser?.email;
          if (email != null) {
            editorName = email.split('@')[0];
            print('👤 Using email username as fallback: "$editorName"');
          }
        } catch (e2) {
          print('⚠️  Could not get email either: $e2');
        }
      }

      // Get the item details
      final itemResponse = await supabase
          .from('items')
          .select('id, title, created_by')
          .eq('id', itemId)
          .single();

      final itemTitle = itemResponse['title'] as String? ?? 'Untitled';
      final itemOwnerId = itemResponse['created_by'] as String?;

      // Get all users who have access to this item (except current user)
      final sharesResponse = await supabase
          .from('item_shares')
          .select('user_id')
          .eq('item_id', itemId)
          .neq('user_id', currentUserId);

      final shares = sharesResponse as List<dynamic>;
      
      // Create notifications for all shared users
      for (final share in shares) {
        final userId = share['user_id'] as String;
        
        final notificationMessage = '$editorName updated "$itemTitle"';
        print('📬 Creating notification for user $userId: "$notificationMessage"');
        
        try {
          await supabase.from('notifications').insert({
            'user_id': userId,
            'type': 'update',
            'title': 'Item updated',
            'message': notificationMessage,
            'item_id': itemId,
            'related_user_id': currentUserId,
            'is_read': false,
            'created_at': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          });
          
          print('✅ Created edit notification for user: $userId');
        } catch (e) {
          print('⚠️  Failed to create notification for user $userId: $e');
        }
      }

      // Also notify the owner if they're not the editor
      if (itemOwnerId != null && itemOwnerId != currentUserId) {
        final notificationMessage = '$editorName updated "$itemTitle"';
        print('📬 Creating notification for owner $itemOwnerId: "$notificationMessage"');
        
        try {
          await supabase.from('notifications').insert({
            'user_id': itemOwnerId,
            'type': 'update',
            'title': 'Item updated',
            'message': notificationMessage,
            'item_id': itemId,
            'related_user_id': currentUserId,
            'is_read': false,
            'created_at': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          });
          
          print('✅ Created edit notification for owner: $itemOwnerId');
        } catch (e) {
          print('⚠️  Failed to create notification for owner: $e');
        }
      }

      if (shares.isEmpty && (itemOwnerId == null || itemOwnerId == currentUserId)) {
        print('ℹ️  No one to notify (item not shared)');
      }
      
    } catch (e) {
      print('⚠️  Failed to create edit notification: $e');
      // Don't throw - notifications are not critical
    }
  }
}

