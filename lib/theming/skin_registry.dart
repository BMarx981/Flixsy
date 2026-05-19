import 'package:flutter/material.dart';

import 'remote_skin.dart';
import 'skins/classic/classic_section_renderer.dart';
import 'skins/classic/classic_theme.dart';
import 'skins/main/main_remote_skin.dart';
import 'skins/main/main_theme.dart';
import 'standard/standard_remote.dart';

enum AppSkin { classic, main }

class SkinConfig {
  const SkinConfig({required this.themeData, required this.buildRemoteSkin});

  final ThemeData themeData;
  final RemoteSkinBuilder buildRemoteSkin;
}

final Map<AppSkin, SkinConfig> skinRegistry = {
  // A standard skin: the shared StandardRemote walks the active layout and
  // defers each block to ClassicSectionRenderer.
  AppSkin.classic: SkinConfig(
    themeData: ClassicTheme.themeData,
    buildRemoteSkin: ({required onKeyPressed, required layout}) =>
        StandardRemote(
          layout: layout,
          renderer: const ClassicSectionRenderer(),
          onKeyPressed: onKeyPressed,
        ),
  ),
  // A bespoke skin: hand-coded hit-testing, implements RemoteSkin directly.
  // Its arrangement is fixed, so it ignores the layout argument.
  AppSkin.main: SkinConfig(
    themeData: MainTheme.themeData,
    buildRemoteSkin: ({required onKeyPressed, required layout}) =>
        MainRemoteSkin(onKeyPressed: onKeyPressed),
  ),
};
