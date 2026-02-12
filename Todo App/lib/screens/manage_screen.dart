import 'package:flutter/material.dart';
import 'add_edit_task_screen.dart';
import '../utils/database_helper.dart';
import '../utils/notification_service.dart'; // ⭐ NEW IMPORT

class ManageScreen extends StatefulWidget {
  const ManageScreen({super.key});

  @override
  State<ManageScreen> createState() => _ManageScreenState();
}

class _ManageScreenState extends State<ManageScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedFilter = 'All';
  final List<String> _filters = ['Today', 'Completed', 'Repeated', 'Missed', 'All'];
  final DatabaseHelper _dbHelper = DatabaseHelper();
  final NotificationService _notificationService = NotificationService(); // ⭐ NEW
  List<Task> _tasks = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  Future<void> _loadTasks() async {
    setState(() {
      _isLoading = true;
    });
    _tasks = await _dbHelper.getTasksByFilter(_selectedFilter);
    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _refreshTasks() async {
    await _loadTasks();
  }

  List<Task> get _filteredTasks {
    final searchText = _searchController.text.toLowerCase();
    if (searchText.isEmpty) {
      return _tasks;
    }
    return _tasks.where((task) =>
    task.title.toLowerCase().contains(searchText) ||
        task.description.toLowerCase().contains(searchText)
    ).toList();
  }

  void _addNewTask() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AddEditTaskScreen(),
      ),
    ).then((_) {
      _refreshTasks();
    });
  }

  void _editTask(Task task) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddEditTaskScreen(task: task),
      ),
    ).then((_) {
      _refreshTasks();
    });
  }

  Future<void> _deleteTask(Task task) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFF244724)
            : Colors.white,
        title: Text(
          'Delete Task',
          style: TextStyle(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.white
                : Colors.black,
          ),
        ),
        content: Text(
          'Are you sure you want to delete "${task.title}"?',
          style: TextStyle(
            color: Theme.of(context).brightness == Brightness.dark
                ? const Color(0xFF93C893)
                : Colors.grey[700],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              await _dbHelper.deleteTask(task.id);

              // ⭐ Cancel notification for deleted task
              await _notificationService.cancelNotification(task.id.hashCode);

              Navigator.pop(context);
              _refreshTasks();
              _showSnackBar('Task deleted successfully');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE61919),
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  // ⭐ UPDATED: Toggle completion with notification
  Future<void> _toggleTaskCompletion(Task task) async {
    final newCompletionStatus = !task.isCompleted;
    await _dbHelper.toggleTaskCompletion(task.id, newCompletionStatus);

    // ⭐ If marking as completed, show completion notification
    if (newCompletionStatus) {
      await _notificationService.showTaskCompletedNotification(
        id: task.id.hashCode + 30000, // Different ID
        title: task.title,
        body: task.description.isNotEmpty ? task.description : null,
      );

      // Cancel the reminder notification since task is completed
      await _notificationService.cancelNotification(task.id.hashCode);
    }

    _refreshTasks();
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFF19E619),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF112211) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black;
    final subTextColor = isDark ? const Color(0xFF93C893) : Colors.grey[700]!;
    final cardColor = isDark ? const Color(0xFF244724) : Colors.grey[100]!;
    final searchBgColor = isDark ? const Color(0xFF244724) : Colors.grey[100]!;

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Column(
          children: [
            Container(
              color: bgColor,
              padding: const EdgeInsets.all(16).copyWith(bottom: 8),
              child: Row(
                children: [
                  Expanded(
                    child: Center(
                      child: Text(
                        "Manage Tasks",
                        style: TextStyle(
                          color: textColor,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          letterSpacing: -0.015,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 48,
                    child: IconButton(
                      onPressed: _addNewTask,
                      icon: Icon(
                        Icons.add,
                        color: textColor,
                        size: 24,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Container(
                height: 48,
                decoration: BoxDecoration(
                  color: searchBgColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Icon(
                        Icons.search,
                        color: subTextColor,
                        size: 24,
                      ),
                    ),
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        style: TextStyle(
                          color: textColor,
                          fontSize: 16,
                        ),
                        decoration: InputDecoration(
                          hintText: "Search tasks",
                          hintStyle: TextStyle(
                            color: subTextColor,
                            fontSize: 16,
                          ),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.zero,
                        ),
                        onChanged: (value) {
                          setState(() {});
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),

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
                          color: _selectedFilter == filter ? textColor : subTextColor,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      selected: _selectedFilter == filter,
                      onSelected: (selected) async {
                        setState(() {
                          _selectedFilter = filter;
                        });
                        await _refreshTasks();
                      },
                      backgroundColor: cardColor,
                      selectedColor: const Color(0xFF19E619).withOpacity(0.3),
                      checkmarkColor: textColor,
                      side: BorderSide.none,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Tasks (${_filteredTasks.length})",
                  style: TextStyle(
                    color: textColor,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.015,
                  ),
                ),
              ),
            ),

            Expanded(
              child: _isLoading
                  ? Center(
                child: CircularProgressIndicator(
                  color: const Color(0xFF19E619),
                ),
              )
                  : RefreshIndicator(
                onRefresh: _refreshTasks,
                color: const Color(0xFF19E619),
                child: _filteredTasks.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  itemCount: _filteredTasks.length,
                  itemBuilder: (context, index) {
                    final task = _filteredTasks[index];
                    return _buildTaskItem(
                      task: task,
                      textColor: textColor,
                      subTextColor: subTextColor,
                      cardColor: cardColor,
                      onTap: () => _toggleTaskCompletion(task),
                      onEdit: () => _editTask(task),
                      onDelete: () => _deleteTask(task),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final subTextColor = isDark ? const Color(0xFF93C893) : Colors.grey[700]!;

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.all(40.0),
        child: Column(
          children: [
            Icon(
              _getEmptyStateIcon(),
              color: subTextColor,
              size: 64,
            ),
            const SizedBox(height: 16),
            Text(
              _getEmptyStateMessage(),
              style: TextStyle(
                color: subTextColor,
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              _getEmptyStateSubtitle(),
              style: TextStyle(
                color: subTextColor,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  IconData _getEmptyStateIcon() {
    switch (_selectedFilter) {
      case 'Today':
        return Icons.today;
      case 'Completed':
        return Icons.check_circle;
      case 'Repeated':
        return Icons.repeat;
      case 'Missed':
        return Icons.warning;
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

  String _getEmptyStateSubtitle() {
    switch (_selectedFilter) {
      case 'Missed':
        return "You're staying on top of your tasks!";
      default:
        return "Add some tasks to get started";
    }
  }

  Widget _buildTaskItem({
    required Task task,
    required Color textColor,
    required Color subTextColor,
    required Color cardColor,
    required VoidCallback onTap,
    required VoidCallback onEdit,
    required VoidCallback onDelete,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      color: Colors.transparent,
      elevation: 0,
      child: Container(
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(12),
          border: task.status == TaskStatus.missed
              ? Border.all(color: Colors.red, width: 1)
              : null,
        ),
        child: ListTile(
          leading: GestureDetector(
            onTap: onTap,
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: _getTaskColor(task, isDark),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                task.isCompleted ? Icons.check_circle : Icons.circle_outlined,
                color: _getLeadingIconColor(task),
                size: 24,
              ),
            ),
          ),
          title: Text(
            task.title,
            style: TextStyle(
              color: textColor,
              fontSize: 16,
              fontWeight: FontWeight.w500,
              decoration: task.isCompleted ? TextDecoration.lineThrough : TextDecoration.none,
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                task.description,
                style: TextStyle(
                  color: subTextColor,
                  fontSize: 14,
                  fontWeight: FontWeight.normal,
                  decoration: task.isCompleted ? TextDecoration.lineThrough : TextDecoration.none,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Due: ${_formatDate(task.dueDate)}',
                style: TextStyle(color: subTextColor, fontSize: 12),
              ),
              const SizedBox(height: 2),
              Text(
                'Status: ${_getStatusText(task.status)}',
                style: TextStyle(
                  color: _getStatusColor(task.status),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          trailing: PopupMenuButton<String>(
            icon: Icon(Icons.more_vert, color: textColor),
            onSelected: (value) {
              if (value == 'edit') {
                onEdit();
              } else if (value == 'delete') {
                onDelete();
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'edit',
                child: Row(
                  children: [
                    Icon(Icons.edit, color: textColor),
                    const SizedBox(width: 8),
                    Text('Edit', style: TextStyle(color: textColor)),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete, color: Colors.red),
                    const SizedBox(width: 8),
                    Text('Delete', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        ),
      ),
    );
  }

  Color _getTaskColor(Task task, bool isDark) {
    if (task.isCompleted) return const Color(0xFF19E619).withOpacity(0.3);
    if (task.status == TaskStatus.missed) return Colors.red.withOpacity(0.2);
    return isDark ? const Color(0xFF244724) : const Color(0xFF19E619).withOpacity(0.1);
  }

  Color _getLeadingIconColor(Task task) {
    if (task.isCompleted) return const Color(0xFF19E619);
    if (task.status == TaskStatus.missed) return Colors.red;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? Colors.white : Colors.black;
  }

  String _getStatusText(TaskStatus status) {
    switch (status) {
      case TaskStatus.pending:
        return 'Pending';
      case TaskStatus.completed:
        return 'Completed';
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

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final taskDate = DateTime(date.year, date.month, date.day);

    if (taskDate == today) {
      return 'Today ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } else if (taskDate == today.add(const Duration(days: 1))) {
      return 'Tomorrow ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } else {
      return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    }
  }
}