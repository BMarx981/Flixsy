import 'package:flixsy/l10n/generated/app_localizations.dart';
import 'package:flixsy/theming/remote_key.dart';

/// Localized presentation strings for the capability axis ([RemoteKey]).
///
/// [RemoteKey] itself is pure Dart with no Flutter import — a key's *label* is
/// a presentation concern, so it lives here next to the icon catalog rather
/// than on the enum. The English fallback (`defaultLabel`) stays in
/// `icon_catalog.dart` for non-UI callers such as tests.
extension RemoteKeyL10n on AppLocalizations {
  /// The localized label for [key] — the caption painted on its button.
  String remoteKeyLabel(RemoteKey key) => switch (key) {
    RemoteKey.up => remoteKeyUp,
    RemoteKey.down => remoteKeyDown,
    RemoteKey.left => remoteKeyLeft,
    RemoteKey.right => remoteKeyRight,
    RemoteKey.ok => remoteKeyOk,
    RemoteKey.back => remoteKeyBack,
    RemoteKey.home => remoteKeyHome,
    RemoteKey.keyboard => remoteKeyKeyboard,
    RemoteKey.rewind => remoteKeyRewind,
    RemoteKey.playPause => remoteKeyPlayPause,
    RemoteKey.fastForward => remoteKeyFastForward,
    RemoteKey.next => remoteKeyNext,
    RemoteKey.previous => remoteKeyPrevious,
    RemoteKey.volumeUp => remoteKeyVolumeUp,
    RemoteKey.volumeDown => remoteKeyVolumeDown,
    RemoteKey.mute => remoteKeyMute,
    RemoteKey.channelUp => remoteKeyChannelUp,
    RemoteKey.channelDown => remoteKeyChannelDown,
    RemoteKey.power => remoteKeyPower,
    RemoteKey.settings => remoteKeySettings,
  };

  /// The localized group header for [role] in the action picker.
  String keyRoleLabel(RemoteKeyRole role) => switch (role) {
    RemoteKeyRole.dpad => keyRoleDpad,
    RemoteKeyRole.navigation => keyRoleNavigation,
    RemoteKeyRole.transport => keyRoleTransport,
    RemoteKeyRole.volume => keyRoleVolume,
    RemoteKeyRole.channel => keyRoleChannel,
    RemoteKeyRole.system => keyRoleSystem,
  };

  /// The localized name of a `Standard`-pack icon, by its id.
  ///
  /// An unknown id degrades to [appearanceCustomIcon] — the same total
  /// resolution the icon catalog uses everywhere else.
  String iconName(String iconId) => switch (iconId) {
    'up' => iconNameUp,
    'down' => iconNameDown,
    'left' => iconNameLeft,
    'right' => iconNameRight,
    'ok' => iconNameOk,
    'back' => iconNameBack,
    'home' => iconNameHome,
    'rewind' => iconNameRewind,
    'fast_forward' => iconNameFastForward,
    'play_pause' => iconNamePlayPause,
    'play' => iconNamePlay,
    'pause' => iconNamePause,
    'stop' => iconNameStop,
    'next' => iconNameNext,
    'previous' => iconNamePrevious,
    'volume_up' => iconNameVolumeUp,
    'volume_down' => iconNameVolumeDown,
    'mute' => iconNameMute,
    'channel_up' => iconNameChannelUp,
    'channel_down' => iconNameChannelDown,
    'power' => iconNamePower,
    'menu' => iconNameMenu,
    'settings' => iconNameSettings,
    'info' => iconNameInfo,
    'mic' => iconNameMic,
    'keyboard' => iconNameKeyboard,
    _ => appearanceCustomIcon,
  };
}
