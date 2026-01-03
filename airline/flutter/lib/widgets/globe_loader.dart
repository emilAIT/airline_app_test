import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class GlobeLoader extends StatefulWidget {
  final double size;
  final Color? color;

  const GlobeLoader({
    super.key,
    this.size = 100.0,
    this.color,
  });

  @override
  State<GlobeLoader> createState() => _GlobeLoaderState();
}

class _GlobeLoaderState extends State<GlobeLoader> with TickerProviderStateMixin {
  late AnimationController _rotationController;
  late AnimationController _orbitController;

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();

    _orbitController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
  }

  @override
  void dispose() {
    _rotationController.dispose();
    _orbitController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = widget.color ?? EldiyarTheme.primaryBlue;
    
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Rotating Globe (Wireframe)
          AnimatedBuilder(
            animation: _rotationController,
            builder: (context, child) {
              return Transform.rotate(
                angle: _rotationController.value * 2 * math.pi,
                child: CustomPaint(
                  size: Size(widget.size * 0.6, widget.size * 0.6),
                  painter: GlobePainter(color: primaryColor.withOpacity(0.3)),
                ),
              );
            },
          ),
          
          // Static Core
          Container(
            width: widget.size * 0.5,
            height: widget.size * 0.5,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  primaryColor.withOpacity(0.2),
                  primaryColor.withOpacity(0.05),
                ],
              ),
            ),
          ),

          // Orbiting Plane
          AnimatedBuilder(
            animation: _orbitController,
            builder: (context, child) {
              final angle = _orbitController.value * 2 * math.pi;
              final radius = widget.size * 0.4;
              final x = math.cos(angle) * radius;
              final y = math.sin(angle) * radius * 0.3; // Elliptical orbit

              return Transform.translate(
                offset: Offset(x, y),
                child: Transform.rotate(
                  angle: angle + math.pi / 2, // Rotate plane to face direction
                  child: Icon(
                    Icons.airplanemode_active,
                    color: EldiyarTheme.accentAmber,
                    size: widget.size * 0.2,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class GlobePainter extends CustomPainter {
  final Color color;

  GlobePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Draw Longitudes
    for (int i = 0; i < 4; i++) {
        final angle = (i * math.pi / 4);
        canvas.drawOval(
          Rect.fromCenter(center: center, width: radius * 2 * math.cos(angle), height: radius * 2),
          paint,
        );
    }
    
    // Draw Equator
    canvas.drawCircle(center, radius, paint);
    
    // Draw Latitudes
    canvas.drawOval(
      Rect.fromCenter(center: center, width: radius * 2, height: radius),
      paint,
    );
     canvas.drawOval(
      Rect.fromCenter(center: center, width: radius * 2, height: radius * 0.5),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
