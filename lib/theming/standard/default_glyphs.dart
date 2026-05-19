import '../../data/models/layout/button_appearance.dart';
import '../../data/models/layout/remote_button.dart';
import '../remote_key.dart';

/// Provisional default glyphs and labels for the [RemoteKey] catalogue.
///
/// This is the seed of the `Standard` icon pack: Phase 5 replaces it with a
/// real icon catalogue. Until then, [DefaultLook] — and the icon/image
/// appearances ([BuiltInIcon], [PackIcon], [CustomImage]) that cannot be
/// resolved before Phases 5–6 — render as the single-character glyphs below.
const Map<RemoteKey, String> _glyphs = {
  RemoteKey.up: '▲',
  RemoteKey.down: '▼',
  RemoteKey.left: '◀',
  RemoteKey.right: '▶',
  RemoteKey.ok: 'OK',
  RemoteKey.back: '⬅',
  RemoteKey.home: '⌂',
  RemoteKey.rewind: '⏪',
  RemoteKey.playPause: '⏯',
  RemoteKey.fastForward: '⏩',
  RemoteKey.next: '⏭',
  RemoteKey.previous: '⏮',
  RemoteKey.volumeUp: '＋',
  RemoteKey.volumeDown: '－',
  RemoteKey.mute: '🔇',
  RemoteKey.power: '⏻',
};

const Map<RemoteKey, String> _labels = {
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

/// The default single-glyph representation of [key].
String defaultGlyph(RemoteKey key) => _glyphs[key] ?? key.code;

/// The default human-readable label for [key].
String defaultLabel(RemoteKey key) => _labels[key] ?? key.code;

/// The text a standard renderer paints inside [button].
///
/// A [TextOnly] button shows its label (the override, or the action default);
/// every other appearance shows the action's default glyph — including the
/// icon/image kinds, which gain real resolution in Phases 5–6.
String buttonGlyph(RemoteButton button) {
  final appearance = button.appearance;
  if (appearance is TextOnly) {
    return appearance.labelOverride ?? defaultLabel(button.action);
  }
  return defaultGlyph(button.action);
}
