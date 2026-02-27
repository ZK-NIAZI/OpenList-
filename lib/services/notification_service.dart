import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:openlist/data/models/item_model.dart';

/// Service for managing local notifications and reminders
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  bool _initialized = false;
  
  // Callback for when notification is tapped
  Function(String taskId)? onNotificationTapped;

  /// Initialize the notification service
  Future<void> initialize() async {
    if (_initialized) return;

    // Initialize timezone data
    tz.initializeTimeZones();
    
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    
    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );
    
    await _notifications.initialize(
      settings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    _initialized = true;
  }

  /// Handle notification tap
  void _onNotificationTapped(NotificationResponse response) {
    final payload = response.payload;
    if (payload != null) {
      // Call the callback to navigate to task
      onNotificationTapped?.call(payload);
      print('📱 Notification tapped - Task ID: $payload');
    }
  }

  /// Schedule a reminder notification for a task
  Future<void> scheduleReminder(ItemModel item) async {
    if (!_initialized) await initialize();
    
    // Only schedule if task has a reminder time
    if (item.reminderAt == null) return;
    
    // Don't schedule if reminder is in the past
    if (item.reminderAt!.isBefore(DateTime.now())) {
      print('⚠️ Reminder time is in the past, skipping: ${item.title}');
      return;
    }

    // Don't schedule for completed tasks
    if (item.isCompleted) {
      print('⚠️ Task is completed, skipping reminder: ${item.title}');
      return;
    }

    try {
      final notificationId = item.itemId.hashCode;
      
      await _notifications.zonedSchedule(
        notificationId,
        '⏰ Reminder: ${item.title}',
        item.dueDate != null 
            ? 'Due ${_formatDueDate(item.dueDate!)}'
            : 'Task reminder',
        tz.TZDateTime.from(item.reminderAt!, tz.local),
        NotificationDetails(
          android: AndroidNotificationDetails(
            'task_reminders',
            'Task Reminders',
            channelDescription: 'Notifications for task reminders',
            importance: Importance.high,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: item.itemId, // Pass task ID for navigation
      );
      
      print('✅ Scheduled reminder for "${item.title}" at ${item.reminderAt}');
    } catch (e) {
      print('❌ Failed to schedule reminder: $e');
    }
  }

  /// Cancel a scheduled reminder
  Future<void> cancelReminder(String itemId) async {
    if (!_initialized) await initialize();
    
    try {
      final notificationId = itemId.hashCode;
      await _notifications.cancel(notificationId);
      print('✅ Cancelled reminder for task: $itemId');
    } catch (e) {
      print('❌ Failed to cancel reminder: $e');
    }
  }

  /// Update a reminder (cancel old and schedule new)
  Future<void> updateReminder(ItemModel item) async {
    await cancelReminder(item.itemId);
    await scheduleReminder(item);
  }

  /// Cancel all reminders
  Future<void> cancelAllReminders() async {
    if (!_initialized) await initialize();
    
    try {
      await _notifications.cancelAll();
      print('✅ Cancelled all reminders');
    } catch (e) {
      print('❌ Failed to cancel all reminders: $e');
    }
  }

  /// Get pending notifications (for debugging)
  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    if (!_initialized) await initialize();
    return await _notifications.pendingNotificationRequests();
  }

  /// Show a collaboration notification (share, edit, delete)
  Future<void> showCollaborationNotification({
    required String title,
    required String message,
    String? itemId,
  }) async {
    if (!_initialized) await initialize();
    
    try {
      final notificationId = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      
      await _notifications.show(
        notificationId,
        title,
        message,
        NotificationDetails(
          android: AndroidNotificationDetails(
            'collaboration',
            'Collaboration',
            channelDescription: 'Notifications for shared items and collaboration',
            importance: Importance.high,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
            styleInformation: BigTextStyleInformation(message),
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        payload: itemId, // Pass item ID for navigation
      );
      
      print('✅ Showed collaboration notification: $title');
    } catch (e) {
      print('❌ Failed to show collaboration notification: $e');
    }
  }

  /// Format due date for notification
  String _formatDueDate(DateTime dueDate) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final dueDay = DateTime(dueDate.year, dueDate.month, dueDate.day);

    if (dueDay == today) {
      return 'today at ${_formatTime(dueDate)}';
    } else if (dueDay == tomorrow) {
      return 'tomorrow at ${_formatTime(dueDate)}';
    } else {
      return '${dueDate.month}/${dueDate.day} at ${_formatTime(dueDate)}';
    }
  }

  /// Format time (e.g., "2:30 PM")
  String _formatTime(DateTime time) {
    final hour = time.hour > 12 ? time.hour - 12 : (time.hour == 0 ? 12 : time.hour);
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }

  /// Request notification permissions (iOS)
  Future<bool> requestPermissions() async {
    if (!_initialized) await initialize();
    
    final result = await _notifications
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
    
    return result ?? true; // Android doesn't need runtime permission
  }
}
