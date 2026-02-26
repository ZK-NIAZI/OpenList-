import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:openlist/core/theme/theme.dart';
import 'package:openlist/core/widgets/sync_indicator.dart';
import 'package:openlist/core/widgets/notification_overlay.dart';
import 'package:openlist/core/providers/sync_provider.dart';
import 'package:openlist/core/providers/space_provider.dart';
import 'package:openlist/core/providers/navigation_provider.dart';
import 'package:openlist/data/sync/sync_manager.dart';
import 'package:openlist/features/dashboard/presentation/dashboard_screen.dart';
import 'package:openlist/features/tasks/presentation/tasks_screen.dart';
import 'package:openlist/features/notes/presentation/notes_screen.dart';
import 'package:openlist/features/alerts/presentation/alerts_screen.dart';

class MainNavigation extends ConsumerStatefulWidget {
  const MainNavigation({super.key});

  @override
  ConsumerState<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends ConsumerState<MainNavigation> {
  final List<Widget> _screens = [
    const DashboardScreen(),
    const TasksScreen(),
    const NotesScreen(),
    const AlertsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    
    // Trigger sync on app start / dashboard load
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      SyncManager.instance.triggerSync();
    });
    
    // Set up sync status callback
    SyncManager.instance.onSyncStatusChanged = (isSyncing, success) {
      if (mounted) {
        if (isSyncing) {
          ref.read(syncStatusProvider.notifier).startSync();
        } else if (success) {
          ref.read(syncStatusProvider.notifier).syncSuccess();
        } else {
          ref.read(syncStatusProvider.notifier).syncError('Sync failed');
        }
      }
    };
    
    // Set up notification callback for realtime notifications
    SyncManager.instance.onNewNotification = (notification) {
      if (mounted) {
        print('📬 Showing notification overlay: ${notification.title}');
        NotificationOverlay.show(context, notification);
      }
    };
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final currentIndex = ref.watch(navigationIndexProvider);
    
    return Scaffold(
      body: Stack(
        children: [
          _screens[currentIndex],
          const SyncIndicator(),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: isDarkMode ? AppColors.surfaceDark : Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(
                  icon: Icons.home_outlined,
                  activeIcon: Icons.home,
                  label: 'Home',
                  index: 0,
                ),
                _buildNavItem(
                  icon: Icons.check_circle_outline,
                  activeIcon: Icons.check_circle,
                  label: 'Tasks',
                  index: 1,
                ),
                _buildNavItem(
                  icon: Icons.description_outlined,
                  activeIcon: Icons.description,
                  label: 'Notes',
                  index: 2,
                ),
                _buildNavItem(
                  icon: Icons.notifications_outlined,
                  activeIcon: Icons.notifications,
                  label: 'Alerts',
                  index: 3,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required IconData activeIcon,
    required String label,
    required int index,
  }) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final currentIndex = ref.watch(navigationIndexProvider);
    final isActive = currentIndex == index;
    
    return GestureDetector(
      onTap: () {
        ref.read(navigationIndexProvider.notifier).state = index;
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? AppColors.primaryLight : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isActive ? activeIcon : icon,
              color: isActive 
                  ? AppColors.primary 
                  : (isDarkMode ? AppColors.textMutedDark : AppColors.textMuted),
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                color: isActive 
                    ? AppColors.primary 
                    : (isDarkMode ? AppColors.textMutedDark : AppColors.textMuted),
              ),
            ),
          ],
        ),
      ),
    );
  }
}