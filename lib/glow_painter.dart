import 'dart:ui';
import 'package:flutter/material.dart';
import 'drawing_point.dart';

class GlowPainter extends CustomPainter {
  final List<DrawingPath?> paths;
  final Color color;
  final double strokeWidth;
  final double glowSpread;

  GlowPainter({
    required this.paths,
    required this.color,
    required this.strokeWidth,
    required this.glowSpread,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (final drawingPath in paths) {
      if (drawingPath == null || drawingPath.points.length < 2) continue;

      final path = Path();
      path.moveTo(drawingPath.points[0].dx, drawingPath.points[0].dy);
      for (int i = 1; i < drawingPath.points.length; i++) {
        path.lineTo(drawingPath.points[i].dx, drawingPath.points[i].dy);
      }

      // 1. Outer Glow (Very blurred, large spread)
      final outerGlowPaint = Paint()
        ..color = color.withAlpha(100)
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth + glowSpread * 2
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, glowSpread);
      canvas.drawPath(path, outerGlowPaint);

      // 2. Inner Glow (Medium blur, medium spread)
      final innerGlowPaint = Paint()
        ..color = color.withAlpha(180)
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth + glowSpread
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, glowSpread / 2);
      canvas.drawPath(path, innerGlowPaint);

      // 3. Bright Core (Sharp, thin)
      final corePaint = Paint()
        ..color = Colors.white.withAlpha(220)
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth / 2
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;
      
      final colorCorePaint = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;

      canvas.drawPath(path, colorCorePaint);
      canvas.drawPath(path, corePaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
