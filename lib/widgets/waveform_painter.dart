import 'package:flutter/material.dart';
import '../utils/app_colors.dart';

class WaveformPainter extends CustomPainter {
  final double animationValue;

  WaveformPainter(this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.yellow.withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    for (int i = 0; i < 3; i++) {
      final progress = (animationValue + i * 0.33) % 1.0;
      canvas.drawCircle(
        center,
        radius + progress * 40,
        paint..color = AppColors.yellow.withOpacity(0.3 * (1 - progress)),
      );
    }
  }

  @override
  bool shouldRepaint(WaveformPainter oldDelegate) =>
      animationValue != oldDelegate.animationValue;
}
