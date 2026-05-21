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
        Column(
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
      child: _OceanButton(
        presentation: presentation,
        onPressed: () => onKey(button.action),
        compact: compact,
      ),
    );
  }
}

class _OceanButton extends StatelessWidget {
  const _OceanButton({
    required this.presentation,
    required this.onPressed,
    this.compact = false,
  });

  final ButtonPresentation presentation;
  final VoidCallback onPressed;
  final bool compact;

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
            padding: compact
                ? const EdgeInsets.symmetric(horizontal: 12, vertical: 8)
                : const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            child: DefaultTextStyle.merge(
              style: const TextStyle(color: OceanTheme.foam),
              child: IconTheme.merge(
                data: const IconThemeData(color: OceanTheme.foam),
                child: _ButtonContent(
                  presentation: presentation,
                  compact: compact,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

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
        errorBuilder: (_, _, _) =>
            Icon(Icons.broken_image_outlined, size: iconSize),
      ),
      TextGlyph(:final text) => Text(text),
    };

    return Semantics(label: presentation.semanticLabel, child: mark);
  }
}
