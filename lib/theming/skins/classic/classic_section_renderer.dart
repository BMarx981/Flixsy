import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../data/models/layout/layout_block.dart';
import '../../../data/models/layout/remote_button.dart';
import '../../skin_tokens.dart';
import '../../standard/button_presentation.dart';
import '../../standard/section_renderer.dart';

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
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _button(block.up, onKey, gap),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _button(block.left, onKey, gap),
            _button(block.ok, onKey, gap),
            _button(block.right, onKey, gap),
          ],
        ),
        _button(block.down, onKey, gap),
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
        for (final button in block.buttons) _button(button, onKey, gap),
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
        _button(block.volumeDown, onKey, gap),
        _button(block.mute, onKey, gap),
        _button(block.volumeUp, onKey, gap),
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
                  : _button(cell, onKey, gap),
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
  Widget _button(RemoteButton button, KeyPressHandler onKey, double gap) {
    return Padding(
      padding: EdgeInsets.all(gap / 2),
      child: ElevatedButton(
        onPressed: () => onKey(button.action),
        child: _ButtonContent(presentation: resolveButton(button)),
      ),
    );
  }
}

/// Paints a button's resolved [ButtonPresentation]: the glyph — an icon, or
/// text for a text-only button — with the caption beneath it when shown.
class _ButtonContent extends StatelessWidget {
  const _ButtonContent({required this.presentation});

  final ButtonPresentation presentation;

  @override
  Widget build(BuildContext context) {
    final glyph = presentation.glyph;
    final mark = switch (glyph) {
      IconGlyph(:final icon) => Icon(icon, size: 24),
      TextGlyph(:final text) => Text(text),
    };
    final caption = presentation.caption;

    final content = caption == null
        ? mark
        : Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              mark,
              const SizedBox(height: 2),
              Text(caption, style: const TextStyle(fontSize: 11)),
            ],
          );

    // The icon glyph carries no text, so name the button for screen readers.
    return Semantics(
      label: presentation.semanticLabel,
      child: content,
    );
  }
}
