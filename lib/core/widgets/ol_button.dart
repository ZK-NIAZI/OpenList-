import 'package:flutter/material.dart';
import 'package:openlist/core/theme/theme.dart';

enum OLButtonType {
  primary,
  secondary,
  danger,
  ghost,
}

class OLButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final OLButtonType type;
  final bool isLoading;
  final IconData? prefixIcon;
  final double? width;
  final double? height;
  final bool expanded;

  const OLButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.type = OLButtonType.primary,
    this.isLoading = false,
    this.prefixIcon,
    this.width,
    this.height,
    this.expanded = true,
  });

  @override
  Widget build(BuildContext context) {
    final buttonHeight = height ?? AppDimensions.buttonLg;
    final buttonWidth = expanded ? double.infinity : width;

    return SizedBox(
      height: buttonHeight,
      width: buttonWidth,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: _getStyle(),
        child: _buildContent(),
      ),
    );
  }

  ButtonStyle _getStyle() {
    switch (type) {
      case OLButtonType.primary:
        return ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.lg,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
          ),
          textStyle: AppTypography.buttonLarge,
        );
      case OLButtonType.secondary:
        return ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: AppColors.primary,
          elevation: 0,
          side: const BorderSide(color: AppColors.primary, width: 1.5),
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.lg,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
          ),
          textStyle: AppTypography.buttonLarge,
        );
      case OLButtonType.danger:
        return ElevatedButton.styleFrom(
          backgroundColor: AppColors.danger,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.lg,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
          ),
          textStyle: AppTypography.buttonLarge,
        );
      case OLButtonType.ghost:
        return ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          foregroundColor: AppColors.primary,
          elevation: 0,
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.lg,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
          ),
          textStyle: AppTypography.buttonLarge,
        );
    }
  }

  Widget _buildContent() {
    if (isLoading) {
      return const SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
        ),
      );
    }

    if (prefixIcon != null) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            prefixIcon,
            size: AppDimensions.iconMd,
            color: _getIconColor(),
          ),
          const SizedBox(width: AppDimensions.sm),
          Text(label),
        ],
      );
    }

    return Text(label);
  }

  Color _getIconColor() {
    switch (type) {
      case OLButtonType.primary:
      case OLButtonType.danger:
        return Colors.white;
      case OLButtonType.secondary:
        return AppColors.primary;
      case OLButtonType.ghost:
        return AppColors.primary;
    }
  }
}
