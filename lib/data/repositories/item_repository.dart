import 'package:flutter/foundation.dart';
import 'package:isar/isar.dart';
import 'package:uuid/uuid.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:openlist/data/local/isar_service.dart';
import 'package:openlist/data/models/item_model.dart';
import 'package:openlist/data/models/block_model.dart';
import 'package:openlist/core/models/sync_status.dart';
import 'package:openlist/data/sync/sync_manager.dart';

class ItemRepository {
  final IsarService _isarService = IsarService.instance;
  final _uuid = const Uuid();
  
  // Cache for share status to avoid repeated Supabase queries
  final Map<String, bool> _shareStatusCache = {};
  DateTime? _cacheTimestamp;
  static const _cacheDuration = Duration(minutes: 5);

  // ============ LOCAL-FIRST WRITES ============
  // Always write to Isar first, mark as pending for sync

  Future<ItemModel> createItem({
    required String title,
    ItemType type = ItemType.task,
    String? content,
    String? category,
    DateTime? dueDate,
    DateTime? reminderAt,
    String? parentId,
  }) async {
    try {
      final isar = await _isarService.db;
      final currentUserId = Supabase.instance.client.auth.currentUser?.id;
      
      final item = ItemModel(
        itemId: _uuid.v4(),
        parentId: parentId,
        title: title,
        type: type,
        content: content,
        category: category,
        dueDate: dueDate,
        reminderAt: reminderAt,
        createdBy: currentUserId,
        syncStatus: SyncStatus.pending,
        createdAtParam: DateTime.now(),
        updatedAtParam: DateTime.now(),
      );

      await isar.writeTxn(() async {
        await isar.itemModels.put(item);
      });
      
      // Trigger sync in background
      SyncManager.instance.triggerSync();
      
      return item;
    } catch (e, stackTrace) {
      debugPrint('Error creating item: $e');
      debugPrint('Stack trace: $stackTrace');
      rethrow;
    }
  }

  // Create a sub-task (child task)
  Future<ItemModel> createSubTask({
    required String parentItemId,
    required String title,
  }) async {
    try {
      final isar = await _isarService.db;
      
      // Get parent to inherit creator
      final parent = await isar.itemModels
          .filter()
          .itemIdEqualTo(parentItemId)
          .findFirst();
      
      if (parent == null) {
        throw Exception('Parent task not found');
      }
      
      final currentUserId = Supabase.instance.client.auth.currentUser?.id;
      
      final subTask = ItemModel(
        itemId: _uuid.v4(),
        parentId: parentItemId,
        title: title,
        type: ItemType.task,
        createdBy: parent.createdBy ?? currentUserId,
        syncStatus: SyncStatus.pending,
        createdAtParam: DateTime.now(),
        updatedAtParam: DateTime.now(),
      );

      await isar.writeTxn(() async {
        await isar.itemModels.put(subTask);
      });
      
      SyncManager.instance.triggerSync();
      
      return subTask;
    } catch (e, stackTrace) {
      debugPrint('Error creating sub-task: $e');
      debugPrint('Stack trace: $stackTrace');
      rethrow;
    }
  }

  // Get all sub-tasks for a parent task
  Future<List<ItemModel>> getSubTasks(String parentItemId) async {
    final isar = await _isarService.db;
    return await isar.itemModels
        .filter()
        .parentIdEqualTo(parentItemId)
        .sortByOrderIndex()
        .findAll();
  }

  // Watch sub-tasks for real-time updates
  Stream<List<ItemModel>> watchSubTasks(String parentItemId) async* {
    final isar = await _isarService.db;
    yield* isar.itemModels
        .filter()
        .parentIdEqualTo(parentItemId)
        .sortByOrderIndex()
        .watch(fireImmediately: true);
  }

  // Get parent task
  Future<ItemModel?> getParentTask(String childItemId) async {
    final isar = await _isarService.db;
    
    // Get child first
    final child = await isar.itemModels
        .filter()
        .itemIdEqualTo(childItemId)
        .findFirst();
    
    if (child == null || child.parentId == null) {
      return null;
    }
    
    // Get parent
    return await isar.itemModels
        .filter()
        .itemIdEqualTo(child.parentId!)
        .findFirst();
  }

