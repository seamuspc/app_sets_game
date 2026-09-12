import 'package:flutter/material.dart';

import '../../domain/set_card.dart';

/// Draws ONE symbol (a diamond, squiggle, or oval) with the given color
/// and shading, inside whatever box it's given. SetCardWidget stacks
/// 1–3 of these vertically to represent a card's count.
class SetSymbolPainter extends CustomPainter {
  SetSymbolPainter({
    required this.shape,
    required this.color,
    required this.shading,
  });

  final CardShape shape;
  final Color color;
  final CardShading shading;

  @override
  void paint(Canvas canvas, Size size) {
    final path = _pathFor(shape, size);

    final strokePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;

    switch (shading) {
      case CardShading.solid:
        canvas.drawPath(
          path,
          Paint()
            ..color = color
            ..style = PaintingStyle.fill,
        );
      case CardShading.empty:
        // Just the outline — no fill.
        break;
      case CardShading.striped:
        canvas.save();
        canvas.clipPath(path);
        const stripeGap = 5.0;
        for (double x = 0; x < size.width; x += stripeGap) {
          canvas.drawLine(
            Offset(x, 0),
            Offset(x, size.height),
            Paint()
              ..color = color
              ..strokeWidth = 1.5,
          );
        }
        canvas.restore();
    }

    canvas.drawPath(path, strokePaint);
  }

  Path _pathFor(CardShape shape, Size size) {
    switch (shape) {
      case CardShape.diamond:
        return Path()
          ..moveTo(size.width / 2, 0)
          ..lineTo(size.width, size.height / 2)
          ..lineTo(size.width / 2, size.height)
          ..lineTo(0, size.height / 2)
          ..close();

      case CardShape.oval:
        return Path()
          ..addRRect(
            RRect.fromRectAndRadius(
              Rect.fromLTWH(0, 0, size.width, size.height),
              Radius.circular(size.height / 2),
            ),
          );

      case CardShape.squiggle:
        // A wavy blob — not geometrically "correct" SET squiggle, but a
        // recognizable, readably distinct third shape from diamond/oval.
        final w = size.width;
        final h = size.height;
        return Path()
          ..moveTo(0, h * 0.3)
          ..cubicTo(w * 0.1, 0, w * 0.4, 0, w * 0.5, h * 0.2)
          ..cubicTo(w * 0.65, h * 0.45, w * 0.85, h * 0.1, w, h * 0.25)
          ..cubicTo(w * 0.95, h * 0.55, w * 0.9, h, w * 0.7, h)
          ..cubicTo(w * 0.5, h, w * 0.4, h * 0.75, w * 0.25, h * 0.7)
          ..cubicTo(w * 0.1, h * 0.65, w * 0.05, h * 0.5, 0, h * 0.3)
          ..close();
    }
  }

  @override
  bool shouldRepaint(covariant SetSymbolPainter oldDelegate) {
    return shape != oldDelegate.shape ||
        color != oldDelegate.color ||
        shading != oldDelegate.shading;
  }
}
