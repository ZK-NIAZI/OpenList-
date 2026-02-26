import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:openlist/core/theme/theme.dart';
import 'package:openlist/core/widgets/widgets.dart';
import 'package:openlist/features/sidebar/presentation/app_sidebar.dart';
import 'package:openlist/data/repositories/item_repository.dart';
import 'package:openlist/data/repositories/space_repository.dart';
import 'package:openlist/data/models/item_model.dart';
import 'package:openlist/data/models/space_model.dart';
import 'package:openlist/data/models/block_model.dart';
import 'package:openlist/data/sync/sync_manager.dart';
import 'package:openlist/core/providers/space_provider.dart';
import 'package:openlist/features/auth/providers/auth_provider.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final ItemRepository _repository = ItemRepository();
  final SpaceRepository _spaceRepository = SpaceRepository();

  void _openDrawer() {
    _scaffoldKey.currentState?.openDrawer();
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return 'Good Morning';
    } else if (hour < 17) {
      return 'Good Afternoon';
    } else if (hour < 21) {
      return 'Good Evening';
    } else {
      return 'Good Night';
    }
  }

  String _getUserName() {
    final user = ref.read(currentUserProvider);
    if (user?.userMetadata?['full_name'] != null) {
      return user!.userMetadata!['full_name'];
    } else if (user?.email != null) {
      // Extract name from email (before @)
      return user!.email!.split('@')[0];
    }
    return 'User';
  }

  Future<void> _handleRefresh() async {
    await SyncManager.instance.triggerSync();
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.sync, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Text(
                SyncManager.instance.isOnline 
                    ? '✅ Synced with cloud' 
                    : '📴 Offline - changes saved locally',
              ),
            ],
          ),
          backgroundColor: SyncManager.instance.isOnline 
              ? AppColors.success 
              : AppColors.warning,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
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
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _getGreeting(),
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: isDarkMode ? AppColors.textSecondaryDark : AppColors.textSecondary,
              ),
            ),
            Text(
              _getUserName(),
              style: GoogleFonts.inter(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: isDarkMode ? AppColors.textPrimaryDark : AppColors.textPrimary,
              ),
            ),
          ],
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
                  context.push('/search');
                },
                padding: EdgeInsets.zero,
              ),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _handleRefresh,
        color: AppColors.primary,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              StreamBuilder<List<ItemModel>>(
                stream: _getFilteredItemsStream(selectedSpace),
                builder: (context, snapshot) {
                  var items = snapshot.data ?? [];
                  
                  return _buildProgressCard(items);
                },
              ),
              
              const SizedBox(height: 24),
              
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Pinned Notes',
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: isDarkMode ? AppColors.textPrimaryDark : AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 12),
              
              StreamBuilder<List<ItemModel>>(
                stream: _getFilteredPinnedStream(selectedSpace),
                builder: (context, snapshot) {
                  var pinnedItems = snapshot.data ?? [];
                  
                  if (pinnedItems.isEmpty) {
                    return _buildEmptyState(
                      icon: Icons.push_pin_outlined,
                      title: 'No pinned items',
                      subtitle: 'Pin notes and tasks to see them here',
                    );
                  }
                  
                  return SizedBox(
                    height: 150,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: pinnedItems.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 12),
                      itemBuilder: (context, index) {
                        return _buildPinnedNote(pinnedItems[index]);
                      },
                    ),
                  );
                },
              ),
              
              const SizedBox(height: 24),
              
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Today\'s Tasks',
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: isDarkMode ? AppColors.textPrimaryDark : AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    _formatDate(DateTime.now()),
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: isDarkMode ? AppColors.textSecondaryDark : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 12),
              
              StreamBuilder<List<ItemModel>>(
                stream: _getFilteredTodayStream(selectedSpace),
                builder: (context, snapshot) {
                  var todayItems = snapshot.data ?? [];
                  
                  // Sort: Urgent tasks first, then by due date
                  todayItems.sort((a, b) {
                    // Urgent tasks always come first
                    if (a.category == 'Urgent' && b.category != 'Urgent') return -1;
                    if (a.category != 'Urgent' && b.category == 'Urgent') return 1;
                    
                    // Then sort by due date
                    if (a.dueDate != null && b.dueDate != null) {
                      return a.dueDate!.compareTo(b.dueDate!);
                    }
                    return 0;
                  });
                  
                  if (todayItems.isEmpty) {
                    return _buildEmptyState(
                      icon: Icons.celebration_outlined,
                      title: 'Woohoo! No pending tasks for today',
                      subtitle: 'Enjoy your free time or add new tasks',
                    );
                  }
                  
                  return Column(
                    children: todayItems.map((item) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _buildTaskItem(item),
                      );
                    }).toList(),
                  );
                },
              ),
              
              const SizedBox(height: 24),
              
              GestureDetector(
                onTap: _showAddNoteDialog,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  decoration: BoxDecoration(
                    color: isDarkMode ? AppColors.surfaceDark : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: isDarkMode ? AppColors.borderDark : AppColors.border),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.add,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Add a note...',
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w400,
                          color: isDarkMode ? AppColors.textMutedDark : AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProgressCard(List<ItemModel> items) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final total = items.where((i) => i.type == ItemType.task).length;
    final completed = items.where((i) => i.type == ItemType.task && i.isCompleted).length;
    final active = total - completed;
    final overdue = items.where((i) => 
      i.type == ItemType.task && 
      !i.isCompleted && 
      i.dueDate != null && 
      i.dueDate!.isBefore(DateTime.now())
    ).length;
    
    final percentage = total > 0 ? (completed / total) : 0.0;

    return OLCard(
      child: Row(
        children: [
          SizedBox(
            width: 100,
            height: 100,
            child: Stack(
              children: [
                Center(
                  child: SizedBox(
                    width: 90,
                    height: 90,
                    child: CircularProgressIndicator(
                      value: percentage,
                      strokeWidth: 8,
                      backgroundColor: isDarkMode ? AppColors.borderDark : AppColors.border,
                      valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                    ),
                  ),
                ),
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '${(percentage * 100).toInt()}%',
                        style: GoogleFonts.inter(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: isDarkMode ? AppColors.textPrimaryDark : AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        'DONE',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: isDarkMode ? AppColors.textMutedDark : AppColors.textMuted,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(width: 20),
          
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Overall Progress',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: isDarkMode ? AppColors.textPrimaryDark : AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                _buildProgressRow('$active Active', total > 0 ? '${(active / total * 100).toInt()}%' : '0%', AppColors.primary),
                const SizedBox(height: 6),
                _buildProgressRow('$completed Completed', total > 0 ? '${(completed / total * 100).toInt()}%' : '0%', AppColors.success),
                const SizedBox(height: 6),
                _buildProgressRow('$overdue Overdue', total > 0 ? '${(overdue / total * 100).toInt()}%' : '0%', AppColors.danger),
                const SizedBox(height: 12),
                if (total > 0)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: Row(
                      children: [
                        if (active > 0)
                          Expanded(
                            flex: active,
                            child: Container(height: 6, color: AppColors.primary),
                          ),
                        if (completed > 0)
                          Expanded(
                            flex: completed,
                            child: Container(height: 6, color: AppColors.success),
                          ),
                        if (overdue > 0)
                          Expanded(
                            flex: overdue,
                            child: Container(height: 6, color: AppColors.danger),
                          ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressRow(String label, String percentage, Color color) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: isDarkMode ? AppColors.textSecondaryDark : AppColors.textSecondary,
          ),
        ),
        const Spacer(),
        Text(
          percentage,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildPinnedNote(ItemModel item) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: () {
        context.push('/task/${item.id}');
      },
      child: Container(
        width: 200,
        height: 150,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDarkMode ? AppColors.surfaceDark : Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (item.category != null) ...[
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: _getCategoryColor(item.category!),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      item.category!.toUpperCase(),
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: isDarkMode ? AppColors.textSecondaryDark : AppColors.textSecondary,
                        letterSpacing: 0.5,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],
            Text(
              item.title,
              style: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: isDarkMode ? AppColors.textPrimaryDark : AppColors.textPrimary,
                height: 1.3,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 6),
            Expanded(
              child: StreamBuilder<List<BlockModel>>(
                stream: _repository.watchBlocks(item.itemId),
                builder: (context, snapshot) {
                  final blocks = snapshot.data ?? [];
                  if (blocks.isEmpty) {
                    return Text(
                      'Tap to add content...',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                        color: isDarkMode ? AppColors.textMutedDark : AppColors.textMuted,
                        height: 1.3,
                        fontStyle: FontStyle.italic,
                      ),
                    );
                  }
                  
                  // Get all blocks with content (text, heading, bullet, checklist)
                  final contentBlocks = blocks
                      .where((b) => b.content.trim().isNotEmpty)
                      .toList();
                  
                  if (contentBlocks.isEmpty) {
                    return Text(
                      'Tap to add content...',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                        color: isDarkMode ? AppColors.textMutedDark : AppColors.textMuted,
                        height: 1.3,
                        fontStyle: FontStyle.italic,
                      ),
                    );
                  }
                  
                  // Format content based on block type
                  final formattedContent = contentBlocks.map((b) {
                    switch (b.type) {
                      case BlockType.bullet:
                        return '• ${b.content.trim()}';
                      case BlockType.checklist:
                        return '${b.isChecked ? '☑' : '☐'} ${b.content.trim()}';
                      default:
                        return b.content.trim();
                    }
                  }).join('\n');
                  
                  return Text(
                    formattedContent,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                      color: isDarkMode ? AppColors.textMutedDark : AppColors.textMuted,
                      height: 1.3,
                    ),
                    maxLines: 4,
                    overflow: TextOverflow.ellipsis,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTaskItem(ItemModel item) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final isUrgent = item.category == 'Urgent';
    
    return GestureDetector(
      onTap: () {
        context.push('/task/${item.id}');
      },
      child: Container(
        decoration: BoxDecoration(
          color: isDarkMode ? AppColors.surfaceDark : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border(
            left: BorderSide(
              color: isUrgent 
                  ? AppColors.danger 
                  : (item.isCompleted ? AppColors.success : AppColors.primary),
              width: 3,
            ),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              GestureDetector(
                onTap: () {
                  _repository.toggleComplete(item.id);
                },
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: item.isCompleted 
                        ? AppColors.success 
                        : (isDarkMode ? AppColors.surfaceDark : Colors.white),
                    border: Border.all(
                      color: item.isCompleted 
                          ? AppColors.success 
                          : (isDarkMode ? AppColors.borderDark : AppColors.border),
                      width: 2,
                    ),
                  ),
                  child: item.isCompleted
                      ? const Icon(
                          Icons.check,
                          size: 16,
                          color: Colors.white,
                        )
                      : null,
                ),
              ),
              
              const SizedBox(width: 12),
              
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        if (isUrgent) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.danger.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.priority_high,
                                  size: 12,
                                  color: AppColors.danger,
                                ),
                                const SizedBox(width: 2),
                                Text(
                                  'URGENT',
                                  style: GoogleFonts.inter(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.danger,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                        ],
                        Expanded(
                          child: Text(
                            item.title,
                            style: GoogleFonts.inter(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: item.isCompleted 
                                  ? (isDarkMode ? AppColors.textMutedDark : AppColors.textMuted)
                                  : (isDarkMode ? AppColors.textPrimaryDark : AppColors.textPrimary),
                              decoration: item.isCompleted ? TextDecoration.lineThrough : null,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (item.dueDate != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        _formatTime(item.dueDate!),
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w400,
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

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: isDarkMode ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDarkMode ? AppColors.borderDark : AppColors.border),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            size: 48,
            color: (isDarkMode ? AppColors.textMutedDark : AppColors.textMuted).withOpacity(0.5),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: isDarkMode ? AppColors.textSecondaryDark : AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: GoogleFonts.inter(
              fontSize: 14,
              color: isDarkMode ? AppColors.textMutedDark : AppColors.textMuted,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'work':
        return AppColors.warning;
      case 'personal':
        return AppColors.primary;
      case 'urgent':
        return AppColors.danger;
      default:
        return AppColors.success;
    }
  }

  String _formatDate(DateTime date) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[date.month - 1]} ${date.day}';
  }

  void _showAddNoteDialog() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('New Note', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
        content: Text(
          'Create a new note?',
          style: GoogleFonts.inter(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final newNote = await _repository.createItem(
                title: 'Untitled Note',
                type: ItemType.note,
              );
              if (mounted) {
                Navigator.pop(context);
                context.push('/task/${newNote.id}');
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime date) {
    final hour = date.hour > 12 ? date.hour - 12 : date.hour;
    final period = date.hour >= 12 ? 'PM' : 'AM';
    return '${hour == 0 ? 12 : hour}:${date.minute.toString().padLeft(2, '0')} $period';
  }

  // Helper methods for space filtering
  Stream<List<ItemModel>> _getFilteredItemsStream(String? selectedSpace) {
    if (selectedSpace == 'personal') {
      return _repository.watchPersonalItems();
    } else if (selectedSpace == 'shared') {
      return _repository.watchSharedItems();
    } else {
      return _repository.watchAllItems();
    }
  }

  Stream<List<ItemModel>> _getFilteredPinnedStream(String? selectedSpace) async* {
    await for (final allPinned in _repository.watchPinnedItems()) {
      if (selectedSpace == null) {
        yield allPinned;
      } else if (selectedSpace == 'personal') {
        final filtered = <ItemModel>[];
        for (final item in allPinned) {
          final isShared = await _repository.isItemShared(item.itemId);
          if (!isShared) filtered.add(item);
        }
        yield filtered;
      } else if (selectedSpace == 'shared') {
        final filtered = <ItemModel>[];
        for (final item in allPinned) {
          final isShared = await _repository.isItemShared(item.itemId);
          if (isShared) filtered.add(item);
        }
        yield filtered;
      }
    }
  }

  Stream<List<ItemModel>> _getFilteredTodayStream(String? selectedSpace) async* {
    await for (final allToday in _repository.watchTodayItems()) {
      if (selectedSpace == null) {
        yield allToday;
      } else if (selectedSpace == 'personal') {
        final filtered = <ItemModel>[];
        for (final item in allToday) {
          final isShared = await _repository.isItemShared(item.itemId);
          if (!isShared) filtered.add(item);
        }
        yield filtered;
      } else if (selectedSpace == 'shared') {
        final filtered = <ItemModel>[];
        for (final item in allToday) {
          final isShared = await _repository.isItemShared(item.itemId);
          if (isShared) filtered.add(item);
        }
        yield filtered;
      }
    }
  }
}
