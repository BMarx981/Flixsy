import 'package:flutter/material.dart';

import '../../skin_tokens.dart';

/// Palette and theme for the `Honkytonk` skin. The backdrop is a dim country
/// bar interior — warm wood, hanging bulbs, and a neon stage sign — so the
/// chrome leans into mahogany dark tones with a hot-pink neon accent that
/// reads against both the wood and the warm bulb glow.
abstract final class HonkytonkTheme {
  static const dark = Color(0xFF120A06);
  static const mahogany = Color(0xFF2A1410);
  static const wood = Color(0xFF4A2A18);
  static const bourbon = Color(0xFFC97A2C);
  static const bulb = Color(0xFFFFD37A);
  static const neon = Color(0xFFFF3A78);
  static const cream = Color(0xFFF4E2C4);

  static ThemeData get themeData => ThemeData(
    colorScheme: ColorScheme.fromSeed(
      seedColor: neon,
      brightness: Brightness.dark,
    ),
    useMaterial3: true,
    scaffoldBackgroundColor: dark,
    appBarTheme: const AppBarTheme(
      backgroundColor: dark,
      foregroundColor: cream,
      elevation: 0,
    ),
    extensions: const [SkinTokens(buttonGap: 10)],
  );

  static Color alpha(Color color, double fraction) =>
      color.withAlpha((fraction.clamp(0.0, 1.0) * 255).round());
}
