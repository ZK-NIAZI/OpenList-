import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:openlist/core/theme/theme.dart';
import 'package:openlist/data/repositories/item_repository.dart';
import 'package:openlist/data/models/item_model.dart';
import 'package:openlist/core/providers/space_provider.dart';

class UpcomingScreen extends ConsumerWidget {
  const UpcomingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final repository = ItemRepository();

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
        title: Text(
          'Upcoming',
          style: GoogleFonts.inter(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: isDarkMode ? AppColors.textPrimaryDark : AppColors.textPrimary,
          ),
        ),
      ),
      body: StreamBuilder<List<ItemModel>>(
        stream: repository.watchUpcomingItems(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.event_available,
                    size: 64,
                    color: isDarkMode ? AppColors.textMutedDark : AppColors.textMuted,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No upcoming tasks',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      color: isDarkMode ? AppColors.textMutedDark : AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            );
          }

          var items = snapshot.data!;

          // Group by date
          final groupedItems = _groupItemsByDate(items);

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: groupedItems.length,
            itemBuilder: (context, index) {
              final entry = groupedItems.entries.elementAt(index);
              return _buildDateSection(context, entry.key, entry.value, isDarkMode);
            },
          );
        },
      ),
    );
  }

  Map<String, List<ItemModel>> _groupItemsByDate(List<ItemModel> items) {
    final grouped = <String, List<ItemModel>>{};
    
    for (final item in items) {
      if (item.dueDate == null) continue;
      
      final dateKey = _getDateKey(item.dueDate!);
      if (!grouped.containsKey(dateKey)) {
        grouped[dateKey] = [];
      }
      grouped[dateKey]!.add(item);
    }
    
    // Sort by date
    final sortedEntries = grouped.entries.toList()
      ..sort((a, b) => _compareDateKeys(a.key, b.key));
    
    return Map.fromEntries(sortedEntries);
  }

  String _getDateKey(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final itemDate = DateTime(date.year, date.month, date.day);

    if (itemDate == tomorrow) {
      return 'Tomorrow';
    } else if (itemDate.isAfter(tomorrow) && itemDate.isBefore(tomorrow.add(const Duration(days: 7)))) {
      final weekdays = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
      return weekdays[date.weekday - 1];
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  int _compareDateKeys(String a, String b) {
    // Simple comparison - in real app would need proper date parsing
    if (a == 'Tomorrow') return -1;
    if (b == 'Tomorrow') return 1;
    return 0;
  }

  Widget _buildDateSection(BuildContext context, String dateLabel, List<ItemModel> items, bool isDarkMode) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12, top: 8),
          child: Text(
            dateLabel,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isDarkMode ? AppColors.textSecondaryDark : AppColors.textSecondary,
            ),
          ),
        ),
        ...items.map((item) => _buildTaskItem(context, item, isDarkMode)),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildTaskItem(BuildContext context, ItemModel item, bool isDarkMode) {
    return GestureDetector(
      onTap: () {
        context.push('/task/${item.id}');
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDarkMode ? AppColors.surfaceDark : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDarkMode ? AppColors.borderDark : AppColors.border,
          ),
        ),
        child: Row(
          children: [
            Icon(
              item.isCompleted ? Icons.check_circle : Icons.circle_outlined,
              size: 24,
              color: item.isCompleted ? AppColors.success : (isDarkMode ? AppColors.textMutedDark : AppColors.textMuted),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                item.title,
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
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
      ),
    );
  }
}
