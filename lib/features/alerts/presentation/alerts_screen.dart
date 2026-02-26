import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:isar/isar.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:openlist/core/theme/theme.dart';
import 'package:openlist/data/local/isar_service.dart';
import 'package:openlist/data/models/notification_model.dart';
import 'package:openlist/data/models/item_model.dart';
import 'package:openlist/data/repositories/item_repository.dart';
import 'package:openlist/data/sync/sync_manager.dart';
import 'package:timeago/timeago.dart' as timeago;

class AlertsScreen extends ConsumerStatefulWidget {
  const AlertsScreen({super.key});

  @override
  ConsumerState<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends ConsumerState<AlertsScreen> {
  final IsarService _isarService = IsarService.instance;
  List<NotificationModel> _notifications = [];
  bool _isLoading = true;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
    
    // Refresh every minute to update relative timestamps
    _refreshTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) {
        print('🔄 Timer tick - refreshing notification timestamps');
        setState(() {}); // Trigger rebuild to update timeago
      }
    });
    
    // Listen for sync completion to reload notifications
    SyncManager.instance.onSyncStatusChanged = (isSyncing, success) {
      if (!isSyncing && success && mounted) {
        _loadNotifications();
      }
    };
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    SyncManager.instance.onSyncStatusChanged = null;
    super.dispose();
  }

  Future<void> _loadNotifications() async {
    if (!mounted) return; // Check if widget is still mounted
    
    setState(() => _isLoading = true);
    
    try {
      final isar = await _isarService.db;
      
      // Get all notifications using proper Isar API
      final notificationCount = await isar.notificationModels.count();
      final notifications = <NotificationModel>[];
      
      for (int i = 0; i < notificationCount; i++) {
        final notification = await isar.notificationModels.get(i + 1);
        if (notification != null) {
          notifications.add(notification);
        }
      }
      
      // Sort manually by createdAt descending
      notifications.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      
      print('📬 Loaded ${notifications.length} notifications');
      for (final n in notifications.take(3)) {
        print('  - ${n.type.name}: ${n.message} (${n.createdAt})');
      }
      
      if (mounted) { // Check again before setState
        setState(() {
          _notifications = notifications;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('❌ Failed to load notifications: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _markAsRead(NotificationModel notification) async {
    if (notification.isRead) return;
    
    await SyncManager.instance.markNotificationAsRead(notification.id);
    await _loadNotifications();
  }

  Future<void> _markAllAsRead() async {
    for (final notification in _notifications) {
      if (!notification.isRead) {
        await SyncManager.instance.markNotificationAsRead(notification.id);
      }
    }
    await _loadNotifications();
  }

  Future<void> _clearAllNotifications() async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear all notifications?'),
        content: const Text('This will permanently delete all notifications.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Clear all'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final isar = await _isarService.db;
      await isar.writeTxn(() async {
        await isar.notificationModels.clear();
      });
      
      // Also delete from Supabase
      try {
        final supabase = Supabase.instance.client;
        final userId = supabase.auth.currentUser?.id;
        if (userId != null) {
          await supabase
              .from('notifications')
              .delete()
              .eq('user_id', userId);
        }
      } catch (e) {
        print('❌ Failed to delete notifications from Supabase: $e');
      }
      
      await _loadNotifications();
    } catch (e) {
      print('❌ Failed to clear notifications: $e');
    }
  }

  Future<void> _onNotificationTap(NotificationModel notification) async {
    // Mark as read
    await _markAsRead(notification);
    
    // Navigate to the item if it exists
    if (notification.itemId != null && mounted) {
      try {
        // Use ItemRepository to find the item
        final itemRepo = ItemRepository();
        final item = await itemRepo.getItemByItemId(notification.itemId!);
        
        if (item != null && mounted) {
          // Navigate to task detail screen
          context.push('/task/${item.id}');
        } else {
          // Item not found
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Item not found or has been deleted'),
                backgroundColor: AppColors.warning,
              ),
            );
          }
        }
      } catch (e) {
        print('❌ Failed to navigate to item: $e');
      }
    }
  }

  String _formatNotificationTime(DateTime createdAt) {
    final now = DateTime.now();
    final difference = now.difference(createdAt);
    
    // If less than 1 minute, show "just now"
    if (difference.inSeconds < 60) {
      return 'just now';
    }
    
    // If less than 1 hour, show minutes
    if (difference.inMinutes < 60) {
      final minutes = difference.inMinutes;
      return '$minutes ${minutes == 1 ? 'min' : 'mins'} ago';
    }
    
    // If less than 24 hours, show hours
    if (difference.inHours < 24) {
      final hours = difference.inHours;
      return '$hours ${hours == 1 ? 'hr' : 'hrs'} ago';
    }
    
    // If less than 7 days, show days
    if (difference.inDays < 7) {
      final days = difference.inDays;
      return '$days ${days == 1 ? 'day' : 'days'} ago';
    }
    
    // Otherwise show the actual date and time
    final month = createdAt.month.toString().padLeft(2, '0');
    final day = createdAt.day.toString().padLeft(2, '0');
    final hour = createdAt.hour.toString().padLeft(2, '0');
    final minute = createdAt.minute.toString().padLeft(2, '0');
    return '$day/$month/${createdAt.year} $hour:$minute';
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDarkMode ? AppColors.bgScaffoldDark : AppColors.bgScaffold,
      appBar: AppBar(
        backgroundColor: isDarkMode ? AppColors.bgScaffoldDark : AppColors.bgScaffold,
        elevation: 0,
        title: Text(
          'Notifications',
          style: GoogleFonts.inter(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: isDarkMode ? AppColors.textPrimaryDark : AppColors.textPrimary,
          ),
        ),
        actions: [
          if (_notifications.isNotEmpty)
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'mark_read') {
                  _markAllAsRead();
                } else if (value == 'clear_all') {
                  _clearAllNotifications();
                }
              },
              itemBuilder: (context) => [
                if (_notifications.any((n) => !n.isRead))
                  const PopupMenuItem(
                    value: 'mark_read',
                    child: Text('Mark all read'),
                  ),
                const PopupMenuItem(
                  value: 'clear_all',
                  child: Text('Clear all'),
                ),
              ],
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _notifications.isEmpty
              ? _buildEmptyState(isDarkMode)
              : RefreshIndicator(
                  onRefresh: () async {
                    await SyncManager.instance.triggerSync();
                    await _loadNotifications();
                  },
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _notifications.length,
                    itemBuilder: (context, index) {
                      return _buildNotificationCard(
                        _notifications[index],
                        isDarkMode,
                      );
                    },
                  ),
                ),
    );
  }

  Widget _buildEmptyState(bool isDarkMode) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.notifications_outlined,
            size: 64,
            color: isDarkMode ? AppColors.textMutedDark : AppColors.textMuted,
          ),
          const SizedBox(height: 16),
          Text(
            'No notifications',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: isDarkMode ? AppColors.textPrimaryDark : AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'You\'re all caught up!',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: isDarkMode ? AppColors.textMutedDark : AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationCard(NotificationModel notification, bool isDarkMode) {
    return GestureDetector(
      onTap: () => _onNotificationTap(notification),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: notification.isRead
              ? (isDarkMode ? AppColors.surfaceDark : Colors.white)
              : (isDarkMode ? AppColors.surfaceDark.withOpacity(0.8) : AppColors.primaryLight.withOpacity(0.1)),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: notification.isRead
                ? (isDarkMode ? AppColors.borderDark : AppColors.border)
                : AppColors.primary.withOpacity(0.3),
            width: notification.isRead ? 1 : 2,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: _getNotificationColor(notification.type).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _getNotificationIcon(notification.type),
                color: _getNotificationColor(notification.type),
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          notification.title,
                          style: GoogleFonts.inter(
                            fontSize: 15,
                            fontWeight: notification.isRead ? FontWeight.w600 : FontWeight.w700,
                            color: isDarkMode ? AppColors.textPrimaryDark : AppColors.textPrimary,
                          ),
                        ),
                      ),
                      if (!notification.isRead)
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    notification.message,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: isDarkMode ? AppColors.textSecondaryDark : AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _formatNotificationTime(notification.createdAt),
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: isDarkMode ? AppColors.textMutedDark : AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getNotificationIcon(NotificationType type) {
    switch (type) {
      case NotificationType.share:
        return Icons.share_outlined;
      case NotificationType.unshare:
        return Icons.remove_circle_outline;
      case NotificationType.update:
        return Icons.edit_outlined;
      case NotificationType.delete:
        return Icons.delete_outline;
      case NotificationType.comment:
        return Icons.comment_outlined;
      case NotificationType.reminder:
        return Icons.notifications_outlined;
      case NotificationType.deadline:
        return Icons.event_outlined;
    }
  }

  Color _getNotificationColor(NotificationType type) {
    switch (type) {
      case NotificationType.share:
        return AppColors.success;
      case NotificationType.unshare:
        return AppColors.danger;
      case NotificationType.update:
        return AppColors.warning;
      case NotificationType.delete:
        return AppColors.danger;
      case NotificationType.comment:
        return AppColors.primary;
      case NotificationType.reminder:
        return AppColors.primary;
      case NotificationType.deadline:
        return AppColors.warning;
    }
  }
}
