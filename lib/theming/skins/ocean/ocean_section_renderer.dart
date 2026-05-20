import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/extensions/l10n_extensions.dart';
import '../../../data/models/layout/layout_block.dart';
import '../../../data/models/layout/remote_button.dart';
import '../../icons/remote_key_l10n.dart';
import '../../skin_tokens.dart';
import '../../standard/button_presentation.dart';
import '../../standard/remote_image_scope.dart';
import '../../standard/section_renderer.dart';
import 'ocean_pulse_scope.dart';
import 'ocean_theme.dart';

/// Renders the `Ocean` skin's blocks: dark, slightly-frosted panels with a
/// pale border and a soft glow that breathes with the shared pulse. Colours
/// are intentionally constant — they need to read against every phase of the
/// day cycle the sky moves through.
class OceanSectionRenderer implements SectionRenderer {
  const OceanSectionRenderer();

  static const double _emptyCellSide = 60;

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
        _button(context, block.up, onKey, gap),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _button(context, block.left, onKey, gap),
            _button(context, block.ok, onKey, gap),
            _button(context, block.right, onKey, gap),
          ],
        ),
        _button(context, block.down, onKey, gap),
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

  Widget _button(
    BuildContext context,
    RemoteButton button,
    KeyPressHandler onKey,
    double gap,
  ) {
    final presentation = resolveButton(
      button,
      imagePaths: RemoteImageScope.of(context),
      labelFor: context.l10n.remoteKeyLabel,
    );
    return Padding(
      padding: EdgeInsets.all(gap / 2),
      child: _OceanButton(
        presentation: presentation,
        onPressed: () => onKey(button.action),
      ),
    );
  }
}

class _OceanButton extends StatelessWidget {
  const _OceanButton({required this.presentation, required this.onPressed});

  final ButtonPresentation presentation;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final pulse = OceanPulseScope.of(context);
    return AnimatedBuilder(
      animation: pulse,
      builder: (context, child) {
        final t = pulse.value;
        return Container(
          decoration: BoxDecoration(
            color: OceanTheme.alpha(OceanTheme.deep, 0.55 + 0.05 * t),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: OceanTheme.alpha(OceanTheme.foam, 0.30 + 0.10 * t),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: OceanTheme.alpha(OceanTheme.foam, 0.06 + 0.05 * t),
                blurRadius: 14 + 8 * t,
                spreadRadius: 0.5,
              ),
            ],
          ),
          child: child,
        );
      },
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          splashColor: OceanTheme.alpha(OceanTheme.foam, 0.25),
          highlightColor: OceanTheme.alpha(OceanTheme.foam, 0.10),
          onTap: onPressed,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: DefaultTextStyle.merge(
              style: const TextStyle(color: OceanTheme.foam),
              child: IconTheme.merge(
                data: const IconThemeData(color: OceanTheme.foam),
                child: _ButtonContent(presentation: presentation),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ButtonContent extends StatelessWidget {
  const _ButtonContent({required this.presentation});

  final ButtonPresentation presentation;

  @override
  Widget build(BuildContext context) {
    final glyph = presentation.glyph;
    final mark = switch (glyph) {
      IconGlyph(:final icon) => Icon(icon, size: 24),
      ImageGlyph(:final path) => Image.file(
        File(path),
        width: 28,
        height: 28,
        fit: BoxFit.contain,
        errorBuilder: (_, _, _) =>
            const Icon(Icons.broken_image_outlined, size: 24),
      ),
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

    return Semantics(label: presentation.semanticLabel, child: content);
  }
}
