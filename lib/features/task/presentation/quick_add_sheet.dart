import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:openlist/core/theme/theme.dart';
import 'package:openlist/data/repositories/item_repository.dart';
import 'package:openlist/data/models/item_model.dart';
import 'package:openlist/services/ai_extraction_service.dart';
import 'package:openlist/data/models/task_extraction_model.dart';
import 'package:openlist/utils/date_parser.dart';

class QuickAddSheet extends StatefulWidget {
  const QuickAddSheet({super.key});

  @override
  State<QuickAddSheet> createState() => _QuickAddSheetState();
}

class _QuickAddSheetState extends State<QuickAddSheet> {
  final TextEditingController _taskController = TextEditingController();
  final _storage = const FlutterSecureStorage();
  String _selectedCategory = 'Personal';
  DateTime? _dueDate;
  DateTime? _reminderAt;
  String _recurring = 'None';
  String? _assignedTo;
  bool _isSubmitting = false;
  bool _isExtracting = false;
  bool _aiEnabled = false;
  String? _extractedKeywords;

  @override
  void initState() {
    super.initState();
    _loadAISettings();
  }

  Future<void> _loadAISettings() async {
    final enabled = await _storage.read(key: 'ai_extraction_enabled');
    if (mounted) {
      setState(() {
        _aiEnabled = enabled == 'true';
      });
    }
  }

