import 'package:flutter/material.dart';

import '../../skin_tokens.dart';

/// Theme for the "Main" skin — colours sampled from the Flixsy logo mark.
abstract final class MainTheme {
  static const _pink = Color(0xFFFF3D8A); // logo disc
  static const _plum = Color(0xFF511838); // logo ring
  static const _ink = Color(0xFF0E0A18); // logo star

  static ThemeData get themeData => ThemeData(
    colorScheme: ColorScheme.fromSeed(
      seedColor: _pink,
      brightness: Brightness.dark,
    ),
    useMaterial3: true,
    scaffoldBackgroundColor: _ink,
    appBarTheme: const AppBarTheme(
      backgroundColor: _plum,
      foregroundColor: Colors.white,
      elevation: 0,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: _pink,
        foregroundColor: _ink,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(8)),
        ),
      ),
    ),
    extensions: const [SkinTokens(buttonGap: 12, accent: _pink)],
  );
}
