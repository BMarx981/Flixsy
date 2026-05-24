import 'package:flutter/material.dart';

import 'package:flixsy/theming/remote_skin.dart';
import 'package:flixsy/theming/skins/classic/classic_section_renderer.dart';
import 'package:flixsy/theming/skins/classic/classic_theme.dart';
import 'package:flixsy/theming/skins/campfire/campfire_remote_skin.dart';
import 'package:flixsy/theming/skins/campfire/campfire_theme.dart';
import 'package:flixsy/theming/skins/cityscape/cityscape_remote_skin.dart';
import 'package:flixsy/theming/skins/cityscape/cityscape_theme.dart';
import 'package:flixsy/theming/skins/cloud/cloud_remote_skin.dart';
import 'package:flixsy/theming/skins/cloud/cloud_theme.dart';
import 'package:flixsy/theming/skins/honkytonk/honkytonk_remote_skin.dart';
import 'package:flixsy/theming/skins/honkytonk/honkytonk_theme.dart';
import 'package:flixsy/theming/skins/main/main_remote_skin.dart';
import 'package:flixsy/theming/skins/main/main_theme.dart';
import 'package:flixsy/theming/skins/ocean/ocean_remote_skin.dart';
import 'package:flixsy/theming/skins/ocean/ocean_theme.dart';
import 'package:flixsy/theming/skins/punk/punk_remote_skin.dart';
import 'package:flixsy/theming/skins/punk/punk_theme.dart';
import 'package:flixsy/theming/skins/waterfall/waterfall_remote_skin.dart';
import 'package:flixsy/theming/skins/waterfall/waterfall_theme.dart';
import 'package:flixsy/theming/standard/standard_remote.dart';

enum AppSkin {
  classic,
  main,
  waterfall,
  cloud,
  ocean,
  campfire,
  honkytonk,
  cityscape,
  punk,
}

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
  // A dim country-bar interior: wood-plank walls, a row of warm pendant
  // bulbs, a neon guitar sign on the back wall, drifting smoke and a wooden
  // floor. Buttons glow hot-pink with the shared pulse.
  AppSkin.honkytonk: SkinConfig(
    themeData: HonkytonkTheme.themeData,
    edgeToEdge: true,
    buildRemoteSkin:
        ({required onKeyPressed, required layout, required imagePaths}) =>
            HonkytonkRemoteSkin(
              layout: layout,
              imagePaths: imagePaths,
              onKeyPressed: onKeyPressed,
            ),
  ),
  // A night skyline: deep indigo sky with stars and a soft moon, three
  // parallax bands of building silhouettes speckled with lit windows, and
  // blinking red aircraft warning lights atop the tallest towers. Buttons
  // glow cool cyan with the shared pulse.
  AppSkin.cityscape: SkinConfig(
    themeData: CityscapeTheme.themeData,
    edgeToEdge: true,
    buildRemoteSkin:
        ({required onKeyPressed, required layout, required imagePaths}) =>
            CityscapeRemoteSkin(
              layout: layout,
              imagePaths: imagePaths,
              onKeyPressed: onKeyPressed,
            ),
  ),
  // A graffitied alley: dark brick wall with chipped bricks, two torn band
  // posters stapled crooked, spray-paint splatters and slow drips, and a
  // hot-magenta Flixsy sparkle-star tag in the upper-centre. Buttons are
  // notched-corner stencils that breathe magenta with the shared pulse.
  AppSkin.punk: SkinConfig(
    themeData: PunkTheme.themeData,
    edgeToEdge: true,
    buildRemoteSkin:
        ({required onKeyPressed, required layout, required imagePaths}) =>
            PunkRemoteSkin(
              layout: layout,
              imagePaths: imagePaths,
              onKeyPressed: onKeyPressed,
            ),
  ),
};
