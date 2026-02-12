import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'dart:ui';
import 'dart:typed_data';
import 'database_helper.dart' as db;

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  late FlutterLocalNotificationsPlugin _notifications;
  bool _isInitialized = false;

  static Function(String taskId, String action)? onNotificationAction;

  bool get isInitialized => _isInitialized;

  Future<void> initialize() async {
    if (_isInitialized) {
      print('✅ Notification service already initialized');
      return;
    }

    print('🔧 Initializing notification service...');

    try {
      tz.initializeTimeZones();

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

  Future<String> _getDeviceTimeZone() async {
    try {
      final DateTime now = DateTime.now();
      final int offsetInMinutes = now.timeZoneOffset.inMinutes;

      if (offsetInMinutes == 300) return 'Asia/Karachi';
      if (offsetInMinutes == 330) return 'Asia/Kolkata';
      if (offsetInMinutes == 480) return 'Asia/Shanghai';
      if (offsetInMinutes == 0) return 'UTC';
      if (offsetInMinutes == -300) return 'America/New_York';
      if (offsetInMinutes == -480) return 'America/Los_Angeles';

      return 'UTC';
    } catch (e) {
      print('⚠️ Could not detect timezone: $e');
      return 'UTC';
    }
  }

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

        await dbHelper.toggleTaskCompletion(taskId, true);

        await showTaskCompletedNotification(
          id: taskId.hashCode + 30000,
          title: 'Task Completed',
          body: 'Great job! Task marked as complete.',
        );

        await cancelTaskNotifications(taskId.hashCode);

        if (onNotificationAction != null) {
          onNotificationAction!(taskId, 'complete');
        }

      } else if (actionId == 'snooze') {
        print('⏰ Snoozing task: $taskId');

        final tasks = await dbHelper.getAllTasks();
        final task = tasks.firstWhere(
              (t) => t.id == taskId,
          orElse: () => throw Exception('Task not found'),
        );

        await cancelTaskNotifications(taskId.hashCode);

        final newDueTime = DateTime.now().add(const Duration(minutes: 10));

        await scheduleTaskReminder(
          id: taskId.hashCode + 60000,
          taskId: taskId,
          title: '⏰ Snoozed: ${task.title}',
          body: task.description.isNotEmpty
              ? task.description
              : 'This task was snoozed',
          scheduledTime: newDueTime,
          minutesBefore: 0,
        );

        await showImmediateNotification(
          id: taskId.hashCode + 40000,
          title: '⏰ Task Snoozed',
          body: 'Reminder set for 10 minutes from now',
        );

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

    final now = DateTime.now();
    final reminderTime = scheduledTime.subtract(Duration(minutes: minutesBefore));

    print('📅 Due time: $scheduledTime');
    print('⏰ Reminder time: $reminderTime ($minutesBefore min before)');
    print('🕐 Current time: $now');

    if (reminderTime.isBefore(now)) {
      print('⚠️ Reminder time already passed. Skipping reminder.');
      return;
    }

    if (scheduledTime.isBefore(now)) {
      print('⚠️ Task time is in past, skipping');
      return;
    }

    try {
      final tz.TZDateTime scheduledDate = tz.TZDateTime.from(reminderTime, tz.local);

      print('📤 Scheduling reminder notification...');
      print('   ID: $id');
      print('   Time: $scheduledDate');

      // ⭐ CRASH FIX: Remove fullScreenIntent and reduce timeout
      final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        'task_reminder_channel',
        'Task Reminders',
        channelDescription: 'Notifications for upcoming tasks',
        importance: Importance.max,
        priority: Priority.high,
        enableVibration: true,
        playSound: true,
        visibility: NotificationVisibility.public,
        icon: '@mipmap/ic_launcher',
        color: const Color(0xFF19E619),
        styleInformation: BigTextStyleInformation(
          body,
          contentTitle: '⏰ Reminder: $title',
          summaryText: 'Task Manager',
        ),
        actions: <AndroidNotificationAction>[
          const AndroidNotificationAction(
            'complete',
            '✅ Complete',
            showsUserInterface: true,
            cancelNotification: true,
          ),
          const AndroidNotificationAction(
            'snooze',
            '⏰ Snooze 10min',
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
        '⏰ Reminder: $title',
        body,
        scheduledDate,
        details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
        UILocalNotificationDateInterpretation.absoluteTime,
        payload: taskId,
      );

      print('✅ REMINDER scheduled successfully!');
    } catch (e) {
      print('❌ Scheduling error: $e');
    }
  }

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

    final now = DateTime.now();

    if (dueTime.isBefore(now)) {
      print('⚠️ Due time is in past: $dueTime');
      return;
    }

    print('📤 Scheduling DUE NOW notification...');
    print('   ID: ${id + 5000}');
    print('   Time: $dueTime');

    try {
      final tz.TZDateTime scheduledDate = tz.TZDateTime.from(dueTime, tz.local);

      // ⭐ CRASH FIX: Remove fullScreenIntent
      final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        'task_reminder_channel',
        'Task Reminders',
        channelDescription: 'Task is due right now!',
        importance: Importance.max,
        priority: Priority.high,
        enableVibration: true,
        playSound: true,
        visibility: NotificationVisibility.public,
        icon: '@mipmap/ic_launcher',
        color: const Color(0xFFFF9800),
        vibrationPattern: Int64List.fromList([0, 500, 200, 500]),
        styleInformation: BigTextStyleInformation(
          body.isNotEmpty ? body : 'This task is due right now!',
          contentTitle: '🔔 DUE NOW: $title',
          summaryText: 'Task Manager',
        ),
        actions: <AndroidNotificationAction>[
          const AndroidNotificationAction(
            'complete',
            '✅ Mark Done',
            showsUserInterface: true,
            cancelNotification: true,
          ),
          const AndroidNotificationAction(
            'snooze',
            '⏰ +10 min',
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
        '🔔 DUE NOW: $title',
        body.isNotEmpty ? body : 'This task is due right now!',
        scheduledDate,
        details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
        UILocalNotificationDateInterpretation.absoluteTime,
        payload: taskId,
      );

      print('✅ DUE NOW notification scheduled successfully!');
    } catch (e) {
      print('❌ DUE NOW scheduling error: $e');
    }
  }

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

    // ⭐ CRASH FIX: Remove fullScreenIntent from missed notifications too
    final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'task_missed_channel',
      'Missed Tasks',
      channelDescription: 'You missed this task!',
      importance: Importance.max,
      priority: Priority.high,
      enableVibration: true,
      playSound: true,
      visibility: NotificationVisibility.public,
      icon: '@mipmap/ic_launcher',
      color: const Color(0xFFFF0000),
      vibrationPattern: Int64List.fromList([0, 500, 300, 500, 300, 500]),
      styleInformation: BigTextStyleInformation(
        body,
        contentTitle: '❌ Missed: $title',
        summaryText: 'Task Manager',
      ),
      actions: <AndroidNotificationAction>[
        const AndroidNotificationAction(
          'complete',
          '✅ Complete Now',
          showsUserInterface: true,
          cancelNotification: true,
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

    try {
      await _notifications.show(
        id,
        '❌ Missed: $title',
        body,
        details,
        payload: id.toString(),
      );
      print('✅ MISSED notification sent (ID: $id)');
    } catch (e) {
      print('❌ Error showing missed notification: $e');
    }
  }

  Future<void> showTaskCompletedNotification({
    required int id,
    required String title,
    String? body,
  }) async {
    if (!_isInitialized) return;

    print('✅ Showing TASK COMPLETED notification (ID: $id)');

    final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'task_completed_channel',
      'Task Completed',
      channelDescription: 'Celebration for completed tasks',
      importance: Importance.high,
      priority: Priority.high,
      enableVibration: true,
      playSound: true,
      icon: '@mipmap/ic_launcher',
      color: const Color(0xFF19E619),
      vibrationPattern: Int64List.fromList([0, 200, 100, 200]),
      styleInformation: const BigTextStyleInformation(
        '🎉 Great job! Task completed successfully.',
        contentTitle: '✅ Task Completed',
        summaryText: 'Task Manager',
      ),
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
        body ?? '🎉 Great job! Task completed successfully.',
        details,
      );
      print('✅ COMPLETED notification sent (ID: $id)');
    } catch (e) {
      print('❌ Error showing completed notification: $e');
    }
  }

  Future<void> showTaskRescheduledNotification({
    required int id,
    required String title,
    required DateTime newDueDate,
    required String repeatType,
  }) async {
    if (!_isInitialized) return;

    print('🔄 Showing TASK RESCHEDULED notification (ID: $id)');

    final String formattedDate = _formatDateTime(newDueDate);
    final String body = 'Your $repeatType task rescheduled to $formattedDate';

    final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'task_rescheduled_channel',
      'Task Rescheduled',
      channelDescription: 'Repeated task rescheduled',
      importance: Importance.high,
      priority: Priority.high,
      enableVibration: true,
      playSound: true,
      icon: '@mipmap/ic_launcher',
      color: const Color(0xFF19E619),
      styleInformation: BigTextStyleInformation(
        body,
        contentTitle: '🔄 Rescheduled: $title',
        summaryText: 'Task Manager',
      ),
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

  Future<void> showImmediateNotification({
    required int id,
    required String title,
    required String body,
    String? taskId,
    bool withActions = false,
  }) async {
    if (!_isInitialized) return;

    print('📢 Showing immediate notification (ID: $id)');

    // ⭐ CRASH FIX: Remove fullScreenIntent from immediate notifications
    final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'task_reminder_channel',
      'Task Reminders',
      channelDescription: 'Immediate notification',
      importance: Importance.max,
      priority: Priority.high,
      enableVibration: true,
      playSound: true,
      visibility: NotificationVisibility.public,
      color: const Color(0xFF19E619),
      styleInformation: BigTextStyleInformation(
        body,
        contentTitle: title,
        summaryText: 'Task Manager',
      ),
      actions: withActions ? <AndroidNotificationAction>[
        const AndroidNotificationAction(
          'complete',
          '✅ Complete',
          showsUserInterface: true,
          cancelNotification: true,
        ),
        const AndroidNotificationAction(
          'snooze',
          '⏰ Snooze 10min',
          showsUserInterface: false,
          cancelNotification: false,
        ),
      ] : null,
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
        payload: taskId,
      );
      print('✅ Immediate notification sent (ID: $id)');
    } catch (e) {
      print('❌ Error: $e');
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
    if (!_isInitialized) return;

    try {
      final pending = await _notifications.pendingNotificationRequests();
      print('📋 ===== PENDING NOTIFICATIONS =====');
      print('📋 Total: ${pending.length}');
      for (var notif in pending) {
        print('  📌 ID: ${notif.id}');
        print('     Title: ${notif.title}');
        print('     Body: ${notif.body}');
        print('  ---');
      }
      print('📋 ==================================');
    } catch (e) {
      print('❌ Error: $e');
    }
  }

  Future<void> cancelTaskNotifications(int baseId) async {
    if (!_isInitialized) return;
    await _notifications.cancel(baseId);
    await _notifications.cancel(baseId + 5000);
    await _notifications.cancel(baseId + 60000);
    print('🗑️ Cancelled all notifications for task (Base ID: $baseId)');
  }

  Future<void> cancelNotification(int id) async {
    if (!_isInitialized) return;
    await _notifications.cancel(id);
  }

  Future<void> cancelAllNotifications() async {
    if (!_isInitialized) return;
    await _notifications.cancelAll();
  }
}