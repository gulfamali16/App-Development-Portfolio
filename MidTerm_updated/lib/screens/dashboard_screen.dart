import 'package:flutter/material.dart';
import 'manage_screen.dart';
import 'settings_screen.dart';
import '../utils/database_helper.dart';
import '../utils/notification_service.dart';

class DashboardScreen extends StatefulWidget {
  final String userName;
  const DashboardScreen({Key? key, required this.userName}) : super(key: key);

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> with WidgetsBindingObserver {
  int _selectedIndex = 0;
  late Color _textColor;
  late Color _subTextColor;
  final DatabaseHelper _dbHelper = DatabaseHelper();
  final NotificationService _notificationService = NotificationService();

  // Task counts
  int _todayTasksCount = 0;
  int _completedTasksCount = 0;
  int _repeatedTasksCount = 0;
  int _missedTasksCount = 0;
  int _totalTasksCount = 0;

  // Today's tasks
  List<Task> _todayTasks = [];
  String _selectedFilter = 'Today';
  final List<String> _filters = ['Today', 'Completed', 'Repeated', 'Missed', 'All'];

  bool _isLoading = true;
  bool _isDark = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeServices();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // When app comes to foreground, check for expired tasks
    if (state == AppLifecycleState.resumed) {
      _checkExpiredTasksAndRefresh();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _updateThemeColors();
  }

  void _updateThemeColors() {
    _isDark = Theme.of(context).brightness == Brightness.dark;
    _textColor = _isDark ? Colors.white : Colors.black;
    _subTextColor = _isDark ? const Color(0xFF93C893) : Colors.grey[700]!;
  }

  Future<void> _initializeServices() async {
    // Initialize notification service if not already initialized
    if (!_notificationService.isInitialized) {
      try {
        await _notificationService.initialize();
        print('✅ Notification service initialized in Dashboard');
      } catch (e) {
        print('❌ Failed to initialize notification service: $e');
      }
    }

    // Check for expired tasks and schedule notifications
    await _checkExpiredTasksAndRefresh();
  }

  Future<void> _checkExpiredTasksAndRefresh() async {
    print('🔍 Checking for expired tasks...');

    // Check and update expired tasks
    final results = await _dbHelper.checkAndUpdateExpiredTasks();
    final missedTasks = results['missed'] ?? [];
    final rescheduledTasks = results['rescheduled'] ?? [];

    print('📊 Found ${missedTasks.length} missed tasks');
    print('🔄 Found ${rescheduledTasks.length} rescheduled tasks');

    // Show notifications for missed tasks
    for (final task in missedTasks) {
      await _notificationService.showMissedTaskNotification(
        id: task.id.hashCode,
        title: task.title,
        body: task.description.isNotEmpty
            ? task.description
            : 'This task was due at ${_formatTime(task.dueDate)}',
      );
    }

    // Show notifications and schedule new notifications for rescheduled tasks
    for (final task in rescheduledTasks) {
      // Show rescheduled notification
      await _notificationService.showTaskRescheduledNotification(
        id: task.id.hashCode,
        title: task.title,
        newDueDate: task.dueDate,
        repeatType: _getRepeatTypeName(task.repeatRule),
      );

      // Schedule notifications for the new task
      await _scheduleNotificationsForTask(task);
    }

    // Schedule notifications for any tasks that need them
    await _scheduleAllPendingNotifications();

    // Refresh dashboard data
    await _loadDashboardData();
  }

  Future<void> _scheduleAllPendingNotifications() async {
    final tasksNeedingNotification = await _dbHelper.getTasksNeedingNotification();

    print('📋 Found ${tasksNeedingNotification.length} tasks needing notifications');

    for (final task in tasksNeedingNotification) {
      await _scheduleNotificationsForTask(task);
    }
  }

  Future<void> _scheduleNotificationsForTask(Task task) async {
    try {
      final now = DateTime.now();

      // Only schedule if task is in the future
      if (task.dueDate.isAfter(now)) {
        // 1. Schedule reminder notification (X minutes before)
        await _notificationService.scheduleTaskReminder(
          id: task.id.hashCode,
          taskId: task.id,
          title: task.title,
          body: task.description.isNotEmpty
              ? task.description
              : 'Task reminder: ${task.title}',
          scheduledTime: task.dueDate,
          minutesBefore: task.notificationMinutes,
        );

        // 2. Schedule "Due Now" notification (at exact due time)
        await _notificationService.scheduleTaskDueNow(
          id: task.id.hashCode,
          taskId: task.id,
          title: task.title,
          body: task.description.isNotEmpty
              ? task.description
              : 'This task is due now!',
          dueTime: task.dueDate,
        );

        // Mark notification as scheduled in database
        await _dbHelper.markNotificationScheduled(task.id);

        print('✅ Scheduled notifications for task: ${task.title}');
      } else {
        print('⚠️ Task ${task.title} is in the past, skipping notification');
      }
    } catch (e) {
      print('❌ Error scheduling notifications for task ${task.title}: $e');
    }
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

  Future<void> _loadDashboardData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Load all counts
      final allTasks = await _dbHelper.getAllTasks();

      // Filter tasks by status for accurate counts
      final todayTasks = await _getTodayPendingTasks();
      final completedTasks = allTasks.where((t) => t.status == TaskStatus.completed).toList();
      final repeatedTasks = allTasks.where((t) => t.repeatRule != RepeatRule.none).toList();
      final missedTasks = allTasks.where((t) => t.status == TaskStatus.missed).toList();

      setState(() {
        _totalTasksCount = allTasks.length;
        _todayTasksCount = todayTasks.length;
        _completedTasksCount = completedTasks.length;
        _repeatedTasksCount = repeatedTasks.length;
        _missedTasksCount = missedTasks.length;
        _todayTasks = todayTasks;
        _isLoading = false;
      });

      print('📊 Dashboard Stats:');
      print('  - Total: $_totalTasksCount');
      print('  - Today: $_todayTasksCount');
      print('  - Completed: $_completedTasksCount');
      print('  - Repeated: $_repeatedTasksCount');
      print('  - Missed: $_missedTasksCount');
    } catch (e) {
      print('❌ Error loading dashboard data: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<List<Task>> _getTodayPendingTasks() async {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = startOfDay.add(const Duration(days: 1)).subtract(const Duration(seconds: 1));

    final allTasks = await _dbHelper.getAllTasks();

    // Get today's tasks that are still pending (not completed, not missed)
    return allTasks.where((task) {
      final isToday = task.dueDate.isAfter(startOfDay) && task.dueDate.isBefore(endOfDay);
      final isPending = task.status == TaskStatus.pending && !task.isCompleted;
      return isToday && isPending;
    }).toList();
  }

  Future<void> _refreshData() async {
    await _checkExpiredTasksAndRefresh();
  }

  Future<void> _applyFilter(String filter) async {
    setState(() {
      _selectedFilter = filter;
      _isLoading = true;
    });

    try {
      List<Task> filteredTasks;

      switch (filter) {
        case 'Today':
          filteredTasks = await _getTodayPendingTasks();
          break;
        case 'Completed':
          final allTasks = await _dbHelper.getAllTasks();
          filteredTasks = allTasks.where((t) => t.status == TaskStatus.completed).toList();
          break;
        case 'Repeated':
          final allTasks = await _dbHelper.getAllTasks();
          filteredTasks = allTasks.where((t) => t.repeatRule != RepeatRule.none).toList();
          break;
        case 'Missed':
          final allTasks = await _dbHelper.getAllTasks();
          filteredTasks = allTasks.where((t) => t.status == TaskStatus.missed).toList();
          break;
        case 'All':
          filteredTasks = await _dbHelper.getAllTasks();
          break;
        default:
          filteredTasks = await _dbHelper.getAllTasks();
      }

      // Sort tasks by due date
      filteredTasks.sort((a, b) => a.dueDate.compareTo(b.dueDate));

      setState(() {
        _todayTasks = filteredTasks;
        _isLoading = false;
      });
    } catch (e) {
      print('❌ Error applying filter: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    _updateThemeColors();
    final bgColor = _isDark ? const Color(0xFF112211) : Colors.white;

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: _buildCurrentScreen(),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() => _selectedIndex = index);
          // Refresh data when returning to dashboard
          if (index == 0) {
            _refreshData();
          }
        },
        selectedItemColor: _isDark ? Colors.white : const Color(0xFF19E619),
        unselectedItemColor: _isDark ? const Color(0xFF93C893) : Colors.grey,
        backgroundColor: _isDark ? const Color(0xFF1A321A) : Colors.grey[100],
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Dashboard'),
          BottomNavigationBarItem(icon: Icon(Icons.list), label: 'Manage'),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Settings'),
        ],
      ),
    );
  }

  Widget _buildCurrentScreen() {
    switch (_selectedIndex) {
      case 0:
        return _buildDashboard();
      case 1:
        return const ManageScreen();
      case 2:
        return const SettingsScreen();
      default:
        return _buildDashboard();
    }
  }

  Widget _buildDashboard() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Center(
            child: Text(
              "Dashboard",
              style: TextStyle(
                color: _textColor,
                fontSize: 20,
                fontWeight: FontWeight.bold,
                letterSpacing: -0.5,
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              "Hello, ${widget.userName}",
              style: TextStyle(
                color: _textColor,
                fontSize: 18,
                fontWeight: FontWeight.bold,
                letterSpacing: -0.3,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),

        Expanded(
          child: RefreshIndicator(
            onRefresh: _refreshData,
            color: const Color(0xFF19E619),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                children: [
                  _buildStatsCard(
                    title: "Today's Tasks",
                    count: _todayTasksCount.toString(),
                    description: "Pending tasks due today",
                  ),
                  _buildStatsCard(
                    title: "Completed Tasks",
                    count: _completedTasksCount.toString(),
                    description: "Tasks you've completed",
                  ),
                  _buildStatsCard(
                    title: "Repeated Tasks",
                    count: _repeatedTasksCount.toString(),
                    description: "Tasks that repeat",
                  ),
                  _buildStatsCard(
                    title: "Missed Tasks",
                    count: _missedTasksCount.toString(),
                    description: "Tasks that expired",
                  ),
                  _buildStatsCard(
                    title: "Total Tasks",
                    count: _totalTasksCount.toString(),
                    description: "All tasks in your list",
                  ),
                  const SizedBox(height: 8),

                  // Filter Chips
                  SizedBox(
                    height: 40,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      children: _filters.map((filter) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: FilterChip(
                            label: Text(
                              filter,
                              style: TextStyle(
                                color: _selectedFilter == filter ? _textColor : _subTextColor,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            selected: _selectedFilter == filter,
                            onSelected: (selected) => _applyFilter(filter),
                            backgroundColor: _isDark ? const Color(0xFF244724) : Colors.grey[100]!,
                            selectedColor: const Color(0xFF19E619).withOpacity(0.3),
                            checkmarkColor: _textColor,
                            side: BorderSide.none,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Tasks Header
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "$_selectedFilter Tasks (${_todayTasks.length})",
                          style: TextStyle(
                            color: _textColor,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (_isLoading)
                          const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Color(0xFF19E619),
                            ),
                          ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Tasks List
                  _isLoading
                      ? const Padding(
                    padding: EdgeInsets.all(20.0),
                    child: Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF19E619),
                      ),
                    ),
                  )
                      : _todayTasks.isEmpty
                      ? Padding(
                    padding: const EdgeInsets.all(40.0),
                    child: Column(
                      children: [
                        Icon(
                          _getEmptyStateIcon(),
                          color: _subTextColor,
                          size: 64,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _getEmptyStateMessage(),
                          style: TextStyle(
                            color: _subTextColor,
                            fontSize: 16,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _getEmptyStateSubMessage(),
                          style: TextStyle(
                            color: _subTextColor,
                            fontSize: 14,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  )
                      : Column(
                    children: [
                      ..._todayTasks.map((task) => _taskTile(task)),
                      const SizedBox(height: 80),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  IconData _getEmptyStateIcon() {
    switch (_selectedFilter) {
      case 'Completed':
        return Icons.check_circle_outline;
      case 'Missed':
        return Icons.sentiment_satisfied;
      case 'Repeated':
        return Icons.repeat;
      default:
        return Icons.task_alt;
    }
  }

  String _getEmptyStateMessage() {
    switch (_selectedFilter) {
      case 'Today':
        return "No tasks for today!";
      case 'Completed':
        return "No completed tasks yet!";
      case 'Repeated':
        return "No repeated tasks!";
      case 'Missed':
        return "No missed tasks! Great job!";
      default:
        return "No tasks yet!";
    }
  }

  String _getEmptyStateSubMessage() {
    switch (_selectedFilter) {
      case 'Today':
        return "Enjoy your free day or add some tasks";
      case 'Completed':
        return "Complete tasks to see them here";
      case 'Missed':
        return "Keep up the good work!";
      default:
        return "Add some tasks to get started";
    }
  }

  Widget _buildStatsCard({
    required String title,
    required String count,
    required String description,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(color: _subTextColor, fontSize: 14)),
                const SizedBox(height: 4),
                Text(
                  count,
                  style: TextStyle(
                    color: _getStatsCardColor(title),
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(description, style: TextStyle(color: _subTextColor, fontSize: 13)),
              ],
            ),
          ),
          Expanded(
            child: Container(
              height: 80,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: _getStatsCardBackgroundColor(title),
              ),
              child: _getStatsIcon(title),
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatsCardColor(String title) {
    switch (title) {
      case "Missed Tasks":
        return Colors.red;
      case "Completed Tasks":
        return const Color(0xFF19E619);
      default:
        return _textColor;
    }
  }

  Color _getStatsCardBackgroundColor(String title) {
    switch (title) {
      case "Missed Tasks":
        return Colors.red.withOpacity(0.2);
      case "Completed Tasks":
        return const Color(0xFF19E619).withOpacity(0.2);
      default:
        return const Color(0xFF19E619).withOpacity(0.2);
    }
  }

  Widget _getStatsIcon(String title) {
    IconData icon;
    Color color;

    switch (title) {
      case "Today's Tasks":
        icon = Icons.today;
        color = const Color(0xFF19E619);
        break;
      case "Completed Tasks":
        icon = Icons.check_circle;
        color = const Color(0xFF19E619);
        break;
      case "Repeated Tasks":
        icon = Icons.repeat;
        color = const Color(0xFF19E619);
        break;
      case "Missed Tasks":
        icon = Icons.warning;
        color = Colors.red;
        break;
      default:
        icon = Icons.analytics;
        color = const Color(0xFF19E619);
        break;
    }

    return Icon(icon, color: color, size: 40);
  }

  Widget _taskTile(Task task) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: _isDark ? const Color(0xFF244724) : Colors.grey[100],
        border: task.status == TaskStatus.missed
            ? Border.all(color: Colors.red, width: 2)
            : null,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Row(
              children: [
                Container(
                  height: 48,
                  width: 48,
                  decoration: BoxDecoration(
                    color: _getTaskColor(task),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _getTaskIcon(task),
                    color: _getIconColor(task),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        task.title,
                        style: TextStyle(
                          color: _textColor,
                          fontWeight: FontWeight.w500,
                          decoration: task.isCompleted
                              ? TextDecoration.lineThrough
                              : TextDecoration.none,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Due: ${_formatDate(task.dueDate)}',
                        style: TextStyle(color: _subTextColor, fontSize: 13),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: _getStatusColor(task.status).withOpacity(0.2),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              _getStatusText(task.status),
                              style: TextStyle(
                                color: _getStatusColor(task.status),
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          if (task.repeatRule != RepeatRule.none) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.blue.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.repeat, size: 10, color: Colors.blue),
                                  const SizedBox(width: 2),
                                  Text(
                                    _getRepeatTypeName(task.repeatRule),
                                    style: const TextStyle(
                                      color: Colors.blue,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                      if (task.description.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          task.description,
                          style: TextStyle(color: _subTextColor, fontSize: 12),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          Icon(
            _getTrailingIcon(task),
            color: _getTrailingIconColor(task),
            size: 24,
          ),
        ],
      ),
    );
  }

  Color _getTaskColor(Task task) {
    if (task.isCompleted) return const Color(0xFF19E619).withOpacity(0.3);
    if (task.status == TaskStatus.missed) return Colors.red.withOpacity(0.2);
    return const Color(0xFF19E619).withOpacity(0.1);
  }

  Color _getIconColor(Task task) {
    if (task.isCompleted) return const Color(0xFF19E619);
    if (task.status == TaskStatus.missed) return Colors.red;
    return _getPriorityColor(task.priority);
  }

  IconData _getTaskIcon(Task task) {
    if (task.isCompleted) return Icons.check_circle;
    if (task.status == TaskStatus.missed) return Icons.warning;

    switch (task.priority) {
      case Priority.high:
        return Icons.priority_high;
      case Priority.medium:
        return Icons.info_outline;
      case Priority.low:
        return Icons.low_priority;
    }
  }

  IconData _getTrailingIcon(Task task) {
    if (task.isCompleted) return Icons.check_circle;
    if (task.status == TaskStatus.missed) return Icons.error;
    return Icons.notifications_none;
  }

  Color _getTrailingIconColor(Task task) {
    if (task.isCompleted) return const Color(0xFF19E619);
    if (task.status == TaskStatus.missed) return Colors.red;
    return _textColor;
  }

  String _getStatusText(TaskStatus status) {
    switch (status) {
      case TaskStatus.pending:
        return 'Pending';
      case TaskStatus.completed:
        return 'Done';
      case TaskStatus.missed:
        return 'Missed';
      case TaskStatus.cancelled:
        return 'Cancelled';
    }
  }

  Color _getStatusColor(TaskStatus status) {
    switch (status) {
      case TaskStatus.pending:
        return Colors.orange;
      case TaskStatus.completed:
        return const Color(0xFF19E619);
      case TaskStatus.missed:
        return Colors.red;
      case TaskStatus.cancelled:
        return Colors.grey;
    }
  }

  Color _getPriorityColor(Priority priority) {
    switch (priority) {
      case Priority.high:
        return Colors.red;
      case Priority.medium:
        return Colors.orange;
      case Priority.low:
        return const Color(0xFF19E619);
    }
  }

  String _formatDate(DateTime date) {
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

  String _formatTime(DateTime date) {
    return '${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}