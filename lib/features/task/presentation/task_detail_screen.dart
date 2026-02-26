import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:openlist/core/theme/theme.dart';
import 'package:openlist/core/widgets/widgets.dart';
import 'package:openlist/data/repositories/item_repository.dart';
import 'package:openlist/data/repositories/sharing_repository.dart';
import 'package:openlist/data/models/item_model.dart';
import 'package:openlist/data/models/block_model.dart';
import 'package:openlist/features/sharing/presentation/share_dialog.dart';
import 'package:openlist/features/task/presentation/quick_add_sheet.dart';
import 'package:openlist/services/ai_extraction_service.dart';
import 'package:openlist/utils/date_parser.dart';
import 'package:uuid/uuid.dart';

class TaskDetailScreen extends ConsumerStatefulWidget {
  final String? taskId;

  const TaskDetailScreen({
    super.key,
    this.taskId,
  });

  @override
  ConsumerState<TaskDetailScreen> createState() => _TaskDetailScreenState();
}

class _TaskDetailScreenState extends ConsumerState<TaskDetailScreen> {
  final TextEditingController _titleController = TextEditingController();
  final ItemRepository _repository = ItemRepository();
  final SharingRepository _sharingRepository = SharingRepository();
  final _storage = const FlutterSecureStorage();
  final _uuid = const Uuid();
  
  // Use ValueNotifier for better performance (no setState rebuilds)
  final ValueNotifier<List<BlockModel>> _blocksNotifier = ValueNotifier([]);
  final ValueNotifier<List<ItemModel>> _subTasksNotifier = ValueNotifier([]);
  
  ItemModel? _currentItem;
  ItemModel? _parentItem;
  bool _isLoading = true;
  bool _hasChanges = false;
  bool _isExtractingTasks = false;
  bool _aiEnabled = false;

