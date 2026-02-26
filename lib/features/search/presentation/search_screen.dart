import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:openlist/core/theme/theme.dart';
import 'package:openlist/data/repositories/item_repository.dart';
import 'package:openlist/data/models/item_model.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ItemRepository _repository = ItemRepository();
  List<ItemModel> _searchResults = [];
  bool _isSearching = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _performSearch(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }

    setState(() => _isSearching = true);

    final results = await _repository.searchItems(query);

    setState(() {
      _searchResults = results;
      _isSearching = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDarkMode ? AppColors.bgScaffoldDark : AppColors.bgScaffold,
      appBar: AppBar(
        backgroundColor: isDarkMode ? AppColors.surfaceDark : Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: isDarkMode ? AppColors.textPrimaryDark : AppColors.textPrimary,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: TextField(
          controller: _searchController,
          autofocus: true,
          textDirection: TextDirection.ltr,
          style: GoogleFonts.inter(
            fontSize: 16,
            color: isDarkMode ? AppColors.textPrimaryDark : AppColors.textPrimary,
          ),
          decoration: InputDecoration(
            hintText: 'Search tasks and notes...',
            hintStyle: TextStyle(
              color: isDarkMode ? AppColors.textMutedDark : AppColors.textMuted,
            ),
            border: InputBorder.none,
          ),
          onChanged: (value) {
            _performSearch(value);
          },
        ),
        actions: [
          if (_searchController.text.isNotEmpty)
            IconButton(
              icon: Icon(
                Icons.clear,
                color: isDarkMode ? AppColors.textPrimaryDark : AppColors.textPrimary,
              ),
              onPressed: () {
                _searchController.clear();
                _performSearch('');
              },
            ),
        ],
      ),
      body: _buildBody(isDarkMode),
    );
  }

  Widget _buildBody(bool isDarkMode) {
    if (_isSearching) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_searchController.text.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search,
              size: 64,
              color: isDarkMode ? AppColors.textMutedDark : AppColors.textMuted,
            ),
            const SizedBox(height: 16),
            Text(
              'Search for tasks and notes',
              style: GoogleFonts.inter(
                fontSize: 16,
                color: isDarkMode ? AppColors.textMutedDark : AppColors.textMuted,
              ),
            ),
          ],
        ),
      );
    }

    if (_searchResults.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 64,
              color: isDarkMode ? AppColors.textMutedDark : AppColors.textMuted,
            ),
            const SizedBox(height: 16),
            Text(
              'No results found',
              style: GoogleFonts.inter(
                fontSize: 16,
                color: isDarkMode ? AppColors.textMutedDark : AppColors.textMuted,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final item = _searchResults[index];
        return _buildSearchResultItem(item, isDarkMode);
      },
    );
  }

  Widget _buildSearchResultItem(ItemModel item, bool isDarkMode) {
    return GestureDetector(
      onTap: () {
        context.push('/task/${item.id}');
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDarkMode ? AppColors.surfaceDark : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDarkMode ? AppColors.borderDark : AppColors.border,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  item.type == ItemType.task
                      ? Icons.check_circle_outline
                      : Icons.note_outlined,
                  size: 20,
                  color: item.isCompleted
                      ? AppColors.success
                      : (isDarkMode ? AppColors.textSecondaryDark : AppColors.textSecondary),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    item.title,
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isDarkMode ? AppColors.textPrimaryDark : AppColors.textPrimary,
                      decoration: item.isCompleted ? TextDecoration.lineThrough : null,
                    ),
                  ),
                ),
                if (item.isPinned)
                  Icon(
                    Icons.push_pin,
                    size: 16,
                    color: isDarkMode ? AppColors.textMutedDark : AppColors.textMuted,
                  ),
              ],
            ),
            if (item.dueDate != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.calendar_today,
                    size: 14,
                    color: isDarkMode ? AppColors.textMutedDark : AppColors.textMuted,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _formatDate(item.dueDate!),
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: isDarkMode ? AppColors.textMutedDark : AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final itemDate = DateTime(date.year, date.month, date.day);

    if (itemDate == today) {
      return 'Today';
    } else if (itemDate == tomorrow) {
      return 'Tomorrow';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}
