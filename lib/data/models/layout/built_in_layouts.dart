import '../../../theming/remote_key.dart';
import 'layout_block.dart';
import 'remote_button.dart';
import 'remote_layout.dart';

/// Reserved id prefix marking a layout as a read-only built-in template.
///
/// Built-in layouts are `const` data — not Drift rows. "Editing" a template
/// copies it into a writable `custom_layouts` row (see §7 of the design doc).
const String builtInLayoutIdPrefix = 'builtin:';

/// The built-in `Classic` layout: a full remote — system row at the top, a
/// D-pad flanked by volume (left) and channel (right) rockers, a mute row,
/// then the transport row — with 24px of breathing room between groups.
const RemoteLayout classicLayout = RemoteLayout(
  id: '${builtInLayoutIdPrefix}classic',
  name: 'Classic',
  isTemplate: true,
  blocks: [
    ButtonRowBlock(
      buttons: [
        RemoteButton(action: RemoteKey.power),
        RemoteButton(action: RemoteKey.home),
        RemoteButton(action: RemoteKey.back),
        RemoteButton(action: RemoteKey.settings),
      ],
    ),
    SpacerBlock(height: 24),
    DpadBlock(
      up: RemoteButton(action: RemoteKey.up),
      down: RemoteButton(action: RemoteKey.down),
      left: RemoteButton(action: RemoteKey.left),
      right: RemoteButton(action: RemoteKey.right),
      ok: RemoteButton(action: RemoteKey.ok),
      volumeUp: RemoteButton(action: RemoteKey.volumeUp),
      volumeDown: RemoteButton(action: RemoteKey.volumeDown),
      channelUp: RemoteButton(action: RemoteKey.channelUp),
      channelDown: RemoteButton(action: RemoteKey.channelDown),
    ),
    SpacerBlock(height: 24),
    ButtonRowBlock(buttons: [RemoteButton(action: RemoteKey.mute)]),
    SpacerBlock(height: 24),
    ButtonRowBlock(
      buttons: [
        RemoteButton(action: RemoteKey.rewind),
        RemoteButton(action: RemoteKey.playPause),
        RemoteButton(action: RemoteKey.fastForward),
      ],
    ),
  ],
);

/// Every built-in layout template, in display order.
const List<RemoteLayout> builtInLayouts = [classicLayout];
