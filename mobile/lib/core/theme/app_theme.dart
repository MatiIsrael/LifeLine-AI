import "package:flutter/material.dart";
import "package:flutter/services.dart";

import "lifeline_colors.dart";

class AppTheme {
  static ThemeData get lightTheme => darkTheme;

  static ThemeData get darkTheme {
    const scheme = ColorScheme.dark(
      primary: LifelineColors.gold,
      secondary: LifelineColors.goldDark,
      surface: LifelineColors.card,
      error: LifelineColors.emergency,
      onPrimary: Color(0xFF1A1408),
      onSurface: LifelineColors.textPrimary,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: LifelineColors.background,
      colorScheme: scheme,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: LifelineColors.gold,
        systemOverlayStyle: SystemUiOverlayStyle.light,
      ),
      cardTheme: CardTheme(
        color: LifelineColors.card,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: LifelineColors.cardBorder),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: LifelineColors.card,
        contentTextStyle: const TextStyle(color: LifelineColors.textPrimary),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        behavior: SnackBarBehavior.floating,
      ),
      iconTheme: const IconThemeData(color: LifelineColors.gold),
      textTheme: const TextTheme(
        bodyLarge: TextStyle(color: LifelineColors.textPrimary),
        bodyMedium: TextStyle(color: LifelineColors.textMuted),
      ),
    );
  }
}
