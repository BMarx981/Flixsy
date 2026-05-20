import 'package:flutter/material.dart';

import 'remote_skin.dart';
import 'skins/classic/classic_section_renderer.dart';
import 'skins/classic/classic_theme.dart';
import 'skins/campfire/campfire_remote_skin.dart';
import 'skins/campfire/campfire_theme.dart';
import 'skins/cloud/cloud_remote_skin.dart';
import 'skins/cloud/cloud_theme.dart';
import 'skins/main/main_remote_skin.dart';
import 'skins/main/main_theme.dart';
import 'skins/ocean/ocean_remote_skin.dart';
import 'skins/ocean/ocean_theme.dart';
import 'skins/waterfall/waterfall_remote_skin.dart';
import 'skins/waterfall/waterfall_theme.dart';
import 'standard/standard_remote.dart';

enum AppSkin { classic, main, waterfall, cloud, ocean, campfire }

class SkinConfig {
  const SkinConfig({
    required this.themeData,
    required this.buildRemoteSkin,
    this.edgeToEdge = false,
  });

  final ThemeData themeData;
  final RemoteSkinBuilder buildRemoteSkin;

  /// When true, the host (`HomeScreen`) renders this skin without `SafeArea`
  /// or body padding — the skin fills the body up to the app bar. The skin is
  /// then responsible for keeping its own buttons clear of system insets.
  final bool edgeToEdge;
}

final Map<AppSkin, SkinConfig> skinRegistry = {
  // A standard skin: the shared StandardRemote walks the active layout and
  // defers each block to ClassicSectionRenderer.
  AppSkin.classic: SkinConfig(
    themeData: ClassicTheme.themeData,
    buildRemoteSkin:
        ({required onKeyPressed, required layout, required imagePaths}) =>
            StandardRemote(
              layout: layout,
              renderer: const ClassicSectionRenderer(),
              onKeyPressed: onKeyPressed,
              imagePaths: imagePaths,
            ),
  ),
  // A bespoke skin: hand-coded hit-testing, implements RemoteSkin directly.
  // Its arrangement is fixed, so it ignores the layout and image arguments.
  AppSkin.main: SkinConfig(
    themeData: MainTheme.themeData,
    buildRemoteSkin:
        ({required onKeyPressed, required layout, required imagePaths}) =>
            MainRemoteSkin(onKeyPressed: onKeyPressed),
  ),
  // A bespoke skin that still walks the active layout: a slow waterfall of
  // blues behind a StandardRemote whose buttons pulse together.
  AppSkin.waterfall: SkinConfig(
    themeData: WaterfallTheme.themeData,
    edgeToEdge: true,
    buildRemoteSkin:
        ({required onKeyPressed, required layout, required imagePaths}) =>
            WaterfallRemoteSkin(
              layout: layout,
              imagePaths: imagePaths,
              onKeyPressed: onKeyPressed,
            ),
  ),
  // A bright counterpart to the waterfall: clouds drift horizontally across a
  // sky-blue gradient while the button panels breathe gently.
  AppSkin.cloud: SkinConfig(
    themeData: CloudTheme.themeData,
    edgeToEdge: true,
    buildRemoteSkin:
        ({required onKeyPressed, required layout, required imagePaths}) =>
            CloudRemoteSkin(
              layout: layout,
              imagePaths: imagePaths,
              onKeyPressed: onKeyPressed,
            ),
  ),
  // A horizon between a slowly-cycling sky (sunrise → midday → sunset →
  // night) and a calm sea, with the buttons floating constant over the water.
  AppSkin.ocean: SkinConfig(
    themeData: OceanTheme.themeData,
    edgeToEdge: true,
    buildRemoteSkin:
        ({required onKeyPressed, required layout, required imagePaths}) =>
            OceanRemoteSkin(
              layout: layout,
              imagePaths: imagePaths,
              onKeyPressed: onKeyPressed,
            ),
  ),
  // A desert-night scene: starlit sky with a crescent moon, layered mesa
  // silhouettes on the horizon and an animated campfire with rising embers
  // at the base. Buttons glow ember-warm with the shared pulse.
  AppSkin.campfire: SkinConfig(
    themeData: CampfireTheme.themeData,
    edgeToEdge: true,
    buildRemoteSkin:
        ({required onKeyPressed, required layout, required imagePaths}) =>
            CampfireRemoteSkin(
              layout: layout,
              imagePaths: imagePaths,
              onKeyPressed: onKeyPressed,
            ),
  ),
};
