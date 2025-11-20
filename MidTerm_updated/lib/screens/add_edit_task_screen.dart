import 'package:flutter/material.dart';
import '../utils/database_helper.dart';
import '../utils/notification_service.dart';

class AddEditTaskScreen extends StatefulWidget {
  final Task? task;

  const AddEditTaskScreen({super.key, this.task});

  @override
  State<AddEditTaskScreen> createState() => _AddEditTaskScreenState();
}

class _AddEditTaskScreenState extends State<AddEditTaskScreen> {
  final _formKey = GlobalKey<FormState>();
  final DatabaseHelper _dbHelper = DatabaseHelper();
  final NotificationService _notificationService = NotificationService();

  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late DateTime _dueDate;
  late TimeOfDay _dueTime;
  late Priority _priority;
  late RepeatRule _repeatRule;
  late int _notificationMinutes;
  final List<String> _subTasks = [];
  final TextEditingController _subTaskController = TextEditingController();

  @override
  void initState() {
    super.initState();

    final now = DateTime.now();

    if (widget.task != null) {
      _titleController = TextEditingController(text: widget.task!.title);
      _descriptionController = TextEditingController(text: widget.task!.description);
      _dueDate = widget.task!.dueDate;
      _dueTime = TimeOfDay.fromDateTime(widget.task!.dueDate);
      _priority = widget.task!.priority;
      _repeatRule = widget.task!.repeatRule;
      _notificationMinutes = widget.task!.notificationMinutes;
      _subTasks.addAll(widget.task!.subTasks);
    } else {
      _titleController = TextEditingController();
      _descriptionController = TextEditingController();
      _dueDate = DateTime(now.year, now.month, now.day);
      _dueTime = TimeOfDay(hour: now.hour, minute: now.minute);
      _priority = Priority.medium;
      _repeatRule = RepeatRule.none;
      _notificationMinutes = 15;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _subTaskController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _dueDate,
      firstDate: DateTime.now(),
      lastDate: DateTime(2101),
    );
    if (picked != null) {
      setState(() {
        _dueDate = picked;
      });
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _dueTime,
    );
    if (picked != null) {
      setState(() {
        _dueTime = picked;
      });
    }
  }

  void _addSubTask() {
    if (_subTaskController.text.trim().isNotEmpty) {
      setState(() {
        _subTasks.add(_subTaskController.text.trim());
        _subTaskController.clear();
      });
    }
  }

  void _removeSubTask(int index) {
    setState(() {
      _subTasks.removeAt(index);
    });
  }

  // ⭐ UPDATED: Schedule BOTH reminder AND due now notifications
  Future<void> _scheduleTaskNotification(Task task) async {
    final notificationId = task.id.hashCode;

    // Schedule REMINDER notification (X minutes before)
    await _notificationService.scheduleTaskReminder(
      id: notificationId,
      taskId: task.id, // ⭐ REQUIRED PARAMETER
      title: task.title,
      body: task.description.isNotEmpty
          ? task.description
          : 'Due: ${_formatDate(task.dueDate)}',
      scheduledTime: task.dueDate,
      minutesBefore: task.notificationMinutes,
    );

    // Schedule DUE NOW notification (at exact due time)
    if (task.dueDate.isAfter(DateTime.now())) {
      await _notificationService.scheduleTaskDueNow(
        id: notificationId,
        taskId: task.id, // ⭐ REQUIRED PARAMETER
        title: task.title,
        body: task.description.isNotEmpty
            ? task.description
            : 'This task is due right now!',
        dueTime: task.dueDate,
      );
    }

    await _dbHelper.markNotificationScheduled(task.id);
  }

  // ⭐ Cancel BOTH reminder and due now notifications
  Future<void> _cancelTaskNotification(Task task) async {
    final notificationId = task.id.hashCode;
    await _notificationService.cancelTaskNotifications(notificationId); // Cancels both
  }

