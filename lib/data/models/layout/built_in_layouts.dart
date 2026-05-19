import '../../../theming/remote_key.dart';
import 'layout_block.dart';
import 'remote_button.dart';
import 'remote_layout.dart';

/// Reserved id prefix marking a layout as a read-only built-in template.
///
/// Built-in layouts are `const` data — not Drift rows. "Editing" a template
/// copies it into a writable `custom_layouts` row (see §7 of the design doc).
const String builtInLayoutIdPrefix = 'builtin:';

/// The built-in `Classic` layout: a directional cross above a transport row.
///
/// This reproduces the original hand-coded classic skin exactly — a D-pad,
/// 24px of breathing room, then rewind / play-pause / fast-forward.
const RemoteLayout classicLayout = RemoteLayout(
  id: '${builtInLayoutIdPrefix}classic',
  name: 'Classic',
  isTemplate: true,
  blocks: [
    DpadBlock(
      up: RemoteButton(action: RemoteKey.up),
      down: RemoteButton(action: RemoteKey.down),
      left: RemoteButton(action: RemoteKey.left),
      right: RemoteButton(action: RemoteKey.right),
      ok: RemoteButton(action: RemoteKey.ok),
    ),
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
