import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'dart:ui';
import 'database_helper.dart' as db;

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  late FlutterLocalNotificationsPlugin _notifications;
  bool _isInitialized = false;

  // ⭐ Callback for handling notification actions
  static Function(String taskId, String action)? onNotificationAction;

  bool get isInitialized => _isInitialized;

  Future<void> initialize() async {
    if (_isInitialized) {
      print('✅ Notification service already initialized');
      return;
    }

    print('🔧 Initializing notification service...');

    try {
      // Initialize timezone with auto-detection
      tz.initializeTimeZones();

      // ⭐ AUTO-DETECT TIMEZONE
      final String timeZoneName = await _getDeviceTimeZone();
      try {
        tz.setLocalLocation(tz.getLocation(timeZoneName));
        print('✅ Timezone set to: $timeZoneName');
      } catch (e) {
        print('⚠️ Timezone $timeZoneName not found, using UTC');
        tz.setLocalLocation(tz.getLocation('UTC'));
      }

      _notifications = FlutterLocalNotificationsPlugin();

      const AndroidInitializationSettings androidSettings =
      AndroidInitializationSettings('@mipmap/ic_launcher');

      const DarwinInitializationSettings iosSettings =
      DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      const InitializationSettings settings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      final initialized = await _notifications.initialize(
        settings,
        onDidReceiveNotificationResponse: (NotificationResponse response) {
          print('📨 Notification tapped: ${response.actionId}');
          print('📨 Payload: ${response.payload}');
          _handleNotificationAction(response);
        },
      );

      print('✅ Notification plugin initialized: $initialized');
      await _createNotificationChannels();

      _isInitialized = true;
      print('✅ Notification service fully initialized');
    } catch (e) {
      print('❌ Notification initialization error: $e');
      rethrow;
    }
  }

  // ⭐ AUTO-DETECT DEVICE TIMEZONE
  Future<String> _getDeviceTimeZone() async {
    try {
      final DateTime now = DateTime.now();
      final int offsetInMinutes = now.timeZoneOffset.inMinutes;

      // Map common offsets to timezone names
      if (offsetInMinutes == 300) return 'Asia/Karachi';      // UTC+5
      if (offsetInMinutes == 330) return 'Asia/Kolkata';      // UTC+5:30
      if (offsetInMinutes == 480) return 'Asia/Shanghai';     // UTC+8
      if (offsetInMinutes == 0) return 'UTC';                 // UTC
      if (offsetInMinutes == -300) return 'America/New_York'; // UTC-5
      if (offsetInMinutes == -480) return 'America/Los_Angeles'; // UTC-8

      return 'UTC'; // Default fallback
    } catch (e) {
      print('⚠️ Could not detect timezone: $e');
      return 'UTC';
    }
  }

  // ⭐ IMPROVED: Handle notification actions (Complete/Snooze)
  void _handleNotificationAction(NotificationResponse response) async {
    final actionId = response.actionId;
    final taskId = response.payload;

    if (taskId == null || taskId.isEmpty) {
      print('⚠️ No task ID in notification payload');
      return;
    }

    try {
      final dbHelper = db.DatabaseHelper();

      if (actionId == 'complete') {
        print('✅ Completing task from notification: $taskId');

        // Mark task as completed
        await dbHelper.toggleTaskCompletion(taskId, true);

        // Show completion confirmation
        await showTaskCompletedNotification(
          id: taskId.hashCode + 30000,
          title: 'Task Completed',
          body: 'Great job! Task marked as complete.',
        );

        // Cancel remaining notifications for this task
        await cancelTaskNotifications(taskId.hashCode);

        // Notify app if callback is set
        if (onNotificationAction != null) {
          onNotificationAction!(taskId, 'complete');
        }

      } else if (actionId == 'snooze') {
        print('⏰ Snoozing task: $taskId');

        // Get the task
        final tasks = await dbHelper.getAllTasks();
        final task = tasks.firstWhere(
              (t) => t.id == taskId,
          orElse: () => throw Exception('Task not found'),
        );

        // Cancel current notifications
        await cancelTaskNotifications(taskId.hashCode);

        // Reschedule for 10 minutes later
        final newDueTime = DateTime.now().add(const Duration(minutes: 10));

        await scheduleTaskReminder(
          id: taskId.hashCode,
          taskId: taskId,
          title: '⏰ Snoozed: ${task.title}',
          body: task.description.isNotEmpty
              ? task.description
              : 'This task was snoozed',
          scheduledTime: newDueTime,
          minutesBefore: 0,
        );

        // Show snooze confirmation
        await showImmediateNotification(
          id: taskId.hashCode + 40000,
          title: '⏰ Task Snoozed',
          body: 'Reminder set for 10 minutes from now',
        );

        // Notify app if callback is set
        if (onNotificationAction != null) {
          onNotificationAction!(taskId, 'snooze');
        }
      }
    } catch (e) {
      print('❌ Error handling notification action: $e');
    }
  }

  Future<void> _createNotificationChannels() async {
    final androidPlugin = _notifications
        .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();

    if (androidPlugin == null) return;

    // HIGH PRIORITY CHANNEL for reminders
    const AndroidNotificationChannel reminderChannel = AndroidNotificationChannel(
      'task_reminder_channel',
      'Task Reminders',
      description: 'Notifications for upcoming tasks',
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
      showBadge: true,
      enableLights: true,
      ledColor: Color(0xFF19E619),
    );

    // CRITICAL CHANNEL for missed tasks
    const AndroidNotificationChannel missedChannel = AndroidNotificationChannel(
      'task_missed_channel',
      'Missed Tasks',
      description: 'Notifications for missed tasks',
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
      showBadge: true,
      enableLights: true,
      ledColor: Color(0xFFFF0000),
    );

    const AndroidNotificationChannel completedChannel = AndroidNotificationChannel(
      'task_completed_channel',
      'Task Completed',
      description: 'Notifications when tasks are completed',
      importance: Importance.defaultImportance,
      playSound: true,
      showBadge: false,
    );

    const AndroidNotificationChannel rescheduledChannel = AndroidNotificationChannel(
      'task_rescheduled_channel',
      'Task Rescheduled',
      description: 'Notifications when repeated tasks are rescheduled',
      importance: Importance.high,
      playSound: true,
      showBadge: true,
    );

    await androidPlugin.createNotificationChannel(reminderChannel);
    await androidPlugin.createNotificationChannel(missedChannel);
    await androidPlugin.createNotificationChannel(completedChannel);
    await androidPlugin.createNotificationChannel(rescheduledChannel);

    print("✅ All notification channels created!");
  }

  // ⭐ 1. TASK REMINDER - With action buttons
  Future<void> scheduleTaskReminder({
    required int id,
    required String taskId,
    required String title,
    required String body,
    required DateTime scheduledTime,
    required int minutesBefore,
  }) async {
    if (!_isInitialized) {
      print('❌ Cannot schedule notification: Service not initialized');
      return;
    }

    final notificationTime =
    scheduledTime.subtract(Duration(minutes: minutesBefore));

    if (notificationTime.isBefore(DateTime.now())) {
      print('⚠️ Notification time is in past: $notificationTime');
      return;
    }

    print('🕐 Scheduling REMINDER for: $notificationTime');

    try {
      final tz.TZDateTime scheduledDate =
      tz.TZDateTime.from(notificationTime, tz.local);

      final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        'task_reminder_channel',
        'Task Reminders',
        channelDescription: 'Notifications for upcoming tasks',
        importance: Importance.max,
        priority: Priority.high,
        enableVibration: true,
        playSound: true,
        timeoutAfter: 60000,
        fullScreenIntent: true,
        visibility: NotificationVisibility.public,
        icon: '@mipmap/ic_launcher',
        color: const Color(0xFF19E619),
        actions: <AndroidNotificationAction>[
          const AndroidNotificationAction(
            'complete',
            'Mark Complete',
            showsUserInterface: true,
            cancelNotification: true,
          ),
          const AndroidNotificationAction(
            'snooze',
            'Snooze 10min',
            showsUserInterface: false,
            cancelNotification: false,
          ),
        ],
      );

      final NotificationDetails details = NotificationDetails(
        android: androidDetails,
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      );

      await _notifications.zonedSchedule(
        id,
        '⏰ $title',
        body,
        scheduledDate,
        details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
        UILocalNotificationDateInterpretation.absoluteTime,
        payload: taskId,
      );

      print('✅ REMINDER scheduled! ID: $id for $scheduledDate');
    } catch (e) {
      print('❌ Scheduling error: $e');
      // Retry mechanism
      await Future.delayed(const Duration(seconds: 2));
      print('🔄 Retrying notification schedule...');
      try {
        await scheduleTaskReminder(
          id: id,
          taskId: taskId,
          title: title,
          body: body,
          scheduledTime: scheduledTime,
          minutesBefore: minutesBefore,
        );
      } catch (retryError) {
        print('❌ Retry failed: $retryError');
      }
    }
  }

  // ⭐ 2. DUE NOW NOTIFICATION
  Future<void> scheduleTaskDueNow({
    required int id,
    required String taskId,
    required String title,
    required String body,
    required DateTime dueTime,
  }) async {
    if (!_isInitialized) {
      print('❌ Cannot schedule notification: Service not initialized');
      return;
    }

    if (dueTime.isBefore(DateTime.now())) {
      print('⚠️ Due time is in past: $dueTime');
      return;
    }

    print('⏰ Scheduling DUE NOW notification for: $dueTime');

    try {
      final tz.TZDateTime scheduledDate = tz.TZDateTime.from(dueTime, tz.local);

      final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        'task_reminder_channel',
        'Task Reminders',
        channelDescription: 'Notifications when tasks are due',
        importance: Importance.max,
        priority: Priority.high,
        enableVibration: true,
        playSound: true,
        timeoutAfter: 60000,
        fullScreenIntent: true,
        visibility: NotificationVisibility.public,
        icon: '@mipmap/ic_launcher',
        color: const Color(0xFFFF9800),
        actions: <AndroidNotificationAction>[
          const AndroidNotificationAction(
            'complete',
            'Mark Complete',
            showsUserInterface: true,
            cancelNotification: true,
          ),
          const AndroidNotificationAction(
            'snooze',
            'Snooze 10min',
            showsUserInterface: false,
            cancelNotification: false,
          ),
        ],
      );

      final NotificationDetails details = NotificationDetails(
        android: androidDetails,
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      );

      await _notifications.zonedSchedule(
        id + 5000,
        '⏰ DUE NOW: $title',
        body.isNotEmpty ? body : 'This task is due right now!',
        scheduledDate,
        details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
        UILocalNotificationDateInterpretation.absoluteTime,
        payload: taskId,
      );

      print('✅ DUE NOW notification scheduled! ID: ${id + 5000}');
    } catch (e) {
      print('❌ Scheduling error: $e');
    }
  }

  // ⭐ 3. MISSED TASK NOTIFICATION
  Future<void> showMissedTaskNotification({
    required int id,
    required String title,
    required String body,
  }) async {
    if (!_isInitialized) {
      print('❌ Cannot show notification: Service not initialized');
      return;
    }

    print('❌ Showing MISSED TASK notification (ID: $id)');

    final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'task_missed_channel',
      'Missed Tasks',
      channelDescription: 'Notifications for missed tasks',
      importance: Importance.max,
      priority: Priority.high,
      enableVibration: true,
      playSound: true,
      fullScreenIntent: true,
      visibility: NotificationVisibility.public,
      icon: '@mipmap/ic_launcher',
      color: const Color(0xFFFF0000),
      styleInformation: const BigTextStyleInformation(''),
    );

    final NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: const DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );

    try {
      await _notifications.show(
        id,
        '❌ Missed: $title',
        body,
        details,
      );
      print('✅ MISSED notification sent (ID: $id)');
    } catch (e) {
      print('❌ Error showing missed notification: $e');
    }
  }

  // ⭐ 4. TASK COMPLETED NOTIFICATION
  Future<void> showTaskCompletedNotification({
    required int id,
    required String title,
    String? body,
  }) async {
    if (!_isInitialized) {
      print('❌ Cannot show notification: Service not initialized');
      return;
    }

    print('✅ Showing TASK COMPLETED notification (ID: $id)');

    final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'task_completed_channel',
      'Task Completed',
      channelDescription: 'Notifications when tasks are completed',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
      enableVibration: false,
      playSound: true,
      icon: '@mipmap/ic_launcher',
      color: const Color(0xFF19E619),
    );

    final NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: const DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: false,
        presentSound: true,
      ),
    );

    try {
      await _notifications.show(
        id,
        '✅ Completed: $title',
        body ?? 'Great job! Task completed successfully.',
        details,
      );
      print('✅ COMPLETED notification sent (ID: $id)');
    } catch (e) {
      print('❌ Error showing completed notification: $e');
    }
  }

  // ⭐ 5. TASK RESCHEDULED NOTIFICATION
  Future<void> showTaskRescheduledNotification({
    required int id,
    required String title,
    required DateTime newDueDate,
    required String repeatType,
  }) async {
    if (!_isInitialized) {
      print('❌ Cannot show notification: Service not initialized');
      return;
    }

    print('🔄 Showing TASK RESCHEDULED notification (ID: $id)');

    final String formattedDate = _formatDateTime(newDueDate);
    final String body = 'Your $repeatType task has been rescheduled to $formattedDate';

    final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'task_rescheduled_channel',
      'Task Rescheduled',
      channelDescription: 'Notifications when repeated tasks are rescheduled',
      importance: Importance.high,
      priority: Priority.high,
      enableVibration: true,
      playSound: true,
      icon: '@mipmap/ic_launcher',
      color: const Color(0xFF19E619),
    );

    final NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: const DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );

    try {
      await _notifications.show(
        id,
        '🔄 Rescheduled: $title',
        body,
        details,
      );
      print('✅ RESCHEDULED notification sent (ID: $id)');
    } catch (e) {
      print('❌ Error showing rescheduled notification: $e');
    }
  }

  // ⭐ TEST: Show immediate notification
  Future<void> showImmediateNotification({
    required int id,
    required String title,
    required String body,
  }) async {
    if (!_isInitialized) {
      print('❌ Cannot show notification: Service not initialized');
      return;
    }

    print('📢 Showing immediate TEST notification (ID: $id)');

    final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'task_reminder_channel',
      'Task Reminders',
      channelDescription: 'Notifications for upcoming tasks',
      importance: Importance.max,
      priority: Priority.high,
      enableVibration: true,
      playSound: true,
      fullScreenIntent: true,
      visibility: NotificationVisibility.public,
    );

    final NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: const DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );

    try {
      await _notifications.show(
        id,
        title,
        body,
        details,
      );
      print('✅ TEST notification sent (ID: $id)');
    } catch (e) {
      print('❌ Error showing test notification: $e');
    }
  }

  String _formatDateTime(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final taskDate = DateTime(date.year, date.month, date.day);

    final timeStr = '${date.hour}:${date.minute.toString().padLeft(2, '0')}';

    if (taskDate == today) {
      return 'Today at $timeStr';
    } else if (taskDate == tomorrow) {
      return 'Tomorrow at $timeStr';
    } else {
      return '${date.day}/${date.month}/${date.year} at $timeStr';
    }
  }

  Future<void> printPendingNotifications() async {
    if (!_isInitialized) {
      print('❌ Cannot check pending notifications: Service not initialized');
      return;
    }

    try {
      final pending = await _notifications.pendingNotificationRequests();
      print('📋 Pending notifications: ${pending.length}');
      for (var notif in pending) {
        print('  - ID: ${notif.id}, Title: ${notif.title}, Body: ${notif.body}');
      }
    } catch (e) {
      print('❌ Error getting pending notifications: $e');
    }
  }

  Future<void> cancelTaskNotifications(int baseId) async {
    if (!_isInitialized) return;
    await _notifications.cancel(baseId);
    await _notifications.cancel(baseId + 5000);
    print('🗑️ Cancelled notifications for task (Base ID: $baseId)');
  }

  Future<void> cancelNotification(int id) async {
    if (!_isInitialized) return;
    await _notifications.cancel(id);
    print('🗑️ Notification cancelled (ID: $id)');
  }

  Future<void> cancelAllNotifications() async {
    if (!_isInitialized) return;
    await _notifications.cancelAll();
    print('🗑️ All notifications cancelled');
  }
}