  Future<void> _saveTask() async {
    if (_formKey.currentState!.validate()) {
      final dueDateTime = DateTime(
        _dueDate.year,
        _dueDate.month,
        _dueDate.day,
        _dueTime.hour,
        _dueTime.minute,
      );

      final isEditing = widget.task != null;

      if (isEditing) {
        await _cancelTaskNotification(widget.task!);
      }

      TaskStatus status;
      if (isEditing) {
        status = widget.task!.status;
        if (dueDateTime.isAfter(DateTime.now()) && status == TaskStatus.missed) {
          status = TaskStatus.pending;
        }
      } else {
        status = dueDateTime.isAfter(DateTime.now())
            ? TaskStatus.pending
            : TaskStatus.missed;
      }

      final task = Task(
        id: widget.task?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        dueDate: dueDateTime,
        priority: _priority,
        repeatRule: _repeatRule,
        notificationMinutes: _notificationMinutes,
        subTasks: List.from(_subTasks),
        isCompleted: widget.task?.isCompleted ?? false,
        createdAt: widget.task?.createdAt ?? DateTime.now(),
        status: status,
        notificationScheduled: false,
      );

      if (isEditing) {
        await _dbHelper.updateTask(task);
      } else {
        await _dbHelper.insertTask(task);
      }

      if (dueDateTime.isAfter(DateTime.now()) && !task.isCompleted) {
        await _scheduleTaskNotification(task);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isEditing ? 'Task updated successfully!' : 'Task added successfully!',
              style: const TextStyle(color: Colors.white),
            ),
            backgroundColor: const Color(0xFF19E619),
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );

        Future.delayed(const Duration(milliseconds: 1500), () {
          if (mounted) {
            Navigator.pop(context);
          }
        });
      }
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

