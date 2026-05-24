import 'package:flutter/material.dart';

import 'package:flixsy/theming/skin_tokens.dart';

/// Palette and theme for the `Waterfall` skin — deep ocean blues with a
/// foam-pale foreground. The background is painted by [WaterfallBackground],
/// so the [scaffoldBackgroundColor] only matters for the area outside the
/// skin's own canvas.
abstract final class WaterfallTheme {
  static const abyss = Color(0xFF02223A);
  static const deep = Color(0xFF0A4F7C);
  static const seed = Color(0xFF2C7FB8);
  static const foam = Color(0xFFB8E0F0);

  static ThemeData get themeData => ThemeData(
    colorScheme: ColorScheme.fromSeed(
      seedColor: seed,
      brightness: Brightness.dark,
    ),
    useMaterial3: true,
    scaffoldBackgroundColor: abyss,
    appBarTheme: const AppBarTheme(
      backgroundColor: abyss,
      foregroundColor: foam,
      elevation: 0,
    ),
    extensions: const [SkinTokens(buttonGap: 14, accent: foam)],
  );

  static Color alpha(Color color, double fraction) =>
      color.withAlpha((fraction.clamp(0.0, 1.0) * 255).round());
}
