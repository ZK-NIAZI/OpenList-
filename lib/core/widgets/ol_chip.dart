import 'package:flutter/material.dart';
import 'package:openlist/core/theme/theme.dart';

class OLChip extends StatelessWidget {
  final String label;
  final IconData? icon;
  final bool isSelected;
  final VoidCallback? onTap;
  final Color? color;
  final bool showBorder;
  final double height;

  const OLChip({
    super.key,
    required this.label,
    this.icon,
    this.isSelected = false,
    this.onTap,
    this.color,
    this.showBorder = true,
    this.height = 36,
  });

  @override
  Widget build(BuildContext context) {
    final chipColor = color ?? AppColors.primary;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: height,
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.md,
        ),
        decoration: BoxDecoration(
          color: isSelected ? chipColor : Colors.white,
          borderRadius: BorderRadius.circular(AppDimensions.radiusPill),
          border: showBorder
              ? Border.all(
                  color: isSelected ? Colors.transparent : AppColors.border,
                  width: 1,
                )
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: AppDimensions.iconSm,
                color: isSelected ? Colors.white : chipColor,
              ),
              const SizedBox(width: AppDimensions.xs),
            ],
            Text(
              label,
              style: AppTypography.buttonSmall.copyWith(
                color: isSelected ? Colors.white : AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
