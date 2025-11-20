import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'dart:async';

// Define enums and Task class FIRST, before DatabaseHelper
enum Priority { low, medium, high }

enum RepeatRule { none, daily, weekly, monthly }

enum TaskStatus {
  pending,    // Task is scheduled but not done
  completed,  // User marked as completed
  missed,     // Time passed and task wasn't completed
  cancelled   // User cancelled the task
}

class Task {
  final String id;
  final String title;
  final String description;
  final DateTime dueDate;
  final Priority priority;
  final RepeatRule repeatRule;
  final int notificationMinutes;
  final List<String> subTasks;
  bool isCompleted;
  final DateTime createdAt;
  TaskStatus status;
  bool notificationScheduled;

  Task({
    required this.id,
    required this.title,
    required this.description,
    required this.dueDate,
    this.priority = Priority.medium,
    this.repeatRule = RepeatRule.none,
    this.notificationMinutes = 15,
    this.subTasks = const [],
    this.isCompleted = false,
    required this.createdAt,
    this.status = TaskStatus.pending,
    this.notificationScheduled = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'due_date': dueDate.millisecondsSinceEpoch,
      'priority': priority.index,
      'repeat_rule': repeatRule.index,
      'notification_minutes': notificationMinutes,
      'sub_tasks': subTasks.join('||'),
      'is_completed': isCompleted ? 1 : 0,
      'status': status.index,
      'created_at': createdAt.millisecondsSinceEpoch,
      'notification_scheduled': notificationScheduled ? 1 : 0,
    };
  }

  factory Task.fromMap(Map<String, dynamic> map) {
    return Task(
      id: map['id'],
      title: map['title'],
      description: map['description'],
      dueDate: DateTime.fromMillisecondsSinceEpoch(map['due_date']),
      priority: Priority.values[map['priority']],
      repeatRule: RepeatRule.values[map['repeat_rule']],
      notificationMinutes: map['notification_minutes'],
      subTasks: (map['sub_tasks'] as String).split('||').where((s) => s.isNotEmpty).toList(),
      isCompleted: map['is_completed'] == 1,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at']),
      status: TaskStatus.values[map.containsKey('status') ? map['status'] : 0],
      notificationScheduled: map.containsKey('notification_scheduled') ? map['notification_scheduled'] == 1 : false,
    );
  }

