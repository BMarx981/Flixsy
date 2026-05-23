import 'package:flutter/material.dart';

import '../../skin_tokens.dart';

/// Palette and theme for the `Punk` skin. The backdrop is a graffitied brick
/// alley — dark brick, torn posters, spray-paint tags and a glitching neon
/// anarchy "A" — so the chrome leans into bottle-black with a hot-magenta
/// accent and an acid-yellow secondary that reads against both the brick and
/// the spray-paint.
abstract final class PunkTheme {
  static const dark = Color(0xFF08060A);
  static const ink = Color(0xFF120E14);
  static const brick = Color(0xFF5A1A1C);
  static const concrete = Color(0xFF26242A);
  static const magenta = Color(0xFFFF1F8C);
  static const acid = Color(0xFFD6F33A);
  static const bone = Color(0xFFEAE2D6);

  static ThemeData get themeData => ThemeData(
    colorScheme: ColorScheme.fromSeed(
      seedColor: magenta,
      brightness: Brightness.dark,
    ),
    useMaterial3: true,
    scaffoldBackgroundColor: dark,
    appBarTheme: const AppBarTheme(
      backgroundColor: dark,
      foregroundColor: bone,
      elevation: 0,
    ),
    extensions: const [SkinTokens(buttonGap: 14, accent: magenta)],
  );

  static Color alpha(Color color, double fraction) =>
      color.withAlpha((fraction.clamp(0.0, 1.0) * 255).round());
}
