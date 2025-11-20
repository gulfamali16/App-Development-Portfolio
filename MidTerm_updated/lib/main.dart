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
// IMPORTANT: This runs in an ISOLATED context, so we need ALL imports here
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    print('🔄 [${DateTime.now()}] Background task started: $task');

    try {
      // Initialize services in isolated context
      final dbHelper = DatabaseHelper();
      final notificationService = NotificationService();

      // ⭐ CRITICAL: Initialize notification service first
      await notificationService.initialize();
      print('✅ Background: Services initialized');

      // Check and update expired tasks
      final expiredTasksMap = await dbHelper.checkAndUpdateExpiredTasks();
      final missedTasks = expiredTasksMap['missed'] ?? [];
      final rescheduledTasks = expiredTasksMap['rescheduled'] ?? [];

      print('📋 Background: Found ${missedTasks.length} missed, ${rescheduledTasks.length} rescheduled');

      // Send missed notifications
      for (final task in missedTasks) {
        try {
          await notificationService.showMissedTaskNotification(
            id: task.id.hashCode + 10000,
            title: task.title,
            body: task.description.isNotEmpty
                ? task.description
                : 'This task was due at ${_formatDate(task.dueDate)}',
          );
          print('✅ Sent missed notification for: ${task.title}');
        } catch (e) {
          print('❌ Failed to send missed notification: $e');
        }
      }

      // Handle rescheduled tasks
      for (final task in rescheduledTasks) {
        try {
          final repeatType = _getRepeatTypeName(task.repeatRule);

          // Show rescheduled notification
          await notificationService.showTaskRescheduledNotification(
            id: task.id.hashCode + 20000,
            title: task.title,
            newDueDate: task.dueDate,
            repeatType: repeatType,
          );
          print('✅ Sent rescheduled notification for: ${task.title}');

          // Schedule notifications for new task
          await _scheduleTaskNotifications(task, notificationService, dbHelper);
        } catch (e) {
          print('❌ Failed to handle rescheduled task: $e');
        }
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
  try {
    final now = DateTime.now();

    // Only schedule if task is in the future
    if (!task.dueDate.isAfter(now)) {
      print('⚠️ Task ${task.title} is in the past, skipping notification');
      return;
    }

    final notificationTime = task.dueDate.subtract(
      Duration(minutes: task.notificationMinutes),
    );

    // Schedule REMINDER notification
    if (notificationTime.isAfter(now)) {
      await notificationService.scheduleTaskReminder(
        id: task.id.hashCode,
        taskId: task.id,
        title: task.title,
        body: task.description.isNotEmpty ? task.description : 'Due: ${_formatDate(task.dueDate)}',
        scheduledTime: task.dueDate,
        minutesBefore: task.notificationMinutes,
      );
      print('✅ Background: Scheduled REMINDER for ${task.title}');
    }

    // Schedule DUE NOW notification
    if (task.dueDate.isAfter(now)) {
      await notificationService.scheduleTaskDueNow(
        id: task.id.hashCode,
        taskId: task.id,
        title: task.title,
        body: task.description.isNotEmpty ? task.description : 'This task is due right now!',
        dueTime: task.dueDate,
      );
      print('✅ Background: Scheduled DUE NOW for ${task.title}');
    }

    await dbHelper.markNotificationScheduled(task.id);
  } catch (e) {
    print('❌ Error scheduling task notifications in background: $e');
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  print('🚀 Starting Task Manager App...');

  // ⭐ Initialize WorkManager for background tasks
  try {
    await Workmanager().initialize(
      callbackDispatcher,
      isInDebugMode: true, // Set to false in production
    );
    print('✅ WorkManager initialized');

    // ⭐ Register periodic background task (runs every 15 minutes)
    await Workmanager().registerPeriodicTask(
      "task-expiry-check",
      "checkExpiredTasks",
      frequency: const Duration(minutes: 15), // Minimum is 15 minutes
      constraints: Constraints(
        networkType: NetworkType.notRequired,
        requiresBatteryNotLow: false,
        requiresCharging: false,
        requiresDeviceIdle: false,
        requiresStorageNotLow: false,
      ),
      existingWorkPolicy: ExistingPeriodicWorkPolicy.replace, // Replace if already exists
    );
    print('✅ WorkManager periodic task registered (every 15 minutes)');
  } catch (e) {
    print('❌ WorkManager initialization error: $e');
  }

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

    // ⭐ Set up notification action callback
    NotificationService.onNotificationAction = _handleNotificationAction;
  }

  // ⭐ Handle notification actions (Complete/Snooze) from anywhere in app
  void _handleNotificationAction(String taskId, String action) {
    print('📨 App received notification action: $action for task: $taskId');
    // The notification service already handled the database updates,
    // this callback is for app-level UI updates or analytics

    // Show a confirmation message
    if (mounted) {
      final message = action == 'complete'
          ? 'Task marked as complete!'
          : 'Task snoozed for 10 minutes';

      // You could show a SnackBar here if you have access to BuildContext
      print('✅ $message');
    }
  }

  Future<void> _initializeApp() async {
    try {
      print('🔧 Initializing app...');

      // ⭐ STEP 1: Request permissions
      await _requestPermissions();

      // ⭐ STEP 2: Initialize notification service
      try {
        await _notificationService.initialize();
        print('✅ Notification service initialized');
      } catch (e) {
        print('❌ Notification service initialization failed: $e');
        // Continue even if notifications fail
      }

      // ⭐ STEP 3: Load theme
      await _themeManager.loadTheme();
      print('✅ Theme loaded');

      // ⭐ STEP 4: Check if setup completed
      _hasCompletedSetup = await _dbHelper.hasCompletedSetup();
      print('✅ Setup status: $_hasCompletedSetup');

      // ⭐ STEP 5: Check expired tasks immediately on app start
      await _checkExpiredTasks();

      // ⭐ STEP 6: Schedule all pending notifications
      await _scheduleAllPendingNotifications();

      setState(() {
        _isLoading = false;
      });

      print('✅ App initialization complete');
    } catch (e) {
      print('❌ App initialization error: $e');
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  // ⭐ IMPROVED: Request all necessary permissions
  Future<void> _requestPermissions() async {
    if (!Platform.isAndroid) return;

    try {
      final DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
      final AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;

      print('📱 Device: ${androidInfo.brand} ${androidInfo.model}');
      print('📱 Android SDK: ${androidInfo.version.sdkInt}');

      // ⭐ Notification permission (Android 13+)
      if (androidInfo.version.sdkInt >= 33) {
        final PermissionStatus status = await Permission.notification.request();
        print('🔔 Notification permission: $status');

        if (!status.isGranted) {
          print('⚠️ WARNING: Notification permission denied!');
          _showPermissionDialog('Notifications',
              'This app needs notification permission to remind you about tasks.');
        }
      }

      // ⭐ Exact Alarm permission (Android 12+)
      if (androidInfo.version.sdkInt >= 31) {
        final alarmStatus = await Permission.scheduleExactAlarm.status;
        print('⏰ Exact Alarm permission: $alarmStatus');

        if (!alarmStatus.isGranted) {
          print('⚠️ WARNING: Exact alarm permission not granted!');
          await Permission.scheduleExactAlarm.request();
        }
      }

      // ⭐ Ignore battery optimization (for background tasks)
      if (androidInfo.version.sdkInt >= 23) {
        final ignoreBatteryStatus = await Permission.ignoreBatteryOptimizations.status;
        print('🔋 Battery optimization: $ignoreBatteryStatus');

        if (!ignoreBatteryStatus.isGranted) {
          print('⚠️ Battery optimization not disabled. Background tasks may be affected.');
          // Don't force this, just log it
        }
      }

      print('✅ Permission checks complete');
    } catch (e) {
      print('❌ Permission request error: $e');
    }
  }

  void _showPermissionDialog(String permissionName, String reason) {
    // Show a dialog explaining why permission is needed
    // This is just a placeholder - implement if needed
    print('ℹ️ Should show permission dialog for: $permissionName');
  }

  // ⭐ Check expired tasks and handle notifications
  Future<void> _checkExpiredTasks() async {
    print('🔍 Checking for expired tasks...');

    try {
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
        await _scheduleTaskNotifications(
          task,
          _notificationService,
          _dbHelper,
        );
      }

      print('✅ Expired tasks check complete');
    } catch (e) {
      print('❌ Error checking expired tasks: $e');
    }
  }

  // ⭐ Schedule all pending notifications
  Future<void> _scheduleAllPendingNotifications() async {
    print('📋 Scheduling pending notifications...');

    try {
      final pendingTasks = await _dbHelper.getTasksNeedingNotification();
      print('📋 Tasks needing notifications: ${pendingTasks.length}');

      for (final task in pendingTasks) {
        await _scheduleTaskNotifications(task, _notificationService, _dbHelper);
      }

      // Print pending notifications for debugging
      await _notificationService.printPendingNotifications();

      print('✅ All pending notifications scheduled');
    } catch (e) {
      print('❌ Error scheduling pending notifications: $e');
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} '
        '${date.hour}:${date.minute.toString().padLeft(2, '0')}';
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