import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:openlist/core/theme/theme.dart';
import 'package:openlist/features/sidebar/presentation/app_sidebar.dart';
import 'package:openlist/data/repositories/item_repository.dart';
import 'package:openlist/data/repositories/space_repository.dart';
import 'package:openlist/data/models/item_model.dart';
import 'package:openlist/data/models/space_model.dart';
import 'package:openlist/core/providers/space_provider.dart';

class NotesScreen extends ConsumerStatefulWidget {
  const NotesScreen({super.key});

  @override
  ConsumerState<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends ConsumerState<NotesScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final ItemRepository _repository = ItemRepository();
  final SpaceRepository _spaceRepository = SpaceRepository();
  List<SpaceModel> _spaces = [];

  @override
  void initState() {
    super.initState();
    _loadSpaces();
  }

  Future<void> _loadSpaces() async {
    final spaces = await _spaceRepository.getAllSpaces();
    setState(() {
      _spaces = spaces;
    });
  }

  void _openDrawer() {
    _scaffoldKey.currentState?.openDrawer();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
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
          'Notes',
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
                  context.push('/search');
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
            // Pinned Notes
            Text(
              'Pinned',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: isDarkMode ? AppColors.textPrimaryDark : AppColors.textPrimary,
              ),
            ),
            
            const SizedBox(height: 12),
            
            StreamBuilder<List<ItemModel>>(
              stream: _getFilteredNotesStream(ref.watch(selectedSpaceProvider)),
              builder: (context, snapshot) {
                var pinnedNotes = (snapshot.data ?? [])
                    .where((item) => item.type == ItemType.note && item.isPinned)
                    .toList();
                
                print('🔍 PINNED NOTES: Total = ${pinnedNotes.length}');
                for (final note in pinnedNotes) {
                  print('   📌 "${note.title}" - createdBy: ${note.createdBy}');
                }
                
                if (pinnedNotes.isEmpty) {
                  return _buildEmptySection('No pinned notes');
                }
                
                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 0.85,
                  ),
                  itemCount: pinnedNotes.length,
                  itemBuilder: (context, index) {
                    return _buildNoteCard(pinnedNotes[index]);
                  },
                );
              },
            ),
            
            const SizedBox(height: 24),
            
            // All Notes
            Text(
              'All Notes',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: isDarkMode ? AppColors.textPrimaryDark : AppColors.textPrimary,
              ),
            ),
            
            const SizedBox(height: 12),
            
            StreamBuilder<List<ItemModel>>(
              stream: _getFilteredNotesStream(ref.watch(selectedSpaceProvider)),
              builder: (context, snapshot) {
                var allNotes = (snapshot.data ?? [])
                    .where((item) => item.type == ItemType.note && !item.isPinned)
                    .toList();
                
                print('🔍 NOTES SCREEN: Total notes = ${allNotes.length}');
                for (final note in allNotes) {
                  print('   📝 "${note.title}" - createdBy: ${note.createdBy}');
                }
                
                if (allNotes.isEmpty) {
                  return _buildEmptySection('No notes yet');
                }
                
                return Column(
                  children: allNotes.map((note) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _buildNoteListItem(note),
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

  Widget _buildNoteCard(ItemModel note) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: () {
        context.push('/task/${note.id}');
      },
      child: Container(
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
            if (note.category != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getCategoryColor(note.category!).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  note.category!.toUpperCase(),
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: _getCategoryColor(note.category!),
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            const SizedBox(height: 8),
            Text(
              note.title,
              style: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: isDarkMode ? AppColors.textPrimaryDark : AppColors.textPrimary,
                height: 1.3,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            if (note.content != null) ...[
              const SizedBox(height: 6),
              Expanded(
                child: Text(
                  note.content!,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                    color: isDarkMode ? AppColors.textMutedDark : AppColors.textMuted,
                    height: 1.3,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildNoteListItem(ItemModel note) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: () {
        context.push('/task/${note.id}');
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDarkMode ? AppColors.surfaceDark : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isDarkMode ? AppColors.borderDark : AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    note.title,
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isDarkMode ? AppColors.textPrimaryDark : AppColors.textPrimary,
                    ),
                  ),
                ),
                if (note.category != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getCategoryColor(note.category!).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      note.category!.toUpperCase(),
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: _getCategoryColor(note.category!),
                      ),
                    ),
                  ),
              ],
            ),
            if (note.content != null) ...[
              const SizedBox(height: 8),
              Text(
                note.content!,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: isDarkMode ? AppColors.textMutedDark : AppColors.textMuted,
                  height: 1.4,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
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

  Widget _buildSpaceChip(String label, String? spaceId) {
    final selectedSpaceId = ref.watch(selectedSpaceProvider);
    final isSelected = selectedSpaceId == spaceId;
    final space = _spaces.firstWhere((s) => s.spaceId == spaceId, orElse: () => SpaceModel());
    
    return GestureDetector(
      onTap: () {
        ref.read(selectedSpaceProvider.notifier).setSpace(spaceId);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (spaceId != null) ...[
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: Color(int.parse(space.color.replaceFirst('#', '0xFF'))),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddSpaceDialog() {
    final nameController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('New Space', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
        content: TextField(
          controller: nameController,
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'Space name',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.trim().isNotEmpty) {
                await _spaceRepository.createSpace(
                  name: nameController.text.trim(),
                );
                await _loadSpaces();
                if (mounted) Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  // Helper method for space filtering
  Stream<List<ItemModel>> _getFilteredNotesStream(String? selectedSpace) {
    if (selectedSpace == 'personal') {
      return _repository.watchPersonalItems();
    } else if (selectedSpace == 'shared') {
      return _repository.watchSharedItems();
    } else {
      return _repository.watchAllItems();
    }
  }
}
