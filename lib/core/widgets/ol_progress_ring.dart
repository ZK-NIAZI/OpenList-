import 'package:flutter/material.dart';
import 'package:openlist/core/theme/theme.dart';

class OLProgressRing extends StatelessWidget {
  final double percent; // 0.0 to 1.0
  final double size;
  final double strokeWidth;
  final String? centerText;

  const OLProgressRing({
    super.key,
    required this.percent,
    this.size = AppDimensions.progressRingSize,
    this.strokeWidth = AppDimensions.progressRingStroke,
    this.centerText,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _ProgressRingPainter(
          percent: percent.clamp(0.0, 1.0),
          strokeWidth: strokeWidth,
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${(percent * 100).toInt()}%',
                style: AppTypography.h1.copyWith(
                  fontSize: size * 0.2,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                centerText ?? 'DONE',
                style: AppTypography.bodySmall.copyWith(
                  fontSize: size * 0.08,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProgressRingPainter extends CustomPainter {
  final double percent;
  final double strokeWidth;

  _ProgressRingPainter({
    required this.percent,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    // Background arc
    final backgroundPaint = Paint()
      ..color = AppColors.border
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      rect,
      -90 * (3.14159 / 180),
      360 * (3.14159 / 180),
      false,
      backgroundPaint,
    );

    // Progress arc
    final progressPaint = Paint()
      ..color = AppColors.primary
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      rect,
      -90 * (3.14159 / 180),
      360 * percent * (3.14159 / 180),
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _ProgressRingPainter oldDelegate) {
    return oldDelegate.percent != percent;
  }
}
