import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:openlist/core/theme/theme.dart';
import 'package:openlist/data/repositories/sharing_repository.dart';
import 'package:openlist/data/models/item_share_model.dart';
import 'package:openlist/features/auth/providers/auth_provider.dart';
import 'package:openlist/data/sync/sync_manager.dart';

class ShareDialog extends ConsumerStatefulWidget {
  final String itemId;
  final String itemTitle;

  const ShareDialog({
    super.key,
    required this.itemId,
    required this.itemTitle,
  });

  @override
  ConsumerState<ShareDialog> createState() => _ShareDialogState();
}

class _ShareDialogState extends ConsumerState<ShareDialog> {
  final _sharingRepository = SharingRepository();
  final _emailController = TextEditingController();
  bool _isLoading = false;
  SharePermission _selectedPermission = SharePermission.view;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _shareItem() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter an email address')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final currentUser = ref.read(currentUserProvider);
      final supabase = Supabase.instance.client;
      
      // Look up user UUID by email using our helper function
      final result = await supabase.rpc('get_user_id_by_email', params: {
        'email_address': email,
      });
      
      if (result == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('User with email $email not found'),
              backgroundColor: AppColors.danger,
            ),
          );
        }
        return;
      }
      
      final userId = result as String;
      
      // Create share record with proper UUID
      await _sharingRepository.shareItem(
        itemId: widget.itemId,
        userId: userId,
        permission: _selectedPermission,
        sharedBy: currentUser?.id,
        userName: email.split('@')[0],
        userEmail: email,
      );

      // Trigger sync to push the share to Supabase
      print('🔄 Triggering sync after sharing...');
      SyncManager.instance.triggerSync();

      if (mounted) {
        _emailController.clear();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Shared with $email'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error sharing: $e'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return AlertDialog(
      backgroundColor: isDarkMode ? AppColors.surfaceDark : Colors.white,
      title: Text(
        'Share "${widget.itemTitle}"',
        style: GoogleFonts.inter(
          fontWeight: FontWeight.w700,
          color: isDarkMode ? AppColors.textPrimaryDark : AppColors.textPrimary,
        ),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Enter email address',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isDarkMode ? AppColors.textSecondaryDark : AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              textDirection: TextDirection.ltr,
              style: GoogleFonts.inter(
                color: isDarkMode ? AppColors.textPrimaryDark : AppColors.textPrimary,
              ),
              decoration: InputDecoration(
                hintText: 'user@example.com',
                hintStyle: TextStyle(
                  color: isDarkMode ? AppColors.textMutedDark : AppColors.textMuted,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Permission',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isDarkMode ? AppColors.textSecondaryDark : AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                border: Border.all(
                  color: isDarkMode ? AppColors.borderDark : AppColors.border,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  _buildPermissionOption(
                    SharePermission.view,
                    'Can view',
                    'Can only view this item',
                    Icons.visibility_outlined,
                    isDarkMode,
                  ),
                  Divider(
                    height: 1,
                    color: isDarkMode ? AppColors.borderDark : AppColors.border,
                  ),
                  _buildPermissionOption(
                    SharePermission.edit,
                    'Can edit',
                    'Can view and edit this item',
                    Icons.edit_outlined,
                    isDarkMode,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            StreamBuilder<List<ItemShareModel>>(
              stream: _sharingRepository.watchItemShares(widget.itemId),
              builder: (context, snapshot) {
                final shares = snapshot.data ?? [];
                if (shares.isEmpty) return const SizedBox.shrink();

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Shared with',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isDarkMode ? AppColors.textSecondaryDark : AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...shares.map((share) => _buildSharedUserTile(share, isDarkMode)),
                  ],
                );
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(
            'Cancel',
            style: TextStyle(
              color: isDarkMode ? AppColors.textSecondaryDark : AppColors.textSecondary,
            ),
          ),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _shareItem,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
          ),
          child: _isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text('Share'),
        ),
      ],
    );
  }

  Widget _buildPermissionOption(
    SharePermission permission,
    String title,
    String subtitle,
    IconData icon,
    bool isDarkMode,
  ) {
    final isSelected = _selectedPermission == permission;

    return InkWell(
      onTap: () {
        setState(() {
          _selectedPermission = permission;
        });
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected
                  ? AppColors.primary
                  : (isDarkMode ? AppColors.textMutedDark : AppColors.textMuted),
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isSelected
                          ? AppColors.primary
                          : (isDarkMode ? AppColors.textPrimaryDark : AppColors.textPrimary),
                    ),
                  ),
                  Text(
                    subtitle,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: isDarkMode ? AppColors.textMutedDark : AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(
                Icons.check_circle,
                color: AppColors.primary,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSharedUserTile(ItemShareModel share, bool isDarkMode) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDarkMode ? AppColors.bgScaffoldDark : AppColors.borderLight,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: AppColors.primaryLight,
            child: Text(
              (share.userName ?? share.userEmail ?? 'U')[0].toUpperCase(),
              style: GoogleFonts.inter(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  share.userName ?? share.userEmail ?? 'Unknown',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isDarkMode ? AppColors.textPrimaryDark : AppColors.textPrimary,
                  ),
                ),
                if (share.userEmail != null)
                  Text(
                    share.userEmail!,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: isDarkMode ? AppColors.textMutedDark : AppColors.textMuted,
                    ),
                  ),
              ],
            ),
          ),
          Text(
            share.permission == SharePermission.edit ? 'Can edit' : 'Can view',
            style: GoogleFonts.inter(
              fontSize: 12,
              color: isDarkMode ? AppColors.textSecondaryDark : AppColors.textSecondary,
            ),
          ),
          IconButton(
            icon: Icon(
              Icons.close,
              size: 18,
              color: isDarkMode ? AppColors.textMutedDark : AppColors.textMuted,
            ),
            onPressed: () async {
              await _sharingRepository.removeItemShare(share.id);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Share removed')),
                );
              }
            },
          ),
        ],
      ),
    );
  }
}
