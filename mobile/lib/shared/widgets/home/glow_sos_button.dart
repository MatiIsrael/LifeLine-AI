import "package:flutter/material.dart";

import "../../../core/theme/lifeline_colors.dart";

/// Large 3D-style glowing gold SOS trigger button.
class GlowSosButton extends StatefulWidget {
  final VoidCallback? onPressed;
  final bool isBusy;
  final bool isActive;

  const GlowSosButton({
    super.key,
    required this.onPressed,
    this.isBusy = false,
    this.isActive = false,
  });

  @override
  State<GlowSosButton> createState() => _GlowSosButtonState();
}

class _GlowSosButtonState extends State<GlowSosButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulse,
      builder: (context, _) {
        final scale = 1.0 + _pulse.value * 0.04;
        final glowSpread = 8.0 + _pulse.value * 14;
        final color = widget.isActive ? LifelineColors.emergency : LifelineColors.gold;
        final glowColor = widget.isActive ? LifelineColors.emergencyGlow : LifelineColors.goldLight;

        return Transform(
          transform: Matrix4.identity()
            ..setEntry(3, 2, 0.001)
            ..rotateX(0.08),
          alignment: Alignment.center,
          child: Transform.scale(
            scale: scale,
            child: GestureDetector(
              onTap: widget.isBusy ? null : widget.onPressed,
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: widget.isActive
                        ? [const Color(0xFFFF6B6B), LifelineColors.emergency]
                        : [LifelineColors.goldLight, LifelineColors.gold, LifelineColors.goldDark],
                    stops: const [0.0, 0.55, 1.0],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: glowColor.withOpacity(0.55),
                      blurRadius: 40,
                      spreadRadius: glowSpread,
                    ),
                    BoxShadow(
                      color: color.withOpacity(0.35),
                      blurRadius: 80,
                      spreadRadius: 4,
                    ),
                    const BoxShadow(
                      color: Color(0x40000000),
                      blurRadius: 24,
                      offset: Offset(0, 14),
                    ),
                  ],
                ),
                child: Center(
                  child: widget.isBusy
                      ? const SizedBox(
                          width: 36,
                          height: 36,
                          child: CircularProgressIndicator(
                            color: Colors.black87,
                            strokeWidth: 3,
                          ),
                        )
                      : const Text(
                          "SOS",
                          style: TextStyle(
                            fontSize: 52,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF1A1408),
                            letterSpacing: 2,
                            height: 1,
                          ),
                        ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
