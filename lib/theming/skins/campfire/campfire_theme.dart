import 'package:flutter/material.dart';

import '../../skin_tokens.dart';

/// Palette and theme for the `Campfire` skin. A desert-night scene paints the
/// backdrop, so the chrome leans into warm dark earth tones with an ember
/// accent that reads against both the deep sky and the mesa silhouettes.
abstract final class CampfireTheme {
  static const night = Color(0xFF0B0814);
  static const dusk = Color(0xFF1F1426);
  static const mesa = Color(0xFF2A1A2A);
  static const ember = Color(0xFFFF7A2C);
  static const amber = Color(0xFFFFB060);
  static const sand = Color(0xFFE8D2B0);

  static ThemeData get themeData => ThemeData(
    colorScheme: ColorScheme.fromSeed(
      seedColor: ember,
      brightness: Brightness.dark,
    ),
    useMaterial3: true,
    scaffoldBackgroundColor: night,
    appBarTheme: const AppBarTheme(
      backgroundColor: night,
      foregroundColor: sand,
      elevation: 0,
    ),
    extensions: const [SkinTokens(buttonGap: 14, accent: ember)],
  );

  static Color alpha(Color color, double fraction) =>
      color.withAlpha((fraction.clamp(0.0, 1.0) * 255).round());
}
