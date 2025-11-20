# 📚 **Todo Task Manager App - Complete Documentation**


## 📋 **Table of Contents**

1. [App Overview](#1-app-overview)
2. [Architecture & Structure](#2-architecture--structure)
3. [Setup & Installation](#3-setup--installation)
4. [Core Components](#4-core-components)
5. [Features Documentation](#5-features-documentation)
6. [User Flows & Scenarios](#6-user-flows--scenarios)
7. [API Reference](#7-api-reference)
8. [Background Tasks](#8-background-tasks)
9. [Troubleshooting](#9-troubleshooting)
10. [Code Examples](#10-code-examples)

---

## **1. App Overview**

### **Purpose**
A comprehensive Flutter task management application with smart notifications, background task monitoring, repeat tasks, and theme customization.

### **Key Features**
✅ **Task Management** - Create, edit, delete, and complete tasks  
✅ **Smart Notifications** - Reminder + Due Now notifications with action buttons  
✅ **Background Monitoring** - Auto-detects missed/expired tasks every 15 minutes  
✅ **Repeat Tasks** - Daily, Weekly, Monthly auto-rescheduling  
✅ **Task Status Tracking** - Pending, Completed, Missed, Cancelled  
✅ **Theme Support** - Light/Dark/Auto modes  
✅ **Export Options** - PDF and CSV export  
✅ **Search & Filters** - Today, Completed, Repeated, Missed, All  
✅ **Notification Actions** - Complete or Snooze from notification  
✅ **Debug Tools** - Built-in notification testing screen  

### **Tech Stack**
- **Framework:** Flutter (Dart)
- **Database:** SQLite (sqflite)
- **Notifications:** flutter_local_notifications
- **Background Tasks:** workmanager
- **State Management:** Provider
- **Permissions:** permission_handler

---

## **2. Architecture & Structure**

### **File Organization**

```
lib/
├── main.dart                          # App entry point + background tasks
├── screens/
│   ├── theme_name_screen.dart         # Initial setup (name + theme)
│   ├── dashboard_screen.dart          # Main dashboard with stats
│   ├── manage_screen.dart             # Task list management
│   ├── add_edit_task_screen.dart      # Create/Edit tasks
│   ├── settings_screen.dart           # Settings & exports
│   └── notification_test_screen.dart  # Debug notification testing
└── utils/
    ├── database_helper.dart           # SQLite database operations
    ├── notification_service.dart      # Notification management
    └── theme_manager.dart             # Theme state management

assets/
└── logo.png                           # App logo
```

---

## **3. Setup & Installation**

### **Prerequisites**
- Flutter SDK 3.0+
- Android SDK (API 21+)
- iOS 12+ (for iOS builds)

### **Required Packages**
```yaml
dependencies:
  flutter_local_notifications: ^latest
  timezone: ^latest
  workmanager: ^latest
  sqflite: ^latest
  path_provider: ^latest
  provider: ^latest
  permission_handler: ^latest
  device_info_plus: ^latest
  share_plus: ^latest
  pdf: ^latest
  intl: ^latest
```

### **Android Setup**

**1. AndroidManifest.xml Permissions:**
```xml
<uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED"/>
<uses-permission android:name="android.permission.VIBRATE" />
<uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
<uses-permission android:name="android.permission.SCHEDULE_EXACT_ALARM"/>
<uses-permission android:name="android.permission.USE_EXACT_ALARM"/>
<uses-permission android:name="android.permission.WAKE_LOCK" />
<uses-permission android:name="android.permission.REQUEST_IGNORE_BATTERY_OPTIMIZATIONS"/>
```

**2. Minimum SDK Version (build.gradle):**
```gradle
minSdkVersion 21
targetSdkVersion 34
```

### **iOS Setup**
```xml
<!-- Info.plist -->
<key>UIBackgroundModes</key>
<array>
    <string>fetch</string>
    <string>remote-notification</string>
</array>
```

---

## **4. Core Components**

### **4.1 Database Schema**

#### **Tasks Table:**
```sql
CREATE TABLE tasks(
  id TEXT PRIMARY KEY,
  title TEXT NOT NULL,
  description TEXT,
  due_date INTEGER NOT NULL,
  priority INTEGER NOT NULL,           -- 0=low, 1=medium, 2=high
  repeat_rule INTEGER NOT NULL,        -- 0=none, 1=daily, 2=weekly, 3=monthly
  notification_minutes INTEGER NOT NULL,
  sub_tasks TEXT,
  is_completed INTEGER NOT NULL,
  status INTEGER NOT NULL,             -- 0=pending, 1=completed, 2=missed, 3=cancelled
  created_at INTEGER NOT NULL,
  notification_scheduled INTEGER NOT NULL DEFAULT 0
)
```

#### **App Settings Table:**
```sql
CREATE TABLE app_settings(
  key TEXT PRIMARY KEY,
  value TEXT NOT NULL
)
```

**Stored Settings:**
- `hasCompletedSetup` - Boolean
- `isDarkMode` - Boolean

---

### **4.2 Task Model**

```dart
class Task {
  final String id;
  final String title;
  final String description;
  final DateTime dueDate;
  final Priority priority;           // enum: low, medium, high
  final RepeatRule repeatRule;       // enum: none, daily, weekly, monthly
  final int notificationMinutes;
  final List<String> subTasks;
  bool isCompleted;
  final DateTime createdAt;
  TaskStatus status;                 // enum: pending, completed, missed, cancelled
  bool notificationScheduled;
}
```

---

### **4.3 Notification Types**

| Type | Channel | Priority | When Triggered | Actions |
|------|---------|----------|----------------|---------|
| **Reminder** | `task_reminder_channel` | MAX | X minutes before due | Complete, Snooze |
| **Due Now** | `task_reminder_channel` | MAX | At exact due time | Complete, Snooze |
| **Missed** | `task_missed_channel` | MAX | After task expires | None |
| **Completed** | `task_completed_channel` | DEFAULT | When marked complete | None |
| **Rescheduled** | `task_rescheduled_channel` | HIGH | Repeat task created | None |

---

## **5. Features Documentation**

### **5.1 Task Creation Flow**

```
User opens Add Task Screen
    ↓
Fills: Title, Description, Due Date/Time, Priority, Repeat Rule, Notification Time
    ↓
Taps "Save"
    ↓
Task saved to database (status = pending)
    ↓
Two notifications scheduled:
  - Reminder (X minutes before)
  - Due Now (at exact time)
    ↓
Task appears in dashboard
```

**Code Location:** `add_edit_task_screen.dart` → `_saveTask()`

---

### **5.2 Background Task Monitoring**

**Purpose:** Automatically check for expired tasks even when app is closed.

**How It Works:**
1. **WorkManager** runs every 15 minutes (minimum Android allows)
2. Checks database for tasks where `due_date < current_time` AND `status = pending`
3. **Missed Tasks:** Updates status to `missed` → Sends missed notification
4. **Repeat Tasks:** Creates new task for next occurrence → Sends rescheduled notification

**Code Location:** `main.dart` → `callbackDispatcher()`

**Registration:**
```dart
await Workmanager().registerPeriodicTask(
  "task-expiry-check",
  "checkExpiredTasks",
  frequency: const Duration(minutes: 15),
);
```

---

### **5.3 Notification Actions**

Users can interact with notifications without opening the app:

**1. Complete Button:**
- Marks task as completed in database
- Shows "Task Completed" confirmation notification
- Cancels all remaining notifications for that task
- Updates app UI if open

**2. Snooze Button:**
- Cancels current notification
- Reschedules for 10 minutes later
- Shows "Task Snoozed" confirmation

**Code Location:** `notification_service.dart` → `_handleNotificationAction()`

---

### **5.4 Repeat Task Logic**

When a repeating task expires:

1. **Original task** → Marked as `missed`
2. **New task created** with:
   - Same title, description, priority, repeat rule
   - New due date calculated based on repeat rule
   - New unique ID
   - Status = `pending`
   - Fresh notifications scheduled

**Next Due Date Calculation:**
- **Daily:** `currentDueDate + 1 day`
- **Weekly:** `currentDueDate + 7 days`
- **Monthly:** `currentDueDate + 1 month` (handles month-end edge cases)

**Code Location:** `database_helper.dart` → `checkAndUpdateExpiredTasks()`

---

### **5.5 Dashboard Statistics**

Real-time task counts displayed on dashboard:

| Stat | Query | Description |
|------|-------|-------------|
| **Today's Tasks** | `due_date = today AND status = pending` | Tasks due today not yet completed |
| **Completed Tasks** | `status = completed` | All completed tasks |
| **Repeated Tasks** | `repeat_rule != none` | Tasks with any repeat rule |
| **Missed Tasks** | `status = missed` | Tasks that expired uncompleted |
| **Total Tasks** | All tasks | Complete task count |

**Code Location:** `dashboard_screen.dart` → `_loadDashboardData()`

---

### **5.6 Filters**

Users can filter tasks by:
- **Today** - Pending tasks due today only
- **Completed** - All completed tasks
- **Repeated** - Tasks with repeat rules
- **Missed** - Expired uncompleted tasks
- **All** - Every task in database

**Code Location:** `dashboard_screen.dart` / `manage_screen.dart` → `_applyFilter()`

---

## **6. User Flows & Scenarios**

### **Scenario 1: New User First Launch**

```
App launches
    ↓
No setup completed → Navigate to ThemeNameScreen
    ↓
User enters name + selects theme (Light/Dark)
    ↓
Taps "Continue"
    ↓
Database marks setup complete
    ↓
Navigate to Dashboard
```

---

### **Scenario 2: Creating a Daily Task**

```
User: Create task "Take Vitamins" due today 9:00 AM, Daily repeat, 15-min reminder
    ↓
System: Saves task (status = pending)
    ↓
System: Schedules notifications:
  - Reminder at 8:45 AM
  - Due Now at 9:00 AM
    ↓
[9:00 AM] Due Now notification fires
    ↓
User: Taps "Complete" button on notification
    ↓
System: 
  - Marks task as completed
  - Shows completion notification
  - Cancels remaining notifications
  - Creates NEW task for tomorrow 9:00 AM
  - Schedules notifications for new task
```

---

### **Scenario 3: Missed Task Handling**

```
Task: "Meeting" due today 2:00 PM, status = pending
    ↓
User ignores/misses both notifications
    ↓
[2:00 PM passes]
    ↓
Background task runs (or app reopens)
    ↓
System detects: current_time > due_date AND status = pending
    ↓
System:
  - Updates task status to missed
  - Shows "Missed" notification
  - Logs in missed tasks list
```

---

### **Scenario 4: Snoozing a Task**

```
[Reminder notification fires]
    ↓
User taps "Snooze 10min" button
    ↓
System:
  - Cancels current notifications
  - Reschedules for current_time + 10 minutes
  - Shows "Task Snoozed" confirmation
    ↓
[10 minutes later]
    ↓
Rescheduled notification fires with same actions
```

---

## **7. API Reference**

### **7.1 DatabaseHelper Methods**

```dart
// Task Operations
Future<int> insertTask(Task task)
Future<List<Task>> getAllTasks()
Future<List<Task>> getTasksByFilter(String filter)
Future<int> updateTask(Task task)
Future<int> deleteTask(String id)
Future<int> toggleTaskCompletion(String id, bool isCompleted)

// Expiry Management
Future<Map<String, List<Task>>> checkAndUpdateExpiredTasks()
Future<List<Task>> getExpiredTasks()
Future<List<Task>> getTasksNeedingNotification()
Future<void> markNotificationScheduled(String taskId)

// Settings
Future<bool> hasCompletedSetup()
Future<void> markSetupCompleted()
Future<void> saveTheme(bool isDarkMode)
Future<bool> loadTheme()
```

---

### **7.2 NotificationService Methods**

```dart
// Initialization
Future<void> initialize()
bool get isInitialized

// Scheduling
Future<void> scheduleTaskReminder({
  required int id,
  required String taskId,
  required String title,
  required String body,
  required DateTime scheduledTime,
  required int minutesBefore,
})

Future<void> scheduleTaskDueNow({
  required int id,
  required String taskId,
  required String title,
  required String body,
  required DateTime dueTime,
})

// Immediate Notifications
Future<void> showMissedTaskNotification({
  required int id,
  required String title,
  required String body,
})

Future<void> showTaskCompletedNotification({
  required int id,
  required String title,
  String? body,
})

Future<void> showTaskRescheduledNotification({
  required int id,
  required String title,
  required DateTime newDueDate,
  required String repeatType,
})

Future<void> showImmediateNotification({
  required int id,
  required String title,
  required String body,
})

// Management
Future<void> cancelTaskNotifications(int baseId)
Future<void> cancelNotification(int id)
Future<void> cancelAllNotifications()
Future<void> printPendingNotifications()

// Callback for action handling
static Function(String taskId, String action)? onNotificationAction
```

---

### **7.3 ThemeManager Methods**

```dart
bool get isDarkMode
ThemeMode get currentTheme

Future<void> loadTheme()
Future<void> toggleTheme(bool isDark)
```

---

## **8. Background Tasks**

### **8.1 WorkManager Configuration**

```dart
// Initialization (main.dart)
await Workmanager().initialize(
  callbackDispatcher,
  isInDebugMode: true,  // Set false in production
);

// Register periodic task
await Workmanager().registerPeriodicTask(
  "task-expiry-check",
  "checkExpiredTasks",
  frequency: const Duration(minutes: 15),
  constraints: Constraints(
    networkType: NetworkType.not_required,
    requiresBatteryNotLow: false,
    requiresCharging: false,
  ),
);
```

### **8.2 Background Task Flow**

```
[Every 15 minutes]
    ↓
callbackDispatcher() runs in isolated context
    ↓
Initialize DatabaseHelper & NotificationService
    ↓
Call checkAndUpdateExpiredTasks()
    ↓
For each missed task:
  - Send missed notification
    ↓
For each rescheduled task:
  - Send rescheduled notification
  - Schedule new notifications
    ↓
Task complete → Return success
```

---

## **9. Troubleshooting**

### **Common Issues & Solutions**

#### **Issue 1: Notifications Not Appearing**

**Solutions:**
1. Check permissions in Settings → Apps → Todo App:
   - ✅ Notifications enabled
   - ✅ Allow exact alarms (Android 12+)
   
2. **TECNO/Infinix/Oppo Devices:**
   ```
   Settings → Apps → Todo App
   - Enable "Autostart"
   - Enable "Display pop-up windows"
   - Battery → Unrestricted
   ```

3. Use **Notification Test Screen** (Settings → Test Notifications)

---

#### **Issue 2: Background Tasks Not Running**

**Check:**
- Battery optimization disabled
- App not in "Restricted" background mode
- WorkManager initialized properly

**Debug:**
```dart
// Add logs in callbackDispatcher()
print('🔄 Background task started: ${DateTime.now()}');
```

---

#### **Issue 3: Repeat Tasks Not Creating**

**Verify:**
1. Task has `repeatRule != RepeatRule.none`
2. Background task is running
3. Check logs for `checkAndUpdateExpiredTasks()`

---

### **9.2 Debug Tools**

**Notification Test Screen** (Built-in):
- Check permissions
- Test immediate notifications
- Test scheduled notifications (10 seconds)
- View pending notifications
- Cancel all notifications

**Access:** Settings → 🔔 Test Notifications (Debug)

---

## **10. Code Examples**

### **Example 1: Creating a Task Programmatically**

```dart
final task = Task(
  id: DateTime.now().millisecondsSinceEpoch.toString(),
  title: 'Team Meeting',
  description: 'Discuss Q4 targets',
  dueDate: DateTime.now().add(const Duration(hours: 2)),
  priority: Priority.high,
  repeatRule: RepeatRule.none,
  notificationMinutes: 15,
  subTasks: ['Prepare slides', 'Send agenda'],
  isCompleted: false,
  createdAt: DateTime.now(),
  status: TaskStatus.pending,
  notificationScheduled: false,
);

await DatabaseHelper().insertTask(task);

// Schedule notifications
await NotificationService().scheduleTaskReminder(
  id: task.id.hashCode,
  taskId: task.id,
  title: task.title,
  body: task.description,
  scheduledTime: task.dueDate,
  minutesBefore: task.notificationMinutes,
);
```

---

### **Example 2: Checking for Expired Tasks Manually**

```dart
final results = await DatabaseHelper().checkAndUpdateExpiredTasks();
final missedTasks = results['missed'] ?? [];
final rescheduledTasks = results['rescheduled'] ?? [];

print('Missed: ${missedTasks.length}');
print('Rescheduled: ${rescheduledTasks.length}');

// Show notifications
for (final task in missedTasks) {
  await NotificationService().showMissedTaskNotification(
    id: task.id.hashCode,
    title: task.title,
    body: task.description,
  );
}
```

---

### **Example 3: Filtering Tasks**

```dart
// Get today's pending tasks
final now = DateTime.now();
final startOfDay = DateTime(now.year, now.month, now.day);
final endOfDay = startOfDay.add(const Duration(days: 1));

final allTasks = await DatabaseHelper().getAllTasks();
final todayTasks = allTasks.where((task) {
  return task.dueDate.isAfter(startOfDay) &&
         task.dueDate.isBefore(endOfDay) &&
         task.status == TaskStatus.pending;
}).toList();

print('Today\'s tasks: ${todayTasks.length}');
```

---

## **📊 Summary**

### **App Flow Diagram**

```
App Launch
    ↓
Check Setup → [No] → ThemeNameScreen → Dashboard
    ↓          [Yes] ↓
Request Permissions
    ↓
Initialize Services (Database, Notifications, WorkManager)
    ↓
Check Expired Tasks
    ↓
Schedule Pending Notifications
    ↓
Dashboard Ready
    ↓
[Background: WorkManager checks every 15 min]
```

---

### **Key Numbers**
- **Screens:** 6 (Theme, Dashboard, Manage, Add/Edit, Settings, Notification Test)
- **Database Tables:** 2 (tasks, app_settings)
- **Notification Types:** 5 (Reminder, Due Now, Missed, Completed, Rescheduled)
- **Background Frequency:** Every 15 minutes
- **Task Statuses:** 4 (Pending, Completed, Missed, Cancelled)
- **Repeat Rules:** 4 (None, Daily, Weekly, Monthly)
- **Priority Levels:** 3 (Low, Medium, High)






## 📱 App Screenshots

<p float="left">
  <img src="https://github.com/user-attachments/assets/f8b666fe-85f1-4fbf-9d80-43dd5488157e" width="120" />
  <img src="https://github.com/user-attachments/assets/55573e3d-5329-49d9-8fd0-290cde588caa" width="120" />
  <img src="https://github.com/user-attachments/assets/bf940abe-1ecd-4d3b-8207-250d362ce1b9" width="120" />
  <img src="https://github.com/user-attachments/assets/2687255c-f4f3-4053-8fdc-5b9470cbbb69" width="120" />
  <img src="https://github.com/user-attachments/assets/9390a502-1bdd-4b18-98b6-9689ed2b8cc9" width="120" />
</p>

<p float="left">
  <img src="https://github.com/user-attachments/assets/07a48774-0528-40ff-84b2-e742a56b5093" width="120" />
  <img src="https://github.com/user-attachments/assets/f750ef69-7b9a-4623-98dc-d5cadcd8f041" width="120" />
  <img src="https://github.com/user-attachments/assets/fa2c57a0-9cc4-4725-8535-06ce2169e5e0" width="120" />
  <img src="https://github.com/user-attachments/assets/6e41cac5-d012-4f85-b57b-f836dfd73c48" width="120" />
  <img src="https://github.com/user-attachments/assets/f67b88b7-f955-4c07-adc1-b8846ccd4de9" width="120" />
</p>

<p float="left">
  <img src="https://github.com/user-attachments/assets/056e885a-0f3f-4539-a64d-31489d1cb30b" width="120" />
  <img src="https://github.com/user-attachments/assets/6de49e30-1635-442d-bdfb-1bae9e3f7150" width="120" />
  <img src="https://github.com/user-attachments/assets/c5b28c27-545d-48fa-8dfc-eed3394f7164" width="120" />
  <img src="https://github.com/user-attachments/assets/8fb1c788-79c2-4a37-a4f3-330bf9582aaf" width="120" />
  <img src="https://github.com/user-attachments/assets/ce304794-7ab2-47e2-94d4-e24682c0cad7" width="120" />
</p>

<p float="left">
  <img src="https://github.com/user-attachments/assets/c674382d-972e-487b-9b72-d28602408795" width="120" />
  <img src="https://github.com/user-attachments/assets/b8788e54-0d7d-412e-ab1b-dd40807628bb" width="120" />
  <img src="https://github.com/user-attachments/assets/5891487f-9152-4b7e-831a-5192e7dc23b0" width="120" />
  <img src="https://github.com/user-attachments/assets/69432d10-4998-4df4-8fa5-b47900247595" width="120" />
  <img src="https://github.com/user-attachments/assets/9f27c63e-7b91-44d3-af2c-7a4ff41be92a" width="120" />
</p>
