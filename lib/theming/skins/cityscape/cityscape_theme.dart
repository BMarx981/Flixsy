import 'package:flutter/material.dart';

import '../../skin_tokens.dart';

/// Palette and theme for the `Cityscape` skin. The backdrop is a night skyline
/// — deep indigo sky over layered building silhouettes glittering with lit
/// windows — so the chrome leans into midnight blue with a cyan window-glow
/// accent that reads against both the sky and the warmer amber windows.
abstract final class CityscapeTheme {
  static const dark = Color(0xFF050812);
  static const midnight = Color(0xFF0E1424);
  static const slate = Color(0xFF1E2A44);
  static const window = Color(0xFFFFC062);
  static const neon = Color(0xFF4ED1FF);
  static const moon = Color(0xFFEFEAD8);
  static const ice = Color(0xFFDCE8F4);

  static ThemeData get themeData => ThemeData(
    colorScheme: ColorScheme.fromSeed(
      seedColor: neon,
      brightness: Brightness.dark,
    ),
    useMaterial3: true,
    scaffoldBackgroundColor: dark,
    appBarTheme: const AppBarTheme(
      backgroundColor: dark,
      foregroundColor: ice,
      elevation: 0,
    ),
    extensions: const [SkinTokens(buttonGap: 10)],
  );

  static Color alpha(Color color, double fraction) =>
      color.withAlpha((fraction.clamp(0.0, 1.0) * 255).round());
}