  // Check if all sub-tasks are completed and auto-complete parent
  Future<void> checkAndCompleteParent(String parentItemId) async {
    final isar = await _isarService.db;
    
    // Get all sub-tasks
    final subTasks = await getSubTasks(parentItemId);
    
    if (subTasks.isEmpty) return;
    
    // Check if all are completed
    final allCompleted = subTasks.every((task) => task.isCompleted);
    
    if (allCompleted) {
      // Get parent and mark as completed
      final parent = await isar.itemModels
          .filter()
          .itemIdEqualTo(parentItemId)
          .findFirst();
      
      if (parent != null && !parent.isCompleted) {
        parent.isCompleted = true;
        parent.updatedAt = DateTime.now();
        parent.syncStatus = SyncStatus.pending;
        
        await isar.writeTxn(() async {
          await isar.itemModels.put(parent);
        });
        
        SyncManager.instance.triggerSync();
      }
    }
  }

  Future<void> updateItem(ItemModel item) async {
    try {
      final isar = await _isarService.db;
      
      // Update timestamps and sync status
      item.updatedAt = DateTime.now();
      item.syncStatus = SyncStatus.pending;

      await isar.writeTxn(() async {
        await isar.itemModels.put(item);
      });
      
      SyncManager.instance.triggerSync();
    } catch (e, stackTrace) {
      debugPrint('Error updating item: $e');
      debugPrint('Stack trace: $stackTrace');
      rethrow;
    }
  }

  Future<void> toggleComplete(int id) async {
    final isar = await _isarService.db;
    
    final item = await isar.itemModels.get(id);
    if (item == null) return;

    item.isCompleted = !item.isCompleted;
    item.updatedAt = DateTime.now();
    item.syncStatus = SyncStatus.pending;

    await isar.writeTxn(() async {
      await isar.itemModels.put(item);
    });

    SyncManager.instance.triggerSync();
  }

