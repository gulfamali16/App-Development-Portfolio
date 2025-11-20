import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:workmanager/workmanager.dart';
import 'screens/theme_name_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/manage_screen.dart';
import 'screens/settings_screen.dart';
import 'utils/theme_manager.dart';
import 'utils/database_helper.dart';
import 'utils/notification_service.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'dart:io';

// ⭐ BACKGROUND TASK - Runs even when app is closed
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    print('🔄 [${DateTime.now()}] Background task started: $task');

    try {
      // Initialize services
      final dbHelper = DatabaseHelper();
      final notificationService = NotificationService();
      await notificationService.initialize();

      // Check and update expired tasks
      final expiredTasksMap = await dbHelper.checkAndUpdateExpiredTasks();
      final missedTasks = expiredTasksMap['missed'] ?? [];
      final rescheduledTasks = expiredTasksMap['rescheduled'] ?? [];

      print('📋 Background: Found ${missedTasks.length} missed, ${rescheduledTasks.length} rescheduled');

      // Send missed notifications
      for (final task in missedTasks) {
        await notificationService.showMissedTaskNotification(
          id: task.id.hashCode + 10000,
          title: task.title,
          body: task.description.isNotEmpty
              ? task.description
              : 'This task was due at ${_formatDate(task.dueDate)}',
        );
      }

      // Handle rescheduled tasks
      for (final task in rescheduledTasks) {
        final repeatType = _getRepeatTypeName(task.repeatRule);

        // Show rescheduled notification
        await notificationService.showTaskRescheduledNotification(
          id: task.id.hashCode + 20000,
          title: task.title,
          newDueDate: task.dueDate,
          repeatType: repeatType,
        );

        // Schedule notifications for new task
        await _scheduleTaskNotifications(task, notificationService, dbHelper);
      }

      print('✅ Background task completed successfully');
      return Future.value(true);
    } catch (e) {
      print('❌ Background task error: $e');
      return Future.value(false);
    }
  });
}

// Helper functions for background task
String _formatDate(DateTime date) {
  return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
}

String _getRepeatTypeName(RepeatRule rule) {
  switch (rule) {
    case RepeatRule.daily:
      return 'daily';
    case RepeatRule.weekly:
      return 'weekly';
    case RepeatRule.monthly:
      return 'monthly';
    default:
      return 'one-time';
  }
}

