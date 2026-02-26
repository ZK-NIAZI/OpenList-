import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:openlist/core/theme/theme.dart';
import 'package:openlist/core/widgets/widgets.dart';
import 'package:openlist/core/providers/navigation_provider.dart';
import 'package:openlist/features/task/presentation/quick_add_dialog.dart';
import 'package:openlist/core/providers/space_provider.dart';
import 'package:openlist/data/repositories/item_repository.dart';

class AppSidebar extends ConsumerStatefulWidget {
  const AppSidebar({super.key});

  @override
  ConsumerState<AppSidebar> createState() => _AppSidebarState();
}

class _AppSidebarState extends ConsumerState<AppSidebar> {
  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Drawer(
      child: Container(
        color: isDarkMode ? AppColors.bgScaffoldDark : Colors.white,
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(20),
                child: const OpenListBrandWidget(
                  iconSize: 40,
                  showTagline: false,
                ),
              ),

              // Quick Add Button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: Builder(
                    builder: (context) => ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          showDialog(
                            context: context,
                            builder: (context) => const QuickAddDialog(),
                          );
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Quick Add'),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Menu Items
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    _buildMenuItem(
                      context,
                      icon: Icons.inbox,
                      label: 'Inbox',
                      badge: '0',
                      isActive: false,
                      onTap: () {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Inbox coming soon!')),
                        );
                      },
                    ),
                    _buildMenuItem(
                      context,
                      icon: Icons.today,
                      label: 'Today',
                      isActive: false,
                      onTap: () {
                        ref.read(navigationIndexProvider.notifier).state = 1;
                        Navigator.pop(context);
                      },
                    ),
                    _buildMenuItem(
                      context,
                      icon: Icons.upcoming,
                      label: 'Upcoming',
                      isActive: false,
                      onTap: () {
                        Navigator.pop(context);
                        context.push('/upcoming');
                      },
                    ),
                    _buildMenuItem(
                      context,
                      icon: Icons.note,
                      label: 'Notes',
                      isActive: false,
                      onTap: () {
                        Navigator.pop(context);
                        context.push('/notes');
                      },
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // SPACES Section
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      child: Text(
                        'SPACES',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: isDarkMode ? AppColors.textMutedDark : AppColors.textMuted,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    
                    _buildSpaceItem(
                      context,
                      icon: Icons.person,
                      label: 'Personal',
                      color: AppColors.primary,
                      isActive: ref.watch(selectedSpaceProvider) == 'personal',
                      onTap: () async {
                        // Refresh share status cache before filtering
                        await ItemRepository().refreshShareStatus();
                        ref.read(selectedSpaceProvider.notifier).state = 'personal';
                        Navigator.pop(context);
                        context.go('/dashboard');
                      },
                    ),
                    
                    _buildSpaceItem(
                      context,
                      icon: Icons.people,
                      label: 'Shared',
                      color: AppColors.success,
                      isActive: ref.watch(selectedSpaceProvider) == 'shared',
                      onTap: () async {
                        // Refresh share status cache before filtering
                        await ItemRepository().refreshShareStatus();
                        ref.read(selectedSpaceProvider.notifier).state = 'shared';
                        Navigator.pop(context);
                        context.go('/dashboard');
                      },
                    ),
                  ],
                ),
              ),

              // Bottom Profile
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(color: isDarkMode ? AppColors.borderDark : Colors.grey.shade300),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight,
                        shape: BoxShape.circle,
                      ),
                      child: const Center(
                        child: Text(
                          'JD',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'John Doe',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: isDarkMode ? AppColors.textPrimaryDark : Colors.black87,
                            ),
                          ),
                          const Text(
                            'PRO PLAN',
                            style: TextStyle(
                              fontSize: 10,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.settings,
                        color: isDarkMode ? AppColors.textSecondaryDark : Colors.grey,
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                        context.push('/settings');
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    String? badge,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(
        color: isActive ? AppColors.primaryLight : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        leading: Icon(
          icon,
          color: isActive ? AppColors.primary : (isDarkMode ? AppColors.textSecondaryDark : Colors.grey),
          size: 20,
        ),
        title: Text(
          label,
          style: TextStyle(
            color: isActive ? AppColors.primary : (isDarkMode ? AppColors.textPrimaryDark : Colors.black87),
            fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
        trailing: badge != null
            ? Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: isActive ? AppColors.primary : Colors.grey,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  badge,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              )
            : null,
        onTap: onTap,
        dense: true,
      ),
    );
  }

  Widget _buildSpaceItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(
        color: isActive ? color.withOpacity(0.1) : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        leading: Row(
          mainAxisSize: MainAxisSize.min,
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
            Icon(
              icon,
              color: isActive ? color : (isDarkMode ? AppColors.textSecondaryDark : Colors.grey),
              size: 20,
            ),
          ],
        ),
        title: Text(
          label,
          style: TextStyle(
            color: isActive ? color : (isDarkMode ? AppColors.textPrimaryDark : Colors.black87),
            fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
        onTap: onTap,
        dense: true,
      ),
    );
  }
}
