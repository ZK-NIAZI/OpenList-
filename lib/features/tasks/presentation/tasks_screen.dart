import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:openlist/core/theme/theme.dart';
import 'package:openlist/features/sidebar/presentation/app_sidebar.dart';
import 'package:openlist/data/repositories/item_repository.dart';
import 'package:openlist/data/models/item_model.dart';
import 'package:openlist/core/providers/space_provider.dart';
import 'package:openlist/core/providers/show_completed_provider.dart';

class TasksScreen extends ConsumerStatefulWidget {
  const TasksScreen({super.key});

  @override
  ConsumerState<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends ConsumerState<TasksScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final ItemRepository _repository = ItemRepository();

  void _openDrawer() {
    _scaffoldKey.currentState?.openDrawer();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final showCompleted = ref.watch(showCompletedProvider);
    final selectedSpace = ref.watch(selectedSpaceProvider);
    
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: isDarkMode ? AppColors.bgScaffoldDark : AppColors.bgScaffold,
      drawer: const AppSidebar(),
      appBar: AppBar(
        backgroundColor: isDarkMode ? AppColors.bgScaffoldDark : AppColors.bgScaffold,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(Icons.menu_rounded, color: Colors.white),
              onPressed: _openDrawer,
              padding: EdgeInsets.zero,
            ),
          ),
        ),
        title: Text(
          'Tasks',
          style: GoogleFonts.inter(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: isDarkMode ? AppColors.textPrimaryDark : AppColors.textPrimary,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: const Icon(Icons.search, color: Colors.white, size: 20),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Search coming soon!')),
                  );
                },
                padding: EdgeInsets.zero,
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Toggle for completed tasks
            Row(
              children: [
                Text(
                  'Show completed',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: isDarkMode ? AppColors.textSecondaryDark : AppColors.textSecondary,
                  ),
                ),
                const SizedBox(width: 8),
                Switch(
                  value: showCompleted,
                  onChanged: (value) {
                    ref.read(showCompletedProvider.notifier).state = value;
                  },
                  activeColor: AppColors.primary,
                ),
              ],
            ),
            
            const SizedBox(height: 20),
            
            // Today's Tasks
            Text(
              'Today',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: isDarkMode ? AppColors.textPrimaryDark : AppColors.textPrimary,
              ),
            ),
            
            const SizedBox(height: 12),
            
            StreamBuilder<List<ItemModel>>(
              stream: _getFilteredStream(selectedSpace),
              builder: (context, snapshot) {
                var allItems = snapshot.data ?? [];
                
                final tasks = allItems.where((item) => item.type == ItemType.task).toList();
                final filteredTasks = showCompleted 
                    ? tasks 
                    : tasks.where((t) => !t.isCompleted).toList();
                
                // Filter for today
                final now = DateTime.now();
                final today = DateTime(now.year, now.month, now.day);
                final todayTasks = filteredTasks.where((task) {
                  if (task.dueDate == null) return false;
                  final dueDate = DateTime(
                    task.dueDate!.year,
                    task.dueDate!.month,
                    task.dueDate!.day,
                  );
                  return dueDate == today;
                }).toList();
                
                if (todayTasks.isEmpty) {
                  return _buildEmptySection('No tasks for today');
                }
                
                return Column(
                  children: todayTasks.map((task) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _buildTaskItem(task),
                  )).toList(),
                );
              },
            ),
            
            const SizedBox(height: 24),
            
            // Upcoming Tasks
            Text(
              'Upcoming',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: isDarkMode ? AppColors.textPrimaryDark : AppColors.textPrimary,
              ),
            ),
            
            const SizedBox(height: 12),
            
            StreamBuilder<List<ItemModel>>(
              stream: _repository.watchAllItems(),
              builder: (context, snapshot) {
                var allTasks = snapshot.data ?? [];
                
                final now = DateTime.now();
                final today = DateTime(now.year, now.month, now.day);
                
                final upcomingTasks = allTasks.where((task) {
                  if (task.type != ItemType.task) return false;
                  if (!showCompleted && task.isCompleted) return false;
                  if (task.dueDate == null) return false;
                  
                  final dueDate = DateTime(
                    task.dueDate!.year,
                    task.dueDate!.month,
                    task.dueDate!.day,
                  );
                  
                  return dueDate.isAfter(today);
                }).toList();
                
                if (upcomingTasks.isEmpty) {
                  return _buildEmptySection('No upcoming tasks');
                }
                
                return Column(
                  children: upcomingTasks.map((task) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _buildTaskItem(task),
                  )).toList(),
                );
              },
            ),
            
            const SizedBox(height: 24),
            
            // Later / Untimed Tasks
            Text(
              'Later',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: isDarkMode ? AppColors.textPrimaryDark : AppColors.textPrimary,
              ),
            ),
            
            const SizedBox(height: 12),
            
            StreamBuilder<List<ItemModel>>(
              stream: _getFilteredStream(selectedSpace),
              builder: (context, snapshot) {
                var allTasks = snapshot.data ?? [];
                
                final laterTasks = allTasks.where((task) {
                  if (task.type != ItemType.task) return false;
                  if (!showCompleted && task.isCompleted) return false;
                  return task.dueDate == null;
                }).toList();
                
                if (laterTasks.isEmpty) {
                  return _buildEmptySection('No untimed tasks');
                }
                
                return Column(
                  children: laterTasks.map((task) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _buildTaskItem(task),
                  )).toList(),
                );
              },
            ),
            
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  Widget _buildTaskItem(ItemModel task) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: () {
        context.push('/task/${task.id}');
      },
      child: Container(
        decoration: BoxDecoration(
          color: isDarkMode ? AppColors.surfaceDark : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border(
            left: BorderSide(
              color: task.isCompleted ? AppColors.success : AppColors.primary,
              width: 3,
            ),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              GestureDetector(
                onTap: () {
                  _repository.toggleComplete(task.id);
                },
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: task.isCompleted 
                        ? AppColors.success 
                        : (isDarkMode ? AppColors.surfaceDark : Colors.white),
                    border: Border.all(
                      color: task.isCompleted 
                          ? AppColors.success 
                          : (isDarkMode ? AppColors.borderDark : AppColors.border),
                      width: 2,
                    ),
                  ),
                  child: task.isCompleted
                      ? const Icon(Icons.check, size: 16, color: Colors.white)
                      : null,
                ),
              ),
              
              const SizedBox(width: 12),
              
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      task.title,
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: task.isCompleted 
                            ? (isDarkMode ? AppColors.textMutedDark : AppColors.textMuted)
                            : (isDarkMode ? AppColors.textPrimaryDark : AppColors.textPrimary),
                        decoration: task.isCompleted ? TextDecoration.lineThrough : null,
                      ),
                    ),
                    if (task.dueDate != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        _formatDateTime(task.dueDate!),
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: isDarkMode ? AppColors.textMutedDark : AppColors.textMuted,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptySection(String message) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDarkMode ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDarkMode ? AppColors.borderDark : AppColors.border),
      ),
      child: Center(
        child: Text(
          message,
          style: GoogleFonts.inter(
            fontSize: 14,
            color: isDarkMode ? AppColors.textMutedDark : AppColors.textMuted,
          ),
        ),
      ),
    );
  }

  String _formatDateTime(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final dateOnly = DateTime(date.year, date.month, date.day);
    
    String dateStr;
    if (dateOnly == today) {
      dateStr = 'Today';
    } else if (dateOnly == tomorrow) {
      dateStr = 'Tomorrow';
    } else {
      final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      dateStr = '${months[date.month - 1]} ${date.day}';
    }
    
    final hour = date.hour > 12 ? date.hour - 12 : date.hour;
    final period = date.hour >= 12 ? 'PM' : 'AM';
    final timeStr = '${hour == 0 ? 12 : hour}:${date.minute.toString().padLeft(2, '0')} $period';
    
    return '$dateStr • $timeStr';
  }

  // Helper method for space filtering
  Stream<List<ItemModel>> _getFilteredStream(String? selectedSpace) {
    if (selectedSpace == 'personal') {
      return _repository.watchPersonalItems();
    } else if (selectedSpace == 'shared') {
      return _repository.watchSharedItems();
    } else {
      return _repository.watchAllItems();
    }
  }
}
