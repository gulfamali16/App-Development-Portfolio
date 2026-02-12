import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import '../utils/notification_service.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'dart:io';

class NotificationTestScreen extends StatefulWidget {
  const NotificationTestScreen({super.key});

  @override
  State<NotificationTestScreen> createState() => _NotificationTestScreenState();
}

class _NotificationTestScreenState extends State<NotificationTestScreen> {
  final NotificationService _notificationService = NotificationService();
  String _statusLog = '';
  bool _isInitialized = false;
  String _deviceInfo = '';

  @override
  void initState() {
    super.initState();
    _loadDeviceInfo();
    _checkInitialization();
  }

  Future<void> _loadDeviceInfo() async {
    if (Platform.isAndroid) {
      final deviceInfo = DeviceInfoPlugin();
      final androidInfo = await deviceInfo.androidInfo;
      setState(() {
        _deviceInfo = '''
Device: ${androidInfo.brand} ${androidInfo.model}
Android Version: ${androidInfo.version.release} (SDK ${androidInfo.version.sdkInt})
Manufacturer: ${androidInfo.manufacturer}
''';
      });
    }
  }

  void _addLog(String message) {
    setState(() {
      final timestamp = DateTime.now().toString().substring(11, 19);
      _statusLog += '[$timestamp] $message\n';
    });
    print(message);
  }

  Future<void> _checkInitialization() async {
    _isInitialized = _notificationService.isInitialized;
    _addLog('Notification Service Initialized: $_isInitialized');
  }

  // Test 1: Check Notification Permission
  Future<void> _testNotificationPermission() async {
    _addLog('--- TEST 1: Checking Notification Permission ---');

    final status = await Permission.notification.status;
    _addLog('Current Permission Status: $status');

    if (status.isDenied) {
      _addLog('Permission is DENIED. Requesting...');
      final result = await Permission.notification.request();
      _addLog('Permission Request Result: $result');
    } else if (status.isPermanentlyDenied) {
      _addLog('⚠️ Permission PERMANENTLY DENIED. Please enable in settings.');
      await openAppSettings();
    } else if (status.isGranted) {
      _addLog('✅ Permission GRANTED');
    }
  }

  // Test 2: Check Exact Alarm Permission (Android 12+)
  Future<void> _testExactAlarmPermission() async {
    _addLog('--- TEST 2: Checking Exact Alarm Permission (Android 12+) ---');

    if (Platform.isAndroid) {
      final deviceInfo = DeviceInfoPlugin();
      final androidInfo = await deviceInfo.androidInfo;

      if (androidInfo.version.sdkInt >= 31) {
        final status = await Permission.scheduleExactAlarm.status;
        _addLog('Exact Alarm Permission: $status');

        if (status.isDenied) {
          _addLog('Exact Alarm Permission DENIED. Requesting...');
          final result = await Permission.scheduleExactAlarm.request();
          _addLog('Request Result: $result');
        } else if (status.isGranted) {
          _addLog('✅ Exact Alarm Permission GRANTED');
        }
      } else {
        _addLog('ℹ️ Android version < 12, exact alarm permission not required');
      }
    }
  }

  // Test 3: Initialize Notification Service
  Future<void> _testInitialization() async {
    _addLog('--- TEST 3: Initializing Notification Service ---');

    try {
      await _notificationService.initialize();
      _isInitialized = _notificationService.isInitialized;
      _addLog('✅ Notification Service Initialized: $_isInitialized');
    } catch (e) {
      _addLog('❌ Initialization Error: $e');
    }
  }

  // Test 4: Send Immediate Notification
  Future<void> _testImmediateNotification() async {
    _addLog('--- TEST 4: Sending Immediate Notification ---');

    if (!_isInitialized) {
      _addLog('⚠️ Service not initialized. Initializing first...');
      await _testInitialization();
    }

    try {
      await _notificationService.showImmediateNotification(
        id: 999,
        title: 'Test Notification',
        body: 'This is an immediate test notification!',
      );
      _addLog('✅ Immediate notification sent (ID: 999)');
    } catch (e) {
      _addLog('❌ Error sending immediate notification: $e');
    }
  }

  // Test 5: Schedule Notification (10 seconds)
  Future<void> _testScheduledNotification() async {
    _addLog('--- TEST 5: Scheduling Notification (10 seconds) ---');

    if (!_isInitialized) {
      _addLog('⚠️ Service not initialized. Initializing first...');
      await _testInitialization();
    }

    try {
      final scheduledTime = DateTime.now().add(const Duration(seconds: 10));
      _addLog('Scheduled Time: $scheduledTime');

      await _notificationService.scheduleTaskReminder(
        id: 888,
        taskId: 'test_task_888', // Add taskId parameter
        title: 'Scheduled Test',
        body: 'This notification was scheduled 10 seconds ago',
        scheduledTime: scheduledTime,
        minutesBefore: 0, // No offset, exact time
      );

      _addLog('✅ Notification scheduled for 10 seconds from now (ID: 888)');
      _addLog('⏳ Wait 10 seconds to see if notification appears...');
    } catch (e) {
      _addLog('❌ Error scheduling notification: $e');
    }
  }

