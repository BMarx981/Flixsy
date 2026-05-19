/// The **capability axis** of the remote: *which* keys can exist.
///
/// Per `docs/custom_layouts_design.md`, a remote control is the product of
/// three independent concerns — capability (this file), layout (user data),
/// and skin (visual code). [RemoteKey] is the single source of truth for key
/// codes, replacing the magic strings previously duplicated across skins.
///
/// This file is intentionally pure Dart with no Flutter import: a key's
/// default icon and label are a *presentation* concern and live in the icon
/// catalog, not here.
library;

/// Broad functional grouping of a [RemoteKey].
///
/// Used by the layout editor to offer keys in sensible clusters; it never
/// affects what a key does or how it is sent.
enum RemoteKeyRole { dpad, navigation, transport, volume, system }

/// Every remote key the app can send.
///
/// [code] is the only thing handed to `RemoteChannel.sendKeyCommand`; channel
/// implementations translate it to their vendor-specific wire value. The enum
/// is extended as channels gain support for more keys.
enum RemoteKey {
  up('UP', RemoteKeyRole.dpad),
  down('DOWN', RemoteKeyRole.dpad),
  left('LEFT', RemoteKeyRole.dpad),
  right('RIGHT', RemoteKeyRole.dpad),
  ok('OK', RemoteKeyRole.dpad),
  back('BACK', RemoteKeyRole.navigation),
  home('HOME', RemoteKeyRole.navigation),
  rewind('REWIND', RemoteKeyRole.transport),
  playPause('PLAY_PAUSE', RemoteKeyRole.transport),
  fastForward('FAST_FORWARD', RemoteKeyRole.transport),
  next('NEXT', RemoteKeyRole.transport),
  previous('PREVIOUS', RemoteKeyRole.transport),
  volumeUp('VOLUME_UP', RemoteKeyRole.volume),
  volumeDown('VOLUME_DOWN', RemoteKeyRole.volume),
  mute('MUTE', RemoteKeyRole.volume),
  power('POWER', RemoteKeyRole.system);

  const RemoteKey(this.code, this.role);

  /// The wire string passed to `RemoteChannel.sendKeyCommand`.
  final String code;

  /// Functional grouping, used purely for organising the key picker.
  final RemoteKeyRole role;

  /// Resolves a wire [code] back to its key, or `null` when none matches.
  ///
  /// Returning `null` rather than throwing keeps layout deserialization
  /// total — a layout from a newer build referencing a key this build does
  /// not know simply drops that button (see `custom_layouts_design.md` §4.4).
  static RemoteKey? fromCode(String code) {
    for (final key in values) {
      if (key.code == code) return key;
    }
    return null;
  }
}
