import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'dart:async';

enum Priority { low, medium, high }

enum RepeatRule { none, daily, weekly, monthly }

enum TaskStatus {
  pending,
  completed,
  missed,
  cancelled
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

  Task copyWithNewDueDate(DateTime newDueDate) {
    return Task(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      description: description,
      dueDate: newDueDate,
      priority: priority,
      repeatRule: repeatRule,
      notificationMinutes: notificationMinutes,
      subTasks: List.from(subTasks),
      isCompleted: false,
      createdAt: DateTime.now(),
      status: TaskStatus.pending,
      notificationScheduled: false,
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

  Future<bool> hasCompletedSetup() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'app_settings',
      where: 'key = ?',
      whereArgs: ['hasCompletedSetup'],
    );

    return maps.isNotEmpty && maps.first['value'] == 'true';
  }

  Future<void> markSetupCompleted() async {
    final db = await database;
    await db.insert(
      'app_settings',
      {'key': 'hasCompletedSetup', 'value': 'true'},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

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
      default:
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

  // ⭐ CORRECT LOGIC: Only reschedule if completed ON TIME (before it becomes missed)
  Future<int> toggleTaskCompletion(String id, bool isCompleted) async {
    final db = await database;

    if (isCompleted) {
      // First, get the task to check if it's repeated
      final tasks = await getAllTasks();
      final task = tasks.firstWhere((t) => t.id == id, orElse: () => throw Exception('Task not found'));

      // Mark as completed
      await db.update(
        'tasks',
        {
          'is_completed': 1,
          'status': TaskStatus.completed.index,
        },
        where: 'id = ?',
        whereArgs: [id],
      );

      // ⭐ CORRECT LOGIC: Only reschedule if:
      // 1. Task has repeat rule
      // 2. Task status is PENDING (not already missed)
      // If already missed, it was rescheduled before, so DON'T reschedule again
      if (task.repeatRule != RepeatRule.none && task.status == TaskStatus.pending) {
        final nextDueDate = _calculateNextDueDate(task.dueDate, task.repeatRule);
        final newTask = task.copyWithNewDueDate(nextDueDate);
        await insertTask(newTask);
        print('🔄 Completed ON TIME - Created new task for ${nextDueDate}');
      } else if (task.status == TaskStatus.missed) {
        print('⏹️ Task was already missed and rescheduled, NOT creating duplicate');
      }

      return 1;
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

  // ⭐ CORRECT LOGIC: Check for expired tasks
  // - Missed tasks: Mark as missed, reschedule if repeated
  // - Completed tasks: Already handled in toggleTaskCompletion
  Future<Map<String, List<Task>>> checkAndUpdateExpiredTasks() async {
    final db = await database;
    final now = DateTime.now();
    final oneMinuteAgo = now.subtract(const Duration(minutes: 1));

    final List<Task> missedTasks = [];
    final List<Task> rescheduledTasks = [];

    // ⭐ ONLY check PENDING tasks that are expired
    // Completed tasks are already handled when user completes them
    final List<Map<String, dynamic>> maps = await db.query(
      'tasks',
      where: 'due_date < ? AND status = ? AND is_completed = ?',
      whereArgs: [oneMinuteAgo.millisecondsSinceEpoch, TaskStatus.pending.index, 0],
    );

    final expiredTasks = List.generate(maps.length, (i) => Task.fromMap(maps[i]));

    print('🔍 Found ${expiredTasks.length} expired pending tasks');

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

      // ⭐ CORRECT LOGIC: If task has repeat rule, reschedule it
      if (task.repeatRule != RepeatRule.none) {
        final nextDueDate = _calculateNextDueDate(task.dueDate, task.repeatRule);
        final newTask = task.copyWithNewDueDate(nextDueDate);

        await insertTask(newTask);
        print('🔄 Missed repeated task - Created new task for ${nextDueDate}');
        rescheduledTasks.add(newTask);
      } else {
        print('⏹️ One-time task, NOT rescheduling');
      }
    }

    return {
      'missed': missedTasks,
      'rescheduled': rescheduledTasks,
    };
  }

  DateTime _calculateNextDueDate(DateTime currentDueDate, RepeatRule repeatRule) {
    switch (repeatRule) {
      case RepeatRule.daily:
        return currentDueDate.add(const Duration(days: 1));

      case RepeatRule.weekly:
        return currentDueDate.add(const Duration(days: 7));

      case RepeatRule.monthly:
        int year = currentDueDate.year;
        int month = currentDueDate.month + 1;
        if (month > 12) {
          month = 1;
          year++;
        }

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

  Future<void> markNotificationScheduled(String taskId) async {
    final db = await database;
    await db.update(
      'tasks',
      {'notification_scheduled': 1},
      where: 'id = ?',
      whereArgs: [taskId],
    );
  }

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
    return false;
  }
}