  @override
  void initState() {
    super.initState();
    _loadTask();
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

  Future<void> _loadTask() async {
    if (widget.taskId == null || widget.taskId == 'new') {
      // Create new task
      final newItem = await _repository.createItem(
        title: 'Untitled Task',
        type: ItemType.task,
      );
      setState(() {
        _currentItem = newItem;
        _titleController.text = newItem.title;
        _isLoading = false;
      });
      _loadBlocks(); // Load blocks for new task too
    } else {
      // Load existing task
      try {
        final item = await _repository.getItemById(int.parse(widget.taskId!));
        if (item != null) {
          setState(() {
            _currentItem = item;
            _titleController.text = item.title;
            _isLoading = false;
          });
          _loadBlocks();
        }
      } catch (e) {
        print('Error loading task: $e');
        setState(() => _isLoading = false);
      }
    }
  }

  void _loadBlocks() {
    if (_currentItem == null) return;
    
    // Use ValueNotifier instead of setState for better performance
    _repository.watchBlocks(_currentItem!.itemId).listen((blocks) {
      if (mounted) {
        _blocksNotifier.value = blocks;
      }
    });
    
    // Load sub-tasks
    _repository.watchSubTasks(_currentItem!.itemId).listen((subTasks) {
      if (mounted) {
        _subTasksNotifier.value = subTasks;
      }
    });
    
    // Load parent if this is a child task
    if (_currentItem!.parentId != null) {
      _repository.getParentTask(_currentItem!.itemId).then((parent) {
        if (mounted && parent != null) {
          setState(() {
            _parentItem = parent;
          });
        }
      });
    }
  }

  Future<void> _autoSave() async {
    if (_currentItem == null) return;

    final newTitle = _titleController.text.trim().isEmpty 
        ? 'Untitled Task' 
        : _titleController.text.trim();
    
    // Only save if title actually changed
    if (_currentItem!.title != newTitle) {
      _currentItem!.title = newTitle;
      
      try {
        await _repository.updateItem(_currentItem!);
        if (mounted) {
          _hasChanges = false;
        }
      } catch (e) {
        debugPrint('Auto-save failed: $e');
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _blocksNotifier.dispose();
    _subTasksNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    if (_isLoading) {
      return Scaffold(
        backgroundColor: isDarkMode ? AppColors.bgScaffoldDark : AppColors.bgScaffold,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_currentItem == null) {
      return Scaffold(
        backgroundColor: isDarkMode ? AppColors.bgScaffoldDark : AppColors.bgScaffold,
        appBar: AppBar(
          backgroundColor: isDarkMode ? AppColors.bgScaffoldDark : AppColors.bgScaffold,
          title: const Text('Error'),
        ),
        body: const Center(child: Text('Task not found')),
      );
    }

    return WillPopScope(
      onWillPop: () async {
        await _autoSave();
        return true;
      },
      child: Scaffold(
        backgroundColor: isDarkMode ? AppColors.bgScaffoldDark : AppColors.bgScaffold,
        appBar: AppBar(
          backgroundColor: isDarkMode ? AppColors.surfaceDark : Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: Icon(
              Icons.arrow_back, 
              color: isDarkMode ? AppColors.textPrimaryDark : AppColors.textPrimary,
            ),
            onPressed: () async {
              await _autoSave();
              if (mounted) Navigator.pop(context);
            },
          ),
          title: _parentItem != null
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _currentItem!.title,
                      style: GoogleFonts.inter(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: isDarkMode ? AppColors.textPrimaryDark : AppColors.textPrimary,
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        // Navigate back to parent
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) => TaskDetailScreen(
                              taskId: _parentItem!.id.toString(),
                            ),
                          ),
                        );
                      },
                      child: Text(
                        '📍 ${_parentItem!.title}',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                )
              : Text(
                  _currentItem!.title,
                  style: GoogleFonts.inter(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: isDarkMode ? AppColors.textPrimaryDark : AppColors.textPrimary,
                  ),
                ),
          actions: [
            IconButton(
              icon: Icon(
                Icons.share_outlined,
                color: isDarkMode ? AppColors.textPrimaryDark : AppColors.textPrimary,
              ),
              onPressed: () => _showShareDialog(context),
            ),
            IconButton(
              icon: Icon(
                _currentItem!.isPinned ? Icons.push_pin : Icons.push_pin_outlined,
                color: isDarkMode ? AppColors.textPrimaryDark : AppColors.textPrimary,
              ),
              onPressed: _togglePin,
            ),
            IconButton(
              icon: Icon(
                Icons.more_vert, 
                color: isDarkMode ? AppColors.textPrimaryDark : AppColors.textPrimary,
              ),
              onPressed: () => _showMoreMenu(context),
            ),
          ],
        ),
        body: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title Input
                    TextField(
                      controller: _titleController,
                      textDirection: TextDirection.ltr,
                      style: GoogleFonts.inter(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: isDarkMode ? AppColors.textPrimaryDark : AppColors.textPrimary,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Task title...',
                        hintStyle: TextStyle(
                          color: isDarkMode ? AppColors.textMutedDark : AppColors.textMuted,
                        ),
                        border: InputBorder.none,
                      ),
                      onChanged: (value) {
                        _hasChanges = true;
                      },
                    ),

                    const SizedBox(height: 20),

                    // Parent info (if this is a child task)
                    if (_parentItem != null) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isDarkMode ? AppColors.surfaceDark : AppColors.borderLight,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isDarkMode ? AppColors.borderDark : AppColors.border,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (_parentItem!.dueDate != null) ...[
                              Row(
                                children: [
                                  Icon(Icons.calendar_today, size: 14, color: AppColors.primary),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Due: ${_formatDate(_parentItem!.dueDate!)} (from parent)',
                                    style: GoogleFonts.inter(
                                      fontSize: 13,
                                      color: isDarkMode ? AppColors.textSecondaryDark : AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                            if (_parentItem!.reminderAt != null) ...[
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Icon(Icons.notifications, size: 14, color: AppColors.warning),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Reminder: ${_formatDate(_parentItem!.reminderAt!)} (from parent)',
                                    style: GoogleFonts.inter(
                                      fontSize: 13,
                                      color: isDarkMode ? AppColors.textSecondaryDark : AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],

                    // Blocks - Use ValueListenableBuilder for better performance
                    ValueListenableBuilder<List<BlockModel>>(
                      valueListenable: _blocksNotifier,
                      builder: (context, blocks, child) {
                        return Column(
                          children: blocks.map((block) => _buildBlock(block)).toList(),
                        );
                      },
                    ),

                    const SizedBox(height: 20),

                    // Add Sub-task Button (only show for tasks, not notes)
                    if (_currentItem!.type == ItemType.task) ...[
                      ElevatedButton.icon(
                        onPressed: _addSubTask,
                        icon: const Icon(Icons.add),
                        label: const Text('Add Sub-task'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isDarkMode ? AppColors.surfaceDark : AppColors.borderLight,
                          foregroundColor: isDarkMode ? AppColors.textPrimaryDark : AppColors.textPrimary,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                            side: BorderSide(
                              color: isDarkMode ? AppColors.borderDark : AppColors.border,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],

                    // Sub-tasks List (only show for tasks, not notes)
                    if (_currentItem!.type == ItemType.task)
                      ValueListenableBuilder<List<ItemModel>>(
                        valueListenable: _subTasksNotifier,
                        builder: (context, subTasks, child) {
                          if (subTasks.isEmpty) {
                            return const SizedBox.shrink();
                          }

                          final completedCount = subTasks.where((t) => t.isCompleted).length;

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '📋 Sub-tasks ($completedCount/${subTasks.length} completed)',
                                style: GoogleFonts.inter(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: isDarkMode ? AppColors.textPrimaryDark : AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 12),
                              ...subTasks.map((subTask) => _buildSubTaskItem(subTask)),
                            ],
                          );
                        },
                      ),

                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),

            // Bottom Toolbar
            _buildBottomToolbar(),

            // Mark as Complete Button
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDarkMode ? AppColors.surfaceDark : Colors.white,
                border: Border(
                  top: BorderSide(
                    color: isDarkMode ? AppColors.borderDark : AppColors.border,
                  ),
                ),
              ),
              child: SafeArea(
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _toggleComplete,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _currentItem!.isCompleted 
                          ? AppColors.textMuted 
                          : AppColors.success,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      _currentItem!.isCompleted ? 'Mark as Incomplete' : 'Mark as Complete',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBlock(BlockModel block) {
    switch (block.type) {
      case BlockType.text:
        return _buildTextBlock(block);
      case BlockType.heading:
        return _buildHeadingBlock(block);
      case BlockType.checklist:
        return _buildChecklistBlock(block);
      case BlockType.bullet:
        return _buildBulletBlock(block);
      case BlockType.subTask:
        return _buildTaskBlock(block);
      default:
        return _buildTextBlock(block);
    }
  }

  Widget _buildTextBlock(BlockModel block) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        key: ValueKey(block.blockId),
        initialValue: block.content,
        textDirection: TextDirection.ltr,
        style: GoogleFonts.inter(
          fontSize: 15,
          color: isDarkMode ? AppColors.textPrimaryDark : AppColors.textPrimary,
          height: 1.5,
        ),
        decoration: const InputDecoration(
          border: InputBorder.none,
          hintText: 'Type something...',
        ),
        maxLines: null,
        onChanged: (value) {
          block.content = value;
          _repository.updateBlock(block);
        },
      ),
    );
  }

  Widget _buildHeadingBlock(BlockModel block) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16, top: 8),
      child: TextFormField(
        key: ValueKey(block.blockId),
        initialValue: block.content,
        textDirection: TextDirection.ltr,
        style: GoogleFonts.inter(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: isDarkMode ? AppColors.textPrimaryDark : AppColors.textPrimary,
        ),
        decoration: InputDecoration(
          border: InputBorder.none,
          hintText: 'Heading...',
          hintStyle: TextStyle(
            color: isDarkMode ? AppColors.textMutedDark : AppColors.textMuted,
          ),
        ),
        onChanged: (value) {
          block.content = value;
          _repository.updateBlock(block);
        },
      ),
    );
  }

  Widget _buildChecklistBlock(BlockModel block) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () {
              setState(() {
                block.isChecked = !block.isChecked;
              });
              _repository.updateBlock(block);
            },
            child: Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: block.isChecked ? AppColors.primary : (isDarkMode ? AppColors.surfaceDark : Colors.white),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: block.isChecked ? AppColors.primary : (isDarkMode ? AppColors.borderDark : AppColors.border),
                  width: 2,
                ),
              ),
              child: block.isChecked
                  ? const Icon(Icons.check, size: 16, color: Colors.white)
                  : null,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TextFormField(
              key: ValueKey('${block.blockId}_text'),
              initialValue: block.content,
              textDirection: TextDirection.ltr,
              style: GoogleFonts.inter(
                fontSize: 15,
                color: block.isChecked ? (isDarkMode ? AppColors.textMutedDark : AppColors.textMuted) : (isDarkMode ? AppColors.textPrimaryDark : AppColors.textPrimary),
                decoration: block.isChecked ? TextDecoration.lineThrough : null,
                height: 1.5,
              ),
              decoration: const InputDecoration(
                border: InputBorder.none,
                hintText: 'Checklist item...',
              ),
              onChanged: (value) {
                block.content = value;
                _repository.updateBlock(block);
              },
            ),
          ),
          IconButton(
            icon: Icon(Icons.close, size: 18, color: isDarkMode ? AppColors.textMutedDark : AppColors.textMuted),
            onPressed: () {
              _repository.deleteBlock(block.id);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildBulletBlock(BlockModel block) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 6,
            height: 6,
            margin: const EdgeInsets.only(top: 8),
            decoration: const BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TextFormField(
              key: ValueKey(block.blockId),
              initialValue: block.content,
              textDirection: TextDirection.ltr,
              style: GoogleFonts.inter(
                fontSize: 15,
                color: isDarkMode ? AppColors.textPrimaryDark : AppColors.textPrimary,
                height: 1.5,
              ),
              decoration: const InputDecoration(
                border: InputBorder.none,
                hintText: 'Bullet point...',
              ),
              onChanged: (value) {
                block.content = value;
                _repository.updateBlock(block);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomToolbar() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isDarkMode ? AppColors.surfaceDark : Colors.white,
        border: Border(
          top: BorderSide(
            color: isDarkMode ? AppColors.borderDark : AppColors.border,
          ),
        ),
      ),
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _buildToolbarButton(
            icon: Icons.text_fields,
            label: 'Text',
            onTap: () => _addBlock(BlockType.text),
          ),
          const SizedBox(width: 8),
          _buildToolbarButton(
            icon: Icons.title,
            label: 'Heading',
            onTap: () => _addBlock(BlockType.heading),
          ),
          const SizedBox(width: 8),
          _buildToolbarButton(
            icon: Icons.check_box_outlined,
            label: 'Checklist',
            onTap: () => _addBlock(BlockType.checklist),
          ),
          const SizedBox(width: 8),
          _buildToolbarButton(
            icon: Icons.circle,
            label: 'Bullet',
            onTap: () => _addBlock(BlockType.bullet),
          ),
          const SizedBox(width: 8),
          _buildToolbarButton(
            icon: Icons.task_alt,
            label: 'Task',
            onTap: () => _addTaskBlock(),
          ),
          if (_aiEnabled && _currentItem?.type == ItemType.note) ...[
            const SizedBox(width: 8),
            _buildToolbarButton(
              icon: _isExtractingTasks ? Icons.hourglass_empty : Icons.auto_awesome,
              label: 'AI Extract',
              onTap: () {
                if (!_isExtractingTasks) {
                  _extractTasksFromNote();
                }
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildToolbarButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isDarkMode ? AppColors.bgScaffoldDark : AppColors.borderLight,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 18,
              color: isDarkMode ? AppColors.textSecondaryDark : AppColors.textSecondary,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: isDarkMode ? AppColors.textSecondaryDark : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _addBlock(BlockType type) async {
    if (_currentItem == null) return;

    await _repository.createBlock(
      itemId: _currentItem!.itemId,
      type: type,
      content: '',
      orderIndex: _blocksNotifier.value.length,
    );
    // No need to update UI - stream will handle it
  }

  bool _isAddingTask = false;

  Future<void> _addTaskBlock() async {
    if (_currentItem == null) return;
    if (_isAddingTask) return; // Prevent multiple simultaneous calls
    
    _isAddingTask = true;

    try {
      // Show QuickAddSheet to create a standalone task
      await showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: QuickAddSheet(),
        ),
      );

      // Wait a bit for the task to be saved
      await Future.delayed(const Duration(milliseconds: 500));
      
      // Get the most recently created task
      final recentTasks = await _repository.getRecentTasks(limit: 1);
      if (recentTasks.isNotEmpty) {
        final taskItem = recentTasks.first;
        
        print('📝 Task created: ${taskItem.title} (itemId: ${taskItem.itemId})');
        
        // Create a block that references this task (NOT a sub-task, just a reference)
        await _repository.createBlock(
          itemId: _currentItem!.itemId,
          type: BlockType.subTask,
          content: taskItem.itemId, // Store task item_id in content
          orderIndex: _blocksNotifier.value.length,
        );
        
        print('✅ Block created linking to task');
        
        // IMPORTANT: Copy shares from the note to the task
        // This ensures people who can see the note can also see the task
        await _copySharesFromNoteToTask(_currentItem!.itemId, taskItem.itemId);
      }
    } finally {
      _isAddingTask = false;
    }
    // Stream will handle UI update
  }

  // Copy all shares from the note to the newly created task
  Future<void> _copySharesFromNoteToTask(String noteItemId, String taskItemId) async {
    try {
      // Get all shares for the note
      final shares = await _sharingRepository.getItemShares(noteItemId);
      
      if (shares.isEmpty) {
        print('📝 Note is not shared, task will remain private');
        return;
      }
      
      print('📤 Copying ${shares.length} shares from note to task...');
      
      // Create the same shares for the task
      for (final share in shares) {
        await _sharingRepository.shareItem(
          itemId: taskItemId,
          userId: share.userId,
          permission: share.permission,
        );
        print('   ✅ Shared task with user: ${share.userId} (${share.permission})');
      }
      
      print('✅ Task shares copied successfully');
    } catch (e) {
      print('❌ Failed to copy shares: $e');
      // Don't throw - task is still created, just not shared
    }
  }

  // Extract tasks from note content using AI
  Future<void> _extractTasksFromNote() async {
    if (_currentItem == null || _currentItem!.type != ItemType.note) return;
    if (_isExtractingTasks) return;

    setState(() {
      _isExtractingTasks = true;
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

      // Collect all text content from blocks
      final noteContent = StringBuffer();
      noteContent.writeln(_currentItem!.title); // Include title
      
      for (final block in _blocksNotifier.value) {
        if (block.type == BlockType.text || 
            block.type == BlockType.heading ||
            block.type == BlockType.bullet) {
          noteContent.writeln(block.content);
        }
      }

      final fullText = noteContent.toString().trim();
      if (fullText.isEmpty) {
        if (mounted) {
          _showError('Note is empty. Add some content first.');
        }
        return;
      }

      // Extract with AI
      final service = AIExtractionService(apiKey);
      final extraction = await service.extractTask(fullText);

      if (extraction == null) {
        if (mounted) {
          _showError('Could not extract tasks. Try adding more specific task descriptions.');
        }
        return;
      }

      // Check if it's actually a task
      if (!extraction.isTask) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('No clear tasks found in this note. Try adding phrases like "tomorrow", "deadline", or specific dates.'),
              action: SnackBarAction(
                label: 'OK',
                onPressed: () {},
              ),
              duration: const Duration(seconds: 4),
            ),
          );
        }
        return;
      }

      // Create the task
      final taskItem = await _repository.createItem(
        title: extraction.title,
        type: ItemType.task,
        dueDate: extraction.dueDate,
        reminderAt: extraction.reminderAt ?? (extraction.dueDate != null 
            ? DateParser.calculateReminderTime(extraction.dueDate!, minutesBefore: reminderOffset)
            : null),
      );

      print('📝 AI extracted task: ${taskItem.title}');

      // Create a block that references this task
      await _repository.createBlock(
        itemId: _currentItem!.itemId,
        type: BlockType.subTask,
        content: taskItem.itemId,
        orderIndex: _blocksNotifier.value.length,
      );

      // Copy shares from note to task
      await _copySharesFromNoteToTask(_currentItem!.itemId, taskItem.itemId);

      // Show success message
      if (mounted) {
        final keywords = extraction.detectedKeywords.take(3).join(', ');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.auto_awesome, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text('✨ Task extracted: "${extraction.title}"${keywords.isNotEmpty ? " ($keywords)" : ""}'),
                ),
              ],
            ),
            backgroundColor: AppColors.success,
            duration: const Duration(seconds: 3),
          ),
        );
      }

    } catch (e) {
      if (mounted) {
        _showError('AI extraction failed: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isExtractingTasks = false;
        });
      }
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

  Widget _buildTaskBlock(BlockModel block) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return FutureBuilder<ItemModel?>(
      future: _repository.getItemByItemId(block.content),
      builder: (context, snapshot) {
        // Show loading only briefly
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(
            height: 60,
            child: Center(child: CircularProgressIndicator()),
          );
        }

        // If task doesn't exist or failed to load, show error state
        if (!snapshot.hasData || snapshot.data == null) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDarkMode ? AppColors.surfaceDark : AppColors.borderLight,
                border: Border.all(
                  color: isDarkMode ? AppColors.borderDark : AppColors.border,
                  width: 1.5,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.error_outline,
                    color: AppColors.danger,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Task not found or not synced yet',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: isDarkMode ? AppColors.textMutedDark : AppColors.textMuted,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        final taskItem = snapshot.data!;

        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: InkWell(
            onTap: () {
              // Navigate to task detail page
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => TaskDetailScreen(
                    taskId: taskItem.id.toString(),
                  ),
                ),
              );
            },
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDarkMode ? AppColors.bgScaffoldDark : AppColors.borderLight,
                border: Border.all(
                  color: taskItem.isCompleted
                      ? AppColors.success
                      : (isDarkMode ? AppColors.borderDark : AppColors.border),
                  width: 1.5,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  // Checkbox
                  GestureDetector(
                    onTap: () async {
                      await _repository.toggleComplete(taskItem.id);
                      setState(() {}); // Rebuild to show updated state
                    },
                    child: Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: taskItem.isCompleted
                            ? AppColors.success
                            : (isDarkMode ? AppColors.surfaceDark : Colors.white),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: taskItem.isCompleted
                              ? AppColors.success
                              : (isDarkMode ? AppColors.borderDark : AppColors.border),
                          width: 2,
                        ),
                      ),
                      child: taskItem.isCompleted
                          ? const Icon(Icons.check, size: 16, color: Colors.white)
                          : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Task title
                  Expanded(
                    child: Text(
                      taskItem.title,
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: taskItem.isCompleted
                            ? (isDarkMode ? AppColors.textMutedDark : AppColors.textMuted)
                            : (isDarkMode ? AppColors.textPrimaryDark : AppColors.textPrimary),
                        decoration: taskItem.isCompleted
                            ? TextDecoration.lineThrough
                            : null,
                      ),
                    ),
                  ),
                  // Due date badge (if set)
                  if (taskItem.dueDate != null) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getDueDateColor(taskItem.dueDate!),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        _formatDate(taskItem.dueDate!),
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                  // Arrow icon
                  const SizedBox(width: 8),
                  Icon(
                    Icons.chevron_right,
                    size: 20,
                    color: isDarkMode ? AppColors.textMutedDark : AppColors.textMuted,
                  ),
                  // Delete button
                  IconButton(
                    icon: Icon(
                      Icons.close,
                      size: 18,
                      color: isDarkMode ? AppColors.textMutedDark : AppColors.textMuted,
                    ),
                    onPressed: () async {
                      // Delete the task item and the block
                      await _repository.deleteItem(taskItem.id);
                      await _repository.deleteBlock(block.id);
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Color _getDueDateColor(DateTime dueDate) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final due = DateTime(dueDate.year, dueDate.month, dueDate.day);

    if (due.isBefore(today)) {
      return AppColors.danger; // Overdue
    } else if (due.isAtSameMomentAs(today)) {
      return AppColors.warning; // Due today
    } else {
      return AppColors.primary; // Future
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final dateOnly = DateTime(date.year, date.month, date.day);

    if (dateOnly.isAtSameMomentAs(today)) {
      return 'Today';
    } else if (dateOnly.isAtSameMomentAs(tomorrow)) {
      return 'Tomorrow';
    } else {
      return '${date.month}/${date.day}';
    }
  }

  Future<void> _addSubTask() async {
    if (_currentItem == null) return;

    final subTask = await _repository.createSubTask(
      parentItemId: _currentItem!.itemId,
      title: 'New Sub-task',
    );

    // Navigate to sub-task detail
    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => TaskDetailScreen(
            taskId: subTask.id.toString(),
          ),
        ),
      );
    }
  }

  Widget _buildSubTaskItem(ItemModel subTask) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => TaskDetailScreen(
                taskId: subTask.id.toString(),
              ),
            ),
          );
        },
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isDarkMode ? AppColors.bgScaffoldDark : Colors.white,
            border: Border.all(
              color: subTask.isCompleted
                  ? AppColors.success
                  : (isDarkMode ? AppColors.borderDark : AppColors.border),
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              // Checkbox
              GestureDetector(
                onTap: () async {
                  await _repository.toggleComplete(subTask.id);
                  // Check if all sub-tasks are completed
                  await _repository.checkAndCompleteParent(_currentItem!.itemId);
                },
                child: Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: subTask.isCompleted
                        ? AppColors.success
                        : (isDarkMode ? AppColors.surfaceDark : Colors.white),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: subTask.isCompleted
                          ? AppColors.success
                          : (isDarkMode ? AppColors.borderDark : AppColors.border),
                      width: 2,
                    ),
                  ),
                  child: subTask.isCompleted
                      ? const Icon(Icons.check, size: 14, color: Colors.white)
                      : null,
                ),
              ),
              const SizedBox(width: 12),
              // Title
              Expanded(
                child: Text(
                  subTask.title,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: subTask.isCompleted
                        ? (isDarkMode ? AppColors.textMutedDark : AppColors.textMuted)
                        : (isDarkMode ? AppColors.textPrimaryDark : AppColors.textPrimary),
                    decoration: subTask.isCompleted
                        ? TextDecoration.lineThrough
                        : null,
                  ),
                ),
              ),
              // Arrow
              Icon(
                Icons.chevron_right,
                size: 18,
                color: isDarkMode ? AppColors.textMutedDark : AppColors.textMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _togglePin() {
    if (_currentItem == null) return;
    
    setState(() {
      _currentItem!.isPinned = !_currentItem!.isPinned;
    });
    
    _repository.updateItem(_currentItem!);
  }

  void _toggleComplete() {
    if (_currentItem == null) return;
    
    _repository.toggleComplete(_currentItem!.id);
    
    setState(() {
      _currentItem!.isCompleted = !_currentItem!.isCompleted;
    });
  }

  void _showShareDialog(BuildContext context) {
    if (_currentItem == null) return;

    showDialog(
      context: context,
      builder: (context) => ShareDialog(
        itemId: _currentItem!.itemId,
        itemTitle: _currentItem!.title,
      ),
    );
  }

  void _showMoreMenu(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      backgroundColor: isDarkMode ? AppColors.surfaceDark : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.delete_outline, color: AppColors.danger),
              title: Text(
                'Delete',
                style: GoogleFonts.inter(
                  color: AppColors.danger,
                  fontWeight: FontWeight.w600,
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                _deleteTask();
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteTask() async {
    if (_currentItem == null) return;

    await _repository.deleteItem(_currentItem!.id);
    
    if (mounted) {
      Navigator.pop(context);
    }
  }
}
