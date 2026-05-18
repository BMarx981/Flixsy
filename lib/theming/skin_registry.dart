import 'package:flutter/material.dart';

import 'remote_skin.dart';
import 'skins/classic/classic_remote_skin.dart';
import 'skins/classic/classic_theme.dart';
import 'skins/main/main_remote_skin.dart';
import 'skins/main/main_theme.dart';

enum AppSkin { classic, main }

class SkinConfig {
  const SkinConfig({required this.themeData, required this.buildRemoteSkin});

  final ThemeData themeData;
  final RemoteSkinBuilder buildRemoteSkin;
}

final Map<AppSkin, SkinConfig> skinRegistry = {
  AppSkin.classic: SkinConfig(
    themeData: ClassicTheme.themeData,
    buildRemoteSkin: ({required onKeyPressed}) =>
        ClassicRemoteSkin(onKeyPressed: onKeyPressed),
  ),
  AppSkin.main: SkinConfig(
    themeData: MainTheme.themeData,
    buildRemoteSkin: ({required onKeyPressed}) =>
        MainRemoteSkin(onKeyPressed: onKeyPressed),
  ),
};