  // Test 6: List Pending Notifications
  Future<void> _testPendingNotifications() async {
    _addLog('--- TEST 6: Checking Pending Notifications ---');

    if (!_isInitialized) {
      _addLog('⚠️ Service not initialized.');
      return;
    }

    try {
      await _notificationService.printPendingNotifications();
      _addLog('✅ Check console/logs for pending notifications list');
    } catch (e) {
      _addLog('❌ Error checking pending notifications: $e');
    }
  }

  // Test 7: Cancel All Notifications
  Future<void> _testCancelAll() async {
    _addLog('--- TEST 7: Canceling All Notifications ---');

    try {
      await _notificationService.cancelAllNotifications();
      _addLog('✅ All notifications canceled');
    } catch (e) {
      _addLog('❌ Error canceling notifications: $e');
    }
  }

  // Run All Tests
  Future<void> _runAllTests() async {
    _statusLog = '';
    _addLog('🚀 Running All Tests...\n');

    await _testNotificationPermission();
    await Future.delayed(const Duration(milliseconds: 500));

    await _testExactAlarmPermission();
    await Future.delayed(const Duration(milliseconds: 500));

    await _testInitialization();
    await Future.delayed(const Duration(milliseconds: 500));

    await _testImmediateNotification();
    await Future.delayed(const Duration(milliseconds: 500));

    await _testPendingNotifications();

    _addLog('\n✅ All tests completed!');
    _addLog('⚠️ IMPORTANT: If immediate notification did not appear,');
    _addLog('check device settings for notification permissions.');
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF112211) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black;
    final cardColor = isDark ? const Color(0xFF244724) : Colors.grey[100]!;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: Text('Notification Test', style: TextStyle(color: textColor)),
        backgroundColor: bgColor,
        iconTheme: IconThemeData(color: textColor),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Device Info Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Device Information',
                    style: TextStyle(
                      color: textColor,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _deviceInfo.isEmpty ? 'Loading...' : _deviceInfo,
                    style: TextStyle(color: textColor, fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Initialized: ${_isInitialized ? "✅ Yes" : "❌ No"}',
                    style: TextStyle(
                      color: _isInitialized ? Colors.green : Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Quick Tests
            Text(
              'Quick Tests',
              style: TextStyle(
                color: textColor,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),

            _buildTestButton(
              'Run All Tests',
              Icons.play_arrow,
              _runAllTests,
              const Color(0xFF19E619),
            ),

            _buildTestButton(
              '1. Check Permissions',
              Icons.security,
              _testNotificationPermission,
              Colors.blue,
            ),

            _buildTestButton(
              '2. Check Exact Alarm',
              Icons.alarm,
              _testExactAlarmPermission,
              Colors.purple,
            ),

            _buildTestButton(
              '3. Initialize Service',
              Icons.settings,
              _testInitialization,
              Colors.orange,
            ),

            _buildTestButton(
              '4. Send Immediate Notification',
              Icons.notifications_active,
              _testImmediateNotification,
              Colors.green,
            ),

            _buildTestButton(
              '5. Schedule in 10 Seconds',
              Icons.schedule,
              _testScheduledNotification,
              Colors.teal,
            ),

            _buildTestButton(
              '6. Check Pending',
              Icons.list,
              _testPendingNotifications,
              Colors.indigo,
            ),

            _buildTestButton(
              '7. Cancel All',
              Icons.cancel,
              _testCancelAll,
              Colors.red,
            ),

            const SizedBox(height: 20),

            // Status Log
            Text(
              'Status Log',
              style: TextStyle(
                color: textColor,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),

            Container(
              width: double.infinity,
              height: 300,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey),
              ),
              child: SingleChildScrollView(
                child: Text(
                  _statusLog.isEmpty ? 'No logs yet. Run tests above.' : _statusLog,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 12,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // TECNO-specific instructions
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.warning, color: Colors.orange),
                      const SizedBox(width: 8),
                      Text(
                        'TECNO Device Instructions',
                        style: TextStyle(
                          color: textColor,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '1. Go to Settings → Apps → Todo App\n'
                        '2. Enable "Autostart"\n'
                        '3. Enable "Display pop-up windows while running in background"\n'
                        '4. Battery → Unrestricted\n'
                        '5. Notifications → Allow all',
                    style: TextStyle(color: textColor, fontSize: 13),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTestButton(String label, IconData icon, VoidCallback onTap, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 20),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}