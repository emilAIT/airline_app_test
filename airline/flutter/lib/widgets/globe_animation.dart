import 'package:flutter/material.dart';
import 'dart:math' as math;

class GlobeAnimation extends StatefulWidget {
  final double size;
  final Widget? child;

  const GlobeAnimation({super.key, this.size = 200, this.child});

  @override
  State<GlobeAnimation> createState() => _GlobeAnimationState();
}

class _GlobeAnimationState extends State<GlobeAnimation>
    with TickerProviderStateMixin {
  late AnimationController _globeController;
  late AnimationController _planeController;
  late Animation<double> _globeRotation;

  @override
  void initState() {
    super.initState();

    // Globe rotation animation
    _globeController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();

    _globeRotation = Tween<double>(
      begin: 0,
      end: 2 * math.pi,
    ).animate(CurvedAnimation(parent: _globeController, curve: Curves.linear));

    // Airplane orbit animation
    _planeController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();
  }

  @override
  void dispose() {
    _globeController.dispose();
    _planeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Rotating Globe
          AnimatedBuilder(
            animation: _globeRotation,
            builder: (context, child) {
              return Transform.rotate(
                angle: _globeRotation.value,
                child: _buildGlobe(),
              );
            },
          ),
          // Orbiting Airplane
          AnimatedBuilder(
            animation: _planeController,
            builder: (context, child) {
              return _buildOrbitingPlane();
            },
          ),
          // Child widget overlay (optional)
          if (widget.child != null) widget.child!,
        ],
      ),
    );
  }

  Widget _buildGlobe() {
    return CustomPaint(
      size: Size(widget.size, widget.size),
      painter: GlobePainter(),
    );
  }

  Widget _buildOrbitingPlane() {
    final angle = _planeController.value * 2 * math.pi;
    final radius = widget.size * 0.6;
    final x = math.cos(angle) * radius;
    final y = math.sin(angle) * radius;

    return Transform.translate(
      offset: Offset(x, y),
      child: Transform.rotate(
        angle: angle + math.pi / 2,
        child: Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: const Color(0xFF00D4FF).withOpacity(0.8),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF00D4FF).withOpacity(0.6),
                blurRadius: 10,
                spreadRadius: 2,
              ),
            ],
          ),
          child: const Icon(Icons.flight, color: Colors.white, size: 18),
        ),
      ),
    );
  }
}

class GlobePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 10;

    // Draw globe outline
    final paint = Paint()
      ..color = const Color(0xFF00D4FF).withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    canvas.drawCircle(center, radius, paint);

    // Draw latitude lines
    for (int i = -2; i <= 2; i++) {
      if (i == 0) continue; // Skip equator
      final y = center.dy + (i * radius / 3);
      final latRadius = math.sqrt(
        radius * radius - (y - center.dy) * (y - center.dy),
      );
      if (latRadius > 0) {
        canvas.drawOval(
          Rect.fromCenter(
            center: Offset(center.dx, y),
            width: latRadius * 2,
            height: latRadius * 0.3,
          ),
          paint,
        );
      }
    }

    // Draw longitude lines
    for (int i = 0; i < 8; i++) {
      final angle = (i * math.pi / 4);
      final start = Offset(
        center.dx + math.cos(angle) * radius,
        center.dy + math.sin(angle) * radius,
      );
      final end = Offset(
        center.dx - math.cos(angle) * radius,
        center.dy - math.sin(angle) * radius,
      );
      canvas.drawLine(start, end, paint);
    }

    // Draw equator
    final equatorPaint = Paint()
      ..color = const Color(0xFF00D4FF).withOpacity(0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;
    canvas.drawOval(
      Rect.fromCenter(center: center, width: radius * 2, height: radius * 0.3),
      equatorPaint,
    );

    // Add glow effect
    final glowPaint = Paint()
      ..color = const Color(0xFF00D4FF).withOpacity(0.1)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 15);
    canvas.drawCircle(center, radius + 5, glowPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
