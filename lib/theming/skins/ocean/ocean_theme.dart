import 'package:flutter/material.dart';

import '../../skin_tokens.dart';

/// Palette and theme for the `Ocean` skin. The sky cycles through times of
/// day at runtime, so this theme picks a neutral dark navy chrome that holds
/// up at every phase. Button colours are kept constant in the section
/// renderer for the same reason.
abstract final class OceanTheme {
  static const deep = Color(0xFF050B22);
  static const navy = Color(0xFF0E1A3F);
  static const surface = Color(0xFF1B2A4E);
  static const foam = Color(0xFFE8F1F8);
  static const goldGlow = Color(0xFFFFC68A);

  static ThemeData get themeData => ThemeData(
    colorScheme: ColorScheme.fromSeed(
      seedColor: surface,
      brightness: Brightness.dark,
    ),
    useMaterial3: true,
    scaffoldBackgroundColor: deep,
    appBarTheme: const AppBarTheme(
      backgroundColor: deep,
      foregroundColor: foam,
      elevation: 0,
    ),
    extensions: const [SkinTokens(buttonGap: 14)],
  );

  static Color alpha(Color color, double fraction) =>
      color.withAlpha((fraction.clamp(0.0, 1.0) * 255).round());
}