Future<void> _scheduleTaskNotifications(
    Task task, NotificationService notificationService, DatabaseHelper dbHelper) async {
  final notificationTime = task.dueDate.subtract(
    Duration(minutes: task.notificationMinutes),
  );

  // Schedule REMINDER notification
  if (notificationTime.isAfter(DateTime.now())) {
    await notificationService.scheduleTaskReminder(
      id: task.id.hashCode,
      taskId: task.id,
      title: task.title,
      body: task.description.isNotEmpty ? task.description : 'Due: ${_formatDate(task.dueDate)}',
      scheduledTime: task.dueDate,
      minutesBefore: task.notificationMinutes,
    );
  }

  // Schedule DUE NOW notification
  if (task.dueDate.isAfter(DateTime.now())) {
    await notificationService.scheduleTaskDueNow(
      id: task.id.hashCode,
      taskId: task.id,
      title: task.title,
      body: task.description.isNotEmpty ? task.description : 'This task is due right now!',
      dueTime: task.dueDate,
    );
  }

  await dbHelper.markNotificationScheduled(task.id);
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ⭐ Initialize WorkManager for background tasks
  await Workmanager().initialize(
    callbackDispatcher,
    isInDebugMode: true, // Set to false in production
  );

  // ⭐ Register periodic background task (runs every 15 minutes)
  await Workmanager().registerPeriodicTask(
    "task-expiry-check",
    "checkExpiredTasks",
    frequency: const Duration(minutes: 15), // Minimum is 15 minutes
    constraints: Constraints(
      networkType: NetworkType.not_required,
      requiresBatteryNotLow: false,
      requiresCharging: false,
      requiresDeviceIdle: false,
      requiresStorageNotLow: false,
    ),
  );

  print('✅ WorkManager initialized - background checks every 15 minutes');

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final ThemeManager _themeManager = ThemeManager();
  final DatabaseHelper _dbHelper = DatabaseHelper();
  final NotificationService _notificationService = NotificationService();

  bool _isLoading = true;
  bool _hasCompletedSetup = false;
  String? _error;
  bool _isDarkMode = false;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    try {
      // Request permissions
      if (Platform.isAndroid) {
        final DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
        final AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;

        print('📱 Device: ${androidInfo.brand} ${androidInfo.model}');
        print('📱 Android SDK: ${androidInfo.version.sdkInt}');

        if (androidInfo.version.sdkInt >= 33) {
          final PermissionStatus status = await Permission.notification.request();
          print('🔔 Notification permission: $status');

          if (!status.isGranted) {
            print('⚠️ WARNING: Notification permission denied!');
          }
        }

        if (androidInfo.version.sdkInt >= 31) {
          final alarmStatus = await Permission.scheduleExactAlarm.status;
          print('⏰ Exact Alarm permission: $alarmStatus');

          if (!alarmStatus.isGranted) {
            print('⚠️ WARNING: Exact alarm permission not granted!');
            await Permission.scheduleExactAlarm.request();
          }
        }
      }

      // Initialize notification service
      await _notificationService.initialize();
      print('✅ Notification service initialized');

      // Load theme
      await _themeManager.loadTheme();

      // Check if setup completed
      _hasCompletedSetup = await _dbHelper.hasCompletedSetup();

      // Check expired tasks immediately on app start
      await _checkExpiredTasks();

      // Schedule all pending notifications
      await _scheduleAllPendingNotifications();

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      print('❌ App initialization error: $e');
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  // ⭐ Check expired tasks and handle notifications
  Future<void> _checkExpiredTasks() async {
    final expiredTasksMap = await _dbHelper.checkAndUpdateExpiredTasks();
    final missedTasks = expiredTasksMap['missed'] ?? [];
    final rescheduledTasks = expiredTasksMap['rescheduled'] ?? [];

    print('📋 App Start: Missed=${missedTasks.length}, Rescheduled=${rescheduledTasks.length}');

    // Send missed task notifications
    for (final task in missedTasks) {
      await _notificationService.showMissedTaskNotification(
        id: task.id.hashCode + 10000,
        title: task.title,
        body: task.description.isNotEmpty
            ? task.description
            : 'This task was due: ${_formatDate(task.dueDate)}',
      );
    }

    // Handle rescheduled tasks
    for (final task in rescheduledTasks) {
      final repeatType = _getRepeatTypeName(task.repeatRule);

      await _notificationService.showTaskRescheduledNotification(
        id: task.id.hashCode + 20000,
        title: task.title,
        newDueDate: task.dueDate,
        repeatType: repeatType,
      );

      // Schedule notifications for the NEW rescheduled task
      final notificationTime = task.dueDate.subtract(
        Duration(minutes: task.notificationMinutes),
      );

      if (notificationTime.isAfter(DateTime.now())) {
        await _notificationService.scheduleTaskReminder(
          id: task.id.hashCode,
          taskId: task.id,
          title: task.title,
          body: task.description.isNotEmpty
              ? task.description
              : 'Due: ${_formatDate(task.dueDate)}',
          scheduledTime: task.dueDate,
          minutesBefore: task.notificationMinutes,
        );
        print('✅ Scheduled REMINDER for rescheduled task: ${task.title}');
      }

      if (task.dueDate.isAfter(DateTime.now())) {
        await _notificationService.scheduleTaskDueNow(
          id: task.id.hashCode,
          taskId: task.id,
          title: task.title,
          body: task.description.isNotEmpty
              ? task.description
              : 'This task is due right now!',
          dueTime: task.dueDate,
        );
        print('✅ Scheduled DUE NOW for rescheduled task: ${task.title}');
      }

      await _dbHelper.markNotificationScheduled(task.id);
    }
  }

  // ⭐ Schedule all pending notifications
  Future<void> _scheduleAllPendingNotifications() async {
    final pendingTasks = await _dbHelper.getTasksNeedingNotification();
    print('📋 Tasks needing notifications: ${pendingTasks.length}');

    for (final task in pendingTasks) {
      final notificationTime = task.dueDate.subtract(
        Duration(minutes: task.notificationMinutes),
      );

      // Schedule REMINDER notification
      if (notificationTime.isAfter(DateTime.now())) {
        await _notificationService.scheduleTaskReminder(
          id: task.id.hashCode,
          taskId: task.id,
          title: task.title,
          body: task.description.isNotEmpty
              ? task.description
              : 'Due: ${_formatDate(task.dueDate)}',
          scheduledTime: task.dueDate,
          minutesBefore: task.notificationMinutes,
        );
        print('✅ Scheduled REMINDER: ${task.title} for $notificationTime');
      }

      // Schedule DUE NOW notification
      if (task.dueDate.isAfter(DateTime.now())) {
        await _notificationService.scheduleTaskDueNow(
          id: task.id.hashCode,
          taskId: task.id,
          title: task.title,
          body: task.description.isNotEmpty
              ? task.description
              : 'This task is due right now!',
          dueTime: task.dueDate,
        );
        print('✅ Scheduled DUE NOW: ${task.title} for ${task.dueDate}');
      }

      await _dbHelper.markNotificationScheduled(task.id);
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} '
        '${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  String _getRepeatTypeName(RepeatRule rule) {
    switch (rule) {
      case RepeatRule.daily:
        return 'daily';
      case RepeatRule.weekly:
        return 'weekly';
      case RepeatRule.monthly:
        return 'monthly';
      default:
        return 'one-time';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return MaterialApp(
        home: Scaffold(
          backgroundColor: _isDarkMode ? const Color(0xFF112211) : Colors.white,
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                  'assets/logo.png',
                  height: 120,
                  width: 120,
                  color: _isDarkMode ? Colors.white : null,
                ),
                const SizedBox(height: 20),
                const CircularProgressIndicator(
                  color: Color(0xFF19E619),
                ),
                const SizedBox(height: 10),
                Text(
                  'Loading...',
                  style: TextStyle(
                    color: _isDarkMode ? Colors.white : Colors.black,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (_error != null) {
      return MaterialApp(
        home: Scaffold(
          backgroundColor: _isDarkMode ? const Color(0xFF112211) : Colors.white,
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error, color: Colors.red, size: 64),
                  const SizedBox(height: 20),
                  Text(
                    'App Error',
                    style: TextStyle(
                      color: _isDarkMode ? Colors.white : Colors.black,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    _error!,
                    style: TextStyle(
                      color: _isDarkMode ? Colors.white70 : Colors.black54,
                      fontSize: 16,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _initializeApp,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF19E619),
                    ),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return ChangeNotifierProvider.value(
      value: _themeManager,
      child: Consumer<ThemeManager>(
        builder: (context, themeManager, child) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'Task Manager',
            theme: AppThemes.lightTheme,
            darkTheme: AppThemes.darkTheme,
            themeMode: themeManager.currentTheme,
            initialRoute: _hasCompletedSetup ? '/dashboard' : '/theme',
            routes: {
              '/theme': (context) => const ThemeNameScreen(),
              '/dashboard': (context) {
                final args =
                ModalRoute.of(context)!.settings.arguments as String?;
                return DashboardScreen(userName: args ?? "User");
              },
              '/manage': (context) => const ManageScreen(),
              '/settings': (context) => const SettingsScreen(),
            },
          );
        },
      ),
    );
  }
}