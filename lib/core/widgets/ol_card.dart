import 'package:flutter/material.dart';
import 'package:openlist/core/theme/theme.dart';

class OLCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double? radius;
  final Color? color;
  final VoidCallback? onTap;
  final bool hasShadow;

  const OLCard({
    super.key,
    required this.child,
    this.padding,
    this.radius,
    this.color,
    this.onTap,
    this.hasShadow = true,
  });

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final defaultColor = isDarkMode ? AppColors.surfaceDark : AppColors.surface;
    
    final card = Material(
      color: color ?? defaultColor,
      borderRadius: BorderRadius.circular(radius ?? AppDimensions.radiusLg),
      elevation: hasShadow ? 0 : 0,
      shadowColor: hasShadow 
          ? (isDarkMode 
              ? Colors.black.withOpacity(0.2) 
              : AppColors.textPrimary.withOpacity(0.05)) 
          : null,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(radius ?? AppDimensions.radiusLg),
        child: Container(
          padding: padding ?? const EdgeInsets.all(AppDimensions.lg),
          child: child,
        ),
      ),
    );

    if (hasShadow) {
      return Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(radius ?? AppDimensions.radiusLg),
          boxShadow: [
            BoxShadow(
              color: isDarkMode 
                  ? Colors.black.withOpacity(0.2)
                  : AppColors.textPrimary.withOpacity(0.05),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: card,
      );
    }

    return card;
  }
}
