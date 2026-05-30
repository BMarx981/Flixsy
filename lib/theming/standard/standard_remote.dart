import 'package:flutter/material.dart';

import 'package:flixsy/data/models/layout/layout_block.dart';
import 'package:flixsy/data/models/layout/remote_layout.dart';
import 'package:flixsy/theming/remote_key.dart';
import 'package:flixsy/theming/remote_skin.dart';
import 'package:flixsy/theming/standard/remote_image_scope.dart';
import 'package:flixsy/theming/standard/section_renderer.dart';

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
        // Wrap in a scroll view so the bottom buttons stay reachable on
        // short phones and in landscape; the `ConstrainedBox(minHeight)`
        // keeps the column centered within the viewport when content fits,
        // so taller phones still see the remote anchored to the middle of
        // the screen instead of jumping to the top.
        //
        // The D-pads use [EagerPanGestureRecognizer], which claims the
        // local arena on touch-down — so the scroll view can never steal
        // a spin gesture mid-drag.
        child: LayoutBuilder(
          builder: (context, constraints) {
            // Parents inside another scrollable (layout-editor preview, etc.)
            // pass unbounded vertical constraints — pin the min to 0 in that
            // case so the column just takes its intrinsic height.
            final minHeight = constraints.maxHeight.isFinite
                ? constraints.maxHeight
                : 0.0;
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: minHeight),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (final block in layout.blocks)
                        switch (block) {
                          DpadBlock() => renderer.buildDpad(
                            context,
                            block,
                            onKey,
                          ),
                          ButtonRowBlock() => renderer.buildButtonRow(
                            context,
                            block,
                            onKey,
                          ),
                          VolumeBlock() => renderer.buildVolume(
                            context,
                            block,
                            onKey,
                          ),
                          GridBlock() => renderer.buildGrid(
                            context,
                            block,
                            onKey,
                          ),
                          SpacerBlock() => renderer.buildSpacer(context, block),
                        },
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
