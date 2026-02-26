import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:openlist/core/theme/theme.dart';

class OLAvatar extends StatelessWidget {
  final String? imageUrl;
  final String? initials;
  final double size;
  final bool showOnlineDot;
  final VoidCallback? onTap;

  const OLAvatar({
    super.key,
    this.imageUrl,
    this.initials,
    this.size = AppDimensions.avatarMd,
    this.showOnlineDot = false,
    this.onTap,
  }) : assert(imageUrl != null || initials != null, 'Either imageUrl or initials must be provided');

  @override
  Widget build(BuildContext context) {
    final avatar = Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.white,
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: _buildAvatarContent(),
        ),
        if (showOnlineDot)
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              width: size * 0.25,
              height: size * 0.25,
              decoration: BoxDecoration(
                color: AppColors.success,
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white,
                  width: 2,
                ),
              ),
            ),
          ),
      ],
    );

    if (onTap != null) {
      return GestureDetector(
        onTap: onTap,
        child: avatar,
      );
    }

    return avatar;
  }

  Widget _buildAvatarContent() {
    if (imageUrl != null) {
      return ClipOval(
        child: CachedNetworkImage(
          imageUrl: imageUrl!,
          fit: BoxFit.cover,
          placeholder: (context, url) => Container(
            color: AppColors.primaryLight,
            child: Center(
              child: Text(
                _getInitials(),
                style: TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                  fontSize: size * 0.4,
                ),
              ),
            ),
          ),
          errorWidget: (context, url, error) => Container(
            color: AppColors.primaryLight,
            child: Center(
              child: Text(
                _getInitials(),
                style: TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                  fontSize: size * 0.4,
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.primaryLight,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          _getInitials(),
          style: TextStyle(
            color: AppColors.primary,
            fontWeight: FontWeight.w600,
            fontSize: size * 0.4,
          ),
        ),
      ),
    );
  }

  String _getInitials() {
    if (initials != null && initials!.isNotEmpty) {
      return initials!.length > 2
          ? initials!.substring(0, 2).toUpperCase()
          : initials!.toUpperCase();
    }
    return '?';
  }
}
