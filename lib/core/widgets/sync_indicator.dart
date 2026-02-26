import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:openlist/core/providers/sync_provider.dart';
import 'package:openlist/core/theme/app_colors.dart';

class SyncIndicator extends ConsumerWidget {
  const SyncIndicator({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final syncStatus = ref.watch(syncStatusProvider);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    if (syncStatus.state == SyncState.idle) {
      return const SizedBox.shrink();
    }

    return Positioned(
      bottom: 80,
      right: 16,
      child: Material(
        elevation: 4,
        borderRadius: BorderRadius.circular(24),
        color: isDarkMode ? AppColors.surfaceDark : Colors.white,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isDarkMode ? AppColors.borderDark : AppColors.border,
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildIcon(syncStatus.state, isDarkMode),
              const SizedBox(width: 8),
              Text(
                syncStatus.message ?? '',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: isDarkMode ? AppColors.textPrimaryDark : AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIcon(SyncState state, bool isDarkMode) {
    switch (state) {
      case SyncState.syncing:
        return SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(
              isDarkMode ? AppColors.primary : AppColors.primary,
            ),
          ),
        );
      case SyncState.success:
        return Icon(
          Icons.check_circle,
          size: 16,
          color: AppColors.success,
        );
      case SyncState.error:
        return Icon(
          Icons.error,
          size: 16,
          color: AppColors.danger,
        );
      case SyncState.idle:
        return const SizedBox.shrink();
    }
  }
}
