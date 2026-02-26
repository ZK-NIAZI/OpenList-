import 'package:flutter/material.dart';
import 'package:openlist/core/theme/theme.dart';

Future<T?> showOLottomSheet<T>({
  required BuildContext context,
  required Widget child,
  String? title,
  bool isDismissible = true,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isDismissible: isDismissible,
    enableDrag: isDismissible,
    backgroundColor: Colors.transparent,
    builder: (context) => Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppDimensions.radiusXl),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            margin: const EdgeInsets.only(top: AppDimensions.sm),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          if (title != null) ...[
            Padding(
              padding: const EdgeInsets.all(AppDimensions.lg),
              child: Text(
                title,
                style: AppTypography.h2,
              ),
            ),
          ],
          Flexible(
            child: child,
          ),
        ],
      ),
    ),
  );
}
