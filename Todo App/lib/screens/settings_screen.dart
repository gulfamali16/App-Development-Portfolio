import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart' as pdf;
import 'package:path/path.dart' as p;
import 'package:intl/intl.dart';
import 'package:sqflite/sqflite.dart';
import '../utils/theme_manager.dart';
import '../utils/database_helper.dart';
import '../utils/notification_service.dart';
import 'notification_test_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _selectedTheme = 'dark';
  bool _enableNotifications = true;
  final String _reminderTime = '9:00 AM';
  final String _appVersion = '1.2.3';

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFF19E619),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Future<void> _handleLocalBackup() async {
    try {
      final dbFolder = await getDatabasesPath();
      final dbFile = File(p.join(dbFolder, 'task_manager.db'));

      if (!await dbFile.exists()) {
        _showSnackBar('Error: Database file not found.');
        return;
      }

      final downloadsDir = await getExternalStorageDirectory();
      if (downloadsDir == null) {
        _showSnackBar('Error: Could not access downloads directory.');
        return;
      }

      final timestamp = DateFormat('yyyy-MM-dd_HH-mm-ss').format(DateTime.now());
      final backupFile = File(p.join(downloadsDir.path, 'task_manager_backup_$timestamp.db'));

      await dbFile.copy(backupFile.path);

      _showSnackBar('Backup saved to Downloads folder!');
    } catch (e) {
      _showSnackBar('Error creating backup: $e');
    }
  }

  void _handleCloudUpload() {
    _showSnackBar('Coming in future updates!');
  }

  Future<void> _handleExportPDF() async {
    final tasks = await DatabaseHelper().getAllTasks();
    final pdfDoc = pw.Document();

    pdfDoc.addPage(
      pw.Page(
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Header(level: 0, text: 'Tasks Report'),
              pw.TableHelper.fromTextArray(
                headerDecoration: const pw.BoxDecoration(
                  color: pdf.PdfColors.grey300,
                ),
                headerHeight: 25,
                cellHeight: 40,
                cellAlignments: {
                  0: pw.Alignment.centerLeft,
                  1: pw.Alignment.centerLeft,
                  2: pw.Alignment.center,
                  3: pw.Alignment.center,
                },
                headers: ['Title', 'Description', 'Due Date', 'Status'],
                data: tasks
                    .map((task) => [
                  task.title,
                  task.description,
                  task.dueDate.toIso8601String().substring(0, 10),
                  task.status.toString().split('.').last,
                ])
                    .toList(),
              ),
            ],
          );
        },
      ),
    );

    final output = await getTemporaryDirectory();
    final file = File(p.join(output.path, "tasks.pdf"));
    await file.writeAsBytes(await pdfDoc.save());
    await Share.shareXFiles([XFile(file.path)], text: 'Your tasks PDF report.');
  }

  Future<void> _handleExportCSV() async {
    final tasks = await DatabaseHelper().getAllTasks();
    String csv = 'Title,Description,DueDate,Status\n';
    for (var task in tasks) {
      csv += '"${task.title}","${task.description}","${task.dueDate.toIso8601String()}","${task.status.toString().split('.').last}"\n';
    }

    final output = await getTemporaryDirectory();
    final file = File(p.join(output.path, "tasks.csv"));
    await file.writeAsString(csv);
    await Share.shareXFiles([XFile(file.path)], text: 'Your tasks CSV report.');
  }

  void _handleAboutApp() {
    showDialog(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        backgroundColor: Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFF244724)
            : Colors.white,
        title: Text(
          'About App',
          style: TextStyle(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.white
                : Colors.black,
          ),
        ),
        content: Text(
          'Task Manager App\nVersion $_appVersion\n\nA beautiful and efficient task management application to help you stay organized and productive.',
          style: TextStyle(
            color: Theme.of(context).brightness == Brightness.dark
                ? const Color(0xFF93C893)
                : Colors.grey[700],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  // ⭐ NEW: Reset All Data
  void _handleResetAllData() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;

        return AlertDialog(
          backgroundColor: isDark ? const Color(0xFF244724) : Colors.white,
          title: Row(
            children: [
              const Icon(Icons.warning, color: Colors.red, size: 28),
              const SizedBox(width: 12),
              Text(
                'Reset All Data?',
                style: TextStyle(
                  color: isDark ? Colors.white : Colors.black,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: Text(
            'This will delete:\n\n'
                '• All tasks (pending, completed, missed)\n'
                '• All notifications\n'
                '• All settings\n'
                '• App will restart\n\n'
                'This action CANNOT be undone!',
            style: TextStyle(
              color: isDark ? const Color(0xFF93C893) : Colors.grey[700],
              fontSize: 16,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
                await _performReset();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Reset Everything'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _performReset() async {
    try {
      // Show loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(color: Color(0xFF19E619)),
        ),
      );

      // 1. Cancel all notifications
      await NotificationService().cancelAllNotifications();
      print('✅ Cancelled all notifications');

      // 2. Delete database
      final dbFolder = await getDatabasesPath();
      final dbPath = p.join(dbFolder, 'task_manager.db');
      final dbFile = File(dbPath);

      if (await dbFile.exists()) {
        await dbFile.delete();
        print('✅ Deleted database');
      }

      // 3. Clear all shared preferences/settings
      final db = await DatabaseHelper().database;
      await db.execute('DELETE FROM app_settings');
      print('✅ Cleared settings');

      // Wait a moment
      await Future.delayed(const Duration(seconds: 1));

      // Close loading dialog
      if (mounted) {
        Navigator.pop(context);

        // Show success message
        _showSnackBar('✅ All data reset! Restarting app...');

        // Wait and restart
        await Future.delayed(const Duration(seconds: 2));

        // Navigate to setup screen
        if (mounted) {
          Navigator.pushNamedAndRemoveUntil(
            context,
            '/theme',
                (route) => false,
          );
        }
      }
    } catch (e) {
      print('❌ Reset error: $e');
      if (mounted) {
        Navigator.pop(context);
        _showSnackBar('Error resetting data: $e');
      }
    }
  }

  void _openNotificationTest() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const NotificationTestScreen(),
      ),
    );
  }

  void _setTheme(String theme) async {
    final themeManager = Provider.of<ThemeManager>(context, listen: false);

    setState(() {
      _selectedTheme = theme;
    });

    if (theme == 'light') {
      await themeManager.toggleTheme(false);
    } else if (theme == 'dark') {
      await themeManager.toggleTheme(true);
    } else {
      await themeManager.toggleTheme(false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeManager = Provider.of<ThemeManager>(context);
    final isDark = themeManager.isDarkMode;
    final bgColor = isDark ? const Color(0xFF112211) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black;
    final borderColor = isDark ? const Color(0xFF346534) : Colors.grey[400]!;
    final selectedBorderColor = const Color(0xFF19E619);

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Column(
          children: [
            // ⭐ REMOVED BACK BUTTON - Only title now
            Container(
              color: bgColor,
              padding: const EdgeInsets.all(16).copyWith(bottom: 8),
              child: Center(
                child: Text(
                  "Settings",
                  style: TextStyle(
                    color: textColor,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionHeader("Theme Settings", textColor: textColor),

                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Wrap(
                        spacing: 12,
                        children: [
                          _buildThemeOption("Light", "light",
                              isSelected: _selectedTheme == "light",
                              textColor: textColor,
                              borderColor: borderColor,
                              selectedBorderColor: selectedBorderColor),
                          _buildThemeOption("Dark", "dark",
                              isSelected: _selectedTheme == "dark",
                              textColor: textColor,
                              borderColor: borderColor,
                              selectedBorderColor: selectedBorderColor),
                          _buildThemeOption("Auto", "auto",
                              isSelected: _selectedTheme == "auto",
                              textColor: textColor,
                              borderColor: borderColor,
                              selectedBorderColor: selectedBorderColor),
                        ],
                      ),
                    ),

                    _buildSectionHeader("Data & Backup", textColor: textColor),
                    _buildSettingItem(
                      title: "Export as PDF",
                      textColor: textColor,
                      onTap: _handleExportPDF,
                    ),
                    _buildSettingItem(
                      title: "Export as CSV",
                      textColor: textColor,
                      onTap: _handleExportCSV,
                    ),
                    _buildSettingItem(
                      title: "Create Local Backup",
                      textColor: textColor,
                      onTap: _handleLocalBackup,
                    ),
                    _buildSettingItem(
                      title: "Upload to Drive",
                      textColor: textColor,
                      onTap: _handleCloudUpload,
                    ),

                    _buildSectionHeader(
                      "Notification Settings",
                      textColor: textColor,
                    ),

                    _buildSettingItem(
                      title: "🔔 Test Notifications (Debug)",
                      textColor: textColor,
                      onTap: _openNotificationTest,
                      icon: Icons.bug_report,
                    ),

                    _buildToggleSettingItem(
                      title: "Enable app notifications",
                      textColor: textColor,
                      value: _enableNotifications,
                      onChanged: (value) =>
                          setState(() => _enableNotifications = value),
                    ),
                    _buildValueSettingItem(
                        title: "Default reminder time",
                        textColor: textColor,
                        value: _reminderTime),

                    // ⭐ NEW: Danger Zone Section
                    _buildSectionHeader("Danger Zone", textColor: Colors.red),

                    _buildSettingItem(
                      title: "🗑️ Reset All Data",
                      textColor: Colors.red,
                      onTap: _handleResetAllData,
                      icon: Icons.delete_forever,
                    ),

                    _buildSectionHeader(
                      "App Info",
                      textColor: textColor,
                    ),
                    _buildSettingItem(
                        title: "About app",
                        textColor: textColor,
                        onTap: _handleAboutApp),
                    _buildValueSettingItem(
                        title: "Version",
                        textColor: textColor,
                        value: _appVersion),

                    const SizedBox(height: 80), // Extra space for bottom nav
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, {required Color textColor}) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
      child: Text(title,
          style: TextStyle(
              color: textColor, fontSize: 22, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildThemeOption(String label, String value,
      {required bool isSelected,
        required Color textColor,
        required Color borderColor,
        required Color selectedBorderColor}) {
    return GestureDetector(
      onTap: () => _setTheme(value),
      child: Container(
        height: 44,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: isSelected ? selectedBorderColor : borderColor,
              width: isSelected ? 3 : 1),
        ),
        child: Center(
          child: Text(label,
              style:
              TextStyle(color: textColor, fontWeight: FontWeight.w500)),
        ),
      ),
    );
  }

  Widget _buildSettingItem({
    required String title,
    required Color textColor,
    required VoidCallback onTap,
    IconData? icon,
  }) {
    return ListTile(
      leading: icon != null ? Icon(icon, color: textColor) : null,
      title: Text(title, style: TextStyle(color: textColor)),
      trailing: Icon(Icons.arrow_forward_ios, color: textColor, size: 16),
      onTap: onTap,
    );
  }

  Widget _buildToggleSettingItem({
    required String title,
    required Color textColor,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return ListTile(
      title: Text(title, style: TextStyle(color: textColor)),
      trailing: Switch(value: value, onChanged: onChanged),
    );
  }

  Widget _buildValueSettingItem({
    required String title,
    required Color textColor,
    required String value,
  }) {
    return ListTile(
      title: Text(title, style: TextStyle(color: textColor)),
      trailing: Text(value, style: TextStyle(color: textColor)),
    );
  }
}