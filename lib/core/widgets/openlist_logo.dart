import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:openlist/core/theme/app_dimensions.dart';

class OpenListLogo extends StatelessWidget {
  final double size;
  
  const OpenListLogo({
    super.key,
    this.size = 80,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _OpenListLogoPainter(),
    );
  }
}

class _OpenListLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final double dimension = size.width;
    final center = Offset(dimension / 2, dimension / 2);
    
    // Draw background squircle with gradient
    final rect = Rect.fromLTWH(0, 0, dimension, dimension);
    final gradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: const [
        Color(0xFF6B6EF9), // Indigo
        Color(0xFF9B5CF6), // Purple
      ],
    );
    
    final paint = Paint()
      ..shader = gradient.createShader(rect)
      ..style = PaintingStyle.fill;
    
    // Draw rounded square (squircle) with radius 20 (scaled)
    final double borderRadius = dimension * 0.25; // 20/80 = 0.25 ratio
    final rrect = RRect.fromRectAndRadius(
      rect,
      Radius.circular(borderRadius),
    );
    canvas.drawRRect(rrect, paint);
    
    // Calculate stroke widths based on size
    final double circleStrokeWidth = dimension * 0.075; // ~6px at 80px
    final double lineStrokeWidth = dimension * 0.0625; // ~5px at 80px
    final double circleRadius = dimension * 0.3; // ~24px at 80px
    
    // Draw white circle ring
    final circlePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = circleStrokeWidth
      ..strokeCap = StrokeCap.round;
    
    canvas.drawCircle(center, circleRadius, circlePaint);
    
    // Draw diagonal line from top-right to bottom-left
    final linePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = lineStrokeWidth
      ..strokeCap = StrokeCap.round;
    
    // Calculate line endpoints
    // Start at top-right, just outside the circle
    // End at bottom-left, just outside the circle
    final double offset = circleRadius * 0.7; // Controls how far line extends
    
    final startPoint = Offset(
      center.dx + circleRadius - offset,
      center.dy - circleRadius + offset,
    );
    
    final endPoint = Offset(
      center.dx - circleRadius + offset,
      center.dy + circleRadius - offset,
    );
    
    canvas.drawLine(startPoint, endPoint, linePaint);
    
    // Add subtle inner glow (optional)
    final glowPaint = Paint()
      ..color = Colors.white.withOpacity(0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = circleStrokeWidth * 0.5
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
    
    canvas.drawCircle(center, circleRadius - 1, glowPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Complete brand widget with icon and text
class OpenListBrandWidget extends StatelessWidget {
  final double iconSize;
  final bool showTagline;

  const OpenListBrandWidget({
    super.key,
    this.iconSize = 80,
    this.showTagline = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        OpenListLogo(size: iconSize),
        const SizedBox(height: AppDimensions.md),
        Text(
          'OpenList',
          style: GoogleFonts.inter(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF0F172A), // Slate-900
            height: 1.2,
          ),
        ),
        if (showTagline) ...[
          const SizedBox(height: 4),
          Text(
            'Collaborate. Create. Get it Done.',
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: const Color(0xFF94A3B8), // Slate-400
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }
}