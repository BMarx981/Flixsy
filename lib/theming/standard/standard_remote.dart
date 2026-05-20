import 'package:flutter/material.dart';

import '../../data/models/layout/layout_block.dart';
import '../../data/models/layout/remote_layout.dart';
import '../remote_key.dart';
import '../remote_skin.dart';
import 'remote_image_scope.dart';
import 'section_renderer.dart';

/// Renders a [RemoteLayout] by walking its blocks and handing each to the
/// active skin's [SectionRenderer].
///
/// Every standard skin shares this widget; only the [renderer] and the
/// ambient `ThemeData` differ. It satisfies the [RemoteSkin] contract, so
/// `HomeScreen` treats a standard skin exactly like a bespoke one.
class StandardRemote extends StatelessWidget implements RemoteSkin {
  const StandardRemote({
    super.key,
    required this.layout,
    required this.renderer,
    required this.onKeyPressed,
    this.imagePaths = const {},
  });

  /// The layout to render — its ordered blocks become the on-screen sections.
  final RemoteLayout layout;

  /// The active skin's renderer, which draws each block's chrome.
  final SectionRenderer renderer;

  /// Custom-image id → file-path map, made available to the renderer through
  /// a [RemoteImageScope] so `CustomImage` buttons resolve to their files.
  final Map<String, String> imagePaths;

  @override
  final void Function(String key) onKeyPressed;

  @override
  Widget build(BuildContext context) {
    void onKey(RemoteKey key) => onKeyPressed(key.code);

    return RemoteImageScope(
      imagePaths: imagePaths,
      // A remote is a physical control surface: a D-pad's left/right and a
      // grid's column order must keep their geometry, so the layout is fixed
      // to LTR and never mirrors with an RTL UI language. Button captions are
      // still localized — only the spatial arrangement is pinned.
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final block in layout.blocks)
                switch (block) {
                  DpadBlock() => renderer.buildDpad(context, block, onKey),
                  ButtonRowBlock() => renderer.buildButtonRow(
                    context,
                    block,
                    onKey,
                  ),
                  VolumeBlock() => renderer.buildVolume(context, block, onKey),
                  GridBlock() => renderer.buildGrid(context, block, onKey),
                  SpacerBlock() => renderer.buildSpacer(context, block),
                },
            ],
          ),
        ),
      ),
    );
  }
}