  bool get _isDueDateTimeInPast {
    final selectedDateTime = DateTime(
      _dueDate.year,
      _dueDate.month,
      _dueDate.day,
      _dueTime.hour,
      _dueTime.minute,
    );
    return selectedDateTime.isBefore(DateTime.now());
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF112211) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black;
    final subTextColor = isDark ? const Color(0xFF93C893) : Colors.grey[700]!;
    final cardColor = isDark ? const Color(0xFF244724) : Colors.grey[100]!;
    final borderColor = isDark ? const Color(0xFF346534) : Colors.grey[400]!;

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Column(
          children: [
            Container(
              color: bgColor,
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(
                      Icons.arrow_back,
                      color: textColor,
                      size: 24,
                    ),
                  ),
                  Expanded(
                    child: Center(
                      child: Text(
                        widget.task != null ? "Edit Task" : "Add New Task",
                        style: TextStyle(
                          color: textColor,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          letterSpacing: -0.015,
                        ),
                      ),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: _saveTask,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF19E619),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Save'),
                  ),
                ],
              ),
            ),

            if (widget.task != null) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Row(
                  children: [
                    _buildStatusIndicator(widget.task!.status),
                    const SizedBox(width: 8),
                    Text(
                      'Status: ${_getStatusText(widget.task!.status)}',
                      style: TextStyle(
                        color: _getStatusColor(widget.task!.status),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],

            Expanded(
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Title *',
                        style: TextStyle(
                          color: textColor,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _titleController,
                        style: TextStyle(color: textColor),
                        decoration: InputDecoration(
                          hintText: 'Enter task title',
                          hintStyle: TextStyle(color: subTextColor),
                          filled: true,
                          fillColor: cardColor,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter a title';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),

                      Text(
                        'Description',
                        style: TextStyle(
                          color: textColor,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _descriptionController,
                        style: TextStyle(color: textColor),
                        maxLines: 3,
                        decoration: InputDecoration(
                          hintText: 'Enter task description',
                          hintStyle: TextStyle(color: subTextColor),
                          filled: true,
                          fillColor: cardColor,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        ),
                      ),
                      const SizedBox(height: 20),

                      Text(
                        'Due Date & Time',
                        style: TextStyle(
                          color: textColor,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () => _selectDate(context),
                              child: Container(
                                height: 50,
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                decoration: BoxDecoration(
                                  color: cardColor,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      '${_dueDate.day}/${_dueDate.month}/${_dueDate.year}',
                                      style: TextStyle(color: textColor),
                                    ),
                                    Icon(Icons.calendar_today, color: subTextColor),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: GestureDetector(
                              onTap: () => _selectTime(context),
                              child: Container(
                                height: 50,
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                decoration: BoxDecoration(
                                  color: cardColor,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      _dueTime.format(context),
                                      style: TextStyle(color: textColor),
                                    ),
                                    Icon(Icons.access_time, color: subTextColor),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (_isDueDateTimeInPast) ...[
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(Icons.warning, color: Colors.orange, size: 16),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                'Due date/time is in the past. Task will be marked as missed.',
                                style: TextStyle(
                                  color: Colors.orange,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 20),

                      Text(
                        'Priority',
                        style: TextStyle(
                          color: textColor,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 12,
                        children: Priority.values.map((priority) {
                          final isSelected = _priority == priority;
                          return GestureDetector(
                            onTap: () => setState(() => _priority = priority),
                            child: Container(
                              height: 44,
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              decoration: BoxDecoration(
                                color: isSelected ? const Color(0xFF19E619).withOpacity(0.3) : cardColor,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isSelected ? const Color(0xFF19E619) : borderColor,
                                  width: isSelected ? 2 : 1,
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  _getPriorityText(priority),
                                  style: TextStyle(
                                    color: textColor,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 20),

                      Text(
                        'Repeat',
                        style: TextStyle(
                          color: textColor,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 12,
                        children: RepeatRule.values.map((repeat) {
                          final isSelected = _repeatRule == repeat;
                          return GestureDetector(
                            onTap: () => setState(() => _repeatRule = repeat),
                            child: Container(
                              height: 44,
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              decoration: BoxDecoration(
                                color: isSelected ? const Color(0xFF19E619).withOpacity(0.3) : cardColor,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isSelected ? const Color(0xFF19E619) : borderColor,
                                  width: isSelected ? 2 : 1,
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  _getRepeatText(repeat),
                                  style: TextStyle(
                                    color: textColor,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 20),

                      Text(
                        'Notification',
                        style: TextStyle(
                          color: textColor,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<int>(
                        value: _notificationMinutes,
                        onChanged: (value) => setState(() => _notificationMinutes = value!),
                        items: [5, 15, 30, 60].map((minutes) {
                          return DropdownMenuItem(
                            value: minutes,
                            child: Text(
                              '$minutes minutes before',
                              style: TextStyle(color: textColor),
                            ),
                          );
                        }).toList(),
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: cardColor,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        ),
                        dropdownColor: isDark ? const Color(0xFF244724) : Colors.white,
                      ),
                      if (_isDueDateTimeInPast) ...[
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(Icons.info, color: subTextColor, size: 16),
                            const SizedBox(width: 4),
                            Text(
                              'Notifications not available for past dates',
                              style: TextStyle(
                                color: subTextColor,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 20),

                      Text(
                        'Subtasks',
                        style: TextStyle(
                          color: textColor,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _subTaskController,
                              style: TextStyle(color: textColor),
                              decoration: InputDecoration(
                                hintText: 'Add a subtask',
                                hintStyle: TextStyle(color: subTextColor),
                                filled: true,
                                fillColor: cardColor,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          IconButton(
                            onPressed: _addSubTask,
                            icon: Icon(Icons.add, color: const Color(0xFF19E619)),
                            style: IconButton.styleFrom(
                              backgroundColor: cardColor,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      ..._subTasks.asMap().entries.map((entry) {
                        final index = entry.key;
                        final subtask = entry.value;
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: cardColor,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.circle, color: subTextColor, size: 8),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  subtask,
                                  style: TextStyle(color: textColor),
                                ),
                              ),
                              IconButton(
                                onPressed: () => _removeSubTask(index),
                                icon: Icon(Icons.close, color: subTextColor, size: 16),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusIndicator(TaskStatus status) {
    Color color;
    switch (status) {
      case TaskStatus.pending:
        color = Colors.orange;
        break;
      case TaskStatus.completed:
        color = const Color(0xFF19E619);
        break;
      case TaskStatus.missed:
        color = Colors.red;
        break;
      case TaskStatus.cancelled:
        color = Colors.grey;
        break;
    }

    return Container(
      width: 12,
      height: 12,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
    );
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

  String _getPriorityText(Priority priority) {
    switch (priority) {
      case Priority.low:
        return 'Low';
      case Priority.medium:
        return 'Medium';
      case Priority.high:
        return 'High';
    }
  }

  String _getRepeatText(RepeatRule repeat) {
    switch (repeat) {
      case RepeatRule.none:
        return 'None';
      case RepeatRule.daily:
        return 'Daily';
      case RepeatRule.weekly:
        return 'Weekly';
      case RepeatRule.monthly:
        return 'Monthly';
    }
  }
}