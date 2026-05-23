import 'package:flutter/material.dart';

import '../../skin_tokens.dart';

/// Palette and theme for the `Cloud` skin — a bright sky with white clouds.
/// Brightness flips to [Brightness.light] so the foreground (buttons, icons,
/// app bar) reads against the pale sky background.
abstract final class CloudTheme {
  static const skyTop = Color(0xFF7EB8D9);
  static const skyBottom = Color(0xFFD8ECF6);
  static const cloud = Color(0xFFFFFFFF);
  static const cloudEdge = Color(0xFFE3EEF5);
  static const inkDeep = Color(0xFF1F3A52);
  static const inkSoft = Color(0xFF466585);

  static ThemeData get themeData => ThemeData(
    colorScheme: ColorScheme.fromSeed(
      seedColor: skyTop,
      brightness: Brightness.light,
    ),
    useMaterial3: true,
    scaffoldBackgroundColor: skyBottom,
    appBarTheme: const AppBarTheme(
      backgroundColor: skyTop,
      foregroundColor: Colors.white,
      elevation: 0,
    ),
    extensions: const [SkinTokens(buttonGap: 14, accent: skyTop)],
  );

  static Color alpha(Color color, double fraction) =>
      color.withAlpha((fraction.clamp(0.0, 1.0) * 255).round());
}
