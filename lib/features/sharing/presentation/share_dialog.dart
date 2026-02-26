import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:openlist/core/theme/theme.dart';
import 'package:openlist/data/repositories/sharing_repository.dart';
import 'package:openlist/data/repositories/item_repository.dart';
import 'package:openlist/data/models/item_share_model.dart';
import 'package:openlist/data/models/block_model.dart';
import 'package:openlist/features/auth/providers/auth_provider.dart';
import 'package:openlist/data/sync/sync_manager.dart';
import 'package:openlist/data/local/isar_service.dart';
import 'package:openlist/data/repositories/friendship_repository.dart';
import 'package:openlist/services/friendship_service.dart';
import 'package:openlist/data/models/friendship_model.dart';

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
  late final FriendshipService _friendshipService;
  bool _isLoading = false;
  bool _isLoadingFriends = true;
  SharePermission _selectedPermission = SharePermission.view;
  List<FriendshipModel> _friends = [];
  String? _selectedFriendId;

  @override
  void initState() {
    super.initState();
    // Initialize friendship service
    final isarService = IsarService.instance;
    final supabase = Supabase.instance.client;
    final repository = FriendshipRepository(
      isarService: isarService,
      supabase: supabase,
    );
    _friendshipService = FriendshipService(repository: repository);
    _loadFriends();
  }

  Future<void> _loadFriends() async {
    try {
      final friends = await _friendshipService.getFriendsWithDetails();
      if (mounted) {
        setState(() {
          _friends = friends;
          _isLoadingFriends = false;
        });
      }
    } catch (e) {
      print('Error loading friends: $e');
      if (mounted) {
        setState(() {
          _isLoadingFriends = false;
        });
      }
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _shareItem() async {
    if (_selectedFriendId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a friend')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final currentUser = ref.read(currentUserProvider);
      final selectedFriend = _friends.firstWhere((f) => f.friendId == _selectedFriendId);
      final friendEmail = selectedFriend.friend?.email ?? '';
      final friendName = selectedFriend.friend?.displayName ?? friendEmail.split('@')[0];
      
      // Create share record for the main item
      await _sharingRepository.shareItem(
        itemId: widget.itemId,
        userId: _selectedFriendId!,
        permission: _selectedPermission,
        sharedBy: currentUser?.id,
        userName: friendName,
        userEmail: friendEmail,
      );

      // Also share task references in note blocks (for notes with embedded tasks)
      final itemRepo = ItemRepository();
      
      // Get all blocks for this item
      final blocks = await itemRepo.getBlocks(widget.itemId);
      
      print('📤 Found ${blocks.length} blocks in this item');
      
      // Find task references (blocks of type subTask contain task itemIds in content)
      final taskIds = <String>[];
      for (final block in blocks) {
        if (block.type == BlockType.subTask) {
          taskIds.add(block.content); // content contains the task itemId
          print('   📋 Found task reference: ${block.content}');
        }
      }
      
      print('📤 Sharing ${taskIds.length} referenced tasks...');
      for (final taskId in taskIds) {
        try {
          // Get the task item
          final taskItem = await itemRepo.getItemByItemId(taskId);
          if (taskItem != null) {
            print('   📤 Sharing task: ${taskItem.title} (${taskItem.itemId})');
            await _sharingRepository.shareItem(
              itemId: taskItem.itemId,
              userId: _selectedFriendId!,
              permission: _selectedPermission,
              sharedBy: currentUser?.id,
              userName: friendName,
              userEmail: friendEmail,
            );
          } else {
            print('   ⚠️  Task not found: $taskId');
          }
        } catch (e) {
          print('   ❌ Failed to share task $taskId: $e');
        }
      }
      print('✅ Shared ${taskIds.length} referenced tasks');

      // Trigger sync to push the shares to Supabase
      print('🔄 Triggering sync after sharing...');
      SyncManager.instance.triggerSync();

      if (mounted) {
        setState(() {
          _selectedFriendId = null;
        });
        
        final taskCount = taskIds.isEmpty ? '' : ' and ${taskIds.length} referenced tasks';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Shared with $friendName$taskCount'),
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
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Select a friend',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isDarkMode ? AppColors.textSecondaryDark : AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 12),
            _isLoadingFriends
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(20),
                      child: CircularProgressIndicator(),
                    ),
                  )
                : _friends.isEmpty
                    ? Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: isDarkMode ? AppColors.surfaceDark : AppColors.borderLight,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          children: [
                            Icon(
                              Icons.people_outline,
                              size: 48,
                              color: isDarkMode ? AppColors.textMutedDark : AppColors.textMuted,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'No friends yet',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: isDarkMode ? AppColors.textSecondaryDark : AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Add friends to share items with them',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: isDarkMode ? AppColors.textMutedDark : AppColors.textMuted,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      )
                    : SizedBox(
                        height: 100,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: _friends.length,
                          itemBuilder: (context, index) {
                            final friend = _friends[index];
                            final isSelected = _selectedFriendId == friend.friendId;
                            final friendName = friend.friend?.displayName ?? 
                                               friend.friend?.email?.split('@')[0] ?? 
                                               'Unknown';
                            final initials = friend.friend?.initials ?? '?';

                            return GestureDetector(
                              onTap: () {
                                setState(() {
                                  _selectedFriendId = isSelected ? null : friend.friendId;
                                });
                              },
                              child: Container(
                                width: 80,
                                margin: const EdgeInsets.only(right: 12),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Stack(
                                      children: [
                                        CircleAvatar(
                                          radius: 30,
                                          backgroundColor: isSelected
                                              ? AppColors.primary
                                              : AppColors.primaryLight,
                                          child: Text(
                                            initials,
                                            style: GoogleFonts.inter(
                                              color: isSelected
                                                  ? Colors.white
                                                  : AppColors.primary,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 18,
                                            ),
                                          ),
                                        ),
                                        if (isSelected)
                                          Positioned(
                                            right: 0,
                                            bottom: 0,
                                            child: Container(
                                              padding: const EdgeInsets.all(4),
                                              decoration: const BoxDecoration(
                                                color: AppColors.success,
                                                shape: BoxShape.circle,
                                              ),
                                              child: const Icon(
                                                Icons.check,
                                                size: 12,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      friendName,
                                      style: GoogleFonts.inter(
                                        fontSize: 12,
                                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                                        color: isSelected
                                            ? AppColors.primary
                                            : (isDarkMode ? AppColors.textPrimaryDark : AppColors.textPrimary),
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
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
                  mainAxisSize: MainAxisSize.min,
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
