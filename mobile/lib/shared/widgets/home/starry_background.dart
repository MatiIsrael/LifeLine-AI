import "dart:math";

import "package:flutter/material.dart";

import "../../../core/theme/lifeline_colors.dart";

/// Animated starfield + central gold glow behind the SOS button.
class StarryBackground extends StatefulWidget {
  final Widget child;

  const StarryBackground({super.key, required this.child});

  @override
  State<StarryBackground> createState() => _StarryBackgroundState();
}

class _StarryBackgroundState extends State<StarryBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final _random = Random(42);
  late List<_Star> _stars;

  @override
  void initState() {
    super.initState();
    _stars = List.generate(80, (_) => _Star.random(_random));
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return CustomPaint(
          painter: _StarryPainter(stars: _stars, phase: _controller.value),
          child: widget.child,
        );
      },
    );
  }
}

class _Star {
  final double x;
  final double y;
  final double size;
  final double twinkleSpeed;

  _Star({required this.x, required this.y, required this.size, required this.twinkleSpeed});

  factory _Star.random(Random r) => _Star(
        x: r.nextDouble(),
        y: r.nextDouble(),
        size: r.nextDouble() * 2 + 0.5,
        twinkleSpeed: r.nextDouble() * 2 + 0.5,
      );
}

class _StarryPainter extends CustomPainter {
  final List<_Star> stars;
  final double phase;

  _StarryPainter({required this.stars, required this.phase});

  @override
  void paint(Canvas canvas, Size size) {
    final bg = Paint()..color = LifelineColors.background;
    canvas.drawRect(Offset.zero & size, bg);

    // Central gold aura behind SOS
    final glowCenter = Offset(size.width * 0.5, size.height * 0.38);
    final glow = Paint()
      ..shader = RadialGradient(
        colors: [
          LifelineColors.gold.withOpacity(0.22),
          LifelineColors.gold.withOpacity(0.06),
          Colors.transparent,
        ],
        stops: const [0.0, 0.45, 1.0],
      ).createShader(Rect.fromCircle(center: glowCenter, radius: size.width * 0.55));
    canvas.drawCircle(glowCenter, size.width * 0.55, glow);

    final starPaint = Paint()..style = PaintingStyle.fill;
    for (final star in stars) {
      final twinkle = (sin((phase * 2 * pi * star.twinkleSpeed) + star.x * 10) + 1) / 2;
      starPaint.color = LifelineColors.goldLight.withOpacity(0.15 + twinkle * 0.5);
      canvas.drawCircle(
        Offset(star.x * size.width, star.y * size.height),
        star.size,
        starPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _StarryPainter old) => old.phase != phase;
}