  Future<void> deleteItem(int id) async {
    final isar = await _isarService.db;
    
    // Get the item first to get its itemId for Supabase deletion
    final item = await isar.itemModels.get(id);
    if (item == null) return;
    
    final itemId = item.itemId;
    final itemTitle = item.title;
    final itemCreatedBy = item.createdBy;
    
    print('🗑️  ========== DELETE ITEM START ==========');
    print('🗑️  Item: "$itemTitle" (id: $itemId)');
    print('🗑️  Created by: $itemCreatedBy');
    
    // Delete from Isar (local) first for instant UI update
    await isar.writeTxn(() async {
      // Delete all blocks associated with this item
      final blocks = await isar.blockModels
          .filter()
          .itemIdEqualTo(itemId)
          .findAll();
      
      for (final block in blocks) {
        await isar.blockModels.delete(block.id);
      }
      
      // Delete the item
      await isar.itemModels.delete(id);
    });
    
    print('✅ Item deleted from local Isar');
    
    // Delete from Supabase AND create notifications
    try {
      final supabase = Supabase.instance.client;
      final currentUserId = supabase.auth.currentUser?.id;
      
      if (currentUserId == null) {
        print('⚠️  No current user, skipping Supabase deletion and notifications');
        return;
      }
      
      print('👤 Current user: $currentUserId');
      
      // Get user's display name for notification
      String deleterName = 'Someone';
      try {
        final profileResponse = await supabase
            .from('profiles')
            .select('display_name')
            .eq('id', currentUserId)
            .maybeSingle();
        
        if (profileResponse != null && profileResponse['display_name'] != null && profileResponse['display_name'].toString().isNotEmpty) {
          deleterName = profileResponse['display_name'];
          print('👤 Deleter name from profile: "$deleterName"');
        } else {
          // Fallback to email
          final email = supabase.auth.currentUser?.email;
          if (email != null && email.contains('@')) {
            deleterName = email.split('@')[0];
            print('👤 Deleter name from email: "$deleterName"');
          }
        }
      } catch (e) {
        print('⚠️  Could not get deleter name: $e');
      }
      
      // CRITICAL: Get all users who have access BEFORE deleting anything
      print('🔍 Fetching shared users...');
      final sharesResponse = await supabase
          .from('item_shares')
          .select('user_id')
          .eq('item_id', itemId);
      
      final allSharedUserIds = (sharesResponse as List)
          .map((share) => share['user_id'] as String)
          .toList();
      
      print('📋 Found ${allSharedUserIds.length} total shares: $allSharedUserIds');
      
      // Filter out current user
      final sharedUserIds = allSharedUserIds.where((uid) => uid != currentUserId).toList();
      
      print('📧 Will notify ${sharedUserIds.length} users (excluding current user)');
      
      // Also notify owner if they didn't delete it
      final shouldNotifyOwner = itemCreatedBy != null && 
                                 itemCreatedBy != currentUserId && 
                                 !sharedUserIds.contains(itemCreatedBy);
      
      if (shouldNotifyOwner) {
        print('📧 Will also notify owner: $itemCreatedBy');
      }
      
      // Create notifications BEFORE deleting (in case deletion fails)
      final notificationsToCreate = <String>[];
      notificationsToCreate.addAll(sharedUserIds);
      if (shouldNotifyOwner) {
        notificationsToCreate.add(itemCreatedBy!);
      }
      
      print('📧 Creating delete notifications for ${notificationsToCreate.length} users...');
      
      for (final userId in notificationsToCreate) {
        try {
          print('   📬 Creating notification for: $userId');
          await supabase.from('notifications').insert({
            'user_id': userId,
            'type': 'delete', // Using 'delete' type for delete notifications
            'title': 'Item deleted',
            'message': '$deleterName deleted "$itemTitle"',
            'item_id': itemId,
            'related_user_id': currentUserId,
            'is_read': false,
            'created_at': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          });
          print('   ✅ Notification created successfully');
        } catch (e) {
          print('   ❌ Failed to create notification: $e');
        }
      }
      
      print('✅ All notifications created');
      
      // Now delete from Supabase in correct order
      print('🗑️  Deleting from Supabase...');
      
      // 1. Delete blocks first (foreign key constraint)
      try {
        await supabase
            .from('blocks')
            .delete()
            .eq('item_id', itemId);
        print('   ✅ Blocks deleted');
      } catch (e) {
        print('   ⚠️  Block deletion error (may not exist): $e');
      }
      
      // 2. Delete item_shares
      try {
        await supabase
            .from('item_shares')
            .delete()
            .eq('item_id', itemId);
        print('   ✅ Item shares deleted');
      } catch (e) {
        print('   ⚠️  Share deletion error (may not exist): $e');
      }
      
      // 3. Finally delete the item itself
      try {
        await supabase
            .from('items')
            .delete()
            .eq('id', itemId);
        print('   ✅ Item deleted');
      } catch (e) {
        print('   ❌ Item deletion error: $e');
        throw e; // Re-throw item deletion errors
      }
      
      print('✅ All Supabase deletions completed');
      
    } catch (e) {
      print('❌ Supabase deletion error: $e');
      print('   Note: Item already deleted locally, so UI is updated');
      // Item is already deleted locally, so we continue
    }
    
    print('🗑️  ========== DELETE ITEM END ==========');
    
    SyncManager.instance.triggerSync();
  }

  // ============ LOCAL READS (INSTANT) ============
  // UI always reads from Isar, never waits for network

  Stream<List<ItemModel>> watchAllItems() async* {
    final isar = await _isarService.db;
    yield* isar.itemModels
        .where()
        .sortByCreatedAtDesc()
        .watch(fireImmediately: true);
  }

  Stream<List<ItemModel>> watchTodayItems() async* {
    final isar = await _isarService.db;
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59);