  @override
  void dispose() {
    _taskController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: isDarkMode ? AppColors.surfaceDark : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Text(
                  'New Task',
                  style: GoogleFonts.inter(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: AppColors.bgScaffold,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.close,
                      size: 20,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Task Input
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _taskController,
                    autofocus: true,
                    style: GoogleFonts.inter(
                      fontSize: 20,
                      color: AppColors.textPrimary,
                    ),
                    decoration: InputDecoration(
                      hintText: 'What needs to be done?',
                      hintStyle: GoogleFonts.inter(
                        fontSize: 20,
                        color: AppColors.textMuted.withOpacity(0.5),
                      ),
                      border: InputBorder.none,
                    ),
                    onChanged: (value) {
                      // Clear extracted keywords when user types
                      if (_extractedKeywords != null) {
                        setState(() {
                          _extractedKeywords = null;
                        });
                      }
                    },
                  ),
                ),
                if (_aiEnabled && _taskController.text.isNotEmpty)
                  _isExtracting
                      ? const Padding(
                          padding: EdgeInsets.all(8.0),
                          child: SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        )
                      : IconButton(
                          icon: Icon(
                            Icons.auto_awesome,
                            color: AppColors.primary,
                            size: 24,
                          ),
                          tooltip: 'AI Extract',
                          onPressed: _extractWithAI,
                        ),
              ],
            ),
          ),

          // Show extracted keywords if available
          if (_extractedKeywords != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.check_circle, color: AppColors.primary, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'AI extracted: $_extractedKeywords',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          const SizedBox(height: 20),

          // Category Chips
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                _buildCategoryChip('Personal', Icons.person_outline, AppColors.primary),
                const SizedBox(width: 8),
                _buildCategoryChip('Work', Icons.work_outline, AppColors.textSecondary),
                const SizedBox(width: 8),
                _buildCategoryChip('Urgent', Icons.priority_high, AppColors.danger),
              ],
            ),
          ),

          const SizedBox(height: 20),

          Divider(color: AppColors.border, height: 1),

          // Options
          _buildOptionRow(
            icon: Icons.calendar_today,
            iconColor: AppColors.warning,
            iconBg: AppColors.warningLight,
            label: 'Due Date',
            value: _dueDate != null ? _formatDate(_dueDate!) : 'Today',
            onTap: _pickDueDate,
          ),

          _buildOptionRow(
            icon: Icons.notifications_outlined,
            iconColor: AppColors.primary,
            iconBg: AppColors.primaryLight,
            label: 'Remind me',
            value: _reminderAt != null ? _formatTime(_reminderAt!) : 'None',
            onTap: _pickReminderTime,
          ),

          _buildOptionRow(
            icon: Icons.repeat,
            iconColor: Color(0xFF7C3AED),
            iconBg: Color(0xFFEDE9FE),
            label: 'Recurring',
            value: _recurring,
            onTap: _pickRecurring,
          ),

          _buildOptionRow(
            icon: Icons.person_add_outlined,
            iconColor: AppColors.success,
            iconBg: AppColors.successLight,
            label: 'Assign to',
            value: _assignedTo,
            showAvatar: _assignedTo != null,
            onTap: () {
              // TODO: Show assignee picker
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Assignee picker coming soon!')),
              );
            },
          ),

          const SizedBox(height: 20),

          // Footer
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: Row(
              children: [
                // Space Selector
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.border),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Work Space',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.unfold_more,
                        size: 16,
                        color: AppColors.textMuted,
                      ),
                    ],
                  ),
                ),

                const Spacer(),

                // Add Task Button
                SizedBox(
                  width: 120,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      _addTask();
                    },
                    icon: const Icon(Icons.check, size: 18),
                    label: Text(
                      'Add',
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryChip(String label, IconData icon, Color color) {
    final isSelected = _selectedCategory == label;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedCategory = label;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.1) : AppColors.bgScaffold,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? color : AppColors.border,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: isSelected ? color : AppColors.textMuted),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: isSelected ? color : AppColors.textSecondary,
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
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
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
            const SizedBox(width: 12),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
              ),
            ),
            const Spacer(),
            if (showAvatar)
              CircleAvatar(
                radius: 12,
                backgroundImage: NetworkImage('https://i.pravatar.cc/150?img=1'),
              )
            else if (value != null)
              Text(
                value,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: AppColors.textMuted,
                ),
              ),
            const SizedBox(width: 8),
            const Icon(
              Icons.chevron_right,
              size: 20,
              color: AppColors.textMuted,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _extractWithAI() async {
    final text = _taskController.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _isExtracting = true;
    });

    try {
      // Get API key
      final apiKey = await _storage.read(key: 'gemini_api_key');
      if (apiKey == null || apiKey.isEmpty) {
        if (mounted) {
          _showError('Please configure your API key in Settings > AI Extraction');
        }
        return;
      }

      // Get reminder offset preference
      final reminderOffsetStr = await _storage.read(key: 'ai_reminder_offset') ?? '30';
      final reminderOffset = int.parse(reminderOffsetStr);

      // Extract with AI
      final service = AIExtractionService(apiKey);
      final extraction = await service.extractTask(text);

      if (extraction == null) {
        if (mounted) {
          _showError('Could not extract task details. Please try again or enter manually.');
        }
        return;
      }

      // Check if it's actually a task
      if (!extraction.isTask) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('This looks more like a note than a task. Continue anyway?'),
              action: SnackBarAction(
                label: 'Yes',
                onPressed: () {
                  _applyExtraction(extraction, reminderOffset);
                },
              ),
              duration: const Duration(seconds: 4),
            ),
          );
        }
        return;
      }

      // Apply extraction
      _applyExtraction(extraction, reminderOffset);

    } catch (e) {
      if (mounted) {
        _showError('AI extraction failed: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isExtracting = false;
        });
      }
    }
  }

  void _applyExtraction(TaskExtraction extraction, int reminderOffset) {
    setState(() {
      // Update title (cleaned)
      _taskController.text = extraction.title;
      
      // Update due date
      if (extraction.dueDate != null) {
        _dueDate = extraction.dueDate;
      }
      
      // Update reminder
      if (extraction.reminderAt != null) {
        _reminderAt = extraction.reminderAt;
      } else if (extraction.dueDate != null) {
        // Calculate reminder based on preference
        _reminderAt = DateParser.calculateReminderTime(
          extraction.dueDate!,
          minutesBefore: reminderOffset,
        );
      }
      
      // Show what was extracted
      final keywords = extraction.detectedKeywords.take(3).join(', ');
      _extractedKeywords = keywords.isNotEmpty ? keywords : 'date and time';
    });

    // Show success message
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.auto_awesome, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              const Expanded(
                child: Text('✨ Task details extracted! Review and add.'),
              ),
            ],
          ),
          backgroundColor: AppColors.success,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: AppColors.danger,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  void _addTask() async {
    if (_taskController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a task')),
      );
      return;
    }

    if (_isSubmitting) return; // Prevent double submission
    
    setState(() {
      _isSubmitting = true;
    });

    try {
      // Save to Isar (offline-first)
      final repository = ItemRepository();
      await repository.createItem(
        title: _taskController.text.trim(),
        type: ItemType.task,
        category: _selectedCategory,
        dueDate: _dueDate,
        reminderAt: _reminderAt,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Task "${_taskController.text}" created!'),
            backgroundColor: AppColors.success,
            duration: const Duration(seconds: 2),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
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

  void _pickRecurring() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Recurring',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 20),
            ...[
              'None',
              'Daily',
              'Weekly',
              'Monthly',
              'Yearly',
            ].map((option) => ListTile(
              title: Text(option),
              trailing: _recurring == option ? const Icon(Icons.check, color: AppColors.primary) : null,
              onTap: () {
                setState(() {
                  _recurring = option;
                });
                Navigator.pop(context);
              },
            )),
          ],
        ),
      ),
    );
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
