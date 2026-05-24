import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:flixsy/data/models/layout/layout_block.dart';
import 'package:flixsy/data/models/layout/remote_button.dart';
import 'package:flixsy/core/extensions/l10n_extensions.dart';
import 'package:flixsy/shared/widgets/pointer_aware_star_dpad.dart';
import 'package:flixsy/theming/icons/remote_key_l10n.dart';
import 'package:flixsy/theming/remote_key.dart';
import 'package:flixsy/theming/skin_tokens.dart';
import 'package:flixsy/theming/standard/button_presentation.dart';
import 'package:flixsy/theming/standard/remote_image_scope.dart';
import 'package:flixsy/theming/standard/section_renderer.dart';

/// The `Classic` skin as a [SectionRenderer]: plain rounded [ElevatedButton]s
/// styled entirely by `ClassicTheme`. Together with that theme it forms the
/// standard `Classic` skin.
class ClassicSectionRenderer implements SectionRenderer {
  const ClassicSectionRenderer();

  /// Logical side of an empty [GridBlock] cell, so the grid keeps its shape.
  static const double _emptyCellSide = 56;

  @override
  Widget buildDpad(
    BuildContext context,
    DpadBlock block,
    KeyPressHandler onKey,
  ) {
    final gap = SkinTokens.of(context).buttonGap;
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _button(context, block.volumeUp, onKey, gap, compact: true),
            _button(context, block.volumeDown, onKey, gap, compact: true),
          ],
        ),
        Padding(
          padding: EdgeInsets.all(gap / 2),
          child: PointerAwareStarDpad(
            size: 200,
            onUp: () => onKey(block.up.action),
            onDown: () => onKey(block.down.action),
            onLeft: () => onKey(block.left.action),
            onRight: () => onKey(block.right.action),
            onOk: () => onKey(block.ok.action),
            onScrollUp: () => onKey(RemoteKey.up),
            onScrollDown: () => onKey(RemoteKey.down),
            onScrollLeft: () => onKey(RemoteKey.left),
            onScrollRight: () => onKey(RemoteKey.right),
          ),
        ),
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _button(context, block.channelUp, onKey, gap, compact: true),
            _button(context, block.channelDown, onKey, gap, compact: true),
          ],
        ),
      ],
    );
  }

  @override
  Widget buildButtonRow(
    BuildContext context,
    ButtonRowBlock block,
    KeyPressHandler onKey,
  ) {
    final gap = SkinTokens.of(context).buttonGap;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final button in block.buttons)
          _button(context, button, onKey, gap),
      ],
    );
  }

  @override
  Widget buildVolume(
    BuildContext context,
    VolumeBlock block,
    KeyPressHandler onKey,
  ) {
    final gap = SkinTokens.of(context).buttonGap;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _button(context, block.volumeDown, onKey, gap),
        _button(context, block.mute, onKey, gap),
        _button(context, block.volumeUp, onKey, gap),
      ],
    );
  }

  @override
  Widget buildGrid(
    BuildContext context,
    GridBlock block,
    KeyPressHandler onKey,
  ) {
    final gap = SkinTokens.of(context).buttonGap;
    final columns = math.max(1, block.columns);
    final rows = <Widget>[];
    for (var start = 0; start < block.cells.length; start += columns) {
      final end = math.min(start + columns, block.cells.length);
      rows.add(
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final cell in block.cells.sublist(start, end))
              cell == null
                  ? const SizedBox.square(dimension: _emptyCellSide)
                  : _button(context, cell, onKey, gap),
          ],
        ),
      );
    }
    return Column(mainAxisSize: MainAxisSize.min, children: rows);
  }

  @override
  Widget buildSpacer(BuildContext context, SpacerBlock block) =>
      SizedBox(height: block.height);

  /// A single rounded button; styling comes from the ambient `ElevatedButton`
  /// theme, so every block draws a consistent classic button.
  Widget _button(
    BuildContext context,
    RemoteButton button,
    KeyPressHandler onKey,
    double gap, {
    bool compact = false,
  }) {
    final presentation = resolveButton(
      button,
      imagePaths: RemoteImageScope.of(context),
      labelFor: context.l10n.remoteKeyLabel,
    );
    return Padding(
      padding: EdgeInsets.all(gap / 2),
      child: ElevatedButton(
        style: compact
            ? ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              )
            : ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 12,
                ),
              ),
        onPressed: () => onKey(button.action),
        child: _ButtonContent(
          presentation: presentation,
          compact: compact,
        ),
      ),
    );
  }
}

/// Paints a button's resolved [ButtonPresentation]: the glyph — an icon, a
/// custom image, or text for a text-only button — with the caption beneath it
/// when shown.
class _ButtonContent extends StatelessWidget {
  const _ButtonContent({required this.presentation, this.compact = false});

  final ButtonPresentation presentation;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final glyph = presentation.glyph;
    final iconSize = compact ? 18.0 : 24.0;
    final imageSide = compact ? 20.0 : 28.0;
    final mark = switch (glyph) {
      IconGlyph(:final icon) => Icon(icon, size: iconSize),
      ImageGlyph(:final path) => Image.file(
        File(path),
        width: imageSide,
        height: imageSide,
        fit: BoxFit.contain,
        // The file may have been swept between path resolution and paint.
        errorBuilder: (_, _, _) =>
            Icon(Icons.broken_image_outlined, size: iconSize),
      ),
      TextGlyph(:final text) => Text(text),
    };

    // Captions are intentionally dropped: every button is icon-only. The
    // semantic label names the action for accessibility.
    return Semantics(label: presentation.semanticLabel, child: mark);
  }
}