    yield* isar.itemModels
        .filter()
        .dueDateBetween(startOfDay, endOfDay)
        .sortByDueDate()
        .watch(fireImmediately: true);
  }

  Stream<List<ItemModel>> watchPinnedItems() async* {
    final isar = await _isarService.db;
    yield* isar.itemModels
        .filter()
        .isPinnedEqualTo(true)
        .sortByOrderIndex()
        .watch(fireImmediately: true);
  }

  Stream<List<ItemModel>> watchByType(ItemType type) async* {
    final isar = await _isarService.db;
    yield* isar.itemModels
        .filter()
        .typeEqualTo(type)
        .sortByCreatedAtDesc()
        .watch(fireImmediately: true);
  }

  // Watch Personal items (items created by current user and NOT shared)
  Stream<List<ItemModel>> watchPersonalItems() async* {
    final isar = await _isarService.db;
    final currentUserId = Supabase.instance.client.auth.currentUser?.id;
    
    if (currentUserId == null) {
      yield [];
      return;
    }
    
    print('🔍 watchPersonalItems: currentUserId = $currentUserId');
    
    // Get all items created by current user
    yield* isar.itemModels
        .filter()
        .createdByEqualTo(currentUserId)
        .sortByCreatedAtDesc()
        .watch(fireImmediately: true)
        .asyncMap((items) async {
          print('🔍 watchPersonalItems: Got ${items.length} items created by user');
          
          final personalItems = <ItemModel>[];
          
          for (final item in items) {
            // Check if this item is shared
            final isShared = await isItemShared(item.itemId);
            print('   📄 "${item.title}" - isShared: $isShared');
            if (!isShared) {
              personalItems.add(item);
            }
          }
          
          print('✅ watchPersonalItems: Returning ${personalItems.length} personal items');
          return personalItems;
        });
  }

  // Watch Shared items (items shared with current user OR items current user shared)
  Stream<List<ItemModel>> watchSharedItems() async* {
    final isar = await _isarService.db;
    final currentUserId = Supabase.instance.client.auth.currentUser?.id;
    
    if (currentUserId == null) {
      yield [];
      return;
    }
    
    print('🔍 watchSharedItems: currentUserId = $currentUserId');
    
    // Watch all items
    yield* isar.itemModels
        .where()
        .sortByCreatedAtDesc()
        .watch(fireImmediately: true)
        .asyncMap((items) async {
          print('🔍 watchSharedItems: Got ${items.length} total items');
          
          final sharedItems = <ItemModel>[];
          
          for (final item in items) {
            // Check if this item is shared
            final isShared = await isItemShared(item.itemId);
            print('   📄 "${item.title}" - isShared: $isShared');
            if (isShared) {
              sharedItems.add(item);
            }
          }
          
          print('✅ watchSharedItems: Returning ${sharedItems.length} shared items');
          return sharedItems;
        });
  }

  // Helper to check if an item is shared (public for UI filtering)
  // Uses cache to avoid repeated Supabase queries
  Future<bool> isItemShared(String itemId) async {
    // Check if cache is still valid
    final now = DateTime.now();
    if (_cacheTimestamp != null && 
        now.difference(_cacheTimestamp!) < _cacheDuration &&
        _shareStatusCache.containsKey(itemId)) {
      return _shareStatusCache[itemId]!;
    }
    
    try {
      final supabase = Supabase.instance.client;
      
      // Check if there are any shares for this item
      final response = await supabase
          .from('item_shares')
          .select('id')
          .eq('item_id', itemId)
          .limit(1);
      
      final isShared = (response as List).isNotEmpty;
      
      // Cache the result
      _shareStatusCache[itemId] = isShared;
      _cacheTimestamp = now;
      
      return isShared;
    } catch (e) {
      print('   ❌ Error checking if item is shared: $e');
      // If offline or error, check cache first, then assume not shared
      return _shareStatusCache[itemId] ?? false;
    }
  }
  
  // Clear the share status cache (call after sharing/unsharing)
  void clearShareCache() {
    _shareStatusCache.clear();
    _cacheTimestamp = null;
    print('🧹 Share status cache cleared');
  }
  
  // Refresh share status for all items (call once when filter is selected)
  Future<void> refreshShareStatus() async {
    try {
      final supabase = Supabase.instance.client;
      final currentUserId = supabase.auth.currentUser?.id;
      
      if (currentUserId == null) return;
      
      print('🔄 Refreshing share status cache...');
      
      // Get all item_shares in one query
      final response = await supabase
          .from('item_shares')
          .select('item_id');
      
      final sharedItemIds = (response as List)
          .map((share) => share['item_id'] as String)
          .toSet();
      
      print('   Found ${sharedItemIds.length} shared items');
      
      // Get all items from Isar
      final isar = await _isarService.db;
      final allItems = await isar.itemModels.where().findAll();
      
      // Update cache for all items
      _shareStatusCache.clear();
      for (final item in allItems) {
        _shareStatusCache[item.itemId] = sharedItemIds.contains(item.itemId);
      }
      
      _cacheTimestamp = DateTime.now();
      print('✅ Share status cache refreshed (${_shareStatusCache.length} items)');
    } catch (e) {
      print('❌ Error refreshing share status: $e');
    }
  }

  Future<ItemModel?> getItemById(int id) async {
    final isar = await _isarService.db;
    return await isar.itemModels.get(id);
  }

  Future<ItemModel?> getItemByItemId(String itemId) async {
    final isar = await _isarService.db;
    return await isar.itemModels
        .filter()
        .itemIdEqualTo(itemId)
        .findFirst();
  }

  Stream<List<ItemModel>> watchUpcomingItems() async* {
    final isar = await _isarService.db;
    final now = DateTime.now();
    final startOfTomorrow = DateTime(now.year, now.month, now.day).add(const Duration(days: 1));

    yield* isar.itemModels
        .filter()
        .dueDateIsNotNull()
        .and()
        .dueDateGreaterThan(startOfTomorrow.subtract(const Duration(seconds: 1)))
        .sortByDueDate()
        .watch(fireImmediately: true);
  }

  // ============ SEARCH ============
  
  Future<List<ItemModel>> searchItems(String query) async {
    final isar = await _isarService.db;
    
    if (query.trim().isEmpty) {
      return [];
    }
    
    final lowerQuery = query.toLowerCase();
    
    // Get all items and blocks
    final allItems = await isar.itemModels.where().findAll();
    final allBlocks = await isar.blockModels.where().findAll();
    
    // Create a map of itemId to blocks for quick lookup
    final blocksByItemId = <String, List<BlockModel>>{};
    for (final block in allBlocks) {
      if (!blocksByItemId.containsKey(block.itemId)) {
        blocksByItemId[block.itemId] = [];
      }
      blocksByItemId[block.itemId]!.add(block);
    }
    
    // Search in titles and block content
    final results = allItems.where((item) {
      // Check title
      if (item.title.toLowerCase().contains(lowerQuery)) {
        return true;
      }
      
      // Check blocks content
      final itemBlocks = blocksByItemId[item.itemId] ?? [];
      for (final block in itemBlocks) {
        if (block.content.toLowerCase().contains(lowerQuery)) {
          return true;
        }
      }
      
      return false;
    }).toList();
    
    // Sort by: pinned first, then by updated date
    results.sort((a, b) {
      if (a.isPinned && !b.isPinned) return -1;
      if (!a.isPinned && b.isPinned) return 1;
      return b.updatedAt.compareTo(a.updatedAt);
    });
    
    return results;
  }

  // Get most recently created tasks (for linking from notes)
  Future<List<ItemModel>> getRecentTasks({int limit = 1}) async {
    final isar = await _isarService.db;
    
    final tasks = await isar.itemModels
        .filter()
        .typeEqualTo(ItemType.task)
        .sortByCreatedAtDesc()
        .limit(limit)
        .findAll();
    
    return tasks;
  }

  // ============ SYNC HELPERS ============
  // Used by SyncManager to sync with Supabase

  Future<List<ItemModel>> getPendingItems() async {
    final isar = await _isarService.db;
    
    // First, let's see ALL items in the database
    final allItems = await isar.itemModels.where().findAll();
    print('🔍 Total items in database: ${allItems.length}');
    
    for (final item in allItems) {
      print('   📄 ${item.title} - syncStatus: ${item.syncStatus.name} (${item.syncStatus.index})');
    }
    
    // Now filter for pending
    final pending = await isar.itemModels
        .filter()
        .syncStatusEqualTo(SyncStatus.pending)
        .findAll();
    
    print('🔍 getPendingItems: Found ${pending.length} pending items');
    for (final item in pending) {
      print('   ⏳ ${item.title} (syncStatus: ${item.syncStatus.name})');
    }
    
    return pending;
  }

  Future<void> markAsSynced(int id) async {
    final isar = await _isarService.db;
    
    final item = await isar.itemModels.get(id);
    if (item == null) return;

    item.syncStatus = SyncStatus.synced;

    await isar.writeTxn(() async {
      await isar.itemModels.put(item);
    });
  }

  Future<List<BlockModel>> getPendingBlocks() async {
    final isar = await _isarService.db;
    return await isar.blockModels
        .filter()
        .syncStatusEqualTo(SyncStatus.pending)
        .findAll();
  }

  Future<void> markBlockAsSynced(int id) async {
    final isar = await _isarService.db;
    
    final block = await isar.blockModels.get(id);
    if (block == null) return;

    block.syncStatus = SyncStatus.synced;

    await isar.writeTxn(() async {
      await isar.blockModels.put(block);
    });
  }

  // ============ BLOCKS (for task detail content) ============

  Future<BlockModel> createBlock({
    required String itemId,
    required BlockType type,
    required String content,
    int? orderIndex,
  }) async {
    final isar = await _isarService.db;
    
    final block = BlockModel(
      blockId: _uuid.v4(),
      itemId: itemId,
      type: type,
      content: content,
      orderIndex: orderIndex ?? 0,
      syncStatus: SyncStatus.pending,
    );

    await isar.writeTxn(() async {
      await isar.blockModels.put(block);
    });

    return block;
  }

  Stream<List<BlockModel>> watchBlocks(String itemId) async* {
    print('🔍 watchBlocks called for itemId: $itemId');
    final isar = await _isarService.db;
    
    // First check what blocks exist for this item
    final existingBlocks = await isar.blockModels
        .filter()
        .itemIdEqualTo(itemId)
        .findAll();
    print('🔍 Found ${existingBlocks.length} existing blocks for this item');
    
    yield* isar.blockModels
        .filter()
        .itemIdEqualTo(itemId)
        .sortByOrderIndex()
        .watch(fireImmediately: true);
  }

  // Get all blocks for an item (non-stream version)
  Future<List<BlockModel>> getBlocks(String itemId) async {
    final isar = await _isarService.db;
    return await isar.blockModels
        .filter()
        .itemIdEqualTo(itemId)
        .findAll();
  }

  Future<void> updateBlock(BlockModel block) async {
    final isar = await _isarService.db;
    
    print('🔵 ========== UPDATE BLOCK START ==========');
    print('🔵 Block content: ${block.content}');
    print('🔵 Block id (Isar): ${block.id}');
    print('🔵 Block blockId (UUID): ${block.blockId}');
    print('🔵 Block itemId: ${block.itemId}');
    print('🔵 Current syncStatus BEFORE update: ${block.syncStatus.name}');
    
    block.updatedAt = DateTime.now();
    block.syncStatus = SyncStatus.pending;
    
    print('🔵 New syncStatus AFTER setting: ${block.syncStatus.name}');

    await isar.writeTxn(() async {
      await isar.blockModels.put(block);
      print('🔵 Block put() completed');
    });

    print('✅ Block updated in Isar');
    print('🔵 Triggering sync...');
    SyncManager.instance.triggerSync();
    print('🔵 ========== UPDATE BLOCK END ==========');
  }

  Future<void> deleteBlock(int id) async {
    final isar = await _isarService.db;
    
    // Get the block first to get its blockId for Supabase deletion
    final block = await isar.blockModels.get(id);
    if (block == null) {
      print('⚠️  Block not found in Isar');
      return;
    }
    
    final blockId = block.blockId;
    
    // Delete from Isar (local)
    await isar.writeTxn(() async {
      await isar.blockModels.delete(id);
    });

    print('✅ Block deleted from Isar');
    
    // Delete from Supabase
    try {
      final supabase = Supabase.instance.client;
      
      await supabase
          .from('blocks')
          .delete()
          .eq('id', blockId);
      
      print('✅ Block deleted from Supabase');
    } catch (e) {
      print('❌ Failed to delete block from Supabase: $e');
      // Block is already deleted locally, so we continue
    }
    
    SyncManager.instance.triggerSync();
  }
}
