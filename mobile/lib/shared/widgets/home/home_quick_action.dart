import "package:flutter/material.dart";

import "../../../core/theme/lifeline_colors.dart";

class HomeQuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool highlight;

  const HomeQuickAction({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: highlight
                  ? const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFFFF6B6B), LifelineColors.emergency],
                    )
                  : LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        LifelineColors.card,
                        LifelineColors.card.withOpacity(0.8),
                      ],
                    ),
              border: Border.all(
                color: highlight
                    ? LifelineColors.emergency.withOpacity(0.6)
                    : LifelineColors.cardBorder,
                width: 1.2,
              ),
              boxShadow: [
                if (highlight)
                  BoxShadow(
                    color: LifelineColors.emergency.withOpacity(0.4),
                    blurRadius: 16,
                    spreadRadius: 2,
                  ),
                const BoxShadow(
                  color: Color(0x33000000),
                  blurRadius: 12,
                  offset: Offset(0, 6),
                ),
              ],
            ),
            child: Icon(
              icon,
              color: highlight ? Colors.white : LifelineColors.gold,
              size: 28,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              color: highlight ? LifelineColors.emergency : LifelineColors.textMuted,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
