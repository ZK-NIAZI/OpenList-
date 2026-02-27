import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:isar/isar.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:openlist/data/local/isar_service.dart';
import 'package:openlist/data/models/item_model.dart';
import 'package:openlist/data/models/block_model.dart';
import 'package:openlist/data/models/notification_model.dart';
import 'package:openlist/core/models/sync_status.dart';

class RealtimeService {
  static final RealtimeService instance = RealtimeService._();
  RealtimeService._();

  final IsarService _isarService = IsarService.instance;
  RealtimeChannel? _itemsChannel;
  RealtimeChannel? _blocksChannel;
  RealtimeChannel? _notificationsChannel;
  
  bool _isSubscribed = false;

  // Callbacks for UI updates
  Function(NotificationModel)? onNewNotification;
  Function()? onDataChanged;

  /// Start listening to real-time updates
  Future<void> start() async {
    if (_isSubscribed) {
      print('⚡ Realtime already subscribed');
      return;
    }

    final supabase = Supabase.instance.client;
    final userId = supabase.auth.currentUser?.id;

    if (userId == null) {
      print('⚠️  No user ID, cannot start realtime');
      return;
    }

    print('⚡ Starting Realtime subscriptions for user: $userId');

    try {
      // Subscribe to items table changes
      await _subscribeToItems(userId);
      
      // Subscribe to blocks table changes
      await _subscribeToBlocks(userId);
      
      // Subscribe to notifications
      await _subscribeToNotifications(userId);

      _isSubscribed = true;
      print('✅ Realtime subscriptions active');
    } catch (e) {
      print('❌ Failed to start realtime: $e');
    }
  }

  /// Subscribe to items table for owned and shared items
  Future<void> _subscribeToItems(String userId) async {
    final supabase = Supabase.instance.client;

    _itemsChannel = supabase
        .channel('items_changes')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'items',
          callback: (payload) async {
            print('⚡ Items change detected: ${payload.eventType}');
            await _handleItemChange(payload, userId);
          },
        )
        .subscribe();

