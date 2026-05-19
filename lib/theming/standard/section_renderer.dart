import 'package:flutter/widgets.dart';

import '../../data/models/layout/layout_block.dart';
import '../remote_key.dart';

/// Invoked when a rendered button is pressed, with the [RemoteKey] it carries.
typedef KeyPressHandler = void Function(RemoteKey key);

/// Draws the visual chrome for each [LayoutBlock] type — one `build…` method
/// per block.
///
/// A **standard skin** is a [SectionRenderer] paired with a `ThemeData` (and
/// its `SkinTokens`). The renderer owns the block's shape, colour and press
/// feedback; the glyph painted inside each button is resolved separately from
/// the button's appearance. Bespoke skins ignore this interface and implement
/// `RemoteSkin` directly — see `docs/custom_layouts_design.md` §5.
abstract interface class SectionRenderer {
  Widget buildDpad(
    BuildContext context,
    DpadBlock block,
    KeyPressHandler onKey,
  );

  Widget buildButtonRow(
    BuildContext context,
    ButtonRowBlock block,
    KeyPressHandler onKey,
  );

  Widget buildVolume(
    BuildContext context,
    VolumeBlock block,
    KeyPressHandler onKey,
  );

  Widget buildGrid(
    BuildContext context,
    GridBlock block,
    KeyPressHandler onKey,
  );

  Widget buildSpacer(BuildContext context, SpacerBlock block);
}
