import 'package:flutter/material.dart';

import '../remote_key.dart';
import 'icon_pack.dart';

/// The icon catalogue: the built-in `Standard` pack plus each [RemoteKey]'s
/// default icon and label.
///
/// This replaces the provisional `default_glyphs.dart` from Phase 2. The
/// `Standard` pack is backed by Material icons — no bundled assets — so every
/// icon resolves synchronously and is type-safe. Branded/partner packs
/// (Phase 7) join [iconPacks] alongside it; until then `Standard` is the only
/// pack and a [PackIcon] referencing any other pack degrades to a default.

/// The curated built-in `Standard` icon pack.
///
/// Covers the default icon for every [RemoteKey] plus a handful of common
/// alternates (separate play / pause / stop, menu, settings…) so the picker
/// has substance. The pack grows as the [RemoteKey] catalogue does.
final IconPack standardPack = IconPack(
  id: 'standard',
  name: 'Standard',
  entries: const [
    IconPackEntry(id: 'up', name: 'Up', icon: Icons.keyboard_arrow_up),
    IconPackEntry(id: 'down', name: 'Down', icon: Icons.keyboard_arrow_down),
    IconPackEntry(id: 'left', name: 'Left', icon: Icons.keyboard_arrow_left),
    IconPackEntry(id: 'right', name: 'Right', icon: Icons.keyboard_arrow_right),
    IconPackEntry(id: 'ok', name: 'OK', icon: Icons.radio_button_checked),
    IconPackEntry(id: 'back', name: 'Back', icon: Icons.arrow_back),
    IconPackEntry(id: 'home', name: 'Home', icon: Icons.home),
    IconPackEntry(id: 'rewind', name: 'Rewind', icon: Icons.fast_rewind),
    IconPackEntry(
      id: 'fast_forward',
      name: 'Fast forward',
      icon: Icons.fast_forward,
    ),
    IconPackEntry(
      id: 'play_pause',
      name: 'Play / Pause',
      icon: Icons.play_arrow,
    ),
    IconPackEntry(id: 'play', name: 'Play', icon: Icons.play_arrow),
    IconPackEntry(id: 'pause', name: 'Pause', icon: Icons.pause),
    IconPackEntry(id: 'stop', name: 'Stop', icon: Icons.stop),
    IconPackEntry(id: 'next', name: 'Next', icon: Icons.skip_next),
    IconPackEntry(id: 'previous', name: 'Previous', icon: Icons.skip_previous),
    IconPackEntry(id: 'volume_up', name: 'Volume up', icon: Icons.volume_up),
    IconPackEntry(
      id: 'volume_down',
      name: 'Volume down',
      icon: Icons.volume_down,
    ),
    IconPackEntry(id: 'mute', name: 'Mute', icon: Icons.volume_off),
    IconPackEntry(id: 'power', name: 'Power', icon: Icons.power_settings_new),
    IconPackEntry(id: 'menu', name: 'Menu', icon: Icons.menu),
    IconPackEntry(id: 'settings', name: 'Settings', icon: Icons.settings),
    IconPackEntry(id: 'info', name: 'Info', icon: Icons.info_outline),
    IconPackEntry(id: 'mic', name: 'Microphone', icon: Icons.mic),
  ],
);

/// Every registered icon pack, keyed by [IconPack.id].
///
/// Partner packs (Phase 7) register here; today `Standard` is the only one.
final Map<String, IconPack> iconPacks = {standardPack.id: standardPack};

/// The `Standard`-pack icon id that is each key's default appearance.
const Map<RemoteKey, String> _defaultIconIds = {
  RemoteKey.up: 'up',
  RemoteKey.down: 'down',
  RemoteKey.left: 'left',
  RemoteKey.right: 'right',
  RemoteKey.ok: 'ok',
  RemoteKey.back: 'back',
  RemoteKey.home: 'home',
  RemoteKey.rewind: 'rewind',
  RemoteKey.playPause: 'play_pause',
  RemoteKey.fastForward: 'fast_forward',
  RemoteKey.next: 'next',
  RemoteKey.previous: 'previous',
  RemoteKey.volumeUp: 'volume_up',
  RemoteKey.volumeDown: 'volume_down',
  RemoteKey.mute: 'mute',
  RemoteKey.power: 'power',
};

/// The default human-readable label for each key.
const Map<RemoteKey, String> _defaultLabels = {
  RemoteKey.up: 'Up',
  RemoteKey.down: 'Down',
  RemoteKey.left: 'Left',
  RemoteKey.right: 'Right',
  RemoteKey.ok: 'OK',
  RemoteKey.back: 'Back',
  RemoteKey.home: 'Home',
  RemoteKey.rewind: 'Rewind',
  RemoteKey.playPause: 'Play/Pause',
  RemoteKey.fastForward: 'Fast Forward',
  RemoteKey.next: 'Next',
  RemoteKey.previous: 'Previous',
  RemoteKey.volumeUp: 'Volume Up',
  RemoteKey.volumeDown: 'Volume Down',
  RemoteKey.mute: 'Mute',
  RemoteKey.power: 'Power',
};

/// Fallback glyph for a key with no catalogue default — should never show in
/// practice, since [_defaultIconIds] covers every [RemoteKey].
const IconData _fallbackIcon = Icons.circle_outlined;

/// The default catalogue icon for [key].
IconData defaultIconFor(RemoteKey key) {
  final id = _defaultIconIds[key];
  return (id == null ? null : standardPack.resolve(id)?.icon) ?? _fallbackIcon;
}

/// The id of [key]'s default `Standard`-pack icon, or `null` if it has none.
String? defaultIconIdFor(RemoteKey key) => _defaultIconIds[key];

/// The default human-readable label for [key].
String defaultLabel(RemoteKey key) => _defaultLabels[key] ?? key.code;

/// Resolves a `(packId, iconId)` pair to its glyph, or `null` when the pack is
/// unknown, locked, or has no such icon — callers degrade to a default.
IconData? resolvePackIcon(String packId, String iconId) {
  final pack = iconPacks[packId];
  if (pack == null || !pack.isUnlocked) return null;
  return pack.resolve(iconId)?.icon;
}
