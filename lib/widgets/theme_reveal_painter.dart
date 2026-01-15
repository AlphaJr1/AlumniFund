import 'dart:math';
import 'package:flutter/material.dart';

/// Custom painter untuk circular reveal effect dengan INVERSE CLIPPING
/// Paints old theme color EVERYWHERE EXCEPT inside the circle
/// Circle area is transparent to reveal new theme underneath
class ThemeRevealPainter extends CustomPainter {
  final Offset center;
  final double radius;
  final Color backgroundColor;
  
  ThemeRevealPainter({
    required this.center,
    required this.radius,
    required this.backgroundColor,
  });
  
  @override
  void paint(Canvas canvas, Size size) {
    // Create full screen rect
    final screenRect = Rect.fromLTWH(0, 0, size.width, size.height);
    
    // Create circular path
    final circlePath = Path()
      ..addOval(Rect.fromCircle(center: center, radius: radius));
    
    // Create inverse path: full screen MINUS the circle
    // This reveals the new theme inside the circle
    final inversePath = Path()
      ..fillType = PathFillType.evenOdd
      ..addRect(screenRect)
      ..addPath(circlePath, Offset.zero);
    
    // Paint old theme color everywhere EXCEPT the circle
    final paint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.fill;
    
    canvas.drawPath(inversePath, paint);
  }
  
  @override
  bool shouldRepaint(ThemeRevealPainter oldDelegate) {
    return oldDelegate.radius != radius ||
           oldDelegate.center != center ||
           oldDelegate.backgroundColor != backgroundColor;
  }
}

/// Calculate maximum radius needed to cover entire screen from tap point
double calculateMaxRadius(Offset tapPosition, Size screenSize) {
  // Calculate distance to all four corners
  final corners = [
    const Offset(0, 0),                              // Top-left
    Offset(screenSize.width, 0),                     // Top-right
    Offset(0, screenSize.height),                    // Bottom-left
    Offset(screenSize.width, screenSize.height),     // Bottom-right
  ];
  
  // Find maximum distance
  double maxDistance = 0;
  for (final corner in corners) {
    final dx = tapPosition.dx - corner.dx;
    final dy = tapPosition.dy - corner.dy;
    final distance = sqrt(dx * dx + dy * dy);
    if (distance > maxDistance) {
      maxDistance = distance;
    }
  }
  
  return maxDistance;
}