  // Create a copy of this task with new due date for repeat
  Task copyWithNewDueDate(DateTime newDueDate) {
    return Task(
      id: DateTime.now().millisecondsSinceEpoch.toString(), // New unique ID
      title: title,
      description: description,
      dueDate: newDueDate,
      priority: priority,
      repeatRule: repeatRule,
      notificationMinutes: notificationMinutes,
      subTasks: List.from(subTasks),
      isCompleted: false, // New task is not completed
      createdAt: DateTime.now(),
      status: TaskStatus.pending, // New task is pending
      notificationScheduled: false, // Needs new notification
    );
  }
}

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'task_manager.db');
    return await openDatabase(
      path,
      version: 2,
      onCreate: _createDatabase,
      onUpgrade: _upgradeDatabase,
    );
  }

  Future<void> _createDatabase(Database db, int version) async {
    await db.execute('''
      CREATE TABLE tasks(
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        description TEXT,
        due_date INTEGER NOT NULL,
        priority INTEGER NOT NULL,
        repeat_rule INTEGER NOT NULL,
        notification_minutes INTEGER NOT NULL,
        sub_tasks TEXT,
        is_completed INTEGER NOT NULL,
        status INTEGER NOT NULL,
        created_at INTEGER NOT NULL,
        notification_scheduled INTEGER NOT NULL DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE app_settings(
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL
      )
    ''');
  }

  Future<void> _upgradeDatabase(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('''
        ALTER TABLE tasks ADD COLUMN status INTEGER NOT NULL DEFAULT 0
      ''');
      await db.execute('''
        ALTER TABLE tasks ADD COLUMN notification_scheduled INTEGER NOT NULL DEFAULT 0
      ''');
    }
  }

  // Check if user has completed initial setup
  Future<bool> hasCompletedSetup() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'app_settings',
      where: 'key = ?',
      whereArgs: ['hasCompletedSetup'],
    );

    return maps.isNotEmpty && maps.first['value'] == 'true';
  }

  // Mark initial setup as completed
  Future<void> markSetupCompleted() async {
    final db = await database;
    await db.insert(
      'app_settings',
      {'key': 'hasCompletedSetup', 'value': 'true'},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // Task CRUD Operations
  Future<int> insertTask(Task task) async {
    final db = await database;
    return await db.insert('tasks', task.toMap());
  }

  Future<List<Task>> getAllTasks() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('tasks');
    return List.generate(maps.length, (i) => Task.fromMap(maps[i]));
  }

  Future<List<Task>> getTasksByFilter(String filter) async {
    final db = await database;
    List<Map<String, dynamic>> maps;

    switch (filter) {
      case 'Today':
        final now = DateTime.now();
        final startOfDay = DateTime(now.year, now.month, now.day);
        final endOfDay = startOfDay.add(const Duration(days: 1)).subtract(const Duration(seconds: 1));
        maps = await db.query(
          'tasks',
          where: 'due_date BETWEEN ? AND ? AND is_completed = ?',
          whereArgs: [startOfDay.millisecondsSinceEpoch, endOfDay.millisecondsSinceEpoch, 0],
        );
        break;
      case 'Completed':
        maps = await db.query(
          'tasks',
          where: 'is_completed = ?',
          whereArgs: [1],
        );
        break;
      case 'Repeated':
        maps = await db.query(
          'tasks',
          where: 'repeat_rule != ?',
          whereArgs: [RepeatRule.none.index],
        );
        break;
      case 'Missed':
        final now = DateTime.now().millisecondsSinceEpoch;
        maps = await db.query(
          'tasks',
          where: 'due_date < ? AND status = ? AND is_completed = ?',
          whereArgs: [now, TaskStatus.missed.index, 0],
        );
        break;
      default: // 'All'
        maps = await db.query('tasks');
        break;
    }

    return List.generate(maps.length, (i) => Task.fromMap(maps[i]));
  }

  Future<int> updateTask(Task task) async {
    final db = await database;
    return await db.update(
      'tasks',
      task.toMap(),
      where: 'id = ?',
      whereArgs: [task.id],
    );
  }

  Future<int> deleteTask(String id) async {
    final db = await database;
    return await db.delete(
      'tasks',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> toggleTaskCompletion(String id, bool isCompleted) async {
    final db = await database;

    if (isCompleted) {
      return await db.update(
        'tasks',
        {
          'is_completed': 1,
          'status': TaskStatus.completed.index,
        },
        where: 'id = ?',
        whereArgs: [id],
      );
    } else {
      return await db.update(
        'tasks',
        {
          'is_completed': 0,
          'status': TaskStatus.pending.index,
        },
        where: 'id = ?',
        whereArgs: [id],
      );
    }
  }

  // ⭐ NEW: Check expired tasks and handle repeat logic
  // Returns: List of (missedTasks, rescheduledTasks) for notification purposes
  Future<Map<String, List<Task>>> checkAndUpdateExpiredTasks() async {
    final db = await database;
    final now = DateTime.now();

    final List<Task> missedTasks = [];
    final List<Task> rescheduledTasks = [];

    // Get all pending tasks with expired due dates
    final List<Map<String, dynamic>> maps = await db.query(
      'tasks',
      where: 'due_date < ? AND status = ? AND is_completed = ?',
      whereArgs: [now.millisecondsSinceEpoch, TaskStatus.pending.index, 0],
    );

    final expiredTasks = List.generate(maps.length, (i) => Task.fromMap(maps[i]));

    print('🔍 Found ${expiredTasks.length} expired tasks');

    for (final task in expiredTasks) {
      // Mark current task as missed
      await db.update(
        'tasks',
        {'status': TaskStatus.missed.index},
        where: 'id = ?',
        whereArgs: [task.id],
      );

      print('❌ Task "${task.title}" marked as MISSED');
      missedTasks.add(task);

      // If task has repeat rule, create new task for next occurrence
      if (task.repeatRule != RepeatRule.none) {
        final nextDueDate = _calculateNextDueDate(task.dueDate, task.repeatRule);
        final newTask = task.copyWithNewDueDate(nextDueDate);

        await insertTask(newTask);
        print('🔄 Created new repeated task for ${nextDueDate}');
        rescheduledTasks.add(newTask);
      }
    }

    return {
      'missed': missedTasks,
      'rescheduled': rescheduledTasks,
    };
  }

  // ⭐ NEW: Calculate next due date based on repeat rule
  DateTime _calculateNextDueDate(DateTime currentDueDate, RepeatRule repeatRule) {
    switch (repeatRule) {
      case RepeatRule.daily:
        return currentDueDate.add(const Duration(days: 1));

      case RepeatRule.weekly:
        return currentDueDate.add(const Duration(days: 7));

      case RepeatRule.monthly:
      // Add one month (handle edge cases for month-end dates)
        int year = currentDueDate.year;
        int month = currentDueDate.month + 1;
        if (month > 12) {
          month = 1;
          year++;
        }

        // Handle day overflow (e.g., Jan 31 -> Feb 28/29)
        int day = currentDueDate.day;
        final lastDayOfMonth = DateTime(year, month + 1, 0).day;
        if (day > lastDayOfMonth) {
          day = lastDayOfMonth;
        }

        return DateTime(
          year,
          month,
          day,
          currentDueDate.hour,
          currentDueDate.minute,
        );

      case RepeatRule.none:
      default:
        return currentDueDate;
    }
  }

  // Get expired tasks for notifications
  Future<List<Task>> getExpiredTasks() async {
    final db = await database;
    final now = DateTime.now().millisecondsSinceEpoch;

    final List<Map<String, dynamic>> maps = await db.query(
      'tasks',
      where: 'due_date < ? AND status = ? AND is_completed = ?',
      whereArgs: [now, TaskStatus.missed.index, 0],
    );

    return List.generate(maps.length, (i) => Task.fromMap(maps[i]));
  }

  // Mark notification as scheduled
  Future<void> markNotificationScheduled(String taskId) async {
    final db = await database;
    await db.update(
      'tasks',
      {'notification_scheduled': 1},
      where: 'id = ?',
      whereArgs: [taskId],
    );
  }

  // Get tasks that need notifications scheduled
  Future<List<Task>> getTasksNeedingNotification() async {
    final db = await database;
    final now = DateTime.now().millisecondsSinceEpoch;

    final List<Map<String, dynamic>> maps = await db.query(
      'tasks',
      where: 'due_date > ? AND notification_scheduled = ? AND is_completed = ?',
      whereArgs: [now, 0, 0],
    );

    return List.generate(maps.length, (i) => Task.fromMap(maps[i]));
  }

  // Theme Settings
  Future<void> saveTheme(bool isDarkMode) async {
    final db = await database;
    await db.insert(
      'app_settings',
      {'key': 'isDarkMode', 'value': isDarkMode.toString()},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<bool> loadTheme() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'app_settings',
      where: 'key = ?',
      whereArgs: ['isDarkMode'],
    );

    if (maps.isNotEmpty) {
      return maps.first['value'] == 'true';
    }
    return false; // Default to light mode
  }
}