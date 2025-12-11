import 'package:flutter/material.dart';
import '../utils/app_colors.dart';

class RadioWavePainter extends CustomPainter {
  final double animationValue;

  RadioWavePainter(this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final center = Offset(size.width / 2, size.height / 2);

    for (int i = 0; i < 3; i++) {
      final progress = (animationValue + i * 0.33) % 1.0;
      paint.color = AppColors.yellow.withOpacity(1 - progress);
      canvas.drawCircle(center, 50 + progress * 50, paint);
    }
  }

  @override
  bool shouldRepaint(RadioWavePainter oldDelegate) =>
      animationValue != oldDelegate.animationValue;
}
