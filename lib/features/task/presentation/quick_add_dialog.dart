import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:openlist/core/theme/theme.dart';
import 'package:openlist/data/repositories/item_repository.dart';
import 'package:openlist/data/repositories/space_repository.dart';
import 'package:openlist/data/models/item_model.dart';
import 'package:openlist/data/models/space_model.dart';
import 'package:openlist/features/sharing/presentation/share_dialog.dart';

class QuickAddDialog extends StatefulWidget {
  const QuickAddDialog({super.key});

  @override
  State<QuickAddDialog> createState() => _QuickAddDialogState();
}

class _QuickAddDialogState extends State<QuickAddDialog> {
  final TextEditingController _taskController = TextEditingController();
  final SpaceRepository _spaceRepository = SpaceRepository();
  final ItemRepository _repository = ItemRepository();
  bool _isUrgent = false;
  DateTime? _dueDate;
  DateTime? _reminderAt;
  bool _isLoading = false;
  ItemModel? _createdTask; // Store created task for sharing

  @override
  void dispose() {
    _taskController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag Handle
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Header
                    Row(
                      children: [
                        Text(
                          'New Task',
                          style: GoogleFonts.inter(
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.close, size: 24),
                          onPressed: () => Navigator.pop(context),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Task Input
                    TextField(
                      controller: _taskController,
                      autofocus: true,
                      maxLines: null,
                      style: GoogleFonts.inter(
                        fontSize: 20,
                        color: AppColors.textPrimary,
                      ),
                      decoration: InputDecoration(
                        hintText: 'What needs to be done?',
                        hintStyle: GoogleFonts.inter(
                          fontSize: 20,
                          color: AppColors.textMuted.withOpacity(0.4),
                        ),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Urgent Toggle
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _isUrgent = !_isUrgent;
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: _isUrgent ? AppColors.danger.withOpacity(0.1) : AppColors.bgScaffold,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _isUrgent ? AppColors.danger : Colors.transparent,
                            width: 2,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: _isUrgent ? AppColors.danger.withOpacity(0.2) : AppColors.borderLight,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                Icons.priority_high,
                                color: _isUrgent ? AppColors.danger : AppColors.textMuted,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Mark as Urgent',
                                    style: GoogleFonts.inter(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: _isUrgent ? AppColors.danger : AppColors.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Shows at top of list with reminder popup',
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      color: AppColors.textMuted,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Switch(
                              value: _isUrgent,
                              onChanged: (value) {
                                setState(() {
                                  _isUrgent = value;
                                });
                              },
                              activeColor: AppColors.danger,
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Options
                    _buildOptionRow(
                      icon: Icons.calendar_today_outlined,
                      iconColor: AppColors.warning,
                      iconBg: AppColors.warningLight,
                      label: 'Due Date',
                      value: _dueDate != null ? _formatDate(_dueDate!) : 'Today',
                      onTap: _pickDueDate,
                    ),

                    const SizedBox(height: 12),

                    _buildOptionRow(
                      icon: Icons.notifications_outlined,
                      iconColor: AppColors.primary,
                      iconBg: AppColors.primaryLight,
                      label: 'Remind me',
                      value: _reminderAt != null ? _formatTime(_reminderAt!) : '9:00 AM',
                      onTap: _pickReminderTime,
                    ),

                    const SizedBox(height: 12),

                    _buildOptionRow(
                      icon: Icons.share,
                      iconColor: AppColors.success,
                      iconBg: AppColors.successLight,
                      label: 'Share',
                      value: null,
                      onTap: () async {
                        // If task already created, just share it
                        if (_createdTask != null) {
                          _shareTask();
                          return;
                        }
                        
                        // If text is entered, create task first then share
                        if (_taskController.text.trim().isNotEmpty) {
                          await _createTaskAndShare();
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Please enter a task first')),
                          );
                        }
                      },
                    ),

                    const SizedBox(height: 32),

                    // Footer
                    Row(
                      children: [
                        const Spacer(),

                        // Add Task Button
                        ElevatedButton.icon(
                          onPressed: _isLoading ? null : _addTask,
                          icon: _isLoading
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                )
                              : const Icon(Icons.check_circle_outline, size: 20),
                          label: Text(
                            'Add Task',
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24),
                            ),
                            elevation: 0,
                            minimumSize: const Size(140, 48),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  Widget _buildOptionRow({
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required String label,
    String? value,
    bool showAvatar = false,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 16),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
              ),
            ),
            const Spacer(),
            if (showAvatar)
              CircleAvatar(
                radius: 14,
                backgroundImage: NetworkImage('https://i.pravatar.cc/150?img=1'),
              )
            else if (value != null)
              Text(
                value,
                style: GoogleFonts.inter(
                  fontSize: 15,
                  color: AppColors.textMuted,
                ),
              ),
            const SizedBox(width: 8),
            Icon(
              Icons.chevron_right,
              size: 20,
              color: AppColors.textMuted,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _addTask() async {
    if (_taskController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a task')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final task = await _repository.createItem(
        title: _taskController.text.trim(),
        type: ItemType.task,
        category: _isUrgent ? 'Urgent' : null,
        dueDate: _dueDate ?? DateTime.now(),
        reminderAt: _reminderAt,
      );

      if (mounted) {
        setState(() {
          _createdTask = task;
          _isLoading = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Task created!'),
            backgroundColor: AppColors.success,
            duration: const Duration(seconds: 2),
          ),
        );
        
        // Close dialog after task is created
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    }
  }

  void _shareTask() {
    if (_createdTask == null) return;
    
    // Close current dialog first
    Navigator.pop(context);
    
    // Show the share dialog (same as task detail screen)
    showDialog(
      context: context,
      builder: (context) => ShareDialog(
        itemId: _createdTask!.itemId,
        itemTitle: _createdTask!.title,
      ),
    );
  }

  Future<void> _createTaskAndShare() async {
    if (_taskController.text.trim().isEmpty) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final task = await _repository.createItem(
        title: _taskController.text.trim(),
        type: ItemType.task,
        category: _isUrgent ? 'Urgent' : null,
        dueDate: _dueDate ?? DateTime.now(),
        reminderAt: _reminderAt,
      );

      if (mounted) {
        setState(() {
          _createdTask = task;
          _isLoading = false;
        });
        
        // Immediately open share dialog
        _shareTask();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    }
  }

  Future<void> _pickDueDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    
    if (picked != null) {
      setState(() {
        _dueDate = picked;
      });
    }
  }

  Future<void> _pickReminderTime() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _reminderAt ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    
    if (pickedDate != null && mounted) {
      final pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_reminderAt ?? DateTime.now()),
      );
      
      if (pickedTime != null) {
        setState(() {
          _reminderAt = DateTime(
            pickedDate.year,
            pickedDate.month,
            pickedDate.day,
            pickedTime.hour,
            pickedTime.minute,
          );
        });
      }
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final dateOnly = DateTime(date.year, date.month, date.day);
    
    if (dateOnly == today) return 'Today';
    if (dateOnly == tomorrow) return 'Tomorrow';
    
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[date.month - 1]} ${date.day}';
  }

  String _formatTime(DateTime time) {
    final hour = time.hour > 12 ? time.hour - 12 : time.hour;
    final period = time.hour >= 12 ? 'PM' : 'AM';
    return '${hour == 0 ? 12 : hour}:${time.minute.toString().padLeft(2, '0')} $period';
  }
}
