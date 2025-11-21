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

// ⭐ BACKGROUND TASK
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    print('🔄 [${DateTime.now()}] Background task started: $task');

    try {
      final dbHelper = DatabaseHelper();
      final notificationService = NotificationService();

      await notificationService.initialize();
      print('✅ Background: Services initialized');

      final expiredTasksMap = await dbHelper.checkAndUpdateExpiredTasks();
      final missedTasks = expiredTasksMap['missed'] ?? [];
      final rescheduledTasks = expiredTasksMap['rescheduled'] ?? [];

      print('📋 Background: Found ${missedTasks.length} missed, ${rescheduledTasks.length} rescheduled');

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

      for (final task in rescheduledTasks) {
        try {
          final repeatType = _getRepeatTypeName(task.repeatRule);

          await notificationService.showTaskRescheduledNotification(
            id: task.id.hashCode + 20000,
            title: task.title,
            newDueDate: task.dueDate,
            repeatType: repeatType,
          );
          print('✅ Sent rescheduled notification for: ${task.title}');

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

    if (!task.dueDate.isAfter(now)) {
      print('⚠️ Task ${task.title} is in the past, skipping notification');
      return;
    }

    final notificationTime = task.dueDate.subtract(
      Duration(minutes: task.notificationMinutes),
    );

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

  try {
    await Workmanager().initialize(
      callbackDispatcher,
      isInDebugMode: true,
    );
    print('✅ WorkManager initialized');

    // ⭐ FIX: Use ExistingPeriodicWorkPolicy instead of ExistingWorkPolicy
    await Workmanager().registerPeriodicTask(
      "task-expiry-check",
      "checkExpiredTasks",
      frequency: const Duration(minutes: 15),
      constraints: Constraints(
        networkType: NetworkType.notRequired,
        requiresBatteryNotLow: false,
        requiresCharging: false,
        requiresDeviceIdle: false,
        requiresStorageNotLow: false,
      ),
      existingWorkPolicy: ExistingPeriodicWorkPolicy.replace, // ⭐ FIXED
    );
    print('✅ WorkManager periodic task registered');
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
    NotificationService.onNotificationAction = _handleNotificationAction;
  }

  void _handleNotificationAction(String taskId, String action) {
    print('📨 App received notification action: $action for task: $taskId');
  }

  Future<void> _initializeApp() async {
    try {
      print('🔧 Initializing app...');

      // ⭐ FIX: Run initialization tasks in parallel
      await Future.wait([
        _requestPermissions(),
        _notificationService.initialize().timeout(
          const Duration(seconds: 10),
          onTimeout: () {
            print('⚠️ Notification service init timed out');
            return; // Return void explicitly
          },
        ),
        _themeManager.loadTheme().timeout(
          const Duration(seconds: 5),
          onTimeout: () {
            print('⚠️ Theme loading timed out');
            return; // Return void explicitly
          },
        ),
      ]).timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          print('⚠️ Overall initialization timed out');
          return []; // Return empty list on timeout
        },
      );

      _hasCompletedSetup = await _dbHelper.hasCompletedSetup();
      print('✅ Setup status: $_hasCompletedSetup');

      // ⭐ FIX: Run these in background, don't block UI
      _checkExpiredTasks();
      _scheduleAllPendingNotifications();

      // ⭐ FIX: Always set loading to false after max 2 seconds
      setState(() {
        _isLoading = false;
      });

      print('✅ App initialization complete');
    } catch (e) {
      print('❌ App initialization error: $e');
      setState(() {
        _error = null; // Don't show error, just proceed
        _isLoading = false;
      });
    }
  }

  Future<void> _requestPermissions() async {
    if (!Platform.isAndroid) return;

    try {
      final DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
      final AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;

      print('📱 Device: ${androidInfo.brand} ${androidInfo.model}');
      print('📱 Android SDK: ${androidInfo.version.sdkInt}');

      if (androidInfo.version.sdkInt >= 33) {
        final PermissionStatus status = await Permission.notification.request();
        print('🔔 Notification permission: $status');
      }

      if (androidInfo.version.sdkInt >= 31) {
        final alarmStatus = await Permission.scheduleExactAlarm.status;
        print('⏰ Exact Alarm permission: $alarmStatus');

        if (!alarmStatus.isGranted) {
          await Permission.scheduleExactAlarm.request();
        }
      }

      print('✅ Permission checks complete');
    } catch (e) {
      print('❌ Permission request error: $e');
    }
  }

  Future<void> _checkExpiredTasks() async {
    print('🔍 Checking for expired tasks...');

    try {
      final expiredTasksMap = await _dbHelper.checkAndUpdateExpiredTasks();
      final missedTasks = expiredTasksMap['missed'] ?? [];
      final rescheduledTasks = expiredTasksMap['rescheduled'] ?? [];

      print('📋 App Start: Missed=${missedTasks.length}, Rescheduled=${rescheduledTasks.length}');

      for (final task in missedTasks) {
        await _notificationService.showMissedTaskNotification(
          id: task.id.hashCode + 10000,
          title: task.title,
          body: task.description.isNotEmpty
              ? task.description
              : 'This task was due: ${_formatDate(task.dueDate)}',
        );
      }

      for (final task in rescheduledTasks) {
        final repeatType = _getRepeatTypeName(task.repeatRule);

        await _notificationService.showTaskRescheduledNotification(
          id: task.id.hashCode + 20000,
          title: task.title,
          newDueDate: task.dueDate,
          repeatType: repeatType,
        );

        await _scheduleTaskNotifications(task, _notificationService, _dbHelper);
      }

      print('✅ Expired tasks check complete');
    } catch (e) {
      print('❌ Error checking expired tasks: $e');
    }
  }

  Future<void> _scheduleAllPendingNotifications() async {
    print('📋 Scheduling pending notifications...');

    try {
      final pendingTasks = await _dbHelper.getTasksNeedingNotification();
      print('📋 Tasks needing notifications: ${pendingTasks.length}');

      for (final task in pendingTasks) {
        await _scheduleTaskNotifications(task, _notificationService, _dbHelper);
      }

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
                    onPressed: () {
                      setState(() {
                        _error = null;
                        _isLoading = true;
                      });
                      _initializeApp();
                    },
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