    print('✅ Subscribed to items table');
  }

  /// Subscribe to blocks table for real-time content updates
  Future<void> _subscribeToBlocks(String userId) async {
    final supabase = Supabase.instance.client;

    _blocksChannel = supabase
        .channel('blocks_changes')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'blocks',
          callback: (payload) async {
            print('⚡ Block change detected: ${payload.eventType}');
            await _handleBlockChange(payload, userId);
          },
        )
        .subscribe();

    print('✅ Subscribed to blocks table');
  }

  /// Subscribe to notifications table
  Future<void> _subscribeToNotifications(String userId) async {
    final supabase = Supabase.instance.client;

    _notificationsChannel = supabase
        .channel('notifications_$userId')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'notifications',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: userId,
          ),
          callback: (payload) async {
            print('⚡ New notification received');
            await _handleNotificationChange(payload);
          },
        )
        .subscribe();

    print('✅ Subscribed to notifications table');
  }

  /// Handle item changes from realtime
  Future<void> _handleItemChange(PostgresChangePayload payload, String userId) async {
    try {
      final eventType = payload.eventType;
      final newData = payload.newRecord;
      final oldData = payload.oldRecord;

      print('📥 Item ${eventType.name}: ${newData['title'] ?? oldData['id']}');

      if (eventType == PostgresChangeEvent.delete) {
        // Handle deletion
        final itemId = oldData['id'] as String;
        await _deleteItemLocally(itemId);
        onDataChanged?.call();
        return;
      }

      // For INSERT and UPDATE
      final itemData = newData;
      final itemId = itemData['id'] as String;
      final createdBy = itemData['created_by'] as String?;
      final parentId = itemData['parent_id'] as String?;

      // Check if this item belongs to current user or is shared with them
      final isOwned = createdBy == userId;
      final isShared = await _isItemSharedWithUser(itemId, userId);
      
      // IMPORTANT: Also check if this is a sub-task of a shared item
      bool isChildOfShared = false;
      if (!isOwned && !isShared && parentId != null) {
        isChildOfShared = await _isItemSharedWithUser(parentId, userId);
        if (isChildOfShared) {
          print('📥 Sub-task of shared parent, allowing access');
        }
      }

      if (!isOwned && !isShared && !isChildOfShared) {
        print('⏭️  Item not relevant to current user, skipping');
        return;
      }

      // Check if this change was made by current user (avoid echo)
      final isar = await _isarService.db;
      
      // Find existing item using filter
      final existingItem = await isar.itemModels
          .filter()
          .itemIdEqualTo(itemId)
          .findFirst();

      // If item exists locally and is pending, don't overwrite (user is editing)
      if (existingItem != null && existingItem.syncStatus == SyncStatus.pending) {
        print('⏭️  Item is pending locally, skipping realtime update');
        return;
      }

      // Save to local database
      await _saveItemLocally(itemData);
      onDataChanged?.call();

    } catch (e) {
      print('❌ Error handling item change: $e');
    }
  }

  /// Handle block changes from realtime
  Future<void> _handleBlockChange(PostgresChangePayload payload, String userId) async {
    try {
      final eventType = payload.eventType;
      final newData = payload.newRecord;
      final oldData = payload.oldRecord;

      if (eventType == PostgresChangeEvent.delete) {
        // Handle deletion
        final blockId = oldData['id'] as String;
        await _deleteBlockLocally(blockId);
        onDataChanged?.call();
        return;
      }

      // For INSERT and UPDATE
      final blockData = newData;
      final blockId = blockData['id'] as String;
      final itemId = blockData['item_id'] as String;

      // Check if this block belongs to an item the user has access to
      final hasAccess = await _hasAccessToItem(itemId, userId);
      if (!hasAccess) {
        print('⏭️  Block not relevant to current user, skipping');
        return;
      }

      // Check if this block is pending locally (user is editing)
      final isar = await _isarService.db;
      
      // Find existing block using filter
      final existingBlock = await isar.blockModels
          .filter()
          .blockIdEqualTo(blockId)
          .findFirst();

      if (existingBlock != null && existingBlock.syncStatus == SyncStatus.pending) {
        print('⏭️  Block is pending locally, skipping realtime update');
        return;
      }

      // Save to local database
      await _saveBlockLocally(blockData);
      onDataChanged?.call();

    } catch (e) {
      print('❌ Error handling block change: $e');
    }
  }

  /// Handle notification changes from realtime
  Future<void> _handleNotificationChange(PostgresChangePayload payload) async {
    try {
      final notificationData = payload.newRecord;
      
      print('📬 New notification: ${notificationData['title']}');

      // Save to local database
      final notification = await _saveNotificationLocally(notificationData);
      
      // Trigger callback for UI to show notification
      if (notification != null) {
        onNewNotification?.call(notification);
      }

    } catch (e) {
      print('❌ Error handling notification change: $e');
    }
  }

  /// Check if item is shared with user
  Future<bool> _isItemSharedWithUser(String itemId, String userId) async {
    try {
      final supabase = Supabase.instance.client;
      final shares = await supabase
          .from('item_shares')
          .select('id')
          .eq('item_id', itemId)
          .eq('user_id', userId)
          .limit(1);

      return shares.isNotEmpty;
    } catch (e) {
      print('❌ Error checking item share: $e');
      return false;
    }
  }

  /// Check if user has access to item
  Future<bool> _hasAccessToItem(String itemId, String userId) async {
    try {
      final supabase = Supabase.instance.client;
      
      // Check if user owns the item
      final items = await supabase
          .from('items')
          .select('id')
          .eq('id', itemId)
          .eq('created_by', userId)
          .limit(1);

      if (items.isNotEmpty) return true;

      // Check if item is shared with user
      return await _isItemSharedWithUser(itemId, userId);
    } catch (e) {
      print('❌ Error checking item access: $e');
      return false;
    }
  }

  /// Save item to local Isar database
  Future<void> _saveItemLocally(Map<String, dynamic> itemData) async {
    try {
      final isar = await _isarService.db;
      final itemId = itemData['id'] as String;

      // Check if item already exists using filter
      final existingItem = await isar.itemModels
          .filter()
          .itemIdEqualTo(itemId)
          .findFirst();

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
        createdBy: itemData['created_by'] as String?,
        createdAtParam: DateTime.parse(itemData['created_at'] as String),
        updatedAtParam: DateTime.parse(itemData['updated_at'] as String),
        orderIndex: itemData['order_index'] as int? ?? 0,
        category: itemData['category'] as String?,
        syncStatus: SyncStatus.synced,
      );

      await isar.writeTxn(() async {
        if (existingItem != null) {
          item.id = existingItem.id; // Preserve local ID
        }
        await isar.itemModels.put(item);
      });

      print('✅ Item saved locally via realtime');
    } catch (e) {
      print('❌ Error saving item locally: $e');
    }
  }

  /// Save block to local Isar database
  Future<void> _saveBlockLocally(Map<String, dynamic> blockData) async {
    try {
      final isar = await _isarService.db;
      final blockId = blockData['id'] as String;

      // Check if block already exists using filter
      final existingBlock = await isar.blockModels
          .filter()
          .blockIdEqualTo(blockId)
          .findFirst();

      final block = BlockModel(
        blockId: blockId,
        itemId: blockData['item_id'] as String,
        type: BlockType.values.firstWhere(
          (e) => e.name == blockData['type'],
          orElse: () => BlockType.text,
        ),
        content: blockData['content'] as String? ?? '',
        isChecked: blockData['is_checked'] as bool? ?? false,
        orderIndex: blockData['order_index'] as int? ?? 0,
        updatedAtParam: DateTime.parse(blockData['updated_at'] as String),
        syncStatus: SyncStatus.synced,
      );

      await isar.writeTxn(() async {
        if (existingBlock != null) {
          block.id = existingBlock.id; // Preserve local ID
        }
        await isar.blockModels.put(block);
      });

      print('✅ Block saved locally via realtime');
    } catch (e) {
      print('❌ Error saving block locally: $e');
    }
  }

  /// Save notification to local Isar database
  Future<NotificationModel?> _saveNotificationLocally(Map<String, dynamic> notificationData) async {
    try {
      final isar = await _isarService.db;
      final notificationId = notificationData['id'] as String;

      // Check if notification already exists using filter
      final existingNotification = await isar.notificationModels
          .filter()
          .notificationIdEqualTo(notificationId)
          .findFirst();

      if (existingNotification != null) {
        print('⏭️  Notification already exists locally');
        return null;
      }

      final notification = NotificationModel(
        notificationId: notificationId,
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

      print('📬 Saving notification: ${notification.title}');
      print('   Created at: ${notification.createdAt}');
      print('   Time ago: ${timeago.format(notification.createdAt)}');

      await isar.writeTxn(() async {
        await isar.notificationModels.put(notification);
      });

      print('✅ Notification saved locally via realtime');
      return notification;
    } catch (e) {
      print('❌ Error saving notification locally: $e');
      return null;
    }
  }

  /// Delete item from local database
  Future<void> _deleteItemLocally(String itemId) async {
    try {
      final isar = await _isarService.db;
      
      // Find item using filter
      final item = await isar.itemModels
          .filter()
          .itemIdEqualTo(itemId)
          .findFirst();

      if (item != null) {
        await isar.writeTxn(() async {
          // Delete all blocks first
          final blocks = await isar.blockModels
              .filter()
              .itemIdEqualTo(itemId)
              .findAll();
          
          for (final block in blocks) {
            await isar.blockModels.delete(block.id);
          }
          
          // Delete item
          await isar.itemModels.delete(item.id);
        });

        print('✅ Item deleted locally via realtime');
      }
    } catch (e) {
      print('❌ Error deleting item locally: $e');
    }
  }

  /// Delete block from local database
  Future<void> _deleteBlockLocally(String blockId) async {
    try {
      final isar = await _isarService.db;
      
      // Find block using filter
      final block = await isar.blockModels
          .filter()
          .blockIdEqualTo(blockId)
          .findFirst();

      if (block != null) {
        await isar.writeTxn(() async {
          await isar.blockModels.delete(block.id);
        });

        print('✅ Block deleted locally via realtime');
      }
    } catch (e) {
      print('❌ Error deleting block locally: $e');
    }
  }

  /// Stop realtime subscriptions
  Future<void> stop() async {
    if (!_isSubscribed) return;

    print('🛑 Stopping realtime subscriptions...');

    await _itemsChannel?.unsubscribe();
    await _blocksChannel?.unsubscribe();
    await _notificationsChannel?.unsubscribe();

    _itemsChannel = null;
    _blocksChannel = null;
    _notificationsChannel = null;
    _isSubscribed = false;
    
    // Clear callbacks to prevent memory leaks
    onNewNotification = null;
    onDataChanged = null;

    print('✅ Realtime subscriptions stopped');
  }

  /// Check if subscribed
  bool get isSubscribed => _isSubscribed;
}
