import 'package:flutter/material.dart';

import '../../skin_tokens.dart';

abstract final class ClassicTheme {
  static ThemeData get themeData => ThemeData(
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFF1A1A2E),
      brightness: Brightness.dark,
    ),
    useMaterial3: true,
    scaffoldBackgroundColor: const Color(0xFF1A1A2E),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF16213E),
      foregroundColor: Colors.white,
      elevation: 0,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF0F3460),
        foregroundColor: Colors.white,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(8)),
        ),
      ),
    ),
    extensions: const [SkinTokens(buttonGap: 12)],
  );
}
