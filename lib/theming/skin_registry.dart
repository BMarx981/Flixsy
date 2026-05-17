import 'package:flutter/material.dart';

import 'remote_skin.dart';
import 'skins/classic/classic_remote_skin.dart';
import 'skins/classic/classic_theme.dart';

enum AppSkin { classic }

class SkinConfig {
  const SkinConfig({
    required this.themeData,
    required this.buildRemoteSkin,
  });

  final ThemeData themeData;
  final RemoteSkinBuilder buildRemoteSkin;
}

final Map<AppSkin, SkinConfig> skinRegistry = {
  AppSkin.classic: SkinConfig(
    themeData: ClassicTheme.themeData,
    buildRemoteSkin: ({required onKeyPressed}) =>
        ClassicRemoteSkin(onKeyPressed: onKeyPressed),
  ),
};
