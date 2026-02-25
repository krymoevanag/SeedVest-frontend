import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/colors.dart';

class SeedVestLogo extends StatelessWidget {
  const SeedVestLogo({
    super.key,
    this.size = 140,
    this.showWordmark = true,
    this.wordmarkColor,
  });

  final double size;
  final bool showWordmark;
  final Color? wordmarkColor;

  @override
  Widget build(BuildContext context) {
    final markHeight = size * 0.72;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: size,
          height: markHeight,
          child: CustomPaint(
            painter: _SeedVestMarkPainter(),
          ),
        ),
        if (showWordmark) ...[
          SizedBox(height: size * 0.06),
          Text(
            'SeedVest',
            style: GoogleFonts.sora(
              color: wordmarkColor ?? AppColors.secondary,
              fontSize: size * 0.22,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ],
    );
  }
}

class _SeedVestMarkPainter extends CustomPainter {
  static const Color _deepBlue = Color(0xFF0C2B45);
  static const Color _brandGreen = Color(0xFF1D8C57);
  static const Color _leafGreen = Color(0xFF0F6E45);
  static const Color _gold = Color(0xFFE0D46A);

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final baseline = h * 0.88;

    final barWidth = w * 0.14;
    final gap = w * 0.02;
    final startX = w * 0.10;

    final bars = [
      _bar(startX, baseline, barWidth * 0.78, h * 0.07, _brandGreen),
      _bar(startX + barWidth + gap, baseline, barWidth, h * 0.20, _deepBlue),
      _bar(startX + (barWidth + gap) * 2, baseline, barWidth, h * 0.38, _gold),
      _bar(startX + (barWidth + gap) * 3, baseline, barWidth, h * 0.55, _brandGreen),
      _bar(startX + (barWidth + gap) * 4, baseline, barWidth, h * 0.74, _deepBlue),
    ];

    for (final bar in bars) {
      final paint = Paint()..color = bar.color;
      canvas.drawRRect(
        RRect.fromRectAndRadius(bar.rect, Radius.circular(w * 0.007)),
        paint,
      );
    }

    final slashPaint = Paint()
      ..color = _gold
      ..strokeWidth = w * 0.06
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    canvas.drawLine(
      Offset(startX + w * 0.06, baseline - h * 0.29),
      Offset(startX + w * 0.30, baseline - h * 0.56),
      slashPaint,
    );

    final stemPaint = Paint()
      ..color = _leafGreen
      ..strokeWidth = w * 0.05
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    canvas.drawLine(
      Offset(w * 0.53, baseline - h * 0.22),
      Offset(w * 0.53, baseline - h * 0.73),
      stemPaint,
    );

    final leafRect = Rect.fromCenter(
      center: Offset(w * 0.40, baseline - h * 0.73),
      width: w * 0.28,
      height: h * 0.24,
    );
    canvas.save();
    canvas.translate(leafRect.center.dx, leafRect.center.dy);
    canvas.rotate(-math.pi / 9);
    canvas.translate(-leafRect.center.dx, -leafRect.center.dy);
    canvas.drawOval(
      leafRect,
      Paint()..color = _leafGreen,
    );
    canvas.restore();

    final rightArcPath = Path();
    rightArcPath.moveTo(w * 0.53, baseline - h * 0.64);
    rightArcPath.quadraticBezierTo(
      w * 0.64,
      baseline - h * 0.95,
      w * 0.76,
      baseline - h * 0.76,
    );
    canvas.drawPath(rightArcPath, stemPaint);

    final arrowPaint = Paint()
      ..color = _deepBlue
      ..strokeWidth = w * 0.055
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    final arrowStart = Offset(w * 0.64, baseline - h * 0.48);
    final arrowEnd = Offset(w * 0.94, baseline - h * 0.84);
    canvas.drawLine(arrowStart, arrowEnd, arrowPaint);

    final arrowHead = Path()
      ..moveTo(arrowEnd.dx, arrowEnd.dy)
      ..lineTo(arrowEnd.dx - w * 0.10, arrowEnd.dy - h * 0.02)
      ..lineTo(arrowEnd.dx - w * 0.02, arrowEnd.dy + h * 0.11)
      ..close();
    canvas.drawPath(arrowHead, Paint()..color = _deepBlue);
  }

  _Bar _bar(
    double x,
    double baseline,
    double width,
    double height,
    Color color,
  ) {
    return _Bar(
      rect: Rect.fromLTWH(x, baseline - height, width, height),
      color: color,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _Bar {
  const _Bar({required this.rect, required this.color});
  final Rect rect;
  final Color color;